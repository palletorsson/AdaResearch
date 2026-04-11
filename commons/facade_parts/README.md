# Facade Parts — Procedural Italian Architecture

Part-based facade composition system for generating Italian-style building facades from modular architectural elements.

## Architecture

| File | Role |
|------|------|
| `facade_part_library.gd` | Central factory — `FacadePartLibrary.create(part_name, w, h, params)` |
| `facade_composer.gd` | Assembles parts onto a grid layout from a plan JSON |
| `facade_composer_demo.gd/.tscn` | Demo scene showing facade generation |
| `facade_materials.gd` | Shared material definitions (stone, stucco, terracotta) |
| `procedural_columns.gd` | Parametric classical column generator |
| `part_catalog.json` | Machine-readable catalog of all available parts |

## Part Categories (`parts/`)

9 category files with 42 total parts:

| Category | Parts |
|----------|-------|
| `column_parts.gd` | Tuscan, Doric, Ionic, Corinthian, Solomonic, Composite, Pilaster |
| `opening_parts.gd` | Rect/arched/Venetian windows, rose window, porthole, doors, portal |
| `arch_parts.gd` | Round, pointed, arcade, segmental arches |
| `balcony_parts.gd` | Juliet, projecting balcony, loggia |
| `cornice_parts.gd` | Dentil, cyma recta, string course, fascia, modillion |
| `shutter_parts.gd` | Louvered, paneled shutters |
| `railing_parts.gd` | Simple, balustrade, iron railings |
| `surface_parts.gd` | Plain wall, rusticated block, stucco, ashlar |
| `ornament_parts.gd` | Pediments, medallion, cartouche |

## Usage

```gdscript
var window = FacadePartLibrary.create("arched_window", 2.0, 3.0, {"keystone": true})
```

Web editor: `localhost:3003/facade-builder`
