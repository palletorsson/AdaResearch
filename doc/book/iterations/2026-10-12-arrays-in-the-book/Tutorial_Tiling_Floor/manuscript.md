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

<!-- include:pattern_image.gd -->

### lesson.gd

<!-- include:lesson.gd -->

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
