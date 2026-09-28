#!/usr/bin/env python3
"""check_global_classes.py — why does Godot say a class "hides a global script class"?

2026-09-28, Palle:  Parser Error: Class "SciFiLoFiSoundscape" hides a global
script class.  res://commons/audio/systems/SciFiLoFiSoundscape.gd

That error has exactly one cause (gdscript_analyzer.cpp, resolve_class_inheritance):
the script's `class_name` is already registered in the editor's global class
cache under a DIFFERENT path than the script being parsed. Two things put a
name there twice:

  1. two scripts on disk declare the same class_name — Godot scans everything
     under the project except dot-dirs and folders holding a `.gdignore`, and
     git's ignore rules mean nothing to it, so an untracked copy, a backup, a
     second checkout dropped inside the project, all count;
  2. the cache (.godot/global_script_class_cache.cfg) still holds a path the
     file moved away from — or, on Windows, the same path in a different
     CASE, which the analyzer compares as a plain string.

This tool answers both from the disk Godot sees, not from git:

  * every .gd under the project, walked Godot's way, with its class_name;
  * names declared more than once, with every path;
  * declared scripts git does not track (a stray copy is untracked, or ignored);
  * the class cache, entry by entry: path missing, path differing in case from
    the file on disk, or a name whose cached path is not where it is declared;
  * a script under doc/ that Godot scans at all — a review snapshot
    (…/before/commons__audio__systems__SciFiLoFiSoundscape.gd was the one that
    hid the class on 2026-09-28) belongs behind a `.gdignore`, tracked or not.
    `--fix` writes that `.gdignore` beside the snapshot (the folder holding the
    before/ or after/ dir, else the script's own) and says so;
  * every literal res:// reference in scripts and scenes whose spelling differs
    from the disk in CASE. Windows resolves it, so the file registers under the
    disk's spelling and parses under the reference's — the two paths the
    analyzer compares — and the Quest, case-sensitive, does not resolve it at
    all.

Exit code = number of findings, so it gates.

  python tools/check_global_classes.py            # the report
  python tools/check_global_classes.py --json     # for tools
  python tools/check_global_classes.py --name SciFiLoFiSoundscape   # one name
  python tools/check_global_classes.py --fix      # .gdignore every stray snapshot, then rescan in Godot
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / ".godot" / "global_script_class_cache.cfg"
CLASS_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)
REF_RE = re.compile(r'res://[^"\'\s()]+?\.(?:gd|tscn|tres|gdshader|shader)\b')
REF_EXT = (".gd", ".tscn", ".tres")
INNER_RE = re.compile(r"^[ \t]+class\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:extends[^:]*)?:", re.M)


def godot_walk(root: Path, exts: tuple = (".gd",)):
    """Every file of these kinds Godot's EditorFileSystem would scan: no
    dot-dirs, no dot-files, no folder with a .gdignore in it (and nothing
    beneath one). Extensions compare case-blind, as the scan does."""
    for dirpath, dirnames, filenames in os.walk(root):
        d = Path(dirpath)
        if (d / ".gdignore").exists() and d != root:
            dirnames[:] = []
            continue
        dirnames[:] = sorted(x for x in dirnames if not x.startswith("."))
        for f in sorted(filenames):
            if f.startswith(".") or not f.lower().endswith(exts):
                continue
            yield d / f


def strip_comments(src: str) -> str:
    return "\n".join(line.split("#", 1)[0] if not line.lstrip().startswith("#") else "" for line in src.split("\n"))


def declared(root: Path) -> tuple[dict, dict]:
    """name -> [res paths] for class_name declarations; also inner classes."""
    names: dict[str, list[str]] = {}
    inner: dict[str, list[str]] = {}
    for p in godot_walk(root):
        try:
            src = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        res = "res://" + p.relative_to(root).as_posix()
        body = strip_comments(src)
        m = CLASS_RE.search(body)
        if m:
            names.setdefault(m.group(1), []).append(res)
        for im in INNER_RE.finditer(body):
            inner.setdefault(im.group(1), []).append(res)
    return names, inner


def tracked(root: Path) -> set[str]:
    try:
        out = subprocess.run(["git", "ls-files", "-z", "--", "*.gd"], cwd=str(root),
                             capture_output=True, text=True, timeout=60).stdout
    except Exception:
        return set()
    return {"res://" + f for f in out.split("\0") if f}


def read_cache(path: Path) -> list[dict]:
    """The cache is a ConfigFile with one key, `list`, holding an Array of
    Dictionaries; each has "class" and "path". Read with a regex — it needs
    no Godot, and a truncated or hand-edited cache still yields its rows."""
    if not path.exists():
        return []
    txt = path.read_text(encoding="utf-8", errors="replace")
    rows = []
    for m in re.finditer(r'\{([^{}]*)\}', txt):
        body = m.group(1)
        c = re.search(r'"class"\s*:\s*&?"([^"]+)"', body)
        p = re.search(r'"path"\s*:\s*"([^"]+)"', body)
        if c and p:
            rows.append({"class": c.group(1), "path": p.group(1)})
    return rows


_LISTING: dict[Path, dict[str, str]] = {}


def _entries(d: Path) -> dict[str, str]:
    e = _LISTING.get(d)
    if e is None:
        try:
            e = {x.lower(): x for x in os.listdir(d)}
        except OSError:
            e = {}
        _LISTING[d] = e
    return e


def real_case_path(root: Path, res: str) -> str | None:
    """The path as the disk spells it, walking one component at a time, or
    None when it does not exist. On a case-insensitive disk (Windows) the file
    may exist under a spelling the cache does not use — that is finding #2."""
    parts = res.replace("res://", "").split("/")
    cur = root
    spelled = []
    for part in parts:
        hit = _entries(cur).get(part.lower())
        if hit is None:
            return None
        spelled.append(hit)
        cur = cur / hit
    return "res://" + "/".join(spelled)


def references(root: Path) -> dict[str, list[str]]:
    """Every literal res:// path to a script, scene, resource or shader in the
    scripts and scenes Godot scans: path -> the files that write it so."""
    out: dict[str, list[str]] = {}
    for p in godot_walk(root, REF_EXT):
        try:
            src = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        me = "res://" + p.relative_to(root).as_posix()
        for m in set(REF_RE.findall(src)):
            out.setdefault(m, []).append(me)
    return out


#: where a .gd is evidence, never game code. doc/ as a whole cannot take a
#: .gdignore — ProjectDashboardOverlay reads res://doc/reports/*.json and an
#: ignored folder is left out of the export — so the marker goes beside the
#: snapshot instead.
STRAY_ROOTS = ("doc",)
SNAPSHOT_DIRS = {"before", "after", "snapshot", "snapshots"}


def gdignore_home(root: Path, script: Path) -> Path:
    """Where the .gdignore for a stray script goes: the folder holding its
    before/after dir when there is one, else the script's own folder."""
    rel = script.relative_to(root)
    parts = rel.parts
    for i, part in enumerate(parts[:-1]):
        if part.lower() in SNAPSHOT_DIRS and i > 0:
            return root.joinpath(*parts[:i])
    return script.parent


def report(root: Path, only: str | None = None, fix: bool = False) -> dict:
    names, inner = declared(root)
    git_gd = tracked(root)
    findings: list[dict] = []

    written: list[str] = []
    for p in godot_walk(root):
        rel = p.relative_to(root)
        if rel.parts[0] not in STRAY_ROOTS:
            continue
        res = "res://" + rel.as_posix()
        if only:
            src = p.read_text(encoding="utf-8", errors="replace")
            m = CLASS_RE.search(strip_comments(src))
            if not m or m.group(1) != only:
                continue
        home = gdignore_home(root, p)
        f = {"kind": "stray_script", "path": res, "tracked": bool(git_gd and res in git_gd),
             "gdignore": "res://" + home.relative_to(root).as_posix() + "/.gdignore"}
        if fix:
            marker = home / ".gdignore"
            if not marker.exists():
                marker.write_text("# evidence snapshot, not game code — Godot must not scan it "
                                  "(tools/check_global_classes.py --fix)\n", encoding="utf-8")
                written.append(f["gdignore"])
            f["fixed"] = True
        findings.append(f)

    for name, paths in sorted(names.items()):
        if only and name != only:
            continue
        if len(paths) > 1:
            findings.append({"kind": "duplicate", "class": name, "paths": paths,
                             "untracked": [p for p in paths if git_gd and p not in git_gd]})
    for name, paths in sorted(inner.items()):
        if only and name != only:
            continue
        if name in names:
            findings.append({"kind": "inner_shadows_global", "class": name, "paths": paths,
                             "global": names[name]})
    if git_gd:
        for name, paths in sorted(names.items()):
            if only and name != only:
                continue
            stray = [p for p in paths if p not in git_gd]
            if stray and len(paths) == 1:
                findings.append({"kind": "untracked_declaration", "class": name, "paths": stray})

    refs = references(root)
    mis = 0
    for ref, users in sorted(refs.items()):
        spelled = real_case_path(root, ref)
        if spelled is None:
            mis += 1
            continue
        if spelled != ref:
            if only and not (ref.endswith(".gd") and only in names and ref in names[only]
                             or spelled in names.get(only, [])):
                continue
            findings.append({"kind": "reference_case", "written": ref, "on_disk": spelled,
                             "by": users[:8], "users": len(users)})

    cache_rows = read_cache(CACHE)
    for row in cache_rows:
        name, cpath = row["class"], row["path"]
        if only and name != only:
            continue
        spelled = real_case_path(root, cpath)
        if spelled is None:
            findings.append({"kind": "cache_path_missing", "class": name, "cached": cpath,
                             "declared_at": names.get(name, [])})
        elif spelled != cpath:
            findings.append({"kind": "cache_path_case", "class": name, "cached": cpath, "on_disk": spelled})
        elif name in names and cpath not in names[name]:
            findings.append({"kind": "cache_path_elsewhere", "class": name, "cached": cpath,
                             "declared_at": names[name]})
    return {"scanned": sum(len(v) for v in names.values()), "classes": len(names),
            "cache_rows": len(cache_rows), "cache": str(CACHE) if CACHE.exists() else None,
            "references": len(refs), "references_missing": mis, "findings": findings,
            "gdignore_written": written}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--name", default=None, help="only this class name")
    ap.add_argument("--root", default=str(ROOT))
    ap.add_argument("--fix", action="store_true",
                    help="write a .gdignore beside every stray snapshot script, so Godot stops scanning it")
    args = ap.parse_args()
    r = report(Path(args.root), args.name, fix=args.fix)
    if args.json:
        print(json.dumps(r, indent=1))
        return len(r["findings"])
    print("global classes: %d declared in %d scripts Godot scans%s" % (
        r["classes"], r["scanned"],
        "; cache: %d rows" % r["cache_rows"] if r["cache"] else "; no .godot/ class cache here"))
    print("res:// references: %d distinct paths to scripts/scenes/resources checked against the disk's "
          "spelling (%d point at nothing — not this tool's question)" % (r["references"], r["references_missing"]))
    if not r["findings"]:
        print("no duplicate class_name, no untracked declaration, no stale cache row"
              + (" — for %s" % args.name if args.name else ""))
        return 0
    for f in r["findings"]:
        k = f["kind"]
        if k == "stray_script":
            print("\nSTRAY      %s is a script Godot scans inside doc/%s\n           -> %s%s" % (
                f["path"], "" if f["tracked"] else " (not tracked by git)", f["gdignore"],
                "   written" if f.get("fixed") else "   (--fix writes it)"))
        elif k == "duplicate":
            print("\nDUPLICATE  class_name %s is declared %d times:" % (f["class"], len(f["paths"])))
            for p in f["paths"]:
                print("    %s%s" % (p, "   <- not tracked by git" if p in f["untracked"] else ""))
        elif k == "inner_shadows_global":
            print("\nSHADOW     inner class %s in %s hides the global class at %s" % (
                f["class"], ", ".join(f["paths"]), ", ".join(f["global"])))
        elif k == "untracked_declaration":
            print("\nUNTRACKED  class_name %s is declared only in a file git does not track: %s" % (
                f["class"], ", ".join(f["paths"])))
        elif k == "cache_path_missing":
            print("\nSTALE      the class cache maps %s to %s, which does not exist%s" % (
                f["class"], f["cached"],
                "; it is declared at %s" % ", ".join(f["declared_at"]) if f["declared_at"] else ""))
        elif k == "cache_path_case":
            print("\nCASE       the class cache spells %s as %s but the disk has %s" % (
                f["class"], f["cached"], f["on_disk"]))
        elif k == "reference_case":
            print("\nCASE       %s is written as\n             %s\n           but the disk spells it\n             %s\n           by %s%s" % (
                f["written"].rsplit("/", 1)[-1], f["written"], f["on_disk"], ", ".join(f["by"]),
                " (+%d more)" % (f["users"] - len(f["by"])) if f["users"] > len(f["by"]) else ""))
        elif k == "cache_path_elsewhere":
            print("\nELSEWHERE  the class cache maps %s to %s, but it is declared at %s" % (
                f["class"], f["cached"], ", ".join(f["declared_at"])))
    if r["gdignore_written"]:
        print("\nwrote %d .gdignore file(s); in Godot: Project > Reload Current Project, or restart" % len(r["gdignore_written"]))
    print("\n%d finding(s). A stray snapshot: --fix, or delete the folder. A stale or mis-cased cache row: "
          "close the editor, delete the .godot folder, reopen. A duplicate: rename or delete one. "
          "A mis-cased reference: spell it as the disk does — the Quest will not find it otherwise."
          % len(r["findings"]))
    return len(r["findings"])


if __name__ == "__main__":
    raise SystemExit(main())
