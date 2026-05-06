# Color Sheets

Scrollable palette visualization UI — browse and compare color collections.

## QFEP Connection

Palettes are **curated color relationships**. Each sheet presents colors in context (F, grouping); scrolling reveals variety (E, exploration). A good palette has internal logic — colors that work together. λ as color harmony.

## Features

- Scrollable UI container
- Multiple palette sheets
- Side-by-side comparison
- Loads from `color_palettes.tres` resource

## Files

| File | Purpose |
|------|---------|
| `colorsheets.gd` | UI generator |
| `color_palettes.tres` | Palette definitions |
| `*.tscn` | Scene |

## Usage

```gdscript
var sheets = preload("res://algorithms/color/colorsheets/colorsheets.tscn").instantiate()
add_child(sheets)
```

## See Also

- `color_mixing/` — Color theory demos
- `shaders/queer_materials/` — Material palettes
