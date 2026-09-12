# Three columns, one of them lying

Can you tell how a body changes just by looking at its strange shape?

<!-- @MeltingBerniniScene -->

Three marble columns stand on a low bench in the east half of the room. They are the same height, the same stone, the same width, cut at the same resolution, and every one of them is melting. The plates at their feet say nothing yet. Stand where you can see all three at once and watch for a while before you press anything.

They do not melt together. One of them barely moves at all, and after a moment you will notice it is not moving: it is held. The other two rise and sink, and they are the reason you are here. One of them is on a clock. The other is on a field. From where you stand, at this distance, in this light, they look like the same kind of body doing the same kind of thing, and that resemblance is not a failure of the room. It is the question.

Watch the one on the left through a full cycle. Then keep watching. If it returns to where it was after the same interval twice, you have found the clock. A field returns too — that is what makes this hard — but never on a schedule.

The instrument on the bench tells you what both drivers are doing at this instant without telling you which column has which:

    t  18.40 s · seed 78968 · same mesh 40×16 · same range 0.00–0.70 m
    periodic  phase 0.926 → drop 0.65 m
    field     phase 0.391 → drop 0.27 m

Both numbers on the left are phases between zero and one. Both numbers on the right are the height the top of that column has lost. They pass through one function and land in one range, so nothing separates these two columns except what proposed the phase.

```gdscript
		"periodic":
			return sin(t * melt_speed) * 0.5 + 0.5          # the shipped driver
		"field":
			return clampf(_noise.get_noise_2d(t * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
```

One is a sine, which is where this artifact began and what its room used to call erosion. The other is a coherent field, seeded by the number on the plate, added for this room and doing here what noise actually does: wandering smoothly, arriving nowhere on time.

Three buttons before you name anything. FREEZE stops the clock, and the columns stop with it — nothing drifts, nothing settles, and the shape you are looking at is now a fact you can walk around. SPIN turns all three on their axes without touching their shape, which is worth doing while frozen: a body that is turning and a body that is changing look alike from one standpoint and not from two. MARBLE takes off the veining. Underneath is the same geometry, and if you had been reading the swirls in the stone as evidence of the melt, that is where the reading fails: the veins are a material, and they were never the driver.

Now REVEAL, and the plates name them.

Whatever you guessed, notice what the guess was made of. The shape at any one moment carries no mark of what produced it — the same melt, to the vertex, can come from a clock or from a field, and the instrument proves this by rebuilding a column at a named time twice and getting the same mesh both times, then at another time and getting a different one. What separates the two drivers is not visible in a shape. It is only visible in a history: how the shape comes back.

```gdscript
	if not _frozen and time >= _next_rebuild:
		_next_rebuild = time + 1.0 / TRIO_HZ
```

A last thing, said plainly because the room used to overstate itself. These columns are rebuilt twelve times a second at forty by sixteen segments, they cost about three and a half milliseconds a mesh, and they carry no collider at all. They hold nothing up. What melts here is a display, not a load, and the room's own description said otherwise until this pass corrected it.

<!-- @ -->

Noise One follows, and takes the mapping further: here a field became a single phase and the phase became a height, which is the thinnest possible bridge from a field to a body. The next room widens it.
