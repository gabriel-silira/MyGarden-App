# MyGarden

Projeto pessoal para acompanhar plantas e organizar os cuidados com um jardim, reunindo o aplicativo Flutter e o espaço para o futuro firmware Arduino/ESP32.

## Organização

```text
app/        Aplicativo Flutter para Android, com suporte web para testes
firmware/   Código do Arduino/ESP32, ainda não implementado
```

## O que funciona hoje

- Cadastro, edição e remoção de plantas.
- Umidade do solo e temperatura simuladas, com gráficos e histórico da sessão.
- Irrigação manual e automática simuladas, com limites por planta.
- Temas claro, escuro e do sistema.
- Salvamento local dos cadastros e preferências.

**O aplicativo ainda funciona inteiramente em simulação.** Não recebe leituras de sensores físicos nem aciona uma bomba real. O histórico recomeça a cada sessão e não há monitoramento em segundo plano.

## Executar o aplicativo

Com Flutter instalado e um dispositivo Android conectado:

```bash
cd app
flutter pub get
flutter run
```

Os comandos Flutter devem ser executados dentro de `app/`. Consulte o [README do aplicativo](app/README.md) para mais detalhes.

## Integração futura

O objetivo é integrar o aplicativo a um sistema físico com Arduino/ESP32, sensores e irrigação. O protocolo de comunicação e o acionamento real ainda serão desenvolvidos e validados. A pasta [firmware/](firmware/README.md) está reservada para essa parte do projeto.
