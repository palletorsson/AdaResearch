# Move the Centre

The registry key `omoss` now creates a six-limbed creature with three eyes and a tail. All geometry, bones and skin weights are generated in Godot. This is an experiment prompted by Albert Omoss's transforming bodies, not a reconstruction of his technique or a copy of his figures.

## Run

Open `preview.tscn` in this folder and press F6 for a quiet museum review room with the project's desktop player. The artifact itself is `omoss.tscn`; it is also placed in `Ribbon_Randomness_02`. That gallery is outside the current curriculum spine. Neither the spine order nor the Randomness lessons were changed.

## Touch

- Grab the pink sphere. It is a reachable proxy for the pink pivot inside/near the creature. One metre of proxy movement represents 1/0.7 metres of pivot movement; the result is limited to a 0.65 m radius.
- ROTATION turns the whole creature around that centre. RUN adds a slow turn and animates the limbs.
- SCALE changes the whole body's size around the same point.
- LIMBS changes local bone rotation, scale and displaced centres. At zero the generated rest body is retained.
- BONES exposes the actual hierarchy through a translucent skin.
- CENTRE returns the pivot. RESET stops motion and restores every bone, scale and control.

The controls use existing XRTools dial/button scenes. The pink sphere uses XRToolsPickable with a frozen release and a desktop pointer-drag path. All controls are close together. The sphere is a proxy, not a physics constraint on the body.

## Construction

`pivot_creature.gd` builds a Skeleton3D with 25 bones: root, chest, neck, head, six three-bone limbs and a three-bone tail. Two ellipsoids and seven tapered tubes form one ArrayMesh: 3,344 vertices, 6,400 triangles. Tube roots overlap the torso; this is not a watertight single surface. Up to two bone influences blend each vertex. Inverse bind transforms preserve the original rest geometry.

The source mesh is created once. Skeleton poses deform it thereafter. The whole-body transform is `p' = origin + pivot + R*S*(p-pivot)`. Local limb transforms use the same change-of-centre relation in their parent bone frames. Limb scale is a deliberate geometric distortion; it does not represent conserved volume or biological motion.

This version is skeletal animation, not a physical ragdoll. It has no joint forces or skin collision. The room and console have colliders; the creature is a visual study. No imported model, animation clip or texture is required. The artifact does not install a camera, sky or WorldEnvironment into a containing hall. `preview.gd` owns those only for its separate review room.

## Verification

Run `tools/probes/pivot_body.gd` in Godot with `--xr-mode off --no-window --rendering-method gl_compatibility -- --capture-pivot`. The probe loads the existing gallery through GridSystem and its registry, checks weights/bind transforms, shape preservation, actual deformation, reset, native controls, pointer buttons and simulated XRTools grip/release. All 28 checks pass. Separately, `tools/probes/pivot_preview.gd` photographs the same production artifact in the optional review room; add `--no-bridges` after `--` to keep ecosystem modulation out of those comparison images. Receipts are in `ada_run/pivot_body`; the report is in `doc/book/iterations/2026-10-09-move-the-centre`.

A physical headset and Quest performance still need testing. References: [Godot Skeleton3D](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html), [Omoss: Forms](https://omoss.io/work/forms).
