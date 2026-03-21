# despesas_frontend

Cliente Flutter oficial do projeto **despesas**.

## Primeiro corte funcional

Esta V1 mobile implementa apenas:

- login
- restauração de sessão
- refresh token
- lista read-only de despesas
- logout

O backend continua como fonte de verdade. Nenhuma regra financeira foi movida para o app.

## Configuração

O app usa `--dart-define` para ambiente e URL da API:

```bash
flutter run \
  --dart-define=APP_ENV=local \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Em device físico Android, use o IP LAN da máquina que está rodando o backend, por exemplo:

```bash
flutter run \
  --dart-define=APP_ENV=local \
  --dart-define=API_BASE_URL=http://192.168.31.94:8080
```

Se nenhum `API_BASE_URL` for informado, o app usa defaults locais por plataforma.

## Comandos úteis

```bash
flutter pub get
flutter analyze
flutter test
```

Smoke real contra o backend:

```bash
API_BASE_URL=http://127.0.0.1:8080 dart run tool/smoke_real.dart
```
