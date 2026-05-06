"""
spatial_grammar.py — Narrative architecture engine.

Maps are compositions. Artifacts are sections. The space between them
is the transition. Every transition uses a vocabulary of spatial tools.
Every boundary between sections has a name — arrival, departure,
preparation, continuation, rest. No raw crossfades.

The grammar has three layers:
  1. Vocabulary — 10 spatial transition tools
  2. Boundary types — 5 named conjunctions
  3. Rules — what makes a boundary designed vs accidental

Usage:
  from lib.spatial_grammar import compose_boundary_plan, generate_narrative_structure
"""

from dataclasses import dataclass, field
from typing import Optional
import math


# ═══════════════════════════════════════════════════════════════
# LAYER 1: VOCABULARY — 10 spatial transition words
# ═══════════════════════════════════════════════════════════════

@dataclass
class TransitionTool:
    name: str
    cells: int          # how many cells this transition spans
    description: str
    # Spatial effect parameters
    width_curve: str    # "narrow" | "widen" | "constant"
    height_curve: str   # "rise" | "drop" | "constant" | "jump"
    light_curve: str    # "brighten" | "darken" | "constant"


VOCABULARY = {
    "riser": TransitionTool(
        name="riser",
        cells=6,
        description="Something is coming — walls narrow progressively",
        width_curve="narrow",
        height_curve="constant",
        light_curve="constant",
    ),
    "snare_roll": TransitionTool(
        name="snare_roll",
        cells=3,
        description="It's coming faster — floor steps accelerate",
        width_curve="narrow",
        height_curve="rise",
        light_curve="constant",
    ),
    "crash": TransitionTool(
        name="crash",
        cells=1,
        description="We're here — space opens suddenly",
        width_curve="widen",
        height_curve="jump",
        light_curve="brighten",
    ),
    "downlifter": TransitionTool(
        name="downlifter",
        cells=4,
        description="Coming down — corridor widens gently",
        width_curve="widen",
        height_curve="drop",
        light_curve="darken",
    ),
    "filter_sweep": TransitionTool(
        name="filter_sweep",
        cells=8,
        description="World opening/closing — gradual transformation",
        width_curve="widen",
        height_curve="constant",
        light_curve="brighten",
    ),
    "subtraction": TransitionTool(
        name="subtraction",
        cells=2,
        description="Something taken away — wall appears, view blocked",
        width_curve="narrow",
        height_curve="constant",
        light_curve="darken",
    ),
    "silence": TransitionTool(
        name="silence",
        cells=3,
        description="Hold your breath — empty room, no content",
        width_curve="constant",
        height_curve="constant",
        light_curve="darken",
    ),
    "pad_fadeout": TransitionTool(
        name="pad_fadeout",
        cells=4,
        description="Exhale — ceiling lowers, space contracts gently",
        width_curve="narrow",
        height_curve="drop",
        light_curve="darken",
    ),
    "fill": TransitionTool(
        name="fill",
        cells=1,
        description="Something shifted — one step height change",
        width_curve="constant",
        height_curve="rise",
        light_curve="constant",
    ),
    "element_enter": TransitionTool(
        name="element_enter",
        cells=1,
        description="New voice — artifact becomes visible",
        width_curve="constant",
        height_curve="constant",
        light_curve="brighten",
    ),
}


# ═══════════════════════════════════════════════════════════════
# LAYER 2: BOUNDARY TYPES — 5 named conjunctions
# ═══════════════════════════════════════════════════════════════

@dataclass
class BoundaryType:
    name: str
    conjunction: str
    description: str
    required_transitions: int  # minimum transition tools
    default_tools: list        # suggested transition tools


BOUNDARIES = {
    "arrival": BoundaryType(
        name="arrival",
        conjunction="therefore",
        description="Build to Drop — the payoff. Compression releases into revelation.",
        required_transitions=2,
        default_tools=["riser", "crash"],
    ),
    "departure": BoundaryType(
        name="departure",
        conjunction="but then",
        description="Drop to Breakdown — breathing room after intensity.",
        required_transitions=1,
        default_tools=["downlifter"],
    ),
    "preparation": BoundaryType(
        name="preparation",
        conjunction="and then",
        description="Intro to Build — setting up what comes next.",
        required_transitions=1,
        default_tools=["filter_sweep"],
    ),
    "continuation": BoundaryType(
        name="continuation",
        conjunction="meanwhile",
        description="Verse to Verse — color shift, same energy.",
        required_transitions=1,
        default_tools=["fill"],
    ),
    "rest": BoundaryType(
        name="rest",
        conjunction="...",
        description="Silence before the biggest moment.",
        required_transitions=1,
        default_tools=["silence"],
    ),
}


# ═══════════════════════════════════════════════════════════════
# LAYER 3: RULES
# ═══════════════════════════════════════════════════════════════

def validate_boundary_plan(sections: list) -> list:
    """Validate a boundary plan against the grammar rules.

    Returns list of violations (empty = valid).
    """
    violations = []

    for i, section in enumerate(sections):
        boundary = section.get("boundary", "")
        transitions = section.get("transitions", [])
        btype = BOUNDARIES.get(boundary)

        if not btype:
            violations.append(f"Section {i}: unknown boundary '{boundary}'")
            continue

        # Rule 1: Arrival must have >= 2 transition tools
        if boundary == "arrival" and len(transitions) < 2:
            violations.append(
                f"Section {i} (arrival): needs >= 2 transitions, has {len(transitions)}. "
                f"Try adding: {', '.join(btype.default_tools)}"
            )

        # Rule 2: Departure must have >= 1 signal
        if boundary == "departure" and len(transitions) < 1:
            violations.append(
                f"Section {i} (departure): needs >= 1 signal transition. "
                f"Try: {btype.default_tools[0]}"
            )

        # Rule 3: No unnamed boundaries (raw crossfade)
        if not boundary:
            violations.append(
                f"Section {i}: no boundary named — if you can't name the conjunction, "
                f"it's not designed. Choose: {', '.join(BOUNDARIES.keys())}"
            )

        # Check all transitions are in vocabulary
        for t in transitions:
            if t not in VOCABULARY:
                violations.append(f"Section {i}: unknown transition '{t}'")

    # Rule 4: Tension and energy shouldn't always peak together
    arrivals = [i for i, s in enumerate(sections) if s.get("boundary") == "arrival"]
    if len(arrivals) >= 2:
        consecutive_arrivals = any(
            arrivals[j+1] - arrivals[j] == 1 for j in range(len(arrivals)-1)
        )
        if consecutive_arrivals:
            violations.append(
                "Consecutive arrivals without breathing room — "
                "insert a departure or rest between peaks"
            )

    return violations


# ═══════════════════════════════════════════════════════════════
# SECTION: A beat in the composition
# ═══════════════════════════════════════════════════════════════

@dataclass
class Section:
    """One beat in the spatial composition."""
    artifact: Optional[str] = None   # lookup_name or None for empty beats
    boundary: str = "continuation"   # arrival | departure | preparation | continuation | rest
    transitions: list = field(default_factory=list)  # transition tool names
    role: str = ""                   # intro | complication | revelation | synthesis | breathing


# ═══════════════════════════════════════════════════════════════
# PRESETS: Named grammars from real spaces
# ═══════════════════════════════════════════════════════════════

GRAMMAR_PRESETS = {
    "florence": {
        "name": "Florence — Piazza Rhythm",
        "description": "Narrow street, narrow street, then BOOM — a piazza. Compression then release.",
        "pattern": ["preparation", "continuation", "arrival", "departure",
                     "continuation", "arrival", "departure", "arrival"],
        "default_transitions": {
            "preparation": ["filter_sweep"],
            "continuation": ["fill"],
            "arrival": ["riser", "crash"],
            "departure": ["downlifter"],
        },
    },
    "vatican": {
        "name": "Vatican — Long Compression",
        "description": "The longest anticipation corridor, leading to one room. One ceiling.",
        "pattern": ["preparation", "continuation", "continuation", "continuation",
                     "continuation", "continuation", "rest", "arrival"],
        "default_transitions": {
            "preparation": ["filter_sweep"],
            "continuation": ["snare_roll"],
            "rest": ["silence"],
            "arrival": ["riser", "snare_roll", "crash"],
        },
    },
    "zelda": {
        "name": "Zelda — Dungeon Key",
        "description": "Each room is a puzzle that gives you the tool for the next room.",
        "pattern": ["preparation", "arrival", "departure", "preparation",
                     "arrival", "departure", "rest", "arrival"],
        "default_transitions": {
            "preparation": ["riser"],
            "arrival": ["crash", "element_enter"],
            "departure": ["subtraction", "downlifter"],
            "rest": ["silence"],
        },
    },
    "halflife": {
        "name": "Half-Life — Scripted Corridor",
        "description": "Every hallway is a sight line to the next event. Architecture IS the director.",
        "pattern": ["preparation", "arrival", "departure", "preparation",
                     "arrival", "departure", "preparation", "arrival"],
        "default_transitions": {
            "preparation": ["riser"],
            "arrival": ["crash"],
            "departure": ["pad_fadeout"],
        },
    },
    "metropolitan": {
        "name": "Metropolitan — Wing System",
        "description": "Hub with branches. Choose your depth. Return to center.",
        "pattern": ["arrival", "departure", "preparation", "arrival",
                     "departure", "preparation", "arrival", "departure"],
        "default_transitions": {
            "arrival": ["crash", "element_enter"],
            "departure": ["downlifter"],
            "preparation": ["filter_sweep"],
        },
    },
    "venice": {
        "name": "Venice — Constant Surprise",
        "description": "Lost immediately. Every turn reveals something unexpected.",
        "pattern": ["preparation", "arrival", "continuation", "arrival",
                     "continuation", "arrival", "rest", "arrival"],
        "default_transitions": {
            "preparation": ["fill"],
            "arrival": ["crash"],
            "continuation": ["subtraction", "element_enter"],
            "rest": ["silence"],
        },
    },
    "linear": {
        "name": "Linear — Simple Progression",
        "description": "Straight path, steady reveal. Good for tutorials.",
        "pattern": ["preparation", "arrival", "departure", "arrival",
                     "departure", "arrival"],
        "default_transitions": {
            "preparation": ["filter_sweep"],
            "arrival": ["riser", "crash"],
            "departure": ["downlifter"],
        },
    },
}


# ═══════════════════════════════════════════════════════════════
# COMPOSER: Build a boundary plan from artifacts + grammar
# ═══════════════════════════════════════════════════════════════

def compose_boundary_plan(
    artifacts: list,
    grammar: str = "linear",
    include_breathing: bool = True,
) -> list:
    """Create a boundary plan from a list of artifact names and a grammar preset.

    Returns list of Section dicts ready for the structure generator.
    """
    preset = GRAMMAR_PRESETS.get(grammar, GRAMMAR_PRESETS["linear"])
    pattern = preset["pattern"]
    default_trans = preset["default_transitions"]

    sections = []
    art_idx = 0

    for i, boundary in enumerate(pattern):
        # Assign artifacts to non-rest boundaries
        artifact = None
        if boundary != "rest" and art_idx < len(artifacts):
            artifact = artifacts[art_idx]
            art_idx += 1

        transitions = list(default_trans.get(boundary, []))

        sections.append({
            "artifact": artifact,
            "boundary": boundary,
            "transitions": transitions,
            "index": i,
        })

    # If we have more artifacts than pattern beats, extend with continuation
    while art_idx < len(artifacts):
        sections.append({
            "artifact": artifacts[art_idx],
            "boundary": "continuation",
            "transitions": default_trans.get("continuation", ["fill"]),
            "index": len(sections),
        })
        art_idx += 1

    # Add breathing room between consecutive arrivals if requested
    if include_breathing:
        cleaned = []
        for i, sec in enumerate(sections):
            cleaned.append(sec)
            if (sec["boundary"] == "arrival" and
                i + 1 < len(sections) and
                sections[i + 1]["boundary"] == "arrival"):
                cleaned.append({
                    "artifact": None,
                    "boundary": "departure",
                    "transitions": default_trans.get("departure", ["downlifter"]),
                    "index": -1,
                })
        sections = cleaned

    return sections


# ═══════════════════════════════════════════════════════════════
# STRUCTURE GENERATOR: Boundary plan → grid cells
# ═══════════════════════════════════════════════════════════════

def generate_narrative_structure(
    sections: list,
    grid_width: int = 15,
    wall_height: int = 2,
    base_corridor_width: int = 3,
    layout: str = "packed",
) -> dict:
    """Generate structure from boundary plan. layout='packed' (city) or 'linear' (timeline)."""
    if layout == "packed":
        return generate_packed_structure(sections, grid_width, wall_height, base_corridor_width)
    return generate_linear_structure(sections, grid_width, wall_height, base_corridor_width)


def generate_packed_structure(
    sections: list,
    grid_width: int = 15,
    wall_height: int = 2,
    base_corridor_width: int = 2,
) -> dict:
    """Boolean gutter packing — beehive algorithm.

    Start with a solid block. Each artifact subtracts exactly its footprint
    plus a 1-cell gutter. Passages are 1 cell wide. Everything else is wall.
    The map is 80% solid, 20% void.

    Artifacts are packed using serpentine (boustrophedon) routing through
    the grid. The grammar controls passage character, not room size.
    """
    # Collect artifacts from sections (skip breathing beats)
    artifact_sections = [s for s in sections if s.get("artifact")]
    breathing_sections = [s for s in sections if not s.get("artifact")]

    if not artifact_sections:
        return {"structure": [[str(wall_height)] * grid_width], "artifact_positions": [],
                "spawn": (0, 0), "teleporter": (0, 0), "grid_depth": 1, "grid_width": grid_width, "sections": sections}

    n = len(artifact_sections)

    # ── Grammar-aware placement ────────────────────────────────
    # Each boundary type has a directional relationship to the previous room:
    #   arrival     = ahead + turn (you discover it around a corner)
    #   departure   = straight ahead (you leave directly)
    #   preparation = ahead (building toward something)
    #   continuation = sideways (parallel, same depth)
    #   rest        = dead-end branch (side alcove)

    DIRECTION_MAP = {
        "arrival":     [(0, 4), (3, 0), (0, -4), (-3, 0)],    # rotate: right, down, left, up
        "departure":   [(3, 0)],                                 # always forward (down)
        "preparation": [(3, 0), (0, 3)],                        # forward or right
        "continuation":[(0, 3), (0, -3)],                       # sideways
        "rest":        [(0, 3), (0, -3), (3, 0)],              # branch off
    }

    unit = 3  # artifact(1) + gutter(1) each side
    padding = 2  # extra border padding

    # Place first artifact
    start_r = padding + 1
    start_c = grid_width // 2
    cell_centers = [(start_r, start_c)]
    placed_set = {(start_r, start_c)}

    # Walk through sections, placing each relative to the previous
    direction_idx = 0  # rotate through available directions
    for i in range(1, n):
        sec = artifact_sections[i]
        boundary = sec.get("boundary", "continuation")
        prev_r, prev_c = cell_centers[-1]

        dirs = DIRECTION_MAP.get(boundary, [(3, 0)])
        placed = False

        # Try each direction option, pick first that fits
        for attempt in range(len(dirs) * 4):
            dr, dc = dirs[attempt % len(dirs)]

            # Rotate on subsequent attempts
            if attempt >= len(dirs):
                rot = attempt // len(dirs)
                if rot == 1: dr, dc = dc, -dr      # 90 CW
                elif rot == 2: dr, dc = -dr, -dc    # 180
                elif rot == 3: dr, dc = -dc, dr     # 90 CCW

            nr, nc = prev_r + dr, prev_c + dc

            # Check bounds and no overlap
            if (padding < nr < 100 and padding < nc < grid_width - padding
                and (nr, nc) not in placed_set
                and all(abs(nr - pr) + abs(nc - pc) >= unit - 1
                        for pr, pc in cell_centers)):
                cell_centers.append((nr, nc))
                placed_set.add((nr, nc))
                placed = True
                break

        if not placed:
            # Emergency: just go down
            nr = cell_centers[-1][0] + unit
            nc = cell_centers[-1][1]
            cell_centers.append((nr, nc))
            placed_set.add((nr, nc))

    # Calculate actual grid bounds from placed cells
    min_r = min(r for r, c in cell_centers) - padding
    max_r = max(r for r, c in cell_centers) + padding
    min_c = min(c for r, c in cell_centers) - padding
    max_c = max(c for r, c in cell_centers) + padding

    # Normalize to 0-based grid
    offset_r = min_r
    offset_c = min_c
    cell_centers = [(r - offset_r, c - offset_c) for r, c in cell_centers]

    grid_depth = max_r - offset_r + 1
    actual_width = max_c - offset_c + 1
    grid_width = max(grid_width, actual_width)

    # ── Initialize: solid block ────────────────────────────────
    grid = []
    for _ in range(grid_depth):
        grid.append([str(wall_height)] * grid_width)

    artifact_positions = []

    # ── Boolean subtract: each artifact cell + gutter ──────────
    for i, sec in enumerate(artifact_sections):
        cy, cx = cell_centers[i]
        boundary = sec.get("boundary", "continuation")

        # Gutter size: arrival gets 2, rest gets 1
        gutter = 2 if boundary == "arrival" else 1

        # Carve artifact + gutter
        for dr in range(-gutter, gutter + 1):
            for dc in range(-gutter, gutter + 1):
                r, c = cy + dr, cx + dc
                if 0 < r < grid_depth - 1 and 0 < c < grid_width - 1:
                    grid[r][c] = "1"

        # Place artifact
        if sec.get("artifact") and 0 < cy < grid_depth - 1 and 0 < cx < grid_width - 1:
            artifact_positions.append((cy, cx, sec["artifact"]))

    # ── Connect cells with 1-cell passages (serpentine order) ──
    for i in range(len(cell_centers) - 1):
        r1, c1 = cell_centers[i]
        r2, c2 = cell_centers[i + 1]

        sec = artifact_sections[min(i + 1, len(artifact_sections) - 1)]
        transitions = sec.get("transitions", [])
        boundary = sec.get("boundary", "continuation")

        # Passage width: 1 cell (minimum), 2 for arrivals
        pw = 1
        if boundary == "arrival" and "crash" in transitions:
            pw = 2

        # Carve L-shaped passage
        # Horizontal first
        min_c, max_c = min(c1, c2), max(c1, c2)
        for c in range(min_c, max_c + 1):
            for dw in range(pw):
                rr = r1 + dw
                if 0 < rr < grid_depth - 1 and 0 < c < grid_width - 1:
                    grid[rr][c] = "1"

        # Then vertical
        min_r, max_r = min(r1, r2), max(r1, r2)
        for r in range(min_r, max_r + 1):
            for dw in range(pw):
                cc = c2 + dw
                if 0 < r < grid_depth - 1 and 0 < cc < grid_width - 1:
                    grid[r][cc] = "1"

        # ── Transition effects in the passage ──────────────────
        # Riser: add wall pinch at midpoint of passage (narrowing)
        if "riser" in transitions:
            mid_r = (r1 + r2) // 2
            mid_c = (c1 + c2) // 2
            # Pinch by adding wall cells on sides of passage
            if abs(r1 - r2) > 2:
                for dc in [-1, pw]:
                    cc = c2 + dc
                    if 0 < mid_r < grid_depth - 1 and 0 < cc < grid_width - 1:
                        grid[mid_r][cc] = str(wall_height)

        # Subtraction: block line of sight behind you
        if "subtraction" in transitions:
            # Add a wall cell just after leaving the previous room
            block_r = r1 + (1 if r2 > r1 else -1)
            block_c = c1 + (1 if c2 > c1 else 0)
            if 0 < block_r < grid_depth - 1 and 0 < block_c < grid_width - 1:
                # Only block if it doesn't cut off the passage
                if grid[block_r][c2] == "1":  # passage still open on other side
                    grid[block_r][block_c] = str(wall_height)

    # ── Rest beats: insert dead-end alcoves ────────────────────
    for sec in breathing_sections:
        if sec.get("boundary") == "rest" and cell_centers:
            # Find the midpoint of the path
            mid_idx = len(cell_centers) // 2
            mr, mc = cell_centers[mid_idx]
            # Carve a small side alcove (2 cells deep)
            for dc in range(1, 3):
                nc = mc + dc
                if nc < grid_width - 1:
                    grid[mr][nc] = "1"

    # ── Spawn: connect to first artifact ───────────────────────
    first_r, first_c = cell_centers[0]
    spawn = (1, first_c)
    # Carve spawn cell and connection
    for r in range(1, first_r + 1):
        if 0 < r < grid_depth - 1 and 0 < first_c < grid_width - 1:
            grid[r][first_c] = "1"

    # ── Teleporter: after last artifact ────────────────────────
    last_r, last_c = cell_centers[-1]
    tp_r = min(last_r + 2, grid_depth - 2)
    tp_c = last_c

    # Carve connection to teleporter
    for r in range(last_r, tp_r + 1):
        if 0 < r < grid_depth - 1 and 0 < tp_c < grid_width - 1:
            grid[r][tp_c] = "1"

    # Teleporter on void
    teleporter = (tp_r, tp_c)
    if 0 < tp_r < grid_depth - 1 and 0 < tp_c < grid_width - 1:
        grid[tp_r][tp_c] = "0"

    # ── Ensure border walls ────────────────────────────────────
    for r in range(grid_depth):
        grid[r][0] = str(wall_height)
        if grid_width > 1:
            grid[r][grid_width - 1] = str(wall_height)
    for c in range(grid_width):
        grid[0][c] = str(wall_height)
        if grid_depth > 1:
            grid[grid_depth - 1][c] = str(wall_height)

    return {
        "structure": grid,
        "artifact_positions": artifact_positions,
        "spawn": spawn,
        "teleporter": teleporter,
        "grid_depth": grid_depth,
        "grid_width": grid_width,
        "sections": sections,
        "cell_centers": cell_centers,
    }


def generate_linear_structure(
    sections: list,
    grid_width: int = 15,
    wall_height: int = 2,
    base_corridor_width: int = 3,
) -> dict:
    """Generate a linear timeline structure from a boundary plan.

    Returns {structure: [[str]], artifact_positions: [(row, col, name)],
             spawn: (row, col), teleporter: (row, col), grid_depth: int}.
    """
    # Calculate total depth needed
    total_cells = 0
    section_spans = []
    for sec in sections:
        transitions = sec.get("transitions", [])
        span = sum(VOCABULARY[t].cells for t in transitions if t in VOCABULARY)
        span = max(span, 3)  # minimum 3 cells per section
        # Add room for artifact
        if sec.get("artifact"):
            span += 2  # artifact pad
        section_spans.append(span)
        total_cells += span

    grid_depth = total_cells + 4  # +4 for spawn pad and exit pad
    half_w = grid_width // 2

    # Initialize grid with walls
    grid = []
    for _ in range(grid_depth):
        grid.append([str(wall_height)] * grid_width)

    # Carve sections along the Z axis (top to bottom)
    current_z = 2  # start after spawn pad
    artifact_positions = []
    spawn = (1, half_w)
    teleporter = None

    # Carve spawn pad
    for r in range(0, 3):
        for c in range(1, grid_width - 1):
            grid[r][c] = "1"

    for sec_idx, sec in enumerate(sections):
        transitions = sec.get("transitions", [])
        boundary = sec.get("boundary", "continuation")
        artifact = sec.get("artifact")
        span = section_spans[sec_idx]

        # Calculate corridor width for this section based on transitions
        corridor_width = base_corridor_width
        for t_name in transitions:
            tool = VOCABULARY.get(t_name)
            if not tool:
                continue
            if tool.width_curve == "narrow":
                corridor_width = max(2, corridor_width - 1)
            elif tool.width_curve == "widen":
                corridor_width = min(grid_width - 2, corridor_width + 2)

        # Calculate height variation
        floor_height = 1
        for t_name in transitions:
            tool = VOCABULARY.get(t_name)
            if not tool:
                continue
            if tool.height_curve == "rise":
                floor_height = 2
            elif tool.height_curve == "jump":
                floor_height = 1  # floor stays 1 but we make walls lower (open feel)
            elif tool.height_curve == "drop":
                floor_height = 1

        # Carve this section
        left = max(1, half_w - corridor_width // 2)
        right = min(grid_width - 1, half_w + corridor_width // 2 + 1)

        # Transition carving — progressive narrowing/widening
        for dz in range(span):
            z = current_z + dz
            if z >= grid_depth - 2:
                break

            # Interpolate width across the span for curves
            progress = dz / max(1, span - 1)

            sec_left = left
            sec_right = right

            # Apply width curves from transitions
            for t_name in transitions:
                tool = VOCABULARY.get(t_name)
                if not tool:
                    continue
                if tool.width_curve == "narrow":
                    squeeze = int(progress * 2)
                    sec_left = min(sec_left + squeeze, half_w - 1)
                    sec_right = max(sec_right - squeeze, half_w + 1)
                elif tool.width_curve == "widen":
                    expand = int(progress * 2)
                    sec_left = max(1, sec_left - expand)
                    sec_right = min(grid_width - 1, sec_right + expand)

            # Carve floor
            for c in range(sec_left, sec_right):
                grid[z][c] = str(floor_height)

            # Crash = sudden full width
            if boundary == "arrival" and "crash" in transitions and dz == span - 1:
                for c in range(1, grid_width - 1):
                    grid[z][c] = "1"

        # Place artifact at center of section
        if artifact:
            art_z = current_z + span // 2
            art_x = half_w
            if art_z < grid_depth - 2:
                artifact_positions.append((art_z, art_x, artifact))
                # Ensure artifact has floor
                for dc in range(-1, 2):
                    cx = art_x + dc
                    if 0 < cx < grid_width - 1:
                        grid[art_z][cx] = "1"

        current_z += span

    # Carve exit pad + teleporter
    exit_z = min(current_z + 1, grid_depth - 2)
    for r in range(max(0, exit_z - 1), min(grid_depth, exit_z + 2)):
        for c in range(1, grid_width - 1):
            if r < grid_depth:
                grid[r][c] = "1"

    # Teleporter on void
    teleporter = (exit_z, half_w + 2)
    if teleporter[0] < grid_depth and teleporter[1] < grid_width:
        grid[teleporter[0]][teleporter[1]] = "0"

    # Ensure border walls
    for r in range(grid_depth):
        grid[r][0] = str(wall_height)
        grid[r][grid_width - 1] = str(wall_height)
    for c in range(grid_width):
        grid[0][c] = str(wall_height)
        grid[grid_depth - 1][c] = str(wall_height)

    return {
        "structure": grid,
        "artifact_positions": artifact_positions,
        "spawn": spawn,
        "teleporter": teleporter,
        "grid_depth": grid_depth,
        "grid_width": grid_width,
        "sections": sections,
    }


def ascii_preview(result: dict) -> str:
    """Render narrative structure as annotated ASCII art."""
    grid = result["structure"]
    artifacts = {(r, c): n for r, c, n in result["artifact_positions"]}
    spawn = result["spawn"]
    teleporter = result["teleporter"]

    chars = {"0": ".", "1": " ", "2": "#", "3": "#"}
    lines = []
    for r, row in enumerate(grid):
        line = ""
        for c, cell in enumerate(row):
            pos = (r, c)
            if pos == spawn:
                line += "S"
            elif pos == teleporter:
                line += "T"
            elif pos in artifacts:
                line += "*"
            else:
                line += chars.get(str(cell), cell)
        # Annotate artifacts on the right
        for (ar, ac), name in artifacts.items():
            if ar == r:
                line += f"  <- {name}"
                break
        lines.append(line)
    return "\n".join(lines)
