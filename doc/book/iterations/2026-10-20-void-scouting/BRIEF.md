# Museum → Void: independent scouting trial

You are scouting, not implementing. Read this brief, `inventory.json`, `source-index.md`, and the relevant files under `sources/`. Return your report as your final response. Do not edit any files, run code, contact other agents, access accounts, change layouts, or claim runtime tests. Both Claude and Google's agent receive this same brief independently.

## Intent

The Void is the existing Endless Museum reinhabiting an unfinished skyscraper. The visitor descends through open shafts and exterior ledges. Museum artifacts must find a new architectural home: some inhabit added stages, some can become working components of the space. Think old alien technology discovered, braced, repaired and connected by construction workers: concrete cuts, mismatched steel cradles, readable service connections, strange precise operations. This is a design direction, not a claim about the artifacts' history.

Use existing artifacts, controls and algorithms. Rehousing must preserve the operational distinctions that make the tutorial and reflection meaningful. Decoration alone is insufficient. A procedural surface is not necessarily a walkable surface. Avoid turning every encounter into a locked door or inventing compulsory combat. Wonder can come from a simple repeatable operation.

Scout four maps: Random_Definition, Random_Noise_Types, Noise_Columns, Noise_One. The latter three are the current opening Noise route. Make the proposals as separate selectable trial floors, not additions to the curated tower. Each trial uses the actual Void frame. The owner will choose what to build after comparison.

## Source discipline

`inventory.json` records exact original placement strings, registry scenes, scripts and source hashes. `sources/` preserves selected source files at their repository-relative paths. This is a reading packet, not a runnable Godot project; dependencies are not complete. `source-index.md` distinguishes captured files and missing dependencies. Current source code and enabled configuration take precedence over old briefs. If a necessary file is absent, name it and leave the conclusion unresolved.

The user wants type-safe claims: separate mathematical relation, software behaviour, felt encounter, interpretation and proposal. Use these evidence labels:

- **observed-source**: supported by a cited file and symbol/line.
- **proposed-adapter**: new integration needed; no claim it already works.
- **unknown**: measurement, runtime or headset evidence is missing.

No automatically invented lineage. Not every artifact in a hall belongs to the tutorial. The reflective text, tutorial and wider field overlap. Preserve good final.md writing; identify location-dependent passages needing later review without rewriting them now. A source test result is not a Void adaptation test.

## Existing frame and editor

- 42 m wide × 18 m deep; floor-local X/Z, Y up; storeys 6 m apart; slabs 0.36 m thick.
- Shafts A/B centred at X=-10/+10, Z=0; width 5 m, depth 6 m. Keep openings, arrival, checkpoints and descent routes accessible.
- Pillar centres: X=-20,-14,-5,5,14,20; Z=-7,+7; width 0.9 m. These are fixed structural members.
- Overhead supply at local Y=4.8 m; four stations: NW[-5,-5.5], NE[5,-5.5], SW[-5,5.5], SE[5,5.5]. Source: floor_content.gd and catalog.json. Leads are currently decorative and mounts carry metadata. There is no generic live power-switching contract.
- Floors have no surrounding walls or ceiling by default. Add unfinished walls, scaffolds, braces or platforms where they support the encounter. Do not casually remove structural pillars or slab.
- Artifacts use rooms.json records: id, artifact token, station, facing (0/90/180/270), height, scale, optional position [x,z] and config. Independently editable parts/copies need actual adapter support, not merely a promise.
- Existing shared scene and room data drive desktop and VR. The web editor exports actual Godot geometry; it does not execute the interaction. Preserve move/rotate/copy/remove/save/reload in later implementation.
- Main tower files must remain untouched. Current trial example: commons/void/trials/transformation. Layout, trial registration, preview export, tests and runtime loading need checking for each new trial. The exporter may update shared part metadata; do not run it during scouting.
- Older skill rules forbidding height/ramp use before Transformation are superseded by the user's explicit Void design.

## Questions to resolve from code

1. What is each map's chosen tutorial operation, and how does it differ from its whole artifact inventory and reflective route?
2. Which seed scopes, route links, map-coordinate part poses, player adapters or global scene groups may break after relocation, duplication or streaming?
3. Can a visual body actually support a player? Separate render deformation, fixed collider and matched rebuilt collider.
4. What survives FREEZE, reset, floor unload, death and reload? Distinguish current behaviour from desired persistence.
5. Can the supply line frame a visible connection now? If actual power behaviour is desirable, define what on/off changes and what state it preserves as a proposed adapter.
6. Which existing objects become structural or spatial operations without changing their mathematics? Which need an honest stage around them?

## Output (about 1,500 words; concise and specific)

Begin with a short verdict on feasibility and the smallest first trial. Then one card per map:

**Encounter → carried knowledge → player action → invariant → new capacity → onward use.**

For each card include:

- Exact original artifact IDs and scene/script citations supporting your choice.
- A short plan: approach, reveal/comparison, exit. Give provisional floor-local [x,y,z] placements and supply stations. Label unmeasured footprints. Do not present a sketch as a verified fit.
- One staged integration and one structural/spatial integration. Name what remains the original artifact, what is a new mount, and what would need new behaviour.
- How the old alien-tech appearance makes the operation legible. Specify materials, attachment and light purpose, not vague atmosphere.
- Preserved algorithm/control/recording behaviour; coordinate-frame and lifecycle risks.
- Editor granularity: what can be moved, copied or removed together; what identity/state must remain independent or intentionally shared.
- At least two concrete acceptance tests with setup, action and expected result, including one failing variant. These are proposed tests, not passes.
- A brief disposition for remaining inventory: preserve as comparison, rehouse elsewhere, or defer with reason. Do not silently delete it.
- One implication for tutorial.md and one for final.md, keeping their different jobs.

Finish with a capability ledger: reusable mechanism, existing evidence, proposed adapter, unknown. Recommend one map to prototype first and why. Also answer: what becomes easier to understand, what does this staging foreclose, and what remains productively unresolved?

## Evaluation

We will compare source fidelity, preservation of the teaching focus, architectural integration, interaction and collision honesty, editor compatibility, lifecycle/state scope, and whether the proposed tests could falsify the claims. No credit for claiming a test ran, inventing a source, treating a decorative cable as a working power network, or making shader-only geometry silently support the visitor.
