# Prefab disorder — originals, parts, hybrids

One reversible slider keeps the same inventory through three arrangements. Installed in **Random_Entropy**, grid **(13, 3)**, facing the entrance; an optional tutorial encounter. Run `preview.tscn` here with F6 for the standalone desktop controls. The physical console has the same slider and rectangular buttons.

| Slider | Left table | Right table |
| --- | --- | --- |
| 0 — ORIGINAL | Four original objects | Matching original objects |
| 0.5 — PARTS | Whole objects scattered intact | Fifty mesh parts separated |
| 1 — HYBRIDS | Original objects home again | Four mixed-source assemblies |

Move continuously in either direction. The same setting returns the same poses; slider movement consumes no random draws. ORIGINAL, PARTS and HYBRIDS are precise presets. SEED +1 changes separation offsets **and** the hybrid memberships, joining order, attachment faces and turns. Four display pads remain; their forms are generated from the seed. The original assemblies stay available at 0. KEEP a form before exploring another seed.

## Inventory and new relationships

The existing gallery scenes `cardboard_box`, `computer_monitor`, `lab_stool` and `microscope` contribute 9, 13, 14 and 14 visible meshes respectively. Each source is initially fitted uniformly to a longest dimension of 0.44 m. Both tables retain all fifty original meshes and materials. Clones do not inherit the source scripts or physics. These are authored modelling boundaries, not atoms or mechanically separable components.

`seeded_grafts.gd` divides the inventory into fifteen small bundles. A screen retains its bezel, a stool base retains its feet, and optics retain their local assembly. Each source's bundles are shuffled among the display pads with a local seeded generator. Every hybrid receives box, CRT and microscope parts; three also receive a stool bundle. Every mesh is used exactly once.

Within a hybrid, the seed chooses bundle order, quarter turns, an attachment face and a small sideways offset. The builder tries bounded joins without overlapping bundle bounding boxes, then falls back to stacking above the highest bundle if needed. A final uniform fit gives each completed form a longest dimension of 0.55 m. Labels identify HYBRID A–D and their donors; the displayed seed identifies the variant. The names of yesterday's four authored models appear only when replaying those earlier records.

This is a seeded assembly grammar, not a physical joint solver. Contact between bounding boxes does not guarantee contact between every visible surface or mechanical stability. The authored bundle boundaries and joining rules constrain what can appear, while the seed varies the resulting assemblies. Original geometry and materials remain; display scales may change with the new fit.

## Experiment loop

1. Start at 0, seed 435, with both original inventories visible. Fix a viewpoint.
2. Slide to 0.5, then towards 1. Observe which old relationship disappears and which new relation begins to suggest a form or use. Reverse the slider and follow a recognisable part back.
3. At HYBRIDS (1), press SEED +1 to compare new forms with the stage and viewpoint fixed. KEEP several interesting arrangements, then open GALLERY to compare them side by side. Each entry includes all four forms, its seed and its slider stage. Also try KEEP at an intermediate stage. Record an uninteresting or confusing change as readily as an interesting one.
4. Select REPLAY 1–4 beneath the corresponding gallery entries to recover that arrangement at full size. PREVIOUS/NEXT browse additional pages; BACK returns without changing the live experiment. Reopen the preview and use GALLERY again: the collection persists. The Output panel prints each saved JSON path. Preserve those files, the gallery index, the source signature and the source modules together.
5. Reconstruct with the supplied host/modules below, comparing all part transforms with the receipt. Human independent reconstruction is still to be tried.
6. Compare two saved seeds at stage 1. Which part changes roles, and does a different apparent use arise? A later code intervention can revise one bundle or joining rule while holding the separation record fixed. Save a new recipe version and record the reason.

Whole objects and mesh parts use different draw assignments and different floor bounds. This remains an exploratory comparison; a matched base-motion study is a separate pending refinement. No recognition threshold or learner response has yet been measured.

## Reconstruction contract

The supplied host is `prefab_disorder.gd` with `prefab_disorder.tscn`. It depends on `disorder_sample.gd`, `seeded_grafts.gd`, `hybrid_recipe.gd` (legacy recipes and transform codec), `gallery_store.gd` (persistent index), `kept_gallery.gd` (comparison and selection), the four source `.tscn`/`.gd` prefabs, `control_console.gd`, `hangar_kit.gd` and `RackTemplates.gd` in their existing project locations. `preview.gd` and `preview.tscn` supply desktop framing and duplicate controls. Other host features retain their declared local modules.

The small separation model retains six uint32 draws per movable unit: three translations and three Euler angles. At full separation, x is ±0.23 m, y 0–0.36 m, z ±0.20 m; each angular component is ±0.8π. It turns each unit about its bounding-box centre and corrects its height above the tray.

For slider `s <= 0.5`, separation strength is `2*s`. For `s > 0.5`, the left strength is `2*(1-s)` and the right interpolates from its fixed separated pose to its saved hybrid target with weight `2*s-1`. The right pose receives a floor correction throughout. Calculation starts from stored endpoints each time; nothing accumulates. Original and hybrid endpoints are assigned directly. Parts may intersect in transit; there is no collision-driven assembly or thermal model.

The assembly generator uses a separate local RNG seeded by the first fifteen hex digits of SHA-256 of `str(seed) + "|seeded-grafts/2"`. It never consumes separation draws or the global RNG. Repeating the same seed with the same source and generator rebuilds the same targets. KEEP stores the resulting targets directly, so replay does not need to rerun the generator.

## Saved state and compatibility

KEEP writes timestamped JSON under Godot's `user://` directory and adds it to `prefab-disorder-latest-gallery.json`. The gallery index has schema `prefab-hybrid-gallery/1` and stores paths to those complete records; keeping another arrangement does not replace older entries. Schema `prefab-disorder/2` contains seed, slider, source list/signature, all raw draws, engine version, recipe version (`seeded-grafts/2` for new variants) and each part's source index/key, hybrid group and twelve transform components. Replay uses the stored targets. Invalid or incompatible records are rejected before mutating the experiment.

GALLERY shows four saved sets at a time, with PREVIOUS/NEXT for further entries. A set retains all fifty parts, uniformly fitted to a smaller tray for comparison; this display fit does not alter its saved transforms. REPLAY 1–4 restores the selected entry at full size. The main REPLAY button then returns to that selected entry until another entry is selected or kept. After reopening, main REPLAY uses the latest KEEP pointer; older entries remain selectable in GALLERY. BACK preserves the current live arrangement.

On first opening after the upgrade, the previous latest KEEP joins the gallery automatically. Other old record files are left in place. Missing or incompatible entries show UNAVAILABLE without changing the experiment; an unreadable index is retained rather than overwritten. The gallery is local to this Godot user-data folder. Only the four visible entries allocate preview meshes; older pages remain as records on disk.

Schema 1 records still reproduce their old separation: the old slider value is divided by two. A previous full-separation receipt therefore opens at the new midpoint. Its original geometry remains the reference. Its later hybrid stage uses the legacy fixed recipe. Schema 2 records with `four-grafts/1` keep their saved targets, old labels and recipe identity when kept again. Pressing SEED +1 after either kind of legacy replay switches to the new seeded generator.

This geometric path has no entropy units. It does not establish thermodynamic entropy, irreversibility, material equivalence or spontaneous self-assembly. The question is what new relationships can become possible when an existing assembly loosens.

[Gallery captures, persistence/replay tests and research status](../../../doc/book/iterations/2026-10-16-hybrid-gallery/README.md). The seeded assembly receipt remains in `2026-10-16-seeded-hybrids`; earlier separation and fixed-hybrid receipts remain in `2026-10-15-prefab-disorder` and `2026-10-15-prefab-hybrids`.
