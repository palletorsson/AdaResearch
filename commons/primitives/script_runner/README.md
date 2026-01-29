# Script Runner

A live code display gadget that shows GDScript code executing line-by-line with real evaluation and visual feedback.

## Features

- **Line-by-line execution** with prominent yellow highlight bar
- **Real Expression evaluation** using Godot's Expression class
- **Variable storage** - variables persist across lines
- **Visual feedback** - Vector3 values spawn 3D markers, arrays show grids
- **VR-ready** play button with touch interaction

## Usage in Maps

Add to map's `interactables` array:

```json
"interactables": [
    ["script_runner#point:90:1", " ", " "],
    ["script_runner#array:0:1", " ", " "]
]
```

### Available Scripts

| Config | Description |
|--------|-------------|
| `#point` | Vector3 basics - creating points, accessing x/y/z |
| `#vector_math` | Vector operations - addition, scaling, length |
| `#array` | 2D array indexing with visual 4x4 grid |
| `#pattern` | Checkerboard pattern using (row+col)%2 |
| `#loop` | For loop iteration through rows |

## Creating Custom Scripts

Edit `scripts.json` to add new scripts:

```json
{
    "scripts": {
        "my_script": {
            "name": "My Script",
            "description": "What this script teaches",
            "lines": [
                {"text": "# Comment line", "action": "none", "duration": 1.5},
                {"text": "var x = Vector3(1, 2, 3)", "action": "eval", "params": {"code": "var x = Vector3(1, 2, 3)"}, "duration": 2.0}
            ]
        }
    }
}
```

### Line Structure

Each line in the `lines` array:

```json
{
    "text": "code displayed on screen",
    "action": "action_name",
    "params": {"key": "value"},
    "duration": 2.0
}
```

## Actions

### Code Evaluation

| Action | Params | Description |
|--------|--------|-------------|
| `eval` | `{"code": "expression"}` | Evaluates real GDScript expression, stores variables, shows result |
| `none` | - | Display only, no action |

**Eval Examples:**
```json
{"text": "var point = Vector3(1, 2, 3)", "action": "eval", "params": {"code": "var point = Vector3(1, 2, 3)"}}
{"text": "print(point.x)", "action": "eval", "params": {"code": "print(point.x)"}}
{"text": "point = point + offset", "action": "eval", "params": {"code": "point = point + offset"}}
```

The `eval` action:
- Parses `var x = expr` assignments and stores variables
- Evaluates `print(expr)` and shows `>>> result`
- Supports property access like `point.x`
- Variables persist: use `point` after defining it

### Grid Visualization

| Action | Params | Description |
|--------|--------|-------------|
| `init_grid` | `{"size": 4}` | Creates NxN visual grid |
| `set_cell` | `{"row": 0, "col": 0, "color": "red"}` | Sets cell color with animation |
| `set_diagonal` | `{"color": "white"}` | Sets diagonal cells |
| `highlight_row` | `{"row": 0, "color": "cyan"}` | Highlights entire row |
| `highlight_col` | `{"col": 0, "color": "cyan"}` | Highlights entire column |
| `clear_grid` | - | Removes the grid |

**Available Colors:** `red`, `blue`, `green`, `yellow`, `white`, `black`, `orange`, `purple`, `cyan`, `off`

### Legacy Point Actions

| Action | Params | Description |
|--------|--------|-------------|
| `spawn_point` | `{"pos": [x,y,z], "color": [r,g,b,a]}` | Creates glowing sphere |
| `move_point` | `{"pos": [x,y,z]}` | Moves existing point |
| `shrink_point` | `{"scale": 0.5}` | Scales point size |
| `show_label` | `{"text": "label", "offset": [x,y,z]}` | Shows 3D text label |
| `clear_all` | - | Removes all spawned objects and resets |

## Display Components

### Code Panel
- Dark background with syntax highlighting
- Line numbers on left
- Yellow highlight bar shows current executing line
- Orange left accent for visibility

### Result Display (below panel)
- **Line indicator**: "Line X:" in yellow
- **Result value**: Evaluated result in green

### Visual Grid (for array scripts)
- 4x4 grid of 3D cubes to the right of panel
- Row/column headers (0, 1, 2, 3)
- Cells pulse and glow when set
- Index labels `[row,col]` appear briefly

### Play Button
- Green button at bottom-right of panel
- Click or VR touch to start/pause
- Changes to orange when running

## Keyboard Controls (for testing)

- `Space` - Play/Pause
- `R` - Reset and play from beginning

## Adding to Registry

After creating a new script, add it to `script_runner.json` registry:

```json
{
    "config_mapping": {
        "my_script": {"script_name": "my_script"}
    }
}
```

And update `_check_config_metadata()` in `script_runner.gd`:

```gdscript
var known_scripts = ["point", "vector_math", "array", "pattern", "loop", "my_script"]
```

## Expression Limitations

Godot's Expression class supports:
- Basic math: `+`, `-`, `*`, `/`, `%`
- Constructors: `Vector3()`, `Vector2()`, `Color()`
- Property access: `point.x`, `color.r`
- Method calls: `vector.length()`, `vector.normalized()`
- Variables defined in earlier lines

Does NOT support:
- Control flow (`if`, `for`, `while`)
- Function definitions
- Class instantiation
- File/scene access
