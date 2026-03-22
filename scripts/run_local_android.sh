#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

# shellcheck source=/dev/null
source "${script_dir}/load_governed_env.sh" local

if ! command -v adb >/dev/null 2>&1; then
  echo "adb nao encontrado no PATH." >&2
  exit 1
fi

port="$(python3 - <<'PY'
from urllib.parse import urlparse
import os
parsed = urlparse(os.environ["API_BASE_URL"])
print(parsed.port or (443 if parsed.scheme == "https" else 80))
PY
)"

if ! adb get-state >/dev/null 2>&1; then
  echo "Nenhum device Android conectado para adb reverse." >&2
  exit 1
fi

adb reverse "tcp:${port}" "tcp:${port}" >/dev/null

cd "${repo_root}"
exec flutter run \
  --dart-define=APP_ENV="${APP_ENV}" \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  "$@"
