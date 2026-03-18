# Panel Bridge Sample Data

Example JSON files for the Panel Bridge system. Each page type uses a layout JSON (defining panel structure and widgets) paired with a data JSON (containing domain content). These serve as defaults and test fixtures.

## How It Works

The `PanelBridgeLoader` reads a layout file to know which panels and widgets to create, then reads a data file to populate them with content. Layout files define panel dimensions, roles (left/center/right), and element types. Data files contain the actual matrices, palettes, or placement grids.

## Files

### Loom Simulator
- `loom_panel_layout.json` -- Standard loom layout with threading, tie-up, treadling, and drawdown panels.
- `loom_draft_data.json` -- Basic loom draft data (binary matrices for threading and treadling).
- `loom_overshot_layout.json` -- Overshot weaving layout variant.
- `loom_overshot_data.json` -- Overshot weaving draft data.

### Pattern Maker
- `pattern_maker_layout.json` -- Pattern maker panel layout with domain editor and preview.
- `pattern_maker_data.json` -- Wallpaper group pattern data with domain cells and palette.
- `pattern_maker_hex_layout.json` -- Hexagonal pattern maker layout variant.
- `pattern_maker_hex_data.json` -- Hexagonal pattern data.

### Grid Editor
- `grid_editor_layout.json` -- Glass rack grid editor panel layout.
- `grid_editor_data.json` -- Placement data with element positions on the grid.
