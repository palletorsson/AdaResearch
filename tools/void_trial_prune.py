"""Tear down the stages tools/void_trial_runtime.py leaves behind.

stage_runtime() builds ada_run/void-trial-runtime/run-XXXXXXXX for every native
trial run: ~40 'mklink /J' JUNCTIONS into the real repo (commons, tools,
algorithms, android, ...), a copy of every root file, a .godot/ with cached
cfgs and one more junction (.godot/imported), and whatever the game writes
under the stage (ada_run/). Nothing removed a stage: 285 on 2026-10-21, 763 on
2026-10-23. Every walker that follows junctions pays once per stage -- gate N
ran two hours; and a recursive delete that follows a junction deletes the
repository itself, which is why these are never removed by hand with rmtree.

This module removes a stage WITHOUT ever descending a junction:

  junction          os.rmdir -- deletes the reparse point, leaves the target
  copied root file  os.unlink
  real directory    recursed the same way, then os.rmdir

The reparse-point check is lstat() on every entry, so a junction nested under
a real directory (.godot/imported) is also severed, not entered.

    python tools/void_trial_prune.py --dry-run             # list, remove nothing
    python tools/void_trial_prune.py --older-than=24       # prune stale stages
    python tools/void_trial_prune.py --stage=run-abc12345  # one stage

From a trial runner:

    from void_trial_runtime import stage_runtime
    from void_trial_prune import teardown_stage
    stage = stage_runtime()
    try: ...
    finally: teardown_stage(stage)

Exit code: 0 when every selected stage is gone (or --dry-run), else the number
that could not be removed. A stage touched inside the hold is never selected
by --older-than: a run in flight writes to it.
"""
import os
import stat
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / "ada_run" / "void-trial-runtime"
HOLD_HOURS = 24.0


def is_junction(path: Path) -> bool:
    try:
        st = path.lstat()
    except OSError:
        return False
    attrs = getattr(st, "st_file_attributes", 0)
    return bool(attrs & stat.FILE_ATTRIBUTE_REPARSE_POINT)


def teardown_stage(stage: Path) -> list:
    """Remove one stage. Returns the paths it could not remove (empty = gone)."""
    stage = Path(stage)
    failed = []
    if not stage.exists() and not is_junction(stage):
        return failed
    if is_junction(stage):
        # Never a stage itself, but never descend one either.
        try:
            os.rmdir(stage)
        except OSError:
            failed.append(stage)
        return failed
    for child in list(stage.iterdir()):
        if is_junction(child):
            try:
                os.rmdir(child)
            except OSError:
                failed.append(child)
        elif child.is_dir():
            failed.extend(teardown_stage(child))
        else:
            try:
                os.unlink(child)
            except OSError:
                # copy2 keeps the source's read-only bit (openxr_action_map.tres
                # carries it); Windows refuses unlink until it is cleared.
                try:
                    os.chmod(child, stat.S_IWRITE)
                    os.unlink(child)
                except OSError:
                    failed.append(child)
    if not failed:
        try:
            os.rmdir(stage)
        except OSError:
            failed.append(stage)
    return failed


def stale_stages(hours: float = HOLD_HOURS, now: float = None) -> list:
    if not WORK.is_dir():
        return []
    now = time.time() if now is None else now
    out = []
    for s in sorted(WORK.iterdir()):
        if not s.name.startswith("run-") or not s.is_dir() or is_junction(s):
            continue
        # Creation time, not mtime: a half-finished teardown (one read-only
        # file refusing unlink, 2026-10-23) rewrites the folder's mtime and
        # makes 691 stale stages read "written just now". On Windows st_ctime
        # is the creation stamp; elsewhere take the older of the two.
        st = s.stat()
        age = (now - min(st.st_ctime, st.st_mtime)) / 3600.0
        if age >= hours:
            out.append((s, age))
    return out


def selftest() -> int:
    """Build a toy stage with one junction INTO a real folder, tear it down,
    and prove the target survived. The fault this exists to avoid is the one
    a recursive delete makes by following the link."""
    import subprocess
    import tempfile
    base = Path(tempfile.mkdtemp(prefix="void-prune-selftest-", dir=WORK if WORK.is_dir() else None))
    target = base / "real"
    target.mkdir()
    (target / "keep.txt").write_text("keep", encoding="utf8")
    stage = base / "run-selftest"
    stage.mkdir()
    (stage / "copied.txt").write_text("x", encoding="utf8")
    (stage / "sub").mkdir()
    subprocess.run(["cmd", "/c", "mklink", "/J", str(stage / "sub" / "link"), str(target)],
                   check=True, capture_output=True)
    subprocess.run(["cmd", "/c", "mklink", "/J", str(stage / "top"), str(target)],
                   check=True, capture_output=True)
    cases = []
    cases.append(("sees a junction as a junction", is_junction(stage / "top")))
    failed = teardown_stage(stage)
    cases.append(("removes the stage", failed == [] and not stage.exists()))
    cases.append(("leaves the junction target and its file",
                  (target / "keep.txt").read_text(encoding="utf8") == "keep"))
    cases.append(("a stage written just now is not stale",
                  stale_stages(hours=24.0) == [] or all(a >= 24.0 for _, a in stale_stages(24.0))))
    teardown_stage(base)
    cases.append(("cleans its own fixture", not base.exists()))
    bad = [n for n, ok in cases if not ok]
    for n, ok in cases:
        print("  %-52s %s" % (n, "ok" if ok else "FAIL"))
    print("selftest: %d/%d" % (len(cases) - len(bad), len(cases)))
    return 1 if bad else 0


def main() -> int:
    argv = sys.argv[1:]
    if "--selftest" in argv:
        return selftest()
    dry = "--dry-run" in argv
    hours = HOLD_HOURS
    one = None
    for a in argv:
        if a.startswith("--older-than="):
            hours = float(a.split("=", 1)[1])
        elif a.startswith("--stage="):
            one = WORK / a.split("=", 1)[1]
    if one is not None:
        selected = [(one, (time.time() - one.stat().st_mtime) / 3600.0)] if one.is_dir() else []
    else:
        selected = stale_stages(hours)
    total = len([s for s in WORK.iterdir() if s.name.startswith("run-")]) if WORK.is_dir() else 0
    print("=== VOID TRIAL STAGES ===")
    print("%d stages under %s, %d selected (older than %gh)%s"
          % (total, WORK.relative_to(ROOT).as_posix(), len(selected), hours,
             ", dry run" if dry else ""))
    if dry:
        for s, age in selected[:20]:
            print("  %-16s %6.1fh" % (s.name, age))
        if len(selected) > 20:
            print("  ... %d more" % (len(selected) - 20))
        return 0
    left = 0
    for s, age in selected:
        failed = teardown_stage(s)
        if failed:
            left += 1
            print("  %-16s %6.1fh  NOT REMOVED: %s" % (s.name, age, failed[0]))
    remaining = len([s for s in WORK.iterdir() if s.name.startswith("run-")]) if WORK.is_dir() else 0
    print("removed %d, could not remove %d, %d stages remain"
          % (len(selected) - left, left, remaining))
    return left


if __name__ == "__main__":
    sys.exit(main())
