#!/usr/bin/env python3
"""build_manuscript.py — merge the frame + the tutorial chapters into ONE book.

The synthesis layer: /book is the encyclopedia (every path), /tutorial is THE
path (8 pages per spine sequence, authored overlays), brain-vault holds the
six-part narrative arc. This tool merges them:

  doc/manuscript_frame.json          the arc — parts, epigraphs, front matter
  ada_encyclopedia/public/tutorial/  the chapters — skeleton + authored prose

into a single linear manuscript:

  ada_encyclopedia/public/manuscript.md    the book, one markdown file
  ada_encyclopedia/public/manuscript.json  structure (parts -> chapters), small

manuscript.json stays prose-free (like book.json) so it never goes stale; the
.md is the export — feed it to a reader page, pandoc, or auto-indesign.

Usage:
  python tools/build_manuscript.py            # build both outputs
  python tools/build_manuscript.py --stats    # coverage report only
"""
from __future__ import annotations

import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
FRAME = os.path.join(REPO, "doc", "manuscript_frame.json")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
OUT_MD = os.path.join(ENC, "public", "manuscript.md")
OUT_JSON = os.path.join(ENC, "public", "manuscript.json")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def demojibake(s):
    """Repair double-encoded UTF-8 (â€", Â², â€™ …) that leaks in from some
    sequence JSONs. Strings that are already clean pass through untouched;
    strings that mix mojibake with real non-cp1252 chars stay as they are."""
    if not isinstance(s, str) or not any(m in s for m in ("â€", "Â", "Ã")):
        return s
    try:
        return s.encode("cp1252").decode("utf-8")
    except Exception:
        return s


def clean(node):
    if isinstance(node, str):
        return demojibake(node)
    if isinstance(node, list):
        return [clean(x) for x in node]
    if isinstance(node, dict):
        return {k: clean(v) for k, v in node.items()}
    return node


# --- The Principal (R-029) — the em-square doctrine, woven per chapter -------
# Each chapter names its hero as its principal and how the em-square seats it.
# Seating is resolved from the same declarations the map builders use, so book
# and game stay in agreement: principals → per-artifact overrides → kin family
# membership → the measured bed every unhoused thing falls to.
PRINCIPALS = load_json(os.path.join(REPO, "commons", "data", "principal_artifacts.json")) or {}
_SIZES_RAW = load_json(os.path.join(REPO, "commons", "data", "artifact_sizes.json")) or {}
SIZES = _SIZES_RAW.get("sizes", _SIZES_RAW)


def seat_from_size(hero: str) -> str | None:
    """Derive seating from the measured base — the map builder's own --advise rule
    (Palle's rule 2: base ≥ 6 m is the environment, housing would kill it). Used
    only for heroes no principal/override/kin declares. None if unmeasured."""
    s = SIZES.get(hero) if isinstance(SIZES, dict) else None
    if not isinstance(s, dict) or s.get("base_m") is None:
        return None
    base = float(s["base_m"])
    n = hero.lower()
    if base >= 6.0:
        return "field"
    if any(k in n for k in ("_plate", "_screen", "_board", "_panel")):
        return "frame"
    if base == 0.0:  # live / no static mesh — an act, not an object; brings its own ground
        return "self"
    if any(k in n for k in ("workbench", "_bench", "_machine", "kiosk", "console", "editor")):
        return "self"
    if base >= 2.5:
        return "self"
    if base >= 1.0:
        return "cube"
    return "plinth"

SEAT_GLOSS = {
    "self": "brings its own base — no plinth, no bed",
    "cube": "the one-metre sim-cell made visible — the grid's unit turned into housing",
    "frame": "flat work, framed and wall- or hover-mounted",
    "plinth": "small, raised to the eye on a dark column",
    "podium": "a broad platform — elevation, not housing",
    "pedestal": "a broad platform — elevation, not housing",
    "field": "the artifact IS the environment — to house it would kill it",
    "table_display_1m": "a table display for flat, vertical work",
    "table_display_2m": "a wide table display for flat, vertical work",
    "bed": "the grid's default floor, where a thing rests until it is measured or declared",
}


def resolve_seating(hero: str) -> str:
    """How the em-square seats this artifact: the wrapper family, resolved from
    the declarations. Falls back to 'bed' — the size-guessed floor."""
    if not hero:
        return "bed"
    pr = PRINCIPALS.get("principals", {})
    if hero in pr and isinstance(pr[hero], dict):
        fam = pr[hero].get("wrap_family") or pr[hero].get("integration") or "bed"
        return "bed" if fam == "wrap" else fam
    ov = PRINCIPALS.get("artifact_overrides", {})
    if isinstance(ov.get(hero), str):
        return ov[hero]
    for fv in PRINCIPALS.get("kin", {}).values():
        if isinstance(fv, dict) and isinstance(fv.get("members"), list) and hero in fv["members"]:
            return fv.get("wrap_family") or fv.get("integration") or fv.get("wrap") or "self"
    return seat_from_size(hero) or "bed"


def render_interlude(il: dict, lines: list) -> None:
    """An interlude between parts — a reflection that is not a sequence chapter."""
    lines += [f"# Interlude: {il['title']}", ""]
    if il.get("epigraph"):
        lines += [f"*{il['epigraph']}*", ""]
    if il.get("body"):
        lines += [il["body"], ""]


def render_principal(t: dict, hero: str, essence: str, lines: list, stats: dict) -> None:
    """The Principal beat: the chapter's hero read through the em-square. Authored
    prose in the overlay's `principal` field wins; else a computed sentence."""
    authored = t.get("principal")
    seat = resolve_seating(hero)
    prose = ""
    if isinstance(authored, str):
        prose = authored.strip()
    elif isinstance(authored, dict) and authored.get("prose"):
        prose = str(authored["prose"]).strip()
    if not prose and not hero:
        return
    lines += ["### The Principal", ""]
    if prose:
        lines += [prose, ""]
    else:
        nm = hero.replace("_", " ")
        seatword = seat if seat != "bed" else "the measured bed"
        ess = f" — *{essence}* —" if essence else " —"
        lines.append(
            f"This chapter's principal is **{nm}**{ess} one canonical scene, inherited by every "
            f"instance; the type is the spatial truth. It seats **{seatword}**: "
            f"{SEAT_GLOSS.get(seat, SEAT_GLOSS['bed'])}.")
        lines.append("")
    stats["principal"] = {"hero": hero, "seating": seat}


def art_prose(a: dict) -> str:
    """Authored prose wins; else essence + description as the fallback voice."""
    if a.get("prose"):
        return a["prose"]
    bits = []
    if a.get("essence"):
        bits.append(f"*{a['essence']}*")
    if a.get("description"):
        bits.append(a["description"])
    return "\n\n".join(bits)


def render_artifact(a: dict, lines: list, heading: str | None = None) -> None:
    title = heading or a.get("title") or a.get("name", "")
    lines.append(f"**{title}**")
    lines.append("")
    if a.get("image"):
        lines.append(f"![{title}]({a['image']})")
        lines.append("")
    prose = art_prose(a)
    if prose:
        lines.append(prose)
        lines.append("")
    if a.get("truth"):
        lines.append(f"> {a['truth']}")
        lines.append("")


# ── THE WALK PAGES READ THE ROOMS (2026-08-31) ─────────────────────────────
#
# Palle: "but how do I compile the cross references this into the final book?"
#
# They could not, and the reason was a seam nobody had crossed. This manuscript
# is built from ada_encyclopedia/public/tutorial/*.json — 25 chapters of 8 pages
# — while the rooms are written in commons/maps/<Map>/final.md, artifact-tagged,
# and the two had never met. 48 walk pages across the corpus, every one empty,
# and the walk is precisely where a room belongs.
#
# So a walk page now reads the halls of its own chapter and prints the ones that
# have been written. The artifact tag is what COMPILES: `<!-- @origin -->` in
# final.md becomes the work's name in the book, so a cross-reference made while
# writing survives into the printed page instead of being a comment nobody reads.
#
# It uses tools/final_tags.parse — the same grammar /compose writes and
# tools/final_tags.py --check gates across both implementations. A third parser
# for the same markers is how the marker would come to mean three things.
#
# WHAT IT DOES NOT DO: it does not invent. A chapter with no final.md anywhere
# prints the count of rooms still unwritten rather than an empty heading, because
# 48 silent pages already looked like a finished book once.

import sys as _sys
_sys.path.insert(0, os.path.join(REPO, "tools"))
try:
    from final_tags import parse as _parse_regions       # one grammar, not a copy
except Exception:                                        # the tool is not importable
    _parse_regions = None


def chapter_maps(seq):
    """The chapter's halls, in the order the museum walks them."""
    out = []
    try:
        with open(os.path.join(ENC, "public", "base_layer.json"), encoding="utf-8") as fh:
            bl = json.load(fh)
    except Exception:
        return out
    for c in bl.get("chapters", []):
        if str(c.get("chapter", "")) != str(seq):
            continue
        for h in c.get("halls", []):
            m = str(h.get("map", ""))
            if m and m not in out:
                out.append(m)
    return out


def work_names():
    """token -> display name, so a tag prints as a work rather than a slug."""
    names = {}
    reg = os.path.join(REPO, "commons", "artifacts", "registry")
    if not os.path.isdir(reg):
        return names
    for fn in sorted(os.listdir(reg)):
        if not fn.endswith(".json"):
            continue
        try:
            with open(os.path.join(reg, fn), encoding="utf-8") as fh:
                d = json.load(fh)
        except Exception:
            continue
        arts = d.get("artifacts", d) if isinstance(d, dict) else {}
        if isinstance(arts, dict):
            for k, v in arts.items():
                if isinstance(v, dict):
                    names[k] = str(v.get("name") or k)
    return names


# ── THE DEPENDENCY GRADIENT (2026-09-01) ───────────────────────────────────
#
# Palle asked for the room's assumptions on a board and in the book, with links.
# The first build did that literally: it measured every construct a room's code
# used and printed the lot as "Stands on: functions, .new(), add_child — not
# taught here." Accurate, and a DEPENDENCY WALL. Their ruling:
#
#     Explain a dependency when ignorance of it prevents the learner from
#     forming the intended mental model. Don't explain it merely because
#     it exists.
#
# Follow the other way and there is no bottom: before Vector3, floats; before
# floats, binary; before binary, electricity; and the learner has learned nothing
# about points. The opposite failure — "here is Vector3(1, 0.5, 0), don't worry
# about the rest" — leaves them in unexplained magic. So: a gradient, whose lower
# rungs SHOW NOTHING, and whose default is 'used', which is to say silence.
#
# What the book can do that the headset cannot is make the descent one click. So
# the room prints its subject, and every thing ruled 'glimpsed' prints its
# descent — the small optional inscription, not a lesson. The basement is listed
# once, at the back, so the museum is honest about having one.
#
# Source: commons/data/depth.json, derived by tools/depth.py from the AUTHORED
# commons/data/depth_rulings.json. Unruled rooms print nothing, and 243 of 244
# are unruled, which for most of them is the right answer rather than a backlog.

def depth_doc():
    try:
        with open(os.path.join(REPO, "commons", "data", "depth.json"),
                  encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return {}


def _linked(t):
    """A thing's name, linked if it has somewhere honest to point."""
    nm = str(t.get("thing", ""))
    url = t.get("link")
    return f"[{nm}]({url})" if url else nm


def render_room_depth(map_name, doc, lines):
    """What this room makes you able to do — and the stairs, for those who want.

    Empty prints NOTHING. A room nobody has ruled says nothing, and that silence
    is the ruling."""
    room = (doc.get("rooms") or {}).get(map_name) or {}
    says = room.get("says") or []
    if not says:
        return
    subject = [t for t in says if t.get("status") == "understood"]
    named = [t for t in says if t.get("status") == "named"]
    glimpsed = [t for t in says if t.get("status") == "glimpsed"]

    if subject:
        lines.append("> **Here you can:**")
        for t in subject:
            lines.append(f"> - {_linked(t)} — {t['say']}" if t.get("say")
                         else f"> - {_linked(t)}")
        lines.append("")
    if named:
        # Named, not taught. One line, no theory.
        lines.append("> **Also in the room:** " + ", ".join(
            f"{_linked(t)} ({t['say']})" if t.get("say") else _linked(t)
            for t in named))
        lines.append("")
    for t in glimpsed:
        # The plaque, then the descent the reader may decline. In the book the
        # decline is free, which is the one thing print does better than VR.
        lines.append(f"> {t.get('say', '')}")
        lines.append(f"> <small>{_linked(t)} — {t.get('descend', '')}</small>"
                     if t.get("descend") else f"> <small>{_linked(t)}</small>")
        lines.append("")


def render_thrownness(lines):
    """Said once, at the front. Not a syllabus — a place to stand."""
    doc = depth_doc()
    th = doc.get("_thrownness")
    if not th:
        return
    lines.append("### You arrive late")
    lines.append("")
    lines.append(th)
    lines.append("")
    ladder = doc.get("ladder") or []
    if ladder:
        lines.append("So a thing in this book is not either taught or hidden. It has "
                     "a rung, and the lower rungs are silent on purpose:")
        lines.append("")
        for rung in ladder:
            lines.append(f"- **{rung['status']}** — {rung['gloss']}")
        lines.append("")
    if doc.get("_rule"):
        lines.append(f"> {doc['_rule']}")
        lines.append("")


def render_basement(lines):
    """Everything the museum runs on and never puts on the path.

    Printed once, at the back, and never on a wall. The building is allowed a
    basement the visitor never visits; saying so is what keeps it navigable
    rather than magic."""
    doc = depth_doc()
    seen, rows = set(), []
    for mp, room in (doc.get("rooms") or {}).items():
        for t in room.get("basement") or []:
            k = str(t.get("thing", ""))
            if k and k not in seen:
                seen.add(k)
                rows.append((k, t.get("note", "")))
    if not rows:
        return
    lines.append("## The basement")
    lines.append("")
    lines.append("Everything below is why the rest of this is possible. None of it is "
                 "on the path, and nothing in the museum will ask you for it. It is "
                 "written down so that the building is known to have a basement — a "
                 "museum with one it never mentions is a museum of magic.")
    lines.append("")
    for name, note in rows:
        lines.append(f"- **{name}** — {note}" if note else f"- **{name}**")
    lines.append("")



def render_walk_prose(seq, lines):
    """Print every written room of this chapter. Returns (written, silent)."""
    maps = chapter_maps(seq)
    if not maps or _parse_regions is None:
        return 0, len(maps)
    names = work_names()
    _doc = depth_doc()
    _rul = red_thread_rulings()
    written = 0
    for m in maps:
        f = os.path.join(REPO, "commons", "maps", m, "final.md")
        raw = ""
        if os.path.exists(f):
            try:
                with open(f, encoding="utf-8") as fh:
                    raw = fh.read()
            except Exception:
                raw = ""

        # A ROOM CAN BE RULED WITHOUT BEING WRITTEN, and this used to drop it.
        #
        # Found by running the whole process on Point_Lines as a stranger would:
        # propose, author the ruling, apply, place the sign. The sign built, the
        # museum plan carried it — and the book showed nothing at all, because
        # this loop `continue`d on a missing final.md. The gate was about PROSE
        # and the thing being gated was DEPTH, which are not the same thing and
        # do not arrive together: 243 rooms have no ruling, and most rooms have
        # no final.md, and the two sets barely overlap.
        #
        # So a ruled room now prints its gradient whether or not anyone has
        # written it up. What it does not do is pretend: it says the prose is
        # missing, because a heading with only a depth block under it would
        # otherwise read as a finished room that had nothing to say.
        has_prose = raw.strip() != ""
        has_depth = bool(((_doc.get("rooms") or {}).get(m) or {}).get("says"))
        has_ruling = m in _rul
        if not has_prose and not has_depth and not has_ruling:
            continue
        if has_prose:
            written += 1
        lines.append(f"#### {m.replace('_', ' ')}")
        lines.append("")
        render_room_depth(m, _doc, lines)
        if not has_prose:
            # Say it plainly. A heading carrying only a depth block, with no
            # admission, reads as a room that was written and had nothing to say.
            lines.append("*This room has been ruled but not yet written.*")
            lines.append("")
            if has_ruling:
                r = _rul[m]
                lines.append("*Ruled " + str(r.get("date", "")) + ": " + str(r.get("argument", "")) + "*")
                lines.append("")
        for block in _parse_regions(raw):
            tok = str(block.get("token") or "")
            body = str(block.get("text") or "").strip()
            if tok:
                # THE CROSS-REFERENCE, COMPILED: the tag becomes the work
                lines.append(f"**{names.get(tok, tok)}** — `{tok}`")
                lines.append("")
            if body:
                lines.append(body)
                lines.append("")
        render_field_notes(m, lines)
    return written, len(maps) - written


def red_thread_rulings():
    """Palle's one-line rulings on a room's argument, from
    commons/data/red_thread_rulings.json -> {map: {argument, date}}. A room with
    a ruling prints in the book even before it is written, like a depth ruling."""
    p = os.path.join(REPO, "commons", "data", "red_thread_rulings.json")
    try:
        with open(p, encoding="utf-8") as fh:
            return json.load(fh).get("rooms", {}) or {}
    except Exception:
        return {}


def render_field_notes(map_name, lines):
    """The room's field notes, as the book's footnotes.

    Palle, 2026-09-02: "field notes can be footnotes in the book." Each `##`
    section of commons/maps/<Map>/field_notes.md becomes one GFM footnote: a
    marker line under the room lists the note titles with their references, and
    the definitions follow (remark-gfm collects them at the end of the document,
    the way a book keeps its notes). The H1 and the convention blockquote are
    dropped; they are for the file, not the reader. Returns the note count.
    """
    f = os.path.join(REPO, "commons", "maps", map_name, "field_notes.md")
    if not os.path.exists(f):
        return 0
    try:
        with open(f, encoding="utf-8") as fh:
            raw = fh.read().replace(chr(13), "")
    except Exception:
        return 0
    NL = chr(10)
    kept = []
    for ln in raw.split(NL):
        if ln.startswith("# ") or ln.startswith("> ") or ln.strip() == ">":
            continue
        kept.append(ln)
    text = NL.join(kept).strip()
    notes = []
    for part in re.split(r"(?m)^## +", text):
        part = part.strip()
        if not part:
            continue
        head, _, rest = part.partition(NL)
        notes.append((head.strip(), rest.strip()))
    if not notes:
        return 0
    slug = re.sub(r"[^a-z0-9]+", "-", map_name.lower()).strip("-")
    refs, defs = [], []
    for i, (head, rest) in enumerate(notes, 1):
        fid = slug + "-" + str(i)
        refs.append(head + "[^" + fid + "]")
        block = ["[^" + fid + "]: **" + head + ".**"]
        for ln in rest.split(NL):
            block.append(("    " + ln) if ln.strip() else "")
        defs.append(NL.join(block))
    lines.append("*Field notes: " + " · ".join(refs) + "*")
    lines.append("")
    for d in defs:
        lines.append(d)
        lines.append("")
    return len(notes)


def render_chapter(t: dict, number: int, lines: list) -> dict:
    """Render one tutorial (8 pages) as a chapter; return its TOC entry."""
    name = t.get("name") or t["seq"]
    lines.append(f"## Chapter {number}: {name}")
    lines.append("")
    stats = {"seq": t["seq"], "name": name, "number": number,
             "authored": bool(t.get("authored")), "truth": t.get("truth", "")}
    # The Principal beat (R-029): hero token from the question page's capture path
    # (the reliable lookup token; hero_name is humanized), essence from the primitive.
    hero = ""
    hero_essence = ""
    for _p in t.get("pages", []):
        if _p.get("kind") == "question" and not hero:
            m = re.search(r"/captures/([^/]+)/", _p.get("hero") or "")
            hero = (m.group(1) if m else "") or _p.get("hero_name") or ""
        if _p.get("kind") == "primitive" and isinstance(_p.get("artifact"), dict):
            if not hero_essence:
                hero_essence = _p["artifact"].get("essence", "") or ""
            if not hero:
                hero = _p["artifact"].get("name", "") or ""
    walk_count = 0
    for p in t.get("pages", []):
        kind = p["kind"]
        if kind == "question":
            if p.get("truth"):
                lines.append(f"> **{p['truth']}**")
                lines.append("")
            if p.get("formula"):
                lines.append(f"`{p['formula']}`")
                lines.append("")
            if p.get("text"):
                lines.append(p["text"])
                lines.append("")
            render_principal(t, hero, hero_essence, lines, stats)
        elif kind == "primitive":
            lines.append("### The Primitive")
            lines.append("")
            if p.get("lead"):
                lines.append(f"*{p['lead']}*")
                lines.append("")
            if isinstance(p.get("artifact"), dict):
                render_artifact(p["artifact"], lines)
        elif kind == "walk":
            walk_count += 1
            lines.append(f"### {p.get('title') or 'The Walk'}")
            lines.append("")
            if p.get("lead"):
                lines.append(f"*{p['lead']}*")
                lines.append("")
            # the rooms themselves, once per chapter — on the FIRST walk page, so
            # a chapter with two of them does not print its halls twice
            if walk_count == 1:
                wrote, silent = render_walk_prose(t["seq"], lines)
                stats["rooms_written"] = wrote
                stats["rooms_silent"] = silent
                if wrote == 0 and silent:
                    lines.append(f"*{silent} room(s) in this chapter; none written yet.*")
                    lines.append("")
                elif silent:
                    lines.append(f"*{silent} further room(s) in this chapter, not yet written.*")
                    lines.append("")
            for a in p.get("artifacts") or []:
                render_artifact(a, lines)
        elif kind == "turn":
            lines.append("### The Turn — parameters")
            lines.append("")
            if p.get("text"):
                lines.append(p["text"])
                lines.append("")
            knobs = [k.get("title") or k.get("name", "") for k in p.get("knobs") or []]
            if knobs:
                lines.append("Open in the dressing-room viewer: " + ", ".join(knobs) + ".")
                lines.append("")
        elif kind == "critical":
            lines.append("### The Critical Reading")
            lines.append("")
            if p.get("lead"):
                lines.append(f"*{p['lead']}*")
                lines.append("")
            if p.get("qfep_term"):
                lines.append(f"QFEP term: **{p['qfep_term']}**")
                lines.append("")
            if p.get("qfep_connection"):
                lines.append(p["qfep_connection"])
                lines.append("")
            claims = p.get("claims") or []
            if claims:
                lines.append("The artifacts' own claims:")
                lines.append("")
                for c in claims:
                    nm = c.get("name", "").replace("_", " ")
                    lines.append(f"> {c.get('truth', '')} — *{nm}*")
                    lines.append("")
        elif kind == "world":
            lines.append("### In the World")
            lines.append("")
            if p.get("lead"):
                lines.append(f"*{p['lead']}*")
                lines.append("")
            maps = p.get("maps") or []
            if maps:
                lines.append("| Room | Grid | Artifacts | Footprint |")
                lines.append("|------|------|-----------|-----------|")
                for m in maps:
                    lines.append(f"| {m.get('name', '')} | {m.get('cols', '?')}×{m.get('rows', '?')} "
                                 f"| {m.get('artifacts', 0)} | {m.get('footprint', '')} m |")
                lines.append("")
            objs = p.get("objectives") or []
            if objs:
                lines.append("What this chapter teaches, walked rather than read:")
                lines.append("")
                for o in objs:
                    lines.append(f"- {o}")
                lines.append("")
            # Fold 5 — the machine's ride, the second machine register.
            ride = p.get("ride")
            if isinstance(ride, dict) and ride.get("lines"):
                lines.append(f"The machine walked {ride.get('map', 'the room')} "
                             "and filed this ride log:")
                lines.append("")
                for ln in ride["lines"]:
                    lines.append(f"> {ln}")
                    lines.append("")
        elif kind == "seed":
            lines.append("### The Seed")
            lines.append("")
            if p.get("truth"):
                lines.append(f"> **{p['truth']}**")
                lines.append("")
            exs = p.get("exercises") or []
            if exs:
                lines.append("Exercises:")
                lines.append("")
                for i, e in enumerate(exs, 1):
                    lines.append(f"{i}. {e}")
                lines.append("")
            if p.get("coda"):
                lines.append(p["coda"])
                lines.append("")
            if p.get("next"):
                lines.append(f"*Next: {p['next']}*")
                lines.append("")
    # Declared blanks (R-008) — the excavation's open slots, in print.
    blanks = t.get("blanks") if isinstance(t.get("blanks"), list) else []
    if blanks:
        lines.append("### The Blanks — declared open")
        lines.append("")
        for b in blanks:
            lines.append(f"- ◇ {b.get('note', '')}")
        lines.append("")
    # The ledger — the second voice, closing the chapter. Two registers:
    # authored motif entries (human, uneven, deliberate) and one computed
    # field note (the machine reporting its own edge decision).
    motifs = t.get("motifs") if isinstance(t.get("motifs"), dict) else {}
    dig = t.get("dig") if isinstance(t.get("dig"), dict) else {}
    if motifs or dig.get("pearls"):
        lines.append("### The Ledger")
        lines.append("")
        for k, v in motifs.items():
            lines.append(f"- **{k}** — {v}")
        if dig.get("pearls"):
            total, walked = dig["pearls"], dig.get("walked", 0)
            left = total - walked
            note = (f"{walked} of {total} artifacts excavated; {left} remain at depth."
                    if left > 0 else
                    f"{walked} of {total} artifacts excavated; this stratum is fully exposed.")
            if dig.get("curated"):
                note += " The cut was made by hand."
            lines.append(f"- **the dig** — {note}")
        lines.append("")
        stats["motifs"] = list(motifs.keys())
    return stats


def main() -> int:
    frame = load_json(FRAME)
    if not frame:
        print(f"!! no frame: {FRAME}")
        return 1

    chapters: dict[str, dict] = {}
    for part in frame["parts"]:
        for seq in part["sequences"]:
            t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json"))
            if t:
                chapters[seq] = clean(t)

    total = sum(len(p["sequences"]) for p in frame["parts"])
    authored = [s for s, t in chapters.items() if t.get("authored")]
    missing = [s for p in frame["parts"] for s in p["sequences"] if s not in chapters]
    print(f"chapters: {len(chapters)}/{total} built, {len(authored)} authored "
          f"({', '.join(authored) or 'none'})")
    if missing:
        print(f"missing tutorials (skipped in body, flagged in TOC): {', '.join(missing)}")
    if "--stats" in sys.argv[1:]:
        return 0

    lines: list = []
    toc_entries: list = []
    # Front matter.
    lines += [f"# {frame['title']}", "", f"*{frame['subtitle']}*", ""]
    if frame.get("formula"):
        lines += [f"> **{frame['formula']}**", ""]
    if frame.get("intro"):
        lines += [frame["intro"], ""]

    # The ledger, declared: the book's undertow, five threads under the pedagogy.
    if frame.get("motifs"):
        lines += ["## The Ledger", ""]
        if frame.get("motifs_intro"):
            lines += [f"*{frame['motifs_intro']}*", ""]
        for m in frame["motifs"]:
            lines.append(f"- **{m['name']}** — {m['statement']}")
        lines.append("")

    # The dig, declared: the book as excavation report, not survey.
    if frame.get("excavation_note"):
        lines += ["## The Dig", "", frame["excavation_note"], ""]

    # The lineage: Ada and its ancestors (Learning Processing, Nature of Code,
    # and the critical strand). Read from doc/book/LINEAGE.md if present.
    lineage_path = os.path.join(REPO, "doc", "book", "LINEAGE.md")
    if os.path.exists(lineage_path):
        body = open(lineage_path, encoding="utf-8").read()
        # drop the H1 and the front-matter parenthetical; keep from the first paragraph
        body = re.sub(r"^#\s*Ada and its ancestors\s*\n+(\*\(.*?\)\*\s*\n+)?", "", body, flags=re.S)
        lines += ["## Ada and its ancestors", "", body.strip(), ""]

    # The reader meets the condition before the chapters — the only place it can
    # do any work. Not a list of prerequisites: a place to stand inside a system
    # that is already running.
    render_thrownness(lines)

    # Table of contents.
    lines += ["## Contents", ""]
    num = 0
    for part in frame["parts"]:
        lines.append(f"**Part: {part['title']}**")
        lines.append("")
        for seq in part["sequences"]:
            num += 1
            t = chapters.get(seq)
            if t:
                nm = t.get("name") or seq
                tr = f" — *{t['truth']}*" if t.get("truth") else ""
                mark = "" if t.get("authored") else " †"
                lines.append(f"{num}. {nm}{tr}{mark}")
            else:
                lines.append(f"{num}. {seq} *(not yet built)*")
        for il in frame.get("interludes", []):
            if il.get("after") == part["title"]:
                lines.append(f"— *Interlude: {il['title']}*")
        lines.append("")
    lines += ["*† skeleton chapter — assembled from truth sources, awaiting its writing pass.*", ""]

    # Body: parts and chapters.
    num = 0
    for part in frame["parts"]:
        lines += [f"# Part: {part['title']}", ""]
        if part.get("epigraph"):
            lines += [f"*{part['epigraph']}*", ""]
        part_toc = {"title": part["title"], "chapters": []}
        for seq in part["sequences"]:
            num += 1
            t = chapters.get(seq)
            if not t:
                continue
            part_toc["chapters"].append(render_chapter(t, num, lines))
        # Interludes declared after this part (R-029): the em-square, and future kin.
        for il in frame.get("interludes", []):
            if il.get("after") == part["title"]:
                render_interlude(il, lines)
                part_toc["chapters"].append({"interlude": il["title"]})
        toc_entries.append(part_toc)

    # The basement, at the back: what the museum runs on and never puts on the
    # path. A building is allowed one; a building that never mentions it is a
    # building of magic.
    render_basement(lines)

    md = "\n".join(lines)
    with open(OUT_MD, "w", encoding="utf-8") as f:
        f.write(md)
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump({"title": frame["title"], "subtitle": frame["subtitle"],
                   "formula": frame.get("formula", ""), "parts": toc_entries},
                  f, indent=1)
    print(f"manuscript: {len(md)} chars, {num} chapter slots -> {OUT_MD}")
    print(f"structure  -> {OUT_JSON}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
