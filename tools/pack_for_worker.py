#!/usr/bin/env python
"""
pack_for_worker.py — wrap a bundle into a self-contained worker prompt.

Takes a bundle produced by bundle_sequence.py and emits a single markdown
file that any Claude Code session (on any machine with its own token)
can consume. The resulting file contains:

  1. Context: what Ada Research is, what a map is, what the target role
     (blurb/critical/summary/technical) should do.
  2. Voice rules: humanizer directives, QFEP framing, anti-AI-slop.
  3. The bundle itself, verbatim, inside a fenced ``ada-bundle`` block.
  4. Return protocol: edit in place, keep `<<<MAP: NAME>>>` markers,
     save as `*_edited.md`, then run split_sequence on the host machine.

Typical flow::

    # 1. Host (this machine): bundle the failing maps
    python tools/bundle_sequence.py --sequence primitives --file critical.md \\
        --only-failing --out doc/_bundles/primitives_critical.md

    # 2. Host: pack for a remote worker
    python tools/pack_for_worker.py \\
        --bundle doc/_bundles/primitives_critical.md \\
        --out doc/_bundles/primitives_critical.worker.md

    # 3. Worker (any Claude Code session): read the .worker.md, edit the
    #    bundle in place, save as *_edited.md, send back.

    # 4. Host: split the edited bundle back into per-map files
    python tools/split_sequence.py \\
        --in doc/_bundles/primitives_critical_edited.md

The packed file is self-contained — no repo access required on the worker
side. Exit code 0 on success, 2 on bad input.
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass


ROLE_BRIEFS = {
    "blurb.md": """\
**blurb.md** — 50–150 words, 1–3 short paragraphs. Invites the player
into the map. Names the artifact concretely, says what the player will
do or see. No AI-register scaffolding ("In this map, we explore…"),
no bullet lists, no headings. Present tense, specific nouns, one
surprising verb.""",
    "critical.md": """\
**critical.md** — 200–600 words. A critical reading of the algorithm
through queer theory / QFEP (Queer Field Equation for Persistence:
QFE = F − λE(S) + φΔE(S,t)). Grounds claims in the actual code or
artifact behaviour, not generic theory. Cite a theorist by name at
most twice. No "this map teaches us…"; instead show what the
algorithm resists, what it makes visible, whose body it assumes.""",
    "summary.md": """\
**summary.md** — 80–200 words. One paragraph. What is this map, what
is the algorithm, what does the player leave with. Reads like a
museum wall label: clear, specific, non-promotional.""",
    "technical.md": """\
**technical.md** — 300–900 words. How the algorithm actually works.
Reference the real artifact file(s) and functions if visible in the
INTENT/BLURB comments. At least one fenced code block showing the
core loop or data structure. Mention complexity / failure modes.
No motivational text, no "elegant solution" puffery.""",
}


HUMANIZER_RULES = """\
Voice rules (non-negotiable):

- No em-dashes used as dramatic pauses. Use commas, periods, or recast.
- Drop AI filler: "delve", "leverage", "crucial", "robust", "paradigm",
  "landscape", "journey", "unlock", "empower", "seamlessly", "furthermore".
- No tri-colons ("precise, powerful, profound"). Pick one word.
- No "it's worth noting that", "indeed", "moreover", "in essence".
- No closing moral ("This reminds us that…"). End on a concrete image.
- Contractions are fine. Short sentences are fine. Fragments are fine.
- Don't hedge every claim. Assert, then qualify once if needed.
"""


TASK_INSTRUCTIONS_TEMPLATE = """\
# Ada Research — Worker Task: rewrite {file_role}

## What Ada Research is

A VR curriculum in Godot 4. The player walks through maps in sequences;
each map teaches one algorithm through an interactable artifact. The
text files sit next to each map's scene and are read in-headset or in
the companion encyclopedia.

## What you're editing

A bundle of **{file_role}** files — one per map in the `{sequence_label}`
cohort. Each map is delimited by a `<<<MAP: NAME>>>` marker. The
front matter at the top (between `<<<ADA_BUNDLE>>>` / `<<</ADA_BUNDLE>>>`)
is metadata — leave it unchanged.

Comment headers inside each map section (`# FAILURE:`, `# INTENT:`,
`# BLURB:`, `# STATUS:`) are **editor hints for you**. Strip them on
output, or leave them — the split tool discards them either way.

## Role brief

{role_brief}

{humanizer_rules}

## Return protocol

1. Edit the bundle *in place* in the fenced block below.
2. Keep every `<<<MAP: NAME>>>` marker exactly as given. Do not rename,
   merge, reorder, or remove map sections. Missing markers will abort
   the split step.
3. Save your result as a file named `{out_stem}_edited.md`. Plain
   markdown, UTF-8, LF line endings.
4. Hand the edited file back to the host. On the host side we run:
   ``python tools/split_sequence.py --in <path>_edited.md``
   to write each map's `{file_role}` back into the repo (with
   `.before_bundle` backups).

**Do not** write any file other than the edited bundle. Do not invent
new map sections. Do not add a preamble or closing note outside the
map sections.

## The bundle

Everything between the fences is the bundle. Edit inside.

````ada-bundle
{bundle_body}
````

End of task.
"""


def detect_file_role(bundle_text: str) -> str:
    m = re.search(r"^file:\s*(\S+)", bundle_text, flags=re.MULTILINE)
    return m.group(1) if m else "technical.md"


def detect_sequence_label(bundle_text: str) -> str:
    m = re.search(r"^sequence:\s*(\S+)", bundle_text, flags=re.MULTILINE)
    return m.group(1) if m else "custom"


def pack(bundle_path: Path, out_path: Path) -> int:
    if not bundle_path.exists():
        print(f"[pack_for_worker] bundle not found: {bundle_path}", file=sys.stderr)
        return 2
    bundle_text = bundle_path.read_text(encoding="utf-8")
    if "<<<ADA_BUNDLE>>>" not in bundle_text:
        print(
            f"[pack_for_worker] {bundle_path} does not look like an Ada bundle "
            "(missing <<<ADA_BUNDLE>>> marker).",
            file=sys.stderr,
        )
        return 2

    file_role = detect_file_role(bundle_text)
    sequence_label = detect_sequence_label(bundle_text)
    role_brief = ROLE_BRIEFS.get(file_role, ROLE_BRIEFS["technical.md"])

    out_stem = out_path.stem
    if out_stem.endswith(".worker"):
        out_stem = out_stem[: -len(".worker")]

    prompt = TASK_INSTRUCTIONS_TEMPLATE.format(
        file_role=file_role,
        sequence_label=sequence_label,
        role_brief=role_brief,
        humanizer_rules=HUMANIZER_RULES,
        bundle_body=bundle_text.rstrip() + "\n",
        out_stem=out_stem,
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(prompt, encoding="utf-8")

    n_maps = len(re.findall(r"^<<<MAP:\s+\w+\s*>>>\s*$", bundle_text, flags=re.MULTILINE))
    size_kb = out_path.stat().st_size / 1024.0
    print(
        f"[pack_for_worker] wrote {out_path} "
        f"({n_maps} maps, {size_kb:.1f} KB, role={file_role}, seq={sequence_label})"
    )
    print(
        f"[pack_for_worker] hand this file to any Claude Code session; "
        f"expect back: {out_stem}_edited.md"
    )
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--bundle", required=True, help="Path to a bundle from bundle_sequence.py")
    ap.add_argument("--out", required=True, help="Output path for the packed worker prompt (.md)")
    args = ap.parse_args()

    return pack(Path(args.bundle), Path(args.out))


if __name__ == "__main__":
    raise SystemExit(main())
