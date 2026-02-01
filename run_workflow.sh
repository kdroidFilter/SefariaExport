#!/bin/bash
set -e

echo "=========================================="
echo "Starting Sefaria Export Workflow"
echo "=========================================="
echo "Environment:"
echo "  - TZ_NAME: ${TZ_NAME:-Asia/Jerusalem}"
echo "  - MONGO_HOST: ${MONGO_HOST:-127.0.0.1}"
echo "  - MONGO_PORT: ${MONGO_PORT:-27017}"
echo "  - MONGO_DB_NAME: ${MONGO_DB_NAME:-sefaria}"
echo "=========================================="

# Array of all steps in order
steps=(
    "01_compute_timestamp.sh"
    "02_install_base_tools.sh"
    "03_install_mongo_tools.sh"
    "04_download_small_dump.sh"
    "05_clone_sefaria_project.sh"
    "06_install_build_deps.sh"
    "07_pip_install_requirements.sh"
    "09_create_exports_dir.sh"
    "10_create_local_settings.sh"
    "11_wait_for_mongodb.sh"
    "12_restore_db_from_dump.sh"
    "13_check_export_module.sh"
    "14_run_exports.sh"
    "15_verify_exports.sh"
    "16_drop_db.sh"
    "17a_remove_english_in_exports.sh"
    "17b_flatten_hebrew_in_exports.sh"
    "17_build_combined_archive.sh"
    "18_split_archive.sh"
)

# Optional GitHub release steps (only if GH_TOKEN is set)
if [ -n "${GH_TOKEN:-}" ]; then
    steps+=("19_ensure_gh_cli.sh")
    steps+=("20_create_or_update_release.sh")
    steps+=("21_upload_release_assets.sh")
    echo "ℹ️  GitHub token detected - will create release"
else
    echo "ℹ️  No GitHub token - skipping release creation"
fi

# Execute each step
step_num=0
total_steps=${#steps[@]}

for step in "${steps[@]}"; do
    step_num=$((step_num + 1))
    echo ""
    echo "=========================================="
    echo "Step $step_num/$total_steps: $step"
    echo "=========================================="
    
    if [ -f "/workspace/$step" ]; then
        # Special handling for pip install with fallback
        if [ "$step" == "07_pip_install_requirements.sh" ]; then
            if ! bash "/workspace/$step"; then
                echo "⚠️  Pip install failed, running fallback..."
                bash "/workspace/08_fallback_built_google_re2.sh"
            fi
        else
            bash "/workspace/$step"
        fi
    else
        echo "❌ ERROR: Script not found: $step"
        exit 1
    fi
done

# Load timestamp for final message
TS_ENV_FILE="${GITHUB_WORKSPACE:-$PWD}/ts_env.sh"
if [ -f "${TS_ENV_FILE}" ]; then
    source "${TS_ENV_FILE}"
fi

echo ""
echo "=========================================="
echo "✅ Workflow completed successfully!"
echo "=========================================="
echo ""
echo "📁 Export files: /workspace/exports"
echo "📦 Release archives: /workspace/releases"
if [ -n "${TS_STAMP:-}" ]; then
    echo "🏷️  Release tag: ${TS_STAMP}"
fi
echo ""
echo "To access the files from your host machine:"
echo "  - exports/    (mapped to ./exports/)"
echo "  - releases/   (mapped to ./releases/)"
echo "=========================================="
