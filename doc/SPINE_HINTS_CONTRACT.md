# spine_hints() — the artifact-to-map contract

> The keystone of procedural map generation. Every artifact that appears in
> a spine-runner corridor declares what it needs. The corridor generator
> reads those declarations, places artifacts into a 16×8 frame, and writes
> no JSON. The artifact speaks first.

## The contract

Every artifact root node (the `Node3D` with `class_name ArtifactToken`) may
implement one optional method:

```gdscript
func spine_hints() -> Dictionary:
    return {
        "role":         "supporting",     # primary | supporting | reflection | ambient
        "footprint":    Vector2i(1, 1),   # cells along (x, z) — always ≥ 1x1
        "approach":     "any",            # south | any — which side the player reads it from
        "reading_dist": 1.0,              # min meters from nearest neighbor artifact
        "height":       0.0,              # y_offset applied when placed
        "rotation_y":   -1,               # preferred Y rotation in deg; -1 = generator picks
        "budget_ms":    0.5,              # expected GPU cost per frame in ms
        "tags":         [],               # free-form: ["vector", "interactive", "label"]
    }
```

All keys are optional. Missing keys take the defaults shown above. If the
method itself is missing, the artifact gets *all* defaults — a safe, small,
neutral placement.

## The five keys that matter most

| key | default | effect on placement |
|---|---|---|
| `role` | `"supporting"` | `primary` goes near row 8 (center); `supporting` fills rings around it; `reflection` goes near row 14 (pre-teleporter); `ambient` can go anywhere with no scoring bonus |
| `footprint` | `Vector2i(1,1)` | reserves this many cells on the structure layer; nothing else is placed inside |
| `approach` | `"any"` | `south` means the artifact's −z face must be clear of other artifacts for at least 2 cells — so the player can walk up to it head-on |
| `reading_dist` | `1.0` | minimum meters from any other primary/supporting artifact — breathing room |
| `budget_ms` | `0.5` | generator sums this across placed artifacts; if total > 80% of frame budget (11.1ms @ 90Hz or 13.9ms @ 72Hz), the candidate layout is rejected |

## Roles — the teaching arc of a corridor

A spine-runner map is a short teaching moment you walk through in ~15–30
seconds. Four roles encode the narrative shape:

- **primary** — the one artifact the map is *about*. There should be exactly
  one per map. Placed at row 6–10 (heart of the corridor), centered on the
  walkway. The player reaches it after establishing the space. Typical:
  `interactive_point_origin`, `vector_addition_walk`.

- **supporting** — artifacts that extend or contextualize the primary.
  Placed in rings around the primary, outside its reading_dist. Typical:
  `static_point` next to `interactive_point_origin`, or a `coordinate_system_3m`
  nearby for reference.

- **reflection** — text, science_screen, chamber elements. Placed near the
  end (row 13–14) so the player passes them last, after having walked the
  phenomenon. Typical: `science_screen`, `code_evolution_screen`,
  `folding_past` (aphorism label).

- **ambient** — atmosphere: biome elements, dark spheres, coordinate axes.
  Scattered anywhere the corridor has space. No teaching weight; decoration
  and tone.

## Tags — vocabulary that the generator can learn from

Tags aren't enforced. They're a soft channel the scoring function reads:

- `vector`, `scalar`, `field`, `form` — conceptual kind
- `interactive`, `static`, `label` — player relationship
- `audio`, `visual`, `haptic` — sensory channel
- `isolated`, `grouped` — placement preference (`isolated` softly prefers
  empty cells around it; `grouped` softly prefers proximity to same-sequence
  artifacts)

Over time the scoring function reads the existing hand-placed maps, learns
which tag combinations cluster, and encodes that as soft constraints. Tags
are the vocabulary the generator learns a poetics in.

## Worked examples

```gdscript
# interactive_point_origin — THE point the sequence is about
func spine_hints() -> Dictionary:
    return {
        "role":      "primary",
        "footprint": Vector2i(2, 2),
        "approach":  "south",
        "reading_dist": 2.0,
        "height":    1.0,
        "budget_ms": 1.2,
        "tags":      ["vector", "interactive", "grouped"],
    }

# static_point — companion to the interactive point, fixed reference
func spine_hints() -> Dictionary:
    return {
        "role":      "supporting",
        "footprint": Vector2i(1, 1),
        "approach":  "any",
        "reading_dist": 1.5,
        "height":    1.0,
        "budget_ms": 0.3,
        "tags":      ["vector", "static", "isolated"],
    }

# science_screen — reflection / closing text
func spine_hints() -> Dictionary:
    return {
        "role":      "reflection",
        "footprint": Vector2i(2, 1),
        "approach":  "south",
        "reading_dist": 1.0,
        "height":    2.0,
        "rotation_y": 180,      # face south so player reads while walking north
        "budget_ms": 0.4,
        "tags":      ["label", "static"],
    }

# dark_sphere — ambient atmosphere
func spine_hints() -> Dictionary:
    return {
        "role":      "ambient",
        "footprint": Vector2i(1, 1),
        "approach":  "any",
        "reading_dist": 0.0,
        "height":    -0.5,
        "budget_ms": 0.2,
        "tags":      ["visual"],
    }
```

## What the contract does NOT encode

- **Teaching order.** That's the sequence file's job — the artifact list is
  already ordered, and the generator uses that order as a soft prior
  (earlier-listed primary gets center; later-listed supporting goes nearer
  the teleporter).
- **Specific x,z coordinates.** That's exactly what we're getting *away*
  from. The artifact says what it needs; the generator decides where.
- **Specific scene-instance properties** (e.g. which text appears on a
  science_screen). Those stay on the artifact itself, passed via the
  existing `apply_grid_config(config_data)` pattern. The hint is about
  *shape in the world*, not internal state.

## Rollout discipline

1. New artifacts: ship with `spine_hints()` from day one.
2. Existing artifacts: add as we touch them. Audit tool at
   `tools/spine_hints_audit.py` reports coverage.
3. When an artifact has no hints, generator uses defaults and logs a line.
   Nothing breaks; the artifact is placed as a safe 1×1 supporting.
4. The contract can grow keys but never rename them. Once shipped, a key
   lives forever.

## Why one function, not a resource

We considered `@export` properties on the artifact, or a separate
`.spine_hints.json` file per artifact. Both were rejected:

- `@export` couples the hint to the scene and can't be computed.
- `.json` siblings create two-file synchronization.

A method returns a dict at query time. It can be a constant (most common)
or computed from the artifact's current state (some creatures return
different footprints based on DNA). One function. No ceremony.

## The loop it enables

```
artifact authored  →  spine_hints() written  →  sequence lists it  →
generator reads hints  →  corridor assembled  →  player walks it  →
runner samples frame budget  →  budget pressure fed back  →
generator adjusts LOD / density for next corridor  →  loop
```

Every piece after `spine_hints()` can change. The contract is the only
part that stays. Everything is plugged into that dict.
