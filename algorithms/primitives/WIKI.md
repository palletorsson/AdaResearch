# Ada Research — Primitives Sequence

**(Point → Melencolia)**

This document collects the Primitive maps from Point_Zero through Primitives_Melencolia.
Each section introduces a conceptual threshold, staged as a playable scene.

## Point_Zero
**The Origin as Prerequisite**

Point Zero introduces the origin (0,0,0) as a condition rather than an object.
The origin is not something placed in space; it is the shared reference that makes space measurable at all.

In a computational environment, nothing can appear before the system already provides:
- a coordinate frame
- a unit scale
- a temporal update loop
- a rendering pipeline that continuously reasserts world state

The origin is not primarily visual. It is an implicit agreement that lets positions be compared, returned to, and repeated.

Point Zero stages the moment before geometry. Nothing is constructed yet. Instead, the player encounters the infrastructure that allows construction to happen at all.

Behind this moment lies invisible scaffolding: the engine, the world transform, the clock. These systems are already running before the scene begins. They are the conditions of possibility for any geometric act.

Point Zero marks the threshold between the void and the symbolic world.
Nothing happens here yet—and because nothing happens, everything that follows becomes possible.

```gdscript
var origin := Vector3.ZERO
```

## Point_1
**The Point as Position**

A point in Godot is always a position: a `Vector3(x, y, z)`.
A visible point is a representation; the point itself is the coordinate.

This scene introduces a single movable point—minimal, discrete, and unextended—so that “point” is understood as position-as-data.

```gdscript
var point_position := Vector3(3.0, 1.5, 4.0)
```

Rendered as a marker:

```gdscript
var sphere := SphereMesh.new()
sphere.radius = 0.01
sphere.height = sphere.radius * 2.0

var mesh_instance := MeshInstance3D.new()
mesh_instance.mesh = sphere
mesh_instance.position = point_position
add_child(mesh_instance)
```

## Point_Trace
**Duration Appears as Residue**

The Trace is position through time.
As the point moves, the system records a sequence of past positions.

Unlike the line, which compresses movement, the trace accumulates it.
It makes visible both what the system can record and what it must discard: memory limits, sampling thresholds, reference frames.

Movement becomes history—but only under constraint.

```gdscript
var trail_points: Array[Vector3] = []
@export var trail_max_points := 1024
@export var min_segment_distance := 0.01

func maybe_record(pos: Vector3) -> void:
	if trail_points.is_empty():
		trail_points.append(pos)
		return

	var last := trail_points[-1]
	if pos.distance_to(last) >= min_segment_distance:
		trail_points.append(pos)
		if trail_points.size() > trail_max_points:
			trail_points.pop_front()
```

## Point_Line
**Relation and Compression**

The Line is the first formal relation: the shortest connection between two positions.
It introduces direction and distance.

But the line also compresses.
All possible journeys between two points are reduced to a single metric.

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 1, 0)

var v := b - a
var distance := v.length()
var direction := v.normalized()
```

Rendered as a segment:

```gdscript
var cylinder := MeshInstance3D.new()
var mesh := CylinderMesh.new()
mesh.height = distance
mesh.top_radius = 0.02
mesh.bottom_radius = 0.02
cylinder.mesh = mesh

cylinder.position = (a + b) * 0.5
cylinder.look_at_from_position(cylinder.position, b, Vector3.UP)
add_child(cylinder)
```

## Point_Line_Context
**Reference, Snap, and the Grid’s Invitation**

This scene situates the line within a larger system of reference:
- snapping to grid
- parallel and crossing relations
- repeatability and return

The point remains position, but now it becomes addressable.
This is where geometry begins to behave like an interface.

```gdscript
@export var snap_step := 0.25

func snap_vec3(p: Vector3) -> Vector3:
	return Vector3(
		round(p.x / snap_step) * snap_step,
		round(p.y / snap_step) * snap_step,
		round(p.z / snap_step) * snap_step
	)
```

## Point_Triangle_Context
**The First Enclosure**

Three non-collinear points define a plane.
Three relations enclose an interior.

The triangle introduces:
- a face
- orientation (normal)
- area

It is the first geometry that becomes a surface in the strict computational sense.

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(2, 0, 0)
var c := Vector3(1, 0, 2)

var e1 := b - a
var e2 := c - a
var normal := e1.cross(e2).normalized()
var area := e1.cross(e2).length() * 0.5

var st := SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)
st.set_normal(normal)
st.add_vertex(a)
st.add_vertex(b)
st.add_vertex(c)

var mesh := st.commit()
var mi := MeshInstance3D.new()
mi.mesh = mesh
add_child(mi)
```

## Point_Animatedcube
**The Quad and the First Deception**

The quad appears as a single surface, but is always rendered as two triangles.
This is the first geometry where modeling convenience diverges from rendering reality.

Dragging corners reveals:
- planarity failure
- diagonal choice
- shading artifacts

The quad introduces abstraction.

## Primitives_Ignorance
**Engine-Given Forms**

This scene frames primitives as engine-provided givens:
- fast
- legible
- convenient

Ignorance here is structural forgetting.
The system works because we do not constantly confront what these forms exclude.

```gdscript
var cube := BoxMesh.new()
var sphere := SphereMesh.new()
var cylinder := CylinderMesh.new()
```

## Primitives_Portals
**The Torus and Approximation**

The torus is defined by repetition and dual radii.
It is not Platonic. It is Archimedean.

Segment counts become expressive rather than corrective.
Low resolution reveals structure.
Broken symmetry becomes visible and productive.

```gdscript
var torus := TorusMesh.new()
torus.inner_radius = 2.0
torus.outer_radius = 0.5
torus.ring_segments = 32
torus.radial_segments = 16
```

Portal-like case:

```gdscript
torus.ring_segments = 3
torus.radial_segments = 24
```

Approximation leads naturally to π as process—never completed, always approached.

## Primitives_Melencolia
**The Paralysis of Perfect Forms**

This final scene is not another primitive.
It is the affective threshold of having mastered them all.

In Albrecht Dürer’s Melencolia I (1514), every tool of geometry is present—compass, ruler, polyhedron, sphere, magic square—yet the figure remains motionless.

Knowledge is complete.
Direction is not given.

Primitives are the alphabet, not the poem.
The tools are ready. The bell has not rung.

```gdscript
var origin := Vector3.ZERO
var cube := BoxMesh.new()
var sphere := SphereMesh.new()
# Everything is loaded.
# The question is what to build.
```

Melancholy here is not failure.
It is the pause between knowing and making.

## Sequence Summary

This sequence is not a catalog of shapes.
It is a progression of constraints:

- Point — position
- Trace — duration under limits
- Line — relation compressed into measure
- Grid — addressability and governance
- Triangle — enclosure and surface
- Quad — abstraction and deception
- Primitives — engine-given forms
- Torus — approximation and repetition
- Melencolia — the threshold before transformation

You now have the tools.
What comes next is movement, force, change.

The bell will ring when you decide what to build.
