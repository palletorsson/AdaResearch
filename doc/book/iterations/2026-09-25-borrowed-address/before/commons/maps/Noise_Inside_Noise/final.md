# Borrow an address

<!-- @noisesphere -->

Step through the opening into the sphere. Its colour curves above your head and returns towards the floor behind you. The museum is still visible through the other opening. A pattern that could have been held at a distance has become the inside of where you stand.

Two smaller spheres stand behind a tilted instrument within it. A yellow point marks the same direction on each body. Their colours seem related, but a patch on the left has acquired a different neighbourhood on the right.

Press ZERO. Stay with one patch: the two bodies agree at once. Then press WARP. Where did the difference enter?

Look up. The surrounding sphere changes too. Your feet have stayed on the same circular floor; the wall has not moved closer. Yet a different patch now hangs above the place where you are standing. The operation reaches the room before we have named it.

The outlines remain round in SKIN mode. The yellow points have stayed where they were. We have not enlarged a sphere or chosen a new colour range. Something changed before the value reached the surface.

Look down at the two square images. They read the field across the same coordinate window. Yellow marks the same address, `p`, in both. On the left, a second, pink point names an address nearby. The right-hand image borrows its answer from there.

The little grid beside the images keeps both versions of the coordinates visible: cyan for where we began, pink for where the warp sends us. The yellow line follows the selected address between them. Try SAMPLE. Follow another line before deciding what the whole picture is doing.

```gdscript
func address_at(p: Vector2, amount: float) -> Vector2:
	return p + amount * displacement_at(p)

func value_at(p: Vector2, amount: float) -> float:
	var q: Vector2 = address_at(p, amount)
	return base.get_noise_2d(q.x, q.y)
```

There are two moments inside this short passage. We first make an address, `q`. Then we ask the base field for its value there. That answer goes back to the original place on the display. The yellow point on the right has not travelled to the pink point on the left. It receives a value from the address the pink point names.

This is domain warping: a transformation of the coordinates used to read a function. In the previous room, several weighted answers were added. Here one field helps decide where another field is asked. An addition still appears in the code, but what it adds is a displacement to an address.

The displacement needs two components:

```gdscript
func displacement_at(p: Vector2) -> Vector2:
	return Vector2(warp_x.get_noise_2d(p.x,p.y),warp_z.get_noise_2d(p.x,p.y))
```

We have brought the vector back into the noise sequence. Two Perlin fields provide its components. Their seeds are fixed at 19 and 47; the base is a Value field with seed 4. These are explicit choices for this instrument. We do not change them when WARP changes. Separate seeds give us different patterns without proving statistical independence or promising a particular kind of beauty.

At amount zero, the displacement contributes zero and `q` becomes `p`. That is why the comparison can return. The baseline is still a chosen field, a coordinate window and a colour mapping. It gives us something steady enough to find where an operation enters.

Try the four amounts: zero, 0.35, 0.8 and 1.4. Watch the coordinate grid as well as the coloured result. Some pink lines draw together; others spread apart. The underlying field has not grown extra samples in those regions. The mapping is asking at differently spaced addresses.

Look for a narrow streak you like. At one amount it might resemble a vein; at another it might lose that resemblance. Neither outcome has to be the successful one. A procedure can make something unfamiliar that you want to stay near. Knowing the amount and the sampling rule gives you a way to return to it, and a way to ask for a difference more precise than “make it more organic.”

Now press RELIEF. Keep the warp amount where it is. The square images stay the same, but the values have gained another job on the spheres:

```gdscript
func radius_at(value: float) -> float:
	return 0.94 + (0.16 * value if relief else 0.0)
```

The base radius is 0.94 in the scene's own units; they are metres only at the work's authored size, and the museum may build the whole work smaller. In RELIEF, a signed sample changes it by up to 0.16, about a sixth of that radius. A negative value can draw a point inward; a positive one can push it outward. Both spheres receive this rule. Their difference still comes from the addresses at which they read the base field.

Press ZERO again, now in RELIEF. The two arrangements of vertices agree. Press WARP, then turn RELIEF off. Both outlines return to round; a changed colour arrangement survives on the warped body. We have separated changing where to sample from changing what a sample does.

The enclosing sphere keeps its fixed wall, ceiling, floor and two openings through RELIEF. Only the two smaller bodies receive the radial change. Their surfaces have no collision; the room and plinths do. A value has changed one visible body while another body remains a steady place from which to compare it.

Walk to the side and follow a patch around a sphere. This instrument uses the x and z components of a direction on the sphere, multiplied by three, as its two field coordinates. It leaves the y component out. Upper and lower directions can therefore ask at the same address. The field has not discovered a natural way to inhabit a sphere; we have supplied a projection.

The enclosure uses that same projection and the warped field. Its colours are dimmed to sixty-five percent and drawn without the lighting that falls across the smaller bodies. Follow a patch overhead, then look back at the instrument. They share a calculation, but scale, lighting and the part of the surface available to your eyes affect how you meet it.

There is another small difference between the square and the curved body. The image samples a 96 by 96 grid. The small sphere receives colour and relief at mesh vertices, and the renderer interpolates between them. The printed value names a calculation at the selected address; a coloured patch is a finite rendering of many such calculations. Zooming closer can reveal the agreement's conditions.

<!-- @dark_sphere -->

The dark orb keeps pulsing beside the stage. Nothing at this instrument needs to advance while you compare the two spheres. The controls change a configuration; the orb's sine changes with elapsed time.

A field can receive a new address without changing its seed. A body can receive another use for the same value. A scene can continue in one place while holding a comparison in another. These are different ways for change to enter, and each lets us make a different experiment.

<!-- @ -->

Carry the distinction towards Noise Space 10: the coordinate, the value, the surface and the body trying to find a way across it. Which of them must change before the landscape offers another route?
