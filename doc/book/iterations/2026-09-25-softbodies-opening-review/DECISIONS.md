# Soft Bodies opening — what holds a body?

25 September 2026. The user asked to jump from Fractals to Soft Bodies. This pass covers the first two halls, Soft Body Deformation and Cloth Physics. The existing cloth pilot supplies the central encounter; the work here makes its comparisons clearer and repairs the opening cube's presentation.

## Writing decisions

- **Keep the question of compliance.** The cube distinguishes resistance to deformation from damping. The cloth distinguishes a material response from the conditions holding it. The question “how much belongs to the object, and how much to the arrangement holding it?” remains central.
- **Let one comparison finish.** In Cloth, remove the apparent support, change eight held points to two, then release them. Rebuild before changing stiffness. The earlier ordering changed stiffness midway and then claimed the material settings had stayed the same.
- **Keep the surprise, narrow the absolutes.** The gantry can disappear without unpinning the cloth. Gravity still acts. Releasing six points lets an edge sag; it does not stop being an edge. REBUILD makes fresh hanging strips, without the unverified claim that no other control could ever suspend a fallen point.
- **Restore the surface/volume distinction.** The cloth is open; the cube encloses a volume. Keep that difference concrete before discussing pressure. The skin paragraph now asks what the surface keeps when inflation no longer helps it, rather than guaranteeing a particular drape over a pedestal.
- **Keep the hand asymmetry, identify its conditions.** The museum's base rig explicitly selects TELEPORT mode for both collision hands. The component also has COLLIDE mode. The text names a choice in this rig, rather than a necessary law of every virtual hand. The incorrect “rounded body two halls on” forecast is removed; that encounter is five halls later.
- **Move implementation qualifications out of the way.** The cube uses five solver passes, but other artifacts use other counts. Stiffness is not simply the fraction of a spring error corrected per pass. Godot Physics adds bending links as well as triangle-edge links. Relevant specifics belong in the footnote and technical companion. Code excerpts and artifact anchors remain verbatim.
- **Keep the falling-body encounter honest.** A visitor may arrive before its timers fire. The rail has width and does not guarantee that a body remains on top of it. In these native captures much of the surface reaches the floor. LANDING changes the receiving geometry and starts another fall; stopping still raises damping/stiffness rather than preserving an exact vertex snapshot.

## Artifact decision: an explicit attachment

The first native cube capture showed the actual free body leaving its small pedestal during the control sequence. Parameter callbacks worked, but that did not make the encounter readable. Several receiving-tray trials also failed: thin floors, different rims and separate collision pieces did not reliably retain the body. Their images and reports remain in the diagnostic directories. No tray is installed in the final map.

The opening hall now selects `jelly_cube:180:1.0#anchor:crown`. A single point nearest the centre of the top face is held. An open stand and brass stem expose that attachment; the old pedestal is absent in this variant, so the hanging surface does not pass through a display plate. The local rack sits lower and further forward, and the caption says that one upper point is held. There is no new interface or solver.

This is a deliberate boundary condition, stated in the opening paragraph. The cube lets the reader vary response while the held point stays; the following cloth lets them vary the held set. Ordinary unconfigured cube placements keep the original unpinned body and pedestal. The failed free-contact trials are not being passed off as repaired. Free soft-body contact with small receiving structures remains a separate development question.

## Evidence and limits

The original native PNGs were captured inside the actual isolated museum. Each probe uses an isolated plan and output files. The live plan rebuilt during work, growing from 199 to 206 records; the latest version is retained. Its stale tray setting for this cube alone was synchronized to the final anchor setting. The two owned hall records are otherwise unchanged, and no save was rewritten. The initial cube probe stopped the museum before deferred exhibits had drained; the final probe explicitly finishes the existing stamp queue. Those initial diagnostic failures remain separate from the final report.

The final cube run checks the map opt-in, exactly one pinned point, the stem meeting that point, independent coefficient controls, RESET retaining the same body, ten further seconds of bounded motion, the unchanged free default and the mill drive. The cloth run checks eight strips of 112 points, stable pins after removing the support, eight → two → zero pins, fresh REBUILD, stiffness with the rebuilt edge held, and LANDING restarting the fall into pans. Six released top points move by up to about 0.15 m in the sampled interval; the pinned set remains still when the frame disappears.

The controls receive supplied pointer events through their existing event path. These are not tracked-hand, mouse-ray aiming, physical reach, comfort, Quest performance or learner-acceptance tests. The hand paragraph has source evidence, not a new headset contact test. Existing UID and renderer/environment warnings are retained in `engine-warnings.json`. Final assertion counts and process results are available beside this record.

The cube before/after support photographs have different framing, identified in their captions. Each cloth pair and each final cube state pair uses a fixed camera. Cube states come from one sequential experiment, not matched fresh-start trials; no quantitative material inference is drawn from their difference.

## Sources and preservation

Source checks use the installed map, jelly cube, workshop, cloth, falling-body and XR hand implementations. Engine details were checked against the [Godot 4.6 SoftBody3D reference](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html) and [Godot Physics soft-body implementation](https://github.com/godotengine/godot/blob/4.6-stable/modules/godot_physics_3d/godot_soft_body_3d.cpp). The earlier [cloth pilot assessment](../2026-09-23-cloth-pilot-review/ASSESSMENT.md) supplied corrections which had not all reached the manuscript.

Both canonical final.md files and their technical companions are updated. The whole nine-hall capture is refreshed. Two core review links and digests are refreshed while roles and acceptance statuses remain. The review queue keeps its existing 21 done / 1 open decisions; this pass does not re-certify them. The critical essays, remaining seven chapters, all placements except the cube's anchor opt-in, remain. The concurrently rebuilt live plan is retained, with only its cube configuration synchronized to the final map. No commit.

Next: the carousel. Follow the change from a fixed attachment to a moving support, with particular attention to what the body can actually experience.
