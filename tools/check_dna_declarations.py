#!/usr/bin/env python3
"""
check_dna_declarations.py — does the registry's DNA declaration match the code?

WHY THIS EXISTS. science_screen shipped a `dna.axes` block declaring
housing = none|bezel|hooded|cabinet and surface = flat|curved|tiles|frosted. The code's
actual enums were stand|wall|console|rig and plane|curve|triptych|tiles. Nothing in the
pipeline noticed:

  - the sweep set an invalid value and the artifact fell back to its default
  - sixteen identical frames were written and published to the gallery
  - the critic measured them and reported the axis INERT at 0.69% focus

Every stage ran green and the conclusion was a lie about the artifact's design when it
was really a fact about the registry. Exactly one value, `tiles`, appeared in both lists
by coincidence, which is why the second axis scored a nonzero 0.29% instead of a clean
zero — a partial signal is harder to notice than no signal at all.

That is the failure class this guards. A declaration that names values the code cannot
reach is not a small bookkeeping error; it silently converts the whole evidence loop into
an experiment about the registry file.

WHAT COUNTS AS THE CODE'S VALUES, in priority order — each is a stronger claim than the
next, and the first one found wins:
  1. @export_enum("a", "b", "c")            — the author enumerated them
  2. _pick_axis(..., SOME_CONST, ...)       — the token parser's allow-list
  3. const TABLE := {"a": …, "b": …}        — a dispatch dictionary keyed by the value
  4. match <axis>:  "a": … "b": …           — what the builder branches on (all blocks,
                                              unioned: an artifact may match twice)
  5. a trailing  # a | b | c  comment       — a convention in this codebase
An axis with none of these is UNVERIFIABLE: reported, but not failed, because absence of
a signature is not evidence of a wrong declaration.

TWO WAYS THIS CHECKER CAN ITSELF LIE, both found by running it and both now handled. It
first reported seven mismatches; six were its own fault:

  - THE DEFAULT HAS NO CASE. `match guard:` lists lit/framed/guarded and lets `_:` catch
    "none", because "none" means build no barrier. That is correct code. A declared value
    absent from the cases is only an error when it is NOT the export default — which is
    exactly the vitrine's real bug, where "niche" was declared, had no case, was not the
    default, and silently rendered as a box.
  - NUMERIC AXES ARE NOT ENUMS. multiple_ring.count and bias_from_inside.perspective_blend
    declare sample points along a range, not names. Demanding a match block for them would
    report a whole legitimate class of axis as unverifiable noise; they are range-checked
    instead.

That is the same disease this tool exists to cure, one level up: an instrument reporting a
fact about itself as a fact about the thing it measures.

Usage:
  python tools/check_dna_declarations.py                 # audit every promoted artifact
  python tools/check_dna_declarations.py --token=science_screen
  python tools/check_dna_declarations.py --quiet         # only problems
Exit code is the number of artifacts with a hard mismatch, so it works as a gate.
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def registry() -> dict:
    out: dict = {}
    for rp in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else data
        if isinstance(arts, dict):
            for tok, e in arts.items():
                if isinstance(e, dict):
                    out[tok] = (e, rp.name)
    return out


def source_for(entry: dict) -> tuple[Path | None, str]:
    """The script a scene actually runs — read from the .tscn, not guessed from its name.

    Swapping .tscn for .gd is right for most artifacts and wrong for the ones that matter:
    info_board.tscn runs AnnotationInfoBoard.gd, so the name-swap found a 27-line stub and
    reported the axis unreadable. The scene file names its own script; ask it.
    """
    sp = str(entry.get("scene_path") or entry.get("scene") or "")
    if not sp:
        return None, ""
    tscn = REPO / sp.replace("res://", "")
    if tscn.suffix == ".tscn" and tscn.exists():
        text = tscn.read_text(encoding="utf-8", errors="replace")
        ids = dict(re.findall(
            r'\[ext_resource type="Script"[^\]]*?path="([^"]+)"[^\]]*?id="([^"]+)"', text))
        root = re.search(r'\n\[node name="[^"]*" type="[^"]*"[^\]]*\](.*?)(?=\n\[|\Z)',
                         text, re.S)
        want = None
        if root:
            rm = re.search(r'script\s*=\s*ExtResource\("([^"]+)"\)', root.group(1))
            if rm:
                want = rm.group(1)
        for path, rid in ids.items():
            if want is None or rid == want:
                gd = REPO / path.replace("res://", "")
                if gd.exists():
                    return gd, gd.read_text(encoding="utf-8", errors="replace")
    gd = REPO / sp.replace("res://", "").replace(".tscn", ".gd")
    if not gd.exists():
        return gd, ""
    return gd, gd.read_text(encoding="utf-8", errors="replace")


def _strings(blob: str) -> list[str]:
    return re.findall(r'"([^"]*)"', blob)


def _dict_keys(src: str, name: str) -> list[str]:
    """Top-level keys of `const NAME := { ... }`, by brace depth.

    Regex cannot do this: these tables are dictionaries of dictionaries, and a flat
    search for `"key":` would return every nested field name as a valid axis value.
    """
    m = re.search(r'const\s+' + re.escape(name) + r'\s*(?::[^=]*)?:?=\s*\{', src)
    if not m:
        return []
    i = src.index("{", m.end() - 1)
    depth = 0
    keys: list[str] = []
    j = i
    while j < len(src):
        c = src[j]
        if c == '"':
            k = src.index('"', j + 1)
            lit = src[j + 1:k]
            rest = src[k + 1:k + 40].lstrip()
            if depth == 1 and rest.startswith(":"):
                keys.append(lit)
            j = k + 1
            continue
        if c == "{" or c == "[":
            depth += 1
        elif c == "}" or c == "]":
            depth -= 1
            if depth == 0:
                break
        j += 1
    return keys


def code_values(src: str, axis: str) -> tuple[list[str] | None, str]:
    """Return (values, how) or (None, reason). See the docstring for the priority order."""
    a = re.escape(axis)

    m = re.search(r'@export_enum\(([^)]*)\)\s*var\s+' + a + r'\b', src)
    if m:
        return _strings(m.group(1)), "@export_enum"

    # _pick_axis(str(config_data["housing"]), HOUSINGS, housing) — the allow-list the
    # token parser validates against, which is the thing a map actually hits.
    m = re.search(r'_pick_axis\([^)]*?,\s*([A-Z][A-Z0-9_]*)\s*,\s*' + a + r'\s*\)', src)
    if m:
        cm = re.search(r'const\s+' + re.escape(m.group(1)) + r'\s*(?::[^=]*)?:?=\s*\[(.*?)\]',
                       src, re.S)
        if cm:
            return _strings(cm.group(1)), f"const {m.group(1)}"

    # BELOW THE ENUM, EVERY SOURCE IS PARTIAL, SO THEY ARE UNIONED RATHER THAN RANKED.
    # Preferring one construct over another was wrong twice in a row on real files:
    #   - AnnotationInfoBoard indexes a canonical VOICES table AND small per-value tweak
    #     tables (LIST_DEG, LEAN_DEG) holding only the values they modify. Taking the
    #     first table read `voice` as a one-value axis; taking the FULLEST table still
    #     read `carriage` as none|easel, because its real list lives in a match block.
    #   - station_crates dispatches with an if/elif chain and nothing else, so any
    #     table-or-match rule found no values for it at all.
    # Each of these constructs is keyed BY an axis value, so anything they mention is a
    # real value. Union is both safer and strictly more informative than a priority order.
    vals: list[str] = []
    hows: list[str] = []

    def add(found: list[str], how: str) -> None:
        new = [v for v in found if v not in vals]
        if new:
            vals.extend(new)
            if how not in hows:
                hows.append(how)

    for n in {n for n in re.findall(
            r'\b([A-Z][A-Z0-9_]*)\s*(?:\.get\(\s*' + a + r'\b|\[\s*' + a + r'\s*\])', src)}:
        add(_dict_keys(src, n), f"const {n}")

    # EVERY `match <axis>:` block. exhibit_vitrine has two — one to build the case and
    # one to return its metrics — and reading only the first understates the code.
    wildcard = False
    for m in re.finditer(r'^([ \t]*)match\s+(?:self\.)?' + a + r'\s*:\s*$', src, re.M):
        indent = m.group(1)
        for line in src[m.end():].splitlines():
            if line.strip() and not line.startswith(indent + "\t") and not line.startswith(indent + " "):
                break
            if re.match(r'^[ \t]+_\s*:\s*$', line):
                wildcard = True
                continue
            cm = re.match(r'^[ \t]+((?:"[^"]*"\s*,?\s*)+):\s*$', line)
            if cm:
                add(_strings(cm.group(1)), "match block")

    add(re.findall(r'\b(?:if|elif)\s+' + a + r'\s*==\s*"([^"]*)"', src), "if/elif chain")
    # `upkeep != "store"` also proves "store" is a value the code distinguishes.
    add(re.findall(r'\b' + a + r'\s*!=\s*"([^"]*)"', src), "inequality guard")

    if vals:
        return vals, " + ".join(hows) + (" (with _: fallthrough)" if wildcard else "")

    m = re.search(r'@export[^\n]*\bvar\s+' + a + r'\b[^\n]*#\s*([a-z0-9_]+(?:\s*\|\s*[a-z0-9_]+)+)',
                  src)
    if m:
        return [v.strip() for v in m.group(1).split("|")], "trailing comment"

    return None, "no enum, allow-list, dispatch table, match block or value comment found"


def numeric_domain(src: str, axis: str) -> tuple[str, tuple[float, float] | None] | None:
    """('float'|'int'|'bool', (lo, hi) or None) when the axis is a number or flag.

    A numeric axis declares SAMPLE POINTS along a continuum, not names, so enum checking
    is the wrong question for it entirely — the right one is whether the samples are in
    range and actually distinct.
    """
    a = re.escape(axis)
    m = re.search(r'@export_range\(\s*([-\d.]+)\s*,\s*([-\d.]+)[^)]*\)\s*var\s+' + a + r'\b', src)
    if m:
        kind = "int"
        t = re.search(r'var\s+' + a + r'\s*:\s*(\w+)', src)
        if t and t.group(1) == "float":
            kind = "float"
        return kind, (float(m.group(1)), float(m.group(2)))
    m = re.search(r'@export[^\n]*\bvar\s+' + a + r'\s*:\s*(int|float|bool)\b', src)
    if m:
        return m.group(1), None
    m = re.search(r'@export[^\n]*\bvar\s+' + a + r'\b[^\n]*?=\s*(true|false)\b', src)
    if m:
        return "bool", None
    m = re.search(r'@export[^\n]*\bvar\s+' + a + r'\b[^\n]*?=\s*(-?\d+\.\d+)', src)
    if m:
        return "float", None
    m = re.search(r'@export[^\n]*\bvar\s+' + a + r'\b[^\n]*?=\s*(-?\d+)\s*(?:#|$)', src, re.M)
    if m:
        return "int", None
    return None


def export_default(src: str, axis: str) -> str | None:
    m = re.search(r'@export[^\n]*\bvar\s+' + re.escape(axis) + r'\b[^\n]*?=\s*"([^"]*)"', src)
    return m.group(1) if m else None


def has_export(src: str, axis: str) -> bool:
    return re.search(r'@export[^\n]*\bvar\s+' + re.escape(axis) + r'\b', src) is not None


def check_token(tok: str, entry: dict) -> list[dict]:
    """One row per declared axis. status: ok | MISMATCH | NO_EXPORT | unverifiable."""
    axes = ((entry.get("dna") or {}).get("axes") or {})
    if not axes:
        return []
    gd, src = source_for(entry)
    if not src:
        return [{"token": tok, "axis": ax, "status": "NO_EXPORT",
                 "detail": f"source unreadable: {gd}"} for ax in axes]

    rows = []
    for ax, declared in axes.items():
        dv = [str(v) for v in declared]
        if not has_export(src, ax):
            # The unreachable-critical_parameter class: a declared knob nobody can set.
            rows.append({"token": tok, "axis": ax, "status": "NO_EXPORT",
                         "detail": f"declared {dv} but there is no `@export var {ax}`",
                         "declared": dv, "code": None})
            continue
        num = numeric_domain(src, ax)
        if num is not None:
            kind, rng = num
            # A JSON true/false arrives here as Python True/False, whose str() is "True" —
            # which is neither a number nor GDScript's spelling. Reading them as literal
            # strings made this checker report two correct declarations as broken, so the
            # bool case is handled before anything is stringified.
            nums, bad_parse = [], []
            for v in dv:
                if isinstance(v, bool):
                    nums.append(1.0 if v else 0.0)
                    continue
                s = str(v).strip().lower()
                if s in ("true", "false"):
                    nums.append(1.0 if s == "true" else 0.0)
                    continue
                try:
                    nums.append(float(s))
                except ValueError:
                    bad_parse.append(v)
            if bad_parse:
                rows.append({"token": tok, "axis": ax, "status": "MISMATCH",
                             "detail": f"{ax} is a {kind}, but declared value(s) are not "
                                       f"numeric: {bad_parse}",
                             "declared": dv, "code": [kind]})
                continue
            if rng and any(n < rng[0] or n > rng[1] for n in nums):
                out = [v for v, n in zip(dv, nums) if n < rng[0] or n > rng[1]]
                rows.append({"token": tok, "axis": ax, "status": "MISMATCH",
                             "detail": f"declared sample(s) outside @export_range"
                                       f"({rng[0]}, {rng[1]}): {out}",
                             "declared": dv, "code": [f"{kind} in {rng}"]})
                continue
            if len(set(nums)) < len(nums):
                rows.append({"token": tok, "axis": ax, "status": "MISMATCH",
                             "detail": f"declared samples are not distinct: {dv}",
                             "declared": dv, "code": [kind]})
                continue
            rows.append({"token": tok, "axis": ax, "status": "ok",
                         "detail": f"{kind} axis, {len(nums)} distinct sample(s)"
                                   + (f" within {rng}" if rng else ""),
                         "declared": dv, "code": [kind]})
            continue

        cv, how = code_values(src, ax)
        if cv is None:
            rows.append({"token": tok, "axis": ax, "status": "unverifiable",
                         "detail": how, "declared": dv, "code": None})
            continue
        # The export DEFAULT legitimately has no case of its own — `match guard:` handles
        # lit/framed/guarded and lets `_:` catch "none", because "none" means build no
        # barrier. Only a NON-default value with no case is a real fault: it silently
        # renders as whatever the fallthrough builds, which is the default. That is the
        # bug that put "niche" in exhibit_vitrine's registry against a code case of "open".
        d = export_default(src, ax)
        missing = [v for v in dv if v not in cv and v != d]
        extra = [v for v in cv if v not in dv]
        if missing:
            rows.append({"token": tok, "axis": ax, "status": "MISMATCH",
                         "detail": f"declared value(s) with no branch in the code, so they "
                                   f"render as the default: {missing}"
                                   + (f"; meanwhile the code offers undeclared {extra}"
                                      if extra else "")
                                   + f"  (via {how})",
                         "declared": dv, "code": cv})
            continue
        if d is not None and d not in dv:
            rows.append({"token": tok, "axis": ax, "status": "MISMATCH",
                         "detail": f'default "{d}" is not among the declared values (via {how})',
                         "declared": dv, "code": cv})
            continue
        note = f"ok via {how}" + (f"; code also offers undeclared {extra}" if extra else "")
        rows.append({"token": tok, "axis": ax,
                     "status": "UNDECLARED" if extra else "ok", "detail": note,
                     "declared": dv, "code": cv})
    return rows


PROMOTION_MARK = re.compile(
    r"STAGE-2 DNA|DNA PROMOTION|stage 2, promoted|--- DNA \(stage 2", re.I)


def undeclared_promotions(reg: dict) -> list[tuple[str, str]]:
    """Artifacts whose SOURCE carries a promotion but whose registry says nothing.

    The rest of this tool reads declarations and asks whether the code backs
    them. That direction cannot see the opposite failure: axes written into a
    script and never declared. Those are worse than a mismatch, because nothing
    reports them at all — the sweep has no axis to turn, so the artifact sits in
    the agenda looking un-promoted while its knobs already exist. Found this way
    after a run of promoting agents died mid-task, having written scripts but
    not registries.
    """
    out: list[tuple[str, str]] = []
    for tok, (entry, rf) in sorted(reg.items()):
        if isinstance(entry.get("dna"), dict):
            continue
        src_path, src = source_for(entry)
        if not src or not PROMOTION_MARK.search(src):
            continue
        axes = re.findall(r"@export_enum\([^)]*\)\s*var\s+(\w+)", src)
        out.append((tok, ", ".join(axes) if axes else "(promotion marker, no enum axis found)"))
    return out


def main() -> int:
    only = ""
    quiet = False
    for a in sys.argv[1:]:
        if a.startswith("--token="):
            only = a.split("=", 1)[1]
        elif a == "--quiet":
            quiet = True

    reg = registry()
    rows: list[dict] = []
    for tok, (entry, _rf) in sorted(reg.items()):
        if only and tok != only:
            continue
        rows.extend(check_token(tok, entry))

    bad = [r for r in rows if r["status"] in ("MISMATCH", "NO_EXPORT")]
    unv = [r for r in rows if r["status"] == "unverifiable"]
    und = [r for r in rows if r["status"] == "UNDECLARED"]

    if not quiet:
        print(f"{'artifact.axis':46} status")
        print("-" * 78)
        for r in rows:
            mark = {"ok": "ok", "unverifiable": "?", "MISMATCH": "MISMATCH",
                    "NO_EXPORT": "NO EXPORT", "UNDECLARED": "undeclared value"}[r["status"]]
            print(f"{r['token'] + '.' + r['axis']:46} {mark}  {r['detail'] if r['status'] != 'ok' else ''}")
        print("-" * 78)
    print(f"{len(rows)} declared axes · {len(rows)-len(bad)-len(unv)-len(und)} verified"
          f" · {len(und)} with an undeclared code value · {len(unv)} unverifiable"
          f" · {len(bad)} broken")
    for r in und:
        print(f"\n  {r['token']}.{r['axis']}  [the code can build a value the registry never "
              f"declares, so the sweep never renders it]\n    {r['detail']}")

    for r in bad:
        print(f"\n  {r['token']}.{r['axis']}  [{r['status']}]")
        print(f"    {r['detail']}")
        if r.get("code"):
            print(f"    declared {r['declared']}\n    code     {r['code']}")
    if unv and not quiet:
        print("\nunverifiable (no machine-readable value list in the source — not a failure):")
        for r in unv:
            print(f"  {r['token']}.{r['axis']}: {r['detail']}")

    orphans = undeclared_promotions(reg)
    if orphans:
        print(f"\n{len(orphans)} promoted in code, undeclared in the registry "
              f"[the axes exist but the sweep can never reach them]:")
        for tok, axes in orphans:
            print(f"  {tok}: {axes}")

    return len({r["token"] for r in bad})


if __name__ == "__main__":
    raise SystemExit(main())
