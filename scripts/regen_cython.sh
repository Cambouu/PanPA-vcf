#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYX_DIR="${ROOT_DIR}/PanPA"

if ! command -v cython >/dev/null 2>&1; then
  echo "Error: cython not found in PATH. Install Cython to regenerate .cpp files." >&2
  exit 1
fi

shopt -s nullglob
pyx_files=("${PYX_DIR}"/*.pyx)
if [ ${#pyx_files[@]} -eq 0 ]; then
  echo "No .pyx files found in ${PYX_DIR}" >&2
  exit 1
fi

for pyx in "${pyx_files[@]}"; do
  cpp="${pyx%.pyx}.cpp"
  cython -3 --cplus -o "${cpp}" "${pyx}"
  echo "Generated ${cpp##${ROOT_DIR}/}"
done
