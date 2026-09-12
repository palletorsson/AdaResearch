# Told, or finding out

How can you plan when the next state is known but its timing is not?

<!-- @r_c -->

The floor is missing in the west corner of this hall. Five metres by three of it, cut square, with the museum's own stars showing through before the artifact lines the sides and lays a bed a metre down. Three cyan blocks stand in the hole, level with the floor, in a row from the near lip to the far one. On the far lip a lit prism sits on a plinth with a number cut into its face. That is the whole room: a gap, three stones, and a reason to be on the other side.

Do not step on anything yet. Stand at the near lip and read the stone on your right, which is cut and says the same thing whatever else changes:

    I   IT STANDS
    II  IT LEAVES
    III IT IS GONE
    IV  IT RETURNS

Watch one block for two full turns of that. It waits at floor level in cyan. It goes orange and sinks. It is gone, dimmed, a hole with a bed under it. It comes back green and waits again. The order held both times, and it will hold every time, because the order is the machine and not the dice. Only the waiting is drawn:

```gdscript
		var visible_wait: float = _next_random_wait()
		_note_step("stands", visible_wait)
		await get_tree().create_timer(visible_wait).timeout

		_set_state(CycleState.GOING_OUT)
```

`_next_random_wait` is the one place a number is invented, and all it invents is a duration:

```gdscript
	return _rng.randf_range(min_wait, max_wait)
```

So you can say what will happen next and you cannot say when. That is not half a prediction. It is the whole of one kind and none of another, and the tablet at the lip's west separates them for you, a line per stone: `1 STANDS drawn 3.0 s left 2.6 |||||||.` The drawn figure is what this stone's dice gave it this turn. The figure beside it is what is left of that same gift. Watch the bar empty and notice what you have not been told: which figure the next turn will be given.

The bar can count because the draw is written down once, the instant it is made, and never asked again:

```gdscript
func _note_step(kind: String, wait_seconds: float) -> void:
	_step_kind = kind
	_step_wait = wait_seconds
	_step_until_ms = Time.get_ticks_msec() + int(round(wait_seconds * 1000.0))
```

A countdown redrawn every frame is not a countdown. It is a new throw of the dice wearing a clock's face, and it would tell you nothing while looking exactly like knowledge.

Now cross. Step from the lip onto the first stone while it stands, and take the next when you are ready rather than when you are moving — the gaps are a step and the stones are patient, standing about twice as long as they are gone. If one leaves under you the fall is a metre onto the bed, and the way out is the ramp up the pit's west side. Nothing is lost in the hole but the walk back, which is the only condition under which the timing of a floor is worth learning.

The middle stone wears a gold ring on its crown for the second or so before it goes. That ring is not the machine; it is an interface, and it reads the deadline the machine wrote down. Press CUE at the lip and the ring stops being offered. What remains is the block's own small lamp, which lights as the block moves — the shipped signal, and a true one:

```gdscript
		CycleState.GOING_OUT:
			_set_cube_visual(outgoing_color, 1.0)
			_set_indicator_visual(outgoing_color, true)
```

Cross again without the ring, then decide which of the two you were actually using. The lamp reports a change that has begun. The ring announces one that has not. Neither changes the state order, and neither changes a single drawn wait; what changes is how early a body can commit to a step. Before you call anyone slow or careless on a floor like this, ask which of those two the floor was offering them.

One more thing the room keeps separate. A block's support is its own, switched on and off inside the same loop that moves it:

```gdscript
		_set_collision_enabled(false)
		_set_state(CycleState.HIDDEN)
```

Three facts, three mechanisms: the state, the wait, the collider. The hall's floor is a fourth and belongs to nobody here — the museum lays none in this pit, which is why the bed you land on is the artifact's own, and why a room that only *looked* like a crossing was not one until something under it was checked.

REPLAY at the lip deals the same rhythm again, every stone's dice re-seeded from the five-digit number cut into the idol, so you can practise a crossing you already lost. NEW SEED names another. That is what you carry out of a trap room: not the prism, but the ability to run it again.

<!-- @ -->

Noise Types follows. Carry the distinction this room drew with a hole in the floor: a procedure's structure and its choices are different things, and irregular timing no more means an unspecified process than an irregular surface means a shapeless one.
