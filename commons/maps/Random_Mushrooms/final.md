# The ring someone specified

Which parts of this population were allowed to vary?

<!-- @mushrooms -->

A raised bed of mushrooms fills the middle of the hall, boarded round like a garden bed, and before it stands a table with six mushrooms on numbered discs under a stencil: SPECIMENS · ONE POPULATION. Stand at the table before you go round the bed. Disc 0 carries a tan cap, 1 a red cap with pale spots, 2 a flat brown one, 3 a tall white one, 4 a puffball, 5 a green stem whose cap glows. Now look past them into the bed and pick two mushrooms that seem related: the same cap, the same stem, one standing in a circle of its kind and one alone on the slope. Press SHOW until the plate names the template they share, and a magenta ring on the ground and a pin in the air mark every mushroom of that kind in the bed, and the same magenta ring lies round that template's disc on the table. Look at two ringed ones side by side. They differ in which way they face and in how big they are, and in nothing else. That is the first thing to hold on to, and it is a construction rather than a resemblance: six bodies are built once, and every mushroom in the bed is a copy of one of them.

```gdscript
	for i in range(mushroom_variety):
		var template = create_mushroom_template(i)
		mushroom_types.append(template)
```

```gdscript
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.rotation_degrees.y = _rf() * 360
		var scale_factor = _size(0.7 + _rf() * 0.6)  # 0.7 to 1.3
```

Which of the six, which way it faces, how big: three draws per mushroom, and the copy is finished. The plate's first line names a five-digit seed. Press REGROW. The bed empties and grows again, and every mushroom comes back to its place with its kind, its facing, its size and the same ground under it, because every draw the build makes comes from one generator started at that number. `_rf()` is the only place a draw is made:

```gdscript
func _rf() -> float:
	return _pop_rng.randf() if _pop_rng != null else randf()
```

Now press SIZE. The bed grows again under the same seed, and every mushroom stands at one size; nothing else has moved, because the size draws are still made and only their use is switched off. That is what one decision contributed on its own, and the plate says so: SIZE off · every mushroom at 1 · same seed. Press SIZE again and the sizes return. NEW SEED grows a population you have not seen, on ground you have not seen, and REGROW brings that one back.

The plate's second line reads candidates 80 · accepted N · rejected M, with the two numbers summing to eighty. Press KIND until it says rejected, and grey marks appear on ground where nothing stands. Each is a place a mushroom was drawn for and refused. The gap you were about to call a clearing is a threshold on a noise field; the marks are the candidates whose noise fell under it:

```gdscript
	for _i in range(target_count):
		var pos_x = _rf() * meadow_size - meadow_size / 2
		var pos_z = _rf() * meadow_size - meadow_size / 2
		var noise_val = noise.get_noise_2d(pos_x * 2, pos_z * 2)
		if noise_val < -0.3:
```

Press KIND again: green rings and pins on the members of the circle. The plate's third line counts them, rings 1 (n) — one ring at this bed's size, `int(meadow_size / 5)` — and the circle you picked your first mushroom from is not something the scattered mushrooms did. It is a separate instruction with a centre, a radius, one template for all its members and a count fixed by the radius, and it sets them down at equal angles:

```gdscript
	var radius = 1.0 + _rf() * 2.0
	var count = int(radius * 8)
		var angle = (2.0 * PI / count) * i
```

When a ring runs past the bed's edge its outer members are skipped, and the number in the plate's brackets falls short of the request; the arc you can see is the part of a circle that fitted. The two clusters that follow on the next press of KIND have their own rule again, a centre, a spread and five to fourteen members thrown at random distances. Three procedures share one bed and one seed, and the bed does not say which of them put a mushroom where you find it. The rings and the plate do.

<!-- @ -->

Ask what else the six permitted shapes could become. Nothing in the rules says mushroom: the templates could be six of anything, the threshold could gate on any field, the ring could be any figure with a count. Nothing here feeds, spreads, competes or dies; the glowing one is a light under a cap, and the bed is an arrangement made once and made again on request. What was allowed to vary was decided rule by rule, which of six, which way, how big, where, and whether at all; what never varies is the six forms, the threshold and the ring's arithmetic. Try describing one patch without the words natural or artificial: say which draw you think made each thing you see, then press KIND and check. Three red-capped mushrooms of another kind stand a hand's reach inside the west and south boards; no rule of the bed made them, the plate counts them apart, and they can be picked up. In a headset, bring one to your face: it is eaten, and for ten seconds the hall looks otherwise. In the next room the draw stops arranging and starts deciding, and an outcome you cannot regrow is on the table.
