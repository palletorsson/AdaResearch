#!/usr/bin/env python3
"""eye_shot.py — one eye shot per map: ride it, read it, improve it, WRITE it.

Palle (2026-07-18): "take the maps and improve them as walkable etc — we have
a lot of rules and tools; it's about optimizing the space with one eye shot
and running qfep — heuristic understanding, digging into what works, in text,
in space. The other one: how does the writing hold up and get developed
meanwhile?"

One pass per map, four instruments, one field note:

  RIDE   tools/gaze_ride.py — the map as a gaze token-stream (THE EDGE law:
         language + observation do the whole work). Overlaps and tight gaps
         are the violations; the ride log is the experience in text.
  MOVE   tools/place.py --in-place --only-improve on a SIBLING
         (Trial_eye_<Map> — sibling-only saves, originals untouched).
  GATE   tools/map_pathfinder.py — nothing ships unwalkable.
  VOICE  tools/qfep_signal.py index — which cast members carry @identity
         theory-claims (the map's voices) and which are mute.

The WRITING develops meanwhile: every shot writes a field note to
doc/book/eye_shots/<Map>.md — the ride quoted, the voices named, the change
recorded, the standing declared. Field notes are dig-report kin: they feed
walked.md pages; they never bind (heuristics propose, Palle rules).

  python tools/eye_shot.py --map=SoftBodies_Carusell
  python tools/eye_shot.py --seq=softbodies          # the draft V1 thread
"""
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPS = ROOT / "commons" / "maps"
NOTES = ROOT / "doc" / "book" / "eye_shots"
DRAFTS = ROOT / "doc" / "book" / "sequence_drafts"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

PY = sys.executable


def run(args, timeout=180):
    r = subprocess.run([PY] + args, cwd=ROOT, capture_output=True,
                       text=True, encoding="utf-8", errors="replace",
                       timeout=timeout)
    return (r.stdout or "") + (r.stderr or "")


def gaze(map_name):
    """ride the map; return (text, overlaps, tights, first_lines)."""
    t = run(["tools/gaze_ride.py", map_name])
    overlaps = len(re.findall(r"\[OVERLAP\]", t))
    tights = len(re.findall(r"\[tight\s*\]", t))
    viol_lines = [l.strip() for l in t.splitlines()
                  if "[OVERLAP]" in l or "[tight" in l][:8]
    return t, overlaps, tights, viol_lines


def qfep_index():
    """artifact -> (phase, crit head) via qfep_signal.build_critical_index()."""
    sys.path.insert(0, str(ROOT / "tools"))
    import qfep_signal as qs
    idx = qs.build_critical_index()
    return {k: (v.get("phase"), (v.get("crit_text") or "").replace("\n", " ")[:110])
            for k, v in idx.items()}


def map_cast(name):
    p = MAPS / name / "map_data.json"
    if not p.exists():
        return []
    md = json.loads(p.read_text(encoding="utf-8"))
    cast = set()
    for row in md.get("layers", {}).get("interactables", []):
        for c in row:
            if c and c.strip():
                base = c.split(":")[0].split("#")[0]
                m = re.search(r"#mount:([a-zA-Z0-9_]+)", c)
                cast.add(m.group(1) if m else base)
    return sorted(cast)


def read_walked(map_name, cast):
    """the existing writing, IN the loop (Palle): the map's walked.md +
    dwell declarations. Returns (exists, mentioned_cast, unmentioned_cast,
    dwelled_count)."""
    p = MAPS / map_name / "walked.md"
    if not p.exists():
        return False, [], list(cast), 0
    text = p.read_text(encoding="utf-8", errors="replace").lower()
    mentioned = [a for a in cast
                 if a.lower() in text
                 or a.lower().replace("_", " ") in text]
    unmentioned = [a for a in cast if a not in mentioned]
    try:
        dw = json.loads((ROOT / "commons" / "data" / "artifact_dwell.json")
                        .read_text(encoding="utf-8")).get("artifacts", {})
    except Exception:
        dw = {}
    dwelled = sum(1 for a in cast if a in dw)
    return True, mentioned, unmentioned, dwelled


def make_sibling(src, dst):
    d = MAPS / dst
    if d.exists():
        shutil.rmtree(d)
    d.mkdir(parents=True)
    md = json.loads((MAPS / src / "map_data.json").read_text(encoding="utf-8"))
    mi = md.setdefault("map_info", {})
    mi["name"] = mi["lookup_name"] = mi["title"] = dst
    mi["eye_shot_of"] = src
    (d / "map_data.json").write_text(json.dumps(md, indent=1),
                                     encoding="utf-8", newline="\n")


def shot(map_name, qidx):
    src = MAPS / map_name / "map_data.json"
    if not src.exists():
        print(f"  {map_name}: no map_data — skip")
        return None
    sib = f"Trial_eye_{map_name}"

    ride_before, ov_b, ti_b, viol_b = gaze(map_name)

    make_sibling(map_name, sib)
    place_out = run(["tools/place.py", f"--map={sib}", "--in-place",
                     "--only-improve", "--seed=7"], timeout=300)
    place_tail = [l for l in place_out.strip().splitlines() if l.strip()][-4:]

    pf = run(["tools/map_pathfinder.py", "check", sib])
    pf_ok = "0 FAIL" in pf and " OK" in pf

    ride_after, ov_a, ti_a, viol_a = gaze(sib) if pf_ok else ("", 99, 99, [])

    improved = pf_ok and (ov_a < ov_b or (ov_a == ov_b and ti_a < ti_b))
    if not improved:
        shutil.rmtree(MAPS / sib, ignore_errors=True)

    cast = map_cast(map_name)
    voices = [(a, qidx[a][1]) for a in cast if a in qidx and qidx[a][1]]
    mutes = [a for a in cast if a not in qidx or not qidx[a][1]]

    NOTES.mkdir(parents=True, exist_ok=True)
    note = NOTES / f"{map_name}.md"
    L = []
    L.append(f"# Eye shot — {map_name}\n")
    L.append(f"> one pass: ride (gaze), move (place --only-improve), "
             f"gate (pathfinder), voice (qfep). Field note, not a ruling.\n")
    L.append("## The ride (before)")
    L.append(f"clearance violations: **{ov_b} overlaps, {ti_b} tight** — "
             f"the law wants ≥1.2m to walk between.")
    for v in viol_b:
        L.append(f"- `{v}`")
    L.append("\n## The move")
    for l in place_tail:
        L.append(f"    {l}")
    if improved:
        L.append(f"\nsibling **{sib}** kept: overlaps {ov_b}→{ov_a}, "
                 f"tight {ti_b}→{ti_a}, pathfinder OK.")
    else:
        L.append(f"\nno sibling kept — {'pathfinder failed' if not pf_ok else 'the move did not beat the ride'}"
                 f" (overlaps {ov_b}→{ov_a}, tight {ti_b}→{ti_a}). Note-only.")
    L.append("\n## The voice (qfep)")
    L.append(f"{len(voices)} of {len(cast)} cast members carry a theory-claim; "
             f"{len(mutes)} mute.")
    for a, crit in voices[:4]:
        L.append(f"- **{a}** — {crit}")
    if mutes:
        L.append(f"- mute: {', '.join(mutes[:8])}")
    walked_exists, mentioned, unmentioned, dwelled = read_walked(map_name, cast)
    L.append("\n## The text vs the space")
    if walked_exists:
        viol_names = set(re.findall(r"[a-zA-Z0-9_]+", " ".join(viol_b)))
        blocked = [a for a in mentioned if a in viol_names]
        L.append(f"walked.md exists — the writing names {len(mentioned)}/"
                 f"{len(cast)} of the cast; dwells declared for {dwelled}.")
        if blocked:
            L.append(f"- **the writing's subjects are blocked in space**: "
                     f"{', '.join(blocked)} sit in clearance violations — "
                     f"the text promises what the floor obstructs.")
        if unmentioned:
            L.append(f"- space without text: {', '.join(unmentioned[:6])} — "
                     f"standing in the room, absent from the walk.")
        if not blocked and not unmentioned:
            L.append("- the text and the space cover each other — the walk "
                     "as written is the walk as built.")
    else:
        L.append("**no walked.md** — the space stands unwritten; this note "
                 "is the first text this map has.")
    L.append("\n## The heuristic understanding")
    if ov_b == 0 and ti_b <= 2:
        L.append("The space already walks: the bodies keep the law without "
                 "being told. What carries this map is its voice, not its floor.")
    elif improved:
        L.append("The floor was fighting the walk — bodies inside each other's "
                 "clearance. The mover found a better seating; the ride confirms "
                 "it in text. The voice column above says what the room is FOR; "
                 "the next writing pass should say it in the walked page.")
    else:
        L.append("The violations are real but mechanical moving does not fix "
                 "them — they are placement DECISIONS (which body yields?), "
                 "not placement errors. This is verdict material, not tooling "
                 "material.")
    body = "\n".join(L) + "\n"
    note.write_text(body, encoding="utf-8", newline="\n")
    # the map-dir copy: beside walked.md, where the /book compilers read
    (MAPS / map_name / "eye_shot.md").write_text(body, encoding="utf-8",
                                                 newline="\n")

    print(f"  {map_name:36s} ov {ov_b}->{ov_a if pf_ok else '-'} "
          f"ti {ti_b}->{ti_a if pf_ok else '-'} "
          f"{'KEPT ' + sib if improved else 'note-only'}  "
          f"voices {len(voices)}/{len(cast)}")
    return {"map": map_name, "improved": improved,
            "overlaps": [ov_b, ov_a], "tight": [ti_b, ti_a],
            "voices": len(voices), "cast": len(cast)}


def main():
    arg = lambda k: next((a.split("=", 1)[1] for a in sys.argv
                          if a.startswith(f"--{k}=")), None)
    targets = []
    if arg("map"):
        targets = [arg("map")]
    elif arg("seq"):
        d = json.loads((DRAFTS / f"{arg('seq')}.json").read_text(encoding="utf-8"))
        targets = [e["map"] for e in d["v1_tutorial"] if e.get("map")]
    if not targets:
        print(__doc__)
        return 1
    print("building qfep index…")
    qidx = qfep_index()
    print(f"index: {len(qidx)} artifacts with critical text\n")
    for m in targets:
        shot(m, qidx)
    return 0


if __name__ == "__main__":
    sys.exit(main())
