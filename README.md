# 🚀 Windows Service Optimizer v2.0

![Windows 11 Compatible](https://img.shields.io/badge/OS-Windows%2011-blue?style=flat-square&logo=windows)
![PowerShell](https://img.shields.io/badge/Language-PowerShell-1A2B34?style=flat-square&logo=powershell)
![Status](https://img.shields.io/badge/Status-Active-success?style=flat-square)
![WPF](https://img.shields.io/badge/GUI-WPF_XAML-blueviolet?style=flat-square)

O **Windows Service Optimizer v2.0** é uma ferramenta gráfica moderna e completa, desenvolvida puramente em PowerShell e WPF (XAML). Seu objetivo principal é melhorar significativamente o desempenho, a privacidade e a estabilidade de sistemas rodando Windows 11.

Com uma interface inspirada no **Fluent Design** (Modo Escuro), a versão 2.0 traz uma reestruturação visual total, permitindo aos usuários aplicar dezenas de otimizações de forma fácil e interativa, com acompanhamento de métricas do sistema em tempo real e total segurança através de backups.

---

## 📸 Nova Interface (v2.0)

A aplicação agora roda em uma janela "Frameless" e é estruturada em uma barra de navegação lateral (Sidebar) com as seguintes abas:

1. **🏠 Dashboard:** Foco no monitoramento de uso de CPU e RAM em tempo real, com destaque para a quantidade de otimizações ativas no momento e o botão principal de "Otimizar Sistema".
2. **⚙️ Serviços:** Categorias específicas para desativar serviços não essenciais (Telemetria, Xbox para não-gamers, Impressoras, Acesso Remoto).
3. **🖥️ Sistema:** Opções de otimização de Registro (Modo de Alto Desempenho, Efeitos Visuais, Desativação da Game Bar e Dicas do Windows) e Remoção de Bloatwares/Limpeza de Disco.
4. **🧹 Avançado:** Reparo profundo do sistema com ferramentas integradas do Windows (SFC, DISM), reset de cache do Windows Update, Limpeza WinSxS, reset de rede e compactação do SO (CompactOS).

Além disso, a janela possui um **>_ Terminal de Logs de Execução** embutido na parte inferior, que permite total transparência no visualizador durante os processos de aplicação, restauração e backup.

---

## ✨ Principais Funcionalidades

* 🛡️ **Segurança Sempre Ativa:** Geração automática e manual de arquivos de backup (salvos em `Documentos\ServiceOptimizer_Backups`) antes de qualquer alteração, permitindo restauração completa em caso de problemas.
* 🔄 **Reversibilidade Inteligente:** O sistema detecta ativamente quais parâmetros do sistema/registro já estão otimizados. Para cada categoria detectada, a interface gera um botão "Reverter", permitindo desfazer mudanças de forma cirúrgica. Também há um botão global "Reverter Tudo".
* 📊 **Monitoramento Dinâmico:** Leitura em tempo real do uso do processador (CPU) via `Get-CimInstance` e de Memória RAM visíveis diretamente no Dashboard principal.
* ⚡ **Desativação Limpa de Serviços:** Scripts adaptados para paralisar dependências de forma segura e limpa, lendo regras de forma dinâmica através do banco de dados em `ServiceList.json`.

---

## 🚀 Como Executar

O projeto já está compilado de forma portável em um prático arquivo `.exe`.

1. Acesse o arquivo `WSO_v2.exe` (ou `WindowsServiceOptimizer.exe`) na pasta raiz.
2. Clique com o botão direito do mouse e selecione **Executar como Administrador** (Permissão administrativa é estritamente necessária para editar serviços de nível de sistema).
3. Navegue entre as abas laterais e assinale as categorias de otimização que fazem sentido para o seu cenário.
4. Retorne ao Dashboard e clique no grande botão verde **Otimizar Sistema**. Acompanhe o progresso da barra e o histórico do Terminal de Logs inferior.

> **💡 Executar pelo Código Fonte:**  
> Caso prefira inspecionar/editar o código e executar pelo terminal, basta abrir o console do PowerShell como **Administrador** e rodar:
> `.\src\GUI.ps1`

---

## 🛠️ Stack Tecnológico e Arquitetura

- **PowerShell (Backend):** O `ServiceOptimizer.psm1` funciona como módulo central responsável por toda lógica pesada de chamadas ao Registro, WMI, e sistema de arquivos.
- **WPF e XAML (Frontend):** O `GUI.ps1` carrega dinamicamente XML pre-formatado com botões, cards arredondados, customização do ScrollViewer, Dispatcher Timers para monitoramento assíncrono de RAM/CPU e iconografia utilizando a fonte `Segoe MDL2 Assets`.
- **JSON (Banco de Regras):** Um arquivo flexível (`ServiceList.json`) permite adicionar ou remover novos aplicativos bloatware ou nomes de serviços sem editar o código fonte do PowerShell.
- **PS2EXE:** Utilizado para empacotar o software em um `.exe` livre de janelas de prompt (Flag `-noConsole`).

---

## ⚠️ Isenção de Responsabilidade

Esta ferramenta modifica chaves de registro profundas e desativa serviços nativos do ecossistema Microsoft. Embora todas as alterações adotem backups automáticos imediatos antes de sua execução, o autor não se responsabiliza por eventuais incompatibilidades de sistema, software de terceiros ou corrupções decorrentes do uso inadequado. Avalie o que está sendo desmarcado ou marcado, de acordo com o seu perfil de uso.

---
*Desenvolvido para maximizar a performance da sua máquina com elegância e eficiência.*
