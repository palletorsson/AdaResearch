# From a stored cell to a visible field

*Coding tutorial draft for Pattern_Foundry. Read the operation here and follow its consequences on the facing page.*

We already know how an array keeps values at addresses. Here we use one small array to supply more visible positions than it stores. A repetition rule tells each position where to look in the source.

This lesson follows `render_surface()` in the museum's `recipe_study.gd`. Its `live` dictionary contains the source card, its size, the palette and the chosen group. `metres` gives the receiving sheet's dimensions. `sampling` says how many image pixels to draw per metre. The node also has access to the loom and the `WallpaperGroups` helper. The excerpts below belong inside that existing function; they are not a standalone scene script.

## 1. Give the receiving image a size

The sheet has a physical size. The image has a pixel size. The code connects them:

```gdscript
var size:=Vector2i(roundi(metres.x*sampling),roundi(metres.y*sampling))
var img:=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
```

For the 1.2 metre square specimen at 100 pixels per metre, this creates a 120 by 120 image. `false` requests no mipmaps; `FORMAT_RGBA8` stores red, green, blue and alpha in eight bits each.

The source card is five by five. We have not enlarged that array to 120 by 120. We have allocated a receiving image whose pixels will look up values from it.

## 2. Turn a surface position into a source address

Inside the nested pixel loops, the function computes two source coordinates:

```gdscript
var source_x:=floori(((x+0.5)/sampling+loom.offset_metres)*n/loom.repeat_metres)
var source_y:=floori((y+0.5)/sampling*n/loom.repeat_metres)
```

Read the first line from inside out. `x + 0.5` chooses the pixel's centre. Dividing by `sampling` converts that position into metres. The offset moves the sampling position along the surface. Multiplying by `n / loom.repeat_metres` converts metres into source-cell steps. `floori` chooses an integer address.

At the initial five-cell card size and 0.3 metre repeat, one cell occupies 0.06 metres. Across a 1.2 metre sheet, the address calculation spans four card widths. The addresses can run beyond the five-cell card; the repetition rule in the next step decides how they return to it.

To try a larger repeat, these two lines can run in an event handler on the study node:

```gdscript
loom.repeat_metres = 0.6
update_specimens()
```

Predict the result before running the change. Under the starting translation rule, two card widths now fit across the sheet. The source still has twenty-five cells and the receiving image still has 120 by 120 pixels. What changed was how quickly the sampled address advances across the same space. Return the value to `0.3` when you finish the comparison.

## 3. Ask the rule, then ask the palette

The next three statements write the result into the image:

```gdscript
var index:int=WallpaperGroups.get_symmetric_color(source_x,source_y,n,live.card,group_id)
var c:Array=live.palette[index]
img.set_pixel(x,y,Color(c[0],c[1],c[2],c[3]))
```

`get_symmetric_color` applies the chosen repetition rule to the address and returns a colour index from the source card. The index is not yet an RGB colour. `live.palette[index]` supplies its four components, and `set_pixel` writes that colour at the receiving pixel.

There are three places to intervene: edit the card, change `group_id`, or change the palette. Each changes a different part of the calculation. Use a pair of unequal neighbouring marks when comparing rules. A symmetrical source can make a changed operation look as if it did nothing.

After both loops finish, `ImageTexture.create_from_image(img)` makes the image available to a material. The function has generated colour; it has not generated the sheet's shape.

## 4. Bend the sheet while keeping its addresses

The study's `bent_sheet()` function creates the flat and curved meshes. Its curved version changes vertex positions and normals. Both versions append the same texture coordinates:

```gdscript
uv.append(Vector2(u,1.0-v))
```

A UV coordinate names a position in the texture. The same coordinate can belong to a vertex on a flat sheet or on a curved one. Both specimens therefore carry the same ordered image across a 1.2 metre surface width, while the curve's projected width is smaller when seen head-on.

Look at the marked cell from the front and then from the side. The geometry changes how the colour reaches your view. The stored card can remain exactly the same.

## 5. Let one receiver decline an update

In `update_specimens()`, a loop visits the registered receivers. Its first decision is:

```gdscript
for receiver:Dictionary in receivers.values():
	if not receiver.linked:continue
```

`continue` skips the rest of this iteration. A held receiver therefore keeps the texture already assigned to its material. The loop can continue to the next receiver; the source and other parts of the museum do not have to stop.

For linked receivers owned by the loom, a later line assigns the newly generated texture:

```gdscript
receiver.mesh.material_override.albedo_texture=textures[metres]
```

The same update function has a separate branch for receivers using an external source such as the studio. The loom excerpts here explain the specimen route; they are not the studio shader's implementation.

Hold the curved specimen, edit the source, and compare it with the flat specimen. You have separated two receivers without giving every repeated mark its own editable value. The place where the program permits an exception determines the size of the difference you can keep.

## Continue building

To let one repeated mark differ independently, what new state would you need? You could keep a table of exceptions indexed by a receiving position, then consult it after calculating the shared pattern. That is a next experiment, not a feature of this instrument yet.

The main text carries this question into the room: which differences can stay, and who receives the next change?
