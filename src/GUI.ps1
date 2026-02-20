# ============================================================================
# Windows Service Optimizer - Interface Grafica Moderna
# Autor: Antigravity
# Descricao: GUI moderna usando WPF com design inspirado em Fluent Design
# ============================================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================================
# CARREGA MODULO DE FUNCOES
# ============================================================================

# Detecta o caminho do script/exe de forma robusta
if ($MyInvocation.MyCommand.Path) {
    $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
}
elseif ($PSScriptRoot) {
    $ScriptPath = $PSScriptRoot
}
else {
    # Fallback para executaveis compilados com ps2exe
    $ScriptPath = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

# Verifica se existe uma pasta 'src' no diretorio atual
$SrcPath = Join-Path $ScriptPath "src"
if (Test-Path $SrcPath) {
    $ModulePath = Join-Path $SrcPath "ServiceOptimizer.psm1"
    $ConfigPath = Join-Path $SrcPath "ServiceList.json"
}
else {
    $ModulePath = Join-Path $ScriptPath "ServiceOptimizer.psm1"
    $ConfigPath = Join-Path $ScriptPath "ServiceList.json"
}

if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
}

# ============================================================================
# DEFINICAO DA INTERFACE XAML
# ============================================================================

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Service Optimizer" 
        Height="720" Width="520"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanMinimize"
        Background="#0d1117">
    
    <Window.Resources>
        <!-- Estilo para botoes principais -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="#238636"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="20,12"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                CornerRadius="8" 
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#2ea043"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#1a7f37"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Estilo para botoes secundarios -->
        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="#21262d"/>
            <Setter Property="Foreground" Value="#c9d1d9"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#30363d"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6" 
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#30363d"/>
                                <Setter Property="BorderBrush" Value="#8b949e"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Estilo para CheckBox -->
        <Style x:Key="CategoryCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="#c9d1d9"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="0,8"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        
        <!-- Estilo para botoes de reversao -->
        <Style x:Key="RevertButton" TargetType="Button">
            <Setter Property="Background" Value="#da3633"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="10,4"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="HorizontalAlignment" Value="Right"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#f85149"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Estilo para Cards -->
        <Style x:Key="CardBorder" TargetType="Border">
            <Setter Property="Background" Value="#161b22"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="Margin" Value="0,0,0,16"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#30363d"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,24">
            <TextBlock Text="Windows Service Optimizer" 
                       FontSize="28" FontWeight="Bold" Foreground="#58a6ff"/>
            <TextBlock Text="Otimize o desempenho do seu Windows 11" 
                       FontSize="14" Foreground="#8b949e" Margin="0,8,0,0"/>
        </StackPanel>
        
        <!-- Status Card -->
        <Border Grid.Row="1" Style="{StaticResource CardBorder}">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Margin="0,0,12,0">
                    <TextBlock Text="Status do Sistema" FontSize="12" Foreground="#8b949e" FontWeight="SemiBold"/>
                    <TextBlock Name="txtStatus" Text="Pronto para otimizar" 
                               FontSize="16" Foreground="#7ee787" Margin="0,4,0,0" TextWrapping="Wrap"/>
                    <TextBlock Name="txtPowerPlan" Text="Plano de Energia: Carregando..." 
                               FontSize="12" Foreground="#8b949e" Margin="0,8,0,0" TextWrapping="Wrap"/>
                    <ProgressBar Name="progressBar" Height="8" Margin="0,12,0,0" 
                                 Foreground="#58a6ff" Background="#21262d" 
                                 Minimum="0" Maximum="100" Value="0"
                                 IsIndeterminate="False" Visibility="Collapsed"/>
                </StackPanel>
                <Button Grid.Column="1" Name="btnRefresh" Content="🔄 Atualizar" 
                        Style="{StaticResource SecondaryButton}" 
                        ToolTip="Atualizar status" Width="100" Height="44" Padding="0"/>
                <Button Grid.Column="3" Name="btnRevertAll" Content="↺ Reverter Tudo" 
                        Style="{StaticResource RevertButton}" 
                        ToolTip="Reverter todas as otimizacoes" Width="120" Height="44" Padding="0"/>
            </Grid>
        </Border>
        
        <!-- Categories Card -->
        <Border Grid.Row="2" Style="{StaticResource CardBorder}">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="pnlCategories">
                    <TextBlock Text="Selecione as categorias para otimizar" 
                               FontSize="14" Foreground="#c9d1d9" FontWeight="SemiBold" Margin="0,0,0,16"/>
                    
                    <!-- Categorias serao populadas dinamicamente -->
                    <CheckBox Name="chkTelemetry" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                        <StackPanel>
                            <TextBlock Text="Telemetria e Rastreamento" FontWeight="SemiBold"/>
                            <TextBlock Text="Coleta de dados de uso pela Microsoft" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkXbox" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                        <StackPanel>
                            <TextBlock Text="Xbox e Gaming" FontWeight="SemiBold"/>
                            <TextBlock Text="Servicos do Xbox Live (desative se nao jogar)" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkPrint" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Impressao e Fax" FontWeight="SemiBold"/>
                            <TextBlock Text="Desative apenas se nao usar impressora" FontSize="11" Foreground="#f0883e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkRemote" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Acesso Remoto" FontWeight="SemiBold"/>
                            <TextBlock Text="Desative apenas se nao usar acesso remoto" FontSize="11" Foreground="#f0883e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkOthers" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                        <StackPanel>
                            <TextBlock Text="Outros Servicos" FontWeight="SemiBold"/>
                            <TextBlock Text="Mapas, Phone Service, Retail Demo, etc." FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <Border Height="1" Background="#30363d" Margin="0,16"/>
                    
                    <TextBlock Text="Otimizacoes Adicionais" 
                               FontSize="14" Foreground="#c9d1d9" FontWeight="SemiBold" Margin="0,0,0,8"/>
                    
                    <CheckBox Name="chkBloatware" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Remover Bloatware" FontWeight="SemiBold"/>
                            <TextBlock Text="Remove apps pre-instalados nao utilizados" FontSize="11" Foreground="#f0883e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkVisualEffects" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                        <StackPanel>
                            <TextBlock Text="Otimizar Efeitos Visuais" FontWeight="SemiBold"/>
                            <TextBlock Text="Desativa animacoes e transparencias" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkGameBar" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                        <StackPanel>
                            <TextBlock Text="Desativar Game Bar/DVR" FontWeight="SemiBold"/>
                            <TextBlock Text="Remove gravacao e overlay de jogos" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkTipsAds" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                        <StackPanel>
                            <TextBlock Text="Desativar Dicas e Anuncios" FontWeight="SemiBold"/>
                            <TextBlock Text="Remove sugestoes do Menu Iniciar e Explorer" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkCleanup" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Limpeza de Disco" FontWeight="SemiBold"/>
                            <TextBlock Text="Remove arquivos temporarios e Prefetch" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkDefrag" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Otimizar Unidade de Disco" FontWeight="SemiBold"/>
                            <TextBlock Text="Desfragmenta HDD ou executa TRIM em SSD" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkDISM" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Reparar Sistema (DISM/SFC)" FontWeight="SemiBold"/>
                            <TextBlock Text="Verifica e repara arquivos do Windows (demorado)" FontSize="11" Foreground="#f0883e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <!-- Separador: Manutencao Avancada -->
                    <Border Height="1" Background="#30363d" Margin="0,16"/>
                    <TextBlock Text="MANUTENCAO AVANCADA" FontWeight="Bold" Foreground="#f85149" FontSize="12" Margin="0,0,0,8"/>
                    
                    <CheckBox Name="chkWinSxS" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Limpeza Profunda (WinSxS)" FontWeight="SemiBold"/>
                            <TextBlock Text="Remove atualizacoes antigas e componentes obsoletos" FontSize="11" Foreground="#f0883e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkNetworkReset" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Reset de Rede" FontWeight="SemiBold"/>
                            <TextBlock Text="Limpa DNS, reseta Winsock e configuracao IP" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkChkdsk" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Agendar ChkDsk (Reinicio)" FontWeight="SemiBold"/>
                            <TextBlock Text="Verifica integridade do disco no proximo boot" FontSize="11" Foreground="#f0883e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <CheckBox Name="chkCompactOS" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Ativar Compact OS" FontWeight="SemiBold"/>
                            <TextBlock Text="Comprime sistema para liberar 2-4GB (seguro)" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <!-- Separador: Solucao de Problemas -->
                    <Border Height="1" Background="#30363d" Margin="0,16"/>
                    <TextBlock Text="SOLUCAO DE PROBLEMAS" FontWeight="Bold" Foreground="#d29922" FontSize="12" Margin="0,0,0,8"/>
                    
                    <CheckBox Name="chkRepairWU" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                        <StackPanel>
                            <TextBlock Text="Reparar Windows Update" FontWeight="SemiBold"/>
                            <TextBlock Text="Limpa cache, reseta servicos e forca nova busca" FontSize="11" Foreground="#d29922"/>
                        </StackPanel>
                    </CheckBox>
                    
                    <Border Height="1" Background="#30363d" Margin="0,16"/>
                    
                    <CheckBox Name="chkPowerPlan" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                        <StackPanel>
                            <TextBlock Text="Ativar Plano de Alto Desempenho" FontWeight="SemiBold" Foreground="#ffa657"/>
                            <TextBlock Text="Configura o Windows para maximo desempenho" FontSize="11" Foreground="#8b949e"/>
                        </StackPanel>
                    </CheckBox>
                </StackPanel>
            </ScrollViewer>
        </Border>
        
        <!-- Action Buttons -->
        <Grid Grid.Row="3" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="12"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <Button Grid.Column="0" Name="btnOptimize" Content="Otimizar Sistema" 
                    Style="{StaticResource PrimaryButton}"/>
            <Button Grid.Column="2" Name="btnRestore" Content="Restaurar Backup" 
                    Style="{StaticResource SecondaryButton}"/>
        </Grid>
        
        <!-- Footer Buttons -->
        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="12"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <Button Grid.Column="0" Name="btnBackup" Content="Criar Backup" 
                    Style="{StaticResource SecondaryButton}"/>
            <Button Grid.Column="2" Name="btnAbout" Content="Sobre" 
                    Style="{StaticResource SecondaryButton}"/>
        </Grid>
    </Grid>
</Window>
"@

# ============================================================================
# CARREGA A INTERFACE
# ============================================================================

$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Obtem referencias aos controles
$txtStatus = $Window.FindName("txtStatus")
$txtPowerPlan = $Window.FindName("txtPowerPlan")
$progressBar = $Window.FindName("progressBar")
$btnOptimize = $Window.FindName("btnOptimize")
$btnRestore = $Window.FindName("btnRestore")
$btnBackup = $Window.FindName("btnBackup")
$btnAbout = $Window.FindName("btnAbout")
$btnRefresh = $Window.FindName("btnRefresh")
$btnRevertAll = $Window.FindName("btnRevertAll")

$chkTelemetry = $Window.FindName("chkTelemetry")
$chkXbox = $Window.FindName("chkXbox")
$chkPrint = $Window.FindName("chkPrint")
$chkRemote = $Window.FindName("chkRemote")
$chkOthers = $Window.FindName("chkOthers")
$chkPowerPlan = $Window.FindName("chkPowerPlan")

# Novas opcoes de otimizacao
$chkBloatware = $Window.FindName("chkBloatware")
$chkVisualEffects = $Window.FindName("chkVisualEffects")
$chkGameBar = $Window.FindName("chkGameBar")
$chkTipsAds = $Window.FindName("chkTipsAds")
$chkCleanup = $Window.FindName("chkCleanup")
$chkDefrag = $Window.FindName("chkDefrag")
$chkDISM = $Window.FindName("chkDISM")

# Opcoes de Manutencao Avancada
$chkWinSxS = $Window.FindName("chkWinSxS")
$chkNetworkReset = $Window.FindName("chkNetworkReset")
$chkChkdsk = $Window.FindName("chkChkdsk")
$chkCompactOS = $Window.FindName("chkCompactOS")

# Opcoes de Solucao de Problemas
$chkRepairWU = $Window.FindName("chkRepairWU")

# ============================================================================
# FUNCOES DA INTERFACE
# ============================================================================

function Update-Status {
    param([string]$Message, [string]$Color = "#7ee787")
    $txtStatus.Text = $Message
    $txtStatus.Foreground = $Color
    $Window.Dispatcher.Invoke([action] {}, "Render")
}

function Update-PowerPlanStatus {
    try {
        $currentPlan = Get-CurrentPowerPlan
        $txtPowerPlan.Text = "Plano de Energia: $currentPlan"
    }
    catch {
        $txtPowerPlan.Text = "Plano de Energia: Desconhecido"
    }
}

function Show-MessageBox {
    param(
        [string]$Message,
        [string]$Title = "Service Optimizer",
        [string]$Type = "Info"
    )
    
    $icon = switch ($Type) {
        "Error" { [System.Windows.MessageBoxImage]::Error }
        "Warning" { [System.Windows.MessageBoxImage]::Warning }
        "Success" { [System.Windows.MessageBoxImage]::Information }
        default { [System.Windows.MessageBoxImage]::Information }
    }
    
    [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, $icon)
}

# ============================================================================
# DETECCAO DE ESTADO E BOTOES DE REVERSAO
# ============================================================================

function Add-RevertButton {
    param(
        [System.Windows.Controls.CheckBox]$Checkbox,
        [string]$Label,
        [scriptblock]$OnClick
    )
    
    # Verificar se já existe um botão de reversão (evitar duplicação)
    if ($null -ne $Checkbox.Tag) {
        # Já existe um botão, não criar outro
        return
    }
    
    # Desabilita o checkbox e marca visualmente como otimizado
    $Checkbox.IsChecked = $false
    $Checkbox.IsEnabled = $false
    $Checkbox.Opacity = 0.5
    
    # Obter o StackPanel dentro do checkbox para adicionar label
    $stackPanel = $Checkbox.Content
    
    # Verificar se já existe label "Já otimizado" (evitar duplicação)
    $hasLabel = $false
    foreach ($child in $stackPanel.Children) {
        if ($child -is [System.Windows.Controls.TextBlock] -and $child.Text -like "*otimizado*") {
            $hasLabel = $true
            break
        }
    }
    
    # Adicionar label de status dentro do checkbox apenas se não existir
    if (-not $hasLabel) {
        $statusLabel = New-Object System.Windows.Controls.TextBlock
        $statusLabel.Text = "✓ Ja otimizado"
        $statusLabel.FontSize = 11
        $statusLabel.FontWeight = "Bold"
        $statusLabel.Foreground = "#7ee787"
        $statusLabel.Margin = "0,4,0,0"
        $stackPanel.Children.Add($statusLabel)
    }
    
    # Obter o painel pai (pnlCategories) e o índice do checkbox
    $parentPanel = $Checkbox.Parent
    $checkboxIndex = $parentPanel.Children.IndexOf($Checkbox)
    
    # Criar botao de reversao FORA do checkbox
    $revertBtn = New-Object System.Windows.Controls.Button
    $revertBtn.Content = "↺ Reverter $Label"
    $revertBtn.Style = $Window.FindResource("RevertButton")
    $revertBtn.Margin = "0,0,0,12"
    $revertBtn.HorizontalAlignment = "Left"
    $revertBtn.Focusable = $true
    $revertBtn.IsTabStop = $true
    $revertBtn.Add_Click($OnClick)
    
    # Inserir o botão logo após o checkbox no painel pai
    $parentPanel.Children.Insert($checkboxIndex + 1, $revertBtn)
    
    # Armazenar referência do botão no checkbox para remoção posterior
    $Checkbox.Tag = $revertBtn
}

function Remove-RevertButton {
    param(
        [System.Windows.Controls.CheckBox]$Checkbox
    )
    
    # Reabilitar checkbox
    $Checkbox.IsEnabled = $true
    $Checkbox.Opacity = 1.0
    $Checkbox.IsChecked = $false
    
    # Remover label "Já otimizado" do StackPanel interno
    $sp = $Checkbox.Content
    while ($sp.Children.Count -gt 2) { 
        $sp.Children.RemoveAt($sp.Children.Count - 1) 
    }
    
    # Remover botão do painel pai
    if ($Checkbox.Tag) {
        $Checkbox.Parent.Children.Remove($Checkbox.Tag)
        $Checkbox.Tag = $null
    }
}

function Update-OptimizeButtonState {
    # Verificar se há pelo menos um checkbox selecionado E habilitado
    $hasSelection = $false
    
    # Lista de todos os checkboxes
    $allCheckboxes = @(
        $chkTelemetry, $chkXbox, $chkPrint, $chkRemote, $chkOthers,
        $chkVisualEffects, $chkGameBar, $chkTipsAds, $chkBloatware,
        $chkDiskCleanup, $chkPowerPlan, $chkCompactOS,
        $chkDISM, $chkSFC, $chkWinSxS, $chkNetworkReset, $chkChkdsk, $chkRepairWU
    )
    
    foreach ($chk in $allCheckboxes) {
        # Verificar se checkbox existe
        if ($null -ne $chk) {
            # Verificar se está marcado E habilitado (ignorar checkboxes otimizados/desabilitados)
            if ($chk.IsEnabled -and $chk.IsChecked -eq $true) {
                $hasSelection = $true
                break
            }
        }
    }
    
    # Habilitar/desabilitar botão Otimizar
    if ($hasSelection) {
        $btnOptimize.IsEnabled = $true
        $btnOptimize.Opacity = 1.0
    }
    else {
        $btnOptimize.IsEnabled = $false
        $btnOptimize.Opacity = 0.5
    }
}

function Update-OptimizationStates {
    Update-Status "Verificando estado das otimizacoes..." "#79c0ff"

    # Carregar config
    $config = Get-ServicesByCategory -JsonPath $ConfigPath
    if (-not $config) { return }
    
    # === Categorias de Servicos ===
    $serviceMap = @{
        "Telemetry" = @{ Checkbox = $chkTelemetry; Name = "Telemetria e Rastreamento"; Label = "Telemetria" }
        "Xbox"      = @{ Checkbox = $chkXbox; Name = "Xbox e Gaming"; Label = "Xbox" }
        "Print"     = @{ Checkbox = $chkPrint; Name = "Impressao e Fax"; Label = "Impressao" }
        "Remote"    = @{ Checkbox = $chkRemote; Name = "Acesso Remoto"; Label = "Acesso Remoto" }
        "Others"    = @{ Checkbox = $chkOthers; Name = "Outros Servicos"; Label = "Outros" }
    }
    
    foreach ($key in $serviceMap.Keys) {
        $item = $serviceMap[$key]
        $isOptimized = Test-ServiceCategoryOptimized -CategoryName $item.Name -Config $config
        
        if ($isOptimized) {
            $categoryName = $item.Name
            $configRef = $config
            $checkboxRef = $item.Checkbox
            Add-RevertButton -Checkbox $item.Checkbox -Label $item.Label -OnClick {
                $msgResult = [System.Windows.MessageBox]::Show(
                    "Deseja reverter a otimizacao de '$categoryName'?`nOs servicos serao restaurados para o modo Manual.",
                    "Reverter Otimizacao",
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Question
                )
                if ($msgResult -eq "Yes") {
                    Update-Status "Revertendo $categoryName..." "#f85149"
                    Restore-ServiceCategory -CategoryName $categoryName -Config $configRef | Out-Null
                    $checkboxRef.IsEnabled = $true
                    $checkboxRef.Opacity = 1.0
                    $checkboxRef.IsChecked = $false
                    # Remover label de status
                    $sp = $checkboxRef.Content
                    while ($sp.Children.Count -gt 2) { $sp.Children.RemoveAt($sp.Children.Count - 1) }
                    # Remover botão do painel pai
                    if ($checkboxRef.Tag) {
                        $checkboxRef.Parent.Children.Remove($checkboxRef.Tag)
                        $checkboxRef.Tag = $null
                    }
                    Update-Status "Servicos de '$categoryName' revertidos!" "#7ee787"
                    Show-MessageBox "Servicos revertidos com sucesso!" "Reversao" "Success"
                }
            }.GetNewClosure()
        }
    }
    
    # === Registro: Efeitos Visuais ===
    if ($config.registryOptimizations) {
        $regMap = @{
            "VisualEffects" = @{ Checkbox = $chkVisualEffects; Label = "Efeitos Visuais"; Opts = $config.registryOptimizations.visualEffects }
            "GameBar"       = @{ Checkbox = $chkGameBar; Label = "Game Bar"; Opts = $config.registryOptimizations.gameBar }
            "TipsAds"       = @{ Checkbox = $chkTipsAds; Label = "Dicas/Anuncios"; Opts = $config.registryOptimizations.tipsAndAds }
        }
        
        foreach ($key in $regMap.Keys) {
            $item = $regMap[$key]
            $isOptimized = Test-RegistryKeyOptimized -Optimizations $item.Opts
            
            if ($isOptimized) {
                $regType = $key
                $checkboxRef = $item.Checkbox
                Add-RevertButton -Checkbox $item.Checkbox -Label $item.Label -OnClick {
                    $msgResult = [System.Windows.MessageBox]::Show(
                        "Deseja reverter a otimizacao de registro '$regType'?`nOs valores serao restaurados para o padrao do Windows.",
                        "Reverter Registro",
                        [System.Windows.MessageBoxButton]::YesNo,
                        [System.Windows.MessageBoxImage]::Question
                    )
                    if ($msgResult -eq "Yes") {
                        Update-Status "Revertendo registro $regType..." "#f85149"
                        Restore-RegistryDefault -OptimizationType $regType | Out-Null
                        $checkboxRef.IsEnabled = $true
                        $checkboxRef.Opacity = 1.0
                        $checkboxRef.IsChecked = $false
                        $sp = $checkboxRef.Content
                        while ($sp.Children.Count -gt 2) { $sp.Children.RemoveAt($sp.Children.Count - 1) }
                        if ($checkboxRef.Tag) {
                            $checkboxRef.Parent.Children.Remove($checkboxRef.Tag)
                            $checkboxRef.Tag = $null
                        }
                        Update-Status "Registro '$regType' revertido!" "#7ee787"
                        Show-MessageBox "Configuracao de registro revertida!" "Reversao" "Success"
                    }
                }.GetNewClosure()
            }
        }
    }
    
    # === CompactOS ===
    $compactStatus = Get-CompactOSStatus
    if ($compactStatus.Enabled) {
        Add-RevertButton -Checkbox $chkCompactOS -Label "CompactOS" -OnClick {
            $msgResult = [System.Windows.MessageBox]::Show(
                "Deseja desativar o Compact OS?`nIsso vai descomprimir os arquivos do sistema.",
                "Reverter CompactOS",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )
            if ($msgResult -eq "Yes") {
                Update-Status "Desativando Compact OS..." "#f85149"
                Disable-CompactOS | Out-Null
                $chkCompactOS.IsEnabled = $true
                $chkCompactOS.Opacity = 1.0
                $chkCompactOS.IsChecked = $false
                $sp = $chkCompactOS.Content
                while ($sp.Children.Count -gt 2) { $sp.Children.RemoveAt($sp.Children.Count - 1) }
                if ($chkCompactOS.Tag) {
                    $chkCompactOS.Parent.Children.Remove($chkCompactOS.Tag)
                    $chkCompactOS.Tag = $null
                }
                Update-Status "CompactOS desativado!" "#7ee787"
                Show-MessageBox "Compact OS desativado com sucesso!" "Reversao" "Success"
            }
        }
    }
    
    # === Plano de Energia ===
    $powerOptimized = Test-PowerPlanOptimized
    if ($powerOptimized) {
        Add-RevertButton -Checkbox $chkPowerPlan -Label "Plano de Energia" -OnClick {
            $msgResult = [System.Windows.MessageBox]::Show(
                "Deseja reverter para o plano de energia Equilibrado?",
                "Reverter Plano de Energia",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )
            if ($msgResult -eq "Yes") {
                Update-Status "Revertendo plano de energia..." "#f85149"
                Set-BalancedPowerPlan | Out-Null
                $chkPowerPlan.IsEnabled = $true
                $chkPowerPlan.Opacity = 1.0
                $chkPowerPlan.IsChecked = $true
                $sp = $chkPowerPlan.Content
                while ($sp.Children.Count -gt 2) { $sp.Children.RemoveAt($sp.Children.Count - 1) }
                if ($chkPowerPlan.Tag) {
                    $chkPowerPlan.Parent.Children.Remove($chkPowerPlan.Tag)
                    $chkPowerPlan.Tag = $null
                }
                Update-Status "Plano de energia revertido para Equilibrado!" "#7ee787"
                Update-PowerPlanStatus
                Show-MessageBox "Plano de energia restaurado!" "Reversao" "Success"
            }
        }
    }
    
    Update-Status "Verificacao concluida. Pronto para otimizar!" "#7ee787"
    
    # Habilitar/desabilitar botao "Reverter Tudo" baseado em otimizacoes detectadas
    $totalOptimized = 0
    
    # Contar servicos otimizados
    foreach ($key in $serviceMap.Keys) {
        if (Test-ServiceCategoryOptimized -CategoryName $serviceMap[$key].Name -Config $config) {
            $totalOptimized++
        }
    }
    
    # Contar registro otimizado
    if ($config.registryOptimizations) {
        if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.visualEffects) { $totalOptimized++ }
        if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.gameBar) { $totalOptimized++ }
        if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.tipsAndAds) { $totalOptimized++ }
    }
    
    # Contar CompactOS e Plano de Energia
    if ($compactStatus.Enabled) { $totalOptimized++ }
    if ($powerOptimized) { $totalOptimized++ }
    
    # Habilitar/desabilitar botao
    if ($totalOptimized -gt 0) {
        $btnRevertAll.IsEnabled = $true
        $btnRevertAll.Opacity = 1.0
        $btnRevertAll.ToolTip = "Reverter $totalOptimized otimizacao(oes)"
    }
    else {
        $btnRevertAll.IsEnabled = $false
        $btnRevertAll.Opacity = 0.5
        $btnRevertAll.ToolTip = "Nenhuma otimizacao para reverter"
    }
}

# ============================================================================
# EVENT HANDLERS
# ============================================================================

# Botao Otimizar
$btnOptimize.Add_Click({
        # Contar etapas totais selecionadas
        $totalSteps = 0
        if ($chkTelemetry.IsChecked) { $totalSteps++ }
        if ($chkXbox.IsChecked) { $totalSteps++ }
        if ($chkPrint.IsChecked) { $totalSteps++ }
        if ($chkRemote.IsChecked) { $totalSteps++ }
        if ($chkOthers.IsChecked) { $totalSteps++ }
        if ($chkBloatware.IsChecked) { $totalSteps++ }
        if ($chkVisualEffects.IsChecked) { $totalSteps++ }
        if ($chkGameBar.IsChecked) { $totalSteps++ }
        if ($chkTipsAds.IsChecked) { $totalSteps++ }
        if ($chkDiskCleanup.IsChecked) { $totalSteps++ }
        if ($chkDISM.IsChecked) { $totalSteps++ }
        if ($chkSFC.IsChecked) { $totalSteps++ }
        if ($chkWinSxS.IsChecked) { $totalSteps++ }
        if ($chkNetworkReset.IsChecked) { $totalSteps++ }
        if ($chkChkdsk.IsChecked) { $totalSteps++ }
        if ($chkCompactOS.IsChecked) { $totalSteps++ }
        if ($chkRepairWU.IsChecked) { $totalSteps++ }
        if ($chkPowerPlan.IsChecked) { $totalSteps++ }
        
        $currentStep = 0
        
        # Resetar e mostrar barra de progresso
        $progressBar.Value = 0
        $progressBar.Visibility = "Visible"
        Update-Status "Iniciando otimizacao..." "#ffa657"
        $Window.Dispatcher.Invoke([action] {}, "Render")
    
        try {
            # Cria backup primeiro (não conta como step)
            Update-Status "Criando backup de seguranca..." "#ffa657"
            $Window.Dispatcher.Invoke([action] {}, "Render")
            $backupPath = New-ServiceBackup 2>&1 | Out-Null
        
            if (-not $backupPath) {
                $progressBar.Visibility = "Collapsed"
                [System.Windows.MessageBox]::Show("Erro ao criar backup. Operacao cancelada.", "Erro", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                Update-Status "Erro ao criar backup" "#f85149"
                return
            }
        
            $totalDisabled = 0
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
            # Processa cada categoria selecionada
            if ($chkTelemetry.IsChecked) {
                Update-Status "Desativando Telemetria... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                $category = $config.categories | Where-Object { $_.name -eq "Telemetria e Rastreamento" }
                foreach ($svc in $category.services) {
                    Disable-ServiceSafely -ServiceName $svc.name 2>&1 | Out-Null
                    $totalDisabled++
                }
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
        
            if ($chkXbox.IsChecked) {
                Update-Status "Desativando Xbox... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                $category = $config.categories | Where-Object { $_.name -eq "Xbox e Gaming" }
                foreach ($svc in $category.services) {
                    Disable-ServiceSafely -ServiceName $svc.name 2>&1 | Out-Null
                    $totalDisabled++
                }
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
        
            if ($chkPrint.IsChecked) {
                Update-Status "Desativando Impressao... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                $category = $config.categories | Where-Object { $_.name -eq "Impressao e Fax" }
                foreach ($svc in $category.services) {
                    Disable-ServiceSafely -ServiceName $svc.name 2>&1 | Out-Null
                    $totalDisabled++
                }
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
        
            if ($chkRemote.IsChecked) {
                Update-Status "Desativando Acesso Remoto... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                $category = $config.categories | Where-Object { $_.name -eq "Acesso Remoto" }
                foreach ($svc in $category.services) {
                    Disable-ServiceSafely -ServiceName $svc.name 2>&1 | Out-Null
                    $totalDisabled++
                }
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
        
            if ($chkOthers.IsChecked) {
                Update-Status "Desativando Outros Servicos... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                $category = $config.categories | Where-Object { $_.name -eq "Outros Servicos" }
                foreach ($svc in $category.services) {
                    Disable-ServiceSafely -ServiceName $svc.name 2>&1 | Out-Null
                    $totalDisabled++
                }
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
        
            # Novas otimizacoes adicionais
            if ($chkBloatware.IsChecked) {
                Update-Status "Removendo Bloatware... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                $bloatwareList = $config.bloatwareApps
                Remove-BloatwareFromList -AppList $bloatwareList 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkVisualEffects.IsChecked) {
                Update-Status "Otimizando Efeitos Visuais... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Optimize-VisualEffect -Optimizations $config.registryOptimizations.visualEffects 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkGameBar.IsChecked) {
                Update-Status "Desativando Game Bar/DVR... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Disable-GameBar -Optimizations $config.registryOptimizations.gameBar 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkTipsAds.IsChecked) {
                Update-Status "Desativando Dicas e Anuncios... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Disable-WindowsSuggestion -Optimizations $config.registryOptimizations.tipsAndAds 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkDiskCleanup.IsChecked) {
                Update-Status "Limpando arquivos temporarios... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                $cleanedMB = Clear-SystemJunk 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkDISM.IsChecked) {
                Update-Status "Verificando saude do sistema... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                $healthResult = Test-SystemHealth 2>&1 | Out-Null
                
                if (-not $healthResult.Success) {
                    Update-Status "Executando varredura profunda... ($($currentStep+1)/$totalSteps)" "#ffa657"
                    $Window.Dispatcher.Invoke([action] {}, "Render")
                    Start-SystemScan 2>&1 | Out-Null
                    
                    Update-Status "Reparando imagem do sistema... ($($currentStep+1)/$totalSteps)" "#ffa657"
                    $Window.Dispatcher.Invoke([action] {}, "Render")
                    Repair-SystemImage 2>&1 | Out-Null
                }
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkSFC.IsChecked) {
                Update-Status "Verificando arquivos do sistema (SFC)... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Repair-SystemFile 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            # Manutencao Avancada
            if ($chkWinSxS.IsChecked) {
                Update-Status "Limpando componentes antigos (WinSxS)... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Clear-ComponentStore 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkNetworkReset.IsChecked) {
                Update-Status "Resetando pilha de rede... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Reset-NetworkStack 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkChkdsk.IsChecked) {
                Update-Status "Agendando verificacao de disco... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Set-ScheduledChkdsk -DriveLetter "C" 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            if ($chkCompactOS.IsChecked) {
                Update-Status "Ativando Compact OS... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Enable-CompactOS 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            
            # Solucao de Problemas
            if ($chkRepairWU.IsChecked) {
                Update-Status "Reparando Windows Update... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Repair-WindowsUpdate 2>&1 | Out-Null
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
        
            # Configura plano de energia
            if ($chkPowerPlan.IsChecked) {
                Update-Status "Configurando Alto Desempenho... ($($currentStep+1)/$totalSteps)" "#ffa657"
                $Window.Dispatcher.Invoke([action] {}, "Render")
                Set-HighPerformancePowerPlan 2>&1 | Out-Null
                Update-PowerPlanStatus
                $currentStep++
                $progressBar.Value = ($currentStep / $totalSteps) * 100
                $Window.Dispatcher.Invoke([action] {}, "Render")
            }
        
            # Completar progresso
            $progressBar.Value = 100
            Update-Status "Otimizacao concluida!" "#7ee787"
            $Window.Dispatcher.Invoke([action] {}, "Render")
            
            Start-Sleep -Milliseconds 500
            
            # Ocultar barra de progresso
            $progressBar.Visibility = "Collapsed"
            
            # Atualizar estado para mostrar botoes de reversao
            Update-OptimizationStates
            
            [System.Windows.MessageBox]::Show("Otimizacao concluida com sucesso!`n`nServicos processados: $totalDisabled`nBackup salvo em:`n$backupPath", "Sucesso", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
        catch {
            # Ocultar barra de progresso em caso de erro
            $progressBar.Visibility = "Collapsed"
            Update-Status "Erro na otimizacao" "#f85149"
            [System.Windows.MessageBox]::Show("Erro durante a otimizacao:`n$_", "Erro", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

# Botao Restaurar
$btnRestore.Add_Click({
        try {
            $backupFolder = "$env:USERPROFILE\Documents\ServiceOptimizer_Backups"
        
            if (-not (Test-Path $backupFolder)) {
                Show-MessageBox "Nenhum backup encontrado." "Aviso" "Warning"
                return
            }
        
            $dialog = New-Object System.Windows.Forms.OpenFileDialog
            $dialog.InitialDirectory = $backupFolder
            $dialog.Filter = "Arquivo de Backup (*.json)|*.json"
            $dialog.Title = "Selecione o arquivo de backup"
        
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                Update-Status "Restaurando backup..." "#ffa657"
            
                $result = Restore-ServicesFromBackup -BackupPath $dialog.FileName
            
                if ($result) {
                    Update-Status "Restauracao concluida!" "#7ee787"
                    Show-MessageBox "Servicos restaurados com sucesso!`n`nRecomenda-se reiniciar o computador." "Sucesso" "Success"
                }
                else {
                    Update-Status "Erro na restauracao" "#f85149"
                    Show-MessageBox "Erro ao restaurar backup." "Erro" "Error"
                }
            }
        }
        catch {
            Show-MessageBox "Erro: $_" "Erro" "Error"
        }
    })

# Botao Backup
$btnBackup.Add_Click({
        Update-Status "Criando backup..." "#ffa657"
    
        try {
            $backupPath = New-ServiceBackup
        
            if ($backupPath) {
                Update-Status "Backup criado!" "#7ee787"
                Show-MessageBox "Backup criado com sucesso!`n`nLocal:`n$backupPath" "Sucesso" "Success"
            }
            else {
                Update-Status "Erro ao criar backup" "#f85149"
                Show-MessageBox "Erro ao criar backup." "Erro" "Error"
            }
        }
        catch {
            Show-MessageBox "Erro: $_" "Erro" "Error"
        }
    })

# Botao Sobre
$btnAbout.Add_Click({
        Show-MessageBox "Windows Service Optimizer v1.0.0`n`nDesenvolvido para otimizar o desempenho do Windows 11 em ambientes corporativos.`n`n- Desativa servicos desnecessarios`n- Configura plano de energia`n- Backup e restauracao de configuracoes`n`n(c) 2024 Antigravity" "Sobre"
    })

# Botao Refresh
$btnRefresh.Add_Click({
        Update-Status "Atualizando..." "#ffa657"
        Update-PowerPlanStatus
        Update-OptimizationStates
        Update-Status "Atualizado!" "#7ee787"
    })

# Botao Reverter Tudo
$btnRevertAll.Add_Click({
        $msgResult = [System.Windows.MessageBox]::Show(
            "Deseja reverter TODAS as otimizacoes detectadas?`n`nIsso incluira:`n- Servicos desativados`n- Configuracoes de registro`n- CompactOS`n- Plano de energia`n`nTodas serao restauradas para os padroes do Windows.",
            "Reverter Todas as Otimizacoes",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        
        if ($msgResult -eq "Yes") {
            Update-Status "Revertendo todas as otimizacoes..." "#f85149"
            $revertCount = 0
            
            # Carregar config
            $config = Get-ServicesByCategory -JsonPath $ConfigPath
            if (-not $config) {
                Show-MessageBox "Erro ao carregar configuracao." "Erro" "Error"
                return
            }
            
            # Reverter servicos
            $serviceCategories = @(
                "Telemetria e Rastreamento",
                "Xbox e Gaming",
                "Impressao e Fax",
                "Acesso Remoto",
                "Outros Servicos"
            )
            
            foreach ($catName in $serviceCategories) {
                if (Test-ServiceCategoryOptimized -CategoryName $catName -Config $config) {
                    Restore-ServiceCategory -CategoryName $catName -Config $config | Out-Null
                    $revertCount++
                }
            }
            
            # Reverter registro
            if ($config.registryOptimizations) {
                if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.visualEffects) {
                    Restore-RegistryDefault -OptimizationType "VisualEffects" | Out-Null
                    $revertCount++
                }
                if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.gameBar) {
                    Restore-RegistryDefault -OptimizationType "GameBar" | Out-Null
                    $revertCount++
                }
                if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.tipsAndAds) {
                    Restore-RegistryDefault -OptimizationType "TipsAds" | Out-Null
                    $revertCount++
                }
            }
            
            # Reverter CompactOS
            $compactStatus = Get-CompactOSStatus
            if ($compactStatus.Enabled) {
                Disable-CompactOS | Out-Null
                $revertCount++
            }
            
            # Reverter Plano de Energia
            if (Test-PowerPlanOptimized) {
                Set-BalancedPowerPlan | Out-Null
                Update-PowerPlanStatus
                $revertCount++
            }
            
            Update-Status "Reversao concluida! Atualizando interface..." "#7ee787"
            
            # Limpar interface de todos os checkboxes
            Remove-RevertButton -Checkbox $chkTelemetry
            Remove-RevertButton -Checkbox $chkXbox
            Remove-RevertButton -Checkbox $chkPrint
            Remove-RevertButton -Checkbox $chkRemote
            Remove-RevertButton -Checkbox $chkOthers
            Remove-RevertButton -Checkbox $chkVisualEffects
            Remove-RevertButton -Checkbox $chkGameBar
            Remove-RevertButton -Checkbox $chkTipsAds
            Remove-RevertButton -Checkbox $chkCompactOS
            Remove-RevertButton -Checkbox $chkPowerPlan
            
            # Atualizar estado do botão Reverter Tudo
            $btnRevertAll.IsEnabled = $false
            $btnRevertAll.Opacity = 0.5
            $btnRevertAll.ToolTip = "Nenhuma otimizacao para reverter"
            
            Show-MessageBox "Reversao concluida!`n`n$revertCount categoria(s) revertida(s) para os padroes do Windows." "Sucesso" "Success"
        }
    })

# ============================================================================
# INICIALIZACAO
# ============================================================================

# Adicionar event handlers aos checkboxes para monitorar estado do botão Otimizar
$allCheckboxes = @(
    $chkTelemetry, $chkXbox, $chkPrint, $chkRemote, $chkOthers,
    $chkVisualEffects, $chkGameBar, $chkTipsAds, $chkBloatware,
    $chkDiskCleanup, $chkPowerPlan, $chkCompactOS,
    $chkDISM, $chkSFC, $chkWinSxS, $chkNetworkReset, $chkChkdsk, $chkRepairWU
)

foreach ($chk in $allCheckboxes) {
    if ($null -ne $chk) {
        $chk.Add_Checked({ Update-OptimizeButtonState })
        $chk.Add_Unchecked({ Update-OptimizeButtonState })
    }
}

Update-PowerPlanStatus
Update-OptimizationStates
Update-OptimizeButtonState
$Window.ShowDialog() | Out-Null
