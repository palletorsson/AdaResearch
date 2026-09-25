# Which differences were invited?

In the previous room the numbers gathered into bars. Here they have caps and stems. Which differences can this recipe make?

<!-- @mushrooms -->

The glass enclosure around the bed makes a population into a place you can enter. Its front opening leaves room beside the specimen table; another opening is opposite. Begin at the compact console, then move among the mushrooms. The cage holds an experiment, not a claim that these bodies exhaust what a mushroom could be.

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

<!-- @silhouette_arrivals -->

At the smaller arrival stage, wait for a silhouette. Another place is chosen from those still empty. Six arrivals fill it; the program does not keep producing bodies without somewhere to put them. Press REPLAY and watch the places return in the same order.

Choose one figure and press DRESS. A hem widens, a collar appears, the pleats take another colour. Try again. How far can this wardrobe take the figure?

Now press FORMS. Branches extend from the garment. Read the dress number: it has stayed. Switch FORMS back and the earlier dress returns. You did not need a luckier draw to find the branches. They needed another instruction. DRESS samples within the available recipe; FORMS switches between two recipes, one of which adds branches. Neither button changes the six places or the arrival order.[^chance-repertoire]

These figures still turn towards you as flat images. Their new outlines give them no new way to walk, touch or refuse. A different appearance has not yet become a different permission. Which of those changes would you make next?

<!-- @couture_comparison -->

Beyond the garden, three couture bodies stand together. All begin with the hare head and sheath garment. Their seeds are 41, 42 and 43. Look for differences in proportion, print and pose before pressing NEXT SEED. Three more individuals appear under the same two named constructions.

Keep this trio and press GARMENT. The seeds stay while the sheath gives way to a crinoline, then quilting, bloom and fringe. The body generator receives another construction instruction. Some details may change with the construction too: a seed is not a promise that every branch of a program spends its draws in the same way. RESET restores the starting trio. The garment's possibilities were authored; chance finds individuals within them. Which possibility would you want to add to this wardrobe?

<!-- @ -->

The sampled sizes never grow a seventh template between two others. That would need another rule. Yet these rules could carry other forms, other ranges, other permissions. Which difference would you add first, and what would have to change to let it exist? Carry that question through the cage interlude. Then, in Random Space Geometry, compare values chosen independently with values related across neighbouring positions. What changes when difference acquires a neighbourhood?

[^chance-repertoire]: The “Randomness” chapter of *10 PRINT CHR$(205.5+RND(1)); : GOTO 10*, pp. 125–127, discusses chance operations in Cage, Kelly and Morellet: variation takes place within constructed parameters and arrangements. The distinction between sampling a wardrobe and changing its repertoire is this hall’s experiment, rather than a claim that chance abolishes authorship.
