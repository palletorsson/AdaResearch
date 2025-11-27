extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Melting Bernini[/b][/font_size][/center]
[center][i]Erosion as Sculpture[/i][/center]

[b]Columns of Noise[/b]

Here, 3D noise does not just generate terrain; it eats away at structure.
We start with perfect columns - classical, rigid, Euclidean order.
Then we apply **3D Noise** as a "melting" function.

[hr]

[b]The Algorithm[/b]

[color=yellow][b]How it works:[/b][/color]
[code]
# For each vertex in the column mesh:
func distort_vertex(vertex: Vector3, time: float) -> Vector3:
    # Sample 3D noise at vertex position
    var noise_val = noise.get_noise_3d(vertex.x, vertex.y + time, vertex.z)
    
    # Push vertex outward/inward based on noise
    # The "melt" effect comes from moving noise through Y (time)
    return vertex + (normal * noise_val * melt_intensity)
[/code]

[hr]

[b]Digital Materiality[/b]

In the physical world, entropy (melting, erosion) is a one-way street. Things fall apart.
In this digital space, entropy is a **function**. We can:
- Pause the melting
- Reverse it
- Loop it

This is **reversible entropy**. The "ruin" is not a state of decay, but a calculated coordinate transformation.

[color=pink]Critique: We often treat "glitch" or "noise" as errors. Here, noise is the sculptor. The "perfect" column is boring; the "melted" column has character, history, and organic complexity.[/color]

[hr]

[b]Instructions[/b]

1. Observe how the noise field moves through the columns.
2. Notice that they are all sampling the *same* noise field, but at different offsets.
3. This is not random chaos; it is a coherent field of distortion.
'''

