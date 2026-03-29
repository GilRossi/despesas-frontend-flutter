#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
backend_repo="${BACKEND_REPO_ROOT:-/home/gil/workspace/claude/despesas}"
artifacts_dir="${repo_root}/build/mobile_e2e"
screenshots_dir="${artifacts_dir}/screenshots"
driver_log="${artifacts_dir}/flutter-drive.log"

mkdir -p "${screenshots_dir}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command adb
require_command curl
require_command flutter
require_command jq
require_command python3
require_command timeout

# shellcheck source=/dev/null
source "${script_dir}/load_governed_env.sh" local

device_id="${PROOF_MOBILE_DEVICE_ID:-$(
  flutter devices --machine \
    | jq -r '.[] | select(.targetPlatform | startswith("android")) | .id' \
    | head -n 1
)}"

if [[ -z "${device_id}" ]]; then
  echo "Nenhum device Android disponivel para a prova mobile." >&2
  exit 1
fi

api_port="$(
  python3 - <<'PY'
from urllib.parse import urlparse
import os
parsed = urlparse(os.environ["API_BASE_URL"])
print(parsed.port or (443 if parsed.scheme == "https" else 80))
PY
)"

ensure_backend() {
  local base_url_host
  base_url_host="$(
    python3 - <<'PY'
from urllib.parse import urlparse
import os
print(urlparse(os.environ["API_BASE_URL"]).hostname or "")
PY
  )"

  if curl -fsS "${API_BASE_URL}/actuator/health" >/dev/null 2>&1; then
    return 0
  fi

  if [[ "${base_url_host}" != "localhost" && "${base_url_host}" != "127.0.0.1" ]]; then
    echo "Backend indisponivel em ${API_BASE_URL} e o host nao e local." >&2
    exit 1
  fi

  (
    cd "${backend_repo}"
    nohup scripts/proof/run_local_backend.sh \
      >"${artifacts_dir}/backend.log" 2>&1 &
    echo $! > "${artifacts_dir}/backend.pid"
  )

  for _ in $(seq 1 90); do
    if curl -fsS "${API_BASE_URL}/actuator/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "Timed out waiting for backend at ${API_BASE_URL}" >&2
  exit 1
}

fail_with_body_args=()
if curl --help all 2>/dev/null | grep -q -- '--fail-with-body'; then
  fail_with_body_args+=(--fail-with-body)
else
  fail_with_body_args+=(--fail)
fi

api_post() {
  local url="$1"
  local body="$2"
  local token="${3:-}"

  if [[ -n "${token}" ]]; then
    curl "${fail_with_body_args[@]}" -sS -X POST "${url}" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer ${token}" \
      -d "${body}"
    return
  fi

  curl "${fail_with_body_args[@]}" -sS -X POST "${url}" \
    -H 'Content-Type: application/json' \
    -d "${body}"
}

ensure_backend

adb -s "${device_id}" get-state >/dev/null
adb -s "${device_id}" reverse "tcp:${api_port}" "tcp:${api_port}" >/dev/null

proof_run_id="${PROOF_RUN_ID:-$(date +%s)}"
owner_email="owner-mobile-${proof_run_id}@local.invalid"
owner_password="${PROOF_OWNER_PASSWORD:-senha123}"
household_name="Household Mobile ${proof_run_id}"

admin_login_response="$(
  api_post \
    "${API_BASE_URL}/api/v1/auth/login" \
    "$(jq -nc --arg email "${APP_BOOTSTRAP_PLATFORM_ADMIN_EMAIL}" --arg password "${APP_BOOTSTRAP_PLATFORM_ADMIN_PASSWORD}" '{email:$email,password:$password}')"
)"
admin_token="$(printf '%s' "${admin_login_response}" | jq -r '.data.accessToken')"

api_post \
  "${API_BASE_URL}/api/v1/admin/households" \
  "$(jq -nc --arg householdName "${household_name}" --arg ownerName 'Owner Mobile Proof' --arg ownerEmail "${owner_email}" --arg ownerPassword "${owner_password}" '{householdName:$householdName,ownerName:$ownerName,ownerEmail:$ownerEmail,ownerPassword:$ownerPassword}')" \
  "${admin_token}" \
  >/dev/null

define_file="$(mktemp)"
cleanup() {
  rm -f "${define_file}"
}
trap cleanup EXIT

cat > "${define_file}" <<EOF
{
  "APP_ENV": "local-mobile-proof",
  "API_BASE_URL": "${API_BASE_URL}",
  "PROOF_RUN_ID": "${proof_run_id}",
  "PROOF_OWNER_EMAIL": "${owner_email}",
  "PROOF_OWNER_PASSWORD": "${owner_password}",
  "PROOF_TEXT_SCALE_FACTOR": "1.3"
}
EOF
chmod 600 "${define_file}"

run_phase() {
  local phase="$1"
  local output_name="$2"

  PROOF_OUTPUT_DIR="${artifacts_dir}" \
  PROOF_OUTPUT_NAME="${output_name}" \
  PROOF_SCREENSHOTS_DIR="${screenshots_dir}" \
  timeout --signal=TERM "${PROOF_ATTEMPT_TIMEOUT_SECONDS:-240}" flutter drive \
    --driver=test_driver/mobile_companion_proof.dart \
    --target=integration_test/mobile_companion_proof_test.dart \
    -d "${device_id}" \
    --no-dds \
    --use-application-binary="${android_apk}" \
    --dart-define-from-file="${define_file}" \
    --dart-define="PROOF_PHASE=${phase}" | tee -a "${driver_log}"
}

cd "${repo_root}"
flutter pub get

echo "Construindo APK de prova com defines do mobile e2e..."
flutter build apk --debug \
  --dart-define-from-file="${define_file}"

android_apk="${PROOF_ANDROID_APK:-${repo_root}/build/app/outputs/flutter-apk/app-debug.apk}"
if [[ ! -f "${android_apk}" ]]; then
  alt_android_apk="${repo_root}/build/app/outputs/apk/debug/app-debug.apk"
  if [[ -f "${alt_android_apk}" ]]; then
    android_apk="${alt_android_apk}"
  else
    echo "APK precompilado nao encontrado. Defina PROOF_ANDROID_APK ou gere um debug APK primeiro." >&2
    exit 1
  fi
fi

: > "${driver_log}"
run_phase "login-flow" "mobile_login_flow_response"
run_phase "restore-session" "mobile_restore_session_response"

jq -n \
  --arg runId "${proof_run_id}" \
  --arg deviceId "${device_id}" \
  --arg apiBaseUrl "${API_BASE_URL}" \
  --arg screenshotsDir "${screenshots_dir}" \
  --slurpfile loginFlow "${artifacts_dir}/mobile_login_flow_response.json" \
  --slurpfile restoreFlow "${artifacts_dir}/mobile_restore_session_response.json" \
  '{
    runId: $runId,
    deviceId: $deviceId,
    apiBaseUrl: $apiBaseUrl,
    screenshotsDir: $screenshotsDir,
    loginFlow: $loginFlow[0],
    restoreFlow: $restoreFlow[0]
  }' > "${artifacts_dir}/proof-summary.json"

cat "${artifacts_dir}/proof-summary.json"
