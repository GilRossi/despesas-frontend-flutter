#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

# shellcheck source=/dev/null
source "${script_dir}/load_governed_env.sh" local

cd "${repo_root}"
exec flutter run \
  -d chrome \
  --dart-define=APP_ENV="${APP_ENV}" \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  "$@"
