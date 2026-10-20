"""Lossless, manifest-driven repository housekeeping.

The plan names individual files. No recursive removal, Git reset or clean.
Archive copies are SHA-256 verified before originals are unlinked. A concurrent
edit aborts that file rather than overwriting new work. Source and archive roots
are resolved and checked for every operation.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ENC = ROOT.parent / "ada_encyclopedia"
WORK = ROOT / "ada_run/git-cleanup-2026-10-20"
BACKUP = ENC / "captures/repository-cleanup/2026-10-20"
ARCHIVE = ENC / "captures/repository-reviews"
REVIEW_ROOTS = ("doc/book/iterations/", "doc/space/", "doc/reports/",
                "doc/book/export/", "doc/book/review-packages/", "doc/book/review-packets/")
EXPORT_ROOTS = ("output/", "reports_tmp/")
COPY_DIRS = {"before", "after", "evidence", "printed", "reconstruction", "reconstructed",
             "fault", "faults", "fault-injection", "negative", "negative-controls",
             "mutants", "runtime", "sources", "source_snapshot", "snapshots", "snapshot",
             "previous", "baseline", "bundle", "packages", "runs", "capture", "captures",
             "images", "tests", "test-results", "fixed", "broken", "download", "downloads",
             "archive", "archives"}
SOURCE_EXTENSIONS = {".md", ".gd", ".tscn", ".gdshader", ".tres", ".py", ".godot", ".sh",
                     ".ps1", ".js", ".mjs", ".cjs", ".ts", ".tsx", ".css", ".txt", ".csv",
                     ".cpp", ".cfg", ".ttf", ".save", ".res", ".gltf", ".blend", ".shape", ".scn"}
SOURCE_NAMES = {"contract.json", "expected.json", "plan.json", "lesson.json",
                "lineage.json", "brief.json", "config.json", ".gdignore",
                ".gitignore", ".gitattributes", "LICENSE"}
GENERATED_EXTENSIONS = {".html", ".json", ".diff", ".zip", ".svg", ".pdf", ".glb",
                        ".snapshot", ".index", ".patch"}
SCRATCH_FILES = {"-", ".rows.json", "None\uf022", "algorithms_commit_9afcaade.patch", "cand.tsv"}
EXTRA_GENERATED = {"commons/data/artifact_roles.json.before"} | {
    f"doc/book/handoffs/2026-09-23-writing-next/packages/{sequence}-review.zip"
    for sequence in ("boolean_surfaces", "graphtheory", "machinelearning",
                     "qfeplaboratory", "softbodies")
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def confined(base: Path, relative: str) -> Path:
    path = (base / relative).resolve()
    if not path.is_relative_to(base.resolve()) or path == base.resolve():
        raise ValueError(f"Path escapes intended directory: {relative}")
    # Review snapshots can contain nested source trees whose archive names exceed
    # Windows MAX_PATH. Validate the normal resolved path before adding the prefix.
    if os.name == "nt" and not str(path).startswith("\\\\?\\"):
        return Path("\\\\?\\" + str(path))
    return path


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args], cwd=ROOT, stderr=subprocess.PIPE)


def archive_reason(relative: str) -> str | None:
    """Conservative: authored code and prose stay, including lesson sources."""
    if relative in SCRATCH_FILES:
        return "root scratch/export file"
    if relative in EXTRA_GENERATED:
        return "generated handoff bundle or before copy"
    if relative.startswith(EXPORT_ROOTS):
        return "generated export"
    if not relative.startswith(REVIEW_ROOTS):
        return None
    parts = Path(relative).parts
    if any(part in COPY_DIRS or part.startswith(("fault-", "negative-", "before-", "after-"))
           for part in parts[3:-1]):
        return "review snapshot or test output"
    if Path(relative).suffix in SOURCE_EXTENSIONS or Path(relative).name in SOURCE_NAMES:
        return None
    return "rendered review, receipt or bundle"


def make_plan() -> None:
    snapshot = json.loads((BACKUP / "snapshot.json").read_text(encoding="utf-8"))
    assert snapshot["verified"]
    files = []
    kept = []
    for row in snapshot["files"]:
        reason = archive_reason(row["path"]) if row["status"] == "??" else None
        if reason:
            files.append({**row, "reason": reason})
        else:
            kept.append(row["path"])
    # Existing tracked content is deliberately untouched by this migration.
    plan = {"root": str(ROOT), "archive": str(ARCHIVE), "compatibility": "hard links",
            "files": files, "keep": kept}
    (WORK / "plan.json").write_text(json.dumps(plan, indent=2), encoding="utf-8")
    (BACKUP / "plan.json").write_text(json.dumps(plan, indent=2), encoding="utf-8")
    print(f"Plan: archive {len(files)} files; retain {len(kept)} source/authoring paths.")


def write_ignore() -> None:
    marker = "# BEGIN VERIFIED REVIEW ARCHIVE POLICY (2026-10-20)"
    ending = "# END VERIFIED REVIEW ARCHIVE POLICY"
    file = ROOT / ".gitignore"
    text = file.read_text(encoding="utf-8")
    if marker in text:
        start = text.index(marker)
        end = text.index(ending, start) + len(ending)
        text = text[:start] + text[end:].lstrip("\r\n")
    lines = [marker,
             "# Generated reviews live in ../ada_encyclopedia/captures/repository-reviews.",
             "# Local hard links retain old tool paths and review URLs. Authored code and",
             "# prose remain versioned. Existing tracked historical files stay tracked.",
             "# See doc/REPOSITORY_HOUSEKEEPING.md for backup, restore and verification."]
    # Only add exclusions. Do not broadly reopen ignored cache/addon folders
    # with **/ or source-extension negations.
    for base in REVIEW_ROOTS:
        for ext in sorted(GENERATED_EXTENSIONS):
            lines.append("/" + base + "**/*" + ext)
        for name in sorted(SOURCE_NAMES):
            if Path(name).suffix in GENERATED_EXTENSIONS:
                lines.append("!/" + base + "**/" + name)
        for folder in sorted(COPY_DIRS):
            lines.append("/" + base + "**/" + folder + "/")
        for prefix in ("before-", "after-", "fault-", "negative-"):
            lines.append("/" + base + "**/" + prefix + "*/")
    lines += ["/" + base for base in EXPORT_ROOTS]
    lines += ["/" + name for name in sorted(SCRATCH_FILES)]
    lines += ["/" + name for name in sorted(EXTRA_GENERATED)]
    lines += ["/.claude/settings.local.json", ending]
    file.write_text(text.rstrip() + "\n\n" + "\n".join(lines) + "\n", encoding="utf-8")
    print("Installed generated-output ignore rules; source/prose exceptions retained.")


def status() -> list[dict]:
    fields = git("status", "--porcelain=v1", "-z", "--untracked-files=all").decode("utf-8").split("\0")
    records = []
    i = 0
    while i < len(fields):
        entry = fields[i]
        i += 1
        if not entry:
            continue
        row = {"status": entry[:2], "path": entry[3:]}
        if "R" in row["status"] or "C" in row["status"]:
            row["old_path"] = fields[i]
            i += 1
        records.append(row)
    return records


def backup() -> None:
    BACKUP.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    manifest_path = BACKUP / "snapshot.json"
    if manifest_path.exists():
        raise SystemExit("Backup already exists; never overwrite a recovery snapshot.")
    rows = status()
    snapshot = {"root": str(ROOT), "head": git("rev-parse", "HEAD").decode().strip(),
                "branch": git("branch", "--show-current").decode().strip(),
                "created": time.time(), "files": rows}
    (BACKUP / "tracked.patch").write_bytes(git("diff", "--binary", "HEAD"))
    (BACKUP / "staged.patch").write_bytes(git("diff", "--cached", "--binary"))
    index = Path(git("rev-parse", "--git-path", "index").decode().strip())
    if not index.is_absolute():
        index = ROOT / index
    shutil.copy2(index, BACKUP / "git-index")
    with zipfile.ZipFile(BACKUP / "working-tree.zip", "x", zipfile.ZIP_DEFLATED,
                         compresslevel=1, allowZip64=True) as archive:
        for i, row in enumerate(rows):
            file = confined(ROOT, row["path"])
            if not file.exists():
                row["missing"] = True
                continue
            stat = file.stat()
            data = file.read_bytes()
            after = file.stat()
            if (stat.st_size, stat.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
                raise RuntimeError(f"File changed during backup: {row['path']}")
            row.update(size=len(data), sha256=digest(data), mtime_ns=stat.st_mtime_ns)
            archive.writestr(row["path"], data)
            if i % 1000 == 0:
                print(f"Backup {i}/{len(rows)}", flush=True)
    # Re-read the archive; an existing zip alone is not evidence of preservation.
    with zipfile.ZipFile(BACKUP / "working-tree.zip") as archive:
        for row in rows:
            if row.get("missing"):
                continue
            assert digest(archive.read(row["path"])) == row["sha256"], row["path"]
    snapshot["verified"] = True
    manifest_path.write_text(json.dumps(snapshot, indent=2), encoding="utf-8")
    print(f"Verified backup: {len(rows)} paths; {BACKUP}", flush=True)


def migrate(plan_path: Path, apply: bool) -> None:
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    assert json.loads((BACKUP / "snapshot.json").read_text())["verified"]
    ARCHIVE.mkdir(parents=True, exist_ok=True)
    log_path = BACKUP / "moves.jsonl"
    for i, row in enumerate(plan["files"]):
        source = confined(ROOT, row["path"])
        target = confined(ARCHIVE, row["path"])
        if not source.exists():
            assert target.is_file() and digest(target.read_bytes()) == row["sha256"], row["path"]
            if apply:
                source.parent.mkdir(parents=True, exist_ok=True)
                os.link(target, source)
            continue  # A completed move, safely resumable.
        data = source.read_bytes()
        assert digest(data) == row["sha256"], f"Concurrent edit: {row['path']}"
        if not apply:
            continue
        if target.exists() and os.path.samefile(source, target):
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            assert digest(target.read_bytes()) == row["sha256"], f"Archive collision: {row['path']}"
        else:
            with target.open("xb") as output:
                output.write(data)
                output.flush()
                os.fsync(output.fileno())
            shutil.copystat(source, target)
        assert digest(target.read_bytes()) == row["sha256"], row["path"]
        # Read again immediately before removal; do not discard another writer's edit.
        assert digest(source.read_bytes()) == row["sha256"], f"Concurrent edit: {row['path']}"
        with log_path.open("a", encoding="utf-8") as log:
            log.write(json.dumps({**row, "source": str(source), "destination": str(target)}) + "\n")
            log.flush()
            os.fsync(log.fileno())
        source.unlink()
        # Preserve existing tool paths and URLs without storing a second copy.
        # Both repositories live on the same NTFS volume. Unlike a junction,
        # this does not redirect directory traversal or widen web access.
        os.link(target, source)
        assert os.path.samefile(source, target), row["path"]
        if i % 1000 == 0:
            print(f"Archived {i}/{len(plan['files'])}", flush=True)
    print(f"{'Moved' if apply else 'Validated'} {len(plan['files'])} files", flush=True)


def restore() -> None:
    """Restore archived paths without replacing any differing current file."""
    for line in (BACKUP / "moves.jsonl").read_text(encoding="utf-8").splitlines():
        row = json.loads(line)
        source = confined(ARCHIVE, row["path"])
        target = confined(ROOT, row["path"])
        data = source.read_bytes()
        assert digest(data) == row["sha256"], row["path"]
        if target.exists():
            assert digest(target.read_bytes()) == row["sha256"], f"Keep newer file: {row['path']}"
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("xb") as output:
            output.write(data)
        shutil.copystat(source, target)
    print("Original paths restored; archive copies retained.")


def verify(plan_path: Path) -> None:
    """Check preservation and the ignore boundary without changing source files."""
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    snapshot = json.loads((BACKUP / "snapshot.json").read_text(encoding="utf-8"))
    changed = []
    for i, row in enumerate(plan["files"]):
        source = confined(ROOT, row["path"])
        target = confined(ARCHIVE, row["path"])
        assert digest(target.read_bytes()) == row["sha256"], row["path"]
        assert source.is_file() and os.path.samefile(source, target), row["path"]
        if i % 2000 == 0:
            print(f"Verified archive {i}/{len(plan['files'])}", flush=True)
    archived = {row["path"] for row in plan["files"]}
    kept_untracked = []
    for row in snapshot["files"]:
        if row["path"] in archived or row.get("missing"):
            continue
        source = confined(ROOT, row["path"])
        assert source.is_file(), f"Missing retained source: {row['path']}"
        if digest(source.read_bytes()) != row["sha256"]:
            changed.append(row["path"])
        if row["status"] == "??":
            kept_untracked.append(row["path"])
    paths = sorted(archived) + kept_untracked
    print("Checking Git ignore boundary", flush=True)
    result = subprocess.run(
        ["git", "check-ignore", "--no-index", "-z", "--stdin"], cwd=ROOT,
        input=("\0".join(paths) + "\0").encode("utf-8"), capture_output=True, check=False)
    assert result.returncode in (0, 1), result.stderr.decode("utf-8", "replace")
    ignored = set(result.stdout.decode("utf-8").strip("\0").split("\0")) - {""}
    missing_rules = sorted(archived - ignored)
    hidden_sources = sorted(set(kept_untracked) & ignored)
    receipt = {"archive_count": len(archived), "retained_count": len(plan["keep"]),
               "all_archive_hashes_and_links_verified": True,
               "retained_paths_changed_since_backup": changed,
               "archive_paths_not_ignored": missing_rules,
               "retained_untracked_paths_ignored": hidden_sources}
    (WORK / "verification.json").write_text(json.dumps(receipt, indent=2), encoding="utf-8")
    print(json.dumps(receipt, indent=2), flush=True)
    assert not missing_rules and not hidden_sources, "Ignore policy does not match the manifest."


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["backup", "plan", "migrate", "restore", "ignore", "verify"])
    parser.add_argument("--plan", type=Path, default=WORK / "plan.json")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    if args.mode == "backup":
        backup()
    elif args.mode == "plan":
        make_plan()
    elif args.mode == "ignore":
        write_ignore()
    elif args.mode == "restore":
        restore()
    elif args.mode == "verify":
        verify(args.plan)
    else:
        migrate(args.plan, args.apply)
