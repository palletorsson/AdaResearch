"""Where EVIDENCE goes — screenshots, probe output, review folders — as opposed to game data.

2026-09-14, Palle: "can we move the ada run to encyclopedia and the report images as
well?" — and, asked where: the encyclopedia's `captures/` folder, on disk only; asked how
the writers should follow: one evidence root and a sweep.

WHY A ROOT AND NOT A PATH IN EVERY FILE. 276 probes and 78 tools wrote into ada_run/ and
51 tools and 9 probes into doc/reports/ when this was written. A folder moved out from
under them is recreated at the old path on their next run. Rewriting all of them at once
would edit files other sessions are actively using, so writers move to this module as
they are touched, and tools/sweep_evidence.py collects whatever still lands in the old
place.

WHAT IS NOT EVIDENCE, and must never be routed here: anything the GAME reads. The museum
reads ada_run/em_plan.json, necklace_hand.json, em_overrides.json, em_control.json,
runtime_flags.json and the whole of ada_run/em_cartridges/ every run; the VR feedback
bridge writes desktop_feedback.md there. Those are game data that happen to live in a
folder named like a scratch directory. sweep_evidence.py derives that list from the game
code on every run rather than trusting one written down here.

    from evidence_root import evidence_dir
    out = evidence_dir("voxel-review-2026-09-13")      # a Path, created
"""

from __future__ import annotations

import os
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def encyclopedia_path() -> Path | None:
    """The encyclopedia checkout, or None if this machine does not have one."""
    env = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "").strip()
    candidates = [Path(env)] if env else []
    candidates.append(REPO.parent / "ada_encyclopedia")
    for c in candidates:
        if (c / "package.json").is_file():
            return c
    return None


def captures_root() -> Path | None:
    enc = encyclopedia_path()
    return (enc / "captures") if enc is not None else None


def evidence_dir(*parts: str, kind: str = "ada-run", create: bool = True) -> Path:
    """A directory for evidence, created on demand (create=False for a reader that only looks).

    kind "ada-run" is what used to be ada_run/<parts>; "doc-reports" what used to be
    doc/reports/<parts>. With no encyclopedia on this machine it falls back to the old
    place in this repo, so a writer that has moved to this module never fails because of
    it — it only writes where it always did.
    """
    root = captures_root()
    if root is None:
        base = REPO / ("ada_run" if kind == "ada-run" else "doc/reports")
    else:
        base = root / kind
    d = base.joinpath(*parts) if parts else base
    if create:
        d.mkdir(parents=True, exist_ok=True)
    return d


if __name__ == "__main__":
    import sys

    # `--print <rel> [--kind doc-reports]` prints ONE path and nothing else, so a shell
    # runner can take it:  OUT="$(python tools/evidence_root.py --print waves_chance_noise/$MAP)"
    args = sys.argv[1:]
    if args[:1] == ["--print"]:
        rel = args[1] if len(args) > 1 and not args[1].startswith("--") else ""
        kind = args[args.index("--kind") + 1] if "--kind" in args else "ada-run"
        print(evidence_dir(*[p for p in rel.split("/") if p], kind=kind).as_posix())
    else:
        enc = encyclopedia_path()
        print("encyclopedia:", enc if enc else "(not found - writers fall back to this repo)")
        print("evidence root:", evidence_dir())
