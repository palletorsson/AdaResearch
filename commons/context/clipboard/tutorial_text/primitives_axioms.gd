extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Platonic Solids[/b][/font_size][/center]
[center][i]Perfect Forms Outside Space-Time[/i][/center]

"Let no one ignorant of geometry enter here."

This inscription stood above the entrance to Plato's Academy in ancient Athens. Geometry was not merely mathematics - it was the pathway to understanding eternal truth. For Plato, certain forms existed outside space and time, perfect and unchanging, in a realm beyond the material world.

These are the Platonic solids: five perfect polyhedra that the divine craftsman used to build the cosmos.

[hr]

[b]The Five Perfect Forms[/b]

Only five polyhedra satisfy the requirements of Platonic perfection:
- All faces are identical regular polygons
- All vertices are identical (same number of faces meet)
- All edges are identical length
- Perfect symmetry

[color=yellow][b]The Five:[/b][/color]

**1. Tetrahedron** - 4 triangular faces (Fire)
**2. Cube** - 6 square faces (Earth)
**3. Octahedron** - 8 triangular faces (Air)
**4. Dodecahedron** - 12 pentagonal faces (Cosmos)
**5. Icosahedron** - 20 triangular faces (Water)

Plato assigned each solid to a classical element. The dodecahedron, most complex, represented the cosmos itself.

These are the only five. Euclid proved in the Elements that no other regular convex polyhedra exist.

[hr]

[b]Why Only Five?[/b]

At each vertex, multiple identical faces must meet. The angles must sum to less than 360 degrees (or the faces would lie flat).

[color=yellow][b]The Constraint:[/b][/color]

**Triangular faces:**
- 3 triangles at vertex: 3 × 60° = 180° → Tetrahedron
- 4 triangles at vertex: 4 × 60° = 240° → Octahedron
- 5 triangles at vertex: 5 × 60° = 300° → Icosahedron
- 6 triangles at vertex: 6 × 60° = 360° → Impossible (flat)

**Square faces:**
- 3 squares at vertex: 3 × 90° = 270° → Cube
- 4 squares at vertex: 4 × 90° = 360° → Impossible

**Pentagonal faces:**
- 3 pentagons at vertex: 3 × 108° = 324° → Dodecahedron
- 4 pentagons at vertex: 4 × 108° = 432° → Impossible

**Hexagons and beyond:** Too large - even 3 hexagons = 360°

This is why there are exactly five. Not four, not six. Five perfect forms, proven by mathematical necessity.

[hr]

[b]Foldable, Knowable, Computable[/b]

The Platonic solids are discrete. Every property is rational, calculable, exact:

[color=yellow][b]Code: The Tetrahedron (Simplest)[/b][/color]
[code]
# 4 vertices, 6 edges, 4 faces
var v0 = Vector3(1, 1, 1)
var v1 = Vector3(1, -1, -1)
var v2 = Vector3(-1, 1, -1)
var v3 = Vector3(-1, -1, 1)

# All coordinates are integers
# All edges equal length
# All faces identical equilateral triangles
[/code]

Each solid can be unfolded into a flat net - a pattern that can be drawn on paper, cut out, and folded into 3D form:
- Cube net: 6 squares arranged in a cross
- Tetrahedron net: 4 triangles in a strip
- Octahedron net: 8 triangles in a diamond pattern

They are predictable. Mirrored. Symmetric. Knowable.

[hr]

[b]Plato's Timaeus: The Divine Craftsman[/b]

In the *Timaeus*, Plato describes how the Demiurge (divine craftsman) constructed the cosmos from geometric forms:

> "In the first place, then, it is clear to everyone that fire, earth, water, and air are bodies... Now all bodies are bounded by surfaces... [constructed from] triangles."

The four elements were built from Platonic solids:
- **Fire** (Tetrahedron) - sharp, cutting, destructive
- **Earth** (Cube) - stable, stackable, foundational
- **Air** (Octahedron) - light, mobile
- **Water** (Icosahedron) - smooth, flowing

The **Dodecahedron** was reserved for the shape of the cosmos itself - the container of all other forms.

This was not metaphor. Plato believed the physical world was literally built from these geometric primitives.

[hr]

[b]Discrete, Algorithmic, Perfect[/b]

The Platonic solids represent a worldview:

**1. The world is discrete**
Space is not continuous - it is made of countable units (vertices, edges, faces).

**2. The world is algorithmic**
All properties are calculable. No irrationals, no infinities, no approximations.

**3. The world is ideal**
Perfect forms exist eternally, unchanging, in a realm beyond matter.

[color=yellow][b]Code: Perfect Symmetry[/b][/color]
[code>
# The cube has perfect rotational symmetry
# Rotate 90° around any axis through face centers
# → Returns to identical configuration

# 24 rotational symmetries total
# (48 if including reflections)

# All computable, all exact, all rational
[/code]

The Platonic solids are the geometry of certainty.

[hr]

[b]In the 3D Engine[/b]

Modern 3D engines provide Platonic solids as built-in primitives:

[color=yellow][b]Code: Creating the Forms[/b][/color]
[code]
# Cube (Earth)
var cube = BoxMesh.new()
cube.size = Vector3(1, 1, 1)

# The engine provides these perfect forms
# ready to instantiate, ready to render
# Plato's ideals made material (or digital)
[/code]

They are fast to render (few vertices), easy to calculate (rational coordinates), and foundational to 3D graphics. The cube is the unit of voxel space. The tetrahedron is used in mesh decimation. The icosahedron is the basis for geodesic spheres.

The Platonic solids are not historical curiosities - they are the primitives of computational geometry.

[hr]

[b]What the Platonic Solids Cannot Represent[/b]

But there are forms they cannot capture:

- **Curves** - All faces are flat, all edges straight
- **Irrationals** - All measurements rational (π never appears)
- **Infinity** - Finite vertices, finite faces
- **Organic shapes** - Perfect symmetry excludes biological forms
- **Continuous motion** - Discrete structure, discrete transformations

The Platonic solids are the geometry of architecture, crystallography, and Cartesian space. But not the geometry of spheres, spirals, or living bodies.

[hr]

[b]Materialist vs Idealist[/b]

Plato's claim was metaphysical:

**Idealist Position:**
The perfect cube exists eternally in a realm of forms. Physical cubes (wooden blocks, dice) are imperfect copies - shadows of the ideal. The true cube is timeless, spaceless, perfect.

**Materialist Critique:**
Only physical cubes exist. The "perfect cube" is an abstraction - a generalization from many imperfect instances. The ideal is derived from matter, not prior to it.

**The GPU's Position:**
The GPU can render a perfect cube (within floating-point precision). Does this mean Platonic ideals can exist in silicon? Or does the discrete render simply prove that perfection is algorithmic, not transcendent?

[hr]

[b]The Question of Discreteness[/b]

The Platonic solids imply: **the world is fundamentally discrete**.

If matter is built from geometric atoms (solids), then:
- Space is quantized (smallest unit = vertex)
- All properties are rational (no infinite decimals)
- The cosmos is computable (algorithm generates all forms)

But quantum mechanics suggests space-time might not be continuous. String theory proposes Planck-length limits. Digital physics asks: is the universe a cellular automaton?

The Platonic solids are not just ancient philosophy - they are the discrete foundations of computational worlds we build today.

[hr]

[b]"Let No One Ignorant of Geometry Enter Here"[/b]

Plato's inscription was a warning and a promise:

**Warning:** Geometry is difficult. Perfect forms demand rigorous thinking.

**Promise:** Through geometry, you access eternal truth - forms that exist outside time, unchanged by matter, knowable by reason alone.

In 3D graphics, we inherit this Platonic toolkit: the cube, the mesh, the vertex. We build worlds from discrete units, perfect primitives, rational coordinates.

But the next step breaks this perfection.

The sphere requires π - an irrational, infinite decimal.
The sphere has infinite surface points - not discrete vertices.
The sphere cannot be folded from a flat net.

The sphere is where Platonic perfection ends, and Archimedean approximation begins.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Five Platonic Solids are the only regular convex polyhedra: Tetrahedron, Cube, Octahedron, Dodecahedron, Icosahedron. They are discrete, foldable, rational, and perfectly symmetric. Plato believed the cosmos was built from these forms - ideal geometries existing outside space-time. They represent a worldview where reality is algorithmic, discrete, and computable. They are the primitives of 3D engines and the foundations of Cartesian space.

[hr]

[color=orange][b]Next:[/b] The Sphere[/color]
Where the Platonic solids were perfect, the sphere requires approximation.
Where they were rational, the sphere involves π (irrational, infinite).
Where they were discrete, the sphere is continuous.

The sphere is where computation meets the transcendental.

'''
