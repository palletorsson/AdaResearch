# Placement Rules

Rules that modify structure around artifact positions during map generation. Defined in `commons/artifacts/placement_rules.json`.

## Schema

```json
{
  "schema": "adaresearch.placement_rules.v1",
  "exemptTokens": ["dark_sphere", "cube_scene"],
  "rules": [ ... ]
}
```

## Rule Structure

```json
{
  "id": "pedestal_compact",
  "name": "Pedestal for compact artifacts",
  "description": "Human-readable explanation",
  "condition": {
    "size_group": ["compact"],
    "interaction": ["observe", "manipulate", "grab"],
    "world_phase": ["optional_phase_filter"]
  },
  "actions": [
    {
      "type": "structure_modify",
      "offset": [0, 0],
      "value": 2,
      "probability": 0.6,
      "description": "Elevate the tile under the artifact"
    }
  ],
  "priority": 10,
  "enabled": true,
  "source": "extracted|manual",
  "notes": "Context or origin notes"
}
```

### Condition Fields

| Field | Type | Description |
|-------|------|-------------|
| `size_group` | string[] | Match artifacts with these size groups: `compact`, `room_scale` |
| `interaction` | string[] | Match artifacts with these interaction modes: `observe`, `manipulate`, `grab`, `walkthrough` |
| `world_phase` | string[] | Optional. Match only in specific world phases |

All condition arrays use OR logic within a field, AND logic across fields. An artifact must match at least one value in each specified field.

### Action Types

**`structure_modify`** — Write a value to the structure grid at the specified offset from the artifact position.

| Field | Type | Description |
|-------|------|-------------|
| `offset` | [row, col] | Grid offset from artifact. `[0,0]` = under artifact, `[-1,0]` = one row north (behind) |
| `value` | number | Structure code to write: `1` = floor, `2` = elevated, `3` = dark wall, `4` = decorative elevation |
| `probability` | 0-1 | Chance this action fires. Creates stochastic variety |
| `description` | string | Human-readable label |

**`require_structure`** — Check (without modifying) that a cell matches a value. Used for conditional validation.

| Field | Type | Description |
|-------|------|-------------|
| `offset` | [row, col] | Grid offset to check |
| `value` | number | Expected structure code |
| `comparison` | string | `eq` (default), `gte`, `lte` |

### Safety Guards

- Actions never overwrite cells occupied by other artifacts or utilities (spawn, teleporter)
- The artifact's own cell (`offset [0,0]`) is exempt from the occupied check — pedestals can elevate the tile under the artifact
- Out-of-bounds offsets are logged but skipped
- Walkability is re-validated after all rules are applied

## Exempt Tokens

Artifacts listed in `exemptTokens` are always placed but skip rule application and conflict detection. These are visual elements with no gameplay spatial relationship:

- `dark_sphere` — void backdrop surrounding the map
- `cube_scene` — scene container

To add a new exempt token, append its `lookup_name` to the `exemptTokens` array in `placement_rules.json`.

## Current Rules

### pedestal_compact (priority 10)
Elevate tile under compact artifacts to code 2. Probability 0.6. All interaction types.

### wall_behind_compact (priority 8)
Place dark wall (code 3) one row north. Probability 0.5. All compact interaction types.

### clearance_manipulate (priority 12)
Clear floor (code 1) in front, left, right of manipulate artifacts. Probability 0.8-0.9. Compact and room_scale.

### elevated_room_scale (priority 7)
2×2 platform of code 4 under room-scale observe/manipulate artifacts. Probability 0.4.

### alcove_grab (priority 6)
Walls (code 2) behind, left, right of compact grab artifacts. Probability 0.3 each. Creates niche when multiple fire.

## Pipeline Integration

Rules run in stage 5 of the 7-stage generation pipeline:

```
Footprint → Walkability → Distribute → Spatial Design → RULES → Ordering → Entropy
```

Timing: After `disposeArtifacts()` scores and places all artifacts, after the structure fixer carves space for unplaced artifacts, but before ordering and entropy. The rules modify the structure grid in-place, then walkability is re-validated.

The pipeline UI highlights rule-modified cells with orange borders and reports: rules active, rules matched, artifacts affected, cells modified, actions skipped (probability roll or occupied cell).

## Score Bias

Rules also influence placement scoring before they run. `calculateRuleBias()` adds up to 10 bonus points to candidate positions that already match rule patterns — a cell next to a wall scores higher for an artifact whose rules want a wall behind it. This pre-biases placement toward positions where rules will be most effective.

## File Locations

- Rules definition: `commons/artifacts/placement_rules.json`
- Rules engine: `ada_encyclopedia/src/lib/game/PlacementRules.ts`
- API endpoint: `GET/PUT /api/game/placement-rules`
- Pattern extractor: `ada_encyclopedia/src/lib/game/PlacementRuleExtractor.ts`
