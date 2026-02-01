SefariaExport
==============

An automated, reproducible pipeline to build Sefaria exports from a MongoDB dump using the official Sefaria-Project exporter, and publish the resulting archives as GitHub Releases.

This repository is a collection of small, composable Bash and Python scripts that:
- Prepare a build environment (tools, Python, MongoDB Database Tools)
- Download a small sample MongoDB dump for quick end-to-end runs
- Clone the upstream `Sefaria-Project` repository and install its dependencies
- Restore the database, run the exporters, verify results
- Package, post-process, and split the archives
- Optionally create a GitHub Release and upload the generated assets


## 🚀 Quick Start with Docker (Recommended)

The easiest way to run this pipeline is using Docker. No need to install MongoDB, Python, or other dependencies manually!

### Prerequisites
- Docker Desktop installed and running
- At least 20GB free disk space

### Run on Windows
```cmd
check_requirements.bat
run_local.bat
```

### Run on Linux/Mac
```bash
chmod +x check_requirements.sh run_local.sh
./check_requirements.sh
./run_local.sh
```

### What happens?
1. MongoDB starts in a Docker container
2. All export steps run automatically
3. Results are saved to `./exports/` and `./releases/`

📖 **For detailed instructions including GitHub token setup, see [QUICKSTART.md](QUICKSTART.md)**


Contents
--------
- Top-level scripts `01_...` to `21_...` implement each step in the pipeline, designed to be run sequentially.
- Supporting Python utilities:
  - `configure_local_settings.py`
  - `ensure_history_collection.py`
  - `run_exports.py`
  - `check_export_module.py`
- **Docker files**:
  - `Dockerfile` - Build environment
  - `docker-compose.yml` - Service orchestration
  - `run_workflow.sh` - Main workflow runner
  - `run_local.bat` / `run_local.sh` - Easy launchers
- GitHub Actions workflow: `.github/workflows/release.yml` for CI-driven builds and releases.


## Running Options

### Option 1: Docker (Recommended)
See [Quick Start with Docker](#-quick-start-with-docker-recommended) above.

### Option 2: GitHub Actions
The workflow at `.github/workflows/release.yml` provides a full CI pipeline. Trigger it manually (workflow_dispatch) or configure schedules/conditions as desired.

### Option 3: Manual Local Setup
For advanced users who want to run without Docker.

Prerequisites (manual local setup)
----------------------------------
You can run the pipeline on Linux or macOS. The GitHub Actions workflow shows a fully automated reference run. For a local run, install or ensure access to:

- Bash and coreutils
- Python 3.9 (to mirror CI) with `pip`
- Git, curl, unzip, jq
- MongoDB Database Tools (for `mongorestore`)
- A running MongoDB instance on `localhost:27017`
  - Quick start with Docker: `docker run --rm -p 27017:27017 --name mongo mongo:7`

The scripts will attempt to install/prepare some tools automatically, but having the above ready smooths the process.


Quick Start (manual local setup)
---------------------------------
The scripts are designed to be executed in order. A minimal local end-to-end run using the small sample dump looks like this:

1) Compute a timestamp used for naming artifacts
```
bash 01_compute_timestamp.sh
```

2) Install base tools (curl, jq, unzip, etc.)
```
bash 02_install_base_tools.sh
```

3) Install MongoDB Database Tools (mongorestore)
```
bash 03_install_mongo_tools.sh
```

4) Download a small MongoDB dump suitable for quick tests
```
bash 04_download_small_dump.sh
```

5) Clone the upstream Sefaria codebase
```
bash 05_clone_sefaria_project.sh
```

6) Install build dependencies and Python requirements
```
bash 06_install_build_deps.sh
bash 07_pip_install_requirements.sh
```

7) Fallback build for Google RE2 (only if needed by your environment)
```
bash 08_fallback_built_google_re2.sh
```

8) Prepare local project settings and export directories
```
bash 09_create_exports_dir.sh
bash 10_create_local_settings.sh
```

9) Ensure MongoDB is up, then restore the sample dump
```
bash 11_wait_for_mongodb.sh
bash 12_restore_db_from_dump.sh
```

10) Sanity-check exporter module, run exports, verify outputs
```
bash 13_check_export_module.sh
bash 14_run_exports.sh
bash 15_verify_exports.sh
```

11) (Optional) Drop the database to free space
```
bash 16_drop_db.sh
```

12) Build and post-process archives
```
bash 17_build_combined_archive.sh
# Optional content processing helpers:
bash 17a_remove_english_in_exports.sh
bash 17b_flatten_hebrew_in_exports.sh
bash 18_split_archive.sh
```

13) (Optional) Create a GitHub Release and upload assets
```
bash 19_ensure_gh_cli.sh
bash 20_create_or_update_release.sh
bash 21_upload_release_assets.sh
```

Notes
- The scripts are idempotent where practical; if something fails, re-running from the last successful step is typically fine.
- By default, scripts assume `localhost:27017` for MongoDB. Adjust environment variables as needed if your setup differs.


Environment variables
---------------------
Some scripts accept environment variables to tweak behavior. Common ones include:

- `PYTHON_VERSION` – Pin a Python version (the CI uses 3.9)
- `MONGODB_URI` – Override the default MongoDB connection string (e.g., `mongodb://localhost:27017`)
- `GITHUB_TOKEN` – Personal Access Token with `repo` scope, required for release steps when running locally
- `RELEASE_TAG` / `RELEASE_NAME` – Override the computed tag/name for releases

Refer to each script for any additional, script-specific variables.


Docker Environment Variables
-----------------------------
When running with Docker, customize settings in `.env`:

```env
# Timezone for timestamps (IANA name)
TZ_NAME=Asia/Jerusalem

# Optional: GitHub token for creating releases
# GH_TOKEN=your_github_token_here
```

The following are set automatically by docker-compose:
- `MONGO_HOST=mongodb` (container name)
- `MONGO_PORT=27017`
- `MONGO_DB_NAME=sefaria`
- `DJANGO_SETTINGS_MODULE=sefaria.settings`


Running in GitHub Actions
-------------------------
The workflow at `.github/workflows/release.yml` provides a full CI pipeline that:
- Spins up a MongoDB service
- Runs the numbered scripts in sequence
- Packages artifacts
- Creates/updates a release and uploads artifacts

Trigger it manually (workflow_dispatch) or configure schedules/conditions as desired. The workflow expects default permissions or a token with sufficient rights to create releases.


Troubleshooting
---------------
- MongoDB connection errors: ensure MongoDB is listening on `localhost:27017` and reachable. If using Docker, check the container logs and port mapping.
- `mongorestore` not found: re-run `03_install_mongo_tools.sh` or install MongoDB Database Tools from MongoDB’s official distribution.
- Python build issues (e.g., `re2`): run `08_fallback_built_google_re2.sh` to build a compatible wheel as a fallback.
- Exporter module not found: run `05_clone_sefaria_project.sh` and `07_pip_install_requirements.sh` again, then `13_check_export_module.sh`.


Project goals and scope
-----------------------
This repository focuses on orchestration and reproducibility of Sefaria exports. It does not modify Sefaria content or implement the exporter itself; those come from the upstream `Sefaria-Project`.


License
-------
This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). See `LICENSE` for details.
