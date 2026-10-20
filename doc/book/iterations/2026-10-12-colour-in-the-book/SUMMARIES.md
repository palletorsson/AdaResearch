# Colour — eight lessons in sequence

12 October 2026. Current canonical tutorials; revisable teaching decisions.

## Color_Context_Placed — Colour — the same parts

Return to the familiar block and sphere, arranged with Transformation's positions and Arrays' indexed references. Build one five-part column and give each part its own material. A palette holds available colours; a second list assigns them to parts. Change the assignment, then the palette, while retaining every mesh and transform. Compose a grouping of separated parts and predict it before running. Carry a colour assignment that can change without rebuilding the body.

**Short AI:** Same five parts. Palette = values; slots = destinations. Own materials. Reassign without remeshing. Predict a grouping.

**Carry:** Palette values, assignment indices and independent material references.

**Next:** Flashlight keeps the surface material and changes the light reaching it.

## Color_Flashlight — Flashlight — keep the surface

Encounter the installed grabbable lamps, then reconstruct their light-to-surface relation with a familiar box and two spotlights. Change one lamp's colour, then its aim, keeping the board and other lamp fixed. Use the local/world distinction when turning a light towards a local target. Choose a new target and predict which contribution moves. Carry the distinction between a material value and illumination; source edits provide controlled comparisons while the museum lamps supply the larger hand interaction.

**Short AI:** Fixed board; two lights. Change one colour/aim. Local target → world look_at. Withdraw one contribution; material stays.

**Carry:** Separate references for the light and the receiving material.

**Next:** Nails uses the carried point to calculate a surface colour.

## Color_Nails — Nails — a position becomes a colour

Bring back the same PointBody and its pickup behaviour. Express its position in the study's local frame, divide by the box dimensions, clamp the three channels and return a Color. Apply that result to a preview; the installed salon's hand bindings remain supplied. Choose a colour, work backwards to its position, and make a second independent receiver of the same returned value. Record one RGB triple for Rainbow. The handoff is an explicit copied value, not an automatic transfer between halls.

**Short AI:** Inherited PointBody. Local p/size → clamp → Color → preview. Bound colour, not hand. Record RGB for Rainbow.

**Carry:** A pure position-to-colour function and a recorded RGB choice.

**Next:** Rainbow places that recorded choice among ordered bands.

## Color_Rainbow — Rainbow — keep the opening

Walk the celebration before choosing whether to make a small arch. Copy the recorded Nails colour into an ordered palette and divide a fixed radial thickness among its entries. Predict band width for two, three, four and one colour while the opening and outer radius stay fixed. The complete band builder is supplied from familiar mesh principles. Compose another palette and distinguish the number of colours from the number of parts: this example couples them, but that coupling is a choice. Carry the ordered palette without making coding a condition of joining the celebration.

**Short AI:** Optional arch. Copy Nails RGB; palette length divides fixed thickness. Opening stays. Colour count need not equal part count.

**Carry:** An ordered palette and the distinction between available values and sampled parts.

**Next:** Pillar replaces selection among entries with a position-to-colour function.

## Color_Pillar — Pillar — colour has a height

Return to the point and position-to-colour function, now through hue, saturation and value. Map a reachable hand-height range onto the tall museum field, then calculate colour separately. Keep X and Z fixed while moving Y; compare low, middle, high and out-of-range values. Choose another horizontal position and predict which HSV parameter changes. The existing pillars and ceiling illustrate the field; the study adds a sampler without rebuilding them. Record an RGB result for Grid, keeping HSV value distinct from illumination and perceived brightness.

**Short AI:** Same point. Hand height → field height → HSV → RGB. Y controls V; no added light. Record sample for Grid.

**Carry:** A recorded RGB sample and separate hand-to-field and field-to-colour functions.

**Next:** Grid keeps a colour at an address after the sampler has moved.

## Color_Grid_Pallet — Grid — a colour left at an address

Reuse Arrays' addresses and the recorded colours from Nails and Pillar in a compact grid. Introduce Palette as a small stateful class with an owned list and current index. Select an address, write one colour, then move elsewhere: the old tile keeps its value. Switch palettes without advancing the other instance, then apply a diagonal rule over all cells. The supplied museum pointer console calls these same operations. Compose a local arrangement and predict what the rule will overwrite. Carry independently owned state and distinguish cell address, instance index and palette index.

**Short AI:** Two Palette instances. Select/write/advance separately. Address keeps colour. Rule overwrites; geometry stays. Pointer console supplied.

**Carry:** Palette class, owned state, explicit address binding and a retained colour per cell.

**Next:** Paint retains deposits at finer surface addresses; Walls later reuses Palette unchanged.

## Color_Paint — Paint — a mark stays on the surface

Keep PointBody's pickup and give it a named spray action. A held, active brush casts a ray; an accepted hit becomes a surface-local address and deposits colour into one retained image. First make a manual mark, miss the canvas, release and drop, checking that new deposits stop while previous ones remain. Change the radius or ink without changing targeting. The full receiver and support files are printed. An automatic caller is optional after this completion point: it uses the same receiver, rather than adding a second painting system. Carry a complete input-to-surface relation and identify where its result is stored.

**Short AI:** Same PointBody. Held + spray + accepted ray → local UV → retained image. Miss/release/drop stop deposits. Automatic caller optional.

**Carry:** Distinct action/hit states and one receiver usable by different callers.

**Next:** Walls changes what a surface lets you see while retaining its physical boundary.

## Color_Walls — Walls — a view through two colours

Bring back whole-body position and rotation and Grid's unchanged Palette class. Give two panes independent materials and palettes; change alpha and transparency mode together while retaining their colliders. Move to alter overlap, then change the second pane's turn to compose another view. The supplied pointer controls switch filter mode and advance the first palette. Arrange one view with overlap and another without, explaining which changes affect appearance and which affect passage. Carry independent source, placement and appearance choices into Tiling, where the familiar disco returns in colour.

**Short AI:** Two panes; two Palettes. Alpha + render mode; collider stays. Move/view/turn separately. Carry independent palette into Pattern_Disco.

**Carry:** A composition separating source values, material state, placement, viewpoint and collision.

**Next:** Pattern_Disco returns to the familiar pattern with an independently replaceable palette.

