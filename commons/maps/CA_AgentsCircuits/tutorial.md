# CA Agents Circuits

Wireworld. Cells can be empty, electron head, electron tail, or conductor.

Define cell states.

```gdscript
enum Cell { EMPTY, CONDUCTOR, HEAD, TAIL }
```

Four states. Empty never changes; the other three cycle in specific ways.

Apply the Wireworld rule.

```gdscript
func wireworld_rule(current: int, neighbours: Array) -> int:
    match current:
        Cell.EMPTY: return Cell.EMPTY
        Cell.HEAD: return Cell.TAIL
        Cell.TAIL: return Cell.CONDUCTOR
        Cell.CONDUCTOR:
            var head_count: int = 0
            for n in neighbours:
                if n == Cell.HEAD: head_count += 1
            if head_count == 1 or head_count == 2:
                return Cell.HEAD
            return Cell.CONDUCTOR
    return current
```

HEAD decays to TAIL; TAIL to CONDUCTOR; CONDUCTOR ignites when exactly 1 or 2 neighbours are HEAD. This rule supports signal propagation and logic.

Draw a wire.

```gdscript
func draw_wire(start: Vector2i, end: Vector2i) -> void:
    var current := start
    while current != end:
        grid[current.y][current.x] = Cell.CONDUCTOR
        var diff := end - current
        if abs(diff.x) > abs(diff.y):
            current.x += sign(diff.x)
        else:
            current.y += sign(diff.y)
    grid[end.y][end.x] = Cell.CONDUCTOR
```

Bresenham-style wire drawing. The learner can paint conductors with a controller.

Inject a signal.

```gdscript
func inject_electron(position: Vector2i) -> void:
    grid[position.y][position.x] = Cell.HEAD
```

A single HEAD cell. The signal propagates along any connected conductor.

Build an AND gate.

```gdscript
const AND_GATE := [
    [C, C, C, C, C, C, C],
    [C, 0, 0, 0, 0, 0, C],
    [C, 0, 0, 0, 0, 0, C],
    [C, C, C, C, C, C, C],
]
```

Two input wires converge. When both carry signals, the output wire ignites. Single inputs stall.

Test the gate.

```gdscript
func test_gate(gate_pattern: Array, inputs: Dictionary) -> int:
    place_pattern(gate_pattern, 0, 0)
    for input_pos in inputs:
        if inputs[input_pos]:
            inject_electron(input_pos)
    for _i in 20:  # run for 20 generations
        step()
    return read_output()
```

Place the gate; inject signals; run; read the output. Boolean logic via cellular automata.

Build a clock.

```gdscript
const CLOCK_RING := [
    [0, C, C, C, 0],
    [C, 0, 0, 0, C],
    [C, 0, 0, 0, C],
    [C, 0, 0, 0, C],
    [0, C, C, C, 0],
]
```

A closed loop of conductors. A HEAD placed on the ring circulates forever, producing periodic pulses.

You can now implement Wireworld, draw wires, inject signals, build logic gates, and test them via simulation. CA_EdgeOfChaos extends into classification.

Reset the grid to random.

```gdscript
func reset_random(density: float = 0.3) -> void:
    for y in size.y:
        for x in size.x:
            grid[y][x] = 1 if randf() < density else 0
```

Useful for exploring the rule's behaviour from different starting conditions.
