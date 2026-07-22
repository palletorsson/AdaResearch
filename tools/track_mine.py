"""track_mine.py — learn the section grammar from the composed corridors (P-10).

Archaeology, not invention (L-022): re-express each composed map as a train of
row-categories (edge_walk / side_bay / mirror_bay / axis_moment / breather),
run-length grouped, and count the transitions. The result is the empirical
coupling grammar of Palle's hand — which section follows which — written to
commons/data/track_grammar.json for track_compose to sample from.

  python tools/track_mine.py --scripts doc/book/look_scripts/primitives.json
"""
import argparse
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")


def categorize_rows(map_name):
    d = json.load(open(os.path.join(MAPS_DIR, map_name, "map_data.json"), encoding="utf-8"))
    I = d["layers"]["interactables"]
    W = len(I[0])
    cats = []
    for row in I:
        occ = [x for x, c in enumerate(row) if str(c).strip()]
        if not occ:
            cats.append("breather")
            continue
        lanes = set()
        for x in occ:
            f = x / max(1, W - 1)
            lanes.add("L" if f < 0.40 else "C" if f <= 0.60 else "R")
        if lanes == {"C"}:
            cats.append("axis_moment")
        elif lanes == {"L", "R"}:
            cats.append("mirror_bay")
        elif "C" in lanes:
            cats.append("axis_moment")
        elif len(occ) == 1 or (max(occ) <= 1 or min(occ) >= W - 2):
            cats.append("edge_walk")
        else:
            cats.append("side_bay")
    # run-length group
    train = []
    for c in cats:
        if train and train[-1][0] == c:
            train[-1][1] += 1
        else:
            train.append([c, 1])
    return train


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scripts", default="doc/book/look_scripts/primitives.json")
    args = ap.parse_args()
    scripts = json.load(open(os.path.join(ROOT, args.scripts), encoding="utf-8"))
    trans = {}
    starts = {}
    lengths = {}
    trains = {}
    for m in scripts["maps"]:
        train = categorize_rows(m)
        trains[m] = train
        if not train:
            continue
        starts[train[0][0]] = starts.get(train[0][0], 0) + 1
        for (a, la), (b, _) in zip(train, train[1:]):
            trans.setdefault(a, {})[b] = trans.get(a, {}).get(b, 0) + 1
        for c, ln in train:
            lengths.setdefault(c, []).append(ln)
        print(f"{m:28} " + " > ".join(f"{c}:{n}" for c, n in train))
    grammar = {
        "_readme": "Empirical section-coupling grammar mined from the composed corridors "
                   "(track_mine.py). Counts, not probabilities — normalize at sample time. "
                   "The hand's grammar: archaeology, not invention (L-022).",
        "starts": starts,
        "transitions": trans,
        "run_lengths": {c: sorted(v) for c, v in lengths.items()},
        "trains": trains,
    }
    out = os.path.join(ROOT, "commons", "data", "track_grammar.json")
    json.dump(grammar, open(out, "w", encoding="utf-8"), indent=1)
    print(f"\ngrammar -> {out}")
    print("transitions:")
    for a, row in trans.items():
        total = sum(row.values())
        tops = ", ".join(f"{b} {100*n//total}%" for b, n in
                         sorted(row.items(), key=lambda kv: -kv[1]))
        print(f"  {a:12} -> {tops}")


if __name__ == "__main__":
    main()
