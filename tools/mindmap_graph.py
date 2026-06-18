"""Assemble the ARTIFACT-LEVEL mind-map graph — every artifact a node, heuristically placed.

The meta layer gives concept-level distance. This flattens it to the artifact level: each
artifact inherits its concept's place in the tutorial timeline and the concept's cluster, then
spreads within the concept by magnitude (tier). Hundreds of nodes, positioned from structure we
already have (concept membership + tier + reading order) — heuristic on purpose, refined later
by the channels. This single doc/<domain>_mindmap.json is what the encyclopedia projector page
and the VR-order export both read.

Layers folded in per artifact:
  order  — its concept's index in the tutorial (the forward story axis)
  concept— its concept cluster + the concept-distance matrix (clusters of meaning)
  magnitude — its tier (small/medium/large/applied) -> node size
  spine  — concept act/phase -> colour band

Run:  python tools/mindmap_graph.py            # every <domain>_concept_map.json found
      python tools/mindmap_graph.py vector_forces
"""
import json, glob, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, "doc")
SIZE = {"small": 5, "medium": 8, "large": 14, "applied": 10}


def find_concept_map(domain):
    for cand in ("%s_concept_map.json" % domain, "vector_forces_concept_map.json" if domain == "vector_forces" else None):
        if cand and os.path.exists(os.path.join(DOC, cand)):
            return os.path.join(DOC, cand)
    return None


def anchor_spread(M):
    """Cheap 1D embedding of the concept-distance matrix: project each concept onto the axis
    between the farthest-apart pair. x = d(c,A) - d(c,B), normalised to [-1,1]."""
    n = len(M)
    if n < 2:
        return [0.0] * n
    A, B, best = 0, 1, -1.0
    for i in range(n):
        for j in range(i + 1, n):
            if M[i][j] > best:
                best, A, B = M[i][j], i, j
    raw = [M[c][A] - M[c][B] for c in range(n)]
    lo, hi = min(raw), max(raw)
    if hi <= lo:
        return [0.0] * n
    return [round(2.0 * (x - lo) / (hi - lo) - 1.0, 4) for x in raw]


def build(domain):
    cmpath = find_concept_map(domain)
    if not cmpath:
        return None, "no concept map for %s (artifact-level needs a <domain>_concept_map.json)" % domain
    D = json.load(open(cmpath, encoding="utf-8"))
    concepts = D["concepts"]
    cm = D["concept_meta"]
    groups = D["groups"]
    order_idx = {c: i for i, c in enumerate(concepts)}

    # concept-distance: prefer the concept map's own concept-text distance, then a tutorial
    # distance aligned by order, then order-only proximity.
    cdist = D.get("concept_distance")
    if not (cdist and len(cdist) == len(concepts)):
        cdist = None
    dist_path = os.path.join(DOC, domain + "_distance.json")
    if cdist is None and os.path.exists(dist_path):
        dd = json.load(open(dist_path, encoding="utf-8")).get("matrix")
        if dd and len(dd) >= len(concepts):
            cdist = [row[:len(concepts)] for row in dd[:len(concepts)]]
    if cdist is None:                       # fallback: order-only proximity
        n = len(concepts)
        cdist = [[round(abs(i - j) / (n - 1), 4) if n > 1 else 0.0 for j in range(n)] for i in range(n)]
    spread = anchor_spread(cdist)

    artifacts = []
    for c in concepts:
        for a in groups.get(c, []):
            tier = a.get("tier", "medium")
            artifacts.append({
                "lookup": a["lookup"], "name": a.get("name", a["lookup"]),
                "concept": c, "concept_order": order_idx[c], "tier": tier,
                "fp": a.get("fp", 4), "size": SIZE.get(tier, 8),
                "act": cm[c].get("act", ""), "has_image": a.get("has_image", False),
                "recommended": a.get("recommended", False),
            })
    concept_list = [{
        "key": c, "order": order_idx[c], "act": cm[c].get("act", ""),
        "truth": cm[c].get("truth", ""), "count": len(groups.get(c, [])),
        "x_spread": spread[order_idx[c]],
        "tiers": {t: cm[c].get("tiers", {}).get(t, []) for t in ("small", "medium", "large", "applied")},
    } for c in concepts]

    out = {
        "domain": domain, "title": D.get("title", domain),
        "note": "Artifact-level mind-map: every artifact placed heuristically from concept + tier + reading order. "
                "y = concept_order (timeline); x morphs from a single column (order) to concept clusters (x_spread).",
        "level": "artifact", "heuristic": True,
        "concepts": concept_list, "concept_distance": cdist,
        "artifacts": artifacts, "total_artifacts": len(artifacts), "total_concepts": len(concepts),
    }
    return out, None


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else None
    maps = sorted(glob.glob(os.path.join(DOC, "*_concept_map.json")))
    domains = [os.path.basename(m)[:-len("_concept_map.json")] for m in maps]
    if which:
        domains = [d for d in domains if d == which] or [which]
    if not domains:
        print("no *_concept_map.json in doc/")
        return
    for dm in domains:
        out, err = build(dm)
        if err:
            print("skip %s: %s" % (dm, err))
            continue
        json.dump(out, open(os.path.join(DOC, dm + "_mindmap.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        nb = sum(1 for a in out["artifacts"] if a["concept_order"] == 0)
        print("%s: %d artifacts across %d concepts -> doc/%s_mindmap.json" % (
            dm, out["total_artifacts"], out["total_concepts"], dm))


if __name__ == "__main__":
    main()
