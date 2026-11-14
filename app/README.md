# MyGarden — Aplicativo

Aplicativo desenvolvido em Flutter para acompanhar plantas e organizar os cuidados com um jardim. Projeto de uso pessoal, com foco em Android.

## Funcionalidades atuais

- Cadastro, edição e remoção de plantas.
- Escolha e alteração do ícone da planta entre hortelã, cidreira e cebolinha.
- Visão geral do jardim com umidade do solo e temperatura simuladas.
- Monitoramento com gráficos e histórico da sessão.
- Irrigação manual e automática em modo de simulação, com limites configuráveis por planta.
- Configuração do nome do jardim e exibição da temperatura.
- Temas claro, escuro e do sistema, com ícones e tela de carregamento.
- Salvamento local dos cadastros e preferências.

**A versão atual funciona inteiramente em simulação.** Ainda não recebe dados de sensores nem aciona uma bomba real. A irrigação automática é avaliada ao atualizar as leituras; não há monitoramento em segundo plano. O histórico de leituras e irrigações recomeça a cada sessão.

## Integração futura com Arduino

Futuramente, o MyGarden será integrado a um sistema físico com Arduino/ESP32 e sensores, permitindo acompanhar dados reais das plantas e controlar a irrigação de verdade. A comunicação com o hardware e o acionamento da bomba ainda serão desenvolvidos e validados. O código será organizado em [firmware/](../firmware/README.md); essa parte ainda não foi implementada.

## Executar o projeto

Execute os comandos nesta pasta (`app/`), com o Flutter instalado e um dispositivo Android conectado:

```bash
flutter pub get
flutter run
```

Para executar os testes:

```bash
flutter test
```

O projeto também possui suporte web para testes da interface no computador.
