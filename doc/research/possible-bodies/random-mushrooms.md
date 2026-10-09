# Which differences were invited?

[Random Gaussian](random-gaussian.html) → **Random Mushrooms** → [Random Game](random-game.html)

[The primary and book passage](/necklace/thread?map=Random_Mushrooms&role=primary) · [Waves, randomness and noise](/research/waves-chance-noise/index.html#Random_Mushrooms)

In the previous room the numbers gathered into bars. Here they have caps and stems. Which differences can this recipe make?

![The six templates and their controls from the actual desktop operating position](random-mushrooms-probe_mushrooms_desktop_front_live.png)

The specimen bed already gives us five useful actions: SHOW, KIND, SIZE, REGROW and NEW SEED. We keep that work, enlarge the housed readout and make `mushrooms` the book hero as well as the primary. The six placed artifacts and the hall's recovered structure remain.

## Remove one use of a draw

Choose **Scale 1, same seed** below. The same 94 instances occupy the same positions, with the same templates and orientations. Their individual scale multipliers change to one. Their templates still have different dimensions.

The capture checks more than a repeated count: it compares every instance, every stored ground height, the template detail positions and the planted edible positions. Returning to size variation restores the earlier record.

```gdscript
func _size(v: float) -> float:
    return v if size_variation else 1.0
```

The scale draw is still consumed before `_size` chooses whether to use it. Removing the draw would pass different random values to the decisions that follow. Holding the seed is only part of holding an experiment still.

[Inspect the captured population](random-mushrooms.html).

## The circle the bed could not hold

![The ring routine's members marked in the actual seed-31415 bed](random-mushrooms-population-ring.png)

At seed 31415, the ring requests **17 members and places seven**. The other ten candidate positions fall outside the bed. This circle was specified by a centre, a radius and equal angular intervals; it did not emerge from an interaction between mushrooms. Enable the requested ring in the plan to see what the boundary leaves out. That reconstruction is a review feature; the cabinet's plate reports placed membership.

The scattered candidates use a different permission: **71 accepted, nine rejected** from eighty proposals. Rings and clusters do not pass through that noise threshold. Their members may overlap existing bodies. The three routines share a place, not an admission rule.

## The template also has a past

The six slots are construction recipes. A new seed can change details inside one: the puffball's twelve bumps are drawn when its template is built, then copied into the field and onto the table. Seeds 31415 and 27182 give different bump positions; REGROW repeats them within either seed. A reference object is also made by a procedure.

Continuous scale variation never makes a seventh template between two others. A proposed next experiment could vary cap and stem independently, but that would need a new construction rule. The current controls let us identify that missing capability without pretending it already exists.

![The enlarged readout keeps the six lines together on the specimen table](random-mushrooms-probe_mushrooms_readout_live.png)

## Another capability under a similar cap

![A separately pickable mushroom just inside the bed's edge](random-mushrooms-probe_mushrooms_edibles_live.png)

Three edible mushrooms come from another scene. They can be picked up; the ordinary template copies cannot. In the headset, holding one within 0.25 m of the active camera consumes it, adds five health units where the manager supports that call, and triggers a visual effect. Its peak lasts ten seconds, with a fade in and out.

The desktop carry holds it beyond the eating distance. The test uses the real grab ray and carry first, then explicitly calls the eating function as a desktop substitute. It does not claim to reproduce the headset gesture.

![The actual desktop eating path after repairing the effect shader and overlay](random-mushrooms-probe_mushrooms_eaten_live.png)

The first pass found the effect timer running while the desktop shader failed to compile. After repairing the shader branch, a rendered test exposed an overlay with no viewport-sized surface. The overlay now takes its viewport's dimensions and follows size changes. A fixed test image verifies zero-intensity passthrough and a visible change at intensity 0.8; the live eating path verifies the full-screen rectangle too. A state flag alone was insufficient evidence.

This changes the observer's view rather than the mushroom population's arrangement. REGROW restores the planted mushrooms, but does not rewind the player's health or the whole museum.

## What is ready

**117 independent desktop checks passed, zero assertion failures, engine exit 0.** The accepted log has no GDScript or shader compilation errors. The earlier shader failure and subsequent overlay-size failure are retained in the review record. Existing startup diagnostics are recorded separately.

The interactive plan uses captured Godot records. It does not draw a new population. Symbols show identity, placement routine and transform scale; they are not cap footprints or collision geometry. The plan omits height, lighting and overlap in depth. Matched camera captures let those simplifications be compared with the material scene. The full requested ring and point inspection are browser review tools, not new VR controls.

Headset lettering, tracked-hand reach, the felt perception effect and Quest performance remain for the later visit. The visible terrain and its collider use triangles; the population's ground lookup uses an interpolated height grid. Exact contact at every stem is a separate open inspection, not established by these route checks.

[Captured populations](random-mushrooms-populations.json) · [Desktop report](random-mushrooms-probe_mushrooms_live.json) · [Run receipt](random-mushrooms-run.json) · [Tutorial](random-mushrooms-tutorial.md) · [Technical notes](random-mushrooms-technical.md) · [Critical text](random-mushrooms-critical.md)

**Next: [Random Game](random-game.html).** When a draw enters an encounter, which capabilities does the body need to answer it?

## Book passage

# Which differences were invited?

In the previous room the numbers gathered into bars. Here they have caps and stems. Which differences can this recipe make?

<!-- @mushrooms -->

A bed fills the middle of the hall. Before it, six mushrooms stand on numbered discs. Look past the table and choose two in the bed that seem related. A cap bends out over a stem; another, smaller, repeats its proportions. Before pressing anything, decide what you are using to recognise their relation.

Press SHOW. A magenta ring moves to the next disc, and rings with tall pins mark its copies in the bed. Keep pressing until the plate names the template you were following. There may be many copies, or none in this particular population. The table still gives the absent form a place.

The discs run from 0 to 5: tan cap, red cap, flat brown cap, tall white mushroom, puffball, glowing cap. These are construction recipes rather than six biological species. Within this build, each recipe has become a template. A copy carries its template's details with it:

```gdscript
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "Mushroom_" + str(i)
```

Look at two marked copies again. Their positions, turning and scale can differ. Their material situation can differ too: a cap lit by a neighbour need not look like the same cap in shadow. SHOW names a construction relationship; it cannot make every appearance identical.

Now press SIZE. The bed is rebuilt. Find your pair. Their places and orientations remain, but the extra scaling has gone. They have not all become the same physical size: a tall template remains tall beside a low one. The plate says “scale 1 · template sizes kept.” What did you think the button would remove?

For a scattered mushroom, the scale had been chosen here:

```gdscript
		var scale_factor = _size(0.7 + _rf() * 0.6)  # 0.7 to 1.3
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
```

And the switch decides what to do with that value:

```gdscript
func _size(v: float) -> float:
	return v if size_variation else 1.0
```

The draw still happens when the scale rule is off. Only its use changes. If the program skipped the draw, the following decisions would receive different numbers and our comparison would slip away. Press SIZE again. The earlier scales return.

The seed on the plate makes this return possible under the same recipe. REGROW rebuilds the population and its ground. NEW SEED chooses a number different from the current one; it does not promise a number never used before. A new build can also change details inside a template, such as the puffball's bumps. Six available recipes do not mean six eternally identical objects.

Press KIND until the plate says “scattered.” Count what it calls accepted and rejected. Together they account for eighty candidate positions. The total mushroom count can be larger: two other routines add bodies later. First look at the spaces between the scattered ones. Which gaps seem intentional?

Continue to “rejected.” Grey markers appear at candidate positions that the placement rule refused. They were never mushrooms that died. At each proposed position, a noise field was consulted:

```gdscript
		var noise_val = noise.get_noise_2d(pos_x * 2, pos_z * 2)

		# Skip if noise value is too low (creates natural clearings)
		if noise_val < -0.3:
			_rejected.append(Vector3(pos_x, get_ground_height(pos_x, pos_z), pos_z))
			continue
```

Even the source calls them “natural clearings.” The marks let us read what that phrase stands for here. A number crossed a threshold. In Gaussian, a value beyond the display was kept at its boundary. Here an unsuccessful candidate leaves a recorded position and no body.

Keep pressing KIND until it says “rings.” Green marks pick out the members added by the circle routine. One circle is requested at this bed's six-metre size. Find its arc, then imagine the rest continuing beyond the boards. Its members were given equal angular intervals:

```gdscript
	for i in range(count):
		var angle = (2.0 * PI / count) * i
		var pos_x = center_x + cos(angle) * radius
		var pos_z = center_z + sin(angle) * radius
```

The radius helps set the requested count. Positions outside the bed are skipped. The plate's bracket counts the members actually placed; it does not show the missing ones. A partial circle can carry the trace of two decisions: draw the ring, then admit only what fits.

The next KIND is “clusters.” Two cluster routines choose their own centres, spreads and templates. Their members receive random angles and distances. They do not pass through the scattered candidates' noise test. Bodies from different routines can overlap. Nothing here negotiates for room.

Walk round the west and south margins. Three larger red-capped mushrooms stand just inside the boards. They come from a separate pickable scene and are counted separately. A similar cap has acquired another capability. In the headset, hold one and bring it close to your face: its eating rule starts a visual effect with a ten-second hold and a fade in and out and the mushroom dissolves. The garden has offered a way to change the looking, as well as the thing looked at. The desktop carry lets you inspect it, but holds it beyond that eating distance.

<!-- @ -->

The sampled sizes never grow a seventh template between two others. That would need another rule. Yet these rules could carry other forms, other ranges, other permissions. Which difference would you add first, and what would have to change to let it exist? Keep that question for Random Game, where a draw enters an encounter and the body has to answer in time.
