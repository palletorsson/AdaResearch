# Enlarge the opening, keep the witness

**Learning elements**

- Uniform and unequal scale factors
- Scaling around an origin
- Parent and child transforms
- Local dimensions and world dimensions

In this hall, the furnished room grows while your body keeps its size. A small doorway becomes a possible passage. The bottle also relocates the visitor; that relocation is separate from scaling the room.

Keep Rotation's parent-child arrangement. Replace the rotating pivot with a fixed doorway parent containing three boxes. Remove the clock and face mark. Bring back the familiar black sphere as a size witness, outside the parent that will change. This simple doorway is a visual model; the installed room supplies physical passage.

## The complete study

Attach this `lesson.gd` to an empty, unrotated, unit-scale `TransformStudy` on museum floor. The doorway's origin is at the centre of its threshold. Its initial clear opening is 0.45 metres wide and 0.60 metres high. The sphere's diameter is 0.65 metres.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var doorway := Node3D.new()
var point := MeshInstance3D.new()
var factors := Vector3.ONE

func _ready() -> void:
    assert(factors.x > 0.0 and factors.y > 0.0 and factors.z > 0.0)
    add_child(doorway)
    box(Vector3(0.12, 0.6, 0.2), Vector3(-0.285, 0.3, 0))
    box(Vector3(0.12, 0.6, 0.2), Vector3(0.285, 0.3, 0))
    box(Vector3(0.69, 0.12, 0.2), Vector3(0, 0.66, 0))
    doorway.scale = factors

    var sphere := SphereMesh.new()
    sphere.radius = 0.325
    sphere.height = 0.65
    point.mesh = sphere
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    ink.roughness = 0.18
    point.material_override = ink
    add_child(point)
    point.position = Vector3(1.8, 0.325, 0)

func box(size: Vector3, at: Vector3) -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    body.position = at
    doorway.add_child(body)
```

The two posts and lintel are children of `doorway`. The sphere is a sibling of that parent. Setting the parent's `scale` reaches the three boxes and the distances between them. It does not reach the sphere.

With `factors = Vector3.ONE`, the point is wider than the opening. Change the existing line to `var factors := Vector3(4, 4, 4)` and run again. The clear opening is now 1.80 by 2.40 metres. Every doorway dimension and spacing has grown fourfold. The sphere is still 0.65 metres across.

Each box keeps its local position and mesh dimensions. Its world dimensions change through the parent. The posts' bottom edges stay at floor level because the scaling origin is there. An origin halfway up the door would produce a different relation to the floor.

## Change width without changing height

Set `factors` to `Vector3(4, 1, 1)`. The opening is now 1.80 metres wide but only 0.60 metres high. The sphere remains too tall. This scale changes proportions: X grows, Y and Z do not.

Uniform scale preserves proportions; it does not preserve every possible action around an object. In the installed room, compare the enlarged doorway with the museum frame that stayed outside the changing group.

## Make a deliberate opening

Try `Vector3(2, 2, 1)`. Predict the opening's width, height and depth before running it. The width becomes 0.90 metres and the height 1.20; depth stays unchanged. Explain why the sphere keeps both its position and diameter.

The next hall keeps this size factor but lets your distance choose it. You will change the surroundings by approaching them.
