**The Cube**
Six Faces, First Volume

If the Triangle enclosed area and the Quad negotiated surface, the Cube is the first geometry that occupies volume. It has interior. It displaces space. It blocks passage.

The Cube is the first form that asserts: this space is taken.

---

## Six Faces: Enclosure in Three Dimensions

A cube is six square faces arranged orthogonally, enclosing a finite region of space. Where the triangle drew a boundary on a plane, the cube extends enclosure into depth.

**Code: Cube Vertices**

```
var v0 = Vector3(-0.5, -0.5, -0.5)
var v1 = Vector3( 0.5, -0.5, -0.5)
var v2 = Vector3( 0.5, 0.5, -0.5)
var v3 = Vector3(-0.5, 0.5, -0.5)
var v4 = Vector3(-0.5, -0.5, 0.5)
var v5 = Vector3( 0.5, -0.5, 0.5)
var v6 = Vector3( 0.5, 0.5, 0.5)
var v7 = Vector3(-0.5, 0.5, 0.5)
```

Eight corners. Twelve edges. Six faces.
One closed interior.

---

## From Surface to Solid

Each face of the cube is a quad, internally rendered as two triangles. The cube as a whole is composed of twelve triangular faces.

**Code: Rendering the Cube**

```
var box_mesh = BoxMesh.new()
box_mesh.size = Vector3(1, 1, 1)

var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = box_mesh
add_child(mesh_instance)
```

The cube is the first primitive where surface multiplication produces interior.

---

## Volume: The Measure of Occupation

Unlike surfaces, volume excludes.
Only one thing can occupy a given volume at a time.

**Code: Volume**

```
var volume = 1.0 * 1.0 * 1.0 # cubic units
```

Volume is not just measure — it is claim.

The cube does not merely appear in space.
It displaces what was there.

---

## Collision: Enforced Boundaries

With volume comes obstruction.

**Code: Collision Shape**

```
var static_body = StaticBody3D.new()
var collision_shape = CollisionShape3D.new()
var box_shape = BoxShape3D.new()

box_shape.size = Vector3(1, 1, 1)
collision_shape.shape = box_shape

static_body.add_child(collision_shape)
add_child(static_body)
```

The cube enforces its boundary.
Movement is stopped.

The triangle distinguished inside and outside.
The cube prevents entry.

---

## Occlusion: Control of Visibility

The cube not only blocks movement — it blocks sight.

**Code: Occlusion**

```
var space = get_world_3d().direct_space_state
var ray = PhysicsRayQueryParameters3D.new()
ray.from = Vector3(0, 0, -5)
ray.to = Vector3(0, 0, 5)

var result = space.intersect_ray(ray)
```

What lies behind the cube becomes inaccessible to vision.
The cube governs perception as well as motion.

---

## Inside and Outside, Revisited

The triangle created an inside/outside distinction on a surface.
The cube extends this distinction into volume.

**Code: Point-in-Volume Test**

```
func is_inside(p, min, max):
return (
p.x >= min.x and p.x <= max.x and
p.y >= min.y and p.y <= max.y and
p.z >= min.z and p.z <= max.z
)
```

A position is either inside or outside.
There is no gradient, no ambiguity.

---

## The Cube as Spatial Unit

The cube is the fundamental unit of voxel space.
Entire worlds are built from cubic cells.

**Code: Voxel Space**

```
for x in range(10):
for y in range(5):
for z in range(10):
var cell = Vector3(x, y, z)
```

Cubes tile three-dimensional space perfectly.
They are the Cartesian grid made solid.

---

## What the Cube Cannot Express

The cube is rigid and rectilinear.

It cannot easily express:
• curvature
• organic form
• gradual transition
• porous boundaries

The cube is the geometry of construction, not growth.

---

## The Cube as Architecture

With the cube, geometry becomes inhabitable and restrictive.
Space is no longer only measured or enclosed — it is regulated.

Walls, rooms, volumes, obstacles.
Navigation becomes necessary.

The cube is the first geometry that feels like an object.

---

**Summary:**
The Cube is the first volumetric primitive. Six faces enclose interior space, producing volume, collision, and occlusion. It occupies space, blocks movement, and governs visibility. The cube is the atomic unit of voxel worlds and rectilinear digital architecture.