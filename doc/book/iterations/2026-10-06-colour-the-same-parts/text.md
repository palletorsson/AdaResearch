# Colour — the same parts

**Learning elements**

- RGB colour values
- A palette and an assignment to each part
- Independent material resources
- Changing colour while keeping geometry fixed

Find the first four columns in the Colour hall. They have the same five parts. One coat of ochre gathers the first column into a single body. Beside it, red connects three blocks across a blue sphere. Colour gives your eye another way to group what is there.

We bring the `BoxMesh` and `SphereMesh` constructions from Primitives, their positions and sizes from Transformation, and indexed references from Array. This lesson adds a material colour to each part. The construction stays still while we change the assignment.

## Keep the construction

Work in the existing Endless Museum, beside the entrance columns in `Color_Context_Placed`. Attach this complete `lesson.gd` to an empty `Node3D` named `ColourStudy`, with unit scale and its origin on clear floor. It builds one 4.4-metre column, 1.1 metres wide. Leave room to walk around it. The museum supplies the room, camera, player and light. The script creates every part and material; it needs no child nodes or companion scripts. This reduced colour study has no collision or pickup behaviour.

The five construction calls reproduce the opening column's dimensions and order: broad block, block, sphere, block, dome. They gather familiar mesh creation into two small helpers. The last sphere uses Godot's hemisphere option; its origin sits at the dome's base. Those dimensions are already chosen here. Begin by changing only the two lists at the top.

The palette holds the available colour values. The assignment says where they go: `colour_slots` chooses a palette entry for each part. Changing a value and changing its destination are separate decisions.

<!-- student-code:lesson.gd -->
{{CODE}}

## Give a surface a colour

Run the study with its five zeroes. Every part receives `palette[0]`, the ochre. Walk around it. Different sides catch different light although their assigned colour is the same.

`Color(r, g, b)` supplies red, green and blue channel values. We use values between zero and one. Alpha is omitted, so these colours are opaque. `StandardMaterial3D` describes how a surface is rendered; `albedo_color` sets its base colour. Here roughness stays at 0.55 and the other material settings keep their defaults.

Each call to `add_part` creates a fresh material and assigns it to that mesh instance. This matters even when all five colours are equal. If all parts shared one material, changing that resource would change every part using it. Independent materials let us address their colours separately, just as independent cube instances let us change one transform in Array.

## Give the parts another company

Replace the five zeroes in `colour_slots` with `[1, 1, 2, 1, 2]` and run again. The three blocks become red; the sphere and dome become blue. Their meshes, sizes and positions are unchanged.

There are two addresses here. `i` selects a part, counting upwards from zero. `colour_slots[i]` selects an entry in the palette for that part. At part 2, the slot is 2, so the sphere receives the blue value in `palette[2]`. At part 3, the slot is 1, so the next block returns to red. Several parts can choose the same palette entry while keeping separate materials.

The list records our choice. It does not inspect a mesh and discover its category. We chose these five indices to make the same grouping as the hall's shape-based rule. An automatic shape rule would need to examine a declared kind; it is a possible extension once this assignment is clear.

`apply_colours()` traverses the existing parts and writes each chosen value into its material. It constructs no new geometry. Its assertions check that every part has an assignment and that each palette index exists. They catch an invalid list, not an unsuccessful composition.

## Change the palette; keep the assignment

Keep `[1, 1, 2, 1, 2]`. Replace the red entry with `Color(0.90, 0.22, 0.48)` and run again. The three blocks become pink together. The blue parts stay blue. One palette edit reaches several independent surfaces through the assignment list.

A `Color` is a value copied into `albedo_color`; the material does not keep a live link to the palette entry. Running again calls `apply_colours()` after construction. If a later control changes the palette while the study is running, it must call that function again to update the surfaces.

Now restore the original red and change the assignment to `[1, 2, 1, 2, 1]`. Colour alternates up the stack. The sphere joins the base and dome in red; the other two blocks become blue. This is an authored alternation, not the hall's calculation of a complementary colour from its neighbour. We can make the comparison without introducing that second algorithm here.

## Compose a grouping

Choose two non-neighbouring parts to share one colour, and give an intervening part another colour. Write your five palette indices and predict the result before running. Explain which list changes a colour value and which list changes where that value goes. Check that the construction itself has stayed the same.

Keep the palette, assignment and `apply_colours()` function. They give later work a way to put a chosen colour on a known surface. The larger stacks elsewhere in this hall develop other compositions; this lesson has selected the smaller operation beneath them.

In the next hall, the surface can keep its material while we change the light reaching it. We have assigned an exact value. We have not fixed everything that makes it look the way it does.
