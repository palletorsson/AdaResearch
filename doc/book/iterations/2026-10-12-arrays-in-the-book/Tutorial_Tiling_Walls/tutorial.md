# Walls — the result has another surface

**Learning elements**

- Reusing a saved image
- Image axes and surface orientation
- Appearance versus collision
- Transforming a receiver and its children together

Find the field you followed underfoot, now standing in front of you. At the eye chart, move closer and back. The rule is unchanged while the distance changes how much you can read.

This is a reuse lesson. Bring the PNG made by your Floor study. The new script loads those pixels onto a solid upright panel. It does not contain the pattern generator. You keep that generator in the previous lesson for when you want another result.

## Put the image on a body

Use the same Godot museum project and its `user://` data folder as Floor. Stop the Floor study before running this one: otherwise Floor would save over your chosen image again. On another device or project, copy `ada_array_pattern.png` into that project's user-data folder first. Day Zero covers where those project files live.

Attach this script to an empty `Node3D`, `WallStudy`, at floor level in a clear part of the wall hall. Keep scale at one. Allow a three-metre square panel and space to walk around it. Its picture faces local positive Z. Place it beside the exhibits, away from the actual exit; this is a freestanding study, not a replacement for the museum's guarded hinged wall.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var saved_path := "user://ada_array_pattern.png"
var panel_turn := 0.0
var panel: StaticBody3D
var image := Image.new()

func _ready() -> void:
    if not FileAccess.file_exists(saved_path):
        var label := Label3D.new()
        label.text = "Run the Floor study first.\nIt saves ada_array_pattern.png in this project's user:// folder."
        label.position.y = 1.5
        add_child(label)
        return
    var error := image.load(saved_path)
    assert(error == OK, "The saved pattern could not be read.")
    panel = StaticBody3D.new()
    panel.position.y = 1.5
    panel.rotation_degrees.y = panel_turn
    panel.collision_layer = 1
    panel.collision_mask = 0
    add_child(panel)
    var backing := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(3, 3, 0.1)
    backing.mesh = box
    panel.add_child(backing)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    collision.shape = shape
    panel.add_child(collision)

    var face := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(3, 3)
    face.mesh = quad
    face.position.z = 0.051
    var material := StandardMaterial3D.new()
    material.albedo_texture = ImageTexture.create_from_image(image)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    face.material_override = material
    panel.add_child(face)
```

## Separate the picture from its support

The file check makes the dependency visible. Without Floor's saved result, the study displays an instruction and creates no substitute pattern. `image.load` reads the PNG. The image may contain an exception or a rule you chose; the panel does not need to know how you made it.

The construction brings together things already encountered. The `StaticBody3D` supplies a fixed boundary. Its `BoxMesh` shows the backing; its `BoxShape3D` gives that backing physical extent. The thin `QuadMesh` displays the image just in front, avoiding two visible surfaces at the same depth. Its local XY plane faces positive Z. Image columns run across it; image rows run down it.

`ImageTexture.create_from_image` assigns the saved result to the material. This is the same image-to-texture step as Floor. The material again shows black and white directly. Nothing in these pixels asks for a hole in the collision shape.

Walk towards a black triangle, then a white one. The panel stops your body at both. Walk around its side and look at the plain reverse. The image and the boundary have different responsibilities.

## Two changes to compare

Keep `panel_turn` at zero. Return to the Floor script, switch its exception or change one rule term, and run it to save the new image. Then stop Floor and run Walls again. The picture changes. The panel's position, three-metre size and collision remain the same. This is a deliberate file handoff between runs, not live synchronization between halls.

Now keep that PNG and change `panel_turn` to `90.0`. Run again. Picture, backing and collision turn together because they are children of the same body. A route that crossed the broad face can now pass beside its edge; approaching from the new front still meets a solid panel. The fixed pose is set before physics begins. Making a moving wall yield safely to visitors is the larger installed encounter, not an extra controller hidden in this script.

Choose another angle. Predict where the panel will stand and which way the image will face. Confirm that the saved image is unchanged, then approach from both sides. You are varying the receiver while keeping its input.

In the museum's eye chart, one result appears at several viewing sizes. At the hinged wall, a turn changes access. Our study gives those comparisons a small construction: stored image, visible face, solid support and shared transform. Next, keep the addresses and add a clock. The same places can be read again without moving them.
