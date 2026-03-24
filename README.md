# despesas_frontend

Cliente Flutter oficial do ecossistema **despesas**.

## Papel deste repositório

- Flutter Web e o front-door oficial do produto
- Flutter Mobile e o companion oficial consumindo a mesma API
- o backend Spring Boot continua como fonte de verdade transacional
- nenhuma regra financeira critica e movida para o cliente

## Fluxos reais presentes hoje

O estado atual do codigo vai alem de um V1 mobile read-only. O app ja contem:

- login, restauracao de sessao, refresh token e logout
- lista, detalhe, criacao e edicao de despesas
- lancamento e visualizacao de pagamentos
- relatorios e indicadores consumindo a API oficial
- assistente financeiro conectado ao backend
- review operations para ingestoes de e-mail que exigem decisao humana
- gestao de membros do household
- tela de `PLATFORM_ADMIN` para provisionamento de household + owner

## Arquitetura cliente

- wiring manual em `lib/main.dart`
- `SessionController` coordena sessao, refresh e roteamento principal
- `DespesasApp` alterna entre login, tela de platform admin e fluxo principal autenticado
- cada feature segue o padrao `domain/`, `data/` e `presentation/`
- `API_BASE_URL` e obrigatoria em compile time via `--dart-define`

## Configuracao e runtime local

Helpers governados:

```bash
scripts/run_local_web.sh
scripts/build_local_web.sh
scripts/run_local_android.sh
scripts/run_local_smoke.sh
```

Regras importantes:

- os `dart-defines` oficiais vem de `~/envs/despesas/local/backend.env`
- `API_BASE_URL` precisa apontar para o backend correto no ambiente atual
- no Android fisico, o helper aplica `adb reverse` para a porta configurada
- o smoke local fala com backend real e depende de `SMOKE_EMAIL` e `SMOKE_PASSWORD`

## Web oficial e mobile companion

- o Flutter Web e o build oficial publicado para o front-door servido pelo backend
- o Flutter Mobile continua companion da mesma API, sem contrato separado
- o app nao carrega segredos de servidor; consome apenas a URL publica configurada no build

## CI/CD atual

Este repositório ja possui esteira real para Flutter Web:

- `Flutter CI`: instala dependencias, roda `flutter analyze`, `flutter test` e `flutter build web`
- `Flutter Web CD`: publica `build/web` na VPS em `/srv/despesas/frontend-web/current/`
- `Flutter Web Production Artifact`: gera o artefato de producao por `workflow_dispatch`

## Governanca operacional

Fluxo normal de publicacao:

1. branch
2. PR
3. merge em `main`
4. `Flutter Web CD` publica o build oficial
5. smoke governado confirma o front-door publico

O modo padrao nao deve depender de shell manual na VPS. Auditoria e deploy rotineiros devem ficar versionados e executados por GitHub Actions.

## Contrato atual de publicacao

- o build web e publicado separadamente do deploy do backend
- o backend continua servindo `/` a partir do diretório sincronizado na VPS
- ainda nao existe release atomica unica entre backend, Flutter Web e n8n
- por isso, compatibilidade entre API e build web depende de coordenacao entre os repositorios e de smoke pos-publicacao
- o smoke governado do Flutter Web precisa manter `GET /` em `200` e `GET /password-console.html` em `404`

## Baseline visual

Toda tela atual e futura deve respeitar estas premissas:

- sem overflow visual, faixa amarela/preta ou clipping
- segura com teclado aberto
- segura em altura reduzida
- `SafeArea` e rolagem quando o viewport encolher

## Comandos uteis

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://app.rossicompany.com.br
```
