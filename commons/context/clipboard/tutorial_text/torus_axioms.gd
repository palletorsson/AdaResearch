extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]The Torus[/b][/center]
[center][i]Donut Topology[/i][/center]

The torus as a surface of revolution with dual radii

[hr]
[b]Two Radii Define the Ring[/b]
AXIOM 1: A torus requires two radii.
[color=yellow]Code[/color]
[code]
var torus = TorusMesh.new()
torus.inner_radius = 2.0  # Major radius (center to tube center)
torus.outer_radius = 0.5  # Minor radius (tube thickness)
[/code]
Donut shape: big ring + small tube
[i]Concepts: inner_radius, outer_radius, major, minor, donut[/i]

[hr]
[b]Ring Segments[/b]
AXIOM 2: Ring segments define tube smoothness.
[color=yellow]Code[/color]
[code]
torus.ring_segments = 32

More segments = smoother tube
Each segment = one slice of the tube
[/code]
[i]Concepts: ring_segments, tube, smoothness, cross-section[/i]

[hr]
[b]Radial Segments[/b]
AXIOM 3: Radial segments define ring smoothness.
[color=yellow]Code[/color]
[code]
torus.radial_segments = 16

More segments = smoother circular path
Each segment = one slice around the ring
[/code]
[i]Concepts: radial_segments, circular path, revolution, smoothness[/i]

[hr]
[b]Tessellation Combined[/b]
AXIOM 4: Total triangles = ring_segments x radial_segments x 2
[color=yellow]Code[/color]
[code]
torus.ring_segments = 32
torus.radial_segments = 16
# Creates 1024 triangles
[/code]
Low resolution reveals structure High resolution appears smooth
[i]Concepts: tessellation, triangles, resolution, structure[/i]
'''
