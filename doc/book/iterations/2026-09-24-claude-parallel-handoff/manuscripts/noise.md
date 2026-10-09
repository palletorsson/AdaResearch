# noise: current chapters

Snapshot for the 24 September 2026 Claude assignment. Reconcile with live final.md before editing. Anchors retained; image binaries not included. Resolve original image paths in the live project.

## Random_Noise_Types
Source: `commons/maps/Random_Noise_Types/final.md` · SHA-256 `f94fc7ff88835c253ca2622e2a638acb6729b057176fe15a3bef42b55b818f30`

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

---

## Noise_Columns
Source: `commons/maps/Noise_Columns/final.md` · SHA-256 `d5e3f300bcf46bcca41512bd10f6082c4426883345271da3f47e273114bbbc8c`

# What keeps a body changing?

Can you tell how a body changes just by looking at its strange shape?

<!-- @MeltingBerniniScene -->

Three marble columns stand in the east half of the room. Their shafts come from the same recipe, at the same resolution. The plates at their feet say nothing yet. Stand where you can see all three at once and watch for a while before you press anything.

One silhouette holds. The other two rise and sink. There may be a familiar movement among them, something the wave halls have already taught your body to expect. Choose one to follow. When it comes back, keep watching. Does the return arrive after the same interval?

FREEZE holds the columns' local clock. You can take time to walk around the shape that was passing. The rest of the museum continues. Even here, stopping has an address.

Try SPIN while the clock is held. The columns turn. A ridge slips out of sight and another arrives. The vertices of each shaft keep their local coordinates; their positions in the room change with the whole column. Transformation has returned as a way to inspect what we thought was deformation.

Stop SPIN and press MARBLE. The shaft loses its veining. The folds remain. The base and capital retain their own patterned materials. Look at the edge of the shaft, then at the surface inside that edge. A changing appearance has several places to happen, and a picture can encourage us to fold them together.

Put the veining back if you prefer it. The pleasure of the surface need not end when we learn how it works.

Now REVEAL names the three drivers. BASELINE holds a fixed value. PERIODIC follows a sine. FIELD follows a path through a seeded coherent field. Release FREEZE and compare the names with the movement you watched.

```gdscript
func driver_phase(kind: String, t: float) -> float:
	match kind:
		"periodic":
			return sin(t * melt_speed) * 0.5 + 0.5          # the shipped driver
		"field":
			return clampf(_noise.get_noise_2d(t * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
		_:
			return TRIO_BASE_PHASE
```

The sine repeats after a fixed interval. At the room's speed of 0.9, that interval is about seven seconds. The field has a different history. Nearby sample coordinates give related values; the path does not carry the sine's promise of a seven-second return. That does not make it unknowable. With the same seed, settings and coordinate, this implementation gives the same value again.

Both drivers hand the shaft one number between zero and one. The code calls it a phase. For the sine, it is a remapped output rather than the angle inside `sin`. For the field, it is a sample remapped and bounded to the same range. The shared name makes the numbers interchangeable at the next operation, while their histories remain different.

In the previous hall, each bar received its own draw. Here a whole shaft receives one phase. The field is not being sampled separately at every vertex. It proposes a value; the column recipe decides where that value can go.

```gdscript
var melt_factor = pow(v, 0.5) * melt_strength * melt_phase
var height = v * column_height - melt_factor * 2.0
```

`v` marks progress up the shaft, from zero to one. The square root gives different heights different shares of the same phase. At the top, the mapped drop can reach 0.70 metres. The phase also enters a bulge further down the function. Ribs, twists and offsets were already there before the field arrived.

Look again at BASELINE. It is held at 0.10, and it is already strange. The fixed reference is itself a made body. We have chosen something to keep still so that another change can become legible.

This gives a practical answer to what bodies are possible with the tools we have acquired. A coherent field can supply variation, but it does not contain a column. Rings of vertices, a spiral, a height rule and a material make that variation into this body. Give the same values another recipient and another world can appear.

The recognisable column also brings an expectation: it should hold something up. These display columns have no supporting collision bodies. They carry the appearance of architecture without its load. Calling their movement melting names what we see; it does not establish that stone, heat or erosion is being simulated.

There is a smaller interruption inside the smooth movement. Each moving shaft is rebuilt at most twelve times a second. Between updates, the mesh holds its last shape. The readout reports that budget and the last phase actually used. Our earlier trace had gaps between samples; this surface has intervals between rebuilds. What looks continuous is again being afforded in portions.

<!-- @dark_sphere -->

Leave the columns frozen for a moment and turn to the dark orb. Its sheen shifts. Stay long enough to notice the pulse and the widening ring beneath it. The room has not stopped breathing just because one instrument has stopped counting.

This body uses another local clock. Its script also contains a sine:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
```

This time the value enters brightness and emission. It does not rebuild the sphere's mesh. The body also turns slowly, and the surrounding ring changes size and opacity. A single appearance gathers several operations that our earlier halls let us separate.

The dark sphere was described as a neutral anchor. Looking for longer complicates that description. It is active, but its activity is easy to pass over beside the tall columns. The distinction between foreground and background is also a distribution of our attention.

You need not make it illustrate the columns perfectly. It can keep its quieter presence. It gives the local pause an outside: another process goes on while we concentrate on this one.

<!-- @synthesis_stand -->

Nearby, the darkness has become six small orbs. They turn together in a ring, at alternating heights. There is an empty middle. Walk far enough around them for the gaps to change.

This work belongs to the same dark-sphere family. The stand chooses `presence = hush` and `body = swarm` before the scene builds. The first setting makes the presence smaller and quieter. The second chooses a construction with six members. Their common motion is the rotation of their parent; they are not steering themselves around one another.

```gdscript
var count: int = 6
var ring: float = _radius * 0.95
var small: float = _radius * 0.40
```

The array has come back inside a body. So have the circle and the alternating value. Earlier, a field varied a shaft while its mesh connections remained. Here, selecting a construction changes how many parts the body begins with. These are different kinds of change, and our toolbox contains both.

The stand's plaque records a chosen variant and a score from a saved comparison. That score explains something about the selection procedure; it cannot decide what you should want from this body. Perhaps the small gathering holds your attention precisely because it is difficult to resolve at a glance. Perhaps you prefer the solitary orb.

A family offers possibilities, and choosing one still leaves other members unvisited. We can name the choice without closing the family. The same is true of our route through these halls: enough attention to make a discovery, with other directions still available.

Noise One takes the next step. Two surfaces will receive the same field and spend it differently, as relief and as colour. We leave with a question about the receiver as well as the source: what can this body do with the value it has been given?

---

## Noise_One
Source: `commons/maps/Noise_One/final.md` · SHA-256 `6d9528ae1be355500cc4842e1e3e573cb0f1588d85fe90cb283e31a04717b8c0`

# What does a value become?

<!-- @noisetorus -->

Two rings rest above a bench. One wears its variation as small folds. The other keeps a round outline while colour travels across it. The columns behind us asked where change enters a body. Here the question becomes more intimate: could these two surfaces be receiving the same thing?

Watch a bright patch arrive. Then press FREEZE. The rings hold that moment; the museum carries on. Two pale markers indicate matching coordinates. SAMPLE moves them together around the rings. Before reading the plate, look for a place where the folded ring turns inward and its coloured neighbour goes dark.

The plate gives a signed value. A negative number can become an inward movement. What would negative brightness look like?

At first this colour rule makes every negative sample black. Values that differ on the plate share the same darkness. Their differences have reached the display and been folded together there.

Press REMAP. Some of the dark surface returns. The number at the marker does not change. Neither does the relief. A different reading has made room for something that was already being computed.

```gdscript
func colour_of(value: float) -> float:
	return (value + 1.0) * 0.5 if _remap else maxf(value, 0.0)
```

Read the two invitations inside that line. `maxf(value, 0.0)` gives every negative value the same destination. `(value + 1.0) * 0.5` carries the interval from minus one to one into the interval from zero to one. Minus one becomes black, zero becomes halfway, and one becomes full brightness. The colour channel had room for the difference once we changed its address.

This is a small freedom with a specific mechanism. No hidden body has been rescued whole. We have changed what the display distinguishes. Lighting, the changing hue, screen precision and our eyes will still mediate what becomes visible. The plate reports the brightness factor before those further encounters.

Keep the clock held and try AMPLITUDE. The folds deepen or retreat. At zero they leave a plain ring. The coloured ring keeps its pattern, and the sampled value stays where it was.

```gdscript
func relief_of(value: float) -> float:
	return value * float(PAIR_AMPS[_amp_i])
```

A multiplication is enough to change the force of an appearance. It is not a force calculation. In the vertex shader, the result moves each vertex along its normal, the direction facing away from the surface at that vertex. The two rings have no collision shapes. The bench supports the instrument; its pictured folds will not catch a falling object.

Now change FREQUENCY. Keep watching the same marker. The value itself may change. We have moved the coordinate at which the field is consulted.

```gdscript
var scale: float = float(PAIR_FREQS[_freq_i])
var off: float = fmod(t, 3600.0) * noise_speed
return _noise2(Vector2(x * scale + off, z * scale + off))
```

The field is sampled through the ring's local `x` and `z`. Multiplying those coordinates makes more or less of the field pass across the same small body. Adding the time offset moves the sampling window diagonally. Release FREEZE and that addition resumes from the held moment. A wave of apparent change can come from travelling through values that are already determined by their coordinates.

There is a quiet omission in the expression: no `y`. Two places above and below one another, sharing the same local `x` and `z`, consult the same value. The ring is three-dimensional; this field is addressed in two dimensions. Its normals still point in different directions. One value can therefore move two parts of the body differently.

Look at the rings again. We began by treating their appearances as separate events. We can now follow a shared computation into different recipients. Yet the two views are not identical measurements: relief is evaluated at mesh vertices, while colour is evaluated across rendered fragments. The smooth skin and the bright skin spend different sampling budgets.

The marker is a coordinate probe just outside the surface. The plate rounds its field value to three decimals. Neither is a promise of infinite resolution. The little counters from our first drawn line have reached the ring with us.

<!-- @noiselayers -->

Walk around to the landscape basin. The room's opening now holds a small violet terrain within a pale coordinate frame. Come to its southern edge, where four buttons offer SUM, LOW, MIDDLE and HIGH.

Start with the whole. Choose a ridge to remember. Then press LOW. What survives? Try MIDDLE and HIGH before returning to SUM. One contribution may look modest beside another. Modest does not mean absent: addition has no obligation to give each ingredient an equally dramatic silhouette.

The earlier arrays have become a sheet of addresses. At each address, three existing noise resources supply three weighted numbers.

```gdscript
var low_freq_height = low_freq_noise.get_noise_2d(world_x, world_z) * low_freq_amplitude
var med_freq_height = med_freq_noise.get_noise_2d(world_x, world_z) * med_freq_amplitude
var high_freq_height = high_freq_noise.get_noise_2d(world_x, world_z) * high_freq_amplitude
```

```gdscript
var combined_height = low_freq_height + med_freq_height + high_freq_height
```

The weights are twelve, six and one-and-a-half. The names suggest a tidy progression, but the first two resources have almost equal base frequencies: 0.0056 and 0.0057. They also differ in algorithm, seed and octave count. These are three authored ingredients, not three pure frequency bands. A name can help us enter a construction while still needing inspection.

Each button isolates a contribution before the same further processing. The code calls that processing erosion. Look at what it actually does: in three passes, it lowers samples whose estimated slope exceeds a threshold. No water carries the removed amount elsewhere. The name lends the calculation a landscape story; the implementation gives us a more limited operation to examine.

Because the lowering happens after combination, the displayed SUM need not equal the displayed LOW, MIDDLE and HIGH added together. Combining, then modifying, can differ from modifying, then combining. Transformation taught us to ask about order. It matters here too.

The model keeps 101 by 101 sample points. Its original 200-unit width is shown at one-fiftieth scale, four metres across. The terrain has a collision mesh made from its visible triangles, unlike the shader folds on the rings. That makes a different kind of surface available to the simulation, without making this basin a full-size hiking course.

Keep the violet colour in mind. The geometry code also computes grass, rock and snow vertex colours, but the scene's material wears its own colour instead. A calculation can exist without being selected for display. A mountain can wear violet without its heights changing. The pleasure of dressing a body has arrived inside the terrain pipeline.

<!-- @dark_sphere -->

Near the exit, the dark orb continues its pulse. Leave the rings held and the terrain on HIGH. The orb still has somewhere else to be in time.

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

Another scalar finds a surface through a brightness rule. This one comes from the familiar sine and the orb's own clock. It need not imitate the landscape to belong in the room. It lets us compare a periodic source with a sampled field, and makes the boundary of FREEZE visible again.

Three works remain three works. Across them, we can follow values into displaced vertices, colour, an added height, a collision surface and a pulse. The shared numerical form permits these crossings. It does not decide which crossings we build, or what each one can support.

Noise_Voxel waits beyond the door. There the field meets another demand: decide whether something occupies a cell. Take the dark patch with you. When a rule says that nothing is there, we now have a reason to ask how it read the value.

---

## Noise_Voxel
Source: `commons/maps/Noise_Voxel/final.md` · SHA-256 `0339bbfd0b398f54b24b843450c7e81664a3c58667ae8e1a6974fa8b0c09523e`

# The line that decides

<!-- @perlin_terrain_sculptor -->

A green body waits on the bench, with little daylight between its blocks. The yellow cage names a cell, including when that cell contains nothing you can see. Across the room, a much larger body has the same irregular outline.

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

Press CELL at the bench. The cage visits another address and the screen takes its horizontal layer. Follow a dark square on the right into the coloured square at the same position on the left. There is still a value there. The decision has withheld a block.

Return to THRESHOLD. The right-hand border shifts through a left-hand field that stays still. You can now see several different values receive the same answer. The binary mask cannot tell you how far a rejected value missed the line; the other display can.

The screen reads the bench's stored decision and sets it beside the value from which that decision was made. One view can show a difference that the other has put on the same side of the line.[^voxel-screen]

There are two readings beside each other because each lets us ask something the other has lost. The coloured field has already passed through another rule, a colour mapping. We have no unencoded original glowing behind the screen. We have enough distinct readings to follow one transformation and put pressure on its account.

Now try SEED. The field changes, and the decision map changes with it. The coordinate remains an address, but what arrives there is different. The number on the bench lets you notice that the comparison has begun again.

<!-- @voxelnoise -->

Walk towards the large blue volume with its pink edges. The bench lets you look down into the arrangement; here parts of it rise above your head. A recess that looked like a detail becomes somewhere you might want to approach.

Both works ask at the same 24 × 24 × 24 positions in the same Perlin field. Their cell spacing differs: four centimetres at the bench, twenty centimetres here. The model leaves a small gap around each visible block so its addresses remain legible. The large volume joins occupied neighbours and draws their exposed faces. Its surface also supplies the collision triangles.

The coordinate rule is small enough to carry across the room:

```gdscript
return n.get_noise_3d(u * CONTRACT_SPAN, v * CONTRACT_SPAN, w * CONTRACT_SPAN)
```

The three coordinates run from zero to one within either display. `CONTRACT_SPAN` is 9.6. Increasing the physical spacing therefore enlarges the arrangement without reaching into a different part of the field. The same decisions have gained another relation to your height, reach and route.

The plate counts groups joined through cell faces. Stand beside the volume and ask what that count cannot tell you. It does not measure headroom. It does not know your step height, or whether a passage has an entrance. One connected mass can contain a route you cannot use. Empty space can offer passage, or leave you without support.

There is pleasure in a cavity before its usefulness is settled. Try looking from another side. The blocks need not become an enemy, a resource or a successful level to hold your attention. They can make you curious about what sort of body would find a way here. Our own body gives one answer, with particular dimensions and particular permissions.

<!-- @dark_sphere -->

The dark orb is still here, turning above its pool of light. Leave the threshold at one value and watch it for a while. The voxel body holds its arrangement. The orb continues to brighten and dim.

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

---

## Noise_6_Wall
Source: `commons/maps/Noise_6_Wall/final.md` · SHA-256 `e7a08ec471f7ecb941e512797250f24684056fed92763d79a2350fbd6f943172`

# The room wears the sum

<!-- @shader_noise_space -->

There is a room inside the hall. Pink gathers in its corners. The little sphere inside seems to have borrowed something from the walls, although its clouds pull around a different body. Step through one door and look towards the other. The floor carries you while something softer appears to move through it.

What would have to change for those folds to carry your feet?

Keep that question while you return to the panel. Four small windows show the same coordinates with one, two, four and six cloud terms. Press FREEZE. The room holds the moment you arrived at. Its colours and the small windows stop changing together. We can stay with a difference long enough to inspect it.

Press DRESS, then enter again. Grey has taken the place of pink. Something of the cloud remains, but its depth and atmosphere have changed. Follow the wall towards the door. The opening is still there. Your feet meet the same floor.

We have changed what the surface offers the eye. The wall's vertices and the shapes your body collides with have stayed put. This distinction is useful precisely because the surface can be so persuasive. You might still walk differently towards a dark patch, or hesitate before something that looks deep. What the player can physically cross and what the player imagines crossing need not arrive together.

At the panel, compare the first grey window with the second. A smaller variation has entered the same region. The fourth and sixth terms add finer disturbances. LAYERS carries each of those cumulative choices into the room; the four windows keep their separate counts so you can look back.

Here is the loop doing that work:

```glsl
    for (int i = 0; i < layers; i++) {
        vec2 animated_pos = pos * frequency;
        animated_pos.x += sin(t * 0.3 + pos.y * 0.5) * 0.3;
        animated_pos.y += cos(t * 0.2 + pos.x * 0.3) * 0.2;

        value += amplitude * abs(noise2d(animated_pos));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
```

`value` begins at zero, `amplitude` at 0.5 and `frequency` at 1. Each turn reaches further through the field over the same surface, then gives its answer half the weight of the previous turn. The familiar sine and cosine move the sampling coordinates. FREEZE has held their time, too.

Stay with `abs` for a moment. A negative answer returns as a positive magnitude. Positive and negative values of equal size can now contribute the same amount. In the previous room, a threshold decided whether a cell received a block. Here another operation gives differences another destination: both signs can help dress a surface. This is a new two-dimensional shader field; we are carrying a way of thinking forward, rather than transferring the voxel room's stored samples.

The plate lists accumulated weights: 0.5, 0.75, 0.9375, 0.9844. The sixth term weighs only one thirty-second as much as the first. It still has somewhere to act. Look for a region where a small addition changes the edge you were following.

More terms can also make the grey window brighter. Every weighted magnitude is nonnegative. At a fixed coordinate and time, adding one cannot reduce the sum. But the weights alone do not tell us a pixel's brightness: each term brings a sampled value, and the display puts the result through another rule.

```glsl
        float bare = clamp(cloud_noise(uv * cloud_scale, time * time_scale) * term_gain, 0.0, 1.0);
```

The comparison uses a gain of two. Values beyond the display range meet its limits. Two different sums can therefore become the same white. Grey is already an interpretation, with its own capacity to lose a difference. There is no final undressed picture waiting underneath every other picture.

Try BASIS while the moment stays held. Perlin, Value, Cellular and Simplex offer different constructions to the same accumulation. These are the implementations in this shader, with their own scaling constants. Watch what happens to a contour you had begun to recognise. Returning to Perlin restores this construction at the held coordinates. There is no seed button here; the shader's hash uses fixed constants.

Press DRESS again. The pink returns around the same held cloud sum. The finished material adds a second, four-term turbulence calculation:

```glsl
        float cloud_pattern = (cloud_base + cloud_detail * 0.4) * cloud_density;
        cloud_pattern = smoothstep(0.2, 0.8, cloud_pattern);
```

Colour mixing, edge and corner shading, roughness and small changes to the lighting normal follow. LAYERS changes the cloud sum; that separate detail loop still has four terms. A one-term cloud can therefore wear a detailed finish. The button's number names one part of a construction.

Take this knowledge inside. The material has crossed from a small square to an enclosure and a sphere. Can you follow one cloud around a corner?

Each wall piece starts its own UV coordinates. The sphere wraps a different coordinate chart around itself. The same calculation can stretch, repeat or meet a seam when another surface receives it. The room is surrounded by a shared procedure, but it is not an unbroken sample of a world-space cloud.

The seam is an invitation to look at how the room has dressed. A surface can make a box feel intimate, strange or excessive without first earning another geometry. Its pleasure need not be dismissed when we find the instruction that produces it. Now we can change that instruction with a more particular desire.

<!-- @dark_sphere -->

Outside, the dark orb continues to pulse. The room is held; this body is not. Stand between the two and watch the difference in their times.

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

The orb receives a sine as a changing emission strength. It belongs to the hall without belonging to the panel's clock. A control has a reach, and discovering its edge tells us something about the world's construction.

Press FREEZE once more to let the room continue from its held moment. The orb did not wait. We leave with several times still running, and a surface whose apparent depth has not become a foothold.

<!-- @ -->

In Noise Inside Noise, we will ask what happens when a field changes the coordinates at which another field is read. Here we added answers. Next we follow what happens to the asking.

---

## Noise_Inside_Noise
Source: `commons/maps/Noise_Inside_Noise/final.md` · SHA-256 `8462d0da760da424c42c952fdf02e91373744247abad021d83ecc35697b597fc`

# Borrow an address

<!-- @noisesphere -->

Step through the opening into the sphere. Its colour curves above your head and returns towards the floor behind you. The museum is still visible through the other opening. A pattern that could have been held at a distance has become the inside of where you stand.

Two smaller spheres stand behind a tilted instrument within it. A yellow point marks the same direction on each body. Their colours seem related, but a patch on the left has acquired a different neighbourhood on the right.

Press ZERO. Stay with one patch while the two bodies come to agree. Then press WARP. Where did the difference enter?

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

The base radius is 0.94 metres. In RELIEF, a signed sample changes it by up to 0.16 metres. A negative value can draw a point inward; a positive one can push it outward. Both spheres receive this rule. Their difference still comes from the addresses at which they read the base field.

Press ZERO again, now in RELIEF. The two arrangements of vertices agree. Turn RELIEF off and keep WARP active. A changed colour arrangement survives on the round bodies. We have separated changing where to sample from changing what a sample does.

The enclosing sphere keeps its fixed wall, ceiling, floor and two openings through RELIEF. Only the two smaller bodies receive the radial change. Their surfaces have no collision; the room and plinths do. A value has changed one visible body while another body remains a steady place from which to compare it.

Walk to the side and follow a patch around a sphere. This instrument uses the x and z components of a direction on the sphere, multiplied by three, as its two field coordinates. It leaves the y component out. Upper and lower directions can therefore ask at the same address. The field has not discovered a natural way to inhabit a sphere; we have supplied a projection.

The enclosure uses that same projection and the warped field. Its colours are dimmed to sixty-five percent and drawn without the lighting that falls across the smaller bodies. Follow a patch overhead, then look back at the instrument. They share a calculation, but scale, lighting and the part of the surface available to your eyes affect how you meet it.

There is another small difference between the square and the curved body. The image samples a 96 by 96 grid. The small sphere receives colour and relief at mesh vertices, and the renderer interpolates between them. The printed value names a calculation at the selected address; a coloured patch is a finite rendering of many such calculations. Zooming closer can reveal the agreement's conditions.

<!-- @dark_sphere -->

The dark orb keeps pulsing beside the stage. Nothing at this instrument needs to advance while you compare the two spheres. The controls change a configuration; the orb's sine changes with elapsed time.

A field can receive a new address without changing its seed. A body can receive another use for the same value. A scene can continue in one place while holding a comparison in another. These are different ways for change to enter, and each lets us make a different experiment.

<!-- @ -->

Carry the distinction towards Noise Space 10: the coordinate, the value, the surface and the body trying to find a way across it. Which of them must change before the landscape offers another route?

---

## Noise_Space_10
Source: `commons/maps/Noise_Space_10/final.md` · SHA-256 `0336acd8fbdc95ae7de375d013b2959456b39947fdecb1a1395f786aad4dcf7d`

# Which way will carry you?

<!-- @noise_space -->

Two pairs of pale posts face each other across the ground. A gold line joins them. The far opening looks close enough. Before entering, follow the line with your eyes. Where would you expect your pace to change?

The previous sphere surrounded us with a changing field while its floor stayed still. Here the answer reaches the ground itself. Take the ramp onto the dark margin. The instrument stands along its side, leaving the route open.

At HEIGHT 0.25, try walking between the posts. A small dip can disappear from the far view and return under your feet. The colour gathers into contours, but your body meets a surface. Keep those two ways of reading it in play.

Return to the margin. Press HEIGHT until it reads 0.90 and look for the feature you just crossed. The posts have not moved. The field has not been drawn again from another seed. Try the same approach.

In the recorded desktop walk, the first crossing reached the far margin. At 0.90, the same forward input stopped partway across. That is an observation about one body, one approach and two settings. It leaves other ways through the terrain to be found. A line drawn across the ground has made a proposal; it has not given the body permission to follow it.

Press RESET from the margin. The lower terrain returns, with route A and the first sample selected. HEIGHT waits if a player body is still on the patch. We make the alteration from a place that remains steady enough to compare what changed.

The current height rule is short:

```gdscript
func ground_at(p: Vector2) -> float:
	var value: float = noise.get_noise_2d(p.x * noise_scale, p.y * noise_scale)
	return 1.0 + height_scale * edge_weight(p) * value
```

The value is signed. It can lower a point below the one-metre reference as well as raise it above. HEIGHT selects zero, 0.25, 0.65 or 0.90 as the multiplier. At zero, the ground becomes level. The noise calculation still has an answer; its contribution to height has become zero.

The seed and the field's other settings stay fixed while HEIGHT changes how much of the same variation reaches the ground. We have held the source still enough to feel what one multiplication changes.[^walk-recipe]

There is a second multiplier in the code. Look at the place where green ground meets the dark margin. Even at the largest height setting, the two join at the same level.

```gdscript
func edge_weight(p: Vector2) -> float:
	var distance_to_edge: float = minf(4.0 - absf(p.x), 4.0 - absf(p.y))
	return smoothstep(0.0, 0.75, distance_to_edge)
```

The last three-quarters of a metre gradually withhold the noise's contribution. At the edge, that contribution is zero. The margin did not emerge from the field. We made it, so a body could enter and so the place from which we compare would remain available. The transition is part of the landscape's construction.

Now choose ROUTE B. A gold line takes a longer way through the same patch. Nothing in the ground moves when the line changes. Follow it to the instrument, where the proposed route has become a section: distance across the plan runs horizontally, ground height vertically. SAMPLE moves a yellow witness along both the section and the terrain.

The display gives the length and steepest sampled stretch of each proposed route. At the lower setting, B is longer and includes a slightly steeper stretch. The detour has changed what the body would meet. It has not promised an easier passage.

The section follows a line; your body has width. It can meet a slope beside the line, and its controller brings rules of its own. The recorded desktop body accepted floor angles up to forty-five degrees. Increasing HEIGHT took the steepest sampled stretch of route A from below that limit to above it.[^walk-measurements] That helps us ask why this walk stopped. It does not tell us that no body could pass.

Look down at the yellow witness. Its printed height belongs to the triangle under that point. The terrain is made from 81 by 81 sampled positions, spaced ten centimetres apart. Between those positions, triangles supply a surface. Sampling the noise again between the vertices can give a slightly different answer: the collider is the constructed mesh, not an infinitely detailed function.

```gdscript
var mesh = create_mesh_from_heights(heights)
mesh_instance.mesh = mesh
create_collision_from_mesh(mesh)
```

The same mesh is sent to sight and collision. This is the extra connection the small relief spheres did not have. A displayed height can now catch a foot.

Find a place where the ground seems to fold over itself. Move sideways and look again. Every horizontal position in this heightfield receives one ground height. A cave would need a floor and a roof at some of the same positions. We would have to give the representation something else to hold. Carry the occupied volume from Noise Voxel back into this question.

The crease that catches one body might shelter another. This instrument tests walking; shelter would ask us to place another body and a line of sight. The same terrain can support questions that a successful crossing does not settle. We can learn its construction and still discover another use for what resisted us.

<!-- @dark_sphere -->

The dark orb rests on the raised margin. Its pulse continues while you compare routes or return the terrain to its starting height. RESET has a local reach. It does not recover the time spent choosing a way across.

The margin, the terrain and the orb hold different relations to change. One offers a steady place to return to; one changes when its height multiplier changes; one keeps time. A shared computational world can let those differences coexist, provided we say where each operation acts.

<!-- @ -->

In Noise Perlin Simplex, the next comparison changes the generator. Bring the habit of holding a question steady: if two surfaces differ, which operation changed, and which body makes that difference matter?

[^walk-recipe]: The fixed recipe uses OpenSimplex2S, seed zero, four fBM octaves, gain 0.5 and lacunarity 2. Generator frequency is 0.1 and input coordinates are multiplied by five. HEIGHT changes the later multiplier.

[^walk-measurements]: The desktop record of 13 September 2026 measured routes A/B at approximately 8.13/10.40 metres for HEIGHT 0.25; their steepest sampled segments were about 24.18°/25.22°. Route A reached about 58.26° at HEIGHT 0.90. The tested controller used a 45° floor-angle limit. Forward input crossed at 0.25 and stopped partway at 0.90. A sampled line and one desktop trajectory do not establish every route or body's possibilities.

---

## Noise_Perlin_Simplex
Source: `commons/maps/Noise_Perlin_Simplex/final.md` · SHA-256 `0748a01ffa376a61ac6790c252be37add52664da592686c5b9077fb6c7974447`

# What counts as the same

A hollow on one side of the aisle faces a ridge on the other. It is easy to call that the difference between Perlin and simplex. Walk a little further before deciding.

Two changes of seed could have made two different pictures too. So could a different scale of sampling. We need a way to ask the fields a narrower question.

<!-- @simplex_noise -->

Start at the Simplex panel. Press REPLAY and choose a feature to recognise. Move FREQ a little, watch that feature change, then replay. The field returns to the declared setting. Its variation has a way back, as the colour grids did in Randomness.

In the previous room a height change caught the walking body. Here the small cubes leave space for us to walk around their arrangement. Each sampled coordinate receives a height and a colour. The underlying field relates neighbouring values; the cubes present selected values as separate steps. The grid we see is one way of reading that relation.

The Simplex visualizer asks for a value like this:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

The slider changes the coordinate multiplier. The display can keep the same cube positions while asking the field about a different scale. A ridge can change across an unmoving grid.

Find the pink marker. Press SAMPLE on the shared instrument and watch it move to another cube. Across the aisle, another marker takes the same address. Their heights need not agree. The readout now gives the coordinate, each field's answer and their signed difference.

```gdscript
func sample_pair(p: Vector2) -> Vector2:
	return Vector2(pair[0].sample_at(p.x,p.y), pair[1].sample_at(p.x,p.y))
```

One question goes to two functions. The coordinate is shared. The answer belongs to the function that returns it. A positive difference on the display means the Perlin value exceeds the simplex value at this address; it does not award a point to either landscape.

<!-- @perlin_noise -->

Cross to the Perlin panel and compare the readouts. Both begin with the same seed, octave count, frequency and gain. Their displays share amplitude, sample spacing and finish. The Perlin visualizer chooses its basis in this branch of `_noise_type_for`:

```gdscript
"perlin":
	return FastNoiseLite.TYPE_PERLIN
```

The Simplex visualizer chooses `TYPE_SIMPLEX`, which this engine implements as OpenSimplex2. The plate reads the choices back from the instantiated generators. Names can help us find a work; here we also have a way to check what they claim.

Both belong to gradient noise: a local direction contributes through its relation to a displacement, and contributions are combined into the value at an address. Perlin's lattice and OpenSimplex2's construction organise those contributions differently. The dot product from Vectors is still in the toolbox. The library has folded a longer calculation into the small call above; the call has not made that calculation disappear. [The engine's noise definitions](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html#enumerations).

Choose one comparison to keep in view: the turn of a ridge, the spacing of hollows, or the difference between answers at one coordinate. The shared seed makes each field repeatable. It does not make a ridge on one side the partner of a ridge on the other.

Now alter FREQ on just one side. Look back at the central plate. Alongside the different bases, it reports another difference: the scale at which the field is sampled. That one adjustment changes what you might have attributed to the basis. MATCH returns both generators to the declared settings. REPLAY on either side returns that side alone.

Press VIEW. Keep following the pink markers while the relief settles into two flat arrangements. The colour retains the sampled values. Nothing has been flattened inside the noise function; the display has stopped spending its answer on height.

The cubes remain at half-metre intervals. Their square arrangement is still present whichever basis produced the values. It would be easy to mistake the grid of the display for the lattice inside the calculation. VIEW gives us another way to notice that two decisions have been folded together.

Return to relief. The same answers regain height. In Noise Space 10 we joined height to collision so a change could stop a foot. These cubes are a visual comparison with a walking aisle between them. A visible surface and a surface that carries us ask for different work from the implementation.

Matching conditions costs us possibilities. One shared finish helps compare shape while withholding what another colour treatment might reveal. Half-metre samples give the field a body we can inspect; variation between those addresses has no cube of its own. The comparison makes some distinctions easier to see by agreeing to leave others out.

<!-- @perlin_noise_terrain -->

Behind the pair, a small pink sheet stands above a low plinth. Stay with it for a moment. Its surface changes in steps even while the two larger fields wait for another action.

Its timer advances a third sampling coordinate:

```gdscript
func _on_timer_timeout() -> void:
	if not _is_truthy(animate):
		return
	time_offset += 0.5
	generate_terrain()
```

The mesh helper samples a three-dimensional field. The timer visits another slice every half-second. We have met a coordinate changing before; here the change keeps arriving without another gesture. It is neither an erosion calculation nor a memory of the sheet's previous shape.

The artifact is called `perlin_noise_terrain`, but its helper leaves the generator's basis at the engine default, OpenSimplex2S. This retained work makes the room's question recur inside its own collection. Its one-metre sheet samples in index coordinates, uses seed one and has its own clock. It cannot serve as a third matched surface simply because it stands near the pair.

<!-- @dark_sphere -->

The dark orb changes too. Its pulse gives the eye another rhythm to follow, independent of the small sheet's half-second steps. MATCH does not restart either work.

A return always has a scope. We recovered the two fields' parameters, while the other bodies continued. Even a careful comparison takes place in a world that has more going on than the question currently admits.

<!-- @ -->

Look again at the hollow that first caught your attention. If you were choosing a landscape in which to hide, it might matter for a different reason than if you wanted a clear view. There need not be a winner on either side of the aisle. Keep the ability to repeat a field, change a condition and recognise what the comparison supports.

The small sheet keeps changing. A little noise, and something begins to feel organic. Perhaps that is the body we wanted. Its swelling can carry pleasure, uncertainty or a queer promise of becoming. The ease of the operation is useful: we can put a similar gesture on many different objects.

After several rooms, that usefulness can become a mental algorithmic wall. The familiar answer arrives before we have worked out the next question. Different bodies acquire a family resemblance. We can call this tendency blob culture and begin investigating it here, among our own objects. Its cheapness is the ease with which we can add the filter; what someone makes of that gesture can still matter deeply.

Stay with the sheet and ask what else this body could do. Its changing slice has no record of what happened to the preceding surface. We could give it stored states, neighbours that affect its next move, something to exchange with another body. Each would require another decision and something further to learn. Noise can remain part of those constructions.

In the next chapter, Cellular Automata, a row waits for its first update. We will let a cell's next state depend on the states beside it. Bring the pleasure of the moving surface, and leave room for another form.

---

## Lab_Path
Source: `commons/maps/Lab_Path/final.md` · SHA-256 `3fa6bd94aa92dce6c0212323f16cf26f2eef6ab414a402e698e8c7dd4bdddbf5`

What has followed you out of the room?

A dark patch that returned with REMAP. A connection that broke when the threshold moved. A ridge that caught your foot. Let one encounter come back before you try to explain the whole sequence.

<!-- @dark_sphere -->

The dark sphere keeps turning. For a moment, there is no new control to learn. Stay with the change you remember. What happened there, before you knew what to call it?

You might begin with what you saw: the patch brightened, the gap widened, the column turned. Then give it another telling, following the operation you learned to recognise. Did a different value arrive, or did the same value find another use?

The two tellings need each other. A name can help us return to what happened; it can also hurry us past something we have not understood. If you are unsure whether a surface changed or only its colour, keep both explanations for a moment. Which small alteration would let you tell them apart?

Hold a seed. Change a threshold. Look at an edge after the veining is gone. One question can give you a reason to return to a room you thought you had finished.

The sphere offers no verdict. Its pulse continues while you choose what to attend to. We have been learning how to make a difference visible, and how much must be held aside for that difference to become clear.

Perhaps what stays with you is the swelling surface itself. You wanted to remain near it, or to make a body that could live in its folds. Knowing its operation gives you something to change. It need not settle what the encounter was worth to you.

<!-- @ -->

In the cellular-automata rooms, a cell's next state will depend on what its neighbours were doing in the previous step. The neighbourhood we have been learning to recognise acquires another task. What kinds of bodies could come from that dependence?

Bring one of your unfinished questions with you.

---
