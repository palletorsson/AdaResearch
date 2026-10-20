# Prefab disorder — originals, parts, hybrids

One reversible slider keeps the same inventory through three arrangements. Installed in **Random_Entropy**, grid **(13, 3)**, facing the entrance; an optional tutorial encounter. Run `preview.tscn` here with F6 for the standalone desktop controls. The physical console has the same slider and rectangular buttons.

| Slider | Left table | Right table |
| --- | --- | --- |
| 0 — ORIGINAL | Four original objects | Matching original objects |
| 0.5 — PARTS | Whole objects scattered intact | Fifty mesh parts separated |
| 1 — HYBRIDS | Original objects home again | Four mixed-source assemblies |

Move continuously in either direction. The same setting returns the same poses; slider movement consumes no random draws. ORIGINAL, PARTS and HYBRIDS are precise presets. SEED +1 changes separation offsets, while the original assemblies and authored hybrid recipes stay fixed.

## Inventory and new relationships

The existing gallery scenes `cardboard_box`, `computer_monitor`, `lab_stool` and `microscope` contribute 9, 13, 14 and 14 visible meshes respectively. Each source is initially fitted uniformly to a longest dimension of 0.44 m. Both tables retain all fifty original meshes and materials. Clones do not inherit the source scripts or physics. These are authored modelling boundaries, not atoms or mechanically separable components.

`hybrid_recipe.gd` uses every part once:

- **Screen Walker:** stool feet carry the monitor face under a cardboard visor (box, CRT, stool).
- **Petal Scope:** a monitor stand and stool post carry microscope optics under three cardboard flaps (all four donors).
- **Box Observatory:** a CRT plinth supports the box with a microscope stage, light and eyepieces (box, CRT, microscope).
- **Viewing Perch:** a microscope base, CRT housing and stool seat carry a horizontal microscope column (CRT, stool, microscope).

The names suggest possible uses; they are not functional machines. Small bundles such as the screen/bezel and the stool feet retain their internal arrangement. Each completed hybrid is uniformly fitted to a longest dimension of 0.55 m. This changes its display scale, not its material. The rules join parts deliberately; stochastic separation does not spontaneously discover these assemblies.

## Experiment loop

1. Start at 0, seed 435, with both original inventories visible. Fix a viewpoint.
2. Slide to 0.5, then towards 1. Observe which old relationship disappears and which new relation begins to suggest a form or use. Reverse the slider and follow a recognisable part back.
3. KEEP an intermediate setting. Press ORIGINAL, change the seed, then REPLAY. Record an uninteresting or confusing change as readily as an interesting one.
4. Reopen the preview and REPLAY. The Output panel prints the full saved JSON path. Preserve that file, the source signature and the source modules together.
5. Reconstruct with the supplied host/modules below, comparing all part transforms with the receipt. Human independent reconstruction is still to be tried.
6. Revise one joining rule while holding the separated pose fixed—for example, what carries the screen. Save a new recipe version and record the reason. Does the new relation change what the form appears able to do?

Whole objects and mesh parts use different draw assignments and different floor bounds. This remains an exploratory comparison; a matched base-motion study is a separate pending refinement. No recognition threshold or learner response has yet been measured.

## Reconstruction contract

The supplied host is `prefab_disorder.gd` with `prefab_disorder.tscn`. It depends on `disorder_sample.gd`, `hybrid_recipe.gd`, the four source `.tscn`/`.gd` prefabs, `control_console.gd`, `hangar_kit.gd` and `RackTemplates.gd` in their existing project locations. `preview.gd` and `preview.tscn` supply only desktop framing and duplicate controls.

The small separation model retains six uint32 draws per movable unit: three translations and three Euler angles. At full separation, x is ±0.23 m, y 0–0.36 m, z ±0.20 m; each angular component is ±0.8π. It turns each unit about its bounding-box centre and corrects its height above the tray.

For slider `s <= 0.5`, separation strength is `2*s`. For `s > 0.5`, the left strength is `2*(1-s)` and the right interpolates from its fixed separated pose to its saved hybrid target with weight `2*s-1`. The right pose receives a floor correction throughout. Calculation starts from stored endpoints each time; nothing accumulates. Original and hybrid endpoints are assigned directly. Parts may intersect in transit; there is no collision-driven assembly or thermal model.

## Saved state and compatibility

KEEP writes timestamped JSON under Godot's `user://` directory; REPLAY reads the latest pointer. Schema `prefab-disorder/2` contains seed, slider, source list/signature, all raw draws, engine version, recipe version and each part's source index/key, hybrid group and twelve transform components. Replay uses the stored targets. Invalid or incompatible records are rejected before mutating the experiment.

Schema 1 records still reproduce their old separation: the old slider value is divided by two. A previous full-separation receipt therefore opens at the new midpoint. Its original geometry remains the reference. New hybrid targets come from the current recipe for that migrated record.

This geometric path has no entropy units. It does not establish thermodynamic entropy, irreversibility, material equivalence or spontaneous self-assembly. The question is what new relationships can become possible when an existing assembly loosens.

[Native captures, test results and research status](../../../doc/book/iterations/2026-10-15-prefab-hybrids/README.md). The earlier separation-only receipt remains in `2026-10-15-prefab-disorder`.
