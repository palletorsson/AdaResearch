# The neighbourhood nobody may enter

Can randomly proposed points still keep their distance?

<!-- @randompoints -->

Two square plates stand on a bench in the open half of the room, the same size, side by side, each holding twenty-four points drawn in the same volume from the same five-digit seed. Stand in front of them before you read anything. The left plate is crowded: points in twos and threes, some almost touching, wide bays with nothing in them. The right plate is even. Not regular, not a grid, and no less random-looking at a glance, but nowhere in it will you find a pair as close as the closest pair on the left.

Now look at what each point is wearing. Every point sits at the centre of a faint shell, and every shell is the same size. On the right they touch and never interpenetrate. On the left they pass through each other freely. That is the whole difference between the two plates, drawn rather than argued: the shell is half the rule's distance, so two points that keep the distance can have their shells meet, and two that do not cannot.

The plate on the left kept every candidate it was offered.

```gdscript
func _generate_uniform(count: int, extents: Vector3) -> Array:
	var pts = []
	for i in range(count):
		var pos = Vector3(
			_rf(-extents.x, extents.x),
			_rf(-extents.y, extents.y),
			_rf(-extents.z, extents.z)
		)
		pts.append(pos)
	return pts
```

The plate on the right threw the same kind of dart and then asked one question of every throw before letting it land.

```gdscript
			# Enforce minimum distance
			if min_dist >= blue_noise_min_dist:
				pts.append(candidate)
				placed = true
				break
```

Nothing is arranged, nudged or optimised. A candidate is proposed at random and either admitted or refused, and the refusals are not tidied away: the small grey specks between the points on the right plate are exactly the candidates the rule turned down, left where they fell. There are more of them than there are points. The readout on the bench's front says how many, in the sentence that matters most in this room: `admitted kept 24 of 24 · refused 39 in 63 draws · closest 0.135 m`.

Sixty-three throws for twenty-four points. That is the price of the even plate, and it is paid in refusals rather than in cleverness.

Press REDRAW. Both plates come back exactly as they were, because every draw in this room comes from one generator started at the number on the readout. Press NEW SEED and you get two plates you have not seen, the left one crowded somewhere else, the right one even in a different arrangement. Press RULE and the right plate takes the shipped gaussian instead: the points pile into the middle and the shells overlap worse than on the left. Three rules, one volume, one seed. The comparison is fair because nothing else moved.

Then ask the room for more than it can hold. At four times the population the readout adds a line: `51 could not be placed at all: the volume ran out of room`. It does not shrink the distance to make the number. That refusal is the honest one, and a system that quietly relaxed its own rule to report a full count would have taught you the opposite of what is true here.

Now the part you can do with your hands. Take one of the points on the right plate — they are pickable, and they come away in a hand. Carry it into a neighbour's shell and set it down. Both shells turn red. The readout says `moved 1 · under the distance 1 — the rule was applied at birth, not since`. Nothing pushes the point back out. Nothing rearranges the cloud to make room. The distance was a condition of admission and was never a force, and the room will sit in violation of its own rule indefinitely, because the rule was a test at the door and not a law inside.

RESTORE puts every point back where it was generated. That is a button, which is the right shape for it: somebody has to do it.

<!-- @ -->

The two small galleries further along the room are about something else, and they are down there on their own for that reason. White and pink there name the slopes of audio noise spectra, which is a statement about frequency; the plates on this bench are about a spatial relation between neighbours. The words *white* and *blue* travel between those two subjects and the mathematics does not, so read the galleries as a second exhibit rather than a continuation of this one.

Noise Columns follows. Carry the distinction this bench drew: a field with a constraint is not a field with less randomness in it, and a rule enforced at birth is not the same object as a rule enforced continuously.
