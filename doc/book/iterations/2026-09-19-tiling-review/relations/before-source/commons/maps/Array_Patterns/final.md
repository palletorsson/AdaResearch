When does repetition become an environment rather than a picture?

The red bend returns, with its blue corner and ochre interruption. It is the same starting arrangement you met in Tutorial_Pattern, entered here as a fixed source. Your edits from the previous room have not secretly travelled with you. This time the question is what gives the mark a place to appear.

<!-- @pattern_tunnel_machine -->

Take the opening into the side bay. A six-metre passage stands on a raised platform; its console is beside the ramp on the lower floor. Three wedges make a broad ascent. Side walls close the routes around the tunnel, so crossing this bay takes you through it and down the ramp at the far end. The source has sixteen cells. There are considerably more squares inside the tunnel. Find the pale yellow indicator on the floor and compare its position with the console's two addresses.

Press COL +. The surface address advances. Press it again, watching the smaller source address. After four steps, one number has returned while the other has moved on.

```gdscript
column % 4
row % 4
```

These are the wrapping expressions used by the inspector. It displays addresses as `[row, column]`, then the palette index stored there. Surface `[10,1]` returns to source `[2,1]`. Another place can consult the same memory.

The tunnel's renderer first computes a small swatch from the source and its translation rule. The shader samples that swatch across each face. The inspector follows the same cell coordinates back to the four-by-four source. You can move the indicator without changing a single stored colour.

Now press FACE. The indicator moves to the right wall. The panel still speaks in rows and columns, but those directions occupy another plane. On the floor, one direction runs across the passage and the other along it. On the right wall, columns run along the passage and rows descend from the ceiling. The address needs a surface to acquire a direction in the room.

Walk inside. Follow a line to the corner between floor and wall. Each face begins its own grid. A shared motif does not promise that its edges will join there. The corner exposes a decision that was harder to notice on a single flat panel: where should counting begin, and which way should it proceed?

Return to CELL SIZE. A cell now occupies sixty centimetres instead of forty. The source still has four cells across. Its whole motif therefore spans 2.4 metres instead of 1.6. In the previous room, forty centimetres described an entire motif; here the mark has been enlarged so you can inspect its individual addresses. The same number needs its unit and its referent.

The passage has not grown. Its width remains 3.6 metres and its height 3.2. Some divisions fit exactly; others leave a cut cell at an edge. A room does not owe the pattern an integer number of repeats. The inspector selects complete cells; the remaining strip is still there to look at.

Press GRID. The dark joints disappear. Keep walking. No wall has opened and no floor tile has fallen away. Those divisions were drawn in a shader on four large surfaces. The supports that stop your body are separate. UNDO restores the last inspector setting, including cell size and grid visibility.

<!-- @pattern_tile_brick -->

Back among the earlier stations, look at the brick preview. Follow a seam through two neighbouring rows. The boundary steps sideways. Compare that stagger with the tunnel's straight cell divisions and the corner where two faces restart their counting.

A stagger changes how rows relate within a field. A corner changes how a field is carried into space. They can resemble one another as disruptions, but they ask for different changes to the implementation. Keep the motif, the lookup and the carrier available as separate things to question.

<!-- @ -->

An orderly image can conceal a complicated support. A conspicuous seam can reveal the rule more clearly than a perfect join. Neither smoothness nor interruption is automatically the more interesting result. What becomes available to a body that can read the difference?

This passage holds its pattern fully visible. The earlier automatic reveal remains another performance to revisit when we study change over time. Here there is time to compare addresses, then move on. Symmetry_Seventeen will ask what can be classified about an ideal repeating field. Bring the finite edge of this room with you.
