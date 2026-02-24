#!/usr/bin/env python3
"""Map Pathfinder CLI — validates reachability and finds paths in AdaResearch maps.

Enforces the map construction rules from doc/MAP_AGENT_ONBOARDING.md §7:
  Rule 1: Spawn must be plain 's' — always start at 1,1,1 (auto-fixable)
  Rule 2: Teleport needs +1 row in z with floor cubes behind it
  Rule 3: Teleport must be reachable from spawn
  Rule 4: All interactable artifacts must be reachable from spawn
  Rule 5: Teleport must stand on y=0 (void) in structure
  Rule 6: Only one teleport per map (warning if >1)

  Spawn: always found from s utility, BFS starts there regardless of structure height.

Movement rules:
  - Walk between 4-connected cells at the SAME height (height > 0)
  - Drop 1 level (e.g. h2->h1): allowed
  - Drop 2+ levels (e.g. h3->h1): requires tc transport cube
  - Climbing up: requires wp ramp
  - wp (walkpath/ramp) allows traversal between adjacent cells of different heights
  - tc (transport cube) bridges gaps along an axis; standable even on void
  - br (bridge) transparent walkable path over void: br:z:3, br:x:2, br:-z:1
  - Teleport cells are walkable destinations even on void
  - Height 0 = void (unwalkable without tc/br)

Examples:
  python tools/map_pathfinder.py check Crisis_Synthesis
  python tools/map_pathfinder.py check --all
  python tools/map_pathfinder.py path Crisis_Synthesis --to qfep_formula_3d
  python tools/map_pathfinder.py path Crisis_Synthesis --to teleport
  python tools/map_pathfinder.py show Crisis_Synthesis
  python tools/map_pathfinder.py show Crisis_Synthesis --path-to qfep_formula_3d
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import deque
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"
SEQUENCE_DIR = MAPS_DIR / "sequences"

# Oversight task scheduler integration
OVERSIGHT_URL = os.environ.get("OVERSIGHT_URL", "http://localhost:3000")
OVERSIGHT_PROJECT = os.environ.get("OVERSIGHT_PROJECT", "ada-research")


# ---------------------------------------------------------------------------
# Map loading
# ---------------------------------------------------------------------------

def _strip_trailing_commas(text: str) -> str:
    """Remove trailing commas before ] or } to tolerate Godot-style JSON."""
    return re.sub(r",\s*([}\]])", r"\1", text)


def load_map(path: Path) -> dict:
    with open(path, "r", encoding="utf-8-sig") as f:
        text = f.read()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return json.loads(_strip_trailing_commas(text))


def resolve_map_path(name: str) -> Optional[Path]:
    """Resolve a map name to its map_data.json path."""
    p = MAPS_DIR / name / "map_data.json"
    if p.is_file():
        return p
    # Try case-insensitive search
    for d in MAPS_DIR.iterdir():
        if d.is_dir() and d.name.lower() == name.lower():
            candidate = d / "map_data.json"
            if candidate.is_file():
                return candidate
    return None


def all_curriculum_maps() -> list[str]:
    """Return sorted list of all map names referenced in sequence files."""
    maps = set()
    if not SEQUENCE_DIR.is_dir():
        return []
    for sf in SEQUENCE_DIR.iterdir():
        if sf.suffix != ".json":
            continue
        try:
            data = json.loads(sf.read_text(encoding="utf-8-sig"))
        except (json.JSONDecodeError, OSError):
            continue
        seqs = data.get("sequences", data)
        if isinstance(seqs, dict):
            for seq in seqs.values():
                if isinstance(seq, dict):
                    for m in seq.get("maps", []):
                        maps.add(m)
    return sorted(maps)


def load_sequence_map_groups() -> dict[str, dict]:
    """Return {seq_id: {"title": str, "maps": [str], "file": str}} for all sequences."""
    groups: dict[str, dict] = {}
    if not SEQUENCE_DIR.is_dir():
        return groups
    for sf in sorted(SEQUENCE_DIR.iterdir()):
        if sf.suffix != ".json":
            continue
        try:
            data = json.loads(sf.read_text(encoding="utf-8-sig"))
        except (json.JSONDecodeError, OSError):
            continue
        seqs = data.get("sequences", data)
        if isinstance(seqs, dict):
            for seq_id, seq in seqs.items():
                if isinstance(seq, dict) and "maps" in seq:
                    groups[seq_id] = {
                        "title": seq.get("name", seq_id),
                        "maps": seq["maps"],
                        "file": sf.name,
                    }
    return groups


# ---------------------------------------------------------------------------
# Graph building
# ---------------------------------------------------------------------------

def parse_height(cell) -> int:
    try:
        h = int(str(cell).strip())
        return h if h > 0 else 0
    except (ValueError, TypeError):
        return 0


def find_spawn(utils: list[list]) -> tuple[int, int]:
    for r, row in enumerate(utils):
        for c, cell in enumerate(row):
            val = str(cell).strip()
            if val == "s" or (val.startswith("s:") and not val.startswith("su")):
                return (r, c)
    return (0, 0)


def find_spawn_raw(utils: list[list]) -> str:
    """Return the raw spawn utility string (e.g. 's', 's:1:1:1', 's:1:1:4')."""
    for row in utils:
        for cell in row:
            val = str(cell).strip()
            if val == "s" or (val.startswith("s:") and not val.startswith("su")):
                return val
    return ""


def find_teleports(utils: list[list]) -> list[tuple[int, int]]:
    teleports = []
    for r, row in enumerate(utils):
        for c, cell in enumerate(row):
            val = str(cell).strip()
            if val == "t" or val.startswith("t:") or val.startswith("t3:"):
                teleports.append((r, c))
    return teleports


def find_interactables(ints: list[list], rows: int, cols: int) -> list[dict]:
    """Return list of {name, row, col} for all placed artifacts."""
    arts = []
    for r in range(min(rows, len(ints))):
        for c in range(min(cols, len(ints[r]))):
            cell = str(ints[r][c]).strip()
            if cell and cell != " ":
                name = cell.split(":")[0].split("#")[0]
                arts.append({"name": name, "row": r, "col": c})
    return arts


class MapGraph:
    """Walkability graph for a single map."""

    def __init__(self, data: dict):
        self.data = data
        self.name = data.get("map_info", {}).get(
            "lookup_name", "unknown"
        )
        layers = data.get("layers", {})
        self.struct = layers.get("structure", [])
        self.utils = layers.get("utilities", [])
        self.ints = layers.get("interactables", [])

        self.rows = len(self.struct)
        self.cols = max((len(r) for r in self.struct), default=0)

        # Build height map
        self.hmap: dict[tuple[int, int], int] = {}
        for r in range(self.rows):
            for c in range(min(self.cols, len(self.struct[r]))):
                self.hmap[(r, c)] = parse_height(self.struct[r][c])

        # Parse utilities
        self.util_map: dict[tuple[int, int], str] = {}
        for r in range(min(self.rows, len(self.utils))):
            for c in range(min(self.cols, len(self.utils[r]))):
                cell = str(self.utils[r][c]).strip()
                if cell and cell != " ":
                    self.util_map[(r, c)] = cell

        # wp cells
        self.wp_cells: set[tuple[int, int]] = {
            pos for pos, cell in self.util_map.items() if cell.startswith("wp")
        }

        # tc bridges and positions
        self.tc_positions: set[tuple[int, int]] = set()
        self.tc_adj: dict[tuple[int, int], set[tuple[int, int]]] = {}
        self._parse_tc()

        # br (transparent bridge) cells
        self.br_cells: set[tuple[int, int]] = set()
        self._parse_br()

        # Walkable set
        self.walkable: set[tuple[int, int]] = set()
        for pos, h in self.hmap.items():
            if h > 0:
                self.walkable.add(pos)
        for pos in self.tc_positions:
            self.walkable.add(pos)
        for pos in self.br_cells:
            self.walkable.add(pos)

        # Spawn
        self.spawn = find_spawn(self.utils)
        self.spawn_raw = find_spawn_raw(self.utils)
        if self.spawn not in self.walkable:
            self.walkable.add(self.spawn)

        # Targets
        self.teleports = find_teleports(self.utils)
        self.artifacts = find_interactables(self.ints, self.rows, self.cols)
        self._teleport_set = set(self.teleports)

        # Teleport cells are walkable destinations even on void
        for tp in self.teleports:
            if tp not in self.walkable:
                self.walkable.add(tp)

    def _parse_tc(self):
        bridges: list[tuple[tuple[int, int], tuple[int, int]]] = []
        for pos, cell in self.util_map.items():
            if not cell.startswith("tc"):
                continue
            parts = cell.split(":")
            if len(parts) < 3:
                continue
            try:
                dist = int(parts[1])
                direction = parts[2]
            except (ValueError, IndexError):
                continue
            r, c = pos
            self.tc_positions.add(pos)
            if direction == "z":
                for d in [(r + dist, c), (r - dist, c)]:
                    if 0 <= d[0] < self.rows and 0 <= d[1] < self.cols:
                        bridges.append((pos, d))
            elif direction == "x":
                for d in [(r, c + dist), (r, c - dist)]:
                    if 0 <= d[0] < self.rows and 0 <= d[1] < self.cols:
                        bridges.append((pos, d))
            elif direction == "y":
                for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    adj = (r + dr, c + dc)
                    if 0 <= adj[0] < self.rows and 0 <= adj[1] < self.cols:
                        bridges.append((pos, adj))
        for a, b in bridges:
            self.tc_adj.setdefault(a, set()).add(b)
            self.tc_adj.setdefault(b, set()).add(a)

    def _parse_br(self):
        """Parse br:AXIS:LENGTH bridge utilities.

        A bridge creates walkable cells in +AXIS direction from its placement.
        br:z:3 = bridge spanning 3 cells in +z (rows +1, +2, +3)
        br:x:2 = bridge spanning 2 cells in +x (cols +1, +2)
        br:-z:3 = bridge spanning 3 cells in -z (rows -1, -2, -3)
        br:-x:2 = bridge spanning 2 cells in -x (cols -1, -2)

        The placement cell itself is also part of the bridge.
        All bridge cells are walkable at height 1 (ground level) for
        neighbor calculations.
        """
        for pos, cell in self.util_map.items():
            if not cell.startswith("br"):
                continue
            parts = cell.split(":")
            if len(parts) < 3:
                continue
            try:
                axis = parts[1]
                length = int(parts[2])
            except (ValueError, IndexError):
                continue
            r, c = pos
            self.br_cells.add(pos)
            # Determine direction delta
            if axis == "z":
                dr, dc = 1, 0
            elif axis == "-z":
                dr, dc = -1, 0
            elif axis == "x":
                dr, dc = 0, 1
            elif axis == "-x":
                dr, dc = 0, -1
            else:
                continue
            # Add bridge cells along the direction
            for step in range(1, length + 1):
                br = (r + dr * step, c + dc * step)
                if 0 <= br[0] < self.rows and 0 <= br[1] < self.cols:
                    self.br_cells.add(br)

    def neighbors(self, pos: tuple[int, int]) -> list[tuple[int, int]]:
        """Return all positions reachable from pos in one step.

        Movement rules:
        - Same height: always walkable
        - Drop 1 level (e.g. h2->h1): allowed (player can step down)
        - Drop 2+ levels (e.g. h3->h1): requires tc transport cube
        - Climbing up (nb > cur): requires wp ramp on either cell
        """
        r, c = pos
        # Bridge cells act as height 1 for movement purposes
        cur_h = 1 if pos in self.br_cells else self.hmap.get(pos, 0)
        result = []
        # 4-connected walking
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nb = (r + dr, c + dc)
            if nb not in self.walkable:
                continue
            nb_h = self.hmap.get(nb, 0)
            # Teleport on void — always reachable from adjacent walkable cell
            if nb_h == 0 and nb in self._teleport_set:
                result.append(nb)
            # Bridge cell — walkable from any adjacent cell (floor or bridge)
            elif nb in self.br_cells:
                result.append(nb)
            elif nb_h > 0 and nb_h == cur_h:
                # Same height — always allowed
                result.append(nb)
            elif nb_h > 0 and cur_h - nb_h == 1:
                # Drop 1 level — allowed
                result.append(nb)
            elif nb_h > 0 and cur_h - nb_h >= 2:
                # Drop 2+ levels — only with wp (rare) or tc handles via bridge edges
                if pos in self.wp_cells or nb in self.wp_cells:
                    result.append(nb)
            elif nb_h > cur_h and (pos in self.wp_cells or nb in self.wp_cells):
                # Climbing up — requires wp ramp
                result.append(nb)
        # tc bridges
        if pos in self.tc_adj:
            for dest in self.tc_adj[pos]:
                if dest in self.walkable:
                    result.append(dest)
        return result

    def bfs_flood(self) -> set[tuple[int, int]]:
        """Flood fill from spawn, return all reachable positions."""
        visited = {self.spawn}
        queue = deque([self.spawn])
        while queue:
            pos = queue.popleft()
            for nb in self.neighbors(pos):
                if nb not in visited:
                    visited.add(nb)
                    queue.append(nb)
        return visited

    def bfs_path(
        self, target: tuple[int, int]
    ) -> Optional[list[tuple[int, int]]]:
        """BFS shortest path from spawn to target. Returns path list or None."""
        if self.spawn == target:
            return [self.spawn]
        parent: dict[tuple[int, int], tuple[int, int]] = {}
        visited = {self.spawn}
        queue = deque([self.spawn])
        while queue:
            pos = queue.popleft()
            for nb in self.neighbors(pos):
                if nb not in visited:
                    visited.add(nb)
                    parent[nb] = pos
                    if nb == target:
                        # Reconstruct
                        path = [nb]
                        cur = nb
                        while cur in parent:
                            cur = parent[cur]
                            path.append(cur)
                        path.reverse()
                        return path
                    queue.append(nb)
        return None

    def find_target(self, name: str) -> Optional[tuple[int, int]]:
        """Resolve a target name to a (row, col) position.

        Accepts: 'teleport'/'t', 'spawn'/'s', or an artifact lookup_name.
        """
        low = name.lower()
        if low in ("teleport", "t"):
            return self.teleports[0] if self.teleports else None
        if low in ("spawn", "s"):
            return self.spawn
        # artifact name match
        for art in self.artifacts:
            if art["name"].lower() == low:
                return (art["row"], art["col"])
        # partial match
        for art in self.artifacts:
            if low in art["name"].lower():
                return (art["row"], art["col"])
        return None


# ---------------------------------------------------------------------------
# Rule checking
# ---------------------------------------------------------------------------

def check_rules(graph: MapGraph) -> list[dict]:
    """Check all map construction rules. Returns list of issues."""
    issues = []

    # Rule 1: Spawn must be plain 's' (always start at 1,1,1)
    # Any spawn with parameters (s:1:1:4, s:1:1:1, etc.) should be just 's'.
    raw = graph.spawn_raw
    if raw and raw != "s":
        issues.append({
            "rule": 1,
            "severity": "ERROR",
            "msg": f"Spawn is '{raw}' — must be 's' (always start at 1,1,1)",
            "fix": "normalize_spawn",
        })

    # Rule 2: Teleport needs +1 row in z with floor cubes behind it
    # The row after the teleport in structure must exist and have floor (h>0)
    # so the player doesn't fall through on arrival.
    struct_depth = len(graph.struct)
    for tp in graph.teleports:
        tp_r, tp_c = tp
        next_row = tp_r + 1
        # Check structure has a row beyond teleport with floor
        if next_row >= struct_depth:
            issues.append({
                "rule": 2,
                "severity": "WARN",
                "msg": f"Teleport at ({tp_c},{tp_r}) — no structure row at z={next_row} to catch player",
            })
        else:
            # Check that there are floor cubes in the row behind teleport
            next_row_data = graph.struct[next_row] if next_row < len(graph.struct) else []
            has_floor = any(parse_height(c) > 0 for c in next_row_data)
            if not has_floor:
                issues.append({
                    "rule": 2,
                    "severity": "WARN",
                    "msg": f"Teleport at ({tp_c},{tp_r}) — row z={next_row} has no floor cubes to catch player",
                })

    # Rule 3: Teleport must be reachable
    reachable = graph.bfs_flood()
    for tp in graph.teleports:
        if tp not in reachable:
            issues.append({
                "rule": 3,
                "severity": "ERROR",
                "msg": f"Teleport at ({tp[1]},{tp[0]}) is NOT reachable from spawn",
            })

    # Rule 4: All interactable artifacts must be reachable
    # An artifact is reachable if the player can stand on its cell OR on any
    # adjacent cell (4-connected).  This covers "table" layouts where the
    # artifact sits on an elevated pedestal and the player interacts from a
    # neighboring lower tile.
    for art in graph.artifacts:
        pos = (art["row"], art["col"])
        if pos in reachable:
            continue
        # Check 4-connected neighbors
        r, c = pos
        adjacent_reachable = any(
            (r + dr, c + dc) in reachable
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]
        )
        if not adjacent_reachable:
            on_void = graph.hmap.get(pos, 0) == 0
            suffix = " [on VOID]" if on_void else ""
            issues.append({
                "rule": 4,
                "severity": "ERROR",
                "msg": f"Artifact '{art['name']}' at ({art['col']},{art['row']}) h={graph.hmap.get(pos, 0)} unreachable{suffix}",
            })

    # Rule 5: Teleport must stand on y=0 (void) in structure
    for tp in graph.teleports:
        tp_h = graph.hmap.get(tp, 0)
        if tp_h != 0:
            issues.append({
                "rule": 5,
                "severity": "ERROR",
                "msg": f"Teleport at ({tp[1]},{tp[0]}) has height {tp_h}, must be 0 (void)",
                "fix": "set_teleport_void",
            })

    # Rule 6: Only one teleport per map (normal case)
    if len(graph.teleports) > 1:
        coords = ", ".join(f"({tp[1]},{tp[0]})" for tp in graph.teleports)
        issues.append({
            "rule": 6,
            "severity": "WARN",
            "msg": f"Map has {len(graph.teleports)} teleports ({coords}) — normal case is 1",
        })

    return issues


# ---------------------------------------------------------------------------
# Auto-fix
# ---------------------------------------------------------------------------

def fix_normalize_spawn(data: dict) -> bool:
    """Rule 1: Normalize spawn to plain 's' — always start at 1,1,1.

    Any spawn utility with coordinates (s:1:1:4, s:2:1:1, etc.) gets
    stripped to just 's'.  Also normalizes s:1:1:1 → s.
    """
    utils = data.get("layers", {}).get("utilities", [])
    changed = False
    for r, row in enumerate(utils):
        for c, cell in enumerate(row):
            val = str(cell).strip()
            # Match spawn: 's' alone or 's:...' but NOT 'sub', 'sub:...'
            if val == "s":
                continue
            if val.startswith("s:") and not val.startswith("su"):
                utils[r][c] = "s"
                changed = True
    return changed


def fix_teleport_void(data: dict) -> bool:
    """Rule 5: Set structure height at teleport positions to 0 (void)."""
    utils = data.get("layers", {}).get("utilities", [])
    struct = data.get("layers", {}).get("structure", [])
    teleports = find_teleports(utils)
    changed = False
    for r, c in teleports:
        if r < len(struct) and c < len(struct[r]):
            if str(struct[r][c]).strip() != "0":
                struct[r][c] = "0"
                changed = True
    return changed


def fix_teleport_landing(data: dict) -> bool:
    """Rule 2: Ensure a structure row with floor cubes exists behind each teleport.

    For each teleport at row R, the structure must have a row R+1 with floor
    cubes to catch the arriving player. If row R+1 is missing or has no floor,
    we add/fix it. Also pads utilities and interactables layers to match.
    """
    struct = data.get("layers", {}).get("structure", [])
    utils = data.get("layers", {}).get("utilities", [])
    ints = data.get("layers", {}).get("interactables", [])
    if not struct or not utils:
        return False

    teleports = find_teleports(utils)
    if not teleports:
        return False

    cols = max((len(r) for r in struct), default=0)
    changed = False

    for tp_r, tp_c in teleports:
        landing_r = tp_r + 1

        # Need to add a new structure row?
        if landing_r >= len(struct):
            # Build landing row: copy wall pattern from teleport row,
            # but set floor cubes (h=1) where the teleport row has void (h=0)
            # to create a landing zone. Keep walls (h>=2) as-is.
            tp_row = struct[tp_r] if tp_r < len(struct) else ["0"] * cols
            new_row = []
            for i in range(cols):
                h = str(tp_row[i]).strip() if i < len(tp_row) else "0"
                if h == "0":
                    # Void cell in teleport row — make it floor in landing row
                    new_row.append("1")
                else:
                    # Wall/structure — preserve it
                    new_row.append(h)
            struct.append(new_row)
            changed = True
        else:
            # Row exists but has no floor cubes — add floor at teleport column
            landing_row = struct[landing_r]
            has_floor = any(
                int(str(landing_row[i]).strip() or "0") > 0
                for i in range(min(cols, len(landing_row)))
            )
            if not has_floor:
                # Add floor at teleport column and neighbors
                for c in range(max(0, tp_c - 1), min(cols, tp_c + 2)):
                    if c < len(landing_row):
                        if str(landing_row[c]).strip() == "0":
                            landing_row[c] = "1"
                            changed = True

    # Pad utilities and interactables to match new structure depth
    new_depth = len(struct)
    while len(utils) < new_depth:
        utils.append([" "] * cols)
        changed = True
    while len(ints) < new_depth:
        ints.append([" "] * cols)
        changed = True

    # Update dimensions if they exist
    if changed:
        dims = data.get("map_info", {}).get("dimensions", {})
        if dims and "depth" in dims:
            dims["depth"] = len(struct)

    return changed


def _save_map_preserve_format(map_path: Path, data: dict):
    """Save map JSON preserving compact array format used by Godot.

    Writes layer arrays as single-line rows (matching Godot editor format)
    while using tab indentation for everything else.
    """
    # Use json.dumps with indent, then compact the layer array rows
    text = json.dumps(data, indent="\t", ensure_ascii=False)
    # The layer rows are deeply nested arrays on multiple lines; compact them
    # Match patterns like:   [\n\t\t\t\t"val",\n\t\t\t\t"val"\n\t\t\t]
    # and compress to:       ["val","val"]
    import re
    def compact_inner_arrays(m):
        """Compact innermost arrays (layer rows) onto single lines."""
        content = m.group(0)
        # Strip all tabs/newlines, keep the values
        items = re.findall(r'"[^"]*"', content)
        return "[" + ",".join(items) + "]"

    # Compact arrays that contain only string elements (layer rows)
    text = re.sub(
        r'\[\s*\n(?:\s*"[^"]*",?\s*\n)+\s*\]',
        compact_inner_arrays,
        text,
    )
    with open(map_path, "w", encoding="utf-8") as f:
        f.write(text)


def apply_fixes(map_path: Path, data: dict, issues: list[dict], dry_run: bool = False) -> list[str]:
    """Apply auto-fixes for fixable rules. Returns list of fix descriptions."""
    applied = []

    fixable = {iss.get("fix") for iss in issues if "fix" in iss}

    # Rule 1: normalize spawn to plain 's'
    if "normalize_spawn" in fixable:
        if fix_normalize_spawn(data):
            applied.append("Rule 1: normalized spawn to 's' (always start at 1,1,1)")

    # Rule 2 is always auto-fixable when detected
    has_rule2 = any(iss["rule"] == 2 for iss in issues)
    if has_rule2:
        if fix_teleport_landing(data):
            applied.append("Rule 2: added landing row with floor cubes behind teleport")

    if "set_teleport_void" in fixable:
        if fix_teleport_void(data):
            applied.append("Rule 5: set teleport cell height to 0 (void)")

    if applied and not dry_run:
        _save_map_preserve_format(map_path, data)

    return applied


# ---------------------------------------------------------------------------
# ASCII visualization
# ---------------------------------------------------------------------------

# ANSI color codes
_RESET = "\033[0m"
_BOLD = "\033[1m"
_RED = "\033[91m"
_GREEN = "\033[92m"
_YELLOW = "\033[93m"
_BLUE = "\033[94m"
_MAGENTA = "\033[95m"
_CYAN = "\033[96m"
_DIM = "\033[2m"


def render_ascii(
    graph: MapGraph,
    reachable: set[tuple[int, int]],
    path: Optional[list[tuple[int, int]]] = None,
    use_color: bool = True,
) -> str:
    """Render the map as ASCII grid.

    Legend:
      S = spawn, T = teleport, * = artifact, . = reachable floor,
      # = unreachable floor, _ = void, ~ = wp ramp, ^ = tc platform,
      @ = path step
    """
    path_set = set(path) if path else set()
    lines = []

    # Header with column numbers
    col_header = "    " + "".join(f"{c % 10}" for c in range(graph.cols))
    lines.append(col_header)

    for r in range(graph.rows):
        row_chars = []
        for c in range(graph.cols):
            pos = (r, c)
            h = graph.hmap.get(pos, 0)

            # Determine character
            if pos == graph.spawn:
                ch, color = "S", _GREEN
            elif pos in [(tp[0], tp[1]) for tp in graph.teleports]:
                ch, color = "T", _MAGENTA
            elif any(a["row"] == r and a["col"] == c for a in graph.artifacts):
                # Artifact reachable if player can stand on it or on adjacent cell
                adj_reach = pos in reachable or any(
                    (r + dr, c + dc) in reachable
                    for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]
                )
                if adj_reach:
                    ch, color = "*", _CYAN
                else:
                    ch, color = "!", _RED
            elif pos in path_set:
                ch, color = "@", _YELLOW
            elif h == 0:
                if pos in graph.br_cells:
                    ch, color = "=", _CYAN
                elif pos in graph.tc_positions:
                    ch, color = "^", _BLUE
                else:
                    ch, color = "_", _DIM
            elif pos in graph.wp_cells:
                ch, color = "~", _BLUE
            elif pos in graph.tc_positions:
                ch, color = "^", _BLUE
            elif pos in reachable:
                ch, color = str(h) if h <= 9 else "+", ""
            else:
                ch, color = "#", _RED

            if use_color and color:
                row_chars.append(f"{color}{ch}{_RESET}")
            else:
                row_chars.append(ch)

        lines.append(f"{r:>3} " + "".join(row_chars))

    # Legend
    lines.append("")
    if use_color:
        lines.append(
            f"  {_GREEN}S{_RESET}=spawn  {_MAGENTA}T{_RESET}=teleport  "
            f"{_CYAN}*{_RESET}=artifact  {_RED}!{_RESET}=unreachable artifact  "
            f"{_YELLOW}@{_RESET}=path"
        )
        lines.append(
            f"  {_BLUE}~{_RESET}=ramp  {_BLUE}^{_RESET}=transport  "
            f"{_CYAN}={_RESET}=bridge  "
            f"{_RED}#{_RESET}=unreachable floor  "
            f"{_DIM}_{_RESET}=void  1-9=floor height"
        )
    else:
        lines.append("  S=spawn  T=teleport  *=artifact  !=unreachable  @=path")
        lines.append("  ~=ramp  ^=transport  ==bridge  #=unreachable floor  _=void  1-9=height")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_check(args: argparse.Namespace) -> int:
    """Check map construction rules."""
    if args.all:
        names = all_curriculum_maps()
        if not names:
            print("No curriculum maps found.")
            return 1
    else:
        names = args.maps

    total_issues = 0
    maps_checked = 0
    maps_ok = 0

    for name in names:
        path = resolve_map_path(name)
        if path is None:
            print(f"SKIP  {name} — map_data.json not found")
            continue
        data = load_map(path)
        graph = MapGraph(data)
        issues = check_rules(graph)
        maps_checked += 1

        errors = [i for i in issues if i["severity"] == "ERROR"]
        warnings = [i for i in issues if i["severity"] == "WARN"]
        total_issues += len(errors)

        if errors:
            print(f"FAIL  {graph.name}")
            for iss in issues:
                print(f"  Rule {iss['rule']} [{iss['severity']}] {iss['msg']}")
        else:
            maps_ok += 1
            if args.verbose:
                reachable = graph.bfs_flood()
                print(
                    f"OK    {graph.name}  "
                    f"({len(reachable)}/{len(graph.walkable)} reachable, "
                    f"{len(graph.artifacts)} artifacts, "
                    f"{len(graph.teleports)} teleport(s))"
                )
            if warnings:
                for w in warnings:
                    print(f"  Rule {w['rule']} [{w['severity']}] {w['msg']}")

    print(
        f"\n=== {maps_checked} maps checked: {maps_ok} OK, "
        f"{maps_checked - maps_ok} FAIL ({total_issues} issues) ==="
    )
    return 0 if total_issues == 0 else 1


def cmd_path(args: argparse.Namespace) -> int:
    """Find shortest path from spawn to a target."""
    path = resolve_map_path(args.map)
    if path is None:
        print(f"Map not found: {args.map}")
        return 1

    data = load_map(path)
    graph = MapGraph(data)

    target_pos = graph.find_target(args.to)
    if target_pos is None:
        print(f"Target '{args.to}' not found in {graph.name}")
        print("Available targets:")
        for art in graph.artifacts:
            print(f"  {art['name']}  at ({art['col']},{art['row']})")
        if graph.teleports:
            for tp in graph.teleports:
                print(f"  teleport  at ({tp[1]},{tp[0]})")
        return 1

    result = graph.bfs_path(target_pos)
    if result is None:
        print(f"NO PATH from spawn ({graph.spawn[1]},{graph.spawn[0]}) "
              f"to '{args.to}' at ({target_pos[1]},{target_pos[0]})")
        return 1

    print(f"Path from spawn to '{args.to}' ({len(result)} steps):")
    for i, (r, c) in enumerate(result):
        h = graph.hmap.get((r, c), 0)
        util = graph.util_map.get((r, c), "")
        suffix = f"  [{util}]" if util else ""
        print(f"  {i:>3}. ({c},{r}) h={h}{suffix}")

    if not args.no_map:
        reachable = graph.bfs_flood()
        print()
        print(render_ascii(graph, reachable, path=result, use_color=not args.no_color))

    return 0


def cmd_show(args: argparse.Namespace) -> int:
    """Show ASCII map visualization."""
    path = resolve_map_path(args.map)
    if path is None:
        print(f"Map not found: {args.map}")
        return 1

    data = load_map(path)
    graph = MapGraph(data)
    reachable = graph.bfs_flood()

    bfs_path = None
    if args.path_to:
        target_pos = graph.find_target(args.path_to)
        if target_pos:
            bfs_path = graph.bfs_path(target_pos)
            if bfs_path:
                print(f"Path to '{args.path_to}': {len(bfs_path)} steps")
            else:
                print(f"No path to '{args.path_to}'")

    dims = data.get("map_info", {}).get("dimensions", {})
    print(f"{graph.name}  {dims.get('width', '?')}x{dims.get('depth', '?')} h{dims.get('max_height', '?')}")
    print(f"Spawn: ({graph.spawn[1]},{graph.spawn[0]})  "
          f"Reachable: {len(reachable)}/{len(graph.walkable)}  "
          f"Artifacts: {len(graph.artifacts)}  "
          f"Teleports: {len(graph.teleports)}")
    print()
    print(render_ascii(graph, reachable, path=bfs_path, use_color=not args.no_color))

    # List artifacts with reachability
    if graph.artifacts:
        print(f"\nArtifacts:")
        for art in graph.artifacts:
            pos = (art["row"], art["col"])
            adj_reach = pos in reachable or any(
                (pos[0] + dr, pos[1] + dc) in reachable
                for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]
            )
            status = "OK" if adj_reach else "UNREACHABLE"
            h = graph.hmap.get(pos, 0)
            print(f"  {status:>11}  {art['name']}  ({art['col']},{art['row']}) h={h}")

    return 0


def cmd_fix(args: argparse.Namespace) -> int:
    """Auto-fix map construction rules where possible."""
    if args.all:
        names = all_curriculum_maps()
        if not names:
            print("No curriculum maps found.")
            return 1
    else:
        names = args.maps

    total_fixed = 0
    total_remaining = 0

    for name in names:
        map_path = resolve_map_path(name)
        if map_path is None:
            print(f"SKIP  {name} — map_data.json not found")
            continue
        data = load_map(map_path)
        graph = MapGraph(data)
        issues = check_rules(graph)

        if not issues:
            if args.verbose:
                print(f"OK    {graph.name} — no issues")
            continue

        applied = apply_fixes(map_path, data, issues, dry_run=args.dry_run)

        if applied:
            total_fixed += len(applied)
            prefix = "WOULD FIX" if args.dry_run else "FIXED"
            print(f"{prefix}  {graph.name}")
            for desc in applied:
                print(f"  + {desc}")

        # Re-check after fixes to report remaining issues
        if not args.dry_run and applied:
            data = load_map(map_path)
            graph = MapGraph(data)
            remaining = check_rules(graph)
        else:
            remaining = [iss for iss in issues if "fix" not in iss]

        if remaining:
            total_remaining += len(remaining)
            print(f"REMAIN  {graph.name}")
            for iss in remaining:
                print(f"  Rule {iss['rule']} [{iss['severity']}] {iss['msg']}")

    action = "would fix" if args.dry_run else "fixed"
    print(f"\n=== {total_fixed} {action}, {total_remaining} remaining (manual fix needed) ===")
    return 0 if total_remaining == 0 else 1


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

AUTO_FIXABLE_RULES = {1, 2, 5}  # Rules that map_pathfinder fix handles


def generate_fix_text(map_name: str, issues: list[dict]) -> str:
    """Generate a copy-pasteable fix instruction for one map."""
    errors = [i for i in issues if i["severity"] == "ERROR"]
    warnings = [i for i in issues if i["severity"] == "WARN"]
    auto = [i for i in errors if i["rule"] in AUTO_FIXABLE_RULES]
    manual = [i for i in errors if i["rule"] not in AUTO_FIXABLE_RULES]

    parts = []
    parts.append(f"**{map_name}**")

    if auto:
        rules = ", ".join(sorted(set(f"Rule {i['rule']}" for i in auto)))
        parts.append(f"Auto-fix ({rules}):")
        parts.append(f"  `python tools/map_pathfinder.py fix {map_name}`")

    for iss in manual:
        if iss["rule"] == 3:
            parts.append(f"  Manual: Teleport unreachable — connect with wp ramp, tc transport, or br bridge")
        elif iss["rule"] == 4:
            parts.append(f"  Manual: {iss['msg']} — add wp/tc/br to connect, or move artifact to reachable cell")

    for w in warnings:
        parts.append(f"  Note: {w['msg']}")

    return "\n".join(parts)


def build_task_description(map_name: str, seq_id: str, issues: list[dict]) -> str:
    """Build a detailed task description for Oversight."""
    errors = [i for i in issues if i["severity"] == "ERROR"]
    auto = [i for i in errors if i["rule"] in AUTO_FIXABLE_RULES]
    manual = [i for i in errors if i["rule"] not in AUTO_FIXABLE_RULES]

    lines = []
    lines.append(f"Fix map rules violations in `{map_name}` (sequence: {seq_id}).")
    lines.append("")
    lines.append(f"Map path: `commons/maps/{map_name}/map_data.json`")
    lines.append("")
    lines.append("**Issues:**")
    for iss in errors:
        lines.append(f"- Rule {iss['rule']} [{iss['severity']}]: {iss['msg']}")
    lines.append("")
    lines.append("**Steps:**")
    if auto:
        lines.append(f"1. Run: `python tools/map_pathfinder.py fix {map_name}`")
    step = 2 if auto else 1
    for iss in manual:
        if iss["rule"] == 3:
            lines.append(f"{step}. Teleport unreachable from spawn — add wp ramp, tc transport, or br bridge to connect.")
        elif iss["rule"] == 4:
            lines.append(f"{step}. {iss['msg']} — add wp/tc/br to connect, or move artifact to reachable cell.")
        step += 1
    lines.append(f"{step}. Verify: `python tools/map_pathfinder.py check {map_name} --verbose`")
    return "\n".join(lines)


def dispatch_to_oversight(
    tasks_data: list[dict],
    project_slug: str = OVERSIGHT_PROJECT,
    base_url: str = OVERSIGHT_URL,
    dry_run: bool = False,
) -> list[dict]:
    """POST fix tasks to Oversight scheduler. Returns list of created tasks."""
    import urllib.request
    import urllib.error

    url = f"{base_url}/api/projects/{project_slug}/tasks"
    created = []

    for task in tasks_data:
        payload = json.dumps(task).encode("utf-8")
        if dry_run:
            print(f"  DRY RUN: {task['title']}")
            created.append(task)
            continue

        req = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                result = json.loads(resp.read().decode("utf-8"))
                created.append(result)
                print(f"  Created: {task['title']} (id: {result.get('id', '?')})")
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            print(f"  FAILED: {task['title']} — {e.code} {body[:100]}")
        except urllib.error.URLError as e:
            print(f"  FAILED: {task['title']} — {e.reason}")
            print(f"  Is Oversight running at {base_url}?")
            break

    return created


def cmd_dispatch(args: argparse.Namespace) -> int:
    """Generate fix tasks and dispatch to Oversight scheduler."""
    groups = load_sequence_map_groups()

    if args.sequence:
        key = args.sequence.lower().replace("-", "").replace("_", "")
        groups = {sid: info for sid, info in groups.items()
                  if key in sid.lower().replace("-", "").replace("_", "")}
        if not groups:
            print(f"No sequence matching '{args.sequence}'")
            return 1

    tasks_to_create = []

    for seq_id, info in sorted(groups.items()):
        for mname in info["maps"]:
            path = resolve_map_path(mname)
            if path is None:
                continue
            try:
                data = load_map(path)
                graph = MapGraph(data)
                issues = check_rules(graph)
            except Exception:
                continue

            errors = [i for i in issues if i["severity"] == "ERROR"]
            if not errors:
                continue

            # Determine priority based on issue types
            has_auto_only = all(i["rule"] in AUTO_FIXABLE_RULES for i in errors)
            priority = "low" if has_auto_only else "medium"

            title = f"Fix {mname}: {len(errors)} rule violation(s)"
            desc = build_task_description(mname, seq_id, issues)

            tasks_to_create.append({
                "title": title,
                "description": desc,
                "priority": priority,
                "tags": json.dumps(["map-fix", seq_id, mname]),
                "source": "map_pathfinder",
                "sourceRef": f"pathfinder:{mname}",
            })

    if not tasks_to_create:
        print("No failing maps found — nothing to dispatch.")
        return 0

    # Group options
    if args.group == "sequence":
        # One task per sequence (batch)
        seq_tasks: dict[str, list[dict]] = {}
        for t in tasks_to_create:
            tags = json.loads(t["tags"])
            sid = tags[1]  # seq_id is second tag
            seq_tasks.setdefault(sid, []).append(t)

        batched = []
        for sid, items in sorted(seq_tasks.items()):
            maps = [json.loads(t["tags"])[2] for t in items]
            desc_parts = [t["description"] for t in items]
            batched.append({
                "title": f"Fix {len(items)} map(s) in {sid}",
                "description": "\n\n---\n\n".join(desc_parts),
                "priority": "medium",
                "tags": json.dumps(["map-fix", sid]),
                "source": "map_pathfinder",
                "sourceRef": f"pathfinder:batch:{sid}",
            })
        tasks_to_create = batched

    print(f"Dispatching {len(tasks_to_create)} task(s) to {OVERSIGHT_URL}/projects/{args.project}...")
    created = dispatch_to_oversight(
        tasks_to_create,
        project_slug=args.project,
        base_url=args.url,
        dry_run=args.dry_run,
    )
    print(f"\n{len(created)} task(s) {'would be created' if args.dry_run else 'created'}.")
    return 0


def cmd_report(args: argparse.Namespace) -> int:
    """Generate map rules report grouped by sequence."""
    from datetime import datetime

    groups = load_sequence_map_groups()

    # Filter to one sequence if requested
    if args.sequence:
        key = args.sequence.lower().replace("-", "").replace("_", "")
        filtered = {}
        for sid, info in groups.items():
            if key in sid.lower().replace("-", "").replace("_", ""):
                filtered[sid] = info
        if not filtered:
            print(f"No sequence matching '{args.sequence}' found.")
            return 1
        groups = filtered

    lines = []
    lines.append("# Map Rules Report")
    lines.append("")

    total_maps = 0
    total_ok = 0
    total_fail = 0
    total_missing = 0
    seq_summaries = []
    json_sequences = []  # structured data for JSON output

    for seq_id in sorted(groups.keys()):
        info = groups[seq_id]
        map_names = info["maps"]
        title = info["title"]
        seq_ok = 0
        seq_fail = 0
        seq_missing = 0
        map_rows = []
        fix_texts = []
        json_maps = []  # per-map structured data

        for mname in map_names:
            total_maps += 1
            path = resolve_map_path(mname)
            if path is None:
                map_rows.append((mname, "-- MISSING", "map_data.json not found"))
                json_maps.append({
                    "name": mname, "status": "MISSING",
                    "issues": [], "fix_text": "",
                })
                seq_missing += 1
                total_missing += 1
                continue

            try:
                data = load_map(path)
                graph = MapGraph(data)
                issues = check_rules(graph)
            except Exception as e:
                map_rows.append((mname, "!! ERROR", str(e)[:60]))
                json_maps.append({
                    "name": mname, "status": "ERROR",
                    "issues": [{"rule": 0, "severity": "ERROR", "msg": str(e)[:100]}],
                    "fix_text": "",
                })
                seq_fail += 1
                total_fail += 1
                continue

            errors = [i for i in issues if i["severity"] == "ERROR"]
            if not errors:
                seq_ok += 1
                total_ok += 1
                status = "OK"
                issue_str = ""
                fix_text = ""
            else:
                seq_fail += 1
                total_fail += 1
                status = "FAIL"
                issue_str = "; ".join(f"R{i['rule']}: {i['msg'][:50]}" for i in errors)
                fix_text = generate_fix_text(mname, issues)
                if args.fix_text:
                    fix_texts.append(fix_text)

            json_maps.append({
                "name": mname,
                "status": status,
                "issues": [
                    {"rule": i["rule"], "severity": i["severity"], "msg": i["msg"]}
                    for i in issues
                ],
                "fix_text": fix_text if status == "FAIL" else "",
            })
            map_rows.append((mname, status, issue_str))

        # Sequence header
        count = len(map_names)
        lines.append(f"## {seq_id} — \"{title}\" ({count} maps: {seq_ok} OK, {seq_fail} fail, {seq_missing} missing)")
        lines.append("")
        lines.append("| Map | Status | Issues |")
        lines.append("|-----|--------|--------|")
        for mname, status, issue_str in map_rows:
            lines.append(f"| {mname} | {status} | {issue_str} |")
        lines.append("")

        if fix_texts:
            lines.append("### Fix Instructions")
            lines.append("")
            for ft in fix_texts:
                lines.append(ft)
                lines.append("")

        seq_summaries.append((seq_id, seq_ok, seq_fail, seq_missing, count))
        json_sequences.append({
            "id": seq_id,
            "title": title,
            "ok": seq_ok,
            "fail": seq_fail,
            "missing": seq_missing,
            "maps": json_maps,
        })

    # Summary at top
    summary = []
    summary.append("# Map Rules Report")
    summary.append("")
    summary.append(f"**{len(groups)} sequences, {total_maps} maps: {total_ok} OK, {total_fail} fail, {total_missing} missing**")
    summary.append("")
    summary.append("| Sequence | OK | Fail | Missing | Total |")
    summary.append("|----------|----|------|---------|-------|")
    for sid, ok, fail, missing, total in seq_summaries:
        marker = "OK" if fail == 0 and missing == 0 else "FAIL"
        summary.append(f"| {marker} {sid} | {ok} | {fail} | {missing} | {total} |")
    summary.append("")
    summary.append("---")
    summary.append("")

    # Replace the header with summary + details
    output = "\n".join(summary + lines[2:])  # skip original header lines

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Report written to {args.output}")
    else:
        print(output)

    # JSON output
    json_path = getattr(args, "json", None)
    if not json_path and args.output:
        # Auto-generate JSON sibling when --output is given
        json_path = str(Path(args.output).with_suffix(".json"))

    if json_path:
        report_data = {
            "generated": datetime.now().isoformat(timespec="seconds"),
            "summary": {
                "total_sequences": len(groups),
                "total_maps": total_maps,
                "ok": total_ok,
                "fail": total_fail,
                "missing": total_missing,
            },
            "sequences": json_sequences,
        }
        Path(json_path).write_text(
            json.dumps(report_data, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        print(f"JSON report written to {json_path}")

    return 0 if total_fail == 0 else 1


# ---------------------------------------------------------------------------
# CLI entry
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="map_pathfinder",
        description="Validate reachability and find paths in AdaResearch maps.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # check
    p_check = sub.add_parser(
        "check",
        help="Check map construction rules (spawn, teleport, reachability)",
    )
    p_check.add_argument("maps", nargs="*", help="Map name(s) to check")
    p_check.add_argument("--all", action="store_true", help="Check all curriculum maps")
    p_check.add_argument("--verbose", "-v", action="store_true")
    p_check.set_defaults(func=cmd_check)

    # path
    p_path = sub.add_parser(
        "path",
        help="Find shortest path from spawn to a target",
    )
    p_path.add_argument("map", help="Map name")
    p_path.add_argument("--to", required=True, help="Target: artifact name or 'teleport'")
    p_path.add_argument("--no-map", action="store_true", help="Skip ASCII map")
    p_path.add_argument("--no-color", action="store_true", help="Disable ANSI colors")
    p_path.set_defaults(func=cmd_path)

    # fix
    p_fix = sub.add_parser(
        "fix",
        help="Auto-fix map construction rules (Rule 2: teleport landing, Rule 5: teleport void)",
    )
    p_fix.add_argument("maps", nargs="*", help="Map name(s) to fix")
    p_fix.add_argument("--all", action="store_true", help="Fix all curriculum maps")
    p_fix.add_argument("--dry-run", action="store_true", help="Show what would be fixed without writing")
    p_fix.add_argument("--verbose", "-v", action="store_true")
    p_fix.set_defaults(func=cmd_fix)

    # show
    p_show = sub.add_parser(
        "show",
        help="Show ASCII map with reachability overlay",
    )
    p_show.add_argument("map", help="Map name")
    p_show.add_argument("--path-to", help="Highlight path to target")
    p_show.add_argument("--no-color", action="store_true", help="Disable ANSI colors")
    p_show.set_defaults(func=cmd_show)

    # report
    p_report = sub.add_parser(
        "report",
        help="Generate map rules report grouped by sequence",
    )
    p_report.add_argument("--sequence", "-s", help="Filter to one sequence")
    p_report.add_argument("--output", "-o", help="Write report to file (markdown)")
    p_report.add_argument("--fix-text", action="store_true",
                          help="Include copy-pasteable fix instructions per failing map")
    p_report.add_argument("--json", help="Write JSON report to file (for Godot dashboard)")
    p_report.set_defaults(func=cmd_report)

    # dispatch
    p_dispatch = sub.add_parser(
        "dispatch",
        help="Send fix tasks to Oversight scheduler",
    )
    p_dispatch.add_argument("--sequence", "-s", help="Filter to one sequence")
    p_dispatch.add_argument("--project", default=OVERSIGHT_PROJECT,
                            help=f"Oversight project slug (default: {OVERSIGHT_PROJECT})")
    p_dispatch.add_argument("--url", default=OVERSIGHT_URL,
                            help=f"Oversight base URL (default: {OVERSIGHT_URL})")
    p_dispatch.add_argument("--group", choices=["map", "sequence"], default="map",
                            help="Create one task per map (default) or per sequence")
    p_dispatch.add_argument("--dry-run", action="store_true",
                            help="Show what would be dispatched without sending")
    p_dispatch.set_defaults(func=cmd_dispatch)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
