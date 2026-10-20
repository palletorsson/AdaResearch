# What keeps a pattern changing?

**Soft Bodies 8/9 — Reaction–diffusion.** The earlier CA lesson already supplied a reaction function. This hall opens it, while retaining the field, its neighbour rule and the PointBody interaction.

|Part|Before|Now|
|---|---|---|
|Tutorial|Three isolated formula lines and descriptions of controls|Three complete runnable files with a predicted local step, matched comparison and independent edit|
|Lineage|CA's supplied reaction left implicit|Return to the same two fields; explain conversion, supply and removal|
|Comparison|Different exhibits could be mistaken for matched runs|A and B share initial conditions, neighbour exchange and step count; only local terms differ|
|Numerical scope|Stencil differences unstated|Learner keeps four neighbours; installed display uses eight weighted neighbours|
|Reflection|Mostly repeated technical explanation, code and unverified long-run claims|What needs to continue for a difference to persist; resemblance and biological claims distinguished|
|Room|Small horizontal field; desk blocked arrival and sat apart|Desk beside the field, large upright display of the same live texture, supported frame and local light|

## One focused operation

At each address, conversion removes U and adds V. Supply replenishes U. Removal takes V away, with feed contributing to that removal as well. The comparison holds neighbour exchange in both fields, enabling these local terms in A and initially disabling them in B.

At W=(15,15), all neighbours initially match. The first update is therefore predictable without computing diffusion: A changes from (0.5,0.25) to (0.48725,0.257), while B stays at (0.5,0.25) at that address. B still changes at the patch boundary. The learner can then compare the different consequences after 1,000 equal steps.

Enabling B's local terms restarts both fields; they agree exactly again. The same carried black sphere plants a patch in both fields. It changes their state, not their rule or clock. The independent edit raises feed to 0.050: the student predicts U = 0.49375 and V = 0.25375 at W before looking at the later picture.

The original CA behaviour is retained when all terms are enabled: at 100 steps, the maximum array difference is 0.0. The learner's code keeps the old four-neighbour discretization. The installed hall's eight-neighbour stencil and different rate pair are described explicitly. They are related demonstrations rather than interchangeable numerical evidence.

## A field you can read from the desk

The desk moves from (15, 3) to (8, 6), beside the existing generator. A 3.7 m square screen shows the very same ImageTexture as the tabletop. This changes the presentation without another solver, clock or pattern generator. The other artifacts and the sequence order remain.

The wall capture shows the installed Stripes preset after 1,000 updates from the centre seed. Its name does not guarantee stripes at that moment. The small patch, surrounding conditions and elapsed steps matter. The old text's twelve-cell seed is corrected: the actual 32 × 32 hall field begins with a 6 × 6 square, 36 cells.

The compact two-field learner is temporarily mounted inside the museum at (15, 0, 18), yaw 180°, for the images and tests. It is the student's construction beside the encounter, not another permanently registered exhibit. Its clock/comparison controls are keyboard-driven; planting uses the existing desktop/XR pickup interface. The installed desk retains its VR controls.

## Tested claims

**33 code checks and 38 native museum checks passed.** Exact visible source is extracted and executed in native Godot 4.6/OpenGL. Checks include analytical predictions, wrapping, synchronous update order, the earlier model, display pixels, actual keyboard dispatch, synthetic XRTools targeting under a transformed host, the feed edit and four deliberately faulty programs. The faults reverse conversion, omit supply, update in place, or reset only the clock; each is detected.

The museum checks operate all six controls with the desktop pointer, advance ten actual hundred-step batches, verify shared texture identity and held time, run both learner comparisons and the complete independent edit, and sample floor support and capsule clearance. The larger display and before/after arrangement were inspected in native images from above and eye level.

These checks support the program's claims. They do not establish physical headset comfort, Quest performance or a human student's understanding. Existing UID/renderer warnings remain; final runs have no script/parse errors. Initial test-fixture issues concerned dummy-renderer texture inspection and placing a rigid-body host after initialization; final tests use native rendering and correct scene-entry order. The learner code did not need repair for those fixture issues.

Next: **Morphogenesis — a field becomes a surface.**
