#!/usr/bin/env python3
"""
apply_dna_block.py — write an artifact's `dna` block into the registry FROM ITS CODE.

The step this replaces was me, by hand, reading an agent's proposal and typing the value
list into a registry JSON file. That step produced science_screen's declaration of
housing = none|bezel|hooded|cabinet against a code enum of stand|wall|console|rig, which
nothing downstream could detect: the sweep set an invalid value, the artifact fell back
to its default, sixteen identical frames were published, and the critic reported the axis
INERT. A whole experiment about a registry typo, dressed as a fact about the design.

So the declaration is now DERIVED, never transcribed. The code is the only thing that
renders, which makes it the only thing that can be authoritative about what the values
are. `note` and `default` are prose and stay hand-written; `axes` is generated.

TWO REGISTRY HAZARDS, both learned by breaking them:
  - `commons_artifacts.json` and its siblings are {"artifacts": {token: {...}}} — a DICT
    keyed by token, not a list. A json.dumps() round-trip once reformatted 15,121 lines.
    So this edits the RAW TEXT surgically and only re-parses to validate.
  - Indentation is inconsistent across registry files (spaces in some, tabs in others,
    depth varying by file). The insert copies the indentation of the anchor line it
    lands next to rather than assuming any particular style.

Usage:
  python tools/apply_dna_block.py --token=curation_station --axes=bay,duty
  python tools/apply_dna_block.py --token=exhibit_vitrine --axes=enclosure,guard \
      --drop=enclosure:open            # an alias that must not become its own variant
  python tools/apply_dna_block.py --refresh          # re-derive every existing dna block
  python tools/apply_dna_block.py --refresh --dry-run
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_dna_declarations import (  # noqa: E402
    code_values, export_default, numeric_domain, source_for)

REPO = Path(__file__).resolve().parents[1]
REG_DIR = REPO / "commons" / "artifacts" / "registry"


def find_entry(token: str) -> tuple[Path, dict] | None:
    for rp in sorted(REG_DIR.glob("*.json")):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else data
        if isinstance(arts, dict) and token in arts and isinstance(arts[token], dict):
            return rp, arts[token]
    return None


def derive(token: str, entry: dict, axes: list[str], drop: dict[str, set]) -> dict:
    gd, src = source_for(entry)
    if not src:
        raise SystemExit(f"{token}: no script at {gd}")

    out: dict = {}
    for ax in axes:
        d = export_default(src, ax)
        num = numeric_domain(src, ax)
        if num is not None and code_values(src, ax)[0] is None:
            raise SystemExit(f"{token}.{ax}: numeric axis — declare its sample points by "
                             f"hand, they are a design choice, not a fact about the code")
        cv, how = code_values(src, ax)
        if cv is None:
            raise SystemExit(f"{token}.{ax}: cannot read values from the code ({how}). "
                             f"Refusing to guess — that is the failure this tool exists "
                             f"to prevent.")
        vals = list(cv)
        # The export default is legitimately absent from a match block: it is what the
        # `_:` fallthrough builds. It is still a value of the family.
        if d is not None and d not in vals:
            vals.insert(0, d)
        for bad in drop.get(ax, set()):
            if bad in vals:
                vals.remove(bad)
        # Default first, then the rest in source order — a sweep reads left to right and
        # the legacy lineage should be the leftmost tile.
        if d in vals:
            vals.remove(d)
            vals.insert(0, d)
        out[ax] = vals
    return out


def _entry_span(raw: str, open_brace: int) -> tuple[int, int]:
    """Byte range of ONE registry entry, by brace matching from its opening `{`.

    THE SEARCH MUST BE SCOPED TO THE ENTRY. Looking for `"dna"` in "the rest of the file"
    finds the NEXT artifact's block whenever the target has none of its own — which is
    exactly what happened the first time this ran: pick_up_cube had no dna block, so the
    search walked forward and overwrote request_note's axes with pick_up_cube's, silently
    and in a way JSON validation could never catch.
    """
    depth = 0
    j = open_brace
    while j < len(raw):
        c = raw[j]
        if c == '"':
            j = raw.index('"', j + 1) + 1
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return open_brace, j + 1
        j += 1
    return open_brace, len(raw)


def splice(rp: Path, token: str, axes: dict, dry: bool) -> bool:
    raw = rp.read_text(encoding="utf-8")
    m = re.search(r'^([ \t]*)"' + re.escape(token) + r'"\s*:\s*\{', raw, re.M)
    if not m:
        raise SystemExit(f"{token}: entry not found as a key in {rp.name}")
    outer = m.group(1)
    inner = outer + ("\t" if "\t" in outer or outer == "" else "  ")
    # Indentation inside the entry, taken from its first real field rather than guessed.
    fm = re.search(r'\n([ \t]+)"', raw[m.end():m.end() + 400])
    if fm:
        inner = fm.group(1)

    lo, hi = _entry_span(raw, m.end() - 1)
    entry_text = raw[lo:hi]

    body = json.dumps({"axes": axes}, indent=1)[1:-1].strip()  # drop the outer braces
    body = "\n".join(inner + " " + ln.strip() if i else inner + " " + ln.strip()
                     for i, ln in enumerate(body.splitlines()))

    existing = re.search(
        r'(\n[ \t]*"dna"\s*:\s*\{)(.*?)(\n[ \t]*\},?)(?=\n[ \t]*")', entry_text, re.S)
    if existing:
        block = entry_text[existing.start():existing.end()]
        # Replace ONLY the axes sub-object, so hand-written `note`/`default`/`promoted`
        # prose survives a refresh. Losing that prose would quietly delete the record of
        # why an axis exists.
        newblock, n = re.subn(r'("axes"\s*:\s*)\{.*?\n([ \t]*)\}',
                              lambda mm: mm.group(1) + json.dumps(axes, indent=1).replace(
                                  "\n", "\n" + mm.group(2)) , block, count=1, flags=re.S)
        if n == 0:
            raise SystemExit(f"{token}: has a dna block but no axes sub-object to replace")
        if newblock == block:
            return False
        if not dry:
            rp.write_text(raw[:lo] + entry_text.replace(block, newblock, 1) + raw[hi:],
                          encoding="utf-8")
        return True

    insert = f'\n{inner}"dna": {{\n{body}\n{inner}}},'
    if not dry:
        rp.write_text(raw[:m.end()] + insert + raw[m.end():], encoding="utf-8")
    return True


def main() -> int:
    token = ""
    axes: list[str] = []
    drop: dict[str, set] = {}
    refresh = False
    dry = False
    for a in sys.argv[1:]:
        if a.startswith("--token="):
            token = a.split("=", 1)[1]
        elif a.startswith("--axes="):
            axes = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
        elif a.startswith("--drop="):
            for pair in a.split("=", 1)[1].split(","):
                k, _, v = pair.partition(":")
                drop.setdefault(k.strip(), set()).add(v.strip())
        elif a == "--refresh":
            refresh = True
        elif a == "--dry-run":
            dry = True

    targets: list[tuple[str, list[str]]] = []
    if refresh:
        for rp in sorted(REG_DIR.glob("*.json")):
            try:
                data = json.loads(rp.read_text(encoding="utf-8"))
            except Exception:
                continue
            arts = data.get("artifacts", data) if isinstance(data, dict) else data
            if not isinstance(arts, dict):
                continue
            for tok, e in arts.items():
                ax = ((e.get("dna") or {}).get("axes") or {}) if isinstance(e, dict) else {}
                if ax:
                    targets.append((tok, list(ax)))
    elif token and axes:
        targets = [(token, axes)]
    else:
        print(__doc__)
        return 2

    changed = 0
    for tok, ax in targets:
        found = find_entry(tok)
        if not found:
            print(f"  {tok}: not in any registry")
            continue
        rp, entry = found
        try:
            derived = derive(tok, entry, ax, drop)
        except SystemExit as ex:
            print(f"  {tok}: {ex}")
            continue
        before = ((entry.get("dna") or {}).get("axes") or {})
        if {k: [str(x) for x in v] for k, v in before.items()} == derived:
            print(f"  {tok}: already matches the code")
            continue
        if splice(rp, tok, derived, dry):
            changed += 1
            print(f"  {tok} [{rp.name}]{' (dry run)' if dry else ''}")
            for k, v in derived.items():
                was = before.get(k)
                print(f"     {k}: {v}" + (f"    was {was}" if was and list(was) != v else ""))
        json.loads(rp.read_text(encoding="utf-8"))  # fail loudly if the splice broke JSON

    print(f"\n{changed} entr{'y' if changed == 1 else 'ies'} written")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
