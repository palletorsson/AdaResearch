#!/usr/bin/env python3
"""tools/grammar.py bites (Palle, 2026-11-09: "Move the pendulum below the skateboard; make a grammar that can work
throughout the whole spine"). The live data must pass the checks this test names, and each check must fail when the
data is broken the way it guards against - in memory, nothing is written.
    python tools/test_grammar.py"""
import copy
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import grammar  # noqa: E402

results = []


def check(label: str, ok: bool) -> None:
    results.append(ok)
    print(("PASS " if ok else "FAIL ") + label)


def kinds(r: dict, kind: str) -> list:
    return [t for k, t in r["violations"] if k == kind]


base = grammar.load()
live = grammar.check(copy.deepcopy(base))
check("every card speaks the grammar's vocabulary (%d cards)" % live["cards"], not kinds(live, "vocabulary"))
check("every spine sequence with floors has its root card on its own floors", not kinds(live, "spine"))
check("the skateboard's tie is earned: the pendulum stands below it",
      not any("mod_skateboard" in t and " tie " in t for t in kinds(live, "earned")))
check("the elevated plank (parts:1) is met before the skateboard (parts:2)", not any("raises parts to 2" in t for t in kinds(live, "axes")))
check("the grammar reads nearly every expression word (%d unread)" % len(live["unknown"]), len(live["unknown"]) <= 6)

# 1. the pendulum back on the seesaw's floor (Logic_Event), after the seesaw: the skateboard uses a tie before its card
d = copy.deepcopy(base)
main = d["doc"]["main"]
row = next(r for r in main if r["key"] == "physics_play_pendulum")
main.remove(row)
row["floor"] = next(r for r in main if r["key"] == "physics_play_seesaw")["floor"]
main.insert(next(i for i, r in enumerate(main) if r["key"] == "physics_play_seesaw") + 1, row)
r = grammar.check(d)
check("BITES: with the pendulum back on the seesaw's floor the skateboard uses tie unearned",
      any("mod_skateboard" in t and "uses tie before its card" in t for t in kinds(r, "earned")))

# 1b. the plank on a ball back on the seesaw's floor: the skateboard's parts:2 stands before parts:1 again
d = copy.deepcopy(base)
main = d["doc"]["main"]
row = next(r for r in main if r["key"] == "physics_play_plank_ball")
main.remove(row)
row["floor"] = next(r for r in main if r["key"] == "physics_play_seesaw")["floor"]
main.insert(next(i for i, r in enumerate(main) if r["key"] == "physics_play_seesaw") + 1, row)
r = grammar.check(d)
check("BITES: with the plank on a ball back on the seesaw's floor the skateboard's parts:2 comes before parts:1",
      any("skateboard_3 raises parts to 2" in t for t in kinds(r, "axes")))

# 2. no domino card: the AND gate raises react to 2 with no level 1 below it
d = copy.deepcopy(base)
d["terms"]["domino"].pop("card")
r = grammar.check(d)
check("BITES: without the domino card the AND gate's react:2 has no react:1", any("and_gate raises react to 2" in t for t in kinds(r, "axes")))

# 3. an operation the grammar does not have
d = copy.deepcopy(base)
d["terms"]["line"]["card"]["op"] = "stretch"
r = grammar.check(d)
check("BITES: a card op outside the vocabulary is refused", any("'stretch'" in t for t in kinds(r, "vocabulary")))

# 4. a root card placed on another sequence's floor
d = copy.deepcopy(base)
for x in d["doc"]["main"]:
    if x.get("cards") == ["rainbow_row"]:
        x.pop("cards")
next(x for x in d["doc"]["main"] if x["key"] == "row_3_x").setdefault("cards", []).append("rainbow_row")
r = grammar.check(d)
check("BITES: colour's root card standing on the Array floor is refused", any(t.startswith("color: root card rainbow_row stands on floor %d" % next(x["floor"] for x in d["doc"]["main"] if x["key"] == "row_3_x")) for t in kinds(r, "spine")))

# 5. an operation used before any card introduces it
d = copy.deepcopy(base)
for x in d["doc"]["main"]:
    if x.get("cards") == ["noise_heights"]:
        x.pop("cards")
d["terms"]["metaballs"]["card"]["op"] = "assemblage"   # nothing else introduces field
r = grammar.check(d)
check("BITES: a field used with no field card is caught", any("uses field" in t for t in kinds(r, "earned")))

print("%d/%d" % (sum(results), len(results)))
sys.exit(0 if all(results) else 1)
