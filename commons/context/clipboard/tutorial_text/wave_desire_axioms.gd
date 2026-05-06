extends Node

var content = """[font_size=28][b]The Dancing Body[/b][/font_size]
[i]Kinematic Waves[/i]

[i][color=gray]Summary: We usually animate characters with keyframes (recorded history). But we can also animate them with functions (living math). By passing sine waves through the skeletal hierarchy, we create procedural dance—movement that is fluid, infinite, and algorithmic.[/color][/i]

[hr]

[b]1. Phase Lag[/b]

To create a serpentine motion, we offset the phase of the sine wave as we move down the bone chain.

[color=green][b]Code[/b][/color]
[color=green][code]
# For each bone in the spine
var phase = time + bone_index * 0.5
var angle = sin(phase) * max_rotation
bone.rotation.y = angle
[/code][/color]

The delay (lag) creates the illusion of a wave traveling up the spine.

[hr]

[b]2. Perlin Noise (Improvisation)[/b]

Sine waves look robotic (too perfect). To make the dancer feel "human," we mix in Perlin Noise.

[color=green][b]Code[/b][/color]
[color=green][code]
var wander = noise.get_noise_1d(time) * 0.5
bone.rotation.x += wander
[/code][/color]

Noise adds the drift, the balance correction, the breath.

[hr]

[b]3. Inverse Kinematics (IK)[/b]

We can wave the target, and let the IK solver calculate the joints. This is how we make the hands "float" on invisible waves while the elbows react naturally.

[hr]

[b]4. Algorithmic Choreography[/b]

"The body is a thinking machine." — William Forsythe

By reducing dance to algorithms, we do not rob it of soul; we reveal the geometry of its intent. We can generate movements that no human would think to do, but any human body *could* do.

[color=orange][b]Critical Note:[/b][/color] Is the dancer free? No. They are bound by the function. But are we any different? We are bound by gravity, by bone length, by the firing rates of neurons. Freedom is just improvisation within constraints.

[hr]

[color=cyan][b]→ Next: Vitruvian Man[/b][/color]
The geometry of the ideal human.
"""
