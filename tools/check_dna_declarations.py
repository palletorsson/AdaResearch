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
    """Every artifact entry, preferring the one that can actually be built.

    A lookup name can appear in more than one file here, and not every file is an artifact
    registry: substrate_vectors.json is a feature-weight table keyed by the same names. Under
    last-write-wins a body-less entry displaced the real one and this checker then read ZERO
    declared axes for armadillo_eggling — reporting a fact about file ordering as a fact about
    the artifact, which is the exact disease this tool exists to cure. artifact_dna_research.py
    already carries this guard; it belongs here too.
    """
    out: dict = {}

    def buildable(e: dict) -> bool:
        return bool(str(e.get("scene", "") or e.get("scene_path", "")).strip()
                    or str(e.get("delegate_to", "")).strip())

    for rp in sorted((REPO / "commons" / "artifacts" / "registry").glob("*.json")):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else data
        if isinstance(arts, dict):
            for tok, e in arts.items():
                if not isinstance(e, dict):
                    continue
                prev = out.get(tok)
                if prev is not None and buildable(prev[0]) and not buildable(e):
                    continue
                out[tok] = (e, rp.name)
    return out


_TOKEN_INDEX: dict | None = None


def _entry_by_token(token: str) -> dict | None:
    """The registry entry a delegate_to names, from a lazily built token index.

    Memoized because sources_for runs once per declared axis-carrying token and
    registry() re-reads every JSON file; one scan serves the whole gate run.
    """
    global _TOKEN_INDEX
    if _TOKEN_INDEX is None:
        _TOKEN_INDEX = {tok: e for tok, (e, _f) in registry().items()}
    e = _TOKEN_INDEX.get(token)
    return e if isinstance(e, dict) else None


def sources_for(entry: dict) -> list[tuple[Path, str]]:
    """EVERY script the scene runs, the root's first.

    Swapping .tscn for .gd is right for most artifacts and wrong for the ones that matter:
    info_board.tscn runs AnnotationInfoBoard.gd, so the name-swap found a 27-line stub and
    reported the axis unreadable. The scene file names its own script; ask it.

    WHY A LIST AND NOT ONE PATH. Asking the .tscn and taking the ROOT's script is right for
    info_board and wrong for the NOC forces family, whose scenes are shaped

        [Example_2_x]   <- forces_demo_root.gd, a pass-through that only forwards config down
          └── FishTank
                └── Demo   <- the @export and the axis live HERE

    Resolving to the root alone read a script with no exports in it and reported two correct
    declarations as NO_EXPORT. The reverse of the science_screen fault, and just as loud: a
    fact about scene shape wearing the costume of a verdict about the registry. So offer
    every script the scene lists, root first, and let the caller take the one that actually
    declares the axis it is asking about.

    AND THE SCRIPTS THEY INHERIT FROM. draw_dot_time_domain.gd is 92 lines that open with
    `extends "res://commons/primitives/point/draw_dot.gd"`, and every knob it exposes to a
    map — the whole retention record, its RETENTIONS allow-list, its apply_grid_config — is
    the parent's. Reading only the child's own file reported a working, reachable, already
    implemented axis as NO_EXPORT, which is the same fault as the two above wearing a third
    costume: a fact about WHERE a line of code is written, presented as a verdict about the
    registry. Only `extends "res://..."` is followed; `extends SomeClassName` would need the
    class_name index and has not been needed yet.

    AND THE SCENE A DELEGATE RUNS. loom_alhambra_p6m has no scene of its own — it is a
    registry NAME onto pattern_loom plus delegate_params, the same contract
    GridInteractablesComponent resolves at spawn. Reading only the entry reported a working,
    reachable, already implemented axis as "source unreadable: None" — a fact about WHERE
    a scene path is written, presented as a verdict about the registry (the same disease as
    the three above, fourth costume). So an entry with no scene but a `delegate_to` is read
    through its host's entry, hop-capped so a cycle cannot hang the gate.
    """
    out: list[tuple[Path, str]] = []
    seen: set[Path] = set()

    def add(p: Path) -> None:
        if p in seen or not p.exists():
            return
        seen.add(p)
        out.append((p, p.read_text(encoding="utf-8", errors="replace")))

    sp = str(entry.get("scene_path") or entry.get("scene") or "")
    if not sp:
        e, seen_tok = entry, set()
        while not sp and len(seen_tok) < 4:
            tgt = str(e.get("delegate_to", "")).strip()
            if not tgt or tgt in seen_tok:
                break
            seen_tok.add(tgt)
            nxt = _entry_by_token(tgt)
            if nxt is None:
                break
            e = nxt
            sp = str(e.get("scene_path") or e.get("scene") or "")
    if not sp:
        return out
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
        if want is not None:
            for path, rid in ids.items():
                if rid == want:
                    add(REPO / path.replace("res://", ""))
        for path in ids:
            add(REPO / path.replace("res://", ""))
    if not out:
        add(REPO / sp.replace("res://", "").replace(".tscn", ".gd"))
    # Walk the inheritance chain of everything found so far. add() appends to `out`, so the
    # index-based loop picks up grandparents too, and `seen` stops a cycle.
    i = 0
    while i < len(out):
        src = out[i][1]
        i += 1
        for m in re.finditer(r'^extends\s+"([^"]+)"', src, re.M):
            add(REPO / m.group(1).replace("res://", ""))
    return out


def source_for(entry: dict) -> tuple[Path | None, str]:
    """The scene's primary script — the root's if it has one. See sources_for()."""
    srcs = sources_for(entry)
    if srcs:
        return srcs[0]
    sp = str(entry.get("scene_path") or entry.get("scene") or "")
    if not sp:
        return None, ""
    return REPO / sp.replace("res://", "").replace(".tscn", ".gd"), ""


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
    # LIVING specimens (the biome's organisms) are not scenes: an entry with a
    # `biome_token` is a grammar token (kingdom:algo:role) rendered by a
    # morphology, so it has no .tscn and no @export to read. Its values are
    # derived by tools/promote_living_dna.py from the grammar parser, the
    # dispatcher's algo branches and the preset families on disk — a different
    # authority, but still DERIVED, never transcribed. Report them as
    # unverifiable-by-this-gate rather than a fake NO_EXPORT failure.
    if entry.get("biome_token"):
        derived = ((entry.get("dna") or {}).get("derived_from") or "promote_living_dna.py")
        return [{"token": tok, "axis": ax, "status": "unverifiable",
                 "detail": f"living specimen (no scene); derived from {derived}"}
                for ax in axes]
    all_srcs = sources_for(entry)
    gd, base_src = source_for(entry)
    if not base_src:
        return [{"token": tok, "axis": ax, "status": "NO_EXPORT",
                 "detail": f"source unreadable: {gd}"} for ax in axes]

    rows = []
    for ax, declared in axes.items():
        # PER AXIS, not per scene: the knob may live on a script the scene runs BELOW its
        # root behind a pass-through. Take the first script that actually exports it, and
        # only fall back to the root's when nothing in the scene does — so a genuinely
        # missing export still reports NO_EXPORT against the primary script.
        src = base_src
        for _cand_gd, cand_src in all_srcs:
            if has_export(cand_src, ax):
                src = cand_src
                break

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


def code_axis_names(src: str) -> list[str]:
    """The axis names a script actually implements, by the same standard as code_values.

    Looking only for @export_enum was too narrow and made this tool lie in both
    directions. Most promotions in this codebase declare `@export var evidence: String`
    and branch on it in a `match` block — sine_wave_controller does exactly that, and the
    enum-only search reported "no enum axis found" for a file whose axis was right there.
    A string export ALONE is not an axis, though: finish, unit_code and a dozen other
    cabinet-grammar fields are strings nobody sweeps. What makes a string export an axis
    is that the builder BRANCHES on it, or that a map can set it through the config hook.
    """
    names: list[str] = []

    def add(n: str) -> None:
        if n not in names:
            names.append(n)

    for n in re.findall(r"@export_enum\([^)]*\)\s*var\s+(\w+)", src):
        add(n)
    for m in re.finditer(r"@export[^\n]*\bvar\s+(\w+)\s*:\s*String\b", src):
        n = m.group(1)
        a = re.escape(n)
        if (re.search(r"^[ \t]*match\s+(?:self\.)?" + a + r"\s*:\s*$", src, re.M)
                or re.search(r"config_" + a + r"\b", src)
                or re.search(r"_pick_axis\([^)]*,\s*" + a + r"\s*\)", src)):
            add(n)
    return names


def undeclared_promotions(reg: dict) -> tuple[list[tuple[str, str]], list[str]]:
    """(orphans, note_only) — artifacts whose SOURCE claims a promotion the registry lacks.

    The rest of this tool reads declarations and asks whether the code backs
    them. That direction cannot see the opposite failure: axes written into a
    script and never declared. Those are worse than a mismatch, because nothing
    reports them at all — the sweep has no axis to turn, so the artifact sits in
    the agenda looking un-promoted while its knobs already exist. Found this way
    after a run of promoting agents died mid-task, having written scripts but
    not registries.

    A THIRD STATE, and the reason this returns two lists. lambda_slider carries a
    forty-line STAGE-2 note dated 2026-07-27 describing a `calibration` axis with five
    values and what each does with the part it cannot represent — and the file has no
    such export, no match block, no config hook. The note is the whole promotion. Under
    the old single-bucket report that file printed under the heading "the axes exist but
    the sweep can never reach them", which is a claim this function had never checked and
    which was false. Reporting an unimplemented note as an undeclared axis invites the
    obvious fix — declare it — and that fix is the science_screen disease in the docstring
    above: a registry naming values the code cannot reach. They are opposite repairs, so
    they are counted apart.
    """
    orphans: list[tuple[str, str]] = []
    note_only: list[str] = []
    for tok, (entry, rf) in sorted(reg.items()):
        if isinstance(entry.get("dna"), dict):
            continue
        src_path, src = source_for(entry)
        if not src or not PROMOTION_MARK.search(src):
            continue
        axes = code_axis_names(src)
        if axes:
            orphans.append((tok, ", ".join(axes)))
        else:
            note_only.append(tok)
    return orphans, note_only



def untracked_sources(reg: dict) -> list:
    """Declared axes whose implementing script is not IN THE REPOSITORY.

    THE BLIND SPOT THIS CLOSES. Everything else in this file reads the WORKING TREE, so a
    declaration verifies clean against code that exists on one machine and nowhere else.
    That has now happened twice, from two different causes:

      - a synth-rack promotion, 270 lines, landed inside addons/element_editor/, which
        .gitignore excludes; the registry would have declared an axis whose code was not in
        the repo, and the gate said 0 broken.
      - grid_3d_capture's `bed` axis sat in tools/grid_editor/ and was simply never staged,
        because the commit that shipped its declaration added commons/ and algorithms/ only.

    A fresh clone in either case gets a declared axis with no dispatch behind it. `git
    ls-files --error-unmatch` is the only question that distinguishes "present" from
    "committed", so it is the one asked here.

    ASKED PER AXIS, NOT PER SCENE (2026-08-07). Flagging a token because ANY script its
    scene runs is untracked made this gate red on five declarations that were entirely
    fine. force_cube extends commons/artifacts/_embodied/pickable_prop.gd, which extends
    the gitignored XR-tools pickable.gd — so the walk up `extends` reached a vendored
    base class and reported it as a stranded declaration, while `decomposition` sat two
    hops down in force_cube.gd, tracked, with its @export_enum and its config hook.
    drawing_paper the same, twice, for grab and hand-pose plumbing it merely instances;
    `priming` is implemented in paper_draw_surface.gd and committed.

    That is this file's own recurring disease in a fifth costume — a fact about WHERE a
    line of code is written, presented as a verdict about the registry — and the costume
    it wears here is the worst of them, because a gate that cries wolf on vendored
    third-party plumbing teaches its reader to skip the one line that means the synth-rack
    fault came back.

    So the question is now the one the heading always claimed: is THIS AXIS implemented
    anywhere a fresh clone would get? Both historical catches survive unchanged — in each,
    the untracked file WAS the implementer and no tracked source declared the axis.

    FAIL CLOSED. Silence requires a positive: some tracked source that implements the axis.
    Failing to prove the untracked file implements it is not a reason to let it pass — the
    idiom inside a vendored or unstaged script may be one code_values has never seen.
    """
    import subprocess
    out = []
    for tok, (e, rf) in sorted(reg.items()):
        axes = (e.get("dna") or {}).get("axes") or {}
        if not axes:
            continue
        # EVERY script the scene runs, not just the primary one. A pass-through root that
        # never got staged strands the axis just as completely as an unstaged demo script.
        tracked_src: list[tuple[str, str]] = []
        untracked_src: list[tuple[str, str]] = []
        for gd, src in sources_for(e):
            if not src:
                continue
            rel = str(gd).replace("\\", "/")
            if "AdaResearch_46/" in rel:
                rel = rel.split("AdaResearch_46/", 1)[1]
            r = subprocess.run(["git", "ls-files", "--error-unmatch", rel],
                               capture_output=True, cwd=str(REPO))
            (tracked_src if r.returncode == 0 else untracked_src).append((rel, src))
        if not untracked_src:
            continue
        for axis in axes:
            # A tracked implementer makes the heading's claim false for this axis. Reuse
            # the same two signatures the value checks trust, so the gate cannot hold the
            # rest of the file to one standard and this paragraph to another.
            if any(has_export(src, axis) or code_values(src, axis)[0] is not None
                   for _rel, src in tracked_src):
                continue
            for rel, src in untracked_src:
                # check-ignore exits 0 on a NEGATED pattern too — `!*.gd` means the path is
                # explicitly NOT ignored. Reading only the exit code labelled a merely-unstaged
                # file "gitignored by .gitignore:304", which sends the reader to edit a
                # .gitignore that is already correct. Ask what the matching pattern says.
                ig = subprocess.run(["git", "check-ignore", "-v", rel],
                                    capture_output=True, text=True, cwd=str(REPO))
                why = ""
                if ig.returncode == 0 and ig.stdout.strip():
                    parts = ig.stdout.strip().split("\t")[0].split(":")
                    if len(parts) >= 3 and not parts[2].lstrip().startswith("!"):
                        why = "gitignored by " + ":".join(parts[0:2])
                out.append((tok, rel, why or "never staged", axis))
    return out


PROBE = REPO / "tools" / "_dna_gate_selftest_probe.gd"

PROBE_SRC = '''extends Node3D
# transient self-test probe for check_dna_declarations.py — safe to delete
@export var housing: String = "stand"

func _build() -> void:
\tmatch housing:
\t\t"stand":
\t\t\tpass
\t\t"wall":
\t\t\tpass
'''

PROBE_EXT = REPO / "tools" / "_dna_gate_selftest_probe_ext.gd"

# Untracked by construction, and it EXTENDS a tracked script — the shape that made the
# gate red on five sound declarations (force_cube -> pickable_prop -> gitignored XR-tools).
# One fixture serves both directions: `cube_size` is implemented by the tracked parent,
# `housing` only by this untracked child.
PROBE_EXT_SRC = '''extends "res://commons/grid/GridSystem.gd"
# transient self-test probe for check_dna_declarations.py — safe to delete
@export var housing: String = "stand"
'''


def selftest() -> int:
    """The negative control, made a fixture (2026-08-03, after 85d9f5cc4's manual one).

    The gate that asked git shipped with three bugs that reading did not catch and a
    hand-run fault-injection did. An instrument nobody has watched fail has not been
    tested — so this watches it fail, every time, without touching the user's index or
    the real registry: a throwaway probe script (untracked by construction) and
    synthetic registry entries exercise the real code paths, then the probe is removed.

    Controls (each asserts the gate's behaviour, not its implementation):
      A  clean declaration        -> every axis "ok"          (no false alarms)
      B  value the code lacks     -> MISMATCH                 (the science_screen disease)
      C  axis with no @export     -> NO_EXPORT                (the unreachable-knob class)
      D  untracked source file    -> untracked_sources flags  (the 85d9f5cc4 blind spot)
      E  tracked source file      -> untracked_sources silent (no false alarms from git)
      F  axis implemented by a TRACKED parent, untracked child in the same scene
                                  -> silent  (the five false alarms of 2026-08-07)
      G  same scene, axis implemented ONLY in the untracked child
                                  -> flags   (F must not have sanded the gate down)

    F and G share one fixture on purpose. They differ in nothing but WHICH AXIS is asked
    about, which is the whole content of the 08-07 change: the question is per axis, not
    per scene. If a future edit makes the gate answer per scene again, exactly one of
    this pair goes red whichever direction it drifts.
    """
    results: list[tuple[str, bool, str]] = []

    def control(name: str, ok: bool, detail: str) -> None:
        results.append((name, ok, detail))
        print(f"  {'PASS' if ok else 'FAIL'}  {name}: {detail}")

    print("self-test: injecting faults the gate must catch (and cleans it must not flag)")
    try:
        PROBE.write_text(PROBE_SRC, encoding="utf-8")
        probe_scene = "res://tools/_dna_gate_selftest_probe.gd"

        entry_clean = {"scene": probe_scene,
                       "dna": {"axes": {"housing": ["stand", "wall"]}}}
        rows = check_token("probe", entry_clean)
        control("A clean declaration passes", bool(rows) and all(r["status"] == "ok" for r in rows),
                f"statuses {[r['status'] for r in rows]}")

        entry_bad = {"scene": probe_scene,
                     "dna": {"axes": {"housing": ["stand", "niche"]}}}
        rows = check_token("probe", entry_bad)
        control("B undeclarable value -> MISMATCH",
                any(r["status"] == "MISMATCH" for r in rows),
                f"statuses {[r['status'] for r in rows]}")

        entry_noexp = {"scene": probe_scene,
                       "dna": {"axes": {"surface": ["flat", "curved"]}}}
        rows = check_token("probe", entry_noexp)
        control("C missing export -> NO_EXPORT",
                any(r["status"] == "NO_EXPORT" for r in rows),
                f"statuses {[r['status'] for r in rows]}")

        flagged = untracked_sources({"probe": (entry_clean, "selftest")})
        control("D untracked source is flagged", len(flagged) == 1,
                f"{len(flagged)} flagged (probe is untracked by construction)")

        tracked = {"scene": "res://commons/grid/GridSystem.gd",
                   "dna": {"axes": {"anything": ["a"]}}}
        flagged = untracked_sources({"tracked": (tracked, "selftest")})
        control("E tracked source is not flagged", len(flagged) == 0,
                f"{len(flagged)} flagged (GridSystem.gd is committed)")

        PROBE_EXT.write_text(PROBE_EXT_SRC, encoding="utf-8")
        ext_scene = "res://tools/_dna_gate_selftest_probe_ext.gd"

        entry_parent = {"scene": ext_scene,
                        "dna": {"axes": {"cube_size": ["1.0"]}}}
        flagged = untracked_sources({"probe_ext": (entry_parent, "selftest")})
        control("F axis implemented by tracked parent is not flagged", len(flagged) == 0,
                f"{len(flagged)} flagged (cube_size lives in the committed GridSystem.gd)")

        entry_child = {"scene": ext_scene,
                       "dna": {"axes": {"housing": ["stand", "wall"]}}}
        flagged = untracked_sources({"probe_ext": (entry_child, "selftest")})
        control("G axis implemented only in untracked child is flagged",
                len(flagged) == 1 and flagged[0][3] == "housing",
                f"{len(flagged)} flagged {[f[3] for f in flagged]} "
                f"(housing exists nowhere committed)")
    finally:
        for p in (PROBE, PROBE_EXT):
            if p.exists():
                p.unlink()

    ok = sum(1 for _, r, _ in results if r)
    print(f"self-test: {ok}/{len(results)} controls passed")
    return 0 if ok == len(results) else 1


def unreachable_roots(reg: dict) -> tuple:
    """Declared axes whose SCENE ROOT carries no script, split by how badly.

    THE CASE THIS GENERALISES. cctv.gd was 489 lines implementing `oversight`, its registry
    declaration derived cleanly and the gate passed it — and cctv.tscn referenced no script
    at all. Five frames came back identical to the byte. The declaration validated because
    source_for() falls back to swapping .tscn for .gd, so it read a file BY NAME that the
    scene never loads. Nothing in the value comparison can see that: the values are right,
    they are simply the values of code nobody runs.

    Asked of the whole corpus afterwards, the same shape appeared 16 more times. So:

      BROKEN — no script anywhere in the scene. The declaration describes code that is never
        loaded, and every variant of the axis necessarily renders the same picture.
        cube_scene (166 placements) and prism_block (78) were exactly this: both .gd files
        implement `grain` in full, ~20 references each, and neither scene loaded them.
        Attaching the script moved the axis from silently dead to 13.2% and 27.9%.

      CHILD-ONLY — a script exists, but on a CHILD rather than the root. The sweep still
        finds the property, because it searches the subtree breadth-first, so the axis
        measures fine on the bench and the gallery looks healthy. A MAP cannot reach it:
        GridInteractablesComponent stamps config metadata and calls apply_grid_config on the
        ROOT. The axis works everywhere except in the game, which is the only place it is
        for. Reported, not failed — some of these are legitimately composed scenes.

    Inherited scenes (`instance=ExtResource` on the root) are skipped: the base scene carries
    the script and the root correctly has none of its own.
    """
    broken, child_only = [], []
    for tok, (entry, _f) in sorted(reg.items()):
        axes = ((entry.get("dna") or {}).get("axes") or {})
        if not axes:
            continue
        sp = str(entry.get("scene", "") or "").replace("res://", "")
        if not sp.endswith(".tscn"):
            continue
        path = REPO / sp
        if not path.exists():
            continue
        try:
            raw = path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        nodes = raw.split("[node ")
        if len(nodes) < 2:
            continue
        root = nodes[1]
        if re.search(r"^script = ExtResource", root, re.M):
            continue
        if "instance=ExtResource" in root:
            continue
        n_scripts = len(re.findall(r'\[ext_resource type="Script"', raw))
        (broken if n_scripts == 0 else child_only).append((tok, sp, ",".join(axes)))
    return broken, child_only


def main() -> int:
    only = ""
    quiet = False
    for a in sys.argv[1:]:
        if a.startswith("--token="):
            only = a.split("=", 1)[1]
        elif a == "--quiet":
            quiet = True
        elif a in ("--self-test", "--selftest"):
            return selftest()

    reg = registry()

    # Asked BEFORE the value checks, because a declaration whose code is not in the
    # repository is broken in a way no value comparison can see.
    untracked = untracked_sources(reg)
    # A declaration can be perfectly correct about values and still describe code the scene
    # never loads. See unreachable_roots.
    dead_roots, child_roots = unreachable_roots(reg)
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

    orphans, note_only = undeclared_promotions(reg)
    if orphans:
        print(f"\n{len(orphans)} promoted in code, undeclared in the registry "
              f"[the axes exist but the sweep can never reach them]:")
        for tok, axes in orphans:
            print(f"  {tok}: {axes}")
    if note_only:
        print(f"\n{len(note_only)} promotion NOTE with no axis in the file "
              f"[the write-up landed, the export did not — do NOT declare these, "
              f"implement or retract the note]:")
        for tok in note_only:
            print(f"  {tok}")

    if untracked:
        print(f"\n{len(untracked)} DECLARED AXIS whose implementing script is NOT IN THE "
              f"REPOSITORY [a fresh clone gets the declaration with no dispatch behind it]:")
        for tok, rel, why, axis in untracked:
            print(f"  {tok:28s} .{axis:<16s} {rel}  ({why})")

    if dead_roots:
        print(f"\n{len(dead_roots)} DECLARED AXIS whose SCENE LOADS NO SCRIPT AT ALL "
              f"[the values are right; nothing runs them, so every variant is one picture]:")
        for tok, scene, axes in dead_roots:
            print(f"  {tok:28s} .{axes:<20s} {scene}")
    if child_roots:
        print(f"\n{len(child_roots)} declared axis whose script is on a CHILD, not the scene "
              f"root [the sweep reaches it breadth-first; a map token cannot, because "
              f"apply_grid_config is called on the ROOT]:")
        for tok, scene, axes in child_roots:
            print(f"  {tok:28s} .{axes:<20s} {scene}")

    return len({r["token"] for r in bad}) + len(untracked) + len(dead_roots)


if __name__ == "__main__":
    raise SystemExit(main())
