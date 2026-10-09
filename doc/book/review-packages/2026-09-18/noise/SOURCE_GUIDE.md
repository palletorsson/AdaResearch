# How to read Ada Research as a spatial, implemented book

Review branch: https://github.com/palletorsson/AdaResearch/tree/palm-scanner-door-entry

The local working branch has the same name, but includes uncommitted changes. The supplied text snapshot and spatial index describe that working copy. A missing file on GitHub may be unpublished local work. State which version supports each finding. The GitHub page was not accessible through the preparer's web tool; remote parity has not been verified.

## The chain to follow

**Spine → sequence → hall → placed artifact → registry → scene → script → observable encounter → book passage.**

`res://` means the Godot project root, which is the repository root: `res://algorithms/arrays/row_3_x.tscn` is `algorithms/arrays/row_3_x.tscn` on GitHub.

The map path is **commons/maps/<MapName>/map_data.json**, not common/map. Case matters in repository URLs.

| Question | Inspect |
|---|---|
| Where does this chapter belong? | `commons/maps/curriculum_spine.json`; sort the spine entries by `order`. |
| Which halls form the chapter? | `commons/maps/sequences/<sequence>.json`, usually `sequences[sequence].maps`. |
| What is the current book passage? | `commons/maps/<MapName>/final.md`. |
| What other thinking already exists? | That folder's `technical.md`, `tutorial.md`, `critical.md`, `intent.md`, `summary.md`, `blurb.md`, where present; these can be older than the current map. |
| What is placed and where? | `map_data.json`: `map_info`, `layers`, `settings`, `utility_definitions`. |
| What is primary, supporting or decoration? | `commons/data/artifact_roles.json`: map-specific `roles` and `order`; also manuscript artifact anchors. |
| What does an artifact lookup resolve to? | Search the keys and `lookup_name` values in `commons/artifacts/registry/*.json`; follow `scene`, and any delegation/configuration fields. |
| What constructs its form and behaviour? | The `.tscn` scene's script resources and child scenes, then their `.gd` scripts and loaded resources. |
| How does this grid become a museum hall? | `commons/data/map_authored.json`, `tools/em_map_halls.py`, `commons/scenes/endless_museum.gd`; generated `ada_run/em_plan.json` and export fallback `commons/data/museum/em_plan.json` when available. |

## Read the grid in plan, not as an artifact list

For the two-dimensional map layers, **`layers.<layer>[z][x]`** names a cell. The outer list advances along z; the inner list advances along x. Y is vertical. A cell is an anchor, not the complete footprint of whatever is placed there.

- **structure:** numeric strings usually encode stacked grid structure; `0` is no grid column, `1` the base floor, and larger values taller columns. There are also symbolic wall/platform forms such as `w` and `p`. Inspect the structure parser for exceptional values.
- **interactables:** artifact lookup tokens and instance configuration. Empty cells are not artifacts.
- **utilities:** a separate vocabulary including spawn, teleport, ramps and moving platforms. Resolve through `commons/grid/UtilityRegistry.gd` and `GridUtilitiesComponent.gd`; a utility can be central to the lesson even though it is not an artifact-registry entry.

At the grid level, x and z spacing derives from `cube_size + gutter`. Do not assume a stored height of 1 means a prop stands at world y=1. `GridCommon.surface_world_y()` accounts for centre-origin cubes: a unit floor cube centred at zero has its top at 0.5. Placement overrides, automatic grounding, scene-local offsets and the museum's enclosing transform also matter. Treat a calculated position as source-derived, not a measurement of the running hall.

A raw token such as `pattern_machine_a:90:0#lesson:shared_recipe` retains an instance's orientation, vertical override and lesson configuration. The colon grammar has legacy variants and heuristics: never assume every numeric suffix is the same kind of transform. `GridInteractablesComponent.gd` parses it. Hash configuration can be passed through metadata and `apply_grid_config`; inspect what the receiving script actually reads.

Some families have special dispatch, including `gridagent:<tier>` and `mc:<id>`. The spatial index supplies a **lookup hint**, not a replacement parser, and retains the complete raw token. Missing registry candidates mean “inspect dispatch,” not automatically “missing object.”

## Read an artifact as something constructed and used

The registry description is a lead, not proof. A scene can contain almost no geometry because `_ready()` generates everything. Conversely, a scene's mesh may not be its collision shape.

For each primary encounter, trace:

1. **Construction:** what meshes, materials, labels and collision bodies are made; their local bounds and scale.
2. **Configuration:** exported defaults, map overrides and when deferred setup applies them.
3. **Action:** which actual button signal, pickup/contact event, pointer, hand movement or locomotion provider changes state.
4. **Consequence:** what value changes, what is redrawn, what moves physically, what persists, and what resets.
5. **Spatial dependency:** what the action needs from neighbouring floor, walls, supports, other artifacts or the player.

Follow referenced helpers. A button's presence is not evidence that its callback is connected. A texture changing is not evidence that collision changes. A named parameter is not evidence that this particular instance uses it.

### A small worked example

In the current local `Array` map, `row_3_x` is anchored at x=3, z=6 and `grid_2d_4x4#notation:plate` at x=3, z=12. Resolve `row_3_x` in `commons/artifacts/registry/arrays.json`, then follow `res://algorithms/arrays/row_3_x.tscn` and its script. The name says “3,” but the current lesson contains four positions: count construction loops rather than interpreting names as measurements.

Read the passage after `<!-- @row_3_x -->` in `Array/final.md`. Compare its claim about contact, disappearance and the retained array entry with the actual pickup signal and data update. Do the same for `<!-- @grid_2d_4x4 -->`, including the map's `notation:plate` configuration. The physical difference between a label attached to a departing cube and a plate left at its address matters to the prose.

Anchors such as `<!-- @token -->` connect passages to artifacts. `<!-- @ -->` ends a tagged passage or returns to the hall-level voice. An artifact can occur more than once in a hall; retain each instance's coordinates and configuration. Primary means part of the reading path, not a complete census of the room.

## The endless museum is an additional transformation

The source grid and the assembled museum are related but not identical. Read `map_info.museum`: wall-height thresholds, explicit floor cells, simulation staging, placement policy, plinths, openings and clear regions can change how the map is received. A source zero is not sufficient evidence of a visible museum pit. A portal utility need not retain standalone-level behaviour inside the museum.

The museum can use live grid construction, map-derived plans, saved placements and generated bake/cartridge records. Different lanes use different parts of the source. Check the current hall's route and configuration before inferring which lane applies. A saved plan's existence is not proof that it is current or that a body can traverse it.

For a useful spatial reading, sketch a labelled top-down plan from the layers: entrance, exit, heights/supports, primary anchors and likely viewing positions. Draw an intended encounter route separately from a verified walkable route. Consider objects' extents and motion envelopes, not just whether anchor cells are empty. A plan cannot establish occlusion, reach or comfortable movement by itself.

## Evidence to return

For each useful finding, return:

**Hall · artifact instance (x,z and raw token) · passage quotation · exact source file/function · evidence type · proposed next action.**

Use these evidence types:

- **TEXT:** what the manuscript says or fails to explain.
- **SOURCE:** what the inspected code and this instance's configuration support.
- **CAPTURE:** what a dated image actually shows, with camera/view if known.
- **HYPOTHESIS:** an interpretation or inferred spatial problem.
- **RUNTIME TEST:** a question needing execution, a walking test or a headset.

Example: “The passage asks the reader to carry this cube. Its source removes it on player contact. Propose revising the action to ‘approach and collect’; confirm the current scene uses that script.” This is more actionable than “make the room more interactive.”

**Do not claim to have played, tested or felt an artifact from reading it.** You can still give strong feedback: expose a mismatched action, locate the missing explanatory step, identify two artifacts that support a useful comparison, or propose a specific experiment grounded in an existing mechanism.

The attached spatial index contains current map layers, placements, role orders, registry candidates and file hashes. Use it with the frozen text packet. Optional dated Godot captures help establish what a view looked like; they do not validate interaction or supersede a later source change.
