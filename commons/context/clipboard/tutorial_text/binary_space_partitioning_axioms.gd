extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Binary Space Partitioning (BSP)[/b][/font_size][/center]
[center][i]Recursive Division, Dungeon Generation[/i][/center]

**BSP recursively divides space with lines/planes into tree structure.**

**Classic use:** Doom (1993) rendering, procedural dungeon generation.

[hr]

[b]Algorithm[/b]

1. Start with rectangle (or space)
2. Choose split (horizontal or vertical)
3. Divide into two sub-rectangles
4. Recursively split each sub-rectangle
5. Stop at minimum size

[color=yellow][b]Code:[/b][/color]
[code]
class BSPNode:
    var rect: Rect2
    var left: BSPNode = null
    var right: BSPNode = null

func split_space(node: BSPNode, min_size: float):
    if node.rect.size.x < min_size and node.rect.size.y < min_size:
        return  # Too small, stop

    # Choose split direction
    var split_horizontal = randf() < 0.5

    if split_horizontal:
        var split_y = node.rect.position.y + randf_range(min_size, node.rect.size.y - min_size)
        node.left = BSPNode.new()
        node.left.rect = Rect2(node.rect.position, Vector2(node.rect.size.x, split_y - node.rect.position.y))
        node.right = BSPNode.new()
        node.right.rect = Rect2(Vector2(node.rect.position.x, split_y), Vector2(node.rect.size.x, node.rect.size.y - (split_y - node.rect.position.y)))
    else:
        var split_x = node.rect.position.x + randf_range(min_size, node.rect.size.x - min_size)
        node.left = BSPNode.new()
        node.left.rect = Rect2(node.rect.position, Vector2(split_x - node.rect.position.x, node.rect.size.y))
        node.right = BSPNode.new()
        node.right.rect = Rect2(Vector2(split_x, node.rect.position.y), Vector2(node.rect.size.x - (split_x - node.rect.position.x), node.rect.size.y))

    # Recurse
    split_space(node.left, min_size)
    split_space(node.right, min_size)
[/code]

**Result:** Tree of nested rectangles. **Each leaf = room candidate.**

[hr]

[b]Dungeon Generation[/b]

1. BSP split to create rooms
2. Place room in each leaf node
3. Connect adjacent rooms with corridors

**Guarantees:** All rooms connected, no overlap.

[hr]

[b]Queer BSP[/b]

**BSP is binary division** - always splits into exactly two.

**This is binary thinking:**
- **Male/Female** (gender binary)
- **Gay/Straight** (sexuality binary)
- **Good/Bad** (moral binary)

**Queer resistance:** Non-binary alternatives, spectrum not split, multiplicity not dichotomy.

**BSP forces binary cuts.** Real space is not binary-divisible.

[hr]

[color=cyan][b]Summary:[/b][/color]
BSP: recursive binary division of space into tree. Dungeons: split → rooms in leaves → connect corridors. Queer BSP: binary division enforces dichotomy (male/female, gay/straight). Queer resistance: non-binary multiplicities, spectra not splits.

'''
