# Floor — an address chooses a turn

**Learning elements**

- A function from address to orientation
- Remainder and quarter-turns
- One exception versus a repeated rule
- A generated image saved for another surface

At the museum's four-by-four desk, hold the left sample still and apply the rule to the right. The unit has not changed. Different orientations let neighbouring tiles make a larger figure.

We return from the volume to a plane. Rotation is familiar from Transformation; nested traversal is familiar from Array. Here their relation changes: an address chooses how much to turn the same black-and-white tile. Zero means no added turn. It does not mean an empty place.

## Predict sixteen decisions

Our rule is `(column + row) % 4`. For non-negative indices, remainder by four gives 0, 1, 2, 3 and then returns to zero. Those numbers count quarter-turns. At `[1, 0]` the answer is one; at `[2, 0]` it is two; at `[3, 1]` it is zero.

Write the four answers for one row before running. Notice that the function needs this tile's address, not a picture of the completed field. Then compare plain repetition with the rule.

Save these two files together in your lesson folder. Attach `lesson.gd` to an empty, unit-scale `Node3D` named `FloorStudy` at floor level on clear floor in the existing hall. It creates two two-metre images, with a small gap between them. Allow five metres across. The existing museum floor supports your feet; the image surfaces add no collision. Keep the room, light and player from Day Zero.

The small renderer is printed in full so the rule has no hidden dependency. Begin by reading `turn_at`; the pixel loops below it translate those decisions into a picture. The renderer is support for this lesson, not a demand to learn every image API at once.

### pattern_image.gd

<!-- student-code:pattern_image.gd -->
```gdscript
extends RefCounted

var columns := 4
var rows := 4
var tile_pixels := 32
var use_rule := true
var exception := false
var exception_cell := Vector2i(1, 2)

func turn_at(column: int, row: int) -> int:
    var turns := (column + row) % 4 if use_rule else 0
    if exception and Vector2i(column, row) == exception_cell:
        turns += 1
    return turns % 4

func make() -> Image:
    assert(columns > 0 and rows > 0 and tile_pixels > 1)
    var image := Image.create(columns * tile_pixels, rows * tile_pixels, false, Image.FORMAT_RGB8)
    for row in rows:
        for column in columns:
            var turns := turn_at(column, row)
            for v in tile_pixels:
                for u in tile_pixels:
                    var source := Vector2i(u, v)
                    for quarter in turns:
                        source = Vector2i(source.y, tile_pixels - 1 - source.x)
                    var black := source.x > source.y
                    image.set_pixel(column * tile_pixels + u, row * tile_pixels + v, Color.BLACK if black else Color.WHITE)
    return image
```

### lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const PatternImage = preload("pattern_image.gd")
var columns := 4
var rows := 4
var exception := false
var image: Image
var saved_path := "user://ada_array_pattern.png"

func _ready() -> void:
    var pattern := PatternImage.new()
    pattern.columns = columns
    pattern.rows = rows
    pattern.use_rule = false
    show_image(pattern.make(), Vector3(-1.3, 0.02, 0))
    pattern.use_rule = true
    pattern.exception = exception
    image = pattern.make()
    show_image(image, Vector3(1.3, 0.02, 0))
    var error := image.save_png(saved_path)
    assert(error == OK, "The pattern could not be saved.")
    var label := Label3D.new()
    label.text = "SAME TURN                       ADDRESS CHOOSES TURN"
    label.position = Vector3(0, 1.5, -1.5)
    label.font_size = 26
    add_child(label)

func show_image(picture: Image, at: Vector3) -> void:
    var surface := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(2, 2)
    surface.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_texture = ImageTexture.create_from_image(picture)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    surface.material_override = material
    surface.position = at
    add_child(surface)
```

## What is being turned?

`PatternImage.new()` creates a recipe object. Its `make` function returns an `Image`. The host first disables the address rule to draw plain repetition, then enables it to draw the comparison. The first image keeps its pixels when the recipe changes; each call constructs a new image.

Within one tile, U counts pixels across and V counts down. A pixel is black when U is greater than V; that divides the square along a diagonal. A quarter-turn changes which source pixel we read. Repeating that operation two or three times turns the same motif further. Finally, column and row locate the tile within the complete image.

These are image coordinates. Row does not mean world height. `PlaneMesh` places the picture flat in the study's local XZ plane. `ImageTexture` makes its pixels available to the material. The unshaded material and nearest filtering keep this small comparison legible without asking light to explain the rule. In [Godot's Image API](https://docs.godotengine.org/en/stable/classes/class_image.html), the stored image and the texture assigned to a material are separate resources.

## Change the rule, then one place

In `turn_at`, replace `(column + row) % 4` with `column % 4`. Predict which direction will still change from tile to tile. Run the study and compare both fields. Every row on the right now receives the same sequence of turns. Restore the original expression before the next comparison.

Set `exception` to `true` in `lesson.gd`. The right field receives one extra turn at `[1, 2]`; the left stays unchanged. The condition runs at every address but succeeds at only one. Increasing that cell's turn leaves the source motif and the other fifteen decisions intact.

Change `columns` and `rows` to `8`. The function has not become longer. It is asked at sixty-four addresses, and the first four-by-four corner still receives the same answers. Our display remains two metres wide, so the tiles become smaller. Pixel detail per tile, number of tiles and physical display size are separate choices.

## Keep this result

Each run saves the right image as `user://ada_array_pattern.png`, replacing the previous saved result at that name. `user://` is this Godot project's writable data folder. We check the save result rather than assume a file was written. The PNG contains the pixels; the editable rule remains in your script. A saved image does not preserve why each decision was made.

Choose another rule using column and row, or choose another exception address. Predict one row, run, and locate the change. Keep a result you want to look at upright. In the next hall we will load this exact saved image in the same museum project. We will not generate a replacement and call it your earlier work.
