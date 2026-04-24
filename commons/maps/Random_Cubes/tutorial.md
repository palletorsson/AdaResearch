# Random Cubes

Each cube remembers its coin flips. Build the arena where form encodes chance.

Declare the random cube.

```gdscript
class_name RandomEdgeCube
extends Node3D

@export var edge_chance: float = 0.5
var edge_profile: PackedInt32Array = PackedInt32Array()
```

A cube has 12 edges. Each edge is flipped on or off by a chance. The profile records the result.

Flip the edges.

```gdscript
func flip_edges() -> void:
    edge_profile.clear()
    for i in 12:
        edge_profile.append(1 if randf() < edge_chance else 0)
```

Twelve flips per cube. Each flip decides whether that edge is beveled, hollowed, or plain. The profile is the cube's signature.

Build the cube mesh from the profile.

```gdscript
func build_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in 12:
        if edge_profile[i] == 1:
            _add_beveled_edge(st, i)
        else:
            _add_plain_edge(st, i)
    mesh_instance.mesh = st.commit()
```

The mesh assembles from per-edge rules. Beveled edges get a small chamfer; plain edges stay sharp. The visual is the profile made stone.

Place a field of cubes.

```gdscript
func populate_field() -> void:
    for x in 6:
        for y in 6:
            var cube := preload("res://commons/artifacts/randomness/random_edge_cube.tscn").instantiate()
            cube.position = Vector3(x * 1.5, 0.0, y * 1.5)
            cube.flip_edges()
            cube.build_mesh()
            add_child(cube)
```

36 cubes, 36 unique profiles. No two cubes match. The grid makes differences legible side by side.

Highlight the current cube on inspection.

```gdscript
func highlight(cube: Node3D, active: bool) -> void:
    cube.material_override.emission = Color.WHITE if active else Color.BLACK
    cube.material_override.emission_energy_multiplier = 0.3 if active else 0.0
```

Inspection tints the cube. The learner can see which one they are reading.

Readout the profile.

```gdscript
func readout(cube: RandomEdgeCube, label: Label3D) -> void:
    label.text = "profile: " + str(cube.edge_profile)
```

A label shows the 12-bit profile beside the cube. The number is the cube; the cube is the number.

Offer a dice throw.

```gdscript
func _on_dice_thrown(face: int) -> void:
    edge_chance = float(face) / 6.0
    for cube in cubes:
        cube.flip_edges()
        cube.build_mesh()
```

Throwing a die changes the edge chance for the whole field. The population responds to a single roll. Randomness scales.

You have seen form encoding chance. The next map, Random Rotate, moves randomness into three axes.
<<</MAP>>>

Save a profile to disk.

```gdscript
func save_profile(cube: RandomEdgeCube, slot: int) -> void:
    UserSettings.set_value("cubes/slot_%d" % slot, cube.edge_profile)
```

Any profile can be saved and reloaded later. Randomness becomes archivable.

More rolls produce more varied profiles. The field reads richer over time.
