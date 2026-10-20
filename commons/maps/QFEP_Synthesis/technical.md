# A body receives the mapping

Sandbox separated a moving handle from the values another object receives. Synthesis uses a specimen with its own two local sliders. Neither control is broadcast to the surrounding formula, spheres, ceiling or meter.

Lambda requests two SoftBody3D coefficients:

```gdscript
stiffness = lerpf(0.9, 0.1, lambda)
midpoint_weight = 1.0 - abs(lambda - 0.5) * 2.0
pressure_baseline = base_pressure * (1.0 + midpoint_weight * 0.5)
```

With the default base pressure of 1, the baseline is 1 at the endpoints and 1.5 at the midpoint. This triangular peak is authored. No phase transition or entropy estimate is detected by it.

When pulsing is enabled and 0.3 < lambda < 0.7, the pressure used by the body is baseline * (1 + sin(time * speed) * amplitude), with speed interpolated from 0.5 to 2.0 and amplitude from 0.02 to 0.1 across the lambda range. At lambda 0.5 the pressure varies between 1.41 and 1.59 around 1.5. The former frame callback overwrote this baseline with values near 1. The repaired physics callback preserves the mapped baseline and advances elapsed simulation time independently of rendered frames.

PULSE / STEADY disables or enables this imposed modulation and restarts its phase. It leaves the body's mesh, existing motion, gravity, stiffness, damping and drag intact. It does not pause or reset the physics engine. PAIR A, B and C select (lambda, phi) = (0.1, -0.8), (0.5, 0), (0.8, 0.6). They are sample combinations, not classified biological states.

Phi ranges from -1 to +1. Its normalized coordinate u=(phi+1)/2 requests damping from 0.2 to 0.001 and drag from 0.3 to 0. The current Godot 4.6-stable Jolt backend ignores drag and returns zero. Runtime stiffness assignments change the property but do not rebuild active constraints. Stiffness set before construction does affect the body; pressure and damping update live. Matching-body tests confirmed this distinction, consistent with the [engine implementation](https://github.com/godotengine/godot/blob/4.6-stable/modules/jolt_physics/objects/jolt_soft_body_3d.cpp).

The controls also change material colour and shader parameters, so a changing image is not by itself evidence of mechanical deformation. The installed plate reads properties; it does not verify their physical effects. The tutorial bench distinguishes requested stiffness from its construction-time value and requested drag from unused engine drag. The framed viewport updates text without rebuilding baked meshes every tick.

The jar previously had only a floor collider. A sixteen-part side shell and lid now match the closed jar. The cracked variant has a shorter open shell; escaped retains only the base; clouded retains its fixed 160-grain MultiMesh and has no deformable body. The live plate identifies that distinction. A glass shader is not a fluid solver: there is no buoyancy calculation here.

In this hall the specimen stands at full scale on two adjacent support cells, facing the entry, with the controls to its side. Other placements and the central terraces remain. The selection labels, live readout and causal mapping support a comparison; they do not establish a universal correspondence between a coefficient and an identity.

The specimen uses an opaque material behind transparent glass and fluid; refraction is disabled to keep those nested layers readable on the mobile renderer. Phi's small control display shares the signed range shown on the plate.

The main manuscript retains the proposal to record deformation histories. Such a trace is not yet implemented. Headset comfort and whether learners can distinguish the responses remain open checks.
