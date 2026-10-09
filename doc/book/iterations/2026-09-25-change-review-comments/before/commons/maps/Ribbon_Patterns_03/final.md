# What can you take with you?

Look down before choosing another appearance. In the museum, your garment grows as you enter new sequences. Returning to one does not add another layer. If you chose a nail colour in the salon, your virtual hands have already carried one decision here. A dress can carry part of the walk too.

The mark has crossed a floor, reflected, slipped along a row and acquired depth. In the previous room its values stayed fixed while the surface changed how they appeared. Here the surface is waiting beside a body. Find the bent red mark on both. What would have to stay the same for you to call this the same fabric?

<!-- @fabric_shader_studio -->

Choose one of the four paint colours, then touch a square in the small source array. Watch the wall and the skirt together. One address changes; many places answer. **UNDO** brings the earlier source back. We still have the array we learned to read. We have given it somewhere else to arrive.

![The fabric studio and preview dress inside the museum](/book-review/doc/book/figures/tiling/fabric-studio-museum.png)

*The small source reaches a flat wall and a skirt. The crown and sleeves keep the look’s own materials.*

Press **UV / FABRIC**. The familiar mark disappears into a coloured field. Walk around the preview skirt. Where does the colour return to its beginning? This view draws the surface's own two coordinates as red and green. A curved body can carry a flat address system. It also has to decide where that system joins, ends or starts again.

Return to the fabric and press **OFFSET**, then **REPEAT**. Which operation moves the mark? Which makes more copies fit? The wall and skirt both begin with four horizontal repeats and two vertical repeats in their own UV coordinates. Their physical widths differ. The wall is three metres wide: four copies sit 0.75 metres apart. Four copies around this skirt do not promise that same spacing.

```glsl
vec2 address = UV * vec2(repeats, 2.0) + vec2(phase, 0.0);
ALBEDO = texture(motif, address).rgb;
```

The source texture is four by four pixels, read with nearest filtering. `UV` supplies an address from the mesh; multiplication repeats it, addition shifts it, and the texture wraps. A small statement keeps finding new places to speak. The skirt's side and caps bring their own UV layout. We have not made a tailor's continuous cutting pattern, or promised that every seam will match.

Try **CUT OUT**. Narrow strips disappear from the wall and skirt. Look through a strip, then try to move through the sample wall. The view opens. The collision still refuses you.

```glsl
if (cut_out && fract(address.x) > 0.8) discard;
```

Here `discard` stops drawing a fragment. It does not cut a passage into the collision shape. There are already two accounts of the wall: one receives your gaze, another receives your attempt to cross. Finding their disagreement gives us somewhere precise to work. A visible opening has made a promise that the movement system does not keep.

Turn the cut-outs off. Press **FINISH** and compare a pale patch on the plane with one turning around the skirt. This control changes roughness and metallic response in the engine's material model. It leaves the source alone. Now try **VERTICES** and look along an edge.

```glsl
VERTEX += NORMAL * amplitude *
    sin(UV.y * 18.849556 + UV.x * 6.283185);
```

The shader moves rendered vertices along their normals, by at most 0.04 local units. The wall's subdivisions provide vertices to move. The garment has its own mesh and scale, so its result differs. Collision stays at the old shape; this deformation does not simulate cloth, gravity or a moving hem. Even the shading normals retain the original mesh directions. An edge has changed, but several systems still remember the earlier body.

<!-- @super_drag_mirror -->

Use **LOOK** to choose a silhouette for the preview. When you want to carry the current recipe, press **SAVE**, then **WEAR SAVED**. You take on the preview's silhouette as well as its saved fabric. The fabric goes onto your skirt; your bodice, crown and sleeves keep the chosen look's own materials. Walk to the mirror.

This looking glass sees the body you are wearing in the shared scene. Turn slightly. Find the altered source cell again. It belongs to the recipe, but the shape and viewpoint have given it another appearance. What seemed like a surface sample is now part of how you meet yourself.

The chosen look keeps the growth your walk has already given it. As new sequences arrive, the hem can descend and spread without adding another copy of the painted mark. The same number of repeats has more cloth to occupy. The source stays small; its reach changes with the body. Which part of this dress would you call the same?

Use **NEXT** or **PREVIOUS** at the mirror to change your look. The new skirt receives the saved recipe. **WALK DRESS** returns to your walking costume; the recipe waits in the wardrobe until you choose a skirted look again. The permission to travel was quite specific: the program looks for a mesh named `Skirt`. Other parts of the outfit have not been invited into this exchange. There is room for another garment adapter here, and for a question about who gets to define the parts of a body.

Return to the studio and edit a cell. Your worn skirt keeps the saved version. **SAVE** replaces the stored recipe; **WEAR SAVED** chooses to wear it again. **UNDO** can restore the outfit and fabric from before a wear action. It follows the studio's recent actions and does not erase or rewind the saved recipe file.

<!-- @drag_catwalk -->

Press **RUNWAY SAVED**, then join the four performers. Find the same mark moving towards you and away. Their skirts receive the stored recipe; their other materials and their walking route remain their own. **SWAP LOOKS** changes their silhouettes while keeping the fabric. The studio's **UNDO** can restore each performer's previous fabric.

These walkers follow a programmed route. Their steps and poses do not prove that the garment can balance, bend or bear weight. Yet they make another comparison available: a recipe shared across bodies, encountered at different moments. Repetition can make a group legible without making its members look identical.

<!-- @ -->

Colour supplied values. Arrays gave them addresses. Patterns gave us rules for returning to those addresses, and shaders let the receiving surface take part. We can now carry a small source into a room, a garment and a procession. Each carries something of it; each leaves something unresolved.

We have followed one mark as its address, surroundings and carrier changed. In **Change_Intro**, a curve waits for us. Read its height at two places and join them with a line. The line can slope down while the curve beside your first reading rises. How far should we look before saying which way something is changing?
