What can change when you keep the painted cells exactly as they are?

In the foundry, a small source reached the walls around you. Here, take the opening into the side bay. Two framed fields flank an editor. Both contain the same red bend, the blue corner and the small ochre interruption. Follow the red bend across each field. Does it always face the same way?

<!-- @pattern_maker_station -->

The sixteen buttons on the console show the source. Read them from the top row down. Find the red bend there, then find it again on the left panel. Move one tile to the right. Something has travelled without turning.

On the other panel, the next bend faces back. The painted source still has only sixteen cells. Nothing in that little grid has turned over. Where did the other facing come from?

Press PM. Look at the floor, then back at the source buttons. Press P1 and return. The floor changes its arrangement; the two wall panels keep their respective rules. They let you compare what the floor has just left with what it has become.

The names can wait until you have found the difference. P1 repeats by translation. In this station's PM rule, alternate columns sample the source in reverse across x. The shader begins by separating a position into the tile it belongs to and its position within that tile:

```glsl
vec2 st = uv * tile_scale;
int tile_x = int(floor(st.x));
vec2 local = fract(st);
```

The whole part counts tiles. The fractional part returns to a place inside one tile. For translation, that local address is enough. For the reflected field, one additional condition changes where the lookup goes:

```glsl
if (imod(tile_x, 2) == 1) {
    local.x = 1.0 - local.x;
}
```

These lines run in the wallpaper shader used by the station. They change an address before it reads the source texture. They do not repaint the stored cells. The alternating facing belongs to the relation between copies.

Now press FLIP X. Watch the source this time. Its blue corner crosses to the other side. Both wall fields respond, although their rules remain P1 and PM. Here the operation really does rewrite the array:

```gdscript
row.append(_grid_data[y][tile_size - 1 - x])
```

The line takes a cell from the opposite end of its row. Press FLIP X again. The second reversal brings every cell back. Try ROTATE, then follow the corner through four presses. UNDO takes you back one editing operation; RESET restores the starting mark and the translating floor. Reset can itself be undone.

Choose a paint colour and press a source cell. Put a solitary mark where the motif was quiet. Both fields receive it. Step back. Your interruption has become regular too.

A repeating system can make room for an unexpected mark while giving that mark a schedule. What would it take to let one copy depart without sending the departure everywhere? In the foundry you could hold a receiving surface apart from its source. Here the source is shared deliberately, so an edit travels through every copy. Neither arrangement answers every desire.

The panels and floor give each tile forty centimetres. The floor has more copies because it extends further. On the reflected panel, facing alternates across tile columns: the two-column cycle is wider than the individual tile. A boundary around one copy does not necessarily enclose the whole repeating relation.

<!-- @ -->

The mark is made of cells, but the apparent continuity between copies is another decision. This lesson uses nearest-cell sampling, so a colour holds its square until another cell begins. A softer-looking edge would need a different account of how those stored values become visible. Sixteen cells have never been the whole surface, however completely they seem to occupy it.

For a moment, a field may look unchanged even after an operation. A very symmetrical source can conceal a reversal. Add a difference and try again. The useful mark may be the one that refuses to look the same from every direction.

In Array_Patterns, the repeated field extends along an environment. Keep these two questions available as you enter: what rule relates the copies, and what surface gives those relations a place to appear?
