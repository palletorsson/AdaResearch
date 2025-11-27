extends Node

var content = """[font_size=28][b]Bernini's Twist[/b][/font_size]
[i]The Baroque Algorithm[/i]

[i][color=gray]Summary: The Solomonic columns of St. Peter's Baldachin (Bernini) spiral upward, seemingly defying the rigidity of stone. Here, we use sine waves to displace mesh vertices, transforming a cylinder into a twisting baroque form.[/color][/i]

[hr]

[b]1. Vertex Displacement[/b]

We do not model the twist by hand. We take a straight cylinder and move its vertices in the shader.

[color=green][b]Code[/b][/color]
[color=green][code]
# Vertex Shader
float angle = VERTEX.y * twist_amount;
float cos_a = cos(angle);
float sin_a = sin(angle);

# Rotation matrix around Y axis
mat2 rotation = mat2(
    vec2(cos_a, -sin_a),
    vec2(sin_a, cos_a)
);

VERTEX.xz = rotation * VERTEX.xz;
[/code][/color]

The higher the vertex (y), the more it rotates. This creates a spiral.

[hr]

[b]2. Adding Noise (Erosion)[/b]

Bernini's columns are decorated with vines and bees. We can simulate organic surface detail by layering noise.

[color=green][b]Code[/b][/color]
[color=green][code]
float detail = texture(noise_tex, UV).r;
VERTEX += NORMAL * detail * 0.1;
[/code][/color]

[hr]

[b]3. The Digital Grotesque[/b]

Procedural generation allows for forms impossible in stone. We can animate the twist. The column can breathe.

[color=orange][b]Critical Note:[/b][/color] Baroque art was about motion, emotion, and the breaking of the classical circle into the oval. It was a "glitch" in the Renaissance order.
Procedural geometry is the new Baroque. It favors the variable, the mutating, and the complex over the static and ideal.

[hr]

[color=cyan][b]→ Next: John Cage (Silence)[/b][/color]
Ending with the absence of form.
"""

