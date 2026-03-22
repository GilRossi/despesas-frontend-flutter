# despesas_frontend

Cliente Flutter oficial do projeto **despesas**.

## Primeiro corte funcional

Esta V1 mobile implementa apenas:

- login
- restauração de sessão
- refresh token
- lista read-only de despesas
- detalhe read-only de despesa
- histórico read-only de pagamentos no detalhe
- logout

O backend continua como fonte de verdade. Nenhuma regra financeira foi movida para o app.

## Baseline visual

Toda tela atual e futura deve respeitar esta premissa:

- sem overflow visual, faixa amarela/preta ou clipping
- segura com teclado aberto
- segura em altura reduzida
- `SafeArea` e rolagem quando o viewport encolher

## Configuração

O app usa `--dart-define` para ambiente e URL da API. A URL agora e obrigatoria e deve vir do ambiente governado:

```bash
scripts/run_local_web.sh
```

Build oficial do Flutter Web para o front-door:

```bash
scripts/build_local_web.sh
```

Em device físico Android, carregue `~/envs/despesas/local/backend.env`, ajuste `API_BASE_URL` para o IP LAN do backend e rode o `flutter run` com os mesmos `--dart-define`.

Se o backend local estiver na mesma máquina do Android conectado via ADB, use o helper governado:

```bash
scripts/run_local_android.sh
```

O script aplica `adb reverse` para a porta da API configurada e sobe o app com os `--dart-define` oficiais.

## Comandos úteis

```bash
flutter pub get
flutter analyze
flutter test
```

Smoke real contra o backend:

```bash
scripts/run_local_smoke.sh
```
