# Random Number Generation

Visualizations inspired by the RAND Corporation's "A Million Random Digits with 100,000 Normal Deviates" (1955) — physical book pages filled with random numbers, reimagined as interactive 3D artifacts.

## Artifacts

### Random Number Book Page

A grid of 5-digit random numbers that cascade top-to-bottom like a stock ticker. In VR, touch any number (poke interaction) to freeze it in place — frozen numbers glow amber while the rest keep flowing. Demonstrates how random sequences look when laid out in tabular form and invites the viewer to find (illusory) patterns.

### Random Color Book Page

The same grid concept but with color blocks — each cell maps a random number to a color, producing a continuously shifting mosaic. Highlights how random distributions manifest visually when mapped to a perceptual dimension.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `grid_width` | 10 | Columns of numbers/colors |
| `grid_height` | 28 | Visible rows |
| `number_spacing_y` | 0.15 | Vertical spacing |
| `cascade_speed` | 1.0 | Rows per second |
| `change_interval` | 10.0 | Color page refresh interval |

## Files

- `scripts/random_number_book_page_1995.gd` — Cascading number grid with VR touch-to-freeze.
- `scripts/random_color_book_page_1955.gd` — Color-mapped random grid.
- `scenes/random_number_book_page_1955.tscn` — Number page scene.
- `scenes/random_number_book_page_collection.tscn` — Multi-page number layout.
- `scenes/random_color_book_page_1955.tscn` — Color page scene.
- `scenes/random_color_book_page_collection.tscn` — Multi-page color layout.
