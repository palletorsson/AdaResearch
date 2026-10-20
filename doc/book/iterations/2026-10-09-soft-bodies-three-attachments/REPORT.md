# Three places to hold a sheet

9 October 2026 · An additional ghost-student composition inside the existing Cloth hall

**21 native checks passed.** This exercise goes beyond the chapter's supplied parameter edits. It asks whether the student can reuse its sheet to pose another question about attachment.

The authoring assistant performed this rehearsal with prior knowledge of the chapter. It is not a blind second-model or human-student assessment. The earlier nine-hall run remains the evidence for all 263 supplied checks; this new run adds a composition and native images.

## Prediction and result

Keep two identical sheets. A holds its upper corners. B holds upper left, lower left and the existing vertex nearest middle right. Clear all other pins. Keep the same mesh, mass, stiffness, damping, pressure, starting orientation and height.

Both retain 112 reference positions and identical connectivity. The engine reported A's pins as [104, 111] and B's as [7, 56, 111]. These are results of coordinate selection, not hardcoded instructions. The upper-right vertex is held in A and free in B.

After 120 awaited physics callbacks, B's freed corner had moved **0.813 metres**. The largest drift at its three held points was **0.00000557 metres**, below the predicted 1 mm tolerance. The prediction specified movement, not an exact fold or distance. No material coefficient was changed to produce that difference.

The same PointBody can be grabbed with XRTools. Its trigger reconstructs the two sheets while retaining the point instance; release parks it in the transformed host. Keyboard R was also exercised through actual input dispatch. A moved and turned host retains the same local selection. The study's visitor approach has museum floor. These are synthetic input and native desktop checks, not a physical headset session.

## What this adds to the learning evidence

The new composition uses reference coordinates, a loop and nearest-point selection to choose a boundary the original exercise did not prescribe. It demonstrates that the sheet construction can support another material question. It does not establish that an unfamiliar beginner would formulate or implement that question without help.

The host, sheet and point are available in student/. The sheet and point files are unchanged from Cloth. The comparison is temporary inside the real museum; no permanent artifact, map or chapter code was changed.

## Retained failed attempt

The first checker called a PrimitiveMesh method after Godot had exposed an ArrayMesh. Execution stopped early with SCRIPT ERROR, although the generic runner printed a passing subtotal. attempt-1/ records that rejected run. The corrected checker uses surface_get_arrays(0) and refuses to pass without reaching its completion check.

The next run passed all checks. Its pictures showed a dark caption lost against the sky. Only caption colour changed for the final run, which passed again. attempt-2/ retains the earlier pictures and receipt. The attachment rule was unchanged throughout.

## Reproduce

Run inside AdaResearch_46 with its prepared museum and dependencies:

```powershell
python tools/run_encounter_probe.py SoftBodies_Cloth_Physics --sequence softbodies --render --no-bridges --output-tag ghost-three-attachments --probe tools/probes/soft_three_attachments.gd
```

Require the completed-run check and inspect both engine logs for script/parse errors; exit zero alone is insufficient. The print/step count is a numerical test interval, not a promise about wall-clock time.
