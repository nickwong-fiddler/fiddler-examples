#!/usr/bin/env bash
#
# setup_envs.sh — Create per-notebook uv virtual environments, install
# dependencies, and register Jupyter kernels.
#
# Usage:
#   ./setup_envs.sh                              # set up all notebooks
#   ./setup_envs.sh custom_judge_evaluators      # set up just one (by requirements filename, without .txt)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIREMENTS_DIR="${SCRIPT_DIR}/requirements"
VENVS_DIR="${SCRIPT_DIR}/.venvs"
PYTHON_VERSION="3.11"

# ---------- helpers ----------

setup_env() {
    local req_file="$1"
    local name
    name="$(basename "${req_file}" .txt)"

    local venv_dir="${VENVS_DIR}/${name}"
    local python_bin="${venv_dir}/bin/python"

    # Pretty display name: replace underscores with spaces, title-case each word
    local display_name
    display_name="Fiddler Cookbook: $(echo "${name}" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"

    echo "=============================================="
    echo "  Setting up: ${name}"
    echo "  Display name: ${display_name}"
    echo "=============================================="

    # 1. Create virtual environment
    if [ -d "${venv_dir}" ]; then
        echo "  -> venv already exists, skipping creation"
    else
        echo "  -> Creating venv with Python ${PYTHON_VERSION} ..."
        uv venv "${venv_dir}" --python "${PYTHON_VERSION}"
    fi

    # 2. Install dependencies
    echo "  -> Installing dependencies from ${req_file} ..."
    uv pip install -r "${req_file}" --python "${python_bin}"

    # 3. Register Jupyter kernel
    echo "  -> Registering Jupyter kernel '${name}' ..."
    "${python_bin}" -m ipykernel install --user --name "${name}" --display-name "${display_name}"

    echo "  -> Done: ${name}"
    echo ""
}

# ---------- main ----------

if ! command -v uv &>/dev/null; then
    echo "Error: 'uv' is not installed or not in PATH."
    echo "Install it with:  curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

mkdir -p "${VENVS_DIR}"

if [ $# -gt 0 ]; then
    # Set up only the specified environment(s)
    for target in "$@"; do
        req_file="${REQUIREMENTS_DIR}/${target}.txt"
        if [ ! -f "${req_file}" ]; then
            echo "Error: requirements file not found: ${req_file}"
            echo "Available environments:"
            ls "${REQUIREMENTS_DIR}" | sed 's/\.txt$//'
            exit 1
        fi
        setup_env "${req_file}"
    done
else
    # Set up all environments
    for req_file in "${REQUIREMENTS_DIR}"/*.txt; do
        setup_env "${req_file}"
    done
fi

echo "=============================================="
echo "  All done!"
echo ""
echo "  To use a notebook, open it and select the"
echo "  matching Jupyter kernel (e.g. 'Fiddler Cookbook: Custom Judge Evaluators')."
echo "=============================================="
