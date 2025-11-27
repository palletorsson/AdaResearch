extends Node

var content = """[font_size=28][b]Spherical Harmonics[/b][/font_size]
[i]Vibrating the Void[/i]

[i][color=gray]Summary: When a wave is confined to the surface of a sphere (like an electron in an atom), it cannot just be any shape. It must fit perfectly, or it will cancel itself out. These allowed shapes are Spherical Harmonics—the standing waves of the 3D world.[/color][/i]

[hr]

[b]1. The Geometry of Quantization[/b]

On a line, a standing wave must fit half-wavelengths (n * lambda/2).
On a sphere, the math is harder (Legendre polynomials), but the principle is the same: only certain integer modes are allowed.

These are the [b]Quantum Numbers[/b] (l, m).

[hr]

[b]2. Visualizing Orbitals[/b]

• [b]l=0 (s-orbital):[/b] A sphere.
• [b]l=1 (p-orbital):[/b] A dumbbell / hourglass.
• [b]l=2 (d-orbital):[/b] A cloverleaf.

In this scene, we map the magnitude of the harmonic to the radius of the mesh.

[color=green][b]Code[/b][/color]
[color=green][code]
# Simplified shader logic
float harmonic = calculate_Ylm(l, m, theta, phi);
VERTEX += NORMAL * abs(harmonic) * amplitude;
[/code][/color]

[hr]

[b]3. Basis Functions[/b]

Just as sine waves are the "pixels" of 1D audio, Spherical Harmonics are the "pixels" of 3D lighting. We use them to store global illumination (light probes) because they compress complex light environments into a few coefficients.

[hr]

[b]4. The Shape of Probability[/b]

In quantum mechanics, these shapes are not solid. They are probability clouds. The electron is not *at* a place; it is the *shape* of the harmonic.

[color=orange][b]Critical Note:[/b][/color] Matter is music. The hardness of the table, the shape of the atom—these are not static solids, but stable vibration modes of a field. We are walking through a symphony we cannot hear.

[hr]

[color=cyan][b]→ Next: The Dancing Body[/b][/color]
Applying waves to the human skeleton.
"""
