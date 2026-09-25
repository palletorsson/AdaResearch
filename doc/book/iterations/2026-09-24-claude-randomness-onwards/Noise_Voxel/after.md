# The line that decides

<!-- @perlin_terrain_sculptor -->

A green body waits on the bench, with little daylight between its blocks. A translucent yellow box marks one cell, whether or not that cell holds a block. Deep inside the body, the blocks around it can hide the box until CUT opens the near half. Across the room, a much larger body has the same irregular outline, turned half round.

Leave SEED alone for a moment. Press THRESHOLD and watch the green body. Then watch the field value on the plate while you press again. Something has disappeared. Which number changed?

The field value stays. The line it must exceed has moved.

```gdscript
static func contract_occupied(value: float, v: float, threshold: float) -> bool:
	return value - contract_bias(v) > threshold
```

The whole decision fits inside that return. A field value arrives; a height-dependent bias is subtracted; what remains must be greater than the threshold. Equality goes with empty. The result has two states, although the values arriving at it can differ by tiny amounts.

There are twenty-four addresses along each axis: 13,824 occasions to ask. A voxel is a volume element, a little region whose occupancy receives this answer. We have carried the array into three dimensions. The field supplies values at its sample positions; the grid supplies the places where those values can count.

Look at the bias on the plate. Lower cells receive help. Higher cells have more subtracted. That preference is written here:

```gdscript
static func contract_bias(v: float) -> float:
	return (v - 0.5) * CONTRACT_BIAS_SCALE
```

`v` runs from zero at the bottom to one at the top, and the scale here is 0.5. The bias runs from −0.25 to +0.25. We have given this field a downstairs before placing anything on it. No gravity has acted on these blocks. Even a fragment hanging in the air stays where its address puts it.

The threshold button visits five values and then returns to the first. Within the rising run, −0.20 through +0.20, occupied cells can only be removed while the field and bias stay fixed. Watch a thin connection; watch a tiny island. They do not necessarily disappear at the same step.

The counter for separate pieces has another rhythm. As the threshold rises, a thin connection can break and leave two pieces. A small island can vanish entirely. Less occupied space can mean more pieces, or fewer.[^voxel-pieces] Counting bodies asks a different question from counting how much is occupied.

Press CUT. Part of the model opens to your gaze. Now check the occupied count. It has stayed put. The cells concealed by CUT are still in the array; this button changes which instances are drawn. Bring them back. A disappearance has acquired two possible explanations within reach of the same hand.

<!-- @science_screen -->

The screen keeps a horizontal slice of that array. On the left, colours vary with the field after the height bias. On the right, each square receives the decision: occupied or empty. A small yellow frame marks the selected coordinate in both.

Press CELL at the bench. The box visits another address and the screen takes its horizontal layer. Follow a dark square on the right into the coloured square at the same position on the left. There is still a value there. The decision has withheld a block.

Return to THRESHOLD. The right-hand border shifts through a left-hand field that stays still. You can now see several different values receive the same answer. The binary mask cannot show how far a rejected value missed the line; the other display keeps that difference as a shade, darker the further below, though it prints no scale.

The screen reads the bench's stored decision and sets it beside the value from which that decision was made. One view can show a difference that the other has put on the same side of the line.[^voxel-screen]

There are two readings beside each other because each lets us ask something the other has lost. The coloured field has already passed through another rule, a colour mapping. We have no unencoded original glowing behind the screen. We have enough distinct readings to follow one transformation and put pressure on its account.

Now try SEED. The field changes, and the decision map changes with it. The coordinate remains an address, but what arrives there is different. The number on the bench lets you notice that the comparison has begun again.

<!-- @voxelnoise -->

Walk towards the large blue volume with its pink edges. At the bench you look down on most of the arrangement, though its top layers reach just above eye level; here parts of it rise above your head. A recess that looked like a detail becomes somewhere you might want to approach.

Both works ask at the same 24 × 24 × 24 positions in the same Perlin field. Their cell spacing differs: four centimetres at the bench, twenty centimetres here. The model leaves a small gap around each visible block so its addresses remain legible. The large volume joins occupied neighbours and draws their exposed faces. Its surface also supplies the collision triangles.

The coordinate rule is small enough to carry across the room:

```gdscript
return n.get_noise_3d(u * CONTRACT_SPAN, v * CONTRACT_SPAN, w * CONTRACT_SPAN)
```

The three coordinates run from zero to one within either display. `CONTRACT_SPAN` is 9.6. Increasing the physical spacing therefore enlarges the arrangement without reaching into a different part of the field. The same decisions have gained another relation to your height, reach and route.

The plate counts groups joined through cell faces. Stand beside the volume and ask what that count cannot tell you. It does not measure headroom. It does not know your step height, or whether a passage has an entrance. One connected mass can contain a route you cannot use. Empty space can offer passage, or leave you without support.

There is pleasure in a cavity before its usefulness is settled. Try looking from another side. The blocks need not become an enemy, a resource or a successful level to hold your attention. They can make you curious about what sort of body would find a way here. Our own body gives one answer, with particular dimensions and particular permissions.

<!-- @dark_sphere -->

The dark orb is still here, turning above its faint violet shadow. Leave the threshold at one value and watch it for a while. The voxel body holds its arrangement. The orb continues to brighten and dim.

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

We have met this sine before. It passes through a range of emission strengths while the sphere keeps its form. Nothing here asks whether the sine has earned the right to keep a block.

The same museum can host a continuously dressed body and a body assembled through yes-or-no decisions. The threshold is useful; it gives the volume a boundary you can encounter. The field's other differences remain available to another operation, another material, another question.

<!-- @ -->

Carry a rejected value towards Noise 6 Wall. What else could receive it?

[^voxel-pieces]: In the recorded desktop comparison of 13 September 2026, seed 31415 produced 4, 15, 25, 21 and 32 face-connected pieces at thresholds −0.20, −0.10, 0, +0.10 and +0.20. Occupied counts fell throughout. These are observations of that configuration, not required outcomes for every seed.

[^voxel-screen]: The screen keeps the value, biased score and stored occupancy together: `row.append({"value":value,"score":value-PerlinTerrainSculptor.contract_bias(v),"occupied":source.get("_voxels")[x][cell.y][z]})`. The short threshold function earlier in the chapter makes the decision; this line gathers its two readings for display.
