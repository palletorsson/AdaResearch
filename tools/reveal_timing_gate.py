#!/usr/bin/env python3
"""REVEAL TIMING — does the apparatus state the discovery before the visitor can make it?

    python tools/reveal_timing_gate.py state --map CA_SoftRules
    python tools/reveal_timing_gate.py ask --map CA_SoftRules            # dry run without a key
    python tools/reveal_timing_gate.py validate --labels doc/reports/reveal_timing/labels.json

THE FINDING THIS MEASURES (2026-09-18 review batch). Across all 24 sequences the
reviewers kept catching the same fault: the chapter asks the visitor to predict,
act and compare, and the apparatus prints the conclusion first. NEXT before the
prediction. "Sierpinski" before the resemblance is tested. FLY INTO THE THIRD INDEX
at the door of the array. "exactly 17 wallpaper groups fall out" on the cage the
chapter then has to walk back. The reviewers found these by reading; there are 196
halls and nobody is going to read them all that closely.

WHAT THIS IS. A gate, not a verdict. It assembles what a visitor can read at each
station (the artifact's own label strings, the caption cells beside it) and what
the chapter wanted them to find (the final.md region tagged for that artifact), and
asks TypeSafe's System One model two narrow questions per station: does this text
state the conclusion, and when does the room first say it. The answers are leads at
exactly the standing of the reviews themselves — `doc/book/review-feedback/README.md`:
editorial evidence, not verification, and no change is authorised by one.

WHY IT IS VALIDATED FIRST. The reviewers labelled a few dozen of these by hand, for
and against. `validate` runs the gate over those halls only and reports where it
agrees. A gate that cannot reproduce the known cases has no business reading the
other 196.

THE VISIBILITY HEURISTIC IS THE WEAK PART, and it is deliberate that the model is
told so. A string literal in a .gd file is text the artifact CAN show; nothing here
proves it is on the plate when the visitor walks in. The enclosing function name
travels with every string (`_build_plate` reads very differently from
`_on_step_pressed`), and the `when_stated` question exists to let that judgement be
made explicitly rather than assumed.

No key needed to build state or payloads; set TYPESAFE_API_KEY to ask.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons" / "maps"
REGISTRY = ROOT / "commons" / "artifacts" / "registry"
OUT_DIR = ROOT / "doc" / "reports" / "reveal_timing"
API_URL = "https://api.typesafe.ai/v1/systemone"
MODEL = "jev-latest"

# A string is candidate visitor-facing text only when the line PUTS it somewhere a
# visitor reads. The loose version of this rule (any line mentioning "text") returned
# node names, export enum values and scene paths — "opening", "Display Settings",
# "ParallelLogicDisplay" — which would have been sent to the model as things people read.
SHOWS_TEXT = re.compile(
    # the suffix form matters as much as the word: `instruction_title = "REACH AN
    # ADDRESS"` is the sign on an enclosure, and `\btitle` does not match it
    r'(?i)([A-Za-z0-9_]*\.?text\s*=|"text"\s*:|[A-Za-z0-9_]*title\s*=|"label"\s*:|[A-Za-z0-9_]*label\s*=\s*"'
    r"|set_text\s*\(|add_text\s*\(|append_text\s*\("
    # a call to any helper NAMED for showing text: _billboard_label(...), _plate(...),
    # make_sign(...). `\blabel\(` missed every one of these, because the underscore in
    # `_billboard_label` is a word character — three of the reviewers' loudest plates
    # ("MAX STRENGTH, MIN MATERIAL") were invisible to the first version for that reason.
    r"|[A-Za-z0-9_]*(label|plate|title|sign|caption|billboard|readout)\s*\()"
)
# A constant or variable NAMED for plate text, holding a dictionary or array of lines.
# chroma_stack keeps every plate sentence in `const PLATE_BODY := {...}`; no single line
# of it mentions text, a label or a plate.
TEXT_BLOCK = re.compile(r"(?i)^\s*(const|var)\s+[A-Za-z0-9_]*(plate|label|text|title|sign|caption|line|body|word)[A-Za-z0-9_]*\s*(:[^=]*)?=\s*[\[{]")
SKIP_LINE = re.compile(r"(?i)(\b(print|push_warning|push_error|printerr|printt|assert)\s*\(|get_node|find_child|has_node|add_to_group|\bconnect\s*\(|\.name\s*=|@export_enum)")
STRING = re.compile(r'"([^"\\]{2,200}(?:\\.[^"\\]*)*)"')
FUNC = re.compile(r"^\s*(?:static\s+)?func\s+([A-Za-z0-9_]+)")
TSCN_TEXT = re.compile(r'^text\s*=\s*"([^"]{2,200})"')
CODEY = re.compile(r"^(res://|user://|[a-z_]+/[a-z_/]+$|#?[0-9a-fA-F]{6}$|%[sdf]|[A-Za-z0-9_]+\.(gd|tscn|png)$)")


def _map_doc(hall: str) -> dict:
    path = MAPS / hall / "map_data.json"
    if not path.exists():
        sys.exit("no map: %s" % path)
    return json.loads(path.read_text(encoding="utf-8"))


def _layers(doc: dict) -> dict:
    return doc.get("layers", doc)


def _cells(rows: list) -> list[tuple[int, int, str]]:
    out = []
    for z, row in enumerate(rows or []):
        for x, cell in enumerate(row or []):
            s = str(cell).strip()
            if s:
                out.append((z, x, s))
    return out


def _registry() -> dict:
    """token -> registry entry, over every registry file."""
    reg: dict = {}
    for path in sorted(REGISTRY.glob("*.json")):
        try:
            doc = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = doc.get("artifacts", doc)
        if isinstance(arts, dict):
            for token, entry in arts.items():
                if isinstance(entry, dict):
                    reg.setdefault(token, entry)
    return reg


def _is_plumbing(s: str) -> bool:
    """Reject what survives the line filter but nobody reads.

    Ternary halves caught mid-expression ("if show_u else"), node names built with a
    format ("FieldTitle_%d"), and bare property words ("type"). Each of these reached
    the first payload as something a visitor supposedly reads.
    """
    low = s.lower()
    if low.startswith(("if ", "else", "and ", "or ")) or low.endswith((" if", " else")):
        return True
    if "%" in s and " " not in s:
        return True
    return " " not in s and len(s) < 6 and s.islower()


_STEM_INDEX: dict[str, list[Path]] = {}


def _by_stem(token: str) -> list[Path]:
    """Find a token's files when the registry does not know it.

    `chroma_stack` is placed 14 times in the first colour hall and is newer than the
    registry copy this tool reads, so a registry-only lookup returned NOTHING for that
    hall — no stations, no questions, and a reach check that called the reviewers'
    case blind. Anything placed on a floor can be read, registered or not.
    """
    if not _STEM_INDEX:
        for base in ("commons/artifacts", "commons/primitives", "commons/hazards", "commons/ui", "algorithms"):
            for path in (ROOT / base).rglob("*.gd"):
                _STEM_INDEX.setdefault(path.stem, []).append(path)
            for path in (ROOT / base).rglob("*.tscn"):
                _STEM_INDEX.setdefault(path.stem, []).append(path)
    return _STEM_INDEX.get(token, [])[:4]


def _sources_for(entry: dict, config: list[str]) -> list[Path]:
    """Every file that can put text in front of a visitor at this station.

    NOT just the scene's root script. `rd_artifact:0:0#study:exchange` places one
    artifact whose plates ("A / EXCHANGE ON") are built in a sibling file,
    exchange_study.gd, selected by the map token's own config. Reading only the root
    script found one string in the whole CA_SoftRules hall and missed the give-away
    the reviewers named. So: the scene, its script, and the .gd files beside them —
    with the ones a config value names sorted to the front.
    """
    scene = str(entry.get("scene") or "")
    if not scene.startswith("res://"):
        return []
    tscn = ROOT / scene[len("res://"):]
    out: list[Path] = []
    if tscn.exists():
        out.append(tscn)
        m = re.search(r'\[ext_resource type="Script"[^\]]*path="res://([^"]+)"', tscn.read_text(encoding="utf-8", errors="ignore"))
        if m and (ROOT / m.group(1)).exists():
            out.append(ROOT / m.group(1))
    folder = tscn.parent
    wanted = [str(v.split(":", 1)[1]).lower() for v in config if ":" in v]
    if folder.exists():
        siblings = sorted(folder.glob("*.gd"), key=lambda p: (not any(w and w in p.stem.lower() for w in wanted), p.name))
        out += [p for p in siblings if p not in out][:6]
    return out


def _readable_strings(paths: list[Path]) -> list[dict]:
    """Strings these files can put in front of a visitor, with where each is set.

    A heuristic, and the reason `when_stated` is asked rather than assumed: a string
    in a script is text the artifact CAN show; whether it is on the plate at arrival
    or behind a button is what the enclosing function name is carried for.
    """
    out, seen = [], set()
    for path in paths:
        func = "scene" if path.suffix == ".tscn" else ""
        depth = 0
        for line in path.read_text(encoding="utf-8", errors="ignore").split("\n"):
            if path.suffix == ".tscn":
                m = TSCN_TEXT.match(line.strip())
                lits = [m.group(1)] if m else []
            else:
                fm = FUNC.match(line)
                if fm:
                    func = fm.group(1)
                code = line.split("#", 1)[0]
                if depth == 0 and TEXT_BLOCK.match(code):
                    depth = 1
                    func = code.split()[1].split(":")[0].split("=")[0]
                if depth:
                    depth += code.count("{") + code.count("[") - code.count("}") - code.count("]")
                    depth = max(depth, 0) if (code.count("}") or code.count("]")) else depth
                    lits = STRING.findall(code)
                else:
                    lits = STRING.findall(code) if (SHOWS_TEXT.search(code) and not SKIP_LINE.search(code)) else []
            for lit in lits:
                s = lit.strip()
                if len(s) < 3 or CODEY.match(s) or s in seen or _is_plumbing(s):
                    continue
                seen.add(s)
                out.append({"text": s[:200], "set_in": func or "(top level)", "file": path.name})
    return out[:30]


def _caption(cell: str) -> str:
    """The text a 3t / sub utility cell shows. `3t:90:0#text:POINT_ONE` or `3t:the_grid`."""
    head, *rest = cell.split("#")
    parts = head.split(":")
    text = ""
    for part in rest:
        if part.startswith("text:"):
            text = part[len("text:"):]
    if not text and len(parts) > 1 and not parts[1].lstrip("-").isdigit():
        text = ":".join(parts[1:])
    return text.replace("_", " ").strip()


def _chapter_regions(hall: str) -> dict[str, str]:
    """final.md as {token: the prose written about that artifact}."""
    path = MAPS / hall / "final.md"
    if not path.exists():
        return {}
    sys.path.insert(0, str(ROOT / "tools"))
    import final_tags  # the one grammar, not a second implementation

    regions: dict[str, str] = {}
    for block in final_tags.parse(path.read_text(encoding="utf-8")):
        token = str(block.get("token") or "")
        if token:
            regions[token] = str(block.get("text") or "").strip()
    return regions


def build_state(hall: str) -> dict:
    doc = _map_doc(hall)
    layers = _layers(doc)
    reg = _registry()
    regions = _chapter_regions(hall)
    captions = [(z, x, _caption(c)) for z, x, c in _cells(layers.get("utilities")) if c.split(":")[0].split("#")[0] in ("3t", "sub")]
    spawn_z = min([z for z, _, c in _cells(layers.get("utilities")) if c.split(":")[0] == "s"] or [0])

    stations = []
    for z, x, cell in sorted(_cells(layers.get("interactables")), key=lambda c: (abs(c[0] - spawn_z), c[1])):
        token = cell.split(":")[0].split("#")[0]
        entry = reg.get(token, {})
        config = cell.split("#")[1:]
        paths = _sources_for(entry, config) if entry else []
        if not paths:
            paths = _by_stem(token)
        near = [t for cz, cx, t in captions if t and abs(cz - z) <= 2 and abs(cx - x) <= 3]
        cfg = [p for p in config if p.startswith("text:")]
        readable = _readable_strings(paths)
        # EVERY placed station is kept, including the ones with nothing readable found.
        # Dropping them hid the difference that matters when this is checked against the
        # reviewers: a station the extractor cannot read is a blind spot in this file,
        # and a station with genuinely no text is an answer ("not_stated").
        stations.append({
            "token": token,
            "cell": [x, z],
            "what_it_is": str(entry.get("description") or "")[:300],
            "configured_as": [c for c in config if not c.startswith("text:")],
            "readable_text": readable,
            "captions_beside_it": near + [c[len("text:"):].replace("_", " ") for c in cfg],
            "chapter_passage": regions.get(token, "")[:2400],
            "source": ", ".join(str(p.relative_to(ROOT)).replace("\\", "/") for p in paths[:3]),
            "no_text_found": not (readable or near or cfg),
        })

    return {
        "hall": hall,
        "hall_description": str(doc.get("map_info", {}).get("description") or "")[:400],
        "chapter_opening": (regions.get("", "") or "")[:800],
        # Every caption in the hall, not only the ones within reach of a station. The
        # reviewers' Russell and Edge Of Chaos cases are four-arm cross captions that
        # stand well away from any artifact; attached by proximity alone they vanished.
        "hall_captions": [{"text": t, "cell": [x, z]} for z, x, t in captions if t],
        "stations": stations,
    }


def build_questions(state: dict) -> dict:
    """Two narrow judgements per station, asked together over one shared state."""
    questions: dict = {}
    for i, st in enumerate(state["stations"]):
        if st.get("no_text_found"):
            continue                      # nothing to read: no judgement to buy
        token = st["token"]
        base = "stations[%d]" % i
        questions["states_%s_%d" % (token, i)] = {
            "type": "noul",
            "instructions": (
                "In the museum hall `hall`, the station `%s` is the artifact '%s'. "
                "`%s.readable_text` lists text this artifact can show and `%s.captions_beside_it` "
                "the signs standing beside it; `%s.chapter_passage` is what the written chapter "
                "asks a visitor to find out at this station. Does that readable text or caption "
                "already state the chapter's discovery outright — name the pattern, print the "
                "answer, or announce the conclusion — so a visitor could read it instead of "
                "finding it?" % (base, token, base, base, base)
            ),
            "criteria": {
                "true": "The text states the conclusion, names the pattern the chapter wants recognised, or shows the answer the chapter asks the visitor to predict or compare.",
                "false": "The text only invites, instructs, identifies the object, or reports a neutral quantity, leaving the chapter's discovery to be made by acting.",
            },
        }
        questions["when_%s_%d" % (token, i)] = {
            "type": "choice",
            "instructions": (
                "For that same station `%s`, when does the room first put that conclusion in front "
                "of the visitor? `set_in` on each readable string names the function that sets it: "
                "a builder or _ready puts text up on arrival, a button or input handler puts it up "
                "after the visitor acts." % base
            ),
            "criteria": {
                "on_arrival": "A sign, plate, title or startup readout carries it before the visitor does anything.",
                "after_action": "It appears only after a press, a grab, a step or some other action by the visitor.",
                "not_stated": "The conclusion is not stated by this apparatus at all.",
            },
        }
    return questions


def ask(state: dict, live: bool) -> dict:
    payload = {"state": state, "model": MODEL, "questions": build_questions(state)}
    if not payload["questions"]:
        return {"payload": payload, "answers": {}, "note": "no readable station in this hall"}
    if not live:
        return {"payload": payload, "answers": {}, "note": "dry run — TYPESAFE_API_KEY not set"}
    req = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": "Bearer %s" % os.environ["TYPESAFE_API_KEY"],
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        body = json.loads(resp.read().decode("utf-8"))
    return {"payload": payload, "answers": body.get("answers", {}), "usage": body.get("usage", {})}


def gate_hall(hall: str, live: bool, threshold: float) -> dict:
    state = build_state(hall)
    result = ask(state, live)
    rows = []
    for i, st in enumerate(state["stations"]):
        a = result["answers"].get("states_%s_%d" % (st["token"], i), {})
        w = result["answers"].get("when_%s_%d" % (st["token"], i), {})
        noul = a.get("noul")
        rows.append({
            "hall": hall,
            "token": st["token"],
            "cell": st["cell"],
            "states_conclusion": noul,
            "when": w.get("choice"),
            "when_confidence": w.get("confidence"),
            "verdict": None if noul is None else ("gives_away" if (noul >= threshold and w.get("choice") != "after_action") else "ok"),
            "source": st["source"],
        })
    return {"hall": hall, "stations": rows, "usage": result.get("usage", {}), "note": result.get("note", "")}


def cmd_state(args) -> int:
    state = build_state(args.map)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / ("state_%s.json" % args.map)
    path.write_text(json.dumps(state, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print("%s: %d station(s) with readable text -> %s" % (args.map, len(state["stations"]), path))
    for st in state["stations"]:
        first = (st["readable_text"][0]["text"] if st["readable_text"] else (st["captions_beside_it"] or [""])[0])
        print("   %-34s %-28s %s" % (st["token"], (first or "")[:26], "chapter passage" if st["chapter_passage"] else "(untagged)"))
    return 0


def cmd_ask(args) -> int:
    live = bool(os.environ.get("TYPESAFE_API_KEY")) and not args.dry_run
    out = gate_hall(args.map, live, args.threshold)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / ("gate_%s.json" % args.map)
    path.write_text(json.dumps(out, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    if not live:
        payload = OUT_DIR / ("payload_%s.json" % args.map)
        payload.write_text(json.dumps(ask(build_state(args.map), False)["payload"], indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        print("dry run: %d question(s) written to %s" % (len(build_questions(build_state(args.map))), payload))
        return 0
    for row in out["stations"]:
        print("  %-9s %-30s noul %.2f  %s" % (row["verdict"], row["token"], row["states_conclusion"] or 0.0, row["when"]))
    print("-> %s" % path)
    return 0


def cmd_reach(args) -> int:
    """Does the extractor even SEE what the reviewers read? No key needed.

    The model can only judge text this file found. Before spending a single request,
    check the labelled cases: is the station there, and is the give-away string among
    what a visitor is said to be able to read? A case that fails here is a fault in
    the extractor, and a gate tuned against it would be tuned against a blind spot.
    """
    labels = json.loads(Path(args.labels).read_text(encoding="utf-8"))
    # Only the give-aways are in-world text. A `well_timed` label usually quotes the
    # CHAPTER, which is prose on a page and was never going to be in an artifact's
    # strings; counting those as blind spots measures nothing.
    # A label whose evidence is final.md is a judgement about the CHAPTER's timing, not
    # about an apparatus. It has no in-world string to find, and counting it as a blind
    # spot in the extractor would be scoring this file for something it never reads.
    cases = [c for c in labels
             if (args.all or c.get("verdict") == "gives_away")
             and "final.md" not in str(c.get("code_site") or "").split("(")[0]]
    rows, tally = [], {"text found": 0, "text found in part": 0, "station has other text": 0,
                       "extractor read nothing here": 0, "station not on the floor": 0, "no map": 0}
    states: dict[str, dict] = {}
    for c in cases:
        hall, raw = c["hall"], str(c.get("token") or "")
        if not (MAPS / hall / "map_data.json").exists():
            rows.append([hall, raw[:28], "no map"])
            tally["no map"] += 1
            continue
        if hall not in states:
            states[hall] = build_state(hall)
        by_token = {s["token"]: s for s in states[hall]["stations"]}
        # the label's token field is written by a reader, so it may carry a whole cell
        # ("lambda_slider:0:0.5#locked:0.4 at (10,2)") or a description
        station = next((by_token[w] for w in re.findall(r"[A-Za-z0-9_]{3,}", raw) if w in by_token), None)
        needle = re.sub(r"\s+", " ", str(c.get("label_text") or "")).strip().lower()
        core = max(needle.replace("/", " ").split(), key=len, default="")
        hall_text = " | ".join([c["text"] for c in states[hall]["hall_captions"]]
                               + [r["text"] for s in states[hall]["stations"] for r in s["readable_text"]]).lower()
        if station is None:
            # the label may name a caption cell rather than an artifact; the hall still
            # carries the text, and the model is given the whole hall
            verdict = "found elsewhere in hall" if (needle and needle[:40] in hall_text) else "station not on the floor"
            rows.append([hall, raw[:28], verdict])
            tally[verdict] = tally.get(verdict, 0) + 1
            continue
        haystack = " | ".join([r["text"] for r in station["readable_text"]] + station["captions_beside_it"]).lower()
        if not haystack:
            verdict = "found elsewhere in hall" if (needle and needle[:40] in hall_text) else "extractor read nothing here"
        elif needle and needle[:40] in haystack:
            verdict = "text found"
        elif core and len(core) > 3 and core in haystack:
            verdict = "text found in part"
        else:
            verdict = "station has other text"
        rows.append([hall, station["token"], verdict])
        tally[verdict] += 1
    for r in rows:
        print("  %-26s %-30s %s" % tuple(r))
    print("\nreach over %d give-away case(s):" % len(cases))
    for k, v in tally.items():
        if v:
            print("   %-28s %d" % (k, v))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "reach.json").write_text(json.dumps({"tally": tally, "rows": rows}, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return 0


def cmd_validate(args) -> int:
    labels = json.loads(Path(args.labels).read_text(encoding="utf-8"))
    cases = [c for c in labels if c.get("verdict") in ("gives_away", "well_timed")]
    halls = sorted({c["hall"] for c in cases})
    live = bool(os.environ.get("TYPESAFE_API_KEY")) and not args.dry_run
    if not live:
        print("no TYPESAFE_API_KEY — nothing to compare. Set it and run again.")
    got: dict[tuple[str, str], dict] = {}
    for hall in halls:
        if not (MAPS / hall / "map_data.json").exists():
            print("  skip %s (no map on this branch)" % hall)
            continue
        out = gate_hall(hall, live, args.threshold)
        for row in out["stations"]:
            got[(hall, row["token"])] = row
    hit = miss = false_alarm = unseen = 0
    rows = []
    for c in cases:
        row = got.get((c["hall"], c["token"]))
        if row is None or row.get("states_conclusion") is None:
            unseen += 1
            rows.append([c["hall"], c["token"], c["verdict"], "not reached", ""])
            continue
        agree = (row["verdict"] == "gives_away") == (c["verdict"] == "gives_away")
        if agree and c["verdict"] == "gives_away":
            hit += 1
        elif c["verdict"] == "gives_away":
            miss += 1
        elif not agree:
            false_alarm += 1
        rows.append([c["hall"], c["token"], c["verdict"], row["verdict"], "%.2f" % (row["states_conclusion"] or 0)])
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    report = OUT_DIR / "validation.json"
    report.write_text(json.dumps({"threshold": args.threshold, "hit": hit, "miss": miss,
                                  "false_alarm": false_alarm, "not_reached": unseen, "rows": rows},
                                 indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    for r in rows:
        print("  %-26s %-28s labelled %-11s gate %-11s %s" % tuple(r))
    print("\nagreed on %d of %d labelled give-aways; %d missed, %d false alarms, %d stations never reached"
          % (hit, hit + miss, miss, false_alarm, unseen))
    print("-> %s" % report)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("state", help="assemble what a visitor can read in one hall")
    s.add_argument("--map", required=True)
    s.set_defaults(func=cmd_state)
    a = sub.add_parser("ask", help="ask the gate about one hall")
    a.add_argument("--map", required=True)
    a.add_argument("--threshold", type=float, default=0.6)
    a.add_argument("--dry-run", action="store_true")
    a.set_defaults(func=cmd_ask)
    r = sub.add_parser("reach", help="offline: can the extractor see what the reviewers read?")
    r.add_argument("--labels", default=str(OUT_DIR / "labels.json"))
    r.add_argument("--all", action="store_true", help="include well_timed labels too (their text is usually chapter prose)")
    r.set_defaults(func=cmd_reach)
    v = sub.add_parser("validate", help="run the gate over the hand-labelled cases and report agreement")
    v.add_argument("--labels", default=str(OUT_DIR / "labels.json"))
    v.add_argument("--threshold", type=float, default=0.6)
    v.add_argument("--dry-run", action="store_true")
    v.set_defaults(func=cmd_validate)
    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
