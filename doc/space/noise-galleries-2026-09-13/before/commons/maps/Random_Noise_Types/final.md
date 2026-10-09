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

The seed repeats this local construction when its settings and calls repeat. It does not replay the museum. The left cloud consumes the first part of one generator's stream; the right continues it, so these are not identical candidates subjected to different rules. The next hall will give another operation something already formed to work on: a column, and a field that can displace it.
