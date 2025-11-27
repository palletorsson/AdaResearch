extends Node

var content = """[font_size=28][b]Cables & Catenaries[/b][/font_size]
[i]The Weight of Connection[/i]

[i][color=gray]Summary: A cable is a line with weight. Gravity pulls it down; tension holds it up. The shape it forms is a catenary (hyperbolic cosine). This tutorial explores simulating physical connections between points.[/color][/i]

[hr]

[b]1. The Catenary Curve[/b]

A hanging chain does not form a parabola; it forms a catenary.
Formula: [code]y = a * cosh(x/a)[/code]

However, in real-time graphics, we often approximate this using a quadratic bezier or simple verlet integration, as [code]cosh[/code] is expensive and hard to control with endpoints.

[hr]

[b]2. Verlet Integration (Simulation)[/b]

Instead of a perfect formula, we simulate the physics. We divide the cable into segments (particles).

[color=green][b]Code[/b][/color]
[color=green][code]
# For each segment point
var velocity = current_pos - old_pos
var new_pos = current_pos + velocity + gravity * delta * delta
old_pos = current_pos
current_pos = new_pos
[/code][/color]

Then, we enforce the "stick" constraint: keep segments at a fixed distance.

[color=green][b]Code[/b][/color]
[color=green][code]
var diff = p2 - p1
var error = diff.length() - target_length
p1 += diff.normalized() * error * 0.5
p2 -= diff.normalized() * error * 0.5
[/code][/color]

[hr]

[b]3. Slack and Tension[/b]

The "slack" of the cable represents the excess length relative to the distance between endpoints.
• High tension = straight line.
• High slack = deep droop.

[hr]

[b]4. Network Theory[/b]

We often visualize networks as straight lines (edges) connecting nodes. This is a lie.

[color=orange][b]Critical Note:[/b][/color] Real connections have weight. They sag. They require maintenance. They are affected by gravity (context). A straight line implies an effortless connection. A drooping cable acknowledges the *effort* of maintaining a relation over distance.

The "slack" in the system is not inefficiency; it is the buffer that prevents the connection from snapping when the nodes move apart.

[hr]

[color=cyan][b]→ Next: Bernini (Form)[/b][/color]
Twisting the column.
"""

