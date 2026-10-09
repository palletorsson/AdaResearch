# What a wave can hold

<!-- @sine_flow_tray -->

The blue surface is tilted towards an open edge. Choose a hollow. Will a body that reaches it leave again?

Press RELEASE on the side desk. Thirty-two spheres arrive together. Follow one while the others keep moving. When it meets a fold, its next position depends on contact with that surface and sometimes with another sphere. The landscape has become part of the movement.

After twelve seconds the bodies stop. The small display separates those that crossed the outlet from those still inside and those that left elsewhere. The spheres in the neat rows below are a record: the program moves each departed body there and removes it from further collisions.

Leave RELIEF alone and press SIZE. The surface waits for a larger body. Release again. Which hollow from your first prediction still matters? Cycle SIZE once more to try the smallest spheres. A place in the landscape has dimensions; so does what arrives there. The name of the wave has not told us their relationship.

RESET returns the middle size and the original relief. Now change RELIEF and repeat. RELIEF cycles through three height ranges. From the middle setting, one press makes the folds steeper; the next makes them shallower than when you arrived. Their positions across the tray stay the same. You have changed the surface's height range, then watched what that means to a body with its own size, mass and contacts.

Open RULE. Before the heights are rescaled, the surface begins with this product:

```gdscript
samples.append(sin(TAU*0.9*x) * sin(TAU*0.9*z))
```

One sine repeats across the tray and another along it. Their product supplies a height at each sampled address. Triangles join those addresses. Then a further line gives the visible mesh a collision shape:

```gdscript
collision.shape = mesh.create_trimesh_shape()
```

The surface now participates in the physics simulation. It stays still throughout the trial. Time belongs to the moving bodies and to our observation window.

Look again at STILL IN. Twelve seconds gave us time to compare. It did not give us forever. A body present at this deadline has not been proven permanently trapped. And if the purpose were to hold something here, our judgement of the same count might change. What else would we need to learn before calling this hollow a shelter?

<!-- @ -->

Beyond the tray, at the mouth of the passage, a fold comes towards you.

<!-- @sine_wall_corridor -->

There is a corresponding fold on the other wall, a little out of step. Enter at the end beside the tray and stop. Choose a narrow place ahead. Watch what becomes of it while you stay where you are.

The walls keep changing the invitation. Walk back to the panel and press FREEZE. Now the folds wait for you. Pass one, turn, and approach it from the other direction. A shape can come to meet a body through its own motion or through the body's movement. For a moment these felt alike.

Run the walls again and follow a small ripple across a broader fold. The layers slip past each other. Walking the frozen surface carries one arrangement past the eye; advancing the phase changes how its layers agree. We have found a difference inside the resemblance.

Leave AMP where it is and slide PHASE through half a turn. Look at a place where the left wall approaches the middle. What is the right doing now?

Both sides bend the same way. The passage swerves while the readout settles at 2.00 to 2.00 metres. Slide back towards zero and openings and pinches return. One relative setting has changed the kind of passage the pair makes.

Here is how a displacement is placed on either side:

```gdscript
var x_pos: float = base_x - side * displacement
```

`side` is -1 on the left and 1 on the right. The same positive value moves both walls inward. Give one wall the negative of the other's value and their movement across the passage agrees instead. A half-turn phase offset does that to a sine. It does it to every sine in this sum:

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
```

Read the terms through what you just changed. Amplitude multiplies the depth of a fold. Frequency sets how many returns fit along the passage. Phase changes where in the return a wall stands. The fundamental makes 4.5 cycles over seven metres, a wavelength of about a metre and a half; two higher spatial frequencies add the smaller ripples, each with a shorter wavelength of its own, and a body walking the passage meets every fold at its own spacing. All receive the running phase, but their different wavelengths make the layers drift at different speeds.

Return PHASE to half a turn and inspect a bend. The number still says two metres. Notice its name: `x-gap`. It compares the two walls at matching positions along the passage, across local X. The shortest way between curved surfaces need not follow that direction. We have made a constant width by deciding how to measure it. Which width would matter to a body trying to get through?

Bring PHASE back towards zero, then raise AMP. Approach a pinch slowly. Try crossing a visible crest instead of following the opening.

You can pass through. The walls have no collision shapes; a thin floor slab above the museum deck supplies support. Yet the surfaces have already offered a direction, a narrowing, a reason to hesitate. Their influence did not wait for collision to be enabled.

Try following the apparent passage for a few steps, then cutting across a fold. The same construction permits both. Giving these surfaces the power to stop you would change what can happen here, and it would require another part of the program.

RESET restores the declared settings. The walls begin to disagree by the familiar amount. You can recognise the passage and still choose a different route through it.

<!-- @ -->

The small case beside the tray desk offers another view of the wall rule. Below the bridge, the older floor of spheres rises and falls through a product of two sines. A repeating value has acquired several bodies already.

Ahead, a point travels around a circle. A graph grows beside it, then stays while the point keeps turning. Follow the point and try to predict the graph. After walking among these folds, we can look at one way their returning values are made.
