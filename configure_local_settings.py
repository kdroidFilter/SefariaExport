#!/usr/bin/env python3
"""
Configure Sefaria local_settings.py based on environment variables.

Expected working directory: Sefaria-Project/sefaria

Env used:
- SEFARIA_EXPORT_BASE (path written to SEFARIA_EXPORT_PATH)
- MONGO_HOST (default: 127.0.0.1)
- MONGO_PORT (default: 27017)
- MONGO_DB_NAME (default: sefaria)

"""
import os
import re


def main() -> None:
    p = "local_settings.py"
    with open(p, "r", encoding="utf-8") as f:
        s = f.read()

    export_path = os.environ.get("SEFARIA_EXPORT_PATH", os.environ.get("SEFARIA_EXPORT_BASE", ""))
    s = re.sub(r"SEFARIA_EXPORT_PATH\s*=.*", f'SEFARIA_EXPORT_PATH = r"{export_path}"', s)
    s = re.sub(r"MONGO_HOST\s*=.*", f'MONGO_HOST = "{os.environ.get("MONGO_HOST", "127.0.0.1")}"', s)
    s = re.sub(r"MONGO_PORT\s*=.*", f'MONGO_PORT = {int(os.environ.get("MONGO_PORT", "27017"))}', s)
    s = re.sub(r"MONGO_DB_NAME\s*=.*", f'MONGO_DB_NAME = "{os.environ.get("MONGO_DB_NAME", "sefaria")}"', s)

    if re.search(r"SEFARIA_DB\s*=", s):
        s = re.sub(r"SEFARIA_DB\s*=.*", 'SEFARIA_DB = "sefaria"', s)
    else:
        s += '\nSEFARIA_DB = "sefaria"\n'

    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

    print("✅ local_settings.py configured")
    print(f"   SEFARIA_EXPORT_PATH = {export_path}")


if __name__ == "__main__":
    main()
