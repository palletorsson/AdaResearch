#!/usr/bin/env python3
"""The artifact timeline's EARNED rule and DRAFT promotion (tools/artifact_timeline.py, 2026-11-10/11), on sandbox
copies - no project file is written.

    python tools/test_timeline_earned.py            # exit = failures
    python tools/test_timeline_earned.py --real     # also: the earned flags on the real timeline, and on the randomness
                                                    # floors with the robot pilot's proposed forms applied in memory
"""
import copy
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import artifact_timeline as at

fails = []


def ok(cond, what):
    print(("PASS " if cond else "FAIL ") + what)
    if not cond:
        fails.append(what)


tm = at.terms()

# 1 the rule on a small track: quad (index 7) is a part; the space editor grants it from floor 5
row = lambda key, term, floor, **kw: {"key": key, "floor": floor, "form": {"kind": "base", "term": term}, **kw}
probe_terms = {**tm, "uses_quad": {"expr": "x", "from": ["quad"], "build": {"op": "compose", "parts": [{"t": "quad"}, {"t": "box"}]}}}
doc = {"main": [row("a", "line", 1), row("b", "uses_quad", 2), row("c", "uses_quad", 2)]}   # two works share quad
f = at.earned_flags(doc, probe_terms)
ok(f["a"] == "", "a line on floor 1 is earned (point is a block, line a known form)")
ok(f["b"].startswith("not earned: quad"), f"a work made of quad on floor 2 is not earned ({f['b']!r})")
doc["main"][1]["early"] = "a glimpse of the quad on purpose"
ok(at.earned_flags(doc, probe_terms)["b"] == "", "'early' silences the flag")
doc = {"main": [row("a", "line", 1), row("b", "uses_quad", 6), row("c", "uses_quad", 6)]}
ok(at.earned_flags(doc, probe_terms)["b"] == "", "on floor 6 the space editor has granted quad: earned")
doc = {"main": [row("q", "quad", 2), row("b", "uses_quad", 3)]}
ok(at.earned_flags(doc, probe_terms)["b"] == "", "a quad shown on an earlier row earns it")
doc = {"main": [row("b", "uses_quad", 3), row("q", "quad", 4)]}   # quad has its own row: never internal
ok("first shown at" in at.earned_flags(doc, probe_terms)["b"], "the flag names where the part is first shown, when later")
doc = {"main": [row("a", "line", 1), row("b", "uses_quad", 2)]}
ok(at.earned_flags(doc, probe_terms)["b"] == "", "a part only one work is made of (and nobody's form) is its own construction: not flagged")
doc = {"main": [row("z", "no_such_term", 3)]}
ok(at.earned_flags(doc, probe_terms)["z"].startswith("term no_such_term"), "a form naming no term is flagged")

# 2 promotion and 3 the save round trip, on sandbox copies of the timeline, terms.json and a drafts file
box = Path(tempfile.mkdtemp(prefix="timeline_earned_"))
try:
    saved = (at.AUTHORED, at.TERMS, at.DRAFTS, at.write_view)
    at.AUTHORED, at.TERMS, at.DRAFTS = box / "timeline.json", box / "terms.json", box / "drafts.json"
    shutil.copy(saved[0], at.AUTHORED)
    shutil.copy(saved[1], at.TERMS)
    at.DRAFTS.write_text(json.dumps({"_doc": "test", "terms": {
        "probe_outer": {"expr": "o", "from": ["probe_inner"], "chapter": "randomness",
                        "build": {"op": "sample", "of": {"t": "probe_inner"}}, "drafted_by": "test"},
        "probe_inner": {"expr": "i", "from": ["box"], "chapter": "randomness",
                        "build": {"op": "array", "of": {"t": "box"}, "n": 4, "dims": 1}, "drafted_by": "test"},
        "probe_unused": {"expr": "u", "from": [], "chapter": "randomness", "build": {"p": "mesh"}, "drafted_by": "test"}}},
        indent=1), encoding="utf-8")
    moved = at.promote_drafts({"probe_outer"})
    ok(moved == ["probe_inner", "probe_outer"], f"a draft brings the drafts it is built from ({moved})")
    raw = at.TERMS.read_bytes()
    g = json.loads(raw.decode("utf-8"))
    ok((json.dumps(g, indent=2, ensure_ascii=False) + "\n").encode("utf-8") == raw, "terms.json stays in its indent-2 form")
    ok(g["terms"]["probe_outer"]["accepted"]["by"] == "timeline save", "an accepted term records its acceptance")
    left = json.loads(at.DRAFTS.read_text(encoding="utf-8"))["terms"]
    ok(sorted(left) == ["probe_unused"], "only the accepted drafts leave the drafts file")
    ok(at.promote_drafts({"probe_outer"}) == [], "promoting twice moves nothing")

    # the save: a row given a draft form and an early note
    shutil.copy(saved[1], at.TERMS)
    at.DRAFTS.write_text(json.dumps({"_doc": "test", "terms": {
        "probe_outer": {"expr": "o", "from": ["box"], "chapter": "randomness", "build": {"op": "sample", "of": {"t": "box"}}}}}),
        encoding="utf-8")
    at.write_view = lambda: {"counts": {}}
    cur = at.read(at.AUTHORED)
    body = {"base": cur.get("edited_at") or cur.get("seeded_at"), "main": copy.deepcopy(cur["main"]),
            "environment": cur.get("environment", []), "removed": cur.get("removed", [])}
    body["main"][0]["form"] = {"kind": "base", "term": "probe_outer"}
    body["main"][0]["early"] = "shown early on purpose"
    import io, contextlib
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = at.save(json.dumps(body))
    res = json.loads(out.getvalue().strip().splitlines()[-1])
    after = at.read(at.AUTHORED)["main"][0]
    ok(code == 0 and res.get("terms_accepted") == ["probe_outer"], f"saving a draft form accepts its term ({res.get('terms_accepted')})")
    ok(after.get("early") == "shown early on purpose", "the save keeps 'early'")
    ok("probe_outer" in at.terms(), "the accepted term is in terms.json after the save")
finally:
    at.AUTHORED, at.TERMS, at.DRAFTS, at.write_view = saved
    shutil.rmtree(box, ignore_errors=True)

if "--real" in sys.argv:
    real = at.read(at.AUTHORED)
    allt = {**at.drafts(), **tm}
    flags = at.earned_flags(real, allt)
    bad = {k: v for k, v in flags.items() if v}
    print(f"\nREAL timeline now: {sum(1 for r in real['main'] if (r.get('form') or {}).get('term'))} rows with a form term, "
          f"{len(bad)} flagged")
    for k, v in list(bad.items())[:12]:
        print(f"  {k}: {v}")
    thread = next((e for e in at.read_threads()["entries"] if e["id"] == "t20261110123727167"), None)
    if thread:
        trial = copy.deepcopy(real)
        ops = {o["key"]: o["form"] for o in thread["answer"]["operations"] if o.get("valid") and o["op"] == "form"}
        for r in trial["main"]:
            if r["key"] in ops:
                r["form"] = ops[r["key"]]
        f2 = at.earned_flags(trial, allt)
        rand = [r for r in trial["main"] if r["key"] in ops]
        bad2 = [(r["key"], r.get("floor"), f2[r["key"]]) for r in rand if f2[r["key"]]]
        print(f"\nRANDOMNESS with the pilot's {len(ops)} forms applied in memory: {len(bad2)} of {len(rand)} not earned")
        from collections import Counter
        parts = Counter(p.split(" (")[0].strip() for _, _, v in bad2 for p in v.removeprefix("not earned: ").split("; "))
        print("  parts nothing earned before them:", parts.most_common(15))
        for k, fl, v in bad2[:20]:
            print(f"  floor {fl} {k}: {v}")

print(f"\n{len(fails)} failed")
sys.exit(len(fails))
