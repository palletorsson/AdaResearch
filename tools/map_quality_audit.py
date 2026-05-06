#!/usr/bin/env python3
"""Audit every map in commons/maps and rank by need-of-work.

For each map we collect signals that, combined, indicate whether the
map needs authoring effort. The ranking is *advisory* — the goal is to
tell the author "look at these next" rather than to score authorial
intent (which the audit can't see).

Outputs:
    doc/reports/map_quality.md    — ranked list, grouped by sequence
    doc/reports/map_quality.json  — machine-readable per-map record

Run:
    python tools/map_quality_audit.py
"""
from __future__ import annotations

import json
from collections import deque
from pathlib import Path
from typing import Optional

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"
SPINE_PATH = REPO / "commons" / "maps" / "curriculum_spine.json"
REPORT_DIR = REPO / "doc" / "reports"

# Maps under this many walkable cells are flagged as "tiny".
TINY_THRESHOLD = 25
# Maps with this many or fewer artifacts are flagged as "sparse".
SPARSE_THRESHOLD = 1


# ── Helpers ────────────────────────────────────────────────────────────

def read_json(path: Path) -> dict | None:
    if not path.exists(): return None
    try:
        return json.loads(path.read_text(encoding="utf-8", errors="replace"))
    except Exception:
        return None


def cell_height(cell) -> int:
    if isinstance(cell, int): return cell
    if isinstance(cell, str):
        try: return int(cell)
        except Exception: return 0
    return 0


def is_default_dressing_room(room: dict) -> bool:
    """Matches the canonical 3×3 plinth default we generated for fall-back rooms."""
    fp = room.get("footprint", [])
    try:
        if [int(x) for x in fp[:3]] != [1, 1, 1]: return False
    except Exception:
        return False
    footing = room.get("footing", {})
    if footing.get("anchor", []) != [1, 1] and footing.get("anchor", []) != [1.0, 1.0]:
        return False
    tiles = footing.get("tiles", [])
    if len(tiles) != 3: return False
    try:
        flat = [int(v) for row in tiles for v in row]
    except Exception:
        return False
    if flat != [1, 1, 1, 1, 3, 1, 1, 1, 1]: return False
    extras = room.get("extras", [])
    if isinstance(extras, list) and extras: return False
    return True


def load_dressing_room(name: str) -> dict | None:
    return read_json(ROOMS_DIR / f"{name}.json")


def reachable_count_from_spawn(structure, utilities) -> tuple[int, int, Optional[tuple[int, int]]]:
    """Return (reachable, total_walkable, spawn_cell). Walkable = h >= 1.
    Step rule: |height_diff| <= 1 between adjacent walkable cells."""
    rows = len(structure)
    cols = max((len(r) for r in structure), default=0)
    walkable: dict[tuple[int, int], int] = {}
    for r in range(rows):
        row = structure[r]
        for c in range(min(cols, len(row))):
            h = cell_height(row[c])
            if h >= 1:
                walkable[(r, c)] = h
    total = len(walkable)

    # Find spawn cell. The project uses both 's' and 'sp' (and rarely
    # 'spawn') across its 791 maps — accept any of them.
    spawn = None
    for r in range(min(rows, len(utilities))):
        u_row = utilities[r]
        for c in range(min(cols, len(u_row))):
            if isinstance(u_row[c], str) and u_row[c].strip() in ("s", "sp", "spawn"):
                spawn = (r, c)
                break
        if spawn: break

    if spawn is None or spawn not in walkable:
        return 0, total, spawn

    seen = {spawn}
    q = deque([spawn])
    while q:
        cur = q.popleft()
        ch = walkable[cur]
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (cur[0] + dr, cur[1] + dc)
            if n in seen or n not in walkable: continue
            if abs(walkable[n] - ch) > 1: continue
            seen.add(n)
            q.append(n)
    return len(seen), total, spawn


def collect_artifact_lookups(interactables) -> list[str]:
    seen: list[str] = []
    seen_set: set[str] = set()
    for row in interactables:
        if not isinstance(row, list): continue
        for cell in row:
            if not isinstance(cell, str): continue
            tok = cell.strip()
            if not tok or tok == " ": continue
            lookup = tok.split(":", 1)[0]
            if lookup and lookup not in seen_set:
                seen_set.add(lookup)
                seen.append(lookup)
    return seen


# ── Sequence index ─────────────────────────────────────────────────────

def load_map_to_sequence_index() -> dict[str, str]:
    """Returns {map_name: sequence_id} from sequence files."""
    idx: dict[str, str] = {}
    if SEQUENCES_DIR.exists():
        for p in sorted(SEQUENCES_DIR.glob("*.json")):
            data = read_json(p)
            if not data: continue
            seqs = data.get("sequences", {})
            if not isinstance(seqs, dict): continue
            for seq_id, seq in seqs.items():
                for m in seq.get("maps", []) or []:
                    if isinstance(m, str) and m not in idx:
                        idx[m] = seq_id
    return idx


def load_spine_targets() -> dict[str, list[str]]:
    """Returns {sequence_id: [expected_map_names]} from the curriculum spine."""
    data = read_json(SPINE_PATH)
    if not data: return {}
    out: dict[str, list[str]] = {}
    for seq in (data.get("sequences", []) or []):
        if not isinstance(seq, dict): continue
        sid = seq.get("id") or seq.get("sequence_id")
        maps = seq.get("maps", []) or []
        if sid and isinstance(maps, list):
            out[str(sid)] = [str(m) for m in maps if isinstance(m, str)]
    return out


# ── Per-map audit ──────────────────────────────────────────────────────

def audit_map(map_dir: Path, map_to_seq: dict[str, str]) -> dict | None:
    name = map_dir.name
    md_path = map_dir / "map_data.json"
    md = read_json(md_path)
    if not md: return None
    layers = md.get("layers", {})
    structure = layers.get("structure", []) if isinstance(layers, dict) else []
    utilities = layers.get("utilities", []) if isinstance(layers, dict) else []
    interact = layers.get("interactables", []) if isinstance(layers, dict) else []

    reachable, walkable, spawn = reachable_count_from_spawn(structure, utilities)
    reach_ratio = (reachable / walkable) if walkable else 0.0

    artifacts = collect_artifact_lookups(interact)
    n_artifacts = len(artifacts)

    # Dressing-room default ratio.
    default_count = 0
    custom_count = 0
    missing_room = 0
    for lookup in artifacts:
        room = load_dressing_room(lookup)
        if room is None:
            missing_room += 1
        elif is_default_dressing_room(room):
            default_count += 1
        else:
            custom_count += 1
    default_ratio = (default_count / n_artifacts) if n_artifacts else 1.0

    has_blurb = (map_dir / "blurb.md").exists()
    has_intent = (map_dir / "intent.md").exists()
    has_technical = (map_dir / "technical.md").exists()

    sequence = map_to_seq.get(name, "")
    composed = bool((md.get("map_info", {}) or {}).get("metadata", {}).get("composed_from_dressing_rooms"))

    # ── Score: higher = more need ────────────────────────────────────
    # The score is roughly a sum of penalties weighted to surface the
    # most actionable problems first. Tune freely.
    score = 0.0
    flags: list[str] = []

    if walkable < TINY_THRESHOLD:
        score += 4.0
        flags.append(f"tiny ({walkable} cells)")
    if n_artifacts <= SPARSE_THRESHOLD:
        score += 3.0
        flags.append(f"sparse ({n_artifacts} artifacts)")
    if walkable > 0 and reach_ratio < 0.6:
        score += 5.0
        flags.append(f"broken connectivity ({reachable}/{walkable})")
    elif walkable > 0 and reach_ratio < 0.9:
        score += 1.5
        flags.append(f"partial connectivity ({reachable}/{walkable})")
    if spawn is None:
        score += 4.0
        flags.append("no spawn")
    # Default-rooms signal indicates "artifacts not yet hand-tuned" — a
    # real but lower-priority kind of work. We just generated 1,757
    # default rooms in one sweep, so this signal would otherwise swamp
    # the actually-broken-map signals. Keep it small.
    if n_artifacts > 0 and default_ratio >= 0.9:
        score += 0.8
        flags.append(f"all-default rooms ({default_count}/{n_artifacts})")
    elif n_artifacts > 0 and default_ratio >= 0.5:
        score += 0.3
        flags.append(f"mostly-default rooms ({default_count}/{n_artifacts})")
    if missing_room:
        score += 0.5 * missing_room
        flags.append(f"{missing_room} artifacts missing dressing room")
    if not has_blurb and not has_intent:
        score += 1.5
        flags.append("no blurb or intent text")
    elif not has_intent:
        score += 0.5
        flags.append("no intent")
    if composed:
        # Auto-composed drafts always need review. Don't penalize harshly.
        score += 0.5
        flags.append("auto-composed draft")

    return {
        "name": name,
        "sequence": sequence,
        "score": round(score, 2),
        "flags": flags,
        "walkable_cells": walkable,
        "reachable_cells": reachable,
        "reach_ratio": round(reach_ratio, 3),
        "n_artifacts": n_artifacts,
        "n_default_rooms": default_count,
        "n_custom_rooms": custom_count,
        "n_missing_rooms": missing_room,
        "has_blurb": has_blurb,
        "has_intent": has_intent,
        "has_technical": has_technical,
        "composed": composed,
        "spawn": list(spawn) if spawn else None,
    }


# ── Main ───────────────────────────────────────────────────────────────

def main() -> int:
    map_to_seq = load_map_to_sequence_index()
    spine = load_spine_targets()
    print(f"sequence index: {len(map_to_seq)} mapped maps; spine has {len(spine)} sequences")

    # Audit every map directory on disk.
    audits: list[dict] = []
    for map_dir in sorted(MAPS_DIR.iterdir()):
        if not map_dir.is_dir(): continue
        if map_dir.name in {"sequences"}: continue
        rec = audit_map(map_dir, map_to_seq)
        if rec is not None:
            audits.append(rec)
    print(f"audited {len(audits)} maps")

    # Spine gap: maps that the curriculum says should exist but don't.
    on_disk = {a["name"] for a in audits}
    missing: list[tuple[str, str]] = []
    for seq_id, expected in spine.items():
        for name in expected:
            if name not in on_disk:
                missing.append((seq_id, name))
    print(f"missing maps (in spine but not on disk): {len(missing)}")

    audits.sort(key=lambda a: (-a["score"], a["sequence"], a["name"]))

    # Group by sequence for the report.
    by_seq: dict[str, list[dict]] = {}
    for a in audits:
        by_seq.setdefault(a["sequence"] or "(none)", []).append(a)

    # ── Markdown report ─────────────────────────────────────────────
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    md_path = REPORT_DIR / "map_quality.md"
    md_lines: list[str] = []
    md_lines.append("# Map quality audit\n")
    md_lines.append(f"> Auto-generated by `tools/map_quality_audit.py`. {len(audits)} maps audited; {len(missing)} missing from spine.\n")
    md_lines.append("> Score is a *need-of-work* heuristic — higher = more attention required.\n\n")

    # Top-30 across all sequences.
    md_lines.append("## Top 30 highest-need maps (across all sequences)\n\n")
    md_lines.append("| Score | Sequence | Map | Flags |\n|---:|---|---|---|\n")
    for a in audits[:30]:
        flags = "; ".join(a["flags"]) if a["flags"] else "—"
        md_lines.append(f"| {a['score']} | `{a['sequence'] or '(none)'}` | `{a['name']}` | {flags} |\n")

    # Missing maps.
    if missing:
        md_lines.append("\n## Missing from disk (spine references but no folder)\n\n")
        last_seq = None
        for seq_id, name in sorted(missing):
            if seq_id != last_seq:
                md_lines.append(f"\n**{seq_id}**\n\n")
                last_seq = seq_id
            md_lines.append(f"- `{name}`\n")

    # Per-sequence breakdown — only show maps with score > 0.
    md_lines.append("\n## Per-sequence ranking\n\n")
    for seq_id in sorted(by_seq.keys()):
        items = [a for a in by_seq[seq_id] if a["score"] > 0]
        if not items: continue
        md_lines.append(f"\n### `{seq_id}`  ({len(items)} of {len(by_seq[seq_id])} flagged)\n\n")
        md_lines.append("| Score | Map | Cells | Artifacts | Default rooms | Flags |\n|---:|---|---:|---:|---:|---|\n")
        for a in items[:20]:
            flags = "; ".join(a["flags"]) if a["flags"] else "—"
            md_lines.append(
                f"| {a['score']} | `{a['name']}` | {a['walkable_cells']} | {a['n_artifacts']} | "
                f"{a['n_default_rooms']}/{a['n_artifacts']} | {flags} |\n"
            )
        if len(items) > 20:
            md_lines.append(f"_…and {len(items) - 20} more in this sequence_\n")

    md_path.write_text("".join(md_lines), encoding="utf-8")
    print(f"wrote {md_path.relative_to(REPO)}")

    # ── JSON report ─────────────────────────────────────────────────
    json_path = REPORT_DIR / "map_quality.json"
    json_path.write_text(json.dumps({
        "audits": audits,
        "missing": [{"sequence": s, "map": m} for s, m in missing],
    }, indent=2), encoding="utf-8")
    print(f"wrote {json_path.relative_to(REPO)}")

    # ── Console summary ─────────────────────────────────────────────
    print("\n=== summary ===")
    print(f"  total maps:        {len(audits)}")
    needs_work = sum(1 for a in audits if a["score"] >= 3)
    print(f"  high-need (>=3):   {needs_work}")
    needs_attn = sum(1 for a in audits if 1 <= a["score"] < 3)
    print(f"  mid-need (1-3):    {needs_attn}")
    fine = sum(1 for a in audits if a["score"] < 1)
    print(f"  fine (<1):         {fine}")
    print(f"  missing on disk:   {len(missing)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
