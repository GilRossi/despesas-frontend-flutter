#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
cache_root="${XDG_CACHE_HOME:-${HOME}/.cache}/despesas-frontend-local-proof"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command curl
require_command unzip
require_command flutter
require_command google-chrome
require_command timeout

required_vars=(
  API_BASE_URL
  PROOF_OWNER_EMAIL
  PROOF_OWNER_PASSWORD
  PROOF_MEMBER_EMAIL
  PROOF_MEMBER_PASSWORD
)

for variable_name in "${required_vars[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Missing required environment variable: ${variable_name}" >&2
    exit 1
  fi
done

proof_run_id="${PROOF_RUN_ID:-$(date +%s)}"
browser_mode="${PROOF_BROWSER_MODE:-$([[ -n "${DISPLAY:-}" ]] && printf 'headed' || printf 'headless')}"
max_attempts="${PROOF_MAX_ATTEMPTS:-4}"
attempt_timeout_seconds="${PROOF_ATTEMPT_TIMEOUT_SECONDS:-120}"
define_file="$(mktemp)"
chromedriver_pid=""

browser_args=()
if [[ "${browser_mode}" == "headed" ]]; then
  browser_args+=(--no-headless)
fi

ensure_chromedriver() {
  local chrome_version chrome_major driver_root zip_path extracted_dir driver_bin
  chrome_version="$(google-chrome --version | awk '{print $3}')"
  chrome_major="${chrome_version%%.*}"
  driver_root="${cache_root}/chromedriver/${chrome_version}"
  extracted_dir="${driver_root}/chromedriver-linux64"
  driver_bin="${extracted_dir}/chromedriver"

  if [[ ! -x "${driver_bin}" ]]; then
    mkdir -p "${driver_root}"
    zip_path="${driver_root}/chromedriver-linux64.zip"
    curl -fsSL \
      "https://storage.googleapis.com/chrome-for-testing-public/${chrome_version}/linux64/chromedriver-linux64.zip" \
      -o "${zip_path}"
    rm -rf "${extracted_dir}"
    unzip -oq "${zip_path}" -d "${driver_root}"
    chmod +x "${driver_bin}"
  fi

  if pgrep -f "${cache_root}/chromedriver/.*/chromedriver --port=4444" >/dev/null 2>&1; then
    pkill -f "${cache_root}/chromedriver/.*/chromedriver --port=4444" >/dev/null 2>&1 || true
    sleep 1
  fi

  "${driver_bin}" --port=4444 >/tmp/despesas-frontend-chromedriver.log 2>&1 &
  chromedriver_pid="$!"

  for _ in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:4444/status >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "Unable to start chromedriver for Chrome ${chrome_major}" >&2
  exit 1
}

cleanup() {
  rm -f "${define_file}"
  if [[ -n "${chromedriver_pid}" ]] && kill -0 "${chromedriver_pid}" >/dev/null 2>&1; then
    kill "${chromedriver_pid}" >/dev/null 2>&1 || true
    wait "${chromedriver_pid}" 2>/dev/null || true
  fi
}

trap cleanup EXIT

cat > "${define_file}" <<EOF
{
  "APP_ENV": "local-proof",
  "API_BASE_URL": "${API_BASE_URL}",
  "PROOF_RUN_ID": "${proof_run_id}",
  "PROOF_OWNER_EMAIL": "${PROOF_OWNER_EMAIL}",
  "PROOF_OWNER_PASSWORD": "${PROOF_OWNER_PASSWORD}",
  "PROOF_MEMBER_EMAIL": "${PROOF_MEMBER_EMAIL}",
  "PROOF_MEMBER_PASSWORD": "${PROOF_MEMBER_PASSWORD}"
}
EOF
chmod 600 "${define_file}"

cd "${repo_root}"
flutter pub get

attempt=1
while (( attempt <= max_attempts )); do
  ensure_chromedriver
  output_file="$(mktemp)"
  set +e
  timeout --signal=TERM "${attempt_timeout_seconds}" flutter drive \
    --driver=test_driver/local_e2e_proof.dart \
    --target=integration_test/local_e2e_proof_test.dart \
    -d chrome \
    --browser-dimension=390x844@1 \
    "${browser_args[@]}" \
    --dart-define-from-file="${define_file}" 2>&1 | tee "${output_file}"
  exit_code="${PIPESTATUS[0]}"
  set -e

  if (( exit_code == 0 )); then
    rm -f "${output_file}"
    exit 0
  fi

  if (( attempt < max_attempts )) && {
    grep -q "AppConnectionException" "${output_file}" || (( exit_code == 124 ));
  }; then
    rm -f "${output_file}"
    if [[ -n "${chromedriver_pid}" ]] && kill -0 "${chromedriver_pid}" >/dev/null 2>&1; then
      kill "${chromedriver_pid}" >/dev/null 2>&1 || true
      wait "${chromedriver_pid}" 2>/dev/null || true
      chromedriver_pid=""
    fi
    attempt=$((attempt + 1))
    sleep 2
    continue
  fi

  rm -f "${output_file}"
  exit "${exit_code}"
done
