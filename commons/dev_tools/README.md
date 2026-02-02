# AdaResearch Dev Tools

Developer utilities for content validation and debugging.

## Content Validator

Drill-down navigation with descriptions and tabbed text content.

### Quick Start

```bash
godot --path . res://commons/dev_tools/ContentValidatorDesktop.tscn
```

### Navigation

```
🗺️ World Map Overview
├─ Grouped by QFEP phase
├─ Each sequence shows: name, status, description/truth, difficulty
└─ Click card → Sequence Detail

📋 Sequence Detail
├─ Full description + QFEP connection
├─ Maps grid with blurb preview
└─ Click map → Map Detail

🗂️ Map Detail
├─ Left: 2D grid layout + artifacts list
└─ Right: Tabbed content
    ├─ Overview (path, size, status)
    ├─ Technical (code examples)
    ├─ Summary (spatial layout, elements)
    └─ Critical (philosophical analysis)
```

### World Map Page

Shows all sequences grouped by QFEP phase with:
- **Title** + status icon (✓ ⚠️ ❌)
- **Description/Truth** from sequence JSON
- **Difficulty + time** estimate
- **Map count** (existing/total)

### Sequence Page

Shows sequence details:
- QFEP connection and formula
- Learning objectives
- Map cards with blurb preview
- Text file count per map

### Map Page

Split view:
- **Left panel**: 2D grid visualization + artifact list
- **Right panel**: Tabbed text content

**Grid legend:**
- Gray = floor, Dark = wall
- Green S = spawn, Purple T = teleporter
- Blue/Orange/Red squares = artifacts (valid/warning/error)

**Text tabs:**
| Tab | Source | Content |
|-----|--------|---------|
| Overview | map_data.json | Path, size, difficulty, blurb |
| Technical | technical.md | Code examples, implementation |
| Summary | summary.md | Spatial layout, key elements |
| Critical | critical.md | Philosophical analysis, QFEP |

### Content Files

Maps can have these text files:
```
commons/maps/{MapName}/
├─ map_data.json     # Grid data + metadata
├─ blurb.md          # Short description (169 maps)
├─ technical.md      # Code/implementation (66 maps)
├─ summary.md        # Layout overview (67 maps)
└─ critical.md       # Theory/critique (69 maps)
```

### Keyboard

- **F5** — Refresh validation
- **Esc** — Close / Back

### Files

| File | Purpose |
|------|---------|
| `ContentValidator.gd` | Validation + text loading |
| `ContentValidatorUI.gd/tscn` | Page-based drill-down UI |
| `ContentValidatorDesktop.tscn` | Standalone launcher |
| `MapGridDrawer.gd` | 2D grid visualization |
| `validate_content.gd` | Quick editor script |
