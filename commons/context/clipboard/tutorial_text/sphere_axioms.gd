extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Torus[/b][/font_size][/center]
[center][i]Archimedean Curvature and Donut Topology[/i][/center]

The torus is not a Platonic solid.
It is not perfect, not closed, not exhausted.

The torus is a surface of revolution defined by two radii, endlessly looping back into itself. It has no beginning, no end, no privileged face.

If the Platonic solids were the fantasy of perfect enclosure,
the torus is the geometry of return.

[hr]

[b]Two Radii Define the Ring[/b]
[b]AXIOM 1:[/b] A torus requires two radii.

[color=yellow]Code[/color]
[code]
var torus = TorusMesh.new()
torus.inner_radius = 2.0 # Major radius (center to tube center)
torus.outer_radius = 0.5 # Minor radius (tube thickness)
[/code]

One radius defines the loop.
The other defines the body that loops.

This duality matters.

The torus is not built from faces.
It is built from relation between circles.

[i]Concepts: major radius, minor radius, loop, body, return[/i]

[hr]

[b]The Archimedean Move[/b]

The torus belongs to a different lineage than the Platonic solids.

Plato sought perfect, closed forms.
Archimedes accepted approximation, repetition, and limit.

The torus is generated not by folding polygons, but by:
• rotating a circle,
• repeating that rotation,
• approximating continuity through segments.

This is Archimedean geometry:
truth approached, never completed.

[hr]

[b]Ring Segments[/b]
[b]AXIOM 2:[/b] Ring segments define tube smoothness.

[color=yellow]Code[/color]
[code]
torus.ring_segments = 32
[/code]

Each ring segment is a slice of the tube’s circumference.

More segments:
• smoother tube
• higher triangle count
• stronger illusion of continuity

Fewer segments:
• visible structure
• faceting
• emergent rhythm

[i]Concepts: tube, cross-section, repetition, discretization[/i]

[hr]

[b]Radial Segments[/b]
[b]AXIOM 3:[/b] Radial segments define loop smoothness.

[color=yellow]Code[/color]
[code]
torus.radial_segments = 16
[/code]

Each radial segment is a step around the loop.

This is the torus’s time dimension:
a repeated return around the ring.

[i]Concepts: revolution, loop, periodicity, return[/i]

[hr]

[b]Tessellation as Negotiation[/b]
[b]AXIOM 4:[/b] Total triangles emerge from repetition.

[color=yellow]Code[/color]
[code]
torus.ring_segments = 32
torus.radial_segments = 16

Total triangles = ring_segments * radial_segments * 2
= 1024 triangles

[/code]

Low resolution reveals the scaffold.
High resolution performs smoothness.

Smoothness is not real.
It is an agreement.

[i]Concepts: tessellation, illusion, density, agreement[/i]

[hr]

[b]Breaking Symmetry[/b]

Unlike Platonic solids, the torus does not demand symmetry.

Change the segment counts asymmetrically:

[color=yellow]Code[/color]
[code]
torus.ring_segments = 7
torus.radial_segments = 23
[/code]

Suddenly:
• rhythms appear
• patterns drift
• symmetry dissolves
• queer geometries emerge

The torus does not collapse when symmetry breaks.
It becomes expressive.

This is impossible in Platonic solids.
They fail when symmetry fails.

[hr]

[b]The 3-Segment Torus: A Portal[/b]

A special case:

[color=yellow]Code[/color]
[code]
torus.ring_segments = 3
torus.radial_segments = 24
[/code]

With only three segments around the tube:
• the torus opens visually
• voids appear
• the form becomes portal-like

It no longer reads as a solid object.
It reads as a threshold.

This is not enclosure.
This is passage.

[hr]

[b]Topology Over Form[/b]

The torus introduces topology.

Unlike the sphere:
• it has a hole
• it supports looping paths
• it allows non-contractible cycles

A path around the torus is never closed in the same way twice.

The torus is not about surface perfection.
It is about connectivity.

[hr]

[b]Toward π and Endless Return[/b]

Both radii of the torus rely on circles.
Circles invoke π.

Every loop:
• approximates π
• never completes it
• returns again

The torus does not resolve π.
It rehearses it.

This is geometry as process, not product.

[hr]

[b]The Torus as Anti-Platonic Form[/b]

Where Platonic solids claim:
• closure
• perfection
• finality

The torus insists on:
• repetition
• approximation
• endless return

It is not an ideal form.
It is a procedure.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Torus is an Archimedean surface defined by two radii and constructed through repetition and approximation. Unlike Platonic solids, it does not require perfect symmetry or closure. By varying ring and radial segments, the torus reveals rhythmic, asymmetric, and queer geometries. It introduces topology, looping paths, and endless return—leading directly toward π as process rather than number.

[hr]

[color=orange][b]→ Next[/b][/color]
From the torus, geometry opens into fields, curvature everywhere, and surfaces that no longer enclose but connect.
The argument now belongs to topology, morphology, and learning systems.'''
