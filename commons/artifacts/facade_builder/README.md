# Facade Builder

Interactive architectural facade composer that builds 3D facades from preset styles or v2 plan JSON files. Supports classical, gothic, palazzo, arcade, and minimal architectural styles with configurable bays, stories, symmetry, and colors.

## How It Works

The builder first checks for a v2 facade plan JSON (via `plan_path` or synced from the web editor). If found, it delegates to FacadeComposer for part-based construction. Otherwise, it falls back to built-in preset definitions that divide the facade into horizontal zones (base, main, entablature, etc.), each with specific architectural elements. Zone geometry is built using SurfaceTool, producing columns, rustication, windows, arches, cornices, pediments, balustrades, tracery, rose windows, and glass panels.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| preset | String | "classical" |
| plan_path | String | "" |
| bay_count | int | 5 |
| story_count | int | 3 |
| facade_width | float | 15.0 |
| facade_height | float | 10.0 |
| symmetry | int (enum) | 1 (Bilateral) |
| primary_color | Color | Color(0.82, 0.78, 0.70) |
| secondary_color | Color | Color(0.65, 0.60, 0.52) |

## Features

- Five architectural presets: classical, gothic, palazzo, arcade, minimal
- Part-based FacadeComposer integration for v2 plan JSON from the web editor
- Procedural SurfaceTool geometry for columns, arches, windows, rustication, and more
- Bilateral symmetry via spatial composition modifiers
- Configurable bay and story counts, dimensions, and colors
- Pointed arches and rose windows for gothic style
- Glass panels and flat caps for minimal/modern style
- Automatic lighting

## Files

- `facade_builder.gd` -- Facade composition and geometry builder with preset and plan support
- `facade_builder.tscn` -- Scene file
