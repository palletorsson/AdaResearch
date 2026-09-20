# Repetition without separate pieces

<!-- @mc_torus_sculpture -->

Begin with the torus. Follow the tube around its opening until you return to the part where you started. The empty centre has a boundary you can trace. Move sideways: the visible opening narrows, although the object has not changed.

This reference uses the existing torus field with its distortion weights set to zero. We have temporarily put aside the noise that made the earlier sculpture irregular. The ring lets us keep a relation in view while the next specimen makes repetition harder to separate into individual things. An opening is visible here; whether your body can pass through it is another question, involving orientation, size and collision.

<!-- @GyroidDemo -->

Does a repeating surface have to be a collection of repeating objects?

Choose an opening in the gyroid specimen and follow the surrounding fold into the next region. Change viewpoint wherever a crossing obscures the connection. Look for repetition along another direction, then compare its scale with the first. The pattern is not organised only across a flat face.

Keep one opening as a landmark and compare it with the next recognisable opening along a fold. Look at their orientation as well as their apparent size. Repetition in a volume can carry a relation around a bend, so matching silhouettes are not the only evidence available. If the two features differ, consider whether the difference might come from viewpoint before attributing it to the field's perturbation. A second angle can resolve some of that uncertainty while also revealing another layer of the repeating structure behind the first.

The field begins with three linked trigonometric terms: sine in one direction multiplied by cosine in another, repeated cyclically across the coordinates. Together they create a periodic spatial relation. A threshold selects a surface from that relation, and the extractor turns the sampled boundary into triangles.

Start with FORMULA and SHEET, the desk's initial settings. No noise perturbation is applied. The selected level is still one: this is a sampled trigonometric gyroid level set, not a demonstration of an exact minimal surface. Even “formula” has a chosen boundary and a finite sampling grid.

Press HOLD before changing PERIOD. A copy remains behind the live specimen. PERIOD cycles through coordinate multipliers 0.5, 1, 2 and 4. Choose a fold and compare how much of the repeating relation now fits inside the same domain. The specimen has not simply been scaled as a whole. Its sampling budget remains 64 points per axis while the expression asks those samples to describe more repetition.

The shader's central operation is short enough to carry with you:

```glsl
vec3 gp = p * periodScale;
float gyroid = dot(sin(gp), cos(gp.yzx));
```

The dot product adds sin(x)cos(y), sin(y)cos(z) and sin(z)cos(x). Each term couples two coordinates. The extractor compares the combined value with one; it does not assemble a separate little object for every opening.

INTRUSION restores the complications one step at a time: fine noise erosion, then broader field modulation, then coordinate warp as well. Follow the same region through those changes. Noise can make the surface less regular, but what did it add to the relation you could already describe? What did it make harder to follow? RESET restores FORMULA and SHEET while leaving your held comparison intact.

The shapes gallery assembled descriptions of recognisable parts. Here, repetition arises directly from a field expression. There need be no separately stored object corresponding to each opening you recognise.

That shift changes what it means to edit the form. Adjusting the period changes a repeating relation across the volume. Altering a threshold can change thickness and connections. Distorting coordinates changes where the expression is evaluated. Those operations may all affect an opening, but they are different explanations for its altered shape.

A thin gold line marks one straight test through the live specimen. PROBE changes the radius of an upright capsule from 0.20 to 0.35 to 0.60 metres; its height stays 1.70 metres. The readout reports how far this capsule can travel along the marked twelve-metre segment before the gyroid's collider stops it. The warm marker locates that stop. A larger body asks more of the same visible opening.

This is a deliberately narrow question. The probe does not search for a winding route, test footing, or reproduce every part of the player's controller. A blocked straight path does not prove that no route exists. If the generator omitted collision because the mesh was too costly, the desk says the probe is unavailable; an untested wall must not become evidence of freedom.

We now have three accounts in the same room: a periodic expression, a visible surface and a limited test of bodily clearance. They can disagree. That disagreement gives the next experiment its location. Rather than adding roughness until the object seems alive, we can ask which change makes a passage, a refuge, a barrier, or a relation we do not yet have a name for.

<!-- @ -->

The next room introduces a more direct gesture. Instead of changing a repeating expression, your hand will add local contributions and watch the extracted surface join them together.
