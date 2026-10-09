# Which rules keep acting?

<!-- @randompoint -->

The stones behind us could disappear. Their order of movement stayed intact; the drawn waits changed how long we had to cross. Here, something much smaller asks what can change at all.

A point waits inside a metal square. Carry it sideways. Release it. Try carrying it toward you, out of the square's plane. Where does it end up?

It has a place in this room, yet keeps returning to a surface with no depth. The frame marks a limit you can see. The returning coordinate exposes another one.

At its first appearance, two draws chose x and y. After that, there is no new lottery on release. The point's script repeatedly takes its current position and clips it:

```gdscript
var clamped := Vector3(
	clamp(pos.x, -area_half_extent, area_half_extent),
	clamp(pos.y, -area_half_extent, area_half_extent),
	0.0
)
```

Read the last line again. There is room in the vector for a third number. The code keeps writing zero there.

That zero belongs to the point's local frame. Turn the whole artifact in the museum and its plane turns with it. We have met local and world coordinates before; now their difference determines which movement survives your hand. Within the square, x and y can keep your alteration. Beyond its edges, the excess is clipped. Depth is discarded each process frame.

What looks like a flat existence takes repeated work to maintain. The engine has not forgotten a dimension. This small procedure keeps declining it.

Keep that action in mind at the next bench. A boundary can be drawn on a surface, written into a generator, or continually reapplied. Those arrangements may look alike until somebody moves.

<!-- @randompoints -->

Two shallow frames stand side by side. Find a pair of points that seem almost to touch in the left one. Look for an equally close pair on the right. Lean a little: each frame has twelve centimetres of depth, so an overlap in your view need not be an overlap in space.

The shells help. Each has a radius of half the stated spacing. Two centres at that distance have shells that just touch. Grey specks among the right-hand points record some of the proposals that were refused.

Press REDRAW. The pair of clouds returns. Press NEW SEED and look again. The arrangement changes, but the right-hand spacing survives the new draw.

The left frame keeps each uniformly proposed position. On the right, a candidate is compared with the centres already admitted. Only this condition lets it join them:

```gdscript
if min_dist >= blue_noise_min_dist:
	pts.append(candidate)
	placed = true
	break
```

The candidate's own coordinates are insufficient to decide its place. Its possibility now depends on who arrived before it. Earlier centres stay where they are; the algorithm neither negotiates with them nor rearranges the group.

Press LOAD. The request rises from 24 to 96. The frames and the spacing stay the same size. Read the plate before deciding what the denser cloud means. Candidates split into kept and refused; requested places split into filled and unfilled. These are different accounts.

The generator allows a hundred attempts for each requested place. A place still unfilled after those attempts is skipped, and the next gets its own attempts. The plate names the exhausted budget. It cannot certify that every remaining gap is impossible. Our time for searching has ended before our question about space has been settled.

Only the first 220 refusals receive grey bodies. The full refusal count continues beyond them. Even the display of what was excluded has an exclusion of its own, and this time we can read its limit.

Return LOAD to 24, then press RULE. The right frame gathers toward its centre. This setting makes Gaussian draws for each coordinate and clamps their tails to the frame. It applies no pair-distance test. Shells may already be red before you touch anything. They now show a reference distance that the generator never promised to preserve. A crowded centre and a spacing rule are different ways of making a cloud; the names alone cannot tell us how either was made.

Return to the spaced rule. Carry a point into another's shell.

The red arrives. A count changes. Nothing in the sampling script pushes the pair apart.

```gdscript
if a.position.distance_to(b.position) < blue_noise_min_dist - 0.001:
	touching += 1
	bad[i] = true
	bad[j] = true
```

This passage watches. It counts pairs closer than the spacing minus a one-millimetre tolerance. It writes no replacement position. Compare it with the zero that kept reclaiming the first point's depth.

Release the point, then RESTORE. The cloud returns to the positions recorded when it was generated. That return is available as an action; it does not make the original arrangement inevitable.

A pleasing order has shown us its procedure and the moment that procedure stops governing. There is room to inhabit the difference. We can keep the useful constraint, learn what it made possible, and still discover a relationship it did not authorize at birth.

The red shells could register your alteration without undoing it. That is a different kind of rule from the zero that kept reclaiming the first point's depth. Carry the difference to the field of needles: what does a neighbour get to decide here?[^cloud-replay]

<!-- @WhiteNoiseGallery -->

Walk around the little field of needles. Let your eye follow a row, then cut across it. There are ten thousand bars here. The grid has already given each one an address. Chance decides how far it rises.

The same drawn value gives a bar its height and its place along a colour gradient. Tall and pale can arrive together because one number has been dressed twice. This is something we brought from the colour halls: an arrangement becomes readable through the choices that make its values visible.

```gdscript
var random_val = _rng.randf() # 0.0 to 1.0
var height = random_val * max_height
```

The spacing bench let a neighbour influence whether a new centre could appear. These bars do not consult adjacent heights. Every address receives a draw. A ragged-looking surface has been made from a perfectly regular allocation of places.

Now press WHITE on the console beside it. Then PINK. Listen for a difference while looking at the field. What in the image changes?

The bars stay where they were. The sound has its own stream of draws and its own procedure. It is tempting to let the image explain what we hear, especially when one title seems to cover both. For now, the connection is made by their proximity, their names, and your attention. The sound is not a scan through these ten thousand heights.

That separation leaves an experiment open. What would we hear if a row actually became a sequence of samples? Which row, in which direction, at what speed? A surface offers several ways through; a loudspeaker needs values arriving in time. Choosing the route would already change the work. We can imagine that instrument here without pretending it has been built.

<!-- @NoiseColors3D -->

The neighbouring sculpture keeps five coloured rows together. Brown, pink, white, blue, violet. Try their names on the console. Let each sound last long enough to become a texture before moving on. Return to one you liked.

We are not obliged to hear these as damaged signals. A hiss can be a material to approach, sustain, combine, or leave. The question of what a body may do includes what it may want to remain with.

In the sculpture, a row's height comes from a prescribed curve, disturbed by a random multiplier and clipped to the display's range. A tall plateau can therefore be the place where different large values meet the same ceiling. The apparent agreement of their tops deserves a second look.

The sound is built elsewhere. At the BROWN setting, a stored value receives a small part of the next draw:

```gdscript
_brown_state = clampf(_brown_state + white * 0.02, -1.0, 1.0)
value = _brown_state * 3.5
```

The previous state participates in what comes next. A neighbour has become a previous moment. Notice the bounds here too: accumulation can meet a limit even though new draws continue arriving.

Try VIOLET. Its short passage keeps the previous draw in order to subtract it:

```gdscript
value = (white - _previous_white) * 0.9
_previous_white = white
```

Keeping something from the past does not always make the next moment more similar. Here, what survives into the output is a difference. The two lines give us another way to hear the relation between memory and change.

These are the shipped filters behind the names. The curves above them are illustrations, not measurements of the sound coming from the speakers. Even BLUE's sound uses subtraction from a running low-pass value rather than the exact rising curve that its row illustrates. A name brings several implementations into company; inspecting them keeps that company from becoming an identity claim.

We can leave this hall with more than one discovery. A plane maintained by clipping. A spacing rule that finishes its work. A field that ties colour to height. A sound that holds a previous value, or answers it with a difference. Each gives a different place for a relation to land.

In the next hall, a column is already waiting. What will happen when variation is given an existing form to act on?

[^cloud-replay]: The seed repeats this local construction when its settings and calls repeat; it does not replay the museum. The left cloud consumes the first part of one generator's stream and the right continues it. These are not identical candidates subjected to different rules.
