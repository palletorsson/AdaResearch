#!/usr/bin/env python3
"""
build_map_dna.py — promote every in-map artifact into the DNA gallery system,
one gallery per map.

Palle (2026-07-20): "promote all artifacts that are in the map to dna so we
can see one dna gallery for each map. From there to run auto research."

For each map, every interactable in the cast becomes a DNA entry in the
/dna manifest convention ({id, notes, config, image, ...}) so the existing
gallery machinery (viewer pages, star evals via /api/gallery-evals, promotion
to dna_promoted.json) applies map-by-map. The entry's `config` gathers the
artifact's CURRENT genome — registry spatial fields, dressing-room JSON, and
the map-token params — which is exactly what auto research then varies.

Outputs (encyclopedia public/):
  map-dna/<Map>/manifest.json   one gallery per map
  map-dna/index.json            per-map coverage: cast size, captures,
                                rooms, voices, promoted count — the research
                                agenda, sorted by weakest coverage first.

Usage:
  python tools/build_map_dna.py            # all maps
  python tools/build_map_dna.py --map=Bricolage_Inventory
"""
from __future__ import annotations
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
SEQUENCES = REPO / "commons" / "maps" / "sequences"
REGISTRY = REPO / "commons" / "artifacts" / "registry"
ROOMS = REPO / "commons" / "artifacts" / "dressing_rooms"
ENC = REPO.parent / "ada_encyclopedia" / "public"
CAPTURES = ENC / "artifact-gallery" / "captures"
OUT = ENC / "map-dna"

# tokens that are grid chrome, not artifacts. mc:/criticalinfo: are runtime
# prefixes handled by GridInteractablesComponent; test_scene_* are dead
# placeholders in throwaway test maps.
SKIP = {"", ",", "cluster", "tt", "sub", "tc", "e", "an", "3t",
        "sp", "t", "s", "r", "m", "ds", "n", "0",
        "mc", "criticalinfo", "test_scene_1", "test_scene_2"}


def load_voice_index() -> set:
    """Lookup names with a critical voice ANYWHERE (@identity in .gd or
    registry qfep_connection) — the project's real definition, via the same
    index eye_shot uses. Falls back to empty (registry-only) if unavailable."""
    try:
        sys.path.insert(0, str(REPO / "tools"))
        from qfep_signal import build_critical_index  # type: ignore
        return {k for k, v in build_critical_index().items()
                if str(v.get("crit_text", "") or "").strip()}
    except Exception:
        return set()


def load_sequence_index() -> tuple:
    """(map name -> [sequence ids], map name -> spine rank). Rank orders the
    spine walk: sequence position in curriculum_spine.json × 1000 + the map's
    slot in its sequence's `maps` list. Non-spine maps get no rank."""
    out: dict = {}
    slot: dict = {}   # map -> (seq_id, index in maps list)
    for f in SEQUENCES.glob("*.json"):
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        seqs = data.get("sequences", {})
        if not isinstance(seqs, dict):  # sequence_index.json is a list summary
            continue
        for seq_id, seq in seqs.items():
            if not isinstance(seq, dict):
                continue
            for i, m in enumerate(seq.get("maps", [])):
                if isinstance(m, str):
                    out.setdefault(m, []).append(seq_id)
                    slot.setdefault(m, (seq_id, i))
    spine_order: dict = {}
    try:
        spine = json.loads((MAPS / "curriculum_spine.json").read_text(encoding="utf-8"))
        for s in spine.get("spine", {}).get("sequences", []):
            if isinstance(s, dict) and s.get("name"):
                spine_order[str(s["name"])] = int(s.get("order", len(spine_order) + 1))
    except Exception:
        pass
    rank: dict = {}
    for m, (seq_id, i) in slot.items():
        if seq_id in spine_order:
            rank[m] = spine_order[seq_id] * 1000 + i
    return out, rank


def load_registry() -> dict:
    reg: dict = {}
    for f in REGISTRY.glob("*.json"):
        if f.name == "substrate_vectors.json":
            continue
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data)
        if not isinstance(arts, dict):
            continue
        for k, v in arts.items():
            if isinstance(v, dict) and k not in reg:
                reg[k] = {**v, "_registry": f.name}
    return reg


def cast_of(map_dir: Path) -> list[dict]:
    """[{lookup, token_params}] — one entry per distinct lookup, keeping the
    first full token so the map's own #params travel into the genome."""
    p = map_dir / "map_data.json"
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return []
    seen: dict[str, str] = {}
    for row in d.get("layers", {}).get("interactables", []):
        if not isinstance(row, list):
            continue
        for cell in row:
            if not isinstance(cell, str) or not cell.strip():
                continue
            base = cell.split(":")[0].split("#")[0].strip()
            if not base or base in SKIP:
                continue
            seen.setdefault(base, cell.strip())
    return [{"lookup": k, "token": v} for k, v in sorted(seen.items())]


def genome_of(lookup: str, token: str, reg: dict) -> dict:
    """The artifact's current DNA: the config auto research will vary."""
    e = reg.get(lookup, {})
    g: dict = {"token": token}
    for k in ("scene", "category", "artifact_type", "complexity", "size_group",
              "footprint", "footprint_measured", "spatial_needs", "scale",
              "delegate_to", "delegate_params", "auto_ground"):
        if k in e:
            g[k] = e[k]
    room = ROOMS / f"{lookup}.json"
    if room.exists():
        try:
            g["dressing_room"] = json.loads(room.read_text(encoding="utf-8"))
        except Exception:
            pass
    return g


def build_map(map_dir: Path, reg: dict, voiced_idx: set) -> dict | None:
    cast = cast_of(map_dir)
    if not cast:
        return None
    name = map_dir.name
    entries = []
    types: set = set()
    n_img = n_room = n_voice = n_promoted = 0
    for c in cast:
        lk = c["lookup"]
        e = reg.get(lk, {})
        a_type = str(e.get("artifact_type", "") or "")
        if a_type:
            types.add(a_type)
        img = ""
        cap = CAPTURES / lk / "front.png"
        if cap.exists():
            img = f"/artifact-gallery/captures/{lk}/front.png"
            n_img += 1
        has_room = (ROOMS / f"{lk}.json").exists()
        if has_room:
            n_room += 1
        voice = str(e.get("qfep_connection", "") or "")
        is_voiced = bool(voice) or lk in voiced_idx
        if is_voiced:
            n_voice += 1
        promoted = str(e.get("category", "")) == "dna_promoted" or lk.startswith("dna_")
        if promoted:
            n_promoted += 1
        entries.append({
            "id": lk,
            "notes": str(e.get("description", "") or ""),
            "interpretation": voice,
            "image": img,
            "config": genome_of(lk, c["token"], reg),
            "flags": {
                "registered": lk in reg,
                "captured": bool(img),
                "dressing_room": has_room,
                "voiced": is_voiced,
                "promoted": promoted,
            },
        })
    return {
        "version": 1,
        "map": name,
        "description": f"Every artifact in {name}, promoted to a DNA entry — "
                       "current genome shown; auto research varies it from here.",
        "entries": entries,
        "types": sorted(types),
        "coverage": {
            "cast": len(entries),
            "captured": n_img,
            "rooms": n_room,
            "voiced": n_voice,
            "promoted": n_promoted,
        },
    }


def main() -> int:
    want = None
    for a in sys.argv[1:]:
        if a.startswith("--map="):
            want = a.split("=", 1)[1]
    reg = load_registry()
    voiced_idx = load_voice_index()
    seq_index, spine_rank = load_sequence_index()
    OUT.mkdir(parents=True, exist_ok=True)
    index: list[dict] = []
    n = 0
    for map_dir in sorted(MAPS.iterdir()):
        if not (map_dir / "map_data.json").exists():
            continue
        if want and map_dir.name != want:
            continue
        m = build_map(map_dir, reg, voiced_idx)
        if m is None:
            continue
        d = OUT / map_dir.name
        d.mkdir(exist_ok=True)
        (d / "manifest.json").write_text(
            json.dumps(m, indent=1, ensure_ascii=False) + "\n",
            encoding="utf-8", newline="\n")
        cov = m["coverage"]
        row = {"map": map_dir.name, **cov,
               "seqs": seq_index.get(map_dir.name, []),
               "types": m["types"],
               "mtime": int((map_dir / "map_data.json").stat().st_mtime),
               "gap": cov["cast"] * 3 - cov["captured"] - cov["rooms"] - cov["voiced"]}
        if map_dir.name in spine_rank:
            row["spine"] = spine_rank[map_dir.name]
        index.append(row)
        n += 1
    if not want:
        index.sort(key=lambda r: -r["gap"])  # weakest coverage first = agenda
        (OUT / "index.json").write_text(
            json.dumps({"version": 1, "maps": index}, indent=1, ensure_ascii=False) + "\n",
            encoding="utf-8", newline="\n")
    elif (OUT / "index.json").exists() and want:
        # refresh the one row in the existing index
        try:
            idx = json.loads((OUT / "index.json").read_text(encoding="utf-8"))
            rows = [r for r in idx.get("maps", []) if r.get("map") != want]
            row = next((r for r in index if r["map"] == want), None)
            if row:
                rows.append(row)
                rows.sort(key=lambda r: -r["gap"])
                idx["maps"] = rows
                (OUT / "index.json").write_text(
                    json.dumps(idx, indent=1, ensure_ascii=False) + "\n",
                    encoding="utf-8", newline="\n")
        except Exception:
            pass
    print(f"map-dna: {n} manifest(s) -> {OUT}")
    if not want and index:
        worst = index[:5]
        print("weakest coverage (the research agenda):")
        for r in worst:
            print(f"  {r['map']:36s} cast={r['cast']:3d} captured={r['captured']:3d} "
                  f"rooms={r['rooms']:3d} voiced={r['voiced']:3d}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
