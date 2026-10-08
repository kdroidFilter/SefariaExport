#!/usr/bin/env python3
"""
Run a narrow Sefaria export tailored to what the SefariaSqlite generator
actually consumes:

  * Only the JSON merged format (drop txt / cltk-full / cltk-flat).
  * Only the Hebrew (`he`) language (skip the English merged pass entirely).
  * Plus links / schemas / TOC.

The cuts are applied at the source (Sefaria's `export_formats` tuple and a
custom `export_all_merged` loop), so we save both disk IO and CPU compared
to running the full upstream export.
"""
import os
import sys
import traceback


def list_dir_limited(base: str) -> None:
    for root, dirs, files in os.walk(base):
        level = root.replace(base, '').count(os.sep)
        indent = ' ' * 2 * level
        print(f"{indent}{os.path.basename(root)}/")
        subindent = ' ' * 2 * (level + 1)
        for file in files[:10]:
            print(f"{subindent}{file}")
        if len(files) > 10:
            print(f"{subindent}... and {len(files) - 10} more files")
        if level > 2:
            break


def run_merged_export_he_only(ex) -> None:
    """Replacement for `ex.export_all_merged()` — Hebrew only.

    Mirrors the upstream loop (see sefaria/export.py::export_all_merged) but
    drops the English pass to halve the number of slow Mongo lookups and
    skip writes we don't need.
    """
    from sefaria.system.database import db
    from sefaria.model.text import Ref

    titles = db.texts.find().distinct("title")
    total = len(titles)
    print(f"📋 {total} distinct titles to export (he only)")

    written = skipped = errored = 0
    for idx, title in enumerate(titles, 1):
        if not title:
            continue
        try:
            Ref(title)
        except Exception:
            skipped += 1
            continue

        if idx % 100 == 0 or idx == total:
            print(f"  …{idx}/{total} (written={written}, skipped={skipped}, errors={errored})", flush=True)

        try:
            prepped = ex.prepare_merged_text_for_export(title, lang="he")
            if prepped:
                ex.write_text_doc_to_disk(prepped)
                written += 1
        except Exception as e:  # pragma: no cover
            errored += 1
            print(f"⚠️  {title}: {e}", flush=True)

    print(f"✅ merged export done: written={written}, skipped={skipped}, errors={errored}")


VERSION_FIELDS = (
    "title",
    "versionTitle",
    "versionTitleInHebrew",
    "versionSource",
    "license",
    "actualLanguage",
    "digitizedBySefaria",
)


def export_versions(export_base: str) -> None:
    """Write `versions.json`: the metadata of every Hebrew text version.

    `merged.json` only lists `[versionTitle, versionSource]` pairs and drops the
    license. Dumping the raw version records from the same Mongo snapshot lets
    the SefariaSqlite generator join them back exactly on
    (title, versionTitle). Values are written as-is (no license normalization):
    mapping Sefaria's free-text licenses is the generator's job.
    """
    import json
    from sefaria.system.database import db

    projection = {field: 1 for field in VERSION_FIELDS}
    projection["_id"] = 0
    records = [
        {field: doc.get(field) for field in VERSION_FIELDS}
        for doc in db.texts.find({"language": "he"}, projection)
    ]
    if not records:
        raise RuntimeError("no Hebrew version found in db.texts")
    records.sort(key=lambda r: (r["title"] or "", r["versionTitle"] or ""))

    path = os.path.join(export_base, "versions.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=1)
    print(f"✅ versions.json: {len(records)} Hebrew versions -> {path}")


AUTHOR_PROPERTIES = (
    "birthYear",
    "birthYearIsApprox",
    "deathYear",
    "deathYearIsApprox",
    "era",
)


def export_authors(export_base: str) -> None:
    """Write `authors.json`: the topic of every author referenced by an index.

    The schemas only carry each author's slug and primary names. This adds the
    Hebrew alternate titles (רעק"א, ראב"ע...) and the life data the app shows on
    an author card, from the same Mongo snapshot. Values are written as-is.
    """
    import json
    from sefaria.system.database import db

    slugs = sorted(s for s in db.index.distinct("authors") if isinstance(s, str) and s)
    records = []
    for doc in db.topics.find({"slug": {"$in": slugs}}, {"_id": 0, "slug": 1, "titles": 1, "properties": 1}):
        properties = doc.get("properties") or {}
        records.append({
            "slug": doc["slug"],
            "heTitles": [
                t["text"] for t in doc.get("titles") or []
                if t.get("lang") == "he" and t.get("text")
            ],
            **{name: (properties.get(name) or {}).get("value") for name in AUTHOR_PROPERTIES},
        })
    if not records:
        raise RuntimeError("no author topic found in db.topics")
    records.sort(key=lambda r: r["slug"])

    path = os.path.join(export_base, "authors.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=1)
    print(f"✅ authors.json: {len(records)}/{len(slugs)} author topics -> {path}")


def flatten_hebrew_dirs(export_base: str) -> None:
    """Move the contents of every `.../Hebrew/` directory one level up.

    Sefaria's `make_path` writes to `json/<cat>/<book>/Hebrew/merged.json`.
    The SefariaSqlite generator expects `json/<cat>/<book>/merged.json`, so
    we collapse the language layer in-place.
    """
    import shutil

    targets = []
    for root, dirs, _files in os.walk(export_base):
        for d in dirs:
            if d == "Hebrew":
                targets.append(os.path.join(root, d))

    print(f"📦 Flattening {len(targets)} Hebrew/ directories under {export_base}")
    for src in targets:
        parent = os.path.dirname(src)
        for entry in os.listdir(src):
            shutil.move(os.path.join(src, entry), os.path.join(parent, entry))
        try:
            os.rmdir(src)
        except OSError:
            pass


def main() -> int:
    workspace = os.environ.get('GITHUB_WORKSPACE', os.getcwd())
    proj_dir = os.path.join(workspace, 'Sefaria-Project')
    sys.path.insert(0, os.path.abspath(proj_dir))
    os.chdir(proj_dir)

    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "sefaria.settings")

    export_base = os.path.join(workspace, 'exports')
    os.environ["SEFARIA_EXPORT_PATH"] = export_base

    print(f"📁 Export base directory: {export_base}")
    print(f"📁 Current working directory: {os.getcwd()}")

    import django
    django.setup()

    from django.conf import settings
    print(f"📋 Django SEFARIA_EXPORT_PATH: {getattr(settings, 'SEFARIA_EXPORT_PATH', 'NOT SET')}")

    from sefaria import export as ex

    # Drop txt / cltk-full / cltk-flat formats at the source. This also
    # saves the CPU spent by make_cltk_* on every book.
    print(f"🪓 Restricting export_formats from {[f[0] for f in ex.export_formats]} -> ['json']")
    ex.export_formats = (('json', ex.make_json),)

    try:
        print("\n" + "="*60)
        print("▶️  Running merged export (Hebrew + JSON only)")
        print("="*60)
        run_merged_export_he_only(ex)

        for fn_name in ("export_links", "export_schemas", "export_toc"):
            print(f"\n{'='*60}\n▶️  Running {fn_name}...\n{'='*60}")
            getattr(ex, fn_name)()
            print(f"✅ {fn_name} completed")

        print(f"\n{'='*60}\n▶️  Running export_versions...\n{'='*60}")
        export_versions(export_base)

        print(f"\n{'='*60}\n▶️  Running export_authors...\n{'='*60}")
        export_authors(export_base)
    except Exception as e:  # pragma: no cover
        print(f"❌ export step failed: {e}")
        traceback.print_exc()
        return 1

    # Collapse `json/<cat>/<book>/Hebrew/` -> `json/<cat>/<book>/` to match
    # the layout the SefariaSqlite generator expects.
    flatten_hebrew_dirs(export_base)

    print(f"\n📂 Final layout of {export_base}:")
    if os.path.isdir(export_base):
        list_dir_limited(export_base)

    print("\n✅ All exports completed successfully")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
