# Move the centre

<!-- museum-placement:start -->
## Museum placement

**Placed outside the main route.** Ribbon_Randomness_02, TestMap_Unused_12

[Placement overview](/book-review/doc/book/iterations/2026-10-09-one-arcade-four-operations/placement.html). Checked against map placements and current route configuration; this is not a new headset test.

<!-- museum-placement:end -->

A six-limbed creature replaces the old abstract cluster in the `omoss` artifact. Its three eyes, tail, skeleton and skin are generated in Godot. The body is an experiment prompted by the user's Albert Omoss reference, not a reconstruction of his method.

## Try it

Grab the pink sphere beside the console. It moves the creature's centre of rotation and scale through a bounded proxy. ROTATION and SCALE act on the whole body; LIMBS changes the local bone poses. RUN animates the same body, BONES reveals the hierarchy through translucent skin, CENTRE returns the pivot, and RESET restores the original pose and stops motion.

Open `algorithms/randomness/proceduralrandomness/geometrybased/omoss/preview.tscn` and press F6 for the separate review room with the project's desktop player. The production artifact remains in `Ribbon_Randomness_02`, a non-spine authoring gallery. Its placement was raised one metre because the old floor blocked the console. No tutorial or reflective sequence was rewritten.

## What changes when the centre moves?

Moving a whole-body pivot changes the path of an intact body. Changing a bone's local rotation, scale and centre deforms the weighted skin. The exhibit separates these operations so the distortion can be inspected and reset. Its mesh is generated once; later frames change the poses, not the original vertex buffer.

There are 25 bones, 3,344 vertices and 6,400 triangles. Inverse bind transforms and vertex weights connect the mesh to Skeleton3D. The torso and limb roots overlap; this is not a watertight single surface. This version uses skeletal animation. A physics ragdoll, joint forces and creature collision are not implemented.

## Images and evidence

The clean comparison images are native Godot captures of the same production artifact inside its optional review room. Ecosystem modulation is disabled for those captures. Gallery images show the existing, still crowded authoring space. Neither set is an AI-generated concept image.

All 28 checks pass in Godot 4.6: registry loading, bind transforms, weights, rest shape, pivot invariance, local deformation, unchanged source mesh, reset, controls, desktop pointer targeting/buttons and simulated XRTools pickup, movement and release. Headset interaction and Quest performance have not been tested. The logs retain unrelated startup UID/audio warnings and a Jolt solver-bias warning; these checks do not certify the entire gallery or project.

The native receipt and logs are in `validation/`. Exact artifact and probe snapshots are in `source/`, with SHA-256 hashes in `source/manifest.json`. The live implementation and registry remain the editable sources.
