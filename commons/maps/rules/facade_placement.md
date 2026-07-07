# Facade placement rules

_Drafted 2026-05-14, after the facade_assembly rebuild taught these rules through image-experience._

Rules for placing the `facade_builder` artifact in maps so the existing 42-part FacadeComposer system (`commons/facade_parts/`) renders correctly. Codifies what was learned across the 8-map facade_assembly build so the next map can be authored from these rules alone — no per-change image feedback required.

The image-feedback loop stays alive for **deriving new rules**, not for verifying each change once the rules cover the case.

## R1 — Dispatch syntax

Place a single `facade_builder` token in a map's `interactables` layer:

```
"facade_builder:<rotation>:<scale>#plan_path:<absolute_resource_path>"
```

- `<rotation>` is degrees (0, 90, 180, 270). Most maps want **180** so the facade faces a back-centre spawn.
- `<scale>` is a uniform scale multiplier; **1.0** for canonical-size facade.
- `<plan_path>` is the full `res://` path to a v2 preset JSON in `commons/facade_parts/presets/`.

The interactables parser at `commons/grid/GridInteractablesComponent.gd:1234` uses `split(":", false, 1)` for each `#key:value` config part, so `://` in the path survives intact.

Alternative dispatch (no plan_path):

```
"facade_builder:<rotation>:<scale>#preset:<built_in>"
```

Where `<built_in>` is one of the five in `facade_builder.gd`'s `PRESET_DEFS`: `classical`, `gothic`, `palazzo`, `arcade`, `minimal`. Use this when you want player-composable variation rather than a fixed preset.

## R2 — Tag → preset lookup

The `actualization_tag` in a map's `intent.md` (the `Actualizes:` field) determines the preset to dispatch:

| tag | default preset | alternates |
|---|---|---|
| `canonical` | `classical.json` | `palazzo` (built-in) |
| `dramatized` | `baroque.json` | `bernini_colonnade.json` |
| `hybridized` | `venetian_gothic.json` | `gothic_portal.json` |
| `surfaced` | `naples_diamond_rustication.json` | `florence_marble.json`, `florentine_polychrome.json` |
| `modularized` | `nyc_tenement.json` | `superstudio_grid.json` (also fits `refused`) |
| `refused` | TWO dispatches: `superstudio_grid.json` + `memphis_totem.json` | `continuous_monument.json`, `decon_fragment.json` |
| `synthesis` (chamber) | `#preset:classical` (no plan_path) | any built-in |

The 26 preset JSONs in `commons/facade_parts/presets/` cover all single-actualization tags. The two-dispatch `refused` case is the only one that needs two facade_builders in one map.

## R3 — Room dimensions per tag

The facade_builder's default geometry is **15m wide × 12m tall** (configurable via `facade_width` / `facade_height` config keys). Room dimensions in cells (where one cell = 1m) should:

- give the player at least **3-4 cells of standing room** between the facade plane and the spawn
- not be so wide that the facade reads as a small fragment against a vast floor
- match the actualization-tag's pedagogical shape

| tag | width × depth × height | rationale |
|---|---|---|
| principle (intro) | 8 × 6 × 2 | small dense in the spirit of `Geometric_1` |
| canonical | 10 × 6 × 3 | baseline; canonical comparison set |
| dramatized | 11 × 6 × 3 | slightly wider for syncopation rhythm to read |
| hybridized | 10 × 6 × 3 | **same as canonical**; the substitution is in the vocabulary, not the scale |
| surfaced | 10 × 6 × 3 | same as canonical/hybridized; surface variation, not scale |
| modularized | 8 × 6 × 5 | **narrow + tall** — vertical repetition IS the lesson |
| refused | 12 × 7 × 3 | **asymmetric** — refusal also refuses the symmetric room |
| synthesis (chamber) | 6 × 6 × 3 | intimate; smallest |

## R4 — Standard placement template

For single-facade maps:

```
structure:    all cells filled (e.g., "2" or "3" — solid floor)
utilities:    spawn at (row=depth-1, col=floor(width/2))
              teleporter at (row=3, col=width-1)  [side-front exit]
interactables: facade_builder at (row=1, col=floor(width/2))
                  with rotation=180, scale=1.0, plan_path=<preset>
                science_screen at (row=depth-1, col=1)  [back-side text panel]
```

Rationale: the player spawns at the back facing forward; the facade composes at the back of row 1 (just inside the structure); the side-front teleporter routes the player along an oblique exit path; the text panel sits near spawn for orientation.

## R5 — Two-refusal layout (Critique only)

For maps tagged `refused`:

```
dimensions:    12 × 7 × 3  (asymmetric on purpose)
spawn:         (row=3, col=floor(width/2))  [centred, not back-centred]
teleporter:    (row=depth-1, col=width-1)  [far corner — breaks symmetric path]
facade #1:     row=1, col=floor(width/2), rot=180, plan_path=superstudio_grid.json
facade #2:     row=depth-2, col=floor(width/2), rot=0, plan_path=memphis_totem.json
science_screen: (row=3, col=1)  [side panel, not back]
```

The two refusals face inward; the player stands between them; the asymmetric exit refuses the canonical exit-at-front pattern.

## R6 — intent.md schema for a facade map

Required paragraphs and their content:

```
Concept: <3-5 sentences naming what the facade composes and what the actualization-mode says>

Actualizes: Facade_Assembly_Principle, in the <tag> mode. <1 sentence on what position in
            the virtual field this map takes — which axes are at canonical values, which
            are pushed/substituted/refused.>

Sequence role: <2-3 sentences placing this map in the facade_assembly walk order.
                Reference what comes before and after.>

Technical angle: <2-3 sentences naming the existing system invocation:
                  "Dispatches facade_builder with plan_path=<preset>. The preset uses
                   <named-parts-from-part-catalog>. Composed by FacadeComposer at the
                   front edge of a <width>×<depth> room.">

Critical angle: <2-3 sentences on what the actualization argues, including what it refuses
                 or what choice it makes that other tags would have made differently.>

Key artifacts:
- facade_builder dispatching to commons/facade_parts/presets/<preset>.json
- science_screen for orientation text

Gap: <intentionally empty — the facade is composed, the text is authored, the map walks.
      No queued architectural primitives. Use this field for genuine remaining gaps only.>
```

The `Key artifacts:` and `Gap:` fields are the ones that previously drifted (the text described primitive artifacts that didn't exist while the map dispatched `facade_builder`). The rule fixes this: **`Key artifacts:` lists what's literally placed; `Gap:` is empty unless something is genuinely missing.**

## R7 — blurb.md shape

A blurb is **3 short paragraphs**, total ~150-220 words:

- **Paragraph 1:** name what the player walking in sees first — concrete architectural elements that read at a glance.
- **Paragraph 2:** name the *actualization mode* (clean / dramatized / hybridized / etc.) and what it argues with the principle.
- **Paragraph 3:** what the player carries forward — the relation to the next map or the principle's broader teaching.

No mention of architectural primitives that don't exist. No mention of "queued for pass-4 build" or similar. Describe what the FacadeComposer actually composes.

## R8 — When to capture for verification

Capture is needed when:

- The preset is **new** (never used before in this rule set)
- The room dimensions are **outside R3's ranges**
- The placement is **outside R4 or R5 templates**
- A **new actualization-tag** is being introduced that doesn't fit the existing seven

Capture is NOT needed when:
- The map matches a template with a known preset
- The room dimensions are within R3
- Only the intent.md prose is changing

The captures verify that *the rule's prediction held*. They do not verify the map. The maps are already valid by construction if the rules hold.

## R9 — What the rules don't cover (yet)

These cases still require image-feedback:

- Lighting/ambient palette match between map and preset material (warm cream for Italian, terracotta for tenement, achromatic for modern critique)
- Preset selection within an alternates list (when multiple presets fit a tag, which one)
- Asymmetric layouts beyond the two-refusal case
- Maps mixing facades with other artifact families (catalysts, hazards, ecology)
- The Pompeii-interior subset (10 presets) — different from the wall-facing facades, may need different room shapes

These are the regions of the virtual where new rules need to be derived. Future image-experience sessions on these cases produce R10+ rule extensions.

## R10 — Stamp procedure

Given:
- `name` (e.g., `Facade_Florence_Marble`)
- `tag` (one of the seven)
- `preset` (optional override; defaults from R2 lookup)
- `room_size` (optional override; defaults from R3 lookup)
- `relationship` (per R12 — one of `canonical`, `append`, `sibling`, `replace`)

Steps:
1. Look up dimensions per R3 from tag, or use override.
2. Look up preset per R2 from tag, or use override.
3. If `tag == refused`, use the two-dispatch layout from R5. Otherwise use R4.
4. Write `map_data.json` per the template, filling in spawn/teleporter/facade_builder cells.
5. Write `intent.md` per R6, with the five paragraphs.
6. Write `blurb.md` per R7.
7. Update the sequence file per R11.
8. Skip capture unless R8 conditions trigger it.

The result is a working map in ~10 minutes of authoring rather than ~45 minutes of compose-capture-iterate.

## R11 — Sequence-file update

A stamped map must be wired into its sequence's JSON or the audit will not see it. Specifically, edit `commons/maps/sequences/<sequence_id>.json` and:

1. Add the map name to `sequences.<id>.maps[]` in the chosen walk position (per R12 below).
2. Add a one-line content entry to `sequences.<id>.content[]` in the matching position.
3. Add an `artifact_groups[]` entry naming the placement layout:

```json
{
  "map": "<MapName>",
  "position": "<intro|foundation|exploration|integration|synthesis>",
  "artifacts": ["facade_builder"],
  "size_budget": "environment",
  "rationale": "<sentence naming actualization-tag and preset>",
  "stamp_meta": {
    "rule_file": "commons/maps/rules/facade_placement.md",
    "actualization_tag": "<tag>",
    "preset": "<preset_filename>",
    "relationship": "<canonical|append|sibling|replace>"
  }
}
```

The `stamp_meta` block is optional but recommended — it lets future stampings know this map was rule-derived and how it relates to the sequence's canonical walk.

## R12 — Relationship-to-sequence declaration

When a stamped map is added to a sequence that already has maps, declare its relationship explicitly. The four options:

| relationship | meaning | maps[] effect | walk effect |
|---|---|---|---|
| `canonical` | the map IS the sequence's representative for its tag | inserted at the tag's canonical position | replaces any prior map at that slot |
| `append` | the map walks alongside an existing same-tag map | appended adjacent to the sibling in maps[] | player walks both, in order |
| `sibling` | the map exists in the folder + sequence but is not in the canonical walk | added to maps[] with `not_in_walk` flag (or in a `siblings[]` array if the sequence schema supports it) | player must explicitly seek it |
| `replace` | the map replaces an existing same-tag canonical map | the prior map is moved to `siblings[]` or removed | the new map becomes canonical |

**For surfaced-tag alternates (Naples diamond vs Florence marble vs Florentine polychrome):** the default is `append` — surface-axis variants benefit from back-to-back walking so the range becomes visible.

**For two-actualization-of-the-same-tag conflicts (e.g., two canonical Renaissance facades):** use `replace` and demote the prior. Don't accumulate noise.

**For experimental variants outside the curriculum's pedagogical arc:** use `sibling` so the sequence's canonical walk stays short and clear.

The relationship is recorded in `stamp_meta.relationship` per R11 so future audits can reason about the sequence's structure.
