extends Node

var text = '''
[center][b]Generative Adversarial Networks (GANs)[/b][/center]
[center][i]Inside Generative Adversarial Networks (GANs)[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/generative_adversarial_networks_GANs/GenerativeAdversarialNetworksGANs.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- Inspector properties let you steer the demo without editing code.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_process()[/code]` handles a key part of the simulation loop.
- `[code]create_noise_particles()[/code]` handles a key part of the simulation loop.
[color=yellow]Code[/color]
[code]
func _ready() -> void:
    # Core behaviour described in the tutorial
    pass
[/code]
[hr]
[b]Tips[/b]
- Toggle parameters, watch the metrics respond, and reset the scene to compare runs.
- Pair this with the README walkthrough for step-by-step experiments.
'''
