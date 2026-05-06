# Ada UI Design System

Project-wide interface system for AdaResearch. One palette, one theme, one set of materials — used by both 2D (Control) and 3D (VR) interfaces.

## Architecture

```
commons/ui/
├── ada_palette.gd          # Color constants, sizing, helper factories
├── ada_ui_materials.gd     # Preloaded material refs + migration map
├── ada_theme.tres          # Godot Theme for all 2D Control nodes
├── README.md               # This file
└── materials/              # Shared StandardMaterial3D resources
    ├── panel_white.tres    # Near-white backgrounds
    ├── panel_light.tres    # Light gray panels
    ├── panel_medium.tres   # Mid gray borders/separators
    ├── panel_dark.tres     # Dark panels, bezels
    ├── accent_orange.tres  # Primary accent (TE orange)
    ├── accent_blue.tres    # Info, links
    ├── accent_cyan.tres    # Displays, data
    ├── accent_green.tres   # Active, positive
    ├── accent_yellow.tres  # Warning, highlight
    ├── accent_red.tres     # Stop, danger
    ├── metal_dark.tres     # Knob bases, structure
    ├── metal_chrome.tres   # Shiny metal
    ├── metal_warm.tres     # Brushed metal
    ├── screen_bg.tres      # CRT/LCD display background
    ├── screen_bezel.tres   # Display frame
    ├── handle_glow.tres    # Grabbable elements (bright emission)
    ├── track_groove.tres   # Slider/fader tracks
    └── track_fill.tres     # Active fill on tracks
```

## Usage

### 2D Interfaces
Apply the theme to any root Control:
```gdscript
func _ready():
    theme = preload("res://commons/ui/ada_theme.tres")
```
Or set it on the root node and it cascades to all children.

### 3D VR Components
Reference shared materials instead of inline sub_resources:
```gdscript
const UI = preload("res://commons/ui/ada_ui_materials.gd")

# In scene setup:
backing_mesh.material_override = UI.PANEL_WHITE
handle_mesh.material_override = UI.HANDLE_GLOW
track_mesh.material_override = UI.TRACK_GROOVE
```

### Color Constants (from code)
```gdscript
# Option A: preload
const P = preload("res://commons/ui/ada_palette.gd")
var col = P.ACCENT_ORANGE

# Option B: autoload (register as "AdaPalette")
var col = AdaPalette.ACCENT_ORANGE
var mat = AdaPalette.make_material(AdaPalette.ACCENT_BLUE, 0.3, 0.5, 0.6)
```

### Rack Module Sizing
All VR controls align to a grid based on `RACK_UNIT = 0.08m`:
- **1×1** (8cm²): Button, small knob
- **1×2** (8×16cm): Vertical slider, meter
- **2×1** (16×8cm): Horizontal slider
- **2×2** (16cm²): Joystick, XY pad
- **3×2** (24×16cm): Display, monitor
- **4×2** (32×16cm): Wide display

Gap between modules: 6mm.

## Visual Direction

- **Light backgrounds** — white/light gray panels; components pop against them
- **TE-inspired** — Teenage Engineering aesthetic: cream/white + bold accent colors
- **High contrast in VR** — accent materials have emission so they read at arm's length
- **Dark screens** — display viewports use near-black CRT backgrounds with bright traces

## Migration from Old Materials

Two old material sets exist:
1. `commons/interactables/materials/` — dark rack palette (cyan accent)
2. `commons/audio/interfaces/materials/` — TE palette (cream + orange)

Both are superseded by `commons/ui/materials/`. The migration map in `ada_ui_materials.gd` documents old→new path mappings. Old files can be removed once all scenes are updated.
