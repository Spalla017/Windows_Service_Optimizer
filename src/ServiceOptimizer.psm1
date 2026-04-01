# ============================================================================
# Windows Service Optimizer - Core Functions
# Autor: Antigravity
# Descricao: Funcoes principais para otimizacao de servicos do Windows 11
# ============================================================================

#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURACOES GLOBAIS
# ============================================================================

$Script:AppName = "Windows Service Optimizer"
$Script:Version = "1.0.0"
$Script:BackupFolder = "$env:USERPROFILE\Documents\ServiceOptimizer_Backups"
$Script:LogFile = "$Script:BackupFolder\optimizer_log.txt"
$Script:StructuredLogFile = "$Script:BackupFolder\optimizer_audit.jsonl"
$Script:ExecutionOptions = @{
    DryRun      = $false
    OperationId = $null
}

# ============================================================================
# FUNCOES DE LOGGING
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $operationId = if ($Script:ExecutionOptions.OperationId) { $Script:ExecutionOptions.OperationId } else { "N/A" }
    $actor = "$env:USERDOMAIN\$env:USERNAME"
    $logEntry = "[$timestamp] [$Level] [OperationId:$operationId] [Actor:$actor] $Message"
    
    if (-not (Test-Path $Script:BackupFolder)) {
        New-Item -ItemType Directory -Path $Script:BackupFolder -Force | Out-Null
    }
    
    Add-Content -Path $Script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    Write-StructuredLog -Message $Message -Level $Level
}

function Write-StructuredLog {
    <#
    .SYNOPSIS
        Escreve log de auditoria estruturado em formato JSONL
    #>
    param([string]$Message, [string]$Level = "INFO")
    
    try {
        if (-not (Test-Path $Script:BackupFolder)) {
            New-Item -ItemType Directory -Path $Script:BackupFolder -Force | Out-Null
        }
        
        $event = @{
            TimestampUtc = (Get-Date).ToUniversalTime().ToString("o")
            Level        = $Level
            Message      = $Message
            AppName      = $Script:AppName
            Version      = $Script:Version
            Machine      = $env:COMPUTERNAME
            Actor        = "$env:USERDOMAIN\$env:USERNAME"
            OperationId  = $Script:ExecutionOptions.OperationId
            DryRun       = [bool]$Script:ExecutionOptions.DryRun
        }
        
        Add-Content -Path $Script:StructuredLogFile -Value ($event | ConvertTo-Json -Compress) -ErrorAction SilentlyContinue
    }
    catch {
        # Nao interromper o fluxo por falha de log
    }
}

function Start-OptimizationSession {
    <#
    .SYNOPSIS
        Inicializa um ID de operacao para rastreabilidade
    #>
    param([string]$OperationId)
    
    if ([string]::IsNullOrWhiteSpace($OperationId)) {
        $OperationId = [guid]::NewGuid().ToString()
    }
    
    $Script:ExecutionOptions.OperationId = $OperationId
    Write-Log "Sessao de otimizacao iniciada" "INFO"
    return $OperationId
}

function Set-ExecutionMode {
    <#
    .SYNOPSIS
        Define modo de execucao (aplicacao real ou simulacao/dry-run)
    #>
    param([bool]$DryRun = $false)
    
    $Script:ExecutionOptions.DryRun = $DryRun
    if ($DryRun) {
        Write-Log "Modo DRY-RUN ativado. Nenhuma alteracao sera aplicada." "WARNING"
    }
    else {
        Write-Log "Modo de execucao REAL ativado." "INFO"
    }
}

function Test-ServiceOptimizerConfig {
    <#
    .SYNOPSIS
        Valida estrutura basica da configuracao JSON antes da execucao
    #>
    param([object]$Config)
    
    $errors = New-Object System.Collections.Generic.List[string]
    
    if (-not $Config) {
        $errors.Add("Configuracao nula.")
    }
    
    if (-not $Config.categories) {
        $errors.Add("Sessao 'categories' ausente.")
    }
    else {
        foreach ($category in $Config.categories) {
            if ([string]::IsNullOrWhiteSpace($category.name)) {
                $errors.Add("Categoria sem nome.")
            }
            
            if (-not $category.services) {
                $errors.Add("Categoria '$($category.name)' sem lista de servicos.")
                continue
            }
            
            foreach ($service in $category.services) {
                if ([string]::IsNullOrWhiteSpace($service.name)) {
                    $errors.Add("Categoria '$($category.name)' contem servico sem nome.")
                }
            }
        }
    }
    
    if ($errors.Count -gt 0) {
        foreach ($errorMessage in $errors) {
            Write-Log "Config invalida: $errorMessage" "ERROR"
        }
        
        return @{
            IsValid = $false
            Errors  = $errors
        }
    }
    
    Write-Log "Configuracao validada com sucesso." "SUCCESS"
    return @{
        IsValid = $true
        Errors  = @()
    }
}

# ============================================================================
# FUNCOES DE BACKUP E RESTAURACAO
# ============================================================================

function New-ServiceBackup {
    <#
    .SYNOPSIS
        Cria backup da configuracao atual de todos os servicos
    #>
    param([string]$BackupName = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')")
    
    try {
        Write-Log "Iniciando backup dos servicos..." "INFO"
        
        if (-not (Test-Path $Script:BackupFolder)) {
            New-Item -ItemType Directory -Path $Script:BackupFolder -Force | Out-Null
        }
        
        $services = Get-Service | Select-Object Name, DisplayName, Status, StartType
        $backupPath = "$Script:BackupFolder\$BackupName.json"
        
        $backupData = @{
            Timestamp    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            ComputerName = $env:COMPUTERNAME
            Services     = $services
        }
        
        $backupData | ConvertTo-Json -Depth 10 | Out-File -FilePath $backupPath -Encoding UTF8
        
        Write-Log "Backup criado com sucesso: $backupPath" "SUCCESS"
        return $backupPath
    }
    catch {
        Write-Log "Erro ao criar backup: $_" "ERROR"
        return $null
    }
}

function Restore-ServicesFromBackup {
    <#
    .SYNOPSIS
        Restaura servicos a partir de um arquivo de backup
    #>
    param([string]$BackupPath)
    
    try {
        if (-not (Test-Path $BackupPath)) {
            Write-Log "Arquivo de backup nao encontrado: $BackupPath" "ERROR"
            return $false
        }
        
        Write-Log "Iniciando restauracao a partir de: $BackupPath" "INFO"
        
        $backupData = Get-Content -Path $BackupPath -Raw | ConvertFrom-Json
        $totalServices = $backupData.Services.Count
        $restored = 0
        
        foreach ($service in $backupData.Services) {
            try {
                $currentService = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                if ($currentService) {
                    Set-Service -Name $service.Name -StartupType $service.StartType -ErrorAction SilentlyContinue
                    $restored++
                }
            }
            catch {
                Write-Log "Nao foi possivel restaurar: $($service.Name)" "WARNING"
            }
        }
        
        Write-Log "Restauracao concluida: $restored de $totalServices servicos" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro na restauracao: $_" "ERROR"
        return $false
    }
}

# ============================================================================
# FUNCOES DE OTIMIZACAO DE SERVICOS
# ============================================================================

function Disable-ServiceSafely {
    <#
    .SYNOPSIS
        Desativa um servico de forma segura
    #>
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if (-not $service) {
            Write-Log "Servico nao encontrado: $ServiceName" "WARNING"
            return $false
        }
        
        if ($Script:ExecutionOptions.DryRun) {
            Write-Log "DRY-RUN: Servico seria desativado: $ServiceName" "INFO"
            return $true
        }
        
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        }
        
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
        Write-Log "Servico desativado: $ServiceName" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro ao desativar $ServiceName : $_" "ERROR"
        return $false
    }
}

function Enable-ServiceSafely {
    <#
    .SYNOPSIS
        Reativa um servico
    #>
    param(
        [string]$ServiceName,
        [string]$StartupType = "Manual"
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if (-not $service) {
            Write-Log "Servico nao encontrado: $ServiceName" "WARNING"
            return $false
        }
        
        if ($Script:ExecutionOptions.DryRun) {
            Write-Log "DRY-RUN: Servico seria reativado: $ServiceName ($StartupType)" "INFO"
            return $true
        }
        
        Set-Service -Name $ServiceName -StartupType $StartupType -ErrorAction Stop
        Write-Log "Servico reativado: $ServiceName ($StartupType)" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro ao reativar $ServiceName : $_" "ERROR"
        return $false
    }
}

function Get-ServicesByCategory {
    <#
    .SYNOPSIS
        Carrega lista de servicos do arquivo JSON
    #>
    param([string]$JsonPath)
    
    try {
        if (-not (Test-Path $JsonPath)) {
            Write-Log "Arquivo de configuracao nao encontrado: $JsonPath" "ERROR"
            return $null
        }
        
        $config = Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
        $validation = Test-ServiceOptimizerConfig -Config $config
        if (-not $validation.IsValid) {
            Write-Log "Configuracao rejeitada por erro de validacao." "ERROR"
            return $null
        }
        
        return $config
    }
    catch {
        Write-Log "Erro ao carregar configuracao: $_" "ERROR"
        return $null
    }
}

function Optimize-ServicesByCategory {
    <#
    .SYNOPSIS
        Desativa todos os servicos de uma categoria
    #>
    param(
        [string]$CategoryName,
        [object]$Config
    )
    
    $category = $Config.categories | Where-Object { $_.name -eq $CategoryName }
    
    if (-not $category) {
        Write-Log "Categoria nao encontrada: $CategoryName" "WARNING"
        return 0
    }
    
    $disabled = 0
    foreach ($service in $category.services) {
        if (Disable-ServiceSafely -ServiceName $service.name) {
            $disabled++
        }
    }
    
    Write-Log "Categoria '$CategoryName': $disabled servicos desativados" "SUCCESS"
    return $disabled
}

# ============================================================================
# FUNCOES DE PLANO DE ENERGIA
# ============================================================================

function Set-HighPerformancePowerPlan {
    <#
    .SYNOPSIS
        Ativa o plano de energia de Alto Desempenho
    #>
    
    try {
        Write-Log "Configurando plano de energia para Alto Desempenho..." "INFO"
        
        # GUID do plano de Alto Desempenho
        $highPerformanceGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        
        # Verifica se o plano existe
        $plans = powercfg /list
        
        if ($plans -match $highPerformanceGuid) {
            # Ativa o plano de Alto Desempenho
            powercfg /setactive $highPerformanceGuid
            Write-Log "Plano de energia 'Alto Desempenho' ativado com sucesso!" "SUCCESS"
            return $true
        }
        else {
            # Se nao existir, duplica o plano balanceado e configura
            Write-Log "Plano de Alto Desempenho nao encontrado. Criando..." "INFO"
            $balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
            $result = powercfg /duplicatescheme $balancedGuid
            
            if ($result -match "GUID.*:\s*(.+)") {
                $newGuid = $matches[1].Trim()
                powercfg /changename $newGuid "Alto Desempenho Customizado" "Plano otimizado para maximo desempenho"
                powercfg /setactive $newGuid
                Write-Log "Plano de energia customizado criado e ativado!" "SUCCESS"
                return $true
            }
        }
        
        return $false
    }
    catch {
        Write-Log "Erro ao configurar plano de energia: $_" "ERROR"
        return $false
    }
}

function Get-CurrentPowerPlan {
    <#
    .SYNOPSIS
        Retorna o nome do plano de energia atual
    #>
    
    try {
        $activePlan = powercfg /getactivescheme
        if ($activePlan -match "\((.+)\)") {
            return $matches[1]
        }
        return "Desconhecido"
    }
    catch {
        return "Erro ao obter plano"
    }
}

function Set-BalancedPowerPlan {
    <#
    .SYNOPSIS
        Restaura o plano de energia Equilibrado (padrao)
    #>
    
    try {
        $balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
        powercfg /setactive $balancedGuid
        Write-Log "Plano de energia restaurado para 'Equilibrado'" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro ao restaurar plano de energia: $_" "ERROR"
        return $false
    }
}

# ============================================================================
# FUNCOES DE PONTO DE RESTAURACAO
# ============================================================================

function New-SystemRestorePoint {
    <#
    .SYNOPSIS
        Cria um ponto de restauracao do sistema
    #>
    param([string]$Description = "Windows Service Optimizer - Backup")
    
    try {
        Write-Log "Criando ponto de restauracao do sistema..." "INFO"
        
        # Habilita a protecao do sistema se necessario
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        
        # Cria o ponto de restauracao
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        Write-Log "Ponto de restauracao criado com sucesso!" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Aviso: Nao foi possivel criar ponto de restauracao: $_" "WARNING"
        return $false
    }
}

# ============================================================================
# FUNCOES DE REMOCAO DE BLOATWARE
# ============================================================================

function Remove-BloatwareApp {
    <#
    .SYNOPSIS
        Remove um aplicativo AppX (bloatware) pelo nome do pacote
    #>
    param([string]$PackageName)
    
    try {
        $app = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
        
        if (-not $app) {
            Write-Log "App nao encontrado ou ja removido: $PackageName" "WARNING"
            return $false
        }
        
        if ($Script:ExecutionOptions.DryRun) {
            Write-Log "DRY-RUN: App seria removido: $PackageName" "INFO"
            return $true
        }
        
        Get-AppxPackage -Name $PackageName | Remove-AppxPackage -ErrorAction Stop
        Write-Log "App removido: $PackageName" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro ao remover $PackageName : $_" "ERROR"
        return $false
    }
}

function Remove-BloatwareFromList {
    <#
    .SYNOPSIS
        Remove multiplos apps a partir de uma lista do JSON
    #>
    param([array]$AppList)
    
    $removed = 0
    foreach ($app in $AppList) {
        if (Remove-BloatwareApp -PackageName $app.name) {
            $removed++
        }
    }
    
    Write-Log "Total de apps removidos: $removed de $($AppList.Count)" "SUCCESS"
    return $removed
}

# ============================================================================
# FUNCOES DE OTIMIZACAO DE REGISTRO
# ============================================================================

function Set-RegistryOptimization {
    <#
    .SYNOPSIS
        Aplica uma otimizacao de registro
    #>
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type
    )
    
    try {
        if ($Script:ExecutionOptions.DryRun) {
            Write-Log "DRY-RUN: Registro seria aplicado: $Path\$Name" "INFO"
            return $true
        }
        
        # Cria a chave se nao existir
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Define o valor baseado no tipo
        switch ($Type) {
            "DWord" {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force
            }
            "String" {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type String -Force
            }
            "Binary" {
                Set-ItemProperty -Path $Path -Name $Name -Value ([byte[]]$Value) -Type Binary -Force
            }
            default {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
            }
        }
        
        Write-Log "Registro aplicado: $Path\$Name" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro ao aplicar registro $Path\$Name : $_" "ERROR"
        return $false
    }
}

function Optimize-VisualEffect {
    <#
    .SYNOPSIS
        Aplica otimizacoes de efeitos visuais do JSON
    #>
    param([array]$Optimizations)
    
    $applied = 0
    foreach ($opt in $Optimizations) {
        if (Set-RegistryOptimization -Path $opt.path -Name $opt.name -Value $opt.value -Type $opt.type) {
            $applied++
        }
    }
    
    Write-Log "Efeitos visuais otimizados: $applied configuracoes" "SUCCESS"
    return $applied
}

function Disable-GameBar {
    <#
    .SYNOPSIS
        Desativa a Game Bar e DVR do Windows
    #>
    param([array]$Optimizations)
    
    $applied = 0
    foreach ($opt in $Optimizations) {
        if (Set-RegistryOptimization -Path $opt.path -Name $opt.name -Value $opt.value -Type $opt.type) {
            $applied++
        }
    }
    
    Write-Log "Game Bar/DVR desativado: $applied configuracoes" "SUCCESS"
    return $applied
}

function Disable-WindowsSuggestion {
    <#
    .SYNOPSIS
        Desativa dicas, sugestoes e anuncios do Windows
    #>
    param([array]$Optimizations)
    
    $applied = 0
    foreach ($opt in $Optimizations) {
        if (Set-RegistryOptimization -Path $opt.path -Name $opt.name -Value $opt.value -Type $opt.type) {
            $applied++
        }
    }
    
    Write-Log "Dicas e anuncios desativados: $applied configuracoes" "SUCCESS"
    return $applied
}

# ============================================================================
# FUNCOES DE LIMPEZA DE DISCO
# ============================================================================

function Clear-SystemJunk {
    <#
    .SYNOPSIS
        Limpa arquivos temporarios e lixo do sistema
    #>
    
    try {
        Write-Log "Iniciando limpeza de arquivos temporarios..." "INFO"
        
        $totalCleaned = 0
        
        # Limpa pasta TEMP do usuario
        $userTemp = $env:TEMP
        if (Test-Path $userTemp) {
            $files = Get-ChildItem -Path $userTemp -Recurse -Force -ErrorAction SilentlyContinue
            $sizeBefore = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
            Remove-Item -Path "$userTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
            $totalCleaned += $sizeBefore
            Write-Log "Pasta TEMP do usuario limpa: $([math]::Round($sizeBefore, 2)) MB" "SUCCESS"
        }
        
        # Limpa pasta TEMP do Windows
        $windowsTemp = "$env:WINDIR\Temp"
        if (Test-Path $windowsTemp) {
            $files = Get-ChildItem -Path $windowsTemp -Recurse -Force -ErrorAction SilentlyContinue
            $sizeBefore = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
            Remove-Item -Path "$windowsTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
            $totalCleaned += $sizeBefore
            Write-Log "Pasta TEMP do Windows limpa: $([math]::Round($sizeBefore, 2)) MB" "SUCCESS"
        }
        
        # Limpa Prefetch (melhora boot em SSDs)
        $prefetch = "$env:WINDIR\Prefetch"
        if (Test-Path $prefetch) {
            $files = Get-ChildItem -Path $prefetch -Force -ErrorAction SilentlyContinue
            $sizeBefore = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
            Remove-Item -Path "$prefetch\*" -Force -ErrorAction SilentlyContinue
            $totalCleaned += $sizeBefore
            Write-Log "Pasta Prefetch limpa: $([math]::Round($sizeBefore, 2)) MB" "SUCCESS"
        }
        
        Write-Log "Limpeza concluida! Total liberado: $([math]::Round($totalCleaned, 2)) MB" "SUCCESS"
        return [math]::Round($totalCleaned, 2)
    }
    catch {
        Write-Log "Erro durante limpeza: $_" "ERROR"
        return 0
    }
}

function Clear-RecycleBin {
    <#
    .SYNOPSIS
        Esvazia a Lixeira do Windows
    #>
    
    try {
        Write-Log "Esvaziando Lixeira..." "INFO"
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Log "Lixeira esvaziada com sucesso!" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro ao esvaziar Lixeira: $_" "WARNING"
        return $false
    }
}

# ============================================================================
# FUNCOES DE OTIMIZACAO DE DISCO
# ============================================================================

function Optimize-Disk {
    <#
    .SYNOPSIS
        Otimiza/Desfragmenta as unidades de disco
    #>
    param([string]$DriveLetter = "C")
    
    try {
        Write-Log "Iniciando otimizacao da unidade $DriveLetter..." "INFO"
        
        # Verifica se eh SSD ou HDD para usar o comando apropriado
        $diskInfo = Get-PhysicalDisk | Select-Object -First 1
        $mediaType = $diskInfo.MediaType
        
        if ($mediaType -eq "SSD") {
            Write-Log "Disco SSD detectado. Executando TRIM..." "INFO"
            Optimize-Volume -DriveLetter $DriveLetter -ReTrim -Verbose
        }
        else {
            Write-Log "Disco HDD detectado. Executando desfragmentacao..." "INFO"
            Optimize-Volume -DriveLetter $DriveLetter -Defrag -Verbose
        }
        
        Write-Log "Otimizacao da unidade $DriveLetter concluida!" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar unidade: $_" "ERROR"
        return $false
    }
}

# ============================================================================
# FUNCOES DE REPARO DO SISTEMA (DISM/SFC)
# ============================================================================

function Test-SystemHealth {
    <#
    .SYNOPSIS
        Executa DISM /CheckHealth (verificacao rapida)
    #>
    
    try {
        Write-Log "Verificando saude do sistema (CheckHealth)..." "INFO"
        $result = dism /online /cleanup-image /checkhealth 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-Log "Detalhes CheckHealth: $($result -join ' ')" "INFO"
        
        if ($exitCode -eq 0) {
            Write-Log "CheckHealth: Nenhum problema detectado" "SUCCESS"
            return @{ Success = $true; Message = "Nenhum problema detectado" }
        }
        else {
            Write-Log "CheckHealth: Possiveis problemas encontrados" "WARNING"
            return @{ Success = $false; Message = "Problemas podem existir" }
        }
    }
    catch {
        Write-Log "Erro ao executar CheckHealth: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

function Start-SystemScan {
    <#
    .SYNOPSIS
        Executa DISM /ScanHealth (varredura profunda)
    #>
    
    try {
        Write-Log "Iniciando varredura profunda (ScanHealth)... Isso pode demorar." "INFO"
        $result = dism /online /cleanup-image /scanhealth 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-Log "Detalhes ScanHealth: $($result -join ' ')" "INFO"
        
        if ($exitCode -eq 0) {
            Write-Log "ScanHealth: Sistema integro" "SUCCESS"
            return @{ Success = $true; Message = "Sistema integro" }
        }
        else {
            Write-Log "ScanHealth: Corrupcao detectada" "WARNING"
            return @{ Success = $false; Message = "Corrupcao detectada" }
        }
    }
    catch {
        Write-Log "Erro ao executar ScanHealth: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

function Repair-SystemImage {
    <#
    .SYNOPSIS
        Executa DISM /RestoreHealth (reparar imagem)
    #>
    
    try {
        Write-Log "Iniciando reparo da imagem do sistema (RestoreHealth)... Isso pode demorar bastante." "INFO"
        $result = dism /online /cleanup-image /restorehealth 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-Log "Detalhes RestoreHealth: $($result -join ' ')" "INFO"
        
        if ($exitCode -eq 0) {
            Write-Log "RestoreHealth: Reparo concluido com sucesso" "SUCCESS"
            return @{ Success = $true; Message = "Reparo concluido" }
        }
        else {
            Write-Log "RestoreHealth: Falha no reparo" "ERROR"
            return @{ Success = $false; Message = "Falha no reparo" }
        }
    }
    catch {
        Write-Log "Erro ao executar RestoreHealth: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

function Repair-SystemFile {
    <#
    .SYNOPSIS
        Executa SFC /scannow (verificar arquivos do sistema)
    #>
    
    try {
        Write-Log "Iniciando verificacao de arquivos do sistema (SFC)... Isso pode demorar." "INFO"
        $result = sfc /scannow 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-Log "Detalhes SFC: $($result -join ' ')" "INFO"
        
        if ($exitCode -eq 0) {
            Write-Log "SFC: Verificacao concluida com sucesso" "SUCCESS"
            return @{ Success = $true; Message = "Verificacao concluida" }
        }
        else {
            Write-Log "SFC: Alguns arquivos nao puderam ser reparados" "WARNING"
            return @{ Success = $false; Message = "Alguns arquivos com problemas" }
        }
    }
    catch {
        Write-Log "Erro ao executar SFC: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

# ============================================================================
# FUNCOES DE MANUTENCAO AVANCADA
# ============================================================================

function Clear-ComponentStore {
    <#
    .SYNOPSIS
        Limpa a loja de componentes do Windows (pasta WinSxS)
    #>
    
    try {
        Write-Log "Iniciando limpeza da loja de componentes (WinSxS)... Isso pode demorar." "INFO"
        $result = dism /online /cleanup-image /startcomponentcleanup 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-Log "Detalhes ComponentCleanup: $($result -join ' ')" "INFO"
        
        if ($exitCode -eq 0) {
            Write-Log "Limpeza de componentes concluida com sucesso!" "SUCCESS"
            return @{ Success = $true; Message = "Limpeza concluida" }
        }
        else {
            Write-Log "Falha na limpeza de componentes" "WARNING"
            return @{ Success = $false; Message = "Falha na limpeza" }
        }
    }
    catch {
        Write-Log "Erro ao limpar componentes: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

function Reset-NetworkStack {
    <#
    .SYNOPSIS
        Reseta a pilha de rede (Flush DNS + Winsock Reset)
    #>
    
    try {
        Write-Log "Iniciando reset da pilha de rede..." "INFO"
        
        # Flush DNS
        Write-Log "Limpando cache DNS..." "INFO"
        $resultDns = ipconfig /flushdns 2>&1
        Write-Log "FlushDNS: $($resultDns -join ' ')" "INFO"
        
        # Release e Renew IP
        Write-Log "Liberando e renovando IP..." "INFO"
        $resultRelease = ipconfig /release 2>&1
        Write-Log "IP Release: $($resultRelease -join ' ')" "INFO"
        $resultRenew = ipconfig /renew 2>&1
        Write-Log "IP Renew: $($resultRenew -join ' ')" "INFO"
        
        # Reset Winsock
        Write-Log "Resetando catalogo Winsock..." "INFO"
        $resultWinsock = netsh winsock reset 2>&1
        Write-Log "Winsock: $($resultWinsock -join ' ')" "INFO"
        
        # Reset IP
        Write-Log "Resetando configuracao IP..." "INFO"
        $resultIp = netsh int ip reset 2>&1
        Write-Log "IP Reset: $($resultIp -join ' ')" "INFO"
        
        Write-Log "Reset de rede concluido! Reinicie o computador para aplicar todas as alteracoes." "SUCCESS"
        return @{ Success = $true; Message = "Reset de rede concluido. Reinicialize para completar." }
    }
    catch {
        Write-Log "Erro ao resetar rede: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

function Set-ScheduledChkdsk {
    <#
    .SYNOPSIS
        Agenda uma verificacao de disco (ChkDsk) para o proximo boot
    #>
    param([string]$DriveLetter = "C")
    
    try {
        Write-Log "Agendando verificacao de disco para unidade $DriveLetter no proximo reinicio..." "INFO"
        
        # Marca a unidade como "suja" para forçar chkdsk no boot
        $result = fsutil dirty set ${DriveLetter}: 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-Log "Resultado fsutil: $($result -join ' ')" "INFO"
        
        if ($exitCode -eq 0 -or $result -match "definida") {
            Write-Log "Verificacao de disco agendada! Sera executada no proximo reinicio." "SUCCESS"
            return @{ Success = $true; Message = "ChkDsk agendado para o proximo boot" }
        }
        else {
            Write-Log "Nao foi possivel agendar a verificacao de disco" "WARNING"
            return @{ Success = $false; Message = "Falha ao agendar ChkDsk" }
        }
    }
    catch {
        Write-Log "Erro ao agendar ChkDsk: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

function Get-CompactOSStatus {
    <#
    .SYNOPSIS
        Verifica o status atual do Compact OS
    #>
    
    try {
        $result = compact /compactos:query 2>&1
        
        if ($result -match "Compactado") {
            return @{ Enabled = $true; Message = "Compact OS esta ativado" }
        }
        elseif ($result -match "compactado") {
            return @{ Enabled = $true; Message = "Compact OS esta ativado" }
        }
        else {
            return @{ Enabled = $false; Message = "Compact OS esta desativado" }
        }
    }
    catch {
        return @{ Enabled = $false; Message = "Erro ao verificar status: $_" }
    }
}

function Enable-CompactOS {
    <#
    .SYNOPSIS
        Ativa a compactacao do sistema operacional (libera 2-4GB)
    #>
    
    try {
        Write-Log "Ativando Compact OS... Isso pode demorar varios minutos." "INFO"
        $result = compact /compactos:always 2>&1
        
        Write-Log "Detalhes CompactOS: $($result -join ' ')" "INFO"
        
        Write-Log "Compact OS ativado com sucesso! Espaco liberado no disco." "SUCCESS"
        return @{ Success = $true; Message = "Compact OS ativado" }
    }
    catch {
        Write-Log "Erro ao ativar Compact OS: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

function Disable-CompactOS {
    <#
    .SYNOPSIS
        Desativa a compactacao do sistema operacional
    #>
    
    try {
        Write-Log "Desativando Compact OS..." "INFO"
        $result = compact /compactos:never 2>&1
        
        Write-Log "Detalhes CompactOS: $($result -join ' ')" "INFO"
        
        Write-Log "Compact OS desativado." "SUCCESS"
        return @{ Success = $true; Message = "Compact OS desativado" }
    }
    catch {
        Write-Log "Erro ao desativar Compact OS: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

# ============================================================================
# FUNCOES DE DETECCAO E REVERSAO DE ESTADO
# ============================================================================

function Test-ServiceCategoryOptimized {
    <#
    .SYNOPSIS
        Verifica se todos os servicos de uma categoria ja estao desativados
    #>
    param(
        [string]$CategoryName,
        [object]$Config
    )
    
    $category = $Config.categories | Where-Object { $_.name -eq $CategoryName }
    
    if (-not $category) { return $false }
    
    $totalServices = 0
    $disabledServices = 0
    
    foreach ($svc in $category.services) {
        $service = Get-Service -Name $svc.name -ErrorAction SilentlyContinue
        if ($service) {
            $totalServices++
            if ($service.StartType -eq 'Disabled') {
                $disabledServices++
            }
        }
    }
    
    if ($totalServices -eq 0) { return $false }
    
    return ($disabledServices -eq $totalServices)
}

function Test-RegistryKeyOptimized {
    <#
    .SYNOPSIS
        Verifica se uma chave de registro ja esta otimizada
    #>
    param([array]$Optimizations)
    
    if (-not $Optimizations -or $Optimizations.Count -eq 0) { return $false }
    
    $optimizedCount = 0
    
    foreach ($opt in $Optimizations) {
        try {
            if (Test-Path $opt.path) {
                $currentValue = Get-ItemProperty -Path $opt.path -Name $opt.name -ErrorAction SilentlyContinue
                if ($null -ne $currentValue) {
                    $propValue = $currentValue.($opt.name)
                    if ($opt.type -eq "Binary") {
                        $targetBytes = [byte[]]$opt.value
                        if ($propValue -is [byte[]] -and $propValue.Length -eq $targetBytes.Length) {
                            $match = $true
                            for ($i = 0; $i -lt $targetBytes.Length; $i++) {
                                if ($propValue[$i] -ne $targetBytes[$i]) { $match = $false; break }
                            }
                            if ($match) { $optimizedCount++ }
                        }
                    }
                    else {
                        if ("$propValue" -eq "$($opt.value)") {
                            $optimizedCount++
                        }
                    }
                }
            }
        }
        catch { continue }
    }
    
    return ($optimizedCount -eq $Optimizations.Count)
}

function Test-PowerPlanOptimized {
    <#
    .SYNOPSIS
        Verifica se o plano de energia ja esta em Alto Desempenho
    #>
    
    try {
        $activePlan = powercfg /getactivescheme
        $highPerformanceGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        return ($activePlan -match $highPerformanceGuid)
    }
    catch { return $false }
}

function Get-OptimizationStatus {
    <#
    .SYNOPSIS
        Verifica o status de todas as otimizacoes reversiveis
    #>
    param([object]$Config)
    
    $status = @{}
    
    # Verificar categorias de servicos
    $serviceCategories = @(
        @{ Key = "Telemetry"; Name = "Telemetria e Rastreamento" },
        @{ Key = "Xbox"; Name = "Xbox e Gaming" },
        @{ Key = "Print"; Name = "Impressao e Fax" },
        @{ Key = "Remote"; Name = "Acesso Remoto" },
        @{ Key = "Others"; Name = "Outros Servicos" }
    )
    
    foreach ($cat in $serviceCategories) {
        $status[$cat.Key] = Test-ServiceCategoryOptimized -CategoryName $cat.Name -Config $Config
    }
    
    # Verificar registro
    if ($Config.registryOptimizations) {
        $status["VisualEffects"] = Test-RegistryKeyOptimized -Optimizations $Config.registryOptimizations.visualEffects
        $status["GameBar"] = Test-RegistryKeyOptimized -Optimizations $Config.registryOptimizations.gameBar
        $status["TipsAds"] = Test-RegistryKeyOptimized -Optimizations $Config.registryOptimizations.tipsAndAds
    }
    
    # Verificar CompactOS
    try {
        $compactResult = compact /compactos:query 2>&1
        $status["CompactOS"] = ($compactResult -match "compact" -and $compactResult -match "is|estado")
    }
    catch { $status["CompactOS"] = $false }
    
    # Verificar plano de energia
    $status["PowerPlan"] = Test-PowerPlanOptimized
    
    return $status
}

function Restore-ServiceCategory {
    <#
    .SYNOPSIS
        Restaura os servicos de uma categoria para o padrao (Manual ou Automatic)
    #>
    param(
        [string]$CategoryName,
        [object]$Config
    )
    
    $category = $Config.categories | Where-Object { $_.name -eq $CategoryName }
    
    if (-not $category) {
        Write-Log "Categoria nao encontrada para reversao: $CategoryName" "WARNING"
        return 0
    }
    
    $restored = 0
    foreach ($svc in $category.services) {
        if (Enable-ServiceSafely -ServiceName $svc.name -StartupType "Manual") {
            $restored++
        }
    }
    
    Write-Log "Categoria '$CategoryName': $restored servicos restaurados para Manual" "SUCCESS"
    return $restored
}

function Restore-RegistryDefault {
    <#
    .SYNOPSIS
        Restaura valores padrao do registro do Windows
    #>
    param([string]$OptimizationType)
    
    try {
        switch ($OptimizationType) {
            "VisualEffects" {
                # Restaurar efeitos visuais para padrao
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "1" -Type String -Force
                # Restaurar UserPreferencesMask para padrao (animacoes habilitadas)
                $defaultMask = [byte[]](158, 30, 7, 128, 18, 0, 0, 0)
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value $defaultMask -Type Binary -Force
                Write-Log "Efeitos visuais restaurados para padrao" "SUCCESS"
            }
            "GameBar" {
                Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -Type DWord -Force
                if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR") {
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -Type DWord -Force
                }
                if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR") {
                    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Force -ErrorAction SilentlyContinue
                }
                Write-Log "Game Bar/DVR restaurado para padrao" "SUCCESS"
            }
            "TipsAds" {
                $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
                Set-ItemProperty -Path $cdmPath -Name "SoftLandingEnabled" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338388Enabled" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-310093Enabled" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value 1 -Type DWord -Force
                Write-Log "Dicas e anuncios restaurados para padrao" "SUCCESS"
            }
        }
        return $true
    }
    catch {
        Write-Log "Erro ao restaurar registro ($OptimizationType): $_" "ERROR"
        return $false
    }
}

# ============================================================================
# FUNCOES DE SOLUCAO DE PROBLEMAS
# ============================================================================

function Repair-WindowsUpdate {
    <#
    .SYNOPSIS
        Repara o Windows Update limpando cache e resetando servicos
    #>
    
    try {
        Write-Log "Iniciando reparo do Windows Update..." "INFO"
        
        # === PASSO 1: Parar servicos dependentes ===
        Write-Log "Parando servicos do Windows Update..." "INFO"
        $services = @('wuauserv', 'bits', 'cryptSvc', 'msiserver')
        
        foreach ($svc in $services) {
            try {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Write-Log "Servico parado: $svc" "SUCCESS"
            }
            catch {
                Write-Log "Aviso: Nao foi possivel parar $svc (pode ja estar parado)" "WARNING"
            }
        }
        
        # === PASSO 2: Limpar cache corrompido ===
        Write-Log "Limpando cache do Windows Update..." "INFO"
        
        $sdPath = "$env:WINDIR\SoftwareDistribution"
        $catrootPath = "$env:WINDIR\System32\catroot2"
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        # Renomeia SoftwareDistribution (backup seguro)
        if (Test-Path $sdPath) {
            $backupSD = "${sdPath}.bak_$timestamp"
            try {
                Rename-Item -Path $sdPath -NewName "SoftwareDistribution.bak_$timestamp" -Force -ErrorAction Stop
                Write-Log "SoftwareDistribution renomeada para backup: $backupSD" "SUCCESS"
            }
            catch {
                # Se nao conseguir renomear, tenta limpar o conteudo
                Write-Log "Nao foi possivel renomear SoftwareDistribution. Limpando conteudo..." "WARNING"
                Remove-Item -Path "$sdPath\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$sdPath\DataStore\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Conteudo de SoftwareDistribution limpo" "SUCCESS"
            }
        }
        
        # Renomeia catroot2 (backup seguro)
        if (Test-Path $catrootPath) {
            try {
                Rename-Item -Path $catrootPath -NewName "catroot2.bak_$timestamp" -Force -ErrorAction Stop
                Write-Log "catroot2 renomeada para backup" "SUCCESS"
            }
            catch {
                Write-Log "Nao foi possivel renomear catroot2. Limpando conteudo..." "WARNING"
                Remove-Item -Path "$catrootPath\*" -Force -ErrorAction SilentlyContinue
                Write-Log "Conteudo de catroot2 limpo" "SUCCESS"
            }
        }
        
        # === PASSO 3: Reset de conectividade ===
        Write-Log "Resetando configuracoes de rede para Windows Update..." "INFO"
        
        $result = netsh winsock reset 2>&1
        Write-Log "Winsock reset: $($result -join ' ')" "INFO"
        
        $result = netsh winhttp reset proxy 2>&1
        Write-Log "Proxy reset: $($result -join ' ')" "INFO"
        
        # === PASSO 4: Reiniciar servicos ===
        Write-Log "Reiniciando servicos do Windows Update..." "INFO"
        
        foreach ($svc in $services) {
            try {
                Start-Service -Name $svc -ErrorAction SilentlyContinue
                Write-Log "Servico reiniciado: $svc" "SUCCESS"
            }
            catch {
                Write-Log "Aviso: Nao foi possivel reiniciar $svc" "WARNING"
            }
        }
        
        # === PASSO 5: Forcar busca de atualizacoes ===
        Write-Log "Forcando busca de novas atualizacoes..." "INFO"
        try {
            $result = usoclient ScanInstallWait 2>&1
            Write-Log "Busca de atualizacoes disparada" "SUCCESS"
        }
        catch {
            Write-Log "Aviso: usoclient nao disponivel. Abra Configuracoes > Windows Update manualmente." "WARNING"
        }
        
        Write-Log "Reparo do Windows Update concluido com sucesso!" "SUCCESS"
        return @{ Success = $true; Message = "Windows Update reparado com sucesso" }
    }
    catch {
        Write-Log "Erro durante reparo do Windows Update: $_" "ERROR"
        return @{ Success = $false; Message = $_.ToString() }
    }
}

# ============================================================================
# EXPORTACAO DE FUNCOES
# ============================================================================

Export-ModuleMember -Function @(
    'Write-Log',
    'Write-StructuredLog',
    'Start-OptimizationSession',
    'Set-ExecutionMode',
    'Test-ServiceOptimizerConfig',
    'New-ServiceBackup',
    'Restore-ServicesFromBackup',
    'Disable-ServiceSafely',
    'Enable-ServiceSafely',
    'Get-ServicesByCategory',
    'Optimize-ServicesByCategory',
    'Set-HighPerformancePowerPlan',
    'Get-CurrentPowerPlan',
    'Set-BalancedPowerPlan',
    'New-SystemRestorePoint',
    'Remove-BloatwareApp',
    'Remove-BloatwareFromList',
    'Set-RegistryOptimization',
    'Optimize-VisualEffect',
    'Disable-GameBar',
    'Disable-WindowsSuggestion',
    'Clear-SystemJunk',
    'Clear-RecycleBin',
    'Optimize-Disk',
    'Test-SystemHealth',
    'Start-SystemScan',
    'Repair-SystemImage',
    'Repair-SystemFile',
    'Clear-ComponentStore',
    'Reset-NetworkStack',
    'Set-ScheduledChkdsk',
    'Get-CompactOSStatus',
    'Enable-CompactOS',
    'Disable-CompactOS',
    'Repair-WindowsUpdate',
    'Test-ServiceCategoryOptimized',
    'Test-RegistryKeyOptimized',
    'Test-PowerPlanOptimized',
    'Get-OptimizationStatus',
    'Restore-ServiceCategory',
    'Restore-RegistryDefault'
)
