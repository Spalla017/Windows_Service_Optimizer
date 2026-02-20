# ============================================================================
# Windows Service Optimizer v2.0 - Interface Moderna
# Autor: Antigravity
# Descricao: GUI moderna com Sidebar, Dashboard e Terminal de Logs
# ============================================================================

#Requires -RunAsAdministrator

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================================
# CARREGA MODULO DE FUNCOES
# ============================================================================

if ($MyInvocation.MyCommand.Path) {
    $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
}
elseif ($PSScriptRoot) {
    $ScriptPath = $PSScriptRoot
}
else {
    $ScriptPath = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

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
# DEFINICAO DA INTERFACE XAML v2.0
# ============================================================================

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Service Optimizer" 
        Height="750" Width="900"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True"
        Background="Transparent"
        ResizeMode="CanMinimize">
    
    <Window.Resources>
        <!-- Botao Primario -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="#238636"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="24,14"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="10" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#2ea043"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#1a7f37"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Botao Secundario -->
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
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#30363d"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Botao Revert -->
        <Style x:Key="RevertButton" TargetType="Button">
            <Setter Property="Background" Value="#da3633"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="10,4"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
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

        <!-- Sidebar Button -->
        <Style x:Key="SidebarButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#8b949e"/>
            <Setter Property="FontFamily" Value="Segoe MDL2 Assets"/>
            <Setter Property="FontSize" Value="20"/>
            <Setter Property="Width" Value="48"/>
            <Setter Property="Height" Value="48"/>
            <Setter Property="Margin" Value="0,4"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="bg" Background="{TemplateBinding Background}" CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bg" Property="Background" Value="#21262d"/>
                                <Setter Property="Foreground" Value="#58a6ff"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Sidebar Button Ativo -->
        <Style x:Key="SidebarButtonActive" TargetType="Button" BasedOn="{StaticResource SidebarButton}">
            <Setter Property="Background" Value="#21262d"/>
            <Setter Property="Foreground" Value="#58a6ff"/>
        </Style>

        <!-- CheckBox -->
        <Style x:Key="CategoryCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="#c9d1d9"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="0,6"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <!-- Card -->
        <Style x:Key="CardBorder" TargetType="Border">
            <Setter Property="Background" Value="#161b22"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="Margin" Value="0,0,0,12"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#30363d"/>
        </Style>
    </Window.Resources>

    <!-- Container com borda arredondada -->
    <Border Background="#0d1117" CornerRadius="12" BorderBrush="#30363d" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Barra de Titulo Customizada -->
            <Border Grid.Row="0" Background="#010409" CornerRadius="12,12,0,0" Name="titleBar">
                <Grid>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="16,0,0,0">
                        <TextBlock Text="&#xE80F;" FontFamily="Segoe MDL2 Assets" FontSize="14" 
                                   Foreground="#58a6ff" VerticalAlignment="Center" Margin="0,0,10,0"/>
                        <TextBlock Text="Windows Service Optimizer" FontSize="13" FontWeight="SemiBold"
                                   Foreground="#c9d1d9" VerticalAlignment="Center"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                        <Button Name="btnMinimize" Content="&#xE921;" FontFamily="Segoe MDL2 Assets" FontSize="10"
                                Background="Transparent" Foreground="#8b949e" BorderThickness="0" 
                                Width="46" Height="40" Cursor="Hand"/>
                        <Button Name="btnMaximize" Content="&#xE922;" FontFamily="Segoe MDL2 Assets" FontSize="10"
                                Background="Transparent" Foreground="#8b949e" BorderThickness="0"
                                Width="46" Height="40" Cursor="Hand"/>
                        <Button Name="btnClose" Content="&#xE8BB;" FontFamily="Segoe MDL2 Assets" FontSize="10"
                                Background="Transparent" Foreground="#8b949e" BorderThickness="0"
                                Width="46" Height="40" Cursor="Hand"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- Corpo Principal -->
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="60"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Sidebar -->
                <Border Grid.Column="0" Background="#010409" Padding="6,8">
                    <StackPanel VerticalAlignment="Top">
                        <Button Name="btnNavDash" Style="{StaticResource SidebarButtonActive}" Content="&#xE80F;" ToolTip="Dashboard"/>
                        <Button Name="btnNavServices" Style="{StaticResource SidebarButton}" Content="&#xE713;" ToolTip="Servicos"/>
                        <Button Name="btnNavSystem" Style="{StaticResource SidebarButton}" Content="&#xE7F4;" ToolTip="Sistema"/>
                        <Button Name="btnNavAdvanced" Style="{StaticResource SidebarButton}" Content="&#xE90F;" ToolTip="Avancado"/>
                        <Border Height="1" Background="#21262d" Margin="8,12"/>
                        <Button Name="btnNavBackup" Style="{StaticResource SidebarButton}" Content="&#xE8F1;" ToolTip="Backup"/>
                        <Button Name="btnNavAbout" Style="{StaticResource SidebarButton}" Content="&#xE946;" ToolTip="Sobre"/>
                    </StackPanel>
                </Border>

                <!-- Content Area -->
                <Grid Grid.Column="1" Margin="20,16,20,16">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="200"/>
                    </Grid.RowDefinitions>

                    <!-- Pages Container -->
                    <Grid Name="pageContainer" Grid.Row="0">

                        <!-- PAGE: Dashboard -->
                        <Grid Name="pageDashboard" Visibility="Visible">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <!-- CPU e RAM Cards -->
                            <Grid Grid.Row="0" Margin="0,0,0,12">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="12"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.Column="0" Style="{StaticResource CardBorder}" Margin="0">
                                    <StackPanel>
                                        <TextBlock Text="Uso de CPU" FontSize="12" Foreground="#8b949e" FontWeight="SemiBold"/>
                                        <ProgressBar Name="barCPU" Height="10" Margin="0,10,0,6" Value="0"
                                                     Foreground="#238636" Background="#21262d" Maximum="100"/>
                                        <TextBlock Name="txtCPU" Text="0%" FontSize="18" FontWeight="Bold" Foreground="#c9d1d9"/>
                                    </StackPanel>
                                </Border>
                                <Border Grid.Column="2" Style="{StaticResource CardBorder}" Margin="0">
                                    <StackPanel>
                                        <TextBlock Text="Uso de RAM" FontSize="12" Foreground="#8b949e" FontWeight="SemiBold"/>
                                        <ProgressBar Name="barRAM" Height="10" Margin="0,10,0,6" Value="0"
                                                     Foreground="#58a6ff" Background="#21262d" Maximum="100"/>
                                        <TextBlock Name="txtRAM" Text="0%" FontSize="18" FontWeight="Bold" Foreground="#c9d1d9"/>
                                    </StackPanel>
                                </Border>
                            </Grid>

                            <!-- Botao Otimizar -->
                            <Grid Grid.Row="1" Margin="0,0,0,12">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="12"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Button Grid.Column="0" Name="btnOptimize" Content="Otimizar Sistema" 
                                        Style="{StaticResource PrimaryButton}" Height="56"/>
                                <Border Grid.Column="2" Style="{StaticResource CardBorder}" Margin="0" MinWidth="160">
                                    <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                                        <TextBlock Name="txtOptCount" Text="&#xE73E;" FontFamily="Segoe MDL2 Assets"
                                                   FontSize="28" Foreground="#238636" HorizontalAlignment="Center"/>
                                        <TextBlock Name="txtOptLabel" Text="0 otimizacoes ativas" FontSize="12" 
                                                   Foreground="#8b949e" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                                    </StackPanel>
                                </Border>
                            </Grid>

                            <!-- Barra de Progresso -->
                            <StackPanel Grid.Row="2" Margin="0,0,0,12">
                                <TextBlock Name="txtStatus" Text="Pronto para otimizar" FontSize="13" Foreground="#7ee787" Margin="0,0,0,6"/>
                                <ProgressBar Name="progressBar" Height="8" Foreground="#58a6ff" Background="#21262d" 
                                             Minimum="0" Maximum="100" Value="0" Visibility="Collapsed"/>
                            </StackPanel>

                            <!-- Botoes Secundarios -->
                            <Grid Grid.Row="3">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="8"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="8"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Button Grid.Column="0" Name="btnRefresh" Content="&#x1F504; Atualizar" Style="{StaticResource SecondaryButton}"/>
                                <Button Grid.Column="2" Name="btnRevertAll" Content="&#x21BA; Reverter Tudo" Style="{StaticResource RevertButton}" IsEnabled="False" Opacity="0.5"/>
                                <Button Grid.Column="4" Name="btnRestore" Content="Restaurar Backup" Style="{StaticResource SecondaryButton}"/>
                            </Grid>
                        </Grid>

                        <!-- PAGE: Servicos -->
                        <Grid Name="pageServices" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Grid.Row="0" Text="Servicos do Windows" FontSize="20" FontWeight="Bold" Foreground="#58a6ff" Margin="0,0,0,16"/>
                            <Border Grid.Row="1" Style="{StaticResource CardBorder}">
                                <ScrollViewer VerticalScrollBarVisibility="Auto">
                                    <StackPanel Name="pnlServices">
                                        <CheckBox Name="chkTelemetry" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                                            <StackPanel><TextBlock Text="Telemetria e Rastreamento" FontWeight="SemiBold"/>
                                            <TextBlock Text="Coleta de dados de uso pela Microsoft" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkXbox" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                                            <StackPanel><TextBlock Text="Xbox e Gaming" FontWeight="SemiBold"/>
                                            <TextBlock Text="Servicos do Xbox Live (desative se nao jogar)" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkPrint" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Impressao e Fax" FontWeight="SemiBold"/>
                                            <TextBlock Text="Desative apenas se nao usar impressora" FontSize="11" Foreground="#f0883e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkRemote" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Acesso Remoto" FontWeight="SemiBold"/>
                                            <TextBlock Text="Desative apenas se nao usar acesso remoto" FontSize="11" Foreground="#f0883e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkOthers" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                                            <StackPanel><TextBlock Text="Outros Servicos" FontWeight="SemiBold"/>
                                            <TextBlock Text="Mapas, Phone Service, Retail Demo, etc." FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                    </StackPanel>
                                </ScrollViewer>
                            </Border>
                        </Grid>

                        <!-- PAGE: Sistema -->
                        <Grid Name="pageSystem" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Grid.Row="0" Text="Otimizacoes do Sistema" FontSize="20" FontWeight="Bold" Foreground="#58a6ff" Margin="0,0,0,16"/>
                            <Border Grid.Row="1" Style="{StaticResource CardBorder}">
                                <ScrollViewer VerticalScrollBarVisibility="Auto">
                                    <StackPanel Name="pnlSystem">
                                        <CheckBox Name="chkVisualEffects" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                                            <StackPanel><TextBlock Text="Otimizar Efeitos Visuais" FontWeight="SemiBold"/>
                                            <TextBlock Text="Desativa animacoes e transparencias" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkGameBar" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                                            <StackPanel><TextBlock Text="Desativar Game Bar/DVR" FontWeight="SemiBold"/>
                                            <TextBlock Text="Remove gravacao e overlay de jogos" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkTipsAds" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                                            <StackPanel><TextBlock Text="Desativar Dicas e Anuncios" FontWeight="SemiBold"/>
                                            <TextBlock Text="Remove sugestoes do Menu Iniciar e Explorer" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkBloatware" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Remover Bloatware" FontWeight="SemiBold"/>
                                            <TextBlock Text="Remove apps pre-instalados nao utilizados" FontSize="11" Foreground="#f0883e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkDiskCleanup" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Limpeza de Disco" FontWeight="SemiBold"/>
                                            <TextBlock Text="Remove arquivos temporarios e Prefetch" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                        <Border Height="1" Background="#30363d" Margin="0,12"/>
                                        <CheckBox Name="chkPowerPlan" Style="{StaticResource CategoryCheckBox}" IsChecked="True">
                                            <StackPanel><TextBlock Text="Ativar Plano de Alto Desempenho" FontWeight="SemiBold" Foreground="#ffa657"/>
                                            <TextBlock Text="Configura o Windows para maximo desempenho" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                    </StackPanel>
                                </ScrollViewer>
                            </Border>
                        </Grid>

                        <!-- PAGE: Avancado -->
                        <Grid Name="pageAdvanced" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Grid.Row="0" Text="Manutencao Avancada" FontSize="20" FontWeight="Bold" Foreground="#f85149" Margin="0,0,0,16"/>
                            <Border Grid.Row="1" Style="{StaticResource CardBorder}">
                                <ScrollViewer VerticalScrollBarVisibility="Auto">
                                    <StackPanel Name="pnlAdvanced">
                                        <CheckBox Name="chkDISM" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Reparar Sistema (DISM)" FontWeight="SemiBold"/>
                                            <TextBlock Text="Verifica e repara imagem do Windows (demorado)" FontSize="11" Foreground="#f0883e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkSFC" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Verificar Arquivos (SFC)" FontWeight="SemiBold"/>
                                            <TextBlock Text="Verifica integridade dos arquivos do sistema" FontSize="11" Foreground="#f0883e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkWinSxS" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Limpeza Profunda (WinSxS)" FontWeight="SemiBold"/>
                                            <TextBlock Text="Remove atualizacoes antigas e componentes obsoletos" FontSize="11" Foreground="#f0883e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkNetworkReset" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Reset de Rede" FontWeight="SemiBold"/>
                                            <TextBlock Text="Limpa DNS, reseta Winsock e configuracao IP" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkChkdsk" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Agendar ChkDsk (Reinicio)" FontWeight="SemiBold"/>
                                            <TextBlock Text="Verifica integridade do disco no proximo boot" FontSize="11" Foreground="#f0883e"/></StackPanel>
                                        </CheckBox>
                                        <CheckBox Name="chkCompactOS" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Ativar Compact OS" FontWeight="SemiBold"/>
                                            <TextBlock Text="Comprime sistema para liberar 2-4GB (seguro)" FontSize="11" Foreground="#8b949e"/></StackPanel>
                                        </CheckBox>
                                        <Border Height="1" Background="#30363d" Margin="0,12"/>
                                        <TextBlock Text="SOLUCAO DE PROBLEMAS" FontWeight="Bold" Foreground="#d29922" FontSize="12" Margin="0,0,0,8"/>
                                        <CheckBox Name="chkRepairWU" Style="{StaticResource CategoryCheckBox}" IsChecked="False">
                                            <StackPanel><TextBlock Text="Reparar Windows Update" FontWeight="SemiBold"/>
                                            <TextBlock Text="Limpa cache, reseta servicos e forca nova busca" FontSize="11" Foreground="#d29922"/></StackPanel>
                                        </CheckBox>
                                    </StackPanel>
                                </ScrollViewer>
                            </Border>
                        </Grid>
                    </Grid>

                    <!-- Terminal de Logs (sempre visivel) -->
                    <Border Grid.Row="1" Background="#010409" CornerRadius="8" BorderBrush="#21262d" BorderThickness="1" Margin="0,8,0,0" Padding="12,8">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Grid.Row="0" Text=">_ Log de Execucao" FontSize="11" Foreground="#8b949e" 
                                       FontWeight="SemiBold" FontFamily="Consolas" Margin="0,0,0,6"/>
                            <ListBox Name="logTerminal" Grid.Row="1" Background="Transparent" BorderThickness="0"
                                     Foreground="#7ee787" FontFamily="Consolas" FontSize="11"
                                     ScrollViewer.HorizontalScrollBarVisibility="Disabled"
                                     ScrollViewer.VerticalScrollBarVisibility="Auto"/>
                        </Grid>
                    </Border>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

# ============================================================================
# CARREGA A INTERFACE
# ============================================================================

$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Controles da Barra de Titulo
$titleBar = $Window.FindName("titleBar")
$btnMinimize = $Window.FindName("btnMinimize")
$btnMaximize = $Window.FindName("btnMaximize")
$btnClose = $Window.FindName("btnClose")

# Controles da Sidebar
$btnNavDash = $Window.FindName("btnNavDash")
$btnNavServices = $Window.FindName("btnNavServices")
$btnNavSystem = $Window.FindName("btnNavSystem")
$btnNavAdvanced = $Window.FindName("btnNavAdvanced")
$btnNavBackup = $Window.FindName("btnNavBackup")
$btnNavAbout = $Window.FindName("btnNavAbout")

# Paginas
$pageDashboard = $Window.FindName("pageDashboard")
$pageServices = $Window.FindName("pageServices")
$pageSystem = $Window.FindName("pageSystem")
$pageAdvanced = $Window.FindName("pageAdvanced")

# Dashboard
$barCPU = $Window.FindName("barCPU")
$barRAM = $Window.FindName("barRAM")
$txtCPU = $Window.FindName("txtCPU")
$txtRAM = $Window.FindName("txtRAM")
$txtOptCount = $Window.FindName("txtOptCount")
$txtOptLabel = $Window.FindName("txtOptLabel")
$txtStatus = $Window.FindName("txtStatus")
$progressBar = $Window.FindName("progressBar")
$btnOptimize = $Window.FindName("btnOptimize")
$btnRefresh = $Window.FindName("btnRefresh")
$btnRevertAll = $Window.FindName("btnRevertAll")
$btnRestore = $Window.FindName("btnRestore")

# Terminal de Logs
$logTerminal = $Window.FindName("logTerminal")

# Checkboxes - Servicos
$chkTelemetry = $Window.FindName("chkTelemetry")
$chkXbox = $Window.FindName("chkXbox")
$chkPrint = $Window.FindName("chkPrint")
$chkRemote = $Window.FindName("chkRemote")
$chkOthers = $Window.FindName("chkOthers")

# Checkboxes - Sistema
$chkVisualEffects = $Window.FindName("chkVisualEffects")
$chkGameBar = $Window.FindName("chkGameBar")
$chkTipsAds = $Window.FindName("chkTipsAds")
$chkBloatware = $Window.FindName("chkBloatware")
$chkDiskCleanup = $Window.FindName("chkDiskCleanup")
$chkPowerPlan = $Window.FindName("chkPowerPlan")

# Checkboxes - Avancado
$chkDISM = $Window.FindName("chkDISM")
$chkSFC = $Window.FindName("chkSFC")
$chkWinSxS = $Window.FindName("chkWinSxS")
$chkNetworkReset = $Window.FindName("chkNetworkReset")
$chkChkdsk = $Window.FindName("chkChkdsk")
$chkCompactOS = $Window.FindName("chkCompactOS")
$chkRepairWU = $Window.FindName("chkRepairWU")

# ============================================================================
# FUNCOES DA INTERFACE
# ============================================================================

function Add-LogEntry {
    param([string]$Message, [string]$Color = "#7ee787")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $item = New-Object System.Windows.Controls.ListBoxItem
    $item.Content = "[$timestamp]  $Message"
    $item.Foreground = $Color
    $item.FontFamily = "Consolas"
    $item.FontSize = 11
    $item.Padding = "0,1"
    $logTerminal.Items.Add($item) | Out-Null
    $logTerminal.ScrollIntoView($item)
    $Window.Dispatcher.Invoke([action] {}, "Render")
}

function Update-Status {
    param([string]$Message, [string]$Color = "#7ee787")
    $txtStatus.Text = $Message
    $txtStatus.Foreground = $Color
    Add-LogEntry $Message $Color
}

function Update-PowerPlanStatus {
    try {
        $currentPlan = Get-CurrentPowerPlan
        Add-LogEntry "Plano de Energia: $currentPlan" "#8b949e"
    }
    catch {}
}

function Update-SystemStats {
    try {
        $cpu = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue)
        $barCPU.Value = $cpu
        $txtCPU.Text = "${cpu}%"
    }
    catch {
        $barCPU.Value = 0
        $txtCPU.Text = "N/A"
    }
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $totalRAM = $os.TotalVisibleMemorySize
        $freeRAM = $os.FreePhysicalMemory
        $usedPercent = [math]::Round((($totalRAM - $freeRAM) / $totalRAM) * 100)
        $barRAM.Value = $usedPercent
        $txtRAM.Text = "${usedPercent}%"
    }
    catch {
        $barRAM.Value = 0
        $txtRAM.Text = "N/A"
    }
}

# Navegacao de paginas
$Script:allPages = @($pageDashboard, $pageServices, $pageSystem, $pageAdvanced)
$Script:allNavButtons = @($btnNavDash, $btnNavServices, $btnNavSystem, $btnNavAdvanced)

function Switch-Page {
    param([System.Windows.Controls.Grid]$TargetPage, [System.Windows.Controls.Button]$ActiveButton)
    foreach ($p in $Script:allPages) { $p.Visibility = "Collapsed" }
    $TargetPage.Visibility = "Visible"
    foreach ($b in $Script:allNavButtons) {
        $b.Style = $Window.FindResource("SidebarButton")
    }
    $ActiveButton.Style = $Window.FindResource("SidebarButtonActive")
}

function Show-MessageBox {
    param([string]$Message, [string]$Title = "Service Optimizer", [string]$Type = "Info")
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
    if ($null -ne $Checkbox.Tag) { return }
    $Checkbox.IsChecked = $false
    $Checkbox.IsEnabled = $false
    $Checkbox.Opacity = 0.5
    $stackPanel = $Checkbox.Content
    $hasLabel = $false
    foreach ($child in $stackPanel.Children) {
        if ($child -is [System.Windows.Controls.TextBlock] -and $child.Text -like "*otimizado*") {
            $hasLabel = $true; break
        }
    }
    if (-not $hasLabel) {
        $statusLabel = New-Object System.Windows.Controls.TextBlock
        $statusLabel.Text = [char]0x2713 + " Ja otimizado"
        $statusLabel.FontSize = 11
        $statusLabel.FontWeight = "Bold"
        $statusLabel.Foreground = "#7ee787"
        $statusLabel.Margin = "0,4,0,0"
        $stackPanel.Children.Add($statusLabel)
    }
    $parentPanel = $Checkbox.Parent
    $checkboxIndex = $parentPanel.Children.IndexOf($Checkbox)
    $revertBtn = New-Object System.Windows.Controls.Button
    $revertBtn.Content = [char]0x21BA + " Reverter $Label"
    $revertBtn.Style = $Window.FindResource("RevertButton")
    $revertBtn.Margin = "0,0,0,12"
    $revertBtn.HorizontalAlignment = "Left"
    $revertBtn.Add_Click($OnClick)
    $parentPanel.Children.Insert($checkboxIndex + 1, $revertBtn)
    $Checkbox.Tag = $revertBtn
}

function Remove-RevertButton {
    param([System.Windows.Controls.CheckBox]$Checkbox)
    $Checkbox.IsEnabled = $true
    $Checkbox.Opacity = 1.0
    $Checkbox.IsChecked = $false
    $sp = $Checkbox.Content
    while ($sp.Children.Count -gt 2) { $sp.Children.RemoveAt($sp.Children.Count - 1) }
    if ($Checkbox.Tag) {
        $Checkbox.Parent.Children.Remove($Checkbox.Tag)
        $Checkbox.Tag = $null
    }
}

function Update-OptimizationCount {
    $total = 0
    $config = Get-ServicesByCategory -JsonPath $ConfigPath
    if (-not $config) { return }
    $cats = @("Telemetria e Rastreamento", "Xbox e Gaming", "Impressao e Fax", "Acesso Remoto", "Outros Servicos")
    foreach ($c in $cats) {
        if (Test-ServiceCategoryOptimized -CategoryName $c -Config $config) { $total++ }
    }
    if ($config.registryOptimizations) {
        if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.visualEffects) { $total++ }
        if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.gameBar) { $total++ }
        if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.tipsAndAds) { $total++ }
    }
    $compactStatus = Get-CompactOSStatus
    if ($compactStatus.Enabled) { $total++ }
    if (Test-PowerPlanOptimized) { $total++ }
    $txtOptLabel.Text = "$total otimizacao(oes) ativa(s)"
    if ($total -gt 0) {
        $btnRevertAll.IsEnabled = $true
        $btnRevertAll.Opacity = 1.0
    }
    else {
        $btnRevertAll.IsEnabled = $false
        $btnRevertAll.Opacity = 0.5
    }
}

function Update-OptimizationStates {
    Add-LogEntry "Verificando estado das otimizacoes..." "#79c0ff"
    $config = Get-ServicesByCategory -JsonPath $ConfigPath
    if (-not $config) { return }
    $serviceMap = @{
        "Telemetry" = @{ Checkbox = $chkTelemetry; Name = "Telemetria e Rastreamento"; Label = "Telemetria" }
        "Xbox"      = @{ Checkbox = $chkXbox; Name = "Xbox e Gaming"; Label = "Xbox" }
        "Print"     = @{ Checkbox = $chkPrint; Name = "Impressao e Fax"; Label = "Impressao" }
        "Remote"    = @{ Checkbox = $chkRemote; Name = "Acesso Remoto"; Label = "Acesso Remoto" }
        "Others"    = @{ Checkbox = $chkOthers; Name = "Outros Servicos"; Label = "Outros" }
    }
    foreach ($key in $serviceMap.Keys) {
        $item = $serviceMap[$key]
        if (Test-ServiceCategoryOptimized -CategoryName $item.Name -Config $config) {
            $categoryName = $item.Name
            $configRef = $config
            $checkboxRef = $item.Checkbox
            Add-RevertButton -Checkbox $item.Checkbox -Label $item.Label -OnClick {
                $msgResult = [System.Windows.MessageBox]::Show(
                    "Deseja reverter '$categoryName'?", "Reverter",
                    [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
                if ($msgResult -eq "Yes") {
                    Add-LogEntry "Revertendo $categoryName..." "#f85149"
                    Restore-ServiceCategory -CategoryName $categoryName -Config $configRef | Out-Null
                    Remove-RevertButton -Checkbox $checkboxRef
                    Add-LogEntry "$categoryName revertido!" "#7ee787"
                    Update-OptimizationCount
                }
            }.GetNewClosure()
        }
    }
    if ($config.registryOptimizations) {
        $regMap = @{
            "VisualEffects" = @{ Checkbox = $chkVisualEffects; Label = "Efeitos Visuais"; Opts = $config.registryOptimizations.visualEffects }
            "GameBar"       = @{ Checkbox = $chkGameBar; Label = "Game Bar"; Opts = $config.registryOptimizations.gameBar }
            "TipsAds"       = @{ Checkbox = $chkTipsAds; Label = "Dicas/Anuncios"; Opts = $config.registryOptimizations.tipsAndAds }
        }
        foreach ($key in $regMap.Keys) {
            $item = $regMap[$key]
            if (Test-RegistryKeyOptimized -Optimizations $item.Opts) {
                $regType = $key
                $checkboxRef = $item.Checkbox
                Add-RevertButton -Checkbox $item.Checkbox -Label $item.Label -OnClick {
                    $msgResult = [System.Windows.MessageBox]::Show(
                        "Deseja reverter registro '$regType'?", "Reverter",
                        [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
                    if ($msgResult -eq "Yes") {
                        Add-LogEntry "Revertendo registro $regType..." "#f85149"
                        Restore-RegistryDefault -OptimizationType $regType | Out-Null
                        Remove-RevertButton -Checkbox $checkboxRef
                        Add-LogEntry "Registro '$regType' revertido!" "#7ee787"
                        Update-OptimizationCount
                    }
                }.GetNewClosure()
            }
        }
    }
    $compactStatus = Get-CompactOSStatus
    if ($compactStatus.Enabled) {
        Add-RevertButton -Checkbox $chkCompactOS -Label "CompactOS" -OnClick {
            $msgResult = [System.Windows.MessageBox]::Show(
                "Deseja desativar o Compact OS?", "Reverter",
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($msgResult -eq "Yes") {
                Add-LogEntry "Desativando Compact OS..." "#f85149"
                Disable-CompactOS | Out-Null
                Remove-RevertButton -Checkbox $chkCompactOS
                Add-LogEntry "CompactOS desativado!" "#7ee787"
                Update-OptimizationCount
            }
        }
    }
    if (Test-PowerPlanOptimized) {
        Add-RevertButton -Checkbox $chkPowerPlan -Label "Plano de Energia" -OnClick {
            $msgResult = [System.Windows.MessageBox]::Show(
                "Reverter para o plano Equilibrado?", "Reverter",
                [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($msgResult -eq "Yes") {
                Add-LogEntry "Revertendo plano de energia..." "#f85149"
                Set-BalancedPowerPlan | Out-Null
                Remove-RevertButton -Checkbox $chkPowerPlan
                $chkPowerPlan.IsChecked = $true
                Add-LogEntry "Plano de energia revertido!" "#7ee787"
                Update-PowerPlanStatus
                Update-OptimizationCount
            }
        }
    }
    Add-LogEntry "Verificacao concluida. Pronto para otimizar!" "#7ee787"
    $txtStatus.Text = "Pronto para otimizar"
    $txtStatus.Foreground = "#7ee787"
    Update-OptimizationCount
}

# ============================================================================
# EVENT HANDLERS
# ============================================================================

# Barra de Titulo
$titleBar.Add_MouseLeftButtonDown({ $Window.DragMove() })
$btnMinimize.Add_Click({ $Window.WindowState = "Minimized" })
$btnMaximize.Add_Click({
        if ($Window.WindowState -eq "Maximized") { $Window.WindowState = "Normal" }
        else { $Window.WindowState = "Maximized" }
    })
$btnClose.Add_Click({ $Window.Close() })

# Sidebar
$btnNavDash.Add_Click({ Switch-Page -TargetPage $pageDashboard -ActiveButton $btnNavDash })
$btnNavServices.Add_Click({ Switch-Page -TargetPage $pageServices -ActiveButton $btnNavServices })
$btnNavSystem.Add_Click({ Switch-Page -TargetPage $pageSystem -ActiveButton $btnNavSystem })
$btnNavAdvanced.Add_Click({ Switch-Page -TargetPage $pageAdvanced -ActiveButton $btnNavAdvanced })

$btnNavBackup.Add_Click({
        Switch-Page -TargetPage $pageDashboard -ActiveButton $btnNavDash
        Add-LogEntry "Criando backup..." "#ffa657"
        try {
            $backupPath = New-ServiceBackup
            if ($backupPath) {
                Add-LogEntry "Backup criado: $backupPath" "#7ee787"
                Show-MessageBox "Backup criado com sucesso!`n`nLocal:`n$backupPath" "Sucesso" "Success"
            }
            else {
                Add-LogEntry "Erro ao criar backup" "#f85149"
                Show-MessageBox "Erro ao criar backup." "Erro" "Error"
            }
        }
        catch { Show-MessageBox "Erro: $_" "Erro" "Error" }
    })

$btnNavAbout.Add_Click({
        Show-MessageBox "Windows Service Optimizer v2.0`n`nDesenvolvido para otimizar o desempenho do Windows 11.`n`n- Desativa servicos desnecessarios`n- Configura plano de energia`n- Backup e restauracao`n- Terminal de logs em tempo real`n`n(c) 2024 Antigravity" "Sobre"
    })

# Botao Otimizar
$btnOptimize.Add_Click({
        $totalSteps = 0
        if ($chkTelemetry.IsChecked -and $chkTelemetry.IsEnabled) { $totalSteps++ }
        if ($chkXbox.IsChecked -and $chkXbox.IsEnabled) { $totalSteps++ }
        if ($chkPrint.IsChecked -and $chkPrint.IsEnabled) { $totalSteps++ }
        if ($chkRemote.IsChecked -and $chkRemote.IsEnabled) { $totalSteps++ }
        if ($chkOthers.IsChecked -and $chkOthers.IsEnabled) { $totalSteps++ }
        if ($chkBloatware.IsChecked -and $chkBloatware.IsEnabled) { $totalSteps++ }
        if ($chkVisualEffects.IsChecked -and $chkVisualEffects.IsEnabled) { $totalSteps++ }
        if ($chkGameBar.IsChecked -and $chkGameBar.IsEnabled) { $totalSteps++ }
        if ($chkTipsAds.IsChecked -and $chkTipsAds.IsEnabled) { $totalSteps++ }
        if ($chkDiskCleanup.IsChecked -and $chkDiskCleanup.IsEnabled) { $totalSteps++ }
        if ($chkDISM.IsChecked -and $chkDISM.IsEnabled) { $totalSteps++ }
        if ($chkSFC.IsChecked -and $chkSFC.IsEnabled) { $totalSteps++ }
        if ($chkWinSxS.IsChecked -and $chkWinSxS.IsEnabled) { $totalSteps++ }
        if ($chkNetworkReset.IsChecked -and $chkNetworkReset.IsEnabled) { $totalSteps++ }
        if ($chkChkdsk.IsChecked -and $chkChkdsk.IsEnabled) { $totalSteps++ }
        if ($chkCompactOS.IsChecked -and $chkCompactOS.IsEnabled) { $totalSteps++ }
        if ($chkRepairWU.IsChecked -and $chkRepairWU.IsEnabled) { $totalSteps++ }
        if ($chkPowerPlan.IsChecked -and $chkPowerPlan.IsEnabled) { $totalSteps++ }

        if ($totalSteps -eq 0) {
            Show-MessageBox "Selecione pelo menos uma opcao nas abas Servicos, Sistema ou Avancado." "Aviso" "Warning"
            return
        }

        $currentStep = 0
        $progressBar.Value = 0
        $progressBar.Visibility = "Visible"
        Update-Status "Iniciando otimizacao..." "#ffa657"

        try {
            Add-LogEntry "Criando backup de seguranca..." "#ffa657"
            $backupPath = New-ServiceBackup
            if (-not $backupPath) {
                $progressBar.Visibility = "Collapsed"
                Add-LogEntry "ERRO: Falha ao criar backup!" "#f85149"
                Show-MessageBox "Erro ao criar backup. Operacao cancelada." "Erro" "Error"
                return
            }
            Add-LogEntry "Backup criado com sucesso" "#7ee787"
            $totalDisabled = 0
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

            # Servicos
            $svcChecks = @(
                @{Chk = $chkTelemetry; Cat = "Telemetria e Rastreamento"; Lbl = "Telemetria" },
                @{Chk = $chkXbox; Cat = "Xbox e Gaming"; Lbl = "Xbox" },
                @{Chk = $chkPrint; Cat = "Impressao e Fax"; Lbl = "Impressao" },
                @{Chk = $chkRemote; Cat = "Acesso Remoto"; Lbl = "Acesso Remoto" },
                @{Chk = $chkOthers; Cat = "Outros Servicos"; Lbl = "Outros" }
            )
            foreach ($s in $svcChecks) {
                if ($s.Chk.IsChecked -and $s.Chk.IsEnabled) {
                    $currentStep++
                    Update-Status "Desativando $($s.Lbl)... ($currentStep/$totalSteps)" "#ffa657"
                    $category = $config.categories | Where-Object { $_.name -eq $s.Cat }
                    foreach ($svc in $category.services) {
                        Disable-ServiceSafely -ServiceName $svc.name 2>&1 | Out-Null
                        $totalDisabled++
                    }
                    $progressBar.Value = ($currentStep / $totalSteps) * 100
                    $Window.Dispatcher.Invoke([action] {}, "Render")
                }
            }

            # Sistema
            if ($chkBloatware.IsChecked -and $chkBloatware.IsEnabled) {
                $currentStep++; Update-Status "Removendo Bloatware... ($currentStep/$totalSteps)" "#ffa657"
                Remove-BloatwareFromList -AppList $config.bloatwareApps 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkVisualEffects.IsChecked -and $chkVisualEffects.IsEnabled) {
                $currentStep++; Update-Status "Otimizando Efeitos Visuais... ($currentStep/$totalSteps)" "#ffa657"
                Optimize-VisualEffect -Optimizations $config.registryOptimizations.visualEffects 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkGameBar.IsChecked -and $chkGameBar.IsEnabled) {
                $currentStep++; Update-Status "Desativando Game Bar... ($currentStep/$totalSteps)" "#ffa657"
                Disable-GameBar -Optimizations $config.registryOptimizations.gameBar 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkTipsAds.IsChecked -and $chkTipsAds.IsEnabled) {
                $currentStep++; Update-Status "Desativando Dicas e Anuncios... ($currentStep/$totalSteps)" "#ffa657"
                Disable-WindowsSuggestion -Optimizations $config.registryOptimizations.tipsAndAds 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkDiskCleanup.IsChecked -and $chkDiskCleanup.IsEnabled) {
                $currentStep++; Update-Status "Limpando disco... ($currentStep/$totalSteps)" "#ffa657"
                Clear-SystemJunk 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }

            # Avancado
            if ($chkDISM.IsChecked -and $chkDISM.IsEnabled) {
                $currentStep++; Update-Status "Verificando saude do sistema (DISM)... ($currentStep/$totalSteps)" "#ffa657"
                Test-SystemHealth 2>&1 | Out-Null
                Start-SystemScan 2>&1 | Out-Null
                Repair-SystemImage 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkSFC.IsChecked -and $chkSFC.IsEnabled) {
                $currentStep++; Update-Status "Verificando arquivos (SFC)... ($currentStep/$totalSteps)" "#ffa657"
                Repair-SystemFile 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkWinSxS.IsChecked -and $chkWinSxS.IsEnabled) {
                $currentStep++; Update-Status "Limpando WinSxS... ($currentStep/$totalSteps)" "#ffa657"
                Clear-ComponentStore 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkNetworkReset.IsChecked -and $chkNetworkReset.IsEnabled) {
                $currentStep++; Update-Status "Resetando rede... ($currentStep/$totalSteps)" "#ffa657"
                Reset-NetworkStack 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkChkdsk.IsChecked -and $chkChkdsk.IsEnabled) {
                $currentStep++; Update-Status "Agendando ChkDsk... ($currentStep/$totalSteps)" "#ffa657"
                Set-ScheduledChkdsk -DriveLetter "C" 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkCompactOS.IsChecked -and $chkCompactOS.IsEnabled) {
                $currentStep++; Update-Status "Ativando Compact OS... ($currentStep/$totalSteps)" "#ffa657"
                Enable-CompactOS 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkRepairWU.IsChecked -and $chkRepairWU.IsEnabled) {
                $currentStep++; Update-Status "Reparando Windows Update... ($currentStep/$totalSteps)" "#ffa657"
                Repair-WindowsUpdate 2>&1 | Out-Null
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }
            if ($chkPowerPlan.IsChecked -and $chkPowerPlan.IsEnabled) {
                $currentStep++; Update-Status "Configurando Alto Desempenho... ($currentStep/$totalSteps)" "#ffa657"
                Set-HighPerformancePowerPlan 2>&1 | Out-Null
                Update-PowerPlanStatus
                $progressBar.Value = ($currentStep / $totalSteps) * 100; $Window.Dispatcher.Invoke([action] {}, "Render")
            }

            $progressBar.Value = 100
            Update-Status "Otimizacao concluida!" "#7ee787"
            Start-Sleep -Milliseconds 500
            $progressBar.Visibility = "Collapsed"
            Update-OptimizationStates
            [System.Windows.MessageBox]::Show("Otimizacao concluida com sucesso!`n`nServicos processados: $totalDisabled`nBackup salvo em:`n$backupPath", "Sucesso", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
        catch {
            $progressBar.Visibility = "Collapsed"
            Add-LogEntry "ERRO: $_" "#f85149"
            $txtStatus.Text = "Erro na otimizacao"
            $txtStatus.Foreground = "#f85149"
            [System.Windows.MessageBox]::Show("Erro durante a otimizacao:`n$_", "Erro", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

# Botao Restaurar
$btnRestore.Add_Click({
        try {
            $backupFolder = "$env:USERPROFILE\Documents\ServiceOptimizer_Backups"
            if (-not (Test-Path $backupFolder)) {
                Show-MessageBox "Nenhum backup encontrado." "Aviso" "Warning"; return
            }
            $dialog = New-Object System.Windows.Forms.OpenFileDialog
            $dialog.InitialDirectory = $backupFolder
            $dialog.Filter = "Arquivo de Backup (*.json)|*.json"
            $dialog.Title = "Selecione o arquivo de backup"
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                Add-LogEntry "Restaurando backup..." "#ffa657"
                $result = Restore-ServicesFromBackup -BackupPath $dialog.FileName
                if ($result) {
                    Add-LogEntry "Restauracao concluida!" "#7ee787"
                    Show-MessageBox "Servicos restaurados!`nRecomenda-se reiniciar." "Sucesso" "Success"
                }
                else {
                    Add-LogEntry "Erro na restauracao" "#f85149"
                    Show-MessageBox "Erro ao restaurar backup." "Erro" "Error"
                }
            }
        }
        catch { Show-MessageBox "Erro: $_" "Erro" "Error" }
    })

# Botao Refresh
$btnRefresh.Add_Click({
        Add-LogEntry "Atualizando..." "#ffa657"
        Update-PowerPlanStatus
        Update-OptimizationStates
        Update-SystemStats
    })

# Botao Reverter Tudo
$btnRevertAll.Add_Click({
        $msgResult = [System.Windows.MessageBox]::Show(
            "Deseja reverter TODAS as otimizacoes?`n`nServicos, registro, CompactOS e plano de energia serao restaurados.",
            "Reverter Tudo", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($msgResult -eq "Yes") {
            Add-LogEntry "Revertendo todas as otimizacoes..." "#f85149"
            $revertCount = 0
            $config = Get-ServicesByCategory -JsonPath $ConfigPath
            if (-not $config) { Show-MessageBox "Erro ao carregar config." "Erro" "Error"; return }

            $serviceCategories = @("Telemetria e Rastreamento", "Xbox e Gaming", "Impressao e Fax", "Acesso Remoto", "Outros Servicos")
            foreach ($catName in $serviceCategories) {
                if (Test-ServiceCategoryOptimized -CategoryName $catName -Config $config) {
                    Restore-ServiceCategory -CategoryName $catName -Config $config | Out-Null
                    Add-LogEntry "Revertido: $catName" "#ffa657"
                    $revertCount++
                }
            }
            if ($config.registryOptimizations) {
                if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.visualEffects) {
                    Restore-RegistryDefault -OptimizationType "VisualEffects" | Out-Null; $revertCount++
                }
                if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.gameBar) {
                    Restore-RegistryDefault -OptimizationType "GameBar" | Out-Null; $revertCount++
                }
                if (Test-RegistryKeyOptimized -Optimizations $config.registryOptimizations.tipsAndAds) {
                    Restore-RegistryDefault -OptimizationType "TipsAds" | Out-Null; $revertCount++
                }
            }
            $compactStatus = Get-CompactOSStatus
            if ($compactStatus.Enabled) { Disable-CompactOS | Out-Null; $revertCount++ }
            if (Test-PowerPlanOptimized) { Set-BalancedPowerPlan | Out-Null; Update-PowerPlanStatus; $revertCount++ }

            # Limpar interface
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

            $btnRevertAll.IsEnabled = $false
            $btnRevertAll.Opacity = 0.5
            Update-OptimizationCount
            Add-LogEntry "Reversao concluida! $revertCount categoria(s) revertida(s)." "#7ee787"
            Show-MessageBox "Reversao concluida!`n`n$revertCount categoria(s) revertida(s)." "Sucesso" "Success"
        }
    })

# ============================================================================
# INICIALIZACAO
# ============================================================================

# Timer para CPU/RAM (a cada 3 segundos)
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(3)
$timer.Add_Tick({ Update-SystemStats })
$timer.Start()

# Log inicial
Add-LogEntry "Windows Service Optimizer v2.0 iniciado" "#58a6ff"
Add-LogEntry "Carregando estado do sistema..." "#8b949e"

# Inicializacao
Update-SystemStats
Update-PowerPlanStatus
Update-OptimizationStates

$Window.ShowDialog() | Out-Null
$timer.Stop()
