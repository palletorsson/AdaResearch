#!/usr/bin/env python3
"""
Garden Listener — hears the chatter of sequences and artifacts.
Reports health, potential, and what each algorithm needs to find its body.

Usage:
    python tools/garden_listener.py physicssimulation     # listen to one sequence
    python tools/garden_listener.py ALL                    # listen to everything
    python tools/garden_listener.py --potential IKArm      # one artifact's potential
    python tools/garden_listener.py --silent               # find all voiceless artifacts
    python tools/garden_listener.py --reaching             # find all phantom limbs
    python tools/garden_listener.py --full                 # find all complete bodies
    python tools/garden_listener.py --diagnosis            # project-wide health report
"""

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"
SEARCH_DIRS = [REPO / "algorithms", REPO / "commons" / "artifacts", REPO / "commons"]
SKIP_ARTS = {" ", "0", "dark_sphere", "catalyst_target", "proximity_spawner",
             "becoming_catalyst", "pickup_gate", "pick_up_cube"}
SKIP_SEQS = {"sequence_index", "testmaps", "unused", "devexamples",
             "proceduralgeneration_all", "templats"}

IDENTITY_FIELDS = ["essence", "desire", "critical_parameter", "triggers",
                   "emerges", "needs", "relationships", "truth"]

# Global cache for .gd file lookup
_GD_CACHE = None

def _build_cache():
    global _GD_CACHE
    if _GD_CACHE is not None:
        return
    _GD_CACHE = {}
    for search_dir in SEARCH_DIRS:
        if not search_dir.exists():
            continue
        for gd in search_dir.rglob("*.gd"):
            key = gd.stem.lower()
            _GD_CACHE[key] = gd
            # Also register a normalized key (no underscores) for PascalCase
            # files whose lookup name uses snake_case (e.g. NeuralNetworks_VR
            # vs neural_networks_vr). Exact match wins; this is fallback only.
            norm = key.replace("_", "")
            if norm not in _GD_CACHE:
                _GD_CACHE[norm] = gd


_REG_CACHE = None


def _build_registry_index():
    """Map artifact lookup-name -> backing .gd Path via registry scene_path.

    Many artifacts have a lookup name that differs from their file stem
    (e.g. 'folding_past' -> animated_folding_past.gd, 'dgrid' -> durer_grid.gd).
    Stem-only matching reports these as voiceless even when they carry an
    @identity. Resolve through the registry: read each entry's scene_path,
    open the .tscn, and follow its script ext_resource to the real .gd.
    """
    global _REG_CACHE
    if _REG_CACHE is not None:
        return
    _REG_CACHE = {}
    reg_dir = REPO / "commons" / "artifacts" / "registry"
    if not reg_dir.exists():
        return

    def _resolve_res(res_path):
        # res://foo/bar.ext -> REPO/foo/bar.ext
        rel = res_path.replace("res://", "").lstrip("/")
        return REPO / rel

    def _scene_to_gd(scene_res):
        scene = _resolve_res(scene_res)
        if not scene.exists():
            return None
        try:
            txt = scene.read_text(encoding="utf-8", errors="replace")
        except OSError:
            return None
        m = re.search(r'path="(res://[^"]+\.gd)"', txt)
        if m:
            gd = _resolve_res(m.group(1))
            return gd if gd.exists() else None
        # No script in scene: fall back to a sibling .gd with the same stem
        sib = scene.with_suffix(".gd")
        return sib if sib.exists() else None

    def _walk(o):
        if isinstance(o, dict):
            scene = o.get("scene_path") or o.get("scene")
            name = o.get("name") or o.get("lookup_name")
            if scene and name:
                gd = _scene_to_gd(str(scene))
                if gd is not None:
                    _REG_CACHE.setdefault(str(name).lower(), gd)
            for k, v in o.items():
                if isinstance(v, dict):
                    inner = v.get("scene_path") or v.get("scene")
                    if inner and k not in ("scene_path", "scene"):
                        gd = _scene_to_gd(str(inner))
                        if gd is not None:
                            _REG_CACHE.setdefault(str(k).lower(), gd)
                _walk(v)
        elif isinstance(o, list):
            for v in o:
                _walk(v)

    for reg in reg_dir.glob("*.json"):
        try:
            _walk(json.load(open(reg, encoding="utf-8")))
        except (json.JSONDecodeError, OSError):
            continue


def find_gd(artifact_name):
    """Find a .gd file for an artifact name."""
    _build_cache()
    key = artifact_name.lower()
    result = _GD_CACHE.get(key)
    if result is None:
        result = _GD_CACHE.get(key.replace("_", ""))
    if result is None:
        # Fallback: resolve lookup-name -> scene -> script via the registry.
        _build_registry_index()
        result = _REG_CACHE.get(key)
    return result


def read_identity(gd_path):
    """Read @identity fields from a .gd file."""
    text = gd_path.read_text(encoding="utf-8", errors="replace")
    if "@identity" not in text:
        return None
    ident = {}
    for field in IDENTITY_FIELDS:
        match = re.search(rf"#\s*{field}:\s*(.+)", text)
        if match:
            ident[field] = match.group(1).strip()
    return ident


def get_sequence_artifacts(seq_name):
    """Get ordered list of (map_name, title, [artifact_names]) for a sequence."""
    seq_path = SEQUENCES_DIR / f"{seq_name}.json"
    if not seq_path.exists():
        return []
    d = json.load(open(seq_path, encoding="utf-8"))
    seq_info = None
    for name, info in d.get("sequences", {}).items():
        seq_info = info
        break
    if not seq_info:
        return []

    result = []
    for map_name in seq_info.get("maps", []):
        map_path = MAPS_DIR / map_name / "map_data.json"
        if not map_path.exists():
            continue
        md = json.load(open(map_path, encoding="utf-8"))
        title = md.get("map_info", {}).get("title", map_name)
        arts = []
        for row in md.get("layers", {}).get("interactables", []):
            for cell in row:
                if cell and str(cell).strip() and str(cell) != "0":
                    name = str(cell).split(":")[0].strip()
                    if name not in SKIP_ARTS and name not in arts:
                        arts.append(name)
        result.append((map_name, title, arts))
    return result


def assess_potential(artifact_name, identity, context_title=""):
    """Assess an artifact's potential — what it could become."""
    if not identity:
        return {
            "state": "voiceless",
            "message": f"{artifact_name} has no @identity. It exists but doesn't know itself.",
            "prescription": "Read the .gd, understand the algorithm, write its identity. Start with: what is the one equation?"
        }

    needs = identity.get("needs", "")
    truth = identity.get("truth", "")
    desire = identity.get("desire", "")
    essence = identity.get("essence", "")
    critical = identity.get("critical_parameter", "")

    missing_count = needs.count("[missing")
    has_count = needs.count("[has]")

    # Parse what's missing
    missing_items = re.findall(r"([^,.\[\]]+?)\[missing[^\]]*\]", needs)
    has_items = re.findall(r"([^,.\[\]]+?)\[has\]", needs)

    if missing_count == 0 and has_count > 0:
        state = "embodied"
        message = f"{artifact_name} has found its body. {has_count} limbs, all present."
        prescription = _find_deepening(identity)
    elif missing_count > 0:
        state = "reaching"
        message = f"{artifact_name} is reaching for {missing_count} thing(s) it cannot touch."
        # The prescription IS the potential
        prescription = _find_growth_direction(artifact_name, identity, missing_items, critical, truth, desire)
    else:
        state = "dormant"
        message = f"{artifact_name} has a voice but no declared needs. It may not know what body it wants."
        prescription = f"Its truth is: '{truth}'. Ask: what VR interaction would make this truth felt in the body?"

    return {
        "state": state,
        "message": message,
        "prescription": prescription,
        "essence": essence,
        "truth": truth,
        "desire": desire,
        "missing": [m.strip() for m in missing_items],
        "has": [h.strip() for h in has_items],
    }


def _find_growth_direction(name, identity, missing_items, critical, truth, desire):
    """The core insight: what would make this algorithm find its body?"""
    lines = []

    # The critical parameter is the most important missing piece
    if critical and any("slider" in m.lower() or "control" in m.lower() for m in missing_items):
        lines.append(f"FIRST: Make '{critical}' touchable. Add a VR slider. This is the one parameter that changes {name}'s character.")

    # The truth needs a physical moment
    if truth:
        lines.append(f"The truth '{truth[:80]}...' needs a moment in VR where the learner FEELS it, not just reads it.")

    # The desire tells you the experience to build toward
    if desire:
        lines.append(f"It desires: '{desire[:80]}...' — build toward that experience.")

    # Specific missing items
    for item in missing_items:
        item = item.strip()
        if "slider" in item.lower():
            lines.append(f"Add: {item.strip()} — the body needs this limb to interact.")
        elif "label" in item.lower() or "display" in item.lower():
            lines.append(f"Add: {item.strip()} — the algorithm should show its own equation.")
        elif "grab" in item.lower():
            lines.append(f"Add: {item.strip()} — in VR, hands expect to touch. Let them.")

    if not lines:
        lines.append(f"Read its desire ('{desire[:60]}') and ask: what physical interaction would deliver that?")

    return " ".join(lines)


def _find_deepening(identity):
    """For embodied artifacts — what's the next level?"""
    truth = identity.get("truth", "")
    emerges = identity.get("emerges", "")
    relationships = identity.get("relationships", "")

    lines = []
    if emerges:
        lines.append(f"It already produces emergence: '{emerges[:80]}'. Can this be made more visible?")
    if relationships:
        lines.append(f"Its relationships: '{relationships[:80]}'. Can it communicate with its neighbors live?")
    if truth:
        lines.append(f"Its truth is embodied. The next question: does the learner leave understanding '{truth[:60]}' in their body?")

    return " ".join(lines) if lines else "This artifact has arrived. Maintain it."


def listen_to_sequence(seq_name):
    """Listen to a sequence — report its chatter, health, and potential."""
    maps = get_sequence_artifacts(seq_name)
    if not maps:
        print(f"Cannot find sequence: {seq_name}")
        return

    # Read sequence truth statement
    seq_path = SEQUENCES_DIR / f"{seq_name}.json"
    d = json.load(open(seq_path, encoding="utf-8"))
    seq_info = list(d.get("sequences", {}).values())[0]
    seq_truth = seq_info.get("truth", "(no truth statement)")
    seq_name_full = seq_info.get("name", seq_name)

    total_arts = 0
    voices = 0
    silent = 0
    reaching = 0
    embodied = 0
    total_phantom = 0
    total_limbs = 0
    prescriptions = []

    print(f"\n{'=' * 70}")
    print(f"LISTENING TO: {seq_name_full}")
    print(f"{'=' * 70}")
    print(f"Sequence truth: {seq_truth}")
    print()

    for map_name, title, arts in maps:
        if not arts:
            continue
        print(f"--- {title} ---")
        map_voices = 0
        map_silent = 0
        map_reaching_count = 0

        for art in arts:
            total_arts += 1
            gd = find_gd(art)
            if not gd:
                silent += 1
                map_silent += 1
                continue

            identity = read_identity(gd)
            assessment = assess_potential(art, identity, title)

            if assessment["state"] == "voiceless":
                silent += 1
                map_silent += 1
            elif assessment["state"] == "embodied":
                embodied += 1
                voices += 1
                map_voices += 1
                total_limbs += len(assessment.get("has", []))
                print(f"  {art}: EMBODIED")
                print(f"    truth: {assessment['truth'][:80]}")
            elif assessment["state"] == "reaching":
                reaching += 1
                voices += 1
                map_voices += 1
                mc = len(assessment.get("missing", []))
                total_phantom += mc
                total_limbs += len(assessment.get("has", []))
                map_reaching_count += mc
                print(f"  {art}: REACHING ({mc} phantom)")
                print(f"    truth: {assessment['truth'][:80]}")
                print(f"    wants: {assessment['desire'][:80]}")
                prescriptions.append((art, title, assessment["prescription"]))
            else:
                voices += 1
                map_voices += 1
                print(f"  {art}: DORMANT")

        if map_silent > 0:
            print(f"  ({map_silent} voiceless)")
        print()

    # Summary
    print(f"{'=' * 70}")
    print(f"DIAGNOSIS: {seq_name}")
    print(f"{'=' * 70}")
    print(f"  Artifacts: {total_arts}")
    print(f"  Voices: {voices} ({voices * 100 // max(total_arts, 1)}%)")
    print(f"  Silent: {silent}")
    print(f"  Embodied (full body): {embodied}")
    print(f"  Reaching (phantom limbs): {reaching} ({total_phantom} total phantom limbs)")
    print()

    # Health metaphor
    voice_ratio = voices / max(total_arts, 1)
    embody_ratio = embodied / max(voices, 1)

    if voice_ratio < 0.3:
        print(f"  Health: DORMANT GARDEN — most artifacts have no voice.")
        print(f"  The sequence truth '{seq_truth[:60]}...' echoes off empty walls.")
    elif voice_ratio < 0.7:
        print(f"  Health: SCATTERED CHORUS — some voices, many silences.")
        print(f"  The truth has carriers but not enough to fill the space.")
    elif embody_ratio < 0.2:
        print(f"  Health: REACHING FOREST — many voices, few bodies.")
        print(f"  The algorithms know what they want but can't touch anything.")
    elif embody_ratio > 0.5:
        print(f"  Health: LIVING GARDEN — voices speaking, bodies interacting.")
        print(f"  The truth is finding its physical form.")
    else:
        print(f"  Health: GROWING — voices present, bodies forming.")

    # Top prescriptions
    if prescriptions:
        print(f"\n  GROWTH DIRECTIONS (top {min(5, len(prescriptions))}):\n")
        for art, ctx, rx in prescriptions[:5]:
            print(f"  [{ctx}] {art}:")
            # Wrap prescription text
            words = rx.split()
            line = "    "
            for w in words:
                if len(line) + len(w) > 78:
                    print(line)
                    line = "    "
                line += w + " "
            if line.strip():
                print(line)
            print()


def diagnosis_all():
    """Project-wide health report."""
    print("\nPROJECT-WIDE GARDEN HEALTH")
    print("=" * 70)

    totals = {"total": 0, "voiced": 0, "embodied": 0, "reaching": 0, "phantom": 0}
    seq_health = []

    for seq_file in sorted(SEQUENCES_DIR.glob("*.json")):
        if seq_file.stem in SKIP_SEQS:
            continue
        d = json.load(open(seq_file, encoding="utf-8"))
        for name, info in d.get("sequences", {}).items():
            maps_data = get_sequence_artifacts(name)
            arts_total = 0
            arts_voiced = 0
            arts_embodied = 0
            arts_reaching = 0
            phantom = 0

            for _, _, arts in maps_data:
                for art in arts:
                    arts_total += 1
                    gd = find_gd(art)
                    if not gd:
                        continue
                    ident = read_identity(gd)
                    if not ident:
                        continue
                    arts_voiced += 1
                    needs = ident.get("needs", "")
                    mc = needs.count("[missing")
                    hc = needs.count("[has]")
                    if mc == 0 and hc > 0:
                        arts_embodied += 1
                    elif mc > 0:
                        arts_reaching += 1
                        phantom += mc

            if arts_total == 0:
                continue

            totals["total"] += arts_total
            totals["voiced"] += arts_voiced
            totals["embodied"] += arts_embodied
            totals["reaching"] += arts_reaching
            totals["phantom"] += phantom

            voice_pct = arts_voiced * 100 // arts_total
            state = "..." if arts_total < 3 else (
                "DORMANT" if voice_pct < 30 else
                "SCATTERED" if voice_pct < 70 else
                "REACHING" if arts_embodied < arts_voiced * 0.2 else
                "GROWING" if arts_embodied < arts_voiced * 0.5 else
                "LIVING"
            )
            seq_health.append((name, arts_total, arts_voiced, arts_embodied, arts_reaching, phantom, state))

    # Sort by health (DORMANT first, LIVING last)
    order = {"DORMANT": 0, "SCATTERED": 1, "...": 2, "REACHING": 3, "GROWING": 4, "LIVING": 5}
    seq_health.sort(key=lambda x: (order.get(x[6], 2), -x[1]))

    print(f"\n{'Sequence':<25} {'Arts':>4} {'Voice':>5} {'Body':>4} {'Reach':>5} {'Phantom':>7}  State")
    print("-" * 70)
    for name, total, voiced, embodied, reaching, phantom, state in seq_health:
        print(f"{name:<25} {total:>4} {voiced:>5} {embodied:>4} {reaching:>5} {phantom:>7}  {state}")

    print("-" * 70)
    t = totals
    print(f"{'TOTAL':<25} {t['total']:>4} {t['voiced']:>5} {t['embodied']:>4} {t['reaching']:>5} {t['phantom']:>7}")
    print()
    print(f"Voice coverage: {t['voiced'] * 100 // max(t['total'], 1)}%")
    print(f"Embodiment rate: {t['embodied'] * 100 // max(t['voiced'], 1)}% of voiced artifacts have full bodies")
    print(f"Phantom limbs: {t['phantom']} total across all reaching artifacts")
    print(f"Growth direction: {t['phantom']} VR controls needed to embody the reaching ones")


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    if len(sys.argv) < 2:
        print("Usage:")
        print("  python garden_listener.py <sequence>      Listen to a sequence")
        print("  python garden_listener.py ALL              Listen to everything")
        print("  python garden_listener.py --diagnosis      Project-wide health")
        print("  python garden_listener.py --reaching       All phantom limbs")
        print("  python garden_listener.py --silent         All voiceless artifacts")
        sys.exit(0)

    cmd = sys.argv[1]

    if cmd == "--diagnosis":
        diagnosis_all()
    elif cmd == "--reaching":
        # Find all reaching artifacts across all sequences
        print("\nALL REACHING ARTIFACTS (phantom limbs):\n")
        for seq_file in sorted(SEQUENCES_DIR.glob("*.json")):
            if seq_file.stem in SKIP_SEQS:
                continue
            d = json.load(open(seq_file, encoding="utf-8"))
            for name, info in d.get("sequences", {}).items():
                for _, title, arts in get_sequence_artifacts(name):
                    for art in arts:
                        gd = find_gd(art)
                        if not gd:
                            continue
                        ident = read_identity(gd)
                        if not ident:
                            continue
                        needs = ident.get("needs", "")
                        missing = re.findall(r"([^,.\[\]]+?)\[missing[^\]]*\]", needs)
                        if missing:
                            print(f"  {art} ({name}/{title}):")
                            for m in missing:
                                print(f"    -> {m.strip()}")
    elif cmd == "--silent":
        print("\nALL VOICELESS ARTIFACTS:\n")
        for seq_file in sorted(SEQUENCES_DIR.glob("*.json")):
            if seq_file.stem in SKIP_SEQS:
                continue
            d = json.load(open(seq_file, encoding="utf-8"))
            for name, info in d.get("sequences", {}).items():
                for _, title, arts in get_sequence_artifacts(name):
                    for art in arts:
                        gd = find_gd(art)
                        if not gd:
                            print(f"  {art} ({name}/{title}) -- no .gd file")
                            continue
                        ident = read_identity(gd)
                        if not ident:
                            print(f"  {art} ({name}/{title}) -- no @identity")
    elif cmd == "ALL":
        for seq_file in sorted(SEQUENCES_DIR.glob("*.json")):
            if seq_file.stem in SKIP_SEQS:
                continue
            d = json.load(open(seq_file, encoding="utf-8"))
            for name in d.get("sequences", {}):
                listen_to_sequence(name)
    else:
        listen_to_sequence(cmd)


if __name__ == "__main__":
    main()
