#!/usr/bin/env python3
"""build_text_mentions.py — which artifacts does the WRITING actually name?

The corpus has placement indexes (spine_artifact_order.json: where artifacts
STAND) and per-artifact pages (artifact-md), but no index of where artifacts
are NAMED in the prose. This scans every per-map text file for registry
lookup-name mentions (word-boundary, underscores kept) and writes the
cross-reference both ways:

  doc/book/text_mentions.json
    by_artifact: token -> {mentions: N, files: ["Map/kind.md", ...]}
    by_map:      Map -> {kind -> [tokens]}
    never_mentioned: alive tokens no text ever names
    ghost_mentions: tokens named in text that are NOT in the registry

Provenance: measured (a grep is a measurement). Regenerate after writing
passes. Usage: python tools/build_text_mentions.py [--kind=walked]
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
KINDS = ["walked", "tutorial", "blurb", "critical", "intent", "technical", "summary"]


def alive_tokens() -> set[str]:
    toks: set[str] = set()
    for rp in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", {})
        if isinstance(arts, dict):
            for tok, e in arts.items():
                if isinstance(e, dict) and str(e.get("scene", "") or e.get("scene_path", "")).strip():
                    toks.add(tok)
    return toks


def main() -> int:
    only_kind = ""
    for a in sys.argv[1:]:
        if a.startswith("--kind="):
            only_kind = a.split("=", 1)[1]
    kinds = [only_kind] if only_kind else KINDS
    toks = alive_tokens()
    # one compiled alternation is ~100x faster than 750 searches per file
    pat = re.compile(r"(?<![A-Za-z0-9_])(" + "|".join(
        re.escape(t) for t in sorted(toks, key=len, reverse=True)) + r")(?![A-Za-z0-9_])")
    by_artifact: dict[str, dict] = {}
    by_map: dict[str, dict] = {}
    ghost: dict[str, int] = {}
    token_like = re.compile(r"(?<![A-Za-z0-9_])([a-z][a-z0-9]+(?:_[a-z0-9]+){1,5})(?![A-Za-z0-9_])")
    files = 0
    for d in sorted(MAPS.iterdir()):
        if not d.is_dir():
            continue
        for kind in kinds:
            p = d / f"{kind}.md"
            if not p.is_file():
                continue
            files += 1
            text = p.read_text(encoding="utf-8", errors="replace")
            found = sorted(set(pat.findall(text)))
            if found:
                by_map.setdefault(d.name, {})[kind] = found
                for t in found:
                    e = by_artifact.setdefault(t, {"mentions": 0, "files": []})
                    e["mentions"] += text.count(t)
                    e["files"].append(f"{d.name}/{kind}.md")
            # ghost mentions: token-shaped words the registry does not know
            for w in set(token_like.findall(text)):
                if w not in toks and "_" in w:
                    ghost[w] = ghost.get(w, 0) + 1
    never = sorted(toks - set(by_artifact))
    # ghosts seen in 3+ files are likely renamed/dead tokens worth a look
    ghosts = {w: n for w, n in sorted(ghost.items(), key=lambda kv: -kv[1]) if n >= 3}
    # single-word tokens (point, cube, line) are ALSO ordinary English — a match
    # proves nothing. They are kept, but bucketed apart so the headline numbers
    # only count names a sentence cannot use by accident.
    sure = {k: v for k, v in by_artifact.items() if "_" in k}
    ambiguous = {k: v["mentions"] for k, v in by_artifact.items() if "_" not in k}
    never_sure = [t for t in never if "_" in t]
    out = {
        "_readme": "text -> artifact cross-reference; measured by scan, regenerate after "
                   "writing passes (tools/build_text_mentions.py). Single-word tokens are "
                   "bucketed as ambiguous: 'point' in prose is not evidence of the artifact.",
        "scanned_files": files,
        "alive_tokens": len(toks),
        "mentioned_unambiguous": len(sure),
        "never_mentioned_unambiguous": never_sure,
        "ambiguous_single_word_counts": ambiguous,
        "ghost_mentions_3plus": ghosts,
        "by_artifact": {k: sure[k] for k in sorted(sure)},
        "by_map": by_map,
    }
    dst = REPO / "doc" / "book" / "text_mentions.json"
    dst.write_text(json.dumps(out, indent=1), encoding="utf-8")
    top = sorted(sure.items(), key=lambda kv: -kv[1]["mentions"])[:10]
    print(f"{files} text files scanned · {len(toks)} alive artifacts · "
          f"{len(sure)} named unambiguously in prose · {len(never_sure)} never mentioned · "
          f"{len(ambiguous)} single-word tokens bucketed ambiguous · "
          f"{len(ghosts)} ghost tokens (3+ files) -> {dst.relative_to(REPO)}")
    print("most-written-about (unambiguous):")
    for t, e in top:
        print(f"  {t:36} {e['mentions']:4} mentions in {len(e['files'])} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
