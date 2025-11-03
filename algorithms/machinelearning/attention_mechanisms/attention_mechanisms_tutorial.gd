extends Node

var text = '''
[center][b]Attention Mechanisms[/b][/center]
[center][i]Inside Attention Mechanisms[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/attention_mechanisms/AttentionMechanisms.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]token_count[/code]` tweaks token count in real time.
- `[code]base_attention[/code]` tweaks base attention in real time.
- `[code]attention_gain[/code]` tweaks attention gain in real time.
- `[code]focus_gain[/code]` tweaks focus gain in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_process()[/code]` handles a key part of the simulation loop.
- `[code]_setup_materials()[/code]` handles a key part of the simulation loop.
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
