# Dialectic Panel System

A spatial system for walking through fractal argumentative structures in VR.

## Concept

Arguments unfold along the Z-axis (depth), with branches along X-axis (width). Each level contains the same pattern: **position → counter → critique of counter → pragmatic → limit → response → recurse**.

```
Player walks forward (Z) through the argument
        │
        ▼
    [Level 0: Thesis]
        │
        ▼
    [Level 1: Counter]
        │
        ▼
    [Level 2: Critique of Counter]
        │
        ▼
    ... (each step deeper into Z)
```

## Usage in map_data.json

### Utility Syntax

```
criticalinfo:<dialectic_name>
```

This places the entire dialectic structure starting at that grid position.

### Example

```json
{
    "layers": {
        "utilities": [
            [" ", " ", " ", " ", " "],
            [" ", "criticalinfo:automation_dialectic", " ", " ", " "],
            [" ", " ", " ", " ", " "]
        ]
    }
}
```

### With Parameters

```
criticalinfo:<name>:<rotation>:<scale>
```

- `rotation`: Y-axis rotation in degrees (default: 0)
- `scale`: Panel scale factor (default: 1.0)

```json
"criticalinfo:automation_dialectic:180:0.8"
```

## JSON Structure

Dialectic content files live in:
```
commons/infoboards_3d/content/dialectic/{name}.json
```

### Schema

```json
{
    "_meta": {
        "id": "dialectic_id",
        "title": "Display Title",
        "subtitle": "Subtitle",
        "description": "What this dialectic explores",
        "layout": {
            "z_spacing": 3.0,    // Distance between levels
            "x_spacing": 2.5,    // Distance between branches
            "panel_scale": 0.8   // Default panel scale
        }
    },
    "levels": [
        {
            "level": 0,
            "theme": "thesis|counter|critique|pragmatic|limit|response|recursion",
            "panels": [
                {
                    "x": 0,                           // X position (0 = center, -1 = left, 1 = right)
                    "title": "Panel Title",
                    "position": "The core claim",
                    "narrative": ["Line 1", "Line 2"],
                    "code": {
                        "block": "# code example",
                        "language": "gdscript"
                    },
                    "qfep": {
                        "term": "F|E(S)|λ|φΔE(S,t)",
                        "description": "How this relates to QFEP"
                    },
                    "transition": "but then..."       // null for final panel
                }
            ]
        }
    ]
}
```

## Spatial Layout

```
Z=0:    [0,0]           Level 0 (Thesis)
          │
Z=3:    [1,0]           Level 1 (Counter)
          │
Z=6:    [2,0]           Level 2 (Critique)
          │
Z=9:    [3,0]──[3,1]    Level 3 (Pragmatic + branch)
          │
...

Where:
- Z increases as player walks forward
- X = 0 is center line
- X < 0 is left branch
- X > 0 is right branch
```

## Panel Content Fields

| Field | Required | Description |
|-------|----------|-------------|
| `title` | Yes | Panel header |
| `position` | Yes | Core claim (bold/emphasized) |
| `narrative` | No | Array of explanatory paragraphs |
| `code` | No | Code example with language tag |
| `qfep` | No | QFEP connection (term + description) |
| `transition` | No | Text leading to next level (null = end) |

## Theme Colors (Suggested)

| Theme | Color | Meaning |
|-------|-------|---------|
| thesis | Red | Initial position |
| counter | Blue | Counter-position |
| critique | Yellow | Critique of counter |
| pragmatic | Green | Practical response |
| limit | Orange | Limitation |
| response | Cyan | Hacker response |
| recursion | Purple | Meta-level / recursion |

## Integration with QFEP

Each panel can reference how it relates to the Queer Free Energy Principle:

- **F** (Free Energy): Order, prediction, control
- **E(S)** (Entropy): Disorder, freedom, possibility
- **λ** (Lambda): The dial between order and chaos
- **φΔE(S,t)** (Rate of change): Embrace of becoming

## Example Dialectics to Create

1. `automation_dialectic.json` - Automation and autonomy (created)
2. `bias_dialectic.json` - AI bias and intervention
3. `open_source_dialectic.json` - Free software and its limits
4. `embodiment_dialectic.json` - VR and physical presence
5. `abstraction_dialectic.json` - Abstraction as power

## Implementation Notes

The system needs:
1. A `DialecticPanelGenerator.gd` script that reads the JSON
2. Integration with `GridUtilitiesComponent.gd` to parse `criticalinfo:` prefix
3. Panel template scene (can reuse/adapt `info_board.tscn`)
4. BBCode rendering for formatted text

The player walks through Z, reading each level. Optional: interaction to expand code blocks, show QFEP connections, or branch to alternative paths.
