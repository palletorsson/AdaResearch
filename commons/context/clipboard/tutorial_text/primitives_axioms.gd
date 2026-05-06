extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Platonic Solids[/b][/font_size][/center]
[center][i]Perfect Forms and the Fantasy of Discreteness[/i][/center]

“Let no one ignorant of geometry enter here.”

This inscription marked the entrance to Plato’s Academy. Geometry was not merely a tool—it was a path to truth. For Plato, certain forms existed outside space and time: perfect, eternal, and unchanging.

These are the Platonic solids: five polyhedra that exemplify the idea of absolute geometric order.

[hr]

[b]The Five Perfect Forms[/b]

Only five convex polyhedra satisfy the conditions of Platonic perfection:

• All faces are identical regular polygons
• The same number of faces meet at every vertex
• All edges are equal
• The form is fully symmetric

[color=yellow][b]The Five:[/b][/color]

• Tetrahedron — 4 triangular faces
• Cube — 6 square faces
• Octahedron — 8 triangular faces
• Dodecahedron — 12 pentagonal faces
• Icosahedron — 20 triangular faces

Plato associated these forms with the elements and the cosmos itself. Euclid later proved that no other regular convex polyhedra are possible.

There are exactly five.
This is not tradition—it is necessity.

[hr]

[b]Why Only Five?[/b]

At each vertex, identical faces must meet. The interior angles must sum to less than 360°, or the form collapses into a plane.

[color=yellow][b]Angular Constraint:[/b][/color]

• Triangles: 3, 4, or 5 can meet
• Squares: only 3 can meet
• Pentagons: only 3 can meet
• Hexagons or larger: impossible

This constraint closes the system.

The Platonic solids are not chosen—they are exhausted.

[hr]

[b]Discrete, Finite, Exact[/b]

Each Platonic solid is:

• Finite in vertices, edges, and faces
• Foldable into a flat net
• Fully describable by rational relations

[color=yellow][b]Code: Tetrahedron[/b][/color]
[code]
var v0 = Vector3( 1, 1, 1)
var v1 = Vector3( 1, -1, -1)
var v2 = Vector3(-1, 1, -1)
var v3 = Vector3(-1, -1, 1)
[/code]

Everything is countable.
Everything is computable.

This is geometry without remainder.

[hr]

[b]Plato’s Cosmology[/b]

In the Timaeus, Plato describes a universe constructed from these solids. Matter itself was thought to be assembled from triangles, folded into polyhedra, assembled into bodies.

This was not metaphor.
It was ontology.

The world was thought to be built from perfect shapes.

[hr]

[b]A Worldview Encoded in Geometry[/b]

The Platonic solids imply three assumptions:

Discreteness — the world is made of countable parts

Rationality — all measures are exact and finite

Stability — form precedes matter

This is the geometry of certainty.

No curves.
No infinities.
No approximation.

[hr]

[b]The GPU Inherits the Dream[/b]

Modern 3D engines reproduce this Platonic fantasy.

[color=yellow][b]Code: Engine Primitives[/b][/color]
[code]
var cube = BoxMesh.new()
cube.size = Vector3.ONE
[/code]

These primitives are fast, stable, and predictable.
They are ideal for computation.

In this sense, the GPU is profoundly Platonic: it prefers symmetry, discreteness, and exact repetition.

[hr]

[b]What the Platonic Solids Cannot Express[/b]

Yet something is missing.

They cannot express:

• Curvature
• Continuity
• Irrational ratios
• Smooth transition
• Living form

π does not appear.
Infinity does not appear.
The sphere does not belong.

[hr]

[b]Idealism Meets Approximation[/b]

Plato believed the ideal preceded the material.

A computational perspective suggests the opposite: ideals emerge from approximation and repetition.

The GPU can render a “perfect” cube—but only within floating-point tolerance. Perfection here is not eternal; it is bounded by precision.

The Platonic solids do not exist outside computation.
They exist because computation prefers them.

[hr]

[b]The Limit of Perfection[/b]

The Platonic solids represent the last moment where geometry can pretend to be complete.

After this point:

• π enters
• Curvature dominates
• Approximation becomes necessary
• Surfaces multiply without closure

The fantasy of perfect discreteness collapses.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Platonic solids are the only perfectly regular convex polyhedra. They represent a worldview of discrete, rational, computable space—geometry without remainder. They are foundational to both ancient cosmology and modern 3D engines. But their perfection is also a limit. Beyond them lie curves, irrationality, and approximation.

[hr]

[color=orange][b]→ Next: The Sphere[/b][/color]
Where the Platonic solids end, curvature begins.
Where discreteness fails, approximation takes over.
The sphere introduces π, infinity, and the breakdown of perfect form.'''
