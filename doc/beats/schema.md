# Beats — the layer between sequence and map

_Drafted 2026-05-17 after the question "is there a level above maps where we can say what we're teaching, freely letting maps express that?"_

## Why this layer

The curriculum's *intent* and the curriculum's *manifestation* are different things. Right now they're collapsed: every author intent ends up encoded inside a map, and `intent.md` carries the prose while `map_data.json` carries the cells. This makes it impossible to:

- Declare a beat that has *no map* (a deliberate pause)
- Declare an *anti-pattern beat* (a map whose role is "show the wrong thing")
- Declare a *bleed* (content from another phase visible here, on purpose)
- Audit the curriculum's *argument* without auditing the maps
- Have *multiple maps express one beat* (two ways to land the same moment)

The beat layer fixes this. It sits *between* the sequence (~10 maps, single topic) and the map (one room).

Analogues in other traditions:

| domain | unit above | beat-equivalent | unit below |
|---|---|---|---|
| theatre | act | **beat** (smallest unit of dramatic action) | scene-staging |
| music | section | **measure** | played notes |
| game design | level | **moment** (Half-Life, Souls) | room geometry |
| Alexander's patterns | building | **pattern** | wall / window / alcove |
| Ada (current) | sequence | **(missing)** | map |
| Ada (with this) | sequence | **beat** | map |

## Schema

A sequence's beats live at `commons/maps/sequences/<seq>.beats.json`. The file is a JSON object with `_meta` and `beats[]`.

### `_meta`

```json
{
  "schema_version": "beats/0.1",
  "schema_doc": "doc/beats/schema.md",
  "sequence": "<sequence_id>",
  "phase": "<phase_name>",
  "description": "<one paragraph about this beat score>"
}
```

### Each beat

```json
{
  "id":           "<unique_id_within_sequence>",
  "role":         "<beat role — see vocabulary below>",
  "concept":      "<one sentence — what the player is meant to encounter>",
  "register":     "<teaching | exploring | resting | refusing | synthesizing | catalyst | structural | reflecting>",
  "intensity":    "<high | medium | low>",
  "maps":         ["<map names that express this beat>"],
  "bleed_from":   ["<other sequence IDs whose content shows through here>"],
  "bleed_to":     ["<other sequence IDs that this beat foreshadows>"],
  "note":         "<free-text author note>",
  "next":         "<id of the beat that follows, or null>"
}
```

Most fields are optional; only `id`, `role`, and `concept` are required.

## Beat role vocabulary

Eighteen beat roles in five families. **Use the closest match; if none fit cleanly, the role is missing from the vocabulary — extend the catalogue.**

### Teaching beats (advancing the curriculum)
- `INTRODUCE` — first encounter with a concept
- `DEMONSTRATE` — concept shown in action
- `PRACTICE` — player walks / performs the concept
- `VARIATE` — show the range of the concept
- `LIMIT` — show where the concept breaks down
- `SYNTHESIZE` — combine with previous beats / concepts

### Exploring beats (player driving)
- `WANDER` — free exploration, no specific teach
- `PAUSE` — explicit rest, no new content; can have `maps: []`
- `BLEED` — content from another phase / sequence is visible here, on purpose
- `ANTI` — show what the wrong version looks like (anti-pattern)
- `REFUSE` — the conscious negation of the concept

### Structural beats (curriculum scaffolding)
- `GATEWAY` — transition between phases or sequences
- `CHAMBER` — synthesis moment, often catalyst-flavoured
- `CRISIS` — confrontation with a contradiction
- `REFLECT` — look back on what was learned
- `CATALYST_GAIN` — the catalyst itself is the lesson

### Special
- `META` — a beat about the curriculum itself (rare; for self-referential sequences)

## Registers

Beats have a *register* — the affective key the beat is played in. Two beats of the same role can have different registers (an `INTRODUCE` in `teaching` register vs `refusing`).

- `teaching` — driving forward, advancing the concept
- `exploring` — letting the player wander
- `resting` — pause, breathing room
- `refusing` — conscious negation, anti-pattern
- `synthesizing` — composing previous beats
- `catalyst` — catalyst-specific (pickup, mode-switch, etc.)
- `structural` — scaffolding, transition
- `reflecting` — look back, awareness

## Relationship to maps

A beat's `maps[]` list is the *expression* of the beat. Constraints:

- A beat may have `0` maps — declared intent without manifestation (legitimate for `PAUSE`, sometimes `GATEWAY`, occasionally `BLEED`)
- A beat may have `1` map — the common case
- A beat may have `N` maps — multiple expressions of the same intent (e.g., two adjacent maps that together land a `SYNTHESIZE`)
- A map may appear in `0` beats — *orphan*; flagged by audit; either assign to a beat, add a beat for it, or remove from the sequence
- A map may appear in `>1` beats — *multi-purpose*; the map carries several intents (legitimate for chamber maps, atrium maps, hub maps)

## Relationship to bleeds

Curriculum arcs are not isolated. The `bleed_from` / `bleed_to` fields make this explicit:

- `bleed_from: [<seq>]` — content from `<seq>` shows through HERE. Example: `Primitives_Animatedcube` has `bleed_from: [transformation, oscillation]` because motion (oscillation) and movement (transformation) are *previewed* before they've been formally introduced.
- `bleed_to: [<seq>]` — this beat foreshadows `<seq>`. Example: the `Point_Line_Grid` beat has `bleed_to: [array_tutorial]` because the grid IS an array.

The audit can check **bleed symmetry**: if `primitives.P7.bleed_from = [transformation]`, then somewhere in `transformation.beats.json` there should be a beat with `bleed_to` mentioning `primitives` — otherwise the bleed is one-sided.

## Author conventions

- Beat IDs follow the sequence's prefix + ordinal: `P1`, `P2`, `T1`, `WV1`, etc.
- The `next` field forms a linear chain by default; nonlinear beat structures (branches, loops) extend the schema.
- Keep `concept` to one sentence; details go in `note`.
- The orphan list is *legitimate* — it captures maps in the sequence that haven't been beat-assigned. Don't suppress; surface them.

## Authoring workflow

1. Open the sequence's `beats.json` (create if missing).
2. List the curriculum's intended moments — what should the player encounter, in what order?
3. For each moment, pick the closest beat role + register + intensity.
4. List the maps that already express that moment (if any). Keep `maps: []` if no map yet.
5. Add `bleed_from` / `bleed_to` for any moment that openly references another phase.
6. Run `python tools/beat_audit.py --sequence=<seq>` to check coverage.
7. Iterate: orphan maps need a beat (or removal); unfilled beats need a map (or acceptance as empty intent).

## What this enables

- The curriculum's *argument* is queryable as data — not as prose buried in `intent.md`.
- The catalyst arc (FOE → FRIEND across the spine) is a sequence of `CATALYST_GAIN` beats — can be audited.
- The DNA gallery commitments are *beat decorations*, not map metadata.
- The biome state belongs to the *beat's register*, not the map's metadata.
- The audit can ask *was this map necessary, and if so, for what?*

## Status

This is `beats/0.1` — a sketch. The vocabulary will extend as authors find missing roles. The first sequence to use it is `primitives` (`commons/maps/sequences/primitives.beats.json`).

If after using it on 3-4 sequences the schema feels right, we lift it to `0.2` and consider it stable.
