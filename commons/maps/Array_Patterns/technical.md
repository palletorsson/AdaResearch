# A tile editor and patterned floor where small arrays replicate by translation, rotation, reflection, and glide — symmetry operations made visible

Array_Basics established the grid — indexed cells, sequential access, the 2D array as a container with integer addresses. Now the grid becomes a canvas, and repetition becomes design. A single 4x4 tile, painted by hand, stamps itself across a floor. Change one cell in the tile and every copy changes. Mirror the tile and a kaleidoscope unfolds. Offset alternate rows and bricks appear. Rotate and interleave and herringbone emerges. The operations are few. The patterns are inexhaustible.

This is not decoration. This is the oldest computational thinking on the planet. The Jacquard loom encoded patterns as punched cards a half-century before Babbage built his engine. Warp threads up or down — binary. A card per row — sequential instruction. The cloth — output. When Ada Lovelace recognized the Analytical Engine's potential, she recognized it because she already understood the loom. Every carpet is an algorithm. Every algorithm can be a carpet.

## The Tile as Unit Cell

A tile is a small 2D array. The `pattern_tile_4x4` artifact uses a 4x4 grid — 16 cells, each holding a color index.

```gdscript
var tile_size: int = 4
var tile: Array[Array] = []

func _ready() -> void:
    tile.resize(tile_size)
    for y in tile_size:
        tile[y] = []
        tile[y].resize(tile_size)
        for x in tile_size:
            tile[y][x] = 0
```

Sixteen zeros. A blank tile. The learner paints cells — tapping to cycle through colors — and the tile fills in. Nothing here exceeds what Array_Basics covered. Same `[y][x]` indexing. Same resize-and-fill initialization. The difference is intent. In Array_Basics, the array stored data. Here, the array stores a design. The data is the design.

Crystallographers call this the unit cell — the smallest fragment that, through repetition, generates the entire crystal lattice. In textiles, it is the pattern repeat. In game development, it is the texture tile. In all cases, the logic is identical: define the small thing, then specify the rule that replicates it.

## Translation: The Simplest Repeat

Translation is repetition by shifting. Take the tile, move it right by its own width, stamp it again. Move it down by its own height, stamp again. Fill the plane.

```gdscript
var grid_width: int = 16
var grid_height: int = 16
var floor_grid: Array[Array] = []

func fill_by_translation(tile: Array[Array], tw: int, th: int) -> void:
    for gy in grid_height:
        for gx in grid_width:
            # Map floor position to tile position
            var tx: int = gx % tw
            var ty: int = gy % th
            floor_grid[gy][gx] = tile[ty][tx]
```

The modulo operator does all the work. `gx % tw` wraps the floor's x-coordinate back into the tile's range. Cell 0 maps to tile column 0. Cell 4 maps to tile column 0 again. Cell 7 maps to tile column 3. The tile repeats seamlessly — no seams, no gaps, no special-case logic at boundaries. Modulo is the tiling operator.

This is wallpaper group p1 — the simplest symmetry group. Translation only. No rotation, no reflection. The tile stamps as-is, forever. Every horizontally scrolling game background, every repeating web texture, every brick wall with aligned joints uses p1. It is the computational default, the thing that happens when you do nothing beyond repeat.

## Rotation: Spinning the Tile

Rotation takes the tile's contents and turns them. A 90-degree clockwise rotation maps cell `(x, y)` to `(size - 1 - y, x)`. The array dimensions stay the same — for square tiles — but every value moves.

```gdscript
func rotate_tile_90(source: Array[Array], size: int) -> Array[Array]:
    var rotated: Array[Array] = []
    rotated.resize(size)
    for y in size:
        rotated[y] = []
        rotated[y].resize(size)
        for x in size:
            rotated[y][x] = source[size - 1 - x][y]
    return rotated
```

Apply this once for 90 degrees, twice for 180, three times for 270. Four applications return the original — the rotation group of the square. A tile with a diagonal line becomes four diagonal lines meeting at the center when all four rotations stamp into a 2x2 arrangement of tiles:

```gdscript
func fill_with_rotation(tile: Array[Array], tw: int, th: int) -> void:
    var r90: Array[Array] = rotate_tile_90(tile, tw)
    var r180: Array[Array] = rotate_tile_90(r90, tw)
    var r270: Array[Array] = rotate_tile_90(r180, tw)
    var orientations: Array[Array] = [tile, r90, r180, r270]

    for gy in grid_height:
        for gx in grid_width:
            # Which tile in the 2x2 rotation block?
            var block_x: int = (gx / tw) % 2
            var block_y: int = (gy / th) % 2
            var orientation: int = block_y * 2 + block_x
            var tx: int = gx % tw
            var ty: int = gy % th
            floor_grid[gy][gx] = orientations[orientation][ty][tx]
```

Four tiles, four orientations, one repeating unit. The pattern that emerges has rotational symmetry that the original tile lacked. The symmetry is not in the data — it is in the operation. This is the core insight of the wallpaper groups: symmetry is a verb, not a noun. It is something you do to a tile, not something the tile contains.

## Reflection: The Mirror Operation

Reflection flips the tile across an axis. A horizontal mirror swaps left and right. A vertical mirror swaps top and bottom.

```gdscript
func mirror_horizontal(source: Array[Array], w: int, h: int) -> Array[Array]:
    var mirrored: Array[Array] = []
    mirrored.resize(h)
    for y in h:
        mirrored[y] = []
        mirrored[y].resize(w)
        for x in w:
            mirrored[y][x] = source[y][w - 1 - x]
    return mirrored

func mirror_vertical(source: Array[Array], w: int, h: int) -> Array[Array]:
    var mirrored: Array[Array] = []
    mirrored.resize(h)
    for y in h:
        mirrored[y] = []
        mirrored[y].resize(w)
        for x in w:
            mirrored[y][x] = source[h - 1 - y][x]
    return mirrored
```

The index arithmetic is simple — `w - 1 - x` reverses the column order, `h - 1 - y` reverses the row order. The `pattern_tile_mirror` artifact applies both mirrors to generate a 2x2 block from a single quadrant:

```gdscript
func fill_with_mirror(tile: Array[Array], tw: int, th: int) -> void:
    var h_mirror: Array[Array] = mirror_horizontal(tile, tw, th)
    var v_mirror: Array[Array] = mirror_vertical(tile, tw, th)
    var hv_mirror: Array[Array] = mirror_vertical(h_mirror, tw, th)
    var quadrants: Array[Array] = [tile, h_mirror, v_mirror, hv_mirror]

    for gy in grid_height:
        for gx in grid_width:
            var block_x: int = (gx / tw) % 2
            var block_y: int = (gy / th) % 2
            var quadrant: int = block_y * 2 + block_x
            var tx: int = gx % tw
            var ty: int = gy % th
            floor_grid[gy][gx] = quadrants[quadrant][ty][tx]
```

This is wallpaper group pmm — two perpendicular mirror axes. Paint a quarter of the design; the mirrors generate the rest. The `vr_tile_editor_mirror` artifact makes this tangible in real time. Paint a cell in the top-left quadrant. Three corresponding cells light up simultaneously — horizontal mirror, vertical mirror, both. The floor beneath updates instantly. The learner paints 16 cells and sees 64 respond. Symmetry as amplifier.

The same principle built the persian rug in CA_1 — four-fold symmetry from a single random quadrant. The difference: there, the automaton rule generated the content. Here, the learner generates it by hand. The symmetry operation is identical. The source of the pattern changes. The mathematics does not.

## Glide Reflection: Mirror Plus Shift

Glide reflection combines a mirror with a half-tile translation along the mirror axis. It is the least intuitive symmetry operation — neither pure reflection nor pure translation, but a hybrid that creates patterns neither alone can produce.

```gdscript
func fill_with_glide_reflection(tile: Array[Array], tw: int, th: int) -> void:
    var h_mirror: Array[Array] = mirror_horizontal(tile, tw, th)
    var half_shift: int = tw / 2

    for gy in grid_height:
        for gx in grid_width:
            var row_block: int = (gy / th) % 2
            var tx: int
            var ty: int = gy % th
            if row_block == 0:
                tx = gx % tw
                floor_grid[gy][gx] = tile[ty][tx]
            else:
                tx = (gx + half_shift) % tw
                floor_grid[gy][gx] = h_mirror[ty][tx]
```

Odd rows are mirrored and shifted half a tile width. The visual effect: footprints in sand — left, right, left, right — each one a reflection of the previous, each one offset. This is wallpaper group pg. The glide axis runs vertically; the pattern progresses along it with alternating chirality.

Glide reflections appear everywhere in woven textiles. The over-under-over-under of a basic weave is a glide reflection — each row mirrors the previous and shifts by one thread. The operation is built into the mechanics of the loom itself. The heddles raise alternating warp threads, creating the glide; the shuttle crosses, creating the mirror. The cloth does not represent a glide reflection. The cloth is a glide reflection.

## The Brick Pattern: Offset Rows

The `pattern_tile_brick` artifact introduces a tiling that breaks row alignment. Even-numbered rows stamp normally. Odd-numbered rows shift by half the tile width.

```gdscript
func fill_brick_pattern(tile: Array[Array], tw: int, th: int) -> void:
    var half_w: int = tw / 2

    for gy in grid_height:
        for gx in grid_width:
            var row_index: int = gy / th
            var offset: int = 0
            if row_index % 2 == 1:
                offset = half_w
            var tx: int = (gx + offset) % tw
            var ty: int = gy % th
            floor_grid[gy][gx] = tile[ty][tx]
```

One line of difference from pure translation — the `offset` variable. Yet the visual result is immediately distinct. Columns no longer align vertically. The eye follows diagonal lines instead of vertical ones. The pattern feels interlocked rather than stacked.

Brickwork uses this offset for structural reasons — aligned joints create a weak vertical fault line. The half-bond offset distributes load across rows. The pattern is load-bearing. But the same offset appears in textile twills, subway tile, and pixel art, where structural integrity is irrelevant. The visual rhythm of the offset is its own justification.

## The Herringbone: Alternating Orientation

Herringbone interleaves tiles rotated 90 degrees in an L-shaped arrangement. The `pattern_tile_herringbone` artifact arranges rectangular tiles — taller than wide — in alternating vertical and horizontal orientations.

```gdscript
func fill_herringbone(tile: Array[Array], tw: int, th: int) -> void:
    # Herringbone works with rectangular tiles: tw != th
    # Each "unit" is a 2-tile L-shape
    var unit_w: int = tw + th
    var unit_h: int = tw + th

    for gy in grid_height:
        for gx in grid_width:
            var ux: int = gx % unit_w
            var uy: int = gy % unit_h
            # Determine if this cell belongs to a vertical or horizontal tile
            if (ux < tw and uy < th) or (ux >= tw and uy >= th):
                # Vertical tile
                var tx: int = gx % tw
                var ty: int = gy % th
                floor_grid[gy][gx] = tile[ty][tx]
            else:
                # Horizontal tile (rotated 90 degrees)
                var tx: int = gy % tw
                var ty: int = gx % th
                floor_grid[gy][gx] = tile[ty][tx]
```

The x and y indices swap for horizontal tiles — that swap is the 90-degree rotation, expressed as an index remapping rather than a separate array. Herringbone belongs to wallpaper group p2 — 180-degree rotational symmetry with no mirrors. The two-tile L-shape, when rotated 180 degrees, produces the adjacent L-shape. The pattern self-generates from a single rotational operation.

Herringbone appears in Roman roads, parquet floors, Harris tweed, and basket weaves. The pattern predates written history. The reason is structural and visual: the interlocking L-shapes resist lateral movement, and the eye reads the zigzag as dynamic, directional, energetic — a pattern that moves.

## The 17 Wallpaper Groups

Translation, rotation, reflection, glide reflection — four operations. Combine them. Ask: in how many distinct ways can these operations tile a plane? The answer, proven by Evgraf Fedorov in 1891, is exactly 17. Not approximately, not "at least." Seventeen. A finite classification of all possible planar symmetries.

The groups range from p1 (translation only — the most asymmetric) to p6m (60-degree rotation with all possible mirror axes — the most symmetric). Between them: p2 with 180-degree rotation. pm with parallel mirrors. pg with glide reflections. cmm with centered double mirrors. p4m with the full symmetry of a square — the pattern underlying Islamic geometric art.

Every repeating pattern ever created — every Persian rug, every bathroom tile, every pixel art texture, every woven cloth — belongs to one of these 17 groups. The classification is exhaustive. There is no 18th wallpaper group. The proof is topological: it follows from the constraint that the plane must be filled without gaps or overlaps, using only isometries (distance-preserving transformations). Only certain combinations of rotation orders (2, 3, 4, 6 — never 5) and reflection axes close consistently. Five-fold symmetry does not tile the plane. Pentagons leave gaps. This is why Penrose tilings — which achieve five-fold symmetry — require aperiodic repetition and at least two tile shapes.

The `tiling_demo` artifact generates patterns from several of these groups. The gap — the `wallpaper_group_explorer` — would let the learner paint one tile and see all 17 groups generated from it. Seventeen panels, one source tile, seventeen different symmetry treatments. The same content arranged by every possible rule. That artifact would make the classification tangible: not a table to memorize but a visual space to explore.

## The Facade Grammar

The `facade_grammar_demo` extends tiling from two dimensions into architectural grammar. A facade is a vertical tiling — stories stack, bays repeat, windows follow rules. Classical architecture codifies these rules explicitly: base, shaft, capital on columns; cornice, frieze, architrave on entablatures. The grammar specifies which elements can appear where and how they repeat.

```gdscript
var facade_rules: Dictionary = {
    "ground": ["door", "window", "window", "door"],
    "middle": ["window", "window", "window", "window"],
    "top": ["window", "window", "window", "window"],
    "cornice": ["ornament", "ornament", "ornament", "ornament"]
}

func generate_facade(stories: int, bays: int) -> Array[Array]:
    var facade: Array[Array] = []
    facade.append(facade_rules["cornice"].slice(0, bays))
    for story in range(stories - 1, 0, -1):
        facade.append(facade_rules["middle"].slice(0, bays))
    facade.append(facade_rules["ground"].slice(0, bays))
    return facade
```

Each story is a row. Each bay is a column. The facade is a 2D array — the same data structure as the tile, the same data structure as the cellular automaton grid. The grammar is the rule. The facade is the output. The parallel to textiles is direct: warp (vertical structure) and weft (horizontal repetition) produce a fabric. Columns (vertical structure) and bays (horizontal repetition) produce a building. The substrate differs. The operation — array-based repetition governed by rules — is identical.

## Pattern as Order, Variation as Entropy

A tile filled with a single color has zero informational entropy — every cell is predictable. Stamp it across a floor and the floor has zero entropy too. Repetition preserves the entropy of the source. A tile filled with random colors has maximum entropy — no cell predicts any other. Stamp it and the floor has maximum local entropy but zero surprise at the macro scale, because the randomness itself repeats identically.

The interesting patterns live between these extremes. A tile with some structure — a diagonal line, an asymmetric motif, a gradient — has moderate entropy. Apply a symmetry operation and the entropy shifts. Mirror symmetry halves the effective information: knowing the left half determines the right. Rotational symmetry divides it further. The more symmetric the wallpaper group, the less independent information per unit area. p6m — maximum symmetry — compresses the most. p1 — no added symmetry — compresses the least.

This is the connection to the larger curriculum. Pattern repetition is F-order — the formal structure that makes a system predictable. Variation within the tile is E-entropy — the irreducible novelty, the part that cannot be derived from the rule. The wallpaper groups are a taxonomy of how much F-structure a planar pattern can carry. Seventeen levels of order, from minimal to maximal. The learner who paints a tile and watches it replicate is experiencing this tradeoff directly: how much do I design, and how much does the symmetry generate?

## From Loom to GPU

The Jacquard loom, patented in 1804, used punched cards to control which warp threads were raised for each pass of the shuttle. Each card encoded one row of the pattern. The stack of cards was the program. The loom was the processor. The cloth was the output.

The parallel to a 2D array is exact. Each card is a row. Each hole position is a column. Hole or no-hole is 1 or 0. The Jacquard loom operated on a binary 2D array, stored externally on cards, processed row by row, producing a physical output. Charles Babbage visited the loom. He adopted punched cards for his Analytical Engine. Ada Lovelace understood the Engine by analogy to the loom — and extended it, recognizing that the Engine could manipulate symbols, not just numbers. The loom wove patterns in silk. The Engine, she wrote, could weave algebraic patterns.

The GPU continues the lineage. A fragment shader evaluates a function at every pixel — a 2D grid of cells, each computing its color from its coordinates. The symmetry operations coded in this map — modulo for translation, index reversal for reflection, index swap for rotation — are the same operations a shader uses to generate tiling textures. The substrate moved from thread to vacuum tube to transistor. The operation — replicate a small pattern across a plane using symmetry — has not changed in two centuries.

## Possible Artifacts

**wallpaper_group_explorer** — The learner paints a single tile. Seventeen panels display that tile replicated under each of the 17 wallpaper groups. Changing one cell updates all seventeen views simultaneously. The explorer makes the classification visceral — not a table of group names but a visual array of pattern possibilities, all derived from the same source. Includes labels (p1, pm, p4m, etc.) and highlights the symmetry axes and rotation centers as overlay lines.

**symmetry_operation_stepper** — A slow-motion tool that shows each symmetry operation applied to the tile one step at a time. The learner sees the original tile, then the mirror copy appearing, then the translation placing it, then the next copy. Builds intuition for how compound operations (glide reflection = mirror + translate) compose from primitives. Pause, rewind, step forward. The floor assembles tile by tile.

**loom_simulator** — A virtual loom where punched cards (binary rows) control the pattern. The learner edits the card stack — toggling holes — and watches the cloth emerge row by row. Connects the abstract 2D array to the physical mechanism. Each card maps to one array row. Each hole maps to one cell. The cloth is the rendered grid. The mapping is literal, not metaphorical.

**tile_entropy_meter** — Displays the informational entropy of the tile alongside the entropy of the resulting floor pattern for each wallpaper group. The learner paints the tile and watches the entropy values change. High-symmetry groups compress more — the floor entropy drops relative to the tile entropy. The meter makes the order-entropy tradeoff quantitative rather than intuitive.
