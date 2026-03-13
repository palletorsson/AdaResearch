extends Node

var text = '''
[center][b]Evolving Flowers[/b][/center]
[center][i]Inside Evolving Flowers[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/evolvingflowers/evolvingflowers.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- Inspector properties let you steer the demo without editing code.
[hr]
[b]Loop Highlights[/b]
- `[code]_init()[/code]` handles a key part of the simulation loop.
- `[code]randomize_genome()[/code]` handles a key part of the simulation loop.
- `[code]crossover()[/code]` handles a key part of the simulation loop.
[color=yellow]Code[/color]
[code]
func _init() -> void:
    # Core behaviour described in the tutorial
    pass
[/code]
[hr]
[b]Tips[/b]
- Toggle parameters, watch the metrics respond, and reset the scene to compare runs.
- Pair this with the README walkthrough for step-by-step experiments.
'''
