# Tiling relations encounter audit — 2026-09-19



Scope: Tutorial_Pattern, Array_Patterns and Symmetry_Seventeen. Apply REVIEW_PRINCIPLES.md to the received 2026-09-18 review and GLANCE.md. These are mature chapters with targeted encounter mismatches. Preserve the final manuscripts, tutorials, room geometry and supporting works. A runtime-discovered cage burial is repaired through its hall-local mounting height.



## Decisions



- Tutorial_Pattern: the passage “The names can wait until you have found the difference” gives the asymmetrical source a useful first comparison. The two wall panels already keep independent P1/PM rules while the shared source remains editable. The semantic headings TRANSLATION / REFLECTION supplied the answer before the comparison. Keep the P1 / PM identifiers, six operations and source/receiver architecture; remove only those expanded heading names. The manuscript names and explains the operations after comparison. No reveal control is needed.

- Array_Patterns: the corner supports the chapter's question about where surface counting begins. The entrance sign “EACH FACE STARTS ITS OWN GRID” answered it before entry. Keep FOLLOW AN ADDRESS and replace its second line with an invitation to follow a line to the corner. The inspector, complete-cell selection, independent face mappings, raised traversal and secondary brick comparison remain intact. The later manuscript and tutorial still state the result.

- Symmetry_Seventeen: the source draws an amber circle, five blue permitted-order markers, two red excluded-order markers and text. It does not enumerate planar symmetry combinations or prove completeness. Correct the cage comment, plate and its copied registry description to name the periodic planar lattice assumption and the limit of the diagram. Preserve the interactive P1/PM/PG editor, HOLD, source editing, its later-stage descriptive labels and the manuscript's explicit mathematical caution. The sequence objective belongs to the root review; recommendation sent: compare the three operations and distinguish the lattice rotation restriction from the full classification.



- Runtime-discovered cage placement: the current map token `wallpaper_cage:0:0` centered its diagram at floor height; the initial low diagnostic image showed its lower half buried. Raise only that token to `wallpaper_cage:0:1.1`. The backing bottom is now 0.73 m above the floor. The complete diagram can be seen from a 1.65 m standing camera, and a capsule fits at the approach. Dimensions, geometry and neighboring artifacts stay unchanged.

- Runtime-discovered secondary gallery lifecycle: `_add_overlay` assigned five meshes world positions before adding them to the tree. Under a translated parent this produced five incorrect positions and five transform errors in a focused fixture. Move each `add_child` before its `global_position` assignment. The repaired overlay fixture passes all six checks (five positions plus child count). The hall rerun then isolated the same bug in two `_build_ceiling` assignments, producing 750 remaining errors; its three ceiling cubes and one floor cube also failed under the translated parent. Correct those two assignment orderings as well. The combined fixture passes 11/11 after both repairs. Stand-in behavior is unchanged. A final hall run checks error suppression and the existing comparison approach.
- Correct only stale ordinal phrases in intent.md: Tutorial Pattern is third, Array Patterns fourth and Symmetry Seventeen fifth in the existing eight-hall sequence. No surrounding intent rewrite. There is no new runtime reveal system.



## Evidence and recovery scope



TEXT: current final.md, tutorial.md and intent.md for all three halls; frozen review and glance retained unchanged. SOURCE: current map placements; fixed_motif_lesson.gd and its station opt-in; tunnel_address_lesson.gd and machine opt-in; symmetry_compare_lesson.gd and vr_tile_editor opt-in; wallpaper shader and CPU WallpaperGroups implementation; wallpaper_cage.gd, registry metadata and existing probes. Original source and SHA-256 are preserved in before-source/ and before-source-sha256.json.



The arrays hall's pattern_tile_brick is an explicit chapter anchor; original tiles, mirrors and weaving works remain placed. Tutorial_Pattern keeps the recovered supporting tile/weave exhibits. Symmetry retains its supporting mills, looms, tile puzzle and cage. None needs to be removed or promoted to repair the verified timing/claim mismatch. No claim is made to have verified every secondary renderer.



The cage claim was checked against the [IUCr account of crystallographic restrictions](https://it.iucr.org/Ab/ch8o1v0001/) and [IUCr Volume A plane-group tables](https://it.iucr.org/Ab/). They distinguish the permitted rotation orders from the seventeen plane-group classification. The diagram's inability to establish completeness is source inspection, not a new mathematical proof.



## Runtime verification



Copied existing museum probes, routed to local output folders and paired views. Runs use Godot 4.6, rendered mobile/Vulkan, XR off and Dummy audio. No shared museum code or global preference edits are made. The runner records the shared museum hash before and after each process, command, PID, return code and timing. Original probe logic is reused for actual pointer events, source pixels, held texture independence, physical shape casts and route support. Additions check undo after RESET and the hiding of a PM/PG difference by a uniform source.



### Results and evidence qualification



The initial `before/` runs completed the artifact checks (42 motif, 50 tunnel, 42 symmetry) and rendered images, but each also logged seven dependency script/compile errors from the concurrent `em_detail.gd` fit_card issue. They are retained as initial diagnostic evidence, not a clean full-museum baseline. Root repaired the dependency separately; no shared museum or detail code was changed by this scoped work.



The fresh `after/` runs have no script or compile errors: 42/42 motif, 50/50 tunnel, 45/45 symmetry including raised diagram and standing approach. A final `after-inspection/` symmetry run passes 46/46, adding a closer standing caption view and body clearance check. All return codes are zero. Their preserved logs still report shader-cache write warnings (`_save_to_cache`, 8/5/28 respectively) under this environment; these did not prevent rendered captures or pointer/physics checks. We do not silently equate zero probe failures with a warning-free engine run.



A clean before-source reconstruction is captured separately in `clean-before/`: fresh Godot processes compile the preserved original lesson scripts, place them in the process-local Resource cache before museum loading, and replay the original cage mounting height in memory. The production files are never reverted. For the cage snapshot, the duplicate `class_name` declaration is omitted when compiling it; its visual and behavior source is otherwise unchanged. This is explicitly reconstructed baseline evidence, not an independent old project build. Fixed camera positions, target, FOV and image size are saved alongside each PNG. Shared museum and detail hashes are recorded in the replay runner. All three replays pass with no script/compile errors: 45/45, 53/53 and 49/49 (each includes three original-script compilation checks). The shared source hashes stay stable during each replay and final inspection. The replay helper now also loads the preserved pre-repair gallery script, so rerunning it after the gallery fix retains the original gallery placement (one additional compilation check, also omitting the duplicate gallery `class_name`).

`image-pairs.json` gives six exact-camera pairs: motif headings, tunnel invitation, cage standing view and cage closer inspection. Camera position, target, FOV and 1600x1000 viewport match in all six. These are unedited Godot renders. The nearby gallery animation is not phase-locked, so its incidental pixels can vary. The close original standing view contains no readable cage because its floor-height plate falls below the frame at that 1 m approach; it must not be described as an old/new caption comparison. The wider standing pair shows the old plate and buried top at the bottom of frame and is the preferred before/after placement comparison. The low initial `before/wallpaper_cage.png` diagnostic shows the half-burial directly but has a different, 0.15 m camera height. Two additional pairs compare the intermediate live gallery placement with its final repair. Images were inspected: the repaired cage caption is readable in the close view, its whole diagram clears the floor, and panel/tunnel orientation cues remain visible.

- [Tutorial original reconstructed](clean-before/fixed_motif_bay.png) / [repaired](after/fixed_motif_bay.png)
- [Tunnel original reconstructed](clean-before/tunnel_address_bay.png) / [repaired](after/tunnel_address_bay.png)
- [Cage original standing reconstruction](clean-before/wallpaper_cage.png) / [repaired standing](final/wallpaper_cage.png)
- [Cage original closer reconstruction](clean-before/wallpaper_cage_close.png) / [repaired closer view](final/wallpaper_cage_close.png)

`changes.json`, `diffs/`, `scope-validation.json` and `preserved-manuscripts.json` isolate this pass from the existing dirty worktree. Nine source/metadata files changed. The six final/tutorial manuscripts are byte-identical to their starting snapshots. No room structure or artifact inventory changed; the only map-token placement change is the cage height; gallery world positions are also repaired in source. Scoped Git diff whitespace check and JSON parsing passed. Reports and changed sources validate as UTF-8.



### Other retained runtime diagnostics

`runtime-log-inventory.json` records the full categories instead of hiding engine failures behind successful assertions. Pre-repair Symmetry hall runs produce 8,445 `get_global_transform` errors from the secondary `wall_pattern_gallery.gd`: 7,695 from `_add_overlay` and 750 from ceiling/floor creation in `_build_ceiling`. These nodes received global positions before joining the tree. The repeated cause was repaired in those two methods after focused failing/passing fixtures. The retained initial and intermediate logs establish why both steps were necessary. The complete final hall run is recorded separately in `final/`; `after-overlay-fix/` preserves the intermediate result with 750 remaining errors. Missing UID `uid://rwex60pqapc`, root-certificate read failure, viewport-texture messages, mobile-renderer feature warnings, test-panel temp-write failure, and occasional exit leaks also remain in the preserved logs. The original and repaired primary comparisons still execute and render; these diagnostics prevent calling the entire museum error-free. No global flags were changed to conceal them, and unrelated diagnostics remain recorded for separate investigation.

### Final gallery result

The final `final/` Symmetry run passes 46/46 and exits zero with no script/compile or `is_inside_tree` errors: the original 8,445 transform errors reduce to 750 after the overlay method repair and zero after the ceiling/floor orderings are corrected. The translated-parent fixture passes 11/11. The repaired gallery places its authored bright pattern on the actual surrounding wall/floor faces; the background is consequently more patterned than the displaced pre-repair version. Both current final views were inspected: the primary editor and full cage remain visible, and their tested body approaches remain clear. No finish/curation change was added merely to suppress that authored secondary work. Other engine/environment diagnostics listed above remain.

## Limits



These are scripted desktop rendering and physics probes, not learner or headset tests. Captures can establish what appears at a fixed camera; they cannot establish that an unprompted visitor discovers the relation, notices the corner seam or finds the approach comfortable. Learner verification remains false. The cage still presents a diagram, not an interactive derivation, and the other numerical wallpaper renderers remain outside this bounded comparison.

