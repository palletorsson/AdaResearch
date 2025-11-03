extends Node

var text = '''
[center][b]Reinforcement Learning Creature[/b][/center]
[center][i]Inside Reinforcement Learning Creature[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/reinforcementlearning/joint_learn_walk.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]num_limbs[/code]` tweaks num limbs in real time.
- `[code]min_limb_length[/code]` tweaks min limb length in real time.
- `[code]max_limb_length[/code]` tweaks max limb length in real time.
- `[code]limb_radius[/code]` tweaks limb radius in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_process()[/code]` handles a key part of the simulation loop.
- `[code]create_environment()[/code]` handles a key part of the simulation loop.
[color=yellow]Code[/color]
[code]
func _ready():
    # Core behaviour described in the tutorial
    pass
[/code]
[hr]
[b]Tips[/b]
- Toggle parameters, watch the metrics respond, and reset the scene to compare runs.
- Pair this with the README walkthrough for step-by-step experiments.
'''
