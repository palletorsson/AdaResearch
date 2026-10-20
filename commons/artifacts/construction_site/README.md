# Reusable construction props

Five floor-origin scenes available throughout The Void. Find them in the lab editor's **Prefab props** tab, with picture cards, search and categories. Choose a prop, then click the floor. Move, rotate, copy or paste them between floors; saving writes `commons/void/rooms.json`, shared by desktop and VR. Restart The Void to load that arrangement.

| Palette item | Scene | Placement envelope, metres | Runtime |
|---|---|---|---|
| Tripod work light | `work_light.tscn` | 1.22 × 1.96 × 1.12 | Twin lamp heads, one warm spotlight with 9 m range. Front is -Z; rotates with the prop. |
| Scaffold with blue tarp | `scaffold_tarp.tscn` | 3.22 × 3.50 × 1.34 | Open front faces +Z; solid deck, side braces and rear tarp. Subtle pinned-edge shader motion. |
| Unfinished stud wall | `unfinished_wall.tscn` | 3.60 × 2.90 × 0.86 | Partial plasterboard, exposed studs, support feet and leaning offcut. Sheet faces +Z. |
| Striped folding barricade | `striped_barricade.tscn` | 0.95 × 1.10 × 0.94 | Timber A-frame, hinges, orange-white boards on both sides. Open space between the rails. |
| Chain-link fence panel | `chainlink_panel.tscn` | 3.50 × 2.76 × 0.16 | Pipe frame, diamond wires, centre rail and diagonal brace. Thin collision across the wire panel. |

Dimensions above are conservative editor placement envelopes, not standard product specifications. All five use `collision: parts` in the Void catalog: no invisible full-size collider fills the scaffold, stud or barricade gaps. The fence's fine mesh blocks passage through its panel. Existing container/crate collision remains unchanged.

`stock.gd` batches static geometry by material. The original three prefabs export four mesh surfaces each, including the separate animated tarp. The barricade uses five surfaces / 2,096 triangles; the fence uses three surfaces / 7,224 triangles. Its wire and the barricade's stripes are actual geometry, without transparent textures. The lamp contributes one shadowed local light; copying many lamps will increase rendering cost. The existing floor streamer hides lights and props when the floor sleeps. No CPU cloth simulation or transparent cloth is used.

The browser shows geometry exported from these actual Godot scenes, with a static tarp. Lighting and motion run in Godot. These are environmental props; adding them does not change tutorial subjects or the reflective text.

The full palette has 16 props. Alongside these five scenes, it exposes the existing blue wooden barricade, warning tape, steel crowd barrier, traffic cone, workbench, pallet, concrete barrier, temporary fence, container, crate and point-light switch. Both the palette's blue barricade and the Point Lines assembly say **DO NOT CROSS**. The original barrier's interaction behaviour remains in its source scene. `tools/probes/export_void_editor.gd` exports the actual models and renders every palette thumbnail; the pictures are not illustrative placeholders.

Verification: `python tools/test_void_site_props.py --capture` stages real dependencies, tests native desktop and synthetic XR traversal, checks open/solid collisions, copied placement and floor streaming, and captures the Mobile renderer. Then `python tools/export_void_editor.py` updates the browser models. Run these sequentially because they share the staging project.

## Barricade and fence references

The new scenes are procedural Godot interpretations of `models/props_wasteland/barricade001a.mdl` and `models/props_c17/fence01a.mdl`. The locally installed Garry's Mod spawn icons and model bounds informed their shape and approximate proportions. No Source model, mesh or texture is included or required at runtime. They are static environmental barriers, not pickup objects.

`python tools/test_void_barriers.py --capture` checks the two new props through the real Void factory: geometry bounds, material batching, solid/open/outside collision and copied, rotated, scaled instances. It captures temporary specimens inside the tower and verifies that the saved layout stays unchanged. The editor GLBs come from these same Godot scenes. Physical headset appearance remains a manual check.
