# Transformation machines

Status, 2026-10-22: all four placements were removed from main Translation floor
15 at Palle's request. The assemblies remain reusable sketches in the shared
catalogue and workbench, with their source scenes and cached 3D models retained.
The existing 348-cell construction and both moving carriers remain. The previous
physical test results below describe the archived sketch installation.

We are discussing the crank and piston one artifact at a time before building
more. See `doc/design/transformation-machine-decisions.md`.
The shared prefab catalogue and capacity tree use the same four definitions as
the live editor. No player unlock or manuscript change is made here.

The crank is a powered rigid body on a real hinge, coupled through a two-metre
metal rod to a wooden rigid piston on a slider joint. The piston must contact a
white ball to deliver it to a tray. MOTOR / PAUSE supplies the input. PIN / UNPIN
removes or reinstates the physical coupling; misaligned ends require alignment
or RESET. Removing the pin does not disable the motor. No script maps angle to
the piston's translation or places cargo at its destination.

The lever reuses the force-study hinge and bounded-force rose grips. A two-kilogram
load attaches 0.75 m from the pivot; two effort points are 0.4 m and 2 m away.
The hand moves a proxy that applies force, never the constrained beam itself.

The hanging cube uses four pinned rigid links, not an elastic or fibre-rope
solver. Gravity and collisions determine its swing. The metal slot is physical.
The grip uses the same force proxy as the lever.

The gravity sorter compares three identical diverging-rail lanes. White sphere
radii are 0.16, 0.29 and 0.44 m; every body has mass 1 kg. RELEASE unfreezes the
bodies in place. Their size changes their contact with the rails; this is not a
claim that heavier bodies fall faster. The status observes actual exit positions
and does not drive or predetermine them. Existing concrete slabs, wooden planks,
cube forms and the point-body pickup implementation supply the vocabulary.

Physics admits a particular result under particular body sizes, friction, solver
steps and input. It is evidence for this trial, not a proof for all conditions.
The fixtures expose that dependency through coupling, lever arm, clearance and
attachment. A useful strange-play variation is to remove a pin while leaving the
motor running, or to apply equal effort at the two lever points. A further version
can chain the outputs physically; this version keeps the four experiments distinct.

Native evidence and inspection captures: `ada_run/transformation-machines/`.
The probe tests contact delivery, crank-pin error and stroke, disconnected
coupling, reset, force-distance effects, rope attachment, and gravity exit order
at world Y=-90. A second probe loads the actual main tower and checks the unchanged
crossing, source bounds and outcomes in the staged bay. No complete desktop-input
playthrough or physical-headset acceptance is claimed.

Engine joint references checked for Godot 4.6:
[HingeJoint3D](https://docs.godotengine.org/en/4.6/classes/class_hingejoint3d.html),
[SliderJoint3D](https://docs.godotengine.org/en/4.6/classes/class_sliderjoint3d.html).
