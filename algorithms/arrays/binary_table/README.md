# Binary Table Display

A 3D grid that renders array data as color-coded values (1s and 0s), making the internal structure of arrays and matrices directly visible in VR space.

## How It Works

The artifact creates a panel of Label3D nodes arranged in a rows-by-columns grid, each displaying a value from a 2D array. Values are color-coded for quick scanning: green for 1, red for 0, yellow for values above 1, and blue for negatives. Optional row and column index labels along the edges reinforce how array indexing maps positions to data. Users can update individual cells or swap the entire dataset at runtime through `set_cell()` and `set_data()`.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `rows` | int | 4 |
| `cols` | int | 4 |
| `cell_size` | float | 0.08 |
| `font_size` | int | 24 |
| `show_indices` | bool | true |
| `title` | String | "" |

## Features

- Color-coded cell values for immediate visual distinction
- Optional row and column index labels to teach array indexing
- Dynamic rebuild when data changes via `set_data()` or `set_cell()`
- Configurable via `apply_grid_config()` for grid system integration

## Files

- `binary_table_display.gd` -- Main script
- `binary_table_display.tscn` -- Scene file
