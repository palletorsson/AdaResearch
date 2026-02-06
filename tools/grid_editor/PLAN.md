# Grid Editor - Development Plan

A tool scene within AdaResearch for visually editing 2D layouts that get placed in 3D.

---

## Overview

**Purpose:** Visual editor for placing elements on a 2D grid, outputting JSON configs for 3D systems (GlassRack, BigPipes, LabTable, WallDecor, etc.)

**Tech:** Tool scene within AdaResearch (res://tools/grid_editor/)

**Usage:** Run from editor or via F6 on main.tscn

---

## Architecture

```
tools/grid_editor/
├── PLAN.md                      # This file
├── scenes/
│   └── main.tscn                # Main editor scene
├── scripts/
│   ├── editor_main.gd           # Main controller
│   ├── grid_canvas.gd           # 2D grid logic (zoom/pan/place)
│   └── subset_loader.gd         # Load subset definitions
└── subsets/                     # Subset definitions
    ├── glass_rack.json
    └── big_pipes.json
```

---

## Phase 1: Core Framework (Week 1)

### 1.1 Project Setup
- [ ] Create new Godot project `grid_editor`
- [ ] Set up folder structure
- [ ] Configure project settings (window size, theme)
- [ ] Create main scene with basic layout

### 1.2 Subset System
- [ ] Define subset JSON schema
- [ ] Create `SubsetLoader` singleton
- [ ] Load subset definitions at startup
- [ ] Subset picker dialog

**Subset Schema:**
```json
{
  "id": "glass_rack",
  "name": "Glass Rack",
  "version": "1.0",
  "orientation": {
    "plane": "XZ",
    "up_axis": "Y",
    "forward": "+Z",
    "grid_size": 0.1
  },
  "elements": [
    {
      "id": "flask",
      "name": "Flask",
      "category": "vessels",
      "size": [1, 2],
      "icon": "flask.png",
      "ports": {
        "in": {"cell": [0, 0], "side": "bottom"},
        "out": {"cell": [0, 1], "side": "top"}
      },
      "params": {
        "radius": {"type": "float", "default": 0.05, "min": 0.02, "max": 0.1}
      },
      "preview_scene": "res://elements/flask.tscn"
    }
  ],
  "categories": [
    {"id": "vessels", "name": "Vessels", "color": "#4CAF50"},
    {"id": "tubes", "name": "Tubes", "color": "#2196F3"},
    {"id": "junctions", "name": "Junctions", "color": "#FF9800"}
  ]
}
```

### 1.3 Grid Canvas
- [ ] Create `GridCanvas` Control node
- [ ] Draw grid lines
- [ ] Handle zoom (scroll wheel)
- [ ] Handle pan (middle mouse drag)
- [ ] Cell highlighting on hover
- [ ] Coordinate display

---

## Phase 2: Element System (Week 2)

### 2.1 Element Palette
- [ ] Create palette panel
- [ ] Category tabs/accordion
- [ ] Element buttons with icons
- [ ] Search/filter
- [ ] Drag from palette to start placement

### 2.2 Placement System
- [ ] Drag element onto canvas
- [ ] Ghost preview while dragging
- [ ] Snap to grid
- [ ] Collision detection (no overlap)
- [ ] Rotation (R key or right-click menu)
- [ ] Delete (Delete key or right-click)
- [ ] Multi-select (Shift+click, drag box)

### 2.3 Element Rendering
- [ ] Draw placed elements on canvas
- [ ] Show element icon/shape
- [ ] Show rotation indicator
- [ ] Show ports as colored dots
- [ ] Highlight selected elements

---

## Phase 3: Connections (Week 3)

### 3.1 Port System
- [ ] Display ports on elements
- [ ] Port compatibility rules
- [ ] Visual port indicators (in=red, out=green)

### 3.2 Connection Drawing
- [ ] Auto-connect adjacent compatible ports
- [ ] Draw connection lines/curves
- [ ] Manual connection mode (drag port to port)
- [ ] Connection validation (type matching)

### 3.3 Path Generation
- [ ] Generate path string from layout
- [ ] Handle branching (push/pop)
- [ ] Validate complete paths (no orphans)

---

## Phase 4: Properties & Preview (Week 4)

### 4.1 Properties Panel
- [ ] Show selected element properties
- [ ] Edit element parameters
- [ ] Rotation control
- [ ] Position (cell) display
- [ ] Delete button

### 4.2 3D Preview
- [ ] SubViewport with 3D scene
- [ ] Generate 3D from layout
- [ ] Orbit camera controls
- [ ] Toggle preview on/off
- [ ] Live update as layout changes

### 4.3 Layout Properties
- [ ] Layout name
- [ ] Grid dimensions
- [ ] Global scale
- [ ] Metadata (description, author)

---

## Phase 5: File Operations (Week 5)

### 5.1 Save/Load
- [ ] Layout file format (JSON)
- [ ] Save dialog
- [ ] Load dialog
- [ ] Recent files list
- [ ] Auto-save

**Layout File Schema:**
```json
{
  "version": "1.0",
  "subset": "glass_rack",
  "name": "Y-Branch Distillation",
  "description": "Two condensers feeding beakers",
  "grid_size": [8, 10],
  "placements": [
    {
      "id": "flask_1",
      "element": "flask",
      "position": [4, 0],
      "rotation": 0,
      "params": {"radius": 0.05}
    },
    {
      "id": "ypipe_1",
      "element": "ypipe",
      "position": [4, 2],
      "rotation": 0
    }
  ],
  "connections": [
    {"from": "flask_1.out", "to": "ypipe_1.in"}
  ],
  "metadata": {
    "created": "2026-02-06",
    "modified": "2026-02-06"
  }
}
```

### 5.2 Export
- [ ] Export to AdaResearch config format
- [ ] Export path string
- [ ] Export schematic (ASCII art)
- [ ] Copy to clipboard
- [ ] Export destination picker

### 5.3 Import
- [ ] Import existing configs
- [ ] Parse path strings to layout
- [ ] Import from AdaResearch project

---

## Phase 6: Polish (Week 6)

### 6.1 UX Improvements
- [ ] Undo/Redo system
- [ ] Keyboard shortcuts
- [ ] Context menus
- [ ] Tooltips
- [ ] Status bar
- [ ] Welcome screen

### 6.2 Visual Polish
- [ ] Dark/light theme
- [ ] Custom icons
- [ ] Smooth animations
- [ ] Grid appearance options

### 6.3 Documentation
- [ ] In-app help
- [ ] Keyboard shortcut reference
- [ ] Subset creation guide
- [ ] README

---

## UI Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  File   Edit   View   Help                          [_][□][X]   │
├─────────────────────────────────────────────────────────────────┤
│ ┌──────────┐ ┌────────────────────────────┐ ┌─────────────────┐ │
│ │ PALETTE  │ │                            │ │   PROPERTIES    │ │
│ │          │ │                            │ │                 │ │
│ │ Vessels  │ │                            │ │ Element: flask  │ │
│ │ ┌──┬──┐  │ │      2D GRID CANVAS        │ │ Position: 4,0   │ │
│ │ │⚗️│🧪│  │ │                            │ │ Rotation: 0°    │ │
│ │ └──┴──┘  │ │    ┌───┬───┬───┬───┐       │ │                 │ │
│ │          │ │    │   │ ⚗️│   │   │       │ │ Parameters:     │ │
│ │ Tubes    │ │    ├───┼───┼───┼───┤       │ │ radius: 0.05    │ │
│ │ ┌──┬──┐  │ │    │   │ │ │   │   │       │ │                 │ │
│ │ │| │╱ │  │ │    ├───┼───┼───┼───┤       │ ├─────────────────┤ │
│ │ └──┴──┘  │ │    │ ◎ │ Y │ ◎ │   │       │ │   3D PREVIEW    │ │
│ │          │ │    ├───┼───┼───┼───┤       │ │                 │ │
│ │ Junctions│ │    │ 🧪│   │ 🧪│   │       │ │   ┌─────────┐   │ │
│ │ ┌──┬──┐  │ │    └───┴───┴───┴───┘       │ │   │  3D     │   │ │
│ │ │Y │+│  │ │                            │ │   │  View   │   │ │
│ │ └──┴──┘  │ │                            │ │   └─────────┘   │ │
│ │          │ │                            │ │                 │ │
│ └──────────┘ └────────────────────────────┘ └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ Ready | Subset: Glass Rack | Grid: 8x10 | Zoom: 100%            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Classes

### GridCanvas
```gdscript
class_name GridCanvas extends Control

signal cell_clicked(cell: Vector2i)
signal element_placed(element_id: String, cell: Vector2i)
signal selection_changed(elements: Array)

var grid_size: Vector2i = Vector2i(16, 16)
var cell_size: float = 32.0
var zoom: float = 1.0
var pan_offset: Vector2 = Vector2.ZERO
var placements: Array[PlacementResource] = []
var selected: Array[PlacementResource] = []

func place_element(element: ElementResource, cell: Vector2i, rotation: int) -> PlacementResource
func remove_element(placement: PlacementResource) -> void
func get_element_at(cell: Vector2i) -> PlacementResource
func cell_to_world(cell: Vector2i) -> Vector2
func world_to_cell(pos: Vector2) -> Vector2i
```

### SubsetLoader
```gdscript
class_name SubsetLoader extends Node

var subsets: Dictionary = {}  # id -> SubsetResource
var current_subset: SubsetResource

func load_all_subsets() -> void
func get_subset(id: String) -> SubsetResource
func get_element(subset_id: String, element_id: String) -> ElementResource
```

### ExportManager
```gdscript
class_name ExportManager extends RefCounted

func export_to_json(layout: LayoutResource) -> String
func export_to_path_string(layout: LayoutResource) -> String
func export_to_schematic(layout: LayoutResource) -> String
func export_to_adaresearch_config(layout: LayoutResource, path: String) -> void
```

---

## Milestones

| Week | Milestone | Deliverable |
|------|-----------|-------------|
| 1 | Core Framework | Grid canvas, subset loading, basic UI |
| 2 | Placement | Drag & drop elements, rotation, deletion |
| 3 | Connections | Port system, auto-connect, path generation |
| 4 | Preview | Properties panel, 3D preview |
| 5 | Files | Save/load, export to AdaResearch |
| 6 | Polish | Undo/redo, shortcuts, themes |

---

## Integration with AdaResearch

### Export Location
Editor exports to:
```
AdaResearch/commons/glass_rack/configs/
AdaResearch/algorithms/wavefunctions/big_pipe_system/configs/
```

### Config Format
Matches existing formats so systems can read directly:
```json
{
  "name": "My Layout",
  "schematic": ["..."],
  "path": "flask,f,ypipe,...",
  "layout": {
    "segment_length": 0.2,
    "tube_radius": 0.015
  }
}
```

### Future: Live Link
Could add WebSocket connection for live preview in running AdaResearch instance.

---

## Getting Started

```bash
# Create project
mkdir -p tools/grid_editor
cd tools/grid_editor

# Initialize Godot project
# Open Godot -> New Project -> grid_editor

# First files to create:
# 1. main.tscn - basic layout
# 2. scripts/subset_loader.gd - load definitions
# 3. subsets/glass_rack.json - first subset
# 4. scenes/canvas.tscn - grid canvas
```

---

## Open Questions

1. **Standalone or embedded?** Start standalone, could embed in AdaResearch later
2. **Subset hot-reload?** Useful for development
3. **Version control?** Git-friendly JSON format
4. **Collaboration?** Not in v1, but keep format extensible
