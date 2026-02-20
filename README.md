# 🚀 Windows Service Optimizer

![Windows 11 Compatible](https://img.shields.io/badge/OS-Windows%2011-blue?style=flat-square&logo=windows)
![PowerShell](https://img.shields.io/badge/Language-PowerShell-1A2B34?style=flat-square&logo=powershell)
![Status](https://img.shields.io/badge/Status-Active-success?style=flat-square)

O **Windows Service Optimizer** é uma ferramenta gráfica completa desenvolvida em PowerShell (WPF) para melhorar o desempenho, a privacidade e a estabilidade do Windows 11. 

A aplicação permite aos usuários aplicar dezenas de otimizações de forma fácil e segura, oferecendo total controle sobre quais serviços desativar e com a segurança de criação automática de pontos de restauração.

## ✨ Principais Funcionalidades

* 🛡️ **Segurança em Primeiro Lugar:** Criação automática de ponto de restauração antes de aplicar qualquer alteração.
* ⚡ **Desativação de Serviços Básicos:** Telemetria, recursos do Xbox (para não-gamers), serviços de impressão, acesso remoto e outros serviços em segundo plano que consomem recursos.
* 🧹 **Limpeza e Manutenção Avançada:** Limpeza profunda de disco, remoção de Bloatwares pré-instalados, limpeza da pasta WinSxS (Component Store) e CompactOS.
* 🛠️ **Reparo do Sistema:** Integração direta com ferramentas como `SFC` e `DISM` para reparar arquivos de imagem e de sistema corrompidos. Reparo ágil do Windows Update.
* 🎮 **Otimizações Específicas:** Otimização para "Modo de Alto Desempenho", desligamento de efeitos visuais excessivos, desativação de anúncios/dicas nativas do Windows e do Game Bar.
* 🔄 **Reversibilidade Inteligente:** O sistema detecta quais otimizações já estão aplicadas no seu computador e permite que você reverta cada mudança individualmente ou utilizar o botão "Reverter Tudo" com apenas um clique.
* 🎨 **Interface Moderna:** Design elegante baseado em XAML, com modo escuro nativo, progresso visual em tempo real através de barras animadas e menus responsivos.

## 🚀 Como Executar

O projeto já está compilado em um prático arquivo `.exe` para facilitar o uso.

1. Baixe o executável `WindowsServiceOptimizer.exe` a partir da aba de **Releases** (ou encontre-o na pasta raiz).
2. Clique com o botão direito e selecione **Executar como Administrador** (O programa exige permissão administrativa para alterar serviços e criar pontos de restauração).
3. Selecione as categorias que você deseja otimizar na tela inicial.
4. Clique em **Otimizar Sistema** e acompanhe o progresso.

> **Quer executar direto do código fonte?**  
> Basta executar o arquivo `src/GUI.ps1` no console do PowerShell como Administrador.

## 🛠️ Tecnologias Utilizadas

- **PowerShell:** Motor do backend realizando as chamadas ao WMI, Registro e sistema de arquivos.
- **WPF (Windows Presentation Foundation):** Para construção nativa do design da interface, estilização e eventos (botões, barra de carregamento dinâmica, redimensionamento responsivo).
- **JSON:** Utilizado para armazenamento do arquivo de configuração externa e flexibilidade de regras.
- **PS2EXE:** Para conversão dos scripts PowerShell de forma nativa para formato `.exe` portável.

## ⚠️ Isenção de Responsabilidade

Esta ferramenta modifica chaves de registro e serviços vitais do sistema operacional. Embora criemos backups antes das execuções, o autor não se responsabiliza por eventuais falhas do sistema, incompatibilidade de hardware ou perda de dados resultantes do uso. Sempre verifique o que cada categoria desativa antes de clicar em "Otimizar".

---
*Desenvolvido para maximizar a performance da sua máquina de forma inteligente e direta.*
