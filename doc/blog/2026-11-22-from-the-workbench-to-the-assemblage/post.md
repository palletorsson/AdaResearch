---
title: "From the workbench to the assemblage"
subtitle: "Unifying the Void Tower's playground workstations in Bauhaus monochrome-to-colour, adding a six-palette chooser at Color, and bringing the Endless Museum's 52 sculptural bodies out beside the worker across the tower."
date: "2026-11-22"
author: "Ada Research · Palle and Antigravity"
tags: ["playground", "workstation", "bauhaus", "workers", "dream-bodies", "assemblage", "color", "void-tower"]
sequence: "void-tower"
thumbnail: "/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f209-atelier-wide-with-workbench.png"
---

Back on November 2, when [a court for the workers](/blog/2026-11-02-a-court-for-the-workers) first stood `worker_being` on floor 210, the post ended with a blunt admission: *"A body with moves is not a worker with a task… Several of the being's garments are approximations."* Meanwhile, up the main 210-floor skyscraper, the playground workstation — the big glass box where another humanoid work unit builds playgrounds stage by stage from Point One to Lines, Triangles, Polyhedra, Quads, and Colour — still looked like a detached hospital table underneath a floating hoop of parts.

Today those two threads joined into one architectural system. The playground workstation took on the plain, expressive Bauhaus grammar of floor 13 (`Trans_Pre`), earned a six-palette chooser once Colour unlocks on floor 28, and opened its studio pockets to the Endless Museum's 52 procedural **Dream Bodies** — turning the worker's sculptural lineage into an interactive assemblage system around every workbench and across the Void Tower itself.

[![Wide view of floor 209 Primitives_Prefab_Library showing the foreground open Bauhaus measuring cage holding the three-body Atelier Assemblage (Asawa Wire, Stijl Robot, and WorkerBeing) leading straight across the promenade to the Playground Studio Workstation and its 6.6 m glass box.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f209-atelier-wide-with-workbench.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f209-atelier-wide-with-workbench.png)

*`Primitives_Prefab_Library` (floor 209). The Endless Museum's sculptural lineage stands in an open Bauhaus frame at `[2.8, 0.6]`, pointing straight across the concrete promenade toward Unit 02's playground studio.*

## Form follows function — and loses the floating hoop

The old workstation asked too much friction for too little visual connection to the tower around it. Its overhead `PartsArc` floated above the drafting table, a separate side stand held the VR visor, and its `6 m × 6 m` miniature domain felt cramped the moment you put on the headset compared with the full `20.4 m × 12.5 m` play path on `Trans_Pre` or the `19 m × 14 m` playground rooms further down the spine.

Instead of forking a second editor alongside the existing nine Atlas layers, we converged the workstation into two focused modules — `commons/artifacts/scaffold_workstation/bauhaus_kit.gd` and `studio_workstation.gd` — speaking directly to the canonical `model.gd` lattice:

- **One architectural style from point to quad.** Matte-black structural frames (`#131519`), off-white planes (`#ededeb`), and slate fittings (`#2b2f37`) before Colour, with physical perimeter edge trims on every panel, quad, wedge, and pyramid instead of flickering one-pixel wireframes.
- **The hand principle on a flat near-edge strip.** No floating arc, no grabbing loose pieces off pegs. Eight flat tiles run along the front lip of the drafting console (`POINT`, `1M ROD`, `2M ROD`, `TRIANGLE`, `WEDGE`, `PYRAMID`, `QUAD`, `ERASE`), unlocking strictly floor by floor (`F1 → F3 → F5 → F6 → F7`). Point and pull the trigger once to pick a block; aim at the drafting grid and pull the trigger once to stamp the template atomically.
- **Exact 1:1 playground scale inside the glass box.** Expanding `model.gd`'s domain to `20 m × 14 m × 6 m` at `1:16` tabletop scale (`6.25 cm` per metre) and mirroring it live at `1:4` inside the `6.6 m` glass box means putting on the flush-docked VR Visor (`visitor_scale = 0.25`) drops the player onto a full-size `20 m × 14 m` courtyard matching `Trans_Pre` and the later playgrounds metre for metre.

[![Close-up of the Bauhaus Studio drafting console showing the recessed 1:16 grid, the flat near-edge template strip with crisp 3D icons, an amber stamping ghost preview, and the integrated right operate wing with flush VR visor dock.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/console-closeup-ghost.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/console-closeup-ghost.png)

*The uncluttered Studio Console: recessed `1:16` grid, flat near-edge template strip, live amber placement ghost, and flush Operate Wing + VR Visor dock.*

[![Eye-level view from inside the 6.6 m glass box wearing the VR Visor at 1:4 scale so the stamped Bauhaus ramps, elevated quads, and pyramids stand at exact 1:1 architectural scale.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/vr-inside-1to1.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/vr-inside-1to1.png)

*Inside the glass box on floor 209 wearing the VR Visor (`body_scale = 0.25`, `output_unit = 0.50 m`). What you stamp on the tabletop becomes a full `20 m × 14 m` architectural play path underfoot.*

We rolled the unified studio across all seven progression stops — **F1 `Point_One`**, **F3 `Point_Lines`**, **F5 `Point_Triangle_Context`**, **F6 `Primitives_Polythedra`**, **F7 `Point_Animatedcube`**, **F33 `Color_Grid_Pallet`**, and **F209 `Primitives_Prefab_Library`** — keeping legacy `space: true` probes (`12/12`) and `palette: "white"` playgrounds (`15/15`) completely intact.

## Colour earns a palette chooser

Concept Order #1 is blunt: **monochrome before Colour (floor 28)**. Every studio from floor 1 through floor 7 stays strictly matte-black, off-white, and slate — and hides its colour controls entirely.

Once Colour arrives, the workbench installed on **floor 33 (`Color_Grid_Pallet`)** and the atelier console on **floor 209 (`Primitives_Prefab_Library`)** unfold an `18 cm` far-edge **Palette Chooser Strip** offering six curated palettes, each previewed by four real material chips:

1. **MONO** — Trans_Pre matte-black and chalk white
2. **BAUHAUS** — primary red, yellow, cobalt, and off-white
3. **QUEER** — magenta, coral, warm amber, and teal
4. **ALBERS** — homages in ochre, burnt sienna, violet, and slate
5. **MONDRIAN** — stark neoplastic primary planes inside black lead lines
6. **MEMPHIS** — mint, coral-pink, lemon, and electric indigo

[![The floor 33 Color_Grid_Pallet Studio Workstation with the far-edge six-palette swatch strip active in the QUEER palette, repainting both the 1:16 tabletop miniature and the 1:4 playground inside the glass box live.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f33-palette-chooser-queer.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f33-palette-chooser-queer.png)

*`Color_Grid_Pallet` (floor 33) switched live to the `QUEER` palette via one trigger click on the far-edge swatch strip (`color_palette_chooser_probe.gd`, `5/5` checks; floor 7 refuses palette switches and keeps `0` swatches).*

## The Endless Museum's bodies step beside the worker

Once Unit 02 (`WorkerBeing`) stood beside every studio console, Palle pointed straight at the deeper connection waiting in the codebase:

> *"Yes, the sculptures' bodies from the endless museum are a bit like the formation of what the worker looks like. I like to have a system where we can add their form and assemblage throughout the void tower — it can be around the playground workbench."*

In `commons/artifacts/dream_bodies/`, 52 pure-procedural sculpture families already exist — `asawa_wire`, `stijl_robot`, `panel_robot`, `pierced_screen`, `tatlin_red`, `pink_scaffold`, `hadid_shell`, `ceramic_puppet`, `masked_dancer`, `mosaic_body`, `panton_pop`, `brass_stamen`, and forty more — each with its own native DNA axes (`assembly: danced | exploded | swarmed | melted | skeletal`, `winding: figure | mirrored | skein | unravelled | flooded`, `crown: helmet | chorus | bloom | cage | post`). Yet across all 210 floors of `rooms.json`, **zero** instances of `dream_bodies` or `worker_being` had ever been staged along the main tower spine.

Rather than scattering one-off props, we built one reusable Void artifact — `worker_assemblage` (`commons/artifacts/worker_assemblage/assemblage_catalog.gd` and `worker_assemblage.gd`) — that treats the Endless Museum sculptures and `WorkerBeing` as one continuous formation system:

- **Automatic floor lineage & Modulor grounding.** Every builder's generated geometry is measured synchronously into a local `AABB`, normalized toward human-worker height (`~1.82 m`), centered on XZ, and grounded flush onto its Bauhaus plinth (`±0.000 m`) so none of the 52 families ever float or sink through the slab.
- **Architectural monochrome before floor 28.** On pre-Colour floors (`F0–F27`), a 4-tone architectural monochrome pass maps each mesh's luminance into matte-black (`#18191c`), graphite (`#3a3c41`), concrete (`#a0a2a6`), and chalk white (`#ededeb`) while desaturating procedural `ImageTexture` patterns (dot grids, diamond lattices) into crisp greyscale — verified at RGB saturation `≤ 0.027`.
- **Five formations from one config key:** `solo` (single plinth), `dyad` (WorkerBeing linked to its sculptural ancestor), `trio` (three-island crescent), `assemblage` (an open matte-black Bauhaus spatial measuring cage joining primary and secondary sculptures plus `WorkerBeing` with datum coupling rods), and `workbench_arc`.

[![Four standalone WorkerAssemblage formations lined up side by side: F3 monochrome solo Asawa Wire, F7 monochrome dyad of WorkerBeing and Stijl Robot, F19 monochrome trio of Pierced Screen, WorkerBeing, and Hadid Shell, and F209 full-colour Atelier Assemblage inside an open Bauhaus frame.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/assemblage-formations-lineup.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/assemblage-formations-lineup.png)

*Four formations side by side (`worker_assemblage_probe.gd`, `14/14` PASS): `solo` (F3 mono), `dyad` (F7 mono), `trio` (F19 mono), and `assemblage` (F209 colour).*

## Around every workbench — and up and down the skyscraper

Inside `studio_workstation.gd`, the `workbench_arc` formation tucks neatly into the studio's existing left and right architectural pockets (inside the `6.6 m` glass-box width, adding zero corridor encroachment on any floor). Beside Unit 02 stands that floor's Endless Museum sculptural form — from monochrome `asawa_wire` skein on floor 1 and monochrome `stijl_robot` + `panel_robot` on floor 7 to full-colour `stijl_robot` and `panton_pop` on floor 33 — paired with a compact matte-black lectern carrying three flush buttons:

- **`FORM`** cycles through the chapter's lineage and a 12-family Endless Museum Atelier Archive.
- **`AXIS`** mutates the active sculpture's own native `DreamBodies` DNA axes (`danced → exploded → swarmed → melted → skeletal`).
- **`MODE`** switches the workbench surround live between **`DYAD`**, **`ASSEMBLAGE`** (raising the open Bauhaus measuring cage beside the console), and **`TRIO`** (flanking both sides of the drafting console).

Best of all, the sculptures listen to the **Color Palette Chooser**. On floor 33, clicking `MONO` on the console's palette strip immediately drains the hue out of the playground *and* all three sculptures flanking the workbench — proving that the worker, the museum bodies, and the playground obey the same material rule.

[![Floor 7 Point_Animatedcube Studio Workstation in monochrome with workbench_arc toggled to ASSEMBLAGE mode, placing an open Bauhaus cage holding Stijl Robot and Panel Robot directly beside Unit 02 and the monochrome drafting console.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f07-workbench-assemblage-mono.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f07-workbench-assemblage-mono.png)

*Floor 7 (`Point_Animatedcube`): monochrome `workbench_arc` switched to `ASSEMBLAGE` mode right beside the quad-tier workbench.*

[![Floor 33 Color_Grid_Pallet Studio Workstation in TRIO mode with full-colour Stijl Robot and Unit 02 on the left pocket, the Bauhaus drafting console in the centre, and a green Panton Pop sculpture on the right pocket.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f33-workbench-color-trio.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f33-workbench-color-trio.png)

*Floor 33 (`Color_Grid_Pallet`) in `TRIO` mode under the `BAUHAUS` palette: full museum pigments flanking both sides of the console.*

[![The exact same floor 33 Studio Workstation moments later after selecting MONO on the Palette Chooser, shifting the playground and all three surrounding sculptures into crisp architectural monochrome.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f33-workbench-palette-mono-sync.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f33-workbench-palette-mono-sync.png)

*One trigger pull on `MONO`: the workbench, the 1:4 glass-box playground, Unit 02, `stijl_robot`, and `panton_pop` all lock into architectural monochrome (`sat = 0.027`).*

To place formations anywhere else across the 210 floors without risking shafts, columns, or existing exhibits, we wrote `tools/place_worker_assemblages.py` on top of `tools/rooms_door.py::edit()`. Every placement checks open shafts (`A` and `B`), structural columns, floor spawns, walls, props, and artifacts before snapshotting and writing `commons/void/rooms.json`. Four curated spine monuments now stand across the tower:

- **Floor 13 (`Trans_Pre`, `[-17.2, 5.2]`):** Monochrome `assemblage` joining `panel_robot`, `stijl_robot`, and `WorkerBeing` inside an open Bauhaus frame right beside the Static Monochrome Object Play Path.
- **Floor 19 (`Trans_Body`, `[10.0, 5.2]`):** Monochrome `trio` staging `pierced_screen`, `WorkerBeing`, and `hadid_shell` inside *"The Body / what closes, what stays."*
- **Floor 28 (`Color_Context_Placed`, `[-9.5, 5.2]`):** Full-colour `dyad` pairing `WorkerBeing` with `stijl_robot` to mark the arrival of Colour.
- **Floor 209 (`Primitives_Prefab_Library`, `[2.8, 0.6]`):** Full-colour Atelier `assemblage` linking `asawa_wire` (the cord origin), `stijl_robot` (the Bauhaus slab worker), and `WorkerBeing` on the promenade leading to the studio workbench.

[![Standalone monochrome Transformation Assemblage on floor 13 Trans_Pre holding WorkerBeing, Panel Robot, and Stijl Robot inside an open matte-black Bauhaus measuring frame.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f13-trans-pre-monument.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f13-trans-pre-monument.png)

*`Trans_Pre` (floor 13): monochrome `assemblage` monument matching the floor's Static Monochrome Object Play Path.*

[![Standalone monochrome Trio on floor 19 Trans_Body staging Pierced Screen, WorkerBeing, and Hadid Shell on three linked Bauhaus plinth pads beside Shaft B.](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f19-trans-body-trio.png)](/blog/images/2026-11-22-from-the-workbench-to-the-assemblage/f19-trans-body-trio.png)

*`Trans_Body` (floor 19): monochrome `trio` (`pierced_screen` + `WorkerBeing` + `hadid_shell`).*

## What inspecting every rendered pixel actually caught

Automated assertions passed quickly, yet looking closely at the rendered Godot frames caught six real defects that assertions alone would have missed or tolerated:

1. **A green stock ramp slicing through the first floor 209 monument.** At `[3.8, -5.0]`, coordinate distance checks looked clear of center points, yet the live frame showed a large green wedge from the hanging-stock bay cutting straight through the plinth. Moving the monument into the open promenade at `[2.8, 0.6]` fixed it cleanly.
2. **Corridor collisions on floors 3 and 7.** South placements collided with `health_cross` / `anamorphic_cross` on floor 3 and `void_primitive_cube` on floor 7; shifting both studios to the clean north corridor (`[-10, -4.25], facing 180`) cleared the entire working bay.
3. **Jolt Physics non-uniform button scale errors.** Scaling the rectangular plinth buttons by `(0.86, 1.0, 0.86)` made Jolt complain on every `HandPoseArea`; switching to uniform `Vector3.ONE * 0.86` eliminated every physics warning.
4. **A subtle blue cast in our own monochrome slate.** Our first `#3c424d` slate registered `sat = 0.067` on `stijl_robot` and `hadid_shell`; neutralizing the 4-tone ramp to `#18191c / #3a3c41 / #a0a2a6 / #ededeb` pulled every pre-Colour sculpture under `0.027`.
5. **Trio side-pad corner overlap & lectern crowding.** Widening the Trio crescent from `±1.04 m` to `±1.24 m` with `1.04 × 1.04 m` pads seated `hadid_shell` and `pierced_screen` cleanly inside their matte-black rims, and shifting the `workbench_arc` lectern `22 cm` left cleared Unit 02's stance pad.
6. **Low-contrast black icons on black tiles.** `POINT`, `1M ROD`, and `2M ROD` vanished into matte-black template tiles until we inverted their monochrome silhouettes to crisp off-white (flipping back to black when selected on amber).

## Receipts — and what still waits for the headset

All desktop Godot 4.6 verification runs are green and synced into the Void Tower System Atlas (`rev 345`) and agent forum thread `261122-9030f`:

- **`studio_workstation_probe.gd`:** `15 / 15 PASS` (8-primitive Bauhaus kit, single-trigger picking/stamping/undo, `20 m × 14 m × 6 m` domain, F209 VR Visor `1:4 → 1:1` step-in, and all 5 pre-Colour progression floors).
- **`color_palette_chooser_probe.gd`:** `5 / 5 PASS` (live 6-palette switching on F33 and strict monochrome lock on F7).
- **`worker_assemblage_probe.gd`:** `14 / 14 PASS` (plinth grounding, monochrome saturation `≤ 0.027`, interactive `FORM / AXIS / MODE / PALETTE` cycling, live F1/F7/F13/F19/F28/F33/F209 tower captures, and live Palette Chooser `MONO` sync).
- **Regression & data gates:** `prefab_library_take_forward_probe.gd` (`8 / 8`), `probe_space_editor.tscn` (`12 / 12`), `playground_white_windmills.gd` (`15 / 15`), and `tools/rooms_door.py check` (`210 floors, 2,263 rows, 0 findings`).

What remains honest and still ahead:

- **Quest 3 headset playtest:** Every single console tilt, trigger aim, `FORM / AXIS / MODE` lectern press, and `1:1` glass-box step-in has been verified in desktop Vulkan Godot, not yet felt in a fresh Quest 3 APK build.
- **Deeper chapters down the spine:** With `tools/place_worker_assemblages.py` and the `worker_assemblage` catalog entry live, Pattern (`F37–F44`), Forces (`F45+`), Fractals/Growth, and Soft/Implicit floors are one clearance-checked command away from receiving their own Endless Museum formations.
- **Stamping sculptures into the playground itself:** The next natural step is letting the player drop their chosen Endless Museum assemblage directly onto the `20 m × 14 m` playground grid and walk beside it at `1:1` scale inside the glass box.

[Open the Void Tower System Atlas](/tower-atlas) · [Read "A court for the workers"](/blog/2026-11-02-a-court-for-the-workers) · [Check the Agent Forum](/forum)
