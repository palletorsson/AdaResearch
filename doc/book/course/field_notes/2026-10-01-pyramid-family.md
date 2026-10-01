# Field note: the pyramid family in Point_Animatedcube

1 October 2026. Observer: Claude (session claude-edges-pilot), working from the repository and from captures; Palle Torsson asked for the pilot and decided at two forks. Nothing here was walked by a body in a headset.

This note follows the format in Palle's QFEP method handoff (1 October 2026): a configuration, a bounded intervention, an observation, a decision. It keeps the trials that went wrong.

## The apparatus

- **Scene.** `commons/maps/Point_Animatedcube/map_data.json`, a hall of the primitives sequence, 19 by 14 cells in the working tree. The map and its texts carried another session's uncommitted changes throughout; the committed version is 13 cells wide.
- **Two ways the hall is built.** The grid lane (`commons/grid/GridInteractablesComponent.gd`) loads a map as its own scene. The museum lane (`commons/scenes/endless_museum.gd`) builds the same hall inside the museum and has its own token parser.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an RTX 3070.
- **What I could see.** Headless scripts that call the real parser and build the real scene; the map capture (`commons/testing/capture_multi_angle.gd`, five fixed cameras); museum proof shots (`--em-shot`, iso view); the pathfinder (`tools/map_pathfinder.py`). A headless run draws no frames, so every picture came from a windowed run.
- **What I could not see.** Whether a visitor notices the family, or reads the five as one work. No headset, no walk.
- **Revision.** Baseline at `e81141cc9`. Consolidated at `9eebe2e14`.

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

One pyramid stands at cell (8, 11) with the token `pyramid#base_sides:8`. The hall's notes call it "the eight-sided pyramid". The registry declares the axis `base_sides` with the values 3, 4, 5, 6, 8, and the measurement behind the pilot said: 44 of 46 course chapters have a work with a declared axis standing in their halls, and 8 of 204 spine halls show one as a family.

**Question.** If the four other values stand beside it, does the hall show a family?
**Prediction.** Yes: five pyramids with five different bases, in both lanes.

### T1. Reading the parser (parent T0, status: branch)

Before placing anything I read how the grid lane takes a token. `#base_sides:8` is a config part with two pieces, the second a number. The parser treats that as shorthand for "tutorial id, rotation" unless the key is in `CONFIG_PARAM_NAMES`. `base_sides` was not in the list.

**Prediction, from the code.** The grid lane does not give this pyramid eight sides.
**Decision.** Follow. **Reason.** If the existing pyramid is not what its token says, a family built the same way would be five copies of one mistake.

### T2. First measurement, and it was wrong (parent T1, status: continue)

A headless script passed five tokens to the real parser, set the result on a pyramid and read the pyramid back.

**Observation.** The parser returned `config = { base_sides: true }` and `overrides = { rotation_y_degrees: 8.0 }`. The pyramid read back `base_sides = 4`, with no mesh.
**What I concluded, and told Palle.** The pyramid stays four-sided and turns 8 degrees.
**Another cause, found by reading `pyramid.gd`.** The script read the pyramid in the same frame it was added, before `_ready` had run. The value 4 was the default, not the result. The code turns `true` into 1 and clamps to 3.
**Decision.** Retest with a frame between adding and reading.

### T3. Second measurement (parent T2, status: consolidate)

**Observation.** Built from what the parser returned, the pyramid has `base_sides = 3`, 12 mesh vertices, turned 8 degrees: a tetrahedron. The museum's plan for the same cell holds `config: { "base_sides": "8" }`, a string, which the pyramid turns into 8.
**So.** One token, two bodies: a tetrahedron in the grid lane and an octagon in the museum. Nothing had failed loudly. The hall's text describes the museum's body.

### T4. Listing the key (parent T3, status: consolidate)

**Intervention.** One line: `base_sides` added to `CONFIG_PARAM_NAMES`.
**Prediction.** The five tokens build 3, 4, 5, 6 and 8 sides with no rotation; a plain `pyramid` is unchanged.
**Observation.** 12, 18, 24, 30 and 42 mesh vertices, rotation 0.0; plain `pyramid` 4 sides, 18 vertices. As predicted.

### T5. The family, first placement (parent T4, status: branch)

**Intervention.** Four tokens on the free cells left of the pyramid: `pyramid#base_sides:3`, `:4`, `:5`, `:6` at x = 4 to 7 on row 11, so the row reads 3, 4, 5, 6, 8.
**Prediction.** Five pyramids in a row; the route to the exit unchanged.
**Observation.** The pathfinder passed, 210 of 266 cells reachable. The map capture showed five pyramids. The museum built all five and printed `[em-seal] pyramid seals 1 cell(s) — the route is severed`.
**Another cause, considered.** That message might have been there already, from the single pyramid.

### T6. A comparison that was not one (parent T5, status: continue)

To find out, I built the hall in the museum from the live plan, expecting the old state.

**Observation.** The same message, and the museum packed 20 works, not 16.
**What that showed.** The museum reads this hall from the map when it builds, not from the plan. There was no "before" to be had this way: both runs saw my five pyramids. This is a fact about the apparatus, and a useful one: a family placed in a hall's map reaches the museum with no regeneration.
**Decision.** Reason about the cells instead. The row across z = 11 sits one cell in front of the back wall. Behind it, between the row, the wall, a crate and a pillar, are four floor cells. They can be seen. Nothing can get to them.

### T7. Against the wall (parent T5, status: consolidate)

**Intervention.** The four new pyramids moved to row 12, against the wall; the existing one stays at (8, 11).
**Prediction.** The severed-route message for the pyramid disappears.
**Observation.** It disappeared. Two such messages remain, for works that were there before (`polyhedron_nets_cube`, `station_crates`). Pathfinder: 210 of 266 again. The map capture and the museum shot both show five pyramids.

### T8. Widening (parent T4, status: consolidate)

**Question.** Is the pyramid the only one?
**Intervention.** A probe that reads every registry file, builds a token for every declared axis whose values are all numbers, and runs it through the parser.
**Observation.** 46 numeric axes; 29 misread. A scan of every map for tokens already using one of those keys with a number found one case: `ca_rule_explorer#rule:90` in `CA_Introduction` and `CA_AgentsCircuits`. The parser returned `rule = true` and a rotation of 90 that replaced the 180 and 270 written in the tokens. The explorer turns `true` into 1.
**So.** In the grid lane those two halls ran Rule 1, not Rule 90, facing the wrong way. In the museum they ran Rule 90.
**Decision (Palle).** List the keys and commit. **Reason.** Each unlisted key would misread the day a family is placed on it.
**Observation after.** 28 keys listed; 46 checked, 0 misread; the two tokens carry `rule = "90"` with their own rotation; the three halls pass the pathfinder; `CA_Introduction` loads and captures with no script error.

## What was observed, what was concluded, what is guessed

- **Observed.** The parser's output for each token before and after. The mesh vertex counts. The museum's messages. The pictures.
- **Concluded.** The two lanes disagreed about one token because they parse it differently. The first row fenced off four cells. The museum builds this hall from its map.
- **Guessed.** That nobody noticed the tetrahedron because the museum is what gets walked and reviewed, and the grid lane is what tools and captures use. I did not check who has looked at which.

## Unresolved

- **The pathfinder did not see the pocket.** It reported 210 of 266 reachable for both placements. Either the four cells were already counted unreachable for another reason, or the pathfinder does not treat a 0.6 m body on a 1 m cell as blocking. I did not find out which.
- **One message for five pyramids.** The museum reported a severed route for one pyramid, not five. I take it to be the one whose sealing closed the pocket. That is an inference from the cells, not from the museum's code.
- **The pyramids look different in the two lanes.** Solid orange in the map capture, red-edged and open in the museum shot. I did not look into why.
- **Four of the five are partly hidden** in the map's iso capture, behind the top of the wall they stand against. The museum's iso view shows all five. Whether a standing visitor sees a family or a row of similar things is not known.
- **The hall's texts** still say "the eight-sided pyramid" and its `artifacts.md` lacks four rows. That hall is being revised by another session; the forum thread 261001-znjou tells them.
- **The grid lane ran Rule 1 in two CA halls** for an unknown time. Whether any capture, probe result or sentence in those halls' texts describes Rule 1's picture as Rule 90's was not checked.

## The decisions, in one place

| at | decision | by | reason |
|---|---|---|---|
| T1 | follow the parser | Claude | a family built on a misread token would repeat the mistake |
| T2 | retest | Claude | the reading was taken before the body existed |
| T5 | do not settle on the first row | Claude | the museum reported a severed route |
| T7 | settle on the wall | Claude | no pocket, and the walkway is in front of the family |
| T8 | widen from one key to all numeric axes | Palle | each unlisted key fails the same way |
| T8 | consolidate: commit | Palle | the pilot and the gate are worth keeping |

## Replay

Run on 1 October 2026 at 11:55, at `9eebe2e14`.

```
godot --headless --path . --xr-mode off --script res://commons/testing/probe_numeric_axis_keys.gd
```

Result: `46 numeric axes checked, 0 misread`, exit 0. The five-token probe (`probe_family.gd`, in the folder beside this note) built 3, 4, 5, 6 and 8 sides again. A fresh museum shot of the hall differs from the saved one on 0.20% of pixels; I take that to be the moving sky behind the hall and did not confirm it.

The state before the fix cannot be replayed from the working tree. To see it, run the same probe at `9eebe2e14^`: it reports 29 misread, and `probe_family.gd` prints the tetrahedron on its first line.

## Evidence

- Beside this note, in `2026-10-01-pyramid-family/`: the three probe scripts and the lines they printed, before and after.
- Pictures: `ada_encyclopedia/captures/ada-run/course-field-notes/2026-10-01-pyramid-family/` (the map capture and the museum shot, first placement and final).
- The commit: `9eebe2e14`. The forum thread: 261001-znjou.

## For the hall's own notes

A section the hall's owner may take into `commons/maps/Point_Animatedcube/field_notes.md`:

> ## The pyramid was a tetrahedron in one build (2026-10-01)
>
> `pyramid#base_sides:8` gave eight sides in the museum and three in the grid map, turned 8 degrees: the grid read the number as a rotation because the key was not listed. Fixed in 9eebe2e14. The pyramid now stands with its family, 3, 4, 5, 6 against the back wall and 8 where it was. A first row one cell forward fenced off four floor cells that could be seen and not reached.
