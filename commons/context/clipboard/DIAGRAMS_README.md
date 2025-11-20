# Procedural Diagrams in Tutorials

## Overview

The tutorial system now supports **procedurally generated diagrams** that are drawn into image buffers and displayed inline in BBCode text.

## Usage in Tutorials

### Basic Syntax

```gdscript
var text = '''
[b]Algorithm Visualization:[/b]

[center][img=400x300]diagram://bloom_filter_bits[/img][/center]

Regular text continues here...
'''
```

### Available Diagrams

| Diagram Name | Description | Recommended Size |
|--------------|-------------|------------------|
| `bloom_filter_bits` | Bit array showing hash function results | 400x200 |
| `skip_list_layers` | Multi-level linked list structure | 400x250 |
| `hilbert_curve` | Space-filling curve visualization | 400x400 |
| `dijkstra_graph` | Weighted graph for pathfinding | 450x300 |
| `binary_tree` | Recursive tree structure | 400x350 |

## Creating New Diagrams

Add a new generator function to `DiagramGenerator.gd`:

```gdscript
static func generate_my_diagram(width: int, height: int) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.05, 0.05, 0.07, 1.0))  # Dark background

    # Draw your diagram using primitives:
    draw_circle(img, width/2, height/2, 50, Color.RED)
    draw_line_smooth(img, 0, 0, width, height, Color.BLUE)
    draw_box(img, 100, 100, 30, "Text", Color.GREEN)

    return img
```

Then register it in the `generate()` function:

```gdscript
match diagram_name:
    "my_diagram":
        img = generate_my_diagram(width, height)
```

## Drawing Primitives

Available drawing functions in `DiagramGenerator`:

### Shapes
- `draw_circle(img, x, y, radius, color)` - Filled circle
- `draw_box(img, x, y, size, text, color)` - Rectangle with outline
- `draw_line_smooth(img, x1, y1, x2, y2, color)` - Anti-aliased line
- `draw_line_horizontal(img, x1, x2, y, color)` - Horizontal line
- `draw_arrow_down(img, x, y, color)` - Downward arrow

### Trees & Graphs
- `draw_tree_node(img, x, y, spread, depth, color)` - Recursive binary tree

### Text (Placeholder)
- `draw_text(img, x, y, text, color, centered)` - Text rendering (requires font)

## Performance Notes

- Diagrams are **cached** after first generation
- Cache key: `diagram_name + width + height`
- Generating a 400x400 diagram typically takes <1ms
- Use reasonable sizes (max ~1000x1000) to avoid memory issues

## Color Palette

Recommended colors for consistent visual style:

```gdscript
# Background
Color(0.05, 0.05, 0.07, 1.0)  # Dark blue-gray

# Accent colors
Color(0.8, 0.3, 0.3)  # Red (important/set elements)
Color(0.3, 0.6, 0.8)  # Blue (primary elements)
Color(0.3, 0.7, 0.5)  # Green (success/trees)
Color(0.9, 0.7, 0.3)  # Yellow/Gold (highlights)

# Neutral
Color(0.5, 0.5, 0.6)  # Gray (secondary elements)
Color.WHITE           # Labels and outlines
```

## Example: Complete Tutorial with Diagram

```gdscript
extends Node

var text = '''[center][font_size=28][b]Skip Lists[/b][/font_size][/center]

**Skip lists use layered express lanes for fast search.**

[center][img=400x250]diagram://skip_list_layers[/img][/center]

**How it works:**
- Level 0: All elements
- Level 1: Every ~2nd element (probabilistic)
- Level 2: Every ~4th element
- Level 3: Every ~8th element

Higher levels skip over many elements → O(log n) search time.
'''
```

## Advanced: Animated Diagrams

For animated/interactive diagrams, use the **infoboards_3d** approach instead:

1. Create a Control node with `_draw()` method
2. Update `animation_time` in `_process()`
3. Call `queue_redraw()` to refresh
4. See `commons/infoboards_3d/boards/Point/PointVisualizationControl.gd` for examples

## Integration Checklist

To enable procedural diagrams in codeDisplay:

- [ ] Autoload `DiagramGenerator.gd` as singleton
- [ ] Modify `codeDisplay.gd` to pre-process `diagram://` URLs
- [ ] Call `DiagramProvider.setup_rich_text_label(rtl)` on RichTextLabel
- [ ] Test with `diagram://bloom_filter_bits` in a tutorial

## Future Enhancements

- [ ] Add bitmap font rendering for text in diagrams
- [ ] Create diagram editor GUI for non-coders
- [ ] Export diagrams as PNG files for documentation
- [ ] Add more algorithm visualizations (sorting, hashing, etc.)
- [ ] Support parameters: `diagram://graph?nodes=5&edges=7`
