#!/usr/bin/env python
"""Move evidence out of the game repo and into the encyclopedia's captures/ folder.

2026-09-14, Palle: "can we move the ada run to encyclopedia and the report images as
well?" Destination chosen: ada_encyclopedia/captures/ (ignored there, so neither repo
grows). Writers chosen to follow one evidence root (tools/evidence_root.py,
commons/testing/evidence_root.gd) as they are touched — which means new evidence keeps
landing in the old places for a while, and this sweep is how it leaves again.

    python tools/sweep_evidence.py                 # dry run: what would move, and why not the rest
    python tools/sweep_evidence.py --apply         # move it
    python tools/sweep_evidence.py --undo <manifest.jsonl>

WHAT NEVER MOVES, derived on every run rather than written down:

  game data         every ada_run/ entry named by game code — GDScript, scenes and
                    resources under commons/, algorithms/ and addons/, probes excluded.
                    The museum reads em_plan.json, necklace_hand.json, em_overrides.json
                    and the whole of em_cartridges/ every run. Measured when this was
                    written: every game read of ada_run/ is a literal res:// path, none is
                    assembled from pieces, so a literal scan is complete for the game.
  encyclopedia data every ada_run/ entry the encyclopedia names — its pages read em_plan,
                    em_overrides, desktop_feedback and a few more straight from this repo.
  live work         anything written in the last --fresh-hours (48). Review folders are
                    dated and other sessions write them daily; a folder moved while its
                    session is still writing is split across two places.
  committed ada_run evidence
                    tracked files under ada_run/ stay unless --include-tracked. Sessions
                    commit probe JSON there on purpose, as the record of a run.
  linked reports    a doc/reports image named by any markdown, html or json under doc/ —
                    moving it breaks the report that shows it.
  served reports    doc/reports/map_comparisons/, which the encyclopedia's
                    /api/map-comparison/png route reads by path.

Tracked doc/reports images DO move: that was the point of the request. They become
unstaged deletions in this repo — not staged, because the index is shared with every
other session running here, and a staged deletion is swept into whoever commits next.

Every move is recorded in captures/<kind>/_sweep/<timestamp>.jsonl, and --undo reads one
back.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from evidence_root import REPO, captures_root, encyclopedia_path  # noqa: E402

IMG = (".png", ".jpg", ".jpeg", ".webp", ".gif", ".exr")
SERVED_REPORT_DIRS = ("map_comparisons",)
RES_ADA_RUN = re.compile(r"res://ada_run/([A-Za-z0-9_.\-]+)")
BARE_ADA_RUN = re.compile(r"ada_run/([A-Za-z0-9_.\-]+)")


def _walk_text(roots, exts, skip_dirs=("node_modules", ".next", ".git", "worktrees", "testing")):
    for root in roots:
        if not Path(root).exists():
            continue
        for dp, dn, fn in os.walk(root):
            dn[:] = [d for d in dn if d not in skip_dirs]
            for f in fn:
                if f.endswith(exts):
                    p = Path(dp) / f
                    try:
                        yield p, p.read_text(encoding="utf-8", errors="ignore")
                    except OSError:
                        continue


def names_read_by_game() -> dict[str, str]:
    """ada_run/ top-level names the game reads -> one file that reads it.

    A key ending in "*" is a PREFIX: the literal was cut by a format or a concatenation
    ("res://ada_run/em_built_%s.json" % lane, or "res://ada_run/em_built_" + lane), so
    the game reaches every entry that starts with it. Measured 2026-09-14 there are none —
    every game read is a full literal — but this sweep runs again and again, and a
    literal-only rule would move a file the game writes by format string the first time
    somebody writes one. Only res:// strings count: the scan found seven entries named in
    game code by COMMENTS alone ("measured off ada_run/necklace_head.png"), and a comment
    reads nothing.
    """
    out: dict[str, str] = {}
    roots = [REPO / "commons", REPO / "algorithms", REPO / "addons"]
    cut = re.compile(r'^(?:%|\{|"\s*\+)')
    for p, t in _walk_text(roots, (".gd", ".tscn", ".tres", ".gdshader")):
        where = str(p.relative_to(REPO)).replace("\\", "/")
        for m in RES_ADA_RUN.finditer(t):
            name = m.group(1).rstrip(".")
            if cut.match(t[m.end():m.end() + 4]):
                out.setdefault(name + "*", where)
            elif name:
                out.setdefault(name, where)
    return out


def _game_reads(name: str, game: dict[str, str]) -> str | None:
    if name in game:
        return game[name]
    for k, where in game.items():
        if k.endswith("*") and name.startswith(k[:-1]):
            return where
    return None


def names_read_by_encyclopedia() -> dict[str, str]:
    enc = encyclopedia_path()
    out: dict[str, str] = {}
    if enc is None:
        return out
    for p, t in _walk_text([enc / "src", enc / "scripts"], (".ts", ".tsx", ".js", ".mjs")):
        for m in BARE_ADA_RUN.findall(t):
            out.setdefault(m.rstrip("."), str(p.relative_to(enc)).replace("\\", "/"))
    return out


def report_images_linked_from_doc() -> set[str]:
    """Basenames of images that some document under doc/ names."""
    names: set[str] = set()
    pat = re.compile(r"[\w.\-%]+\.(?:png|jpe?g|webp|gif)", re.I)
    for _p, t in _walk_text([REPO / "doc"], (".md", ".html", ".json"), skip_dirs=(".git",)):
        names.update(n.lower() for n in pat.findall(t))
    return names


def tracked_files(prefix: str) -> set[str]:
    r = subprocess.run(["git", "ls-files", "-z", prefix], cwd=REPO, capture_output=True)
    return {x for x in r.stdout.decode("utf-8", "replace").split("\0") if x}


def newest_mtime(path: Path) -> float:
    if path.is_file():
        return path.stat().st_mtime
    newest = 0.0
    for dp, _dn, fn in os.walk(path):
        for f in fn:
            try:
                newest = max(newest, (Path(dp) / f).stat().st_mtime)
            except OSError:
                pass
    return newest


def plan(fresh_hours: float, include_tracked: bool):
    cutoff = time.time() - fresh_hours * 3600.0
    game = names_read_by_game()
    enc = names_read_by_encyclopedia()
    moves: list[tuple[Path, Path, int, bool]] = []     # src, dst, bytes, tracked
    kept: dict[str, list[str]] = {}

    def keep(reason: str, what: str):
        kept.setdefault(reason, []).append(what)

    cap = captures_root()
    # ── ada_run/ ─────────────────────────────────────────────────────────
    ada = REPO / "ada_run"
    tracked_ada = tracked_files("ada_run")
    for entry in sorted(ada.iterdir(), key=lambda p: p.name.lower()):
        name = entry.name
        reader = _game_reads(name, game)
        if reader is not None:
            keep("the game reads it", "%s  (%s)" % (name, reader))
            continue
        if name in enc:
            keep("the encyclopedia reads it", "%s  (%s)" % (name, enc[name]))
            continue
        if newest_mtime(entry) >= cutoff:
            keep("written in the last %g h" % fresh_hours, name)
            continue
        files = [entry] if entry.is_file() else [Path(dp) / f for dp, _dn, fn in os.walk(entry) for f in fn]
        n_tracked = 0
        for f in files:
            rel = str(f.relative_to(REPO)).replace("\\", "/")
            is_tracked = rel in tracked_ada
            if is_tracked and not include_tracked:
                n_tracked += 1
                continue
            dst = cap / "ada-run" / f.relative_to(ada)
            try:
                size = f.stat().st_size
            except OSError:
                continue
            moves.append((f, dst, size, is_tracked))
        if n_tracked:
            keep("committed ada_run evidence (use --include-tracked)", "%s  (%d tracked file(s))" % (name, n_tracked))

    # ── doc/reports images ───────────────────────────────────────────────
    reports = REPO / "doc" / "reports"
    linked = report_images_linked_from_doc()
    tracked_rep = tracked_files("doc/reports")
    for dp, _dn, fn in os.walk(reports):
        for f in fn:
            if not f.lower().endswith(IMG):
                continue
            p = Path(dp) / f
            rel_r = p.relative_to(reports)
            rel = str(p.relative_to(REPO)).replace("\\", "/")
            if rel_r.parts and rel_r.parts[0] in SERVED_REPORT_DIRS:
                keep("served by an encyclopedia route", rel)
                continue
            if f.lower() in linked:
                keep("linked from a document under doc/", rel)
                continue
            try:
                st = p.stat()
            except OSError:
                continue
            if st.st_mtime >= cutoff:
                keep("written in the last %g h" % fresh_hours, rel)
                continue
            dst = cap / "doc-reports" / rel_r
            moves.append((p, dst, st.st_size, rel in tracked_rep))
            imp = p.with_name(p.name + ".import")        # Godot's sidecar travels with it
            if imp.exists():
                moves.append((imp, dst.with_name(dst.name + ".import"), imp.stat().st_size, False))
    return moves, kept


def apply(moves, stamp: str) -> dict[str, Path]:
    cap = captures_root()
    manifests: dict[str, Path] = {}
    handles = {}
    moved = skipped = failed = 0
    for src, dst, size, is_tracked in moves:
        kind = "ada-run" if "ada-run" in dst.parts else "doc-reports"
        if kind not in handles:
            mdir = cap / kind / "_sweep"
            mdir.mkdir(parents=True, exist_ok=True)
            manifests[kind] = mdir / ("%s.jsonl" % stamp)
            # line-buffered: every move is on disk before the next one starts, so a run
            # that dies halfway still leaves a manifest --undo can read back entirely
            handles[kind] = open(manifests[kind], "a", encoding="utf-8", buffering=1)
        if dst.exists():
            skipped += 1
            handles[kind].write(json.dumps({"skipped": str(src), "reason": "destination exists", "to": str(dst)}) + "\n")
            continue
        # ONE FAILED MOVE IS NOT A FAILED SWEEP. On Windows a file held open — by a
        # running Godot, the encyclopedia's dev server, an image viewer — refuses to move.
        # It stays where it is, is named in the manifest, and the next sweep takes it.
        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dst))
        except OSError as e:
            failed += 1
            handles[kind].write(json.dumps({"failed": str(src), "reason": str(e), "to": str(dst)}) + "\n")
            continue
        moved += 1
        handles[kind].write(json.dumps({"from": str(src), "to": str(dst), "bytes": size, "tracked": is_tracked}) + "\n")
        # tidy the directories this move emptied, but never past the folder it came from
        parent = src.parent
        stop = {REPO / "ada_run", REPO / "doc" / "reports"}
        try:
            while parent not in stop and parent.exists() and not any(parent.iterdir()):
                parent.rmdir()
                parent = parent.parent
        except OSError:
            pass
    for h in handles.values():
        h.close()
    print("moved %d file(s); %d skipped because the destination already existed; %d could not be moved (held open?)"
          % (moved, skipped, failed))
    return manifests


def undo(manifest: Path):
    back = missing = 0
    for line in manifest.read_text(encoding="utf-8").splitlines():
        rec = json.loads(line)
        if "from" not in rec:
            continue
        src, dst = Path(rec["to"]), Path(rec["from"])
        if not src.exists():
            missing += 1
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))
        back += 1
    print("moved %d file(s) back; %d were no longer at their destination" % (back, missing))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--apply", action="store_true", help="move the files (default is a dry run)")
    ap.add_argument("--fresh-hours", type=float, default=48.0)
    ap.add_argument("--include-tracked", action="store_true", help="also move tracked files under ada_run/")
    ap.add_argument("--undo", type=Path, help="a manifest .jsonl to reverse")
    ap.add_argument("--list", type=int, default=8, help="how many kept items to print per reason")
    a = ap.parse_args()

    if captures_root() is None:
        print("no encyclopedia checkout found (set ADA_ENCYCLOPEDIA_PATH) — nothing to move to")
        return 2
    if a.undo:
        undo(a.undo)
        return 0

    moves, kept = plan(a.fresh_hours, a.include_tracked)
    mb = lambda b: b / 1e6
    by_kind: dict[str, list[int]] = {}
    for src, dst, size, is_tracked in moves:
        k = "ada-run" if "ada-run" in dst.parts else "doc-reports"
        v = by_kind.setdefault(k, [0, 0, 0])
        v[0] += 1
        v[1] += size
        v[2] += 1 if is_tracked else 0
    print("%s -> %s" % ("DRY RUN" if not a.apply else "APPLYING", captures_root()))
    for k, (n, b, t) in sorted(by_kind.items()):
        print("  %-12s %6d file(s)  %8.1f MB   %d of them tracked in this repo" % (k, n, mb(b), t))
    print("kept in place:")
    for reason, items in kept.items():
        print("  %-52s %d" % (reason, len(items)))
        for it in items[: a.list]:
            print("      " + it)
        if len(items) > a.list:
            print("      ... %d more" % (len(items) - a.list))
    if not a.apply:
        print("\n(dry run — nothing moved. --apply to move.)")
        return 0
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    manifests = apply(moves, stamp)
    for k, m in manifests.items():
        print("manifest (%s): %s" % (k, m))
    return 0


if __name__ == "__main__":
    sys.exit(main())
