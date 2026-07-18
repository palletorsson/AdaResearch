#!/usr/bin/env python3
"""qfep_signal.py - a REAL per-artifact critical signal for three_orders, from the QFEP STRUCTURE
(not generic vocabulary):

  phase     : the artifact's position in the QFEP arc -
              F_order -> oscillation -> E_entropy -> lambda_edge -> integration -> relation -> synthesis
              read from the per-artifact registry `qfep_connection` prefix (e.g. "F_order: ...").
  crit_text : the artifact's @identity critical_parameter + truth + essence + desire - its OWN
              theory claim, extracted from the .gd source (same regex query_identities uses).

build_critical_index() -> { lookup_name: {phase, phase_idx, crit_text} }   (cached)
"""
import json, os, re, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PHASES = ["f_order", "oscillation", "e_entropy", "lambda_edge", "integration", "relation", "synthesis"]
_IDENT_FIELDS = ["critical_parameter", "truth", "essence", "desire"]
# An artifact's ROLE: 'content' (a real pearl) | 'ambient' (decoration, exclude from the order) |
# 'container' (shows OTHER content - its ontology is its shell, not its content; needs a content tag).
# Decoration-DESIRE language only (an artifact that wants to be unnoticed). NOT "ambient"/"atmosphere"
# on their own - those catch real content that merely uses ambient *sound* (ruth_asawa, john_cage).
_AMBIENT_KW = ("never dominant", "barely notice", "without asserting", "witness to", "marks the inhabited",
               "always present but never", "set dressing")
_CONTAINER_KW = ("subviewport", "renders the grid-state", "wall-mounted screen", "pixel-map",
                 "flattened beside", "2d representation", "renders nearby", "2d pixel-map")
_ROLE_OVERRIDE = {"dark_sphere": "ambient", "science_screen": "container", "living_paper": "container"}
# Confirmed CONTENT that tripped a keyword - the concept lives in their @identity (a curve, a wave,
# a paradox); they should embed by it, not be excluded.
_CONTENT_OVERRIDE = {"ruth_asawa_sculpture", "john_cage_tech_noir", "russell_paradox_workbench"}
_CACHE = None


def phase_idx(s):
    s = (s or "").strip().lower()
    for i, p in enumerate(PHASES):
        if s.startswith(p):
            return i
    return None


def build_critical_index():
    global _CACHE
    if _CACHE is not None:
        return _CACHE
    idx = {}

    def ent(ln):
        return idx.setdefault(ln, {"phase": None, "phase_idx": None, "crit_text": "", "role": None})

    _scene_alias = {}   # script/scene stem -> {lookup_names} (see step 1)

    # 1) registries: per-artifact qfep_connection prefix -> phase (+ its critical prose)
    for p in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts")
        if not isinstance(arts, dict):
            continue
        for key, e in arts.items():
            if not isinstance(e, dict):
                continue
            ln = e.get("lookup_name", key)
            q = str(e.get("qfep_connection", "") or e.get("qfep", "")).strip()
            v = ent(ln)
            pi = phase_idx(q)
            if pi is not None and v["phase_idx"] is None:
                v["phase"], v["phase_idx"] = PHASES[pi], pi
            if q:
                v["crit_text"] = (v["crit_text"] + " " + q).strip()
            # scene-stem alias: @identity in .gd is keyed by script FILENAME,
            # but maps speak lookup_name — when they differ (softstopscene ->
            # fourstopsoftbody.tscn) the artifact reads as mute. Remember the
            # scene stem so step 2 can merge the .gd claim into the lookup.
            sc = str(e.get("scene", ""))
            if sc:
                stem = os.path.splitext(os.path.basename(sc))[0]
                if stem and stem != ln:
                    _scene_alias.setdefault(stem, set()).add(ln)

    # 2) @identity from .gd: the artifact's own theory claim
    for base in ("algorithms", os.path.join("commons", "artifacts")):
        for root, _, files in os.walk(os.path.join(ROOT, base)):
            for f in files:
                if not f.endswith(".gd"):
                    continue
                try:
                    text = open(os.path.join(root, f), encoding="utf-8", errors="replace").read()
                except Exception:
                    continue
                if "@identity" not in text:
                    continue
                v = ent(f[:-3])
                bits = []
                for field in _IDENT_FIELDS:
                    m = re.search(rf"#\s*{field}:\s*(.+)", text)
                    if m:
                        bits.append(m.group(1).strip())
                if bits:
                    blob = " ".join(bits)
                    targets = [v] + [ent(a) for a in
                                     _scene_alias.get(f[:-3], ())]
                    low = blob.lower()
                    for tv in targets:
                        tv["crit_text"] = (tv["crit_text"] + " " + blob).strip()
                        if tv["role"] is None:
                            if any(k in low for k in _AMBIENT_KW):
                                tv["role"] = "ambient"
                            elif any(k in low for k in _CONTAINER_KW):
                                tv["role"] = "container"

    for t, r in _ROLE_OVERRIDE.items():          # curated truth wins
        idx.setdefault(t, {"phase": None, "phase_idx": None, "crit_text": "", "role": None})["role"] = r
    for t in _CONTENT_OVERRIDE:                   # ...but confirmed content is never excluded
        if t in idx:
            idx[t]["role"] = None

    _CACHE = idx
    return idx


if __name__ == "__main__":
    import sys
    idx = build_critical_index()
    phased = [v for v in idx.values() if v["phase_idx"] is not None]
    ctext = [v for v in idx.values() if v["crit_text"].strip()]
    print("critical index: %d artifacts  |  with QFEP phase: %d  |  with @identity crit_text: %d"
          % (len(idx), len(phased), len(ctext)))
    if len(sys.argv) > 1:  # coverage for a sequence's pearls (names piped or listed)
        names = sys.argv[1:]
        for n in names:
            v = idx.get(n, {})
            print("  %-34s phase=%-12s crit=%r" % (n, v.get("phase"), (v.get("crit_text", "")[:70])))
    else:
        from collections import Counter
        c = Counter(v["phase"] for v in phased)
        print("phase distribution:", dict(c))
        for ln, v in list(idx.items())[:4]:
            print("  %-30s phase=%-12s crit=%r" % (ln, v["phase"], v["crit_text"][:80]))
