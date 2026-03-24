# Prova local do mobile companion

Esta prova existe para demonstrar, em device Android real conectado por ADB:

- login mobile real
- navegacao critica minima
- fluxo curto de dominio
- restauracao de sessao ou retorno claro ao login em nova execucao
- evidencia visual real com screenshots

## Pre-requisitos

- backend local acessivel pela `API_BASE_URL` governada
- device Android conectado via `adb`
- Flutter, `curl`, `jq`, `python3` e `timeout`
- envs locais governados em `~/envs/despesas/local`

## Execucao

No repositório Flutter:

```bash
scripts/run_mobile_e2e_proof.sh
```

O runner:

1. carrega o ambiente governado local
2. detecta um device Android real via `flutter devices --machine`
3. aplica `adb reverse` para a porta do backend
4. faz bootstrap de um `OWNER` exclusivo via API real
5. executa a fase `login-flow` no app mobile
6. executa a fase `restore-session` em nova inicializacao do app
7. grava screenshots e respostas estruturadas em `build/mobile_e2e/`

## Evidencias

- screenshots: `build/mobile_e2e/screenshots`
- resposta da fase de login: `build/mobile_e2e/mobile_login_flow_response.json`
- resposta da fase de restauracao: `build/mobile_e2e/mobile_restore_session_response.json`
- resumo simples: `build/mobile_e2e/proof-summary.json`

## Observacoes

- a prova nao relaxa auth nem tenancy
- o bootstrap usa apenas APIs reais do backend local
- a fase `restore-session` registra o estado inicial da nova abertura do app:
  - se a sessao for preservada, a captura mostra a home autenticada
  - se o ciclo local do `flutter drive` iniciar o app limpo, a captura mostra o retorno explicito ao login
- se nao houver device Android conectado, o runner falha explicitamente
