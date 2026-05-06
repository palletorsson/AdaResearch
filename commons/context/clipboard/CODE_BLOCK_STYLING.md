# Code Block Styling Guide

## Current Configuration

The `[code]` blocks now have custom styling:

- **Text Color**: `Color(0.2, 0.9, 0.6)` - Bright green (matrix-style)
- **Background**: `Color(0.08, 0.12, 0.15)` - Very dark blue-gray
- **Font Size**: `16` (slightly smaller than normal text)

## Available Theme Properties for Code Blocks

### Colors

| Property | Description | Example |
|----------|-------------|---------|
| `font_code_color` | Text color inside `[code]` | `Color(0.2, 0.9, 0.6)` - Green |
| `font_code_bg_color` | Background color | `Color(0.08, 0.12, 0.15)` - Dark |
| `font_mono_color` | Alternative code color | `Color(0.9, 0.7, 0.3)` - Gold |

### Fonts

| Property | Description | Notes |
|----------|-------------|-------|
| `mono_font` | Monospace font resource | Use `.ttf` font file |
| `mono_font_size` | Code font size | Typically 14-18 |

### Borders/Padding

| Property | Description |
|----------|-------------|
| `code_border_width` | Border thickness |
| `code_border_color` | Border outline color |

## Method 2: Create a Custom Theme Resource

For more control, create a dedicated theme:

### Step 1: Create Theme Resource

```gdscript
# res://commons/themes/tutorial_theme.tres
[gd_resource type="Theme" format=3]

[resource]

# Code block styling
RichTextLabel/colors/font_code_color = Color(0.2, 0.9, 0.6, 1)
RichTextLabel/colors/font_code_bg_color = Color(0.08, 0.12, 0.15, 1)
RichTextLabel/font_sizes/mono_font_size = 16

# Load custom monospace font
RichTextLabel/fonts/mono_font = preload("res://commons/font/JetBrainsMono-Regular.ttf")
```

### Step 2: Apply to RichTextLabel

In the `.tscn` file:
```
[node name="TutorialContent" type="RichTextLabel"]
theme = ExtResource("tutorial_theme")
```

Or programmatically:
```gdscript
var theme = preload("res://commons/themes/tutorial_theme.tres")
rich_text_label.theme = theme
```

## Method 3: Programmatic Styling

Apply styles via code for dynamic changes:

```gdscript
extends Control

@onready var tutorial_content = $MarginContainer/ScrollContainer/TutorialContent

func _ready():
    apply_code_styling()

func apply_code_styling():
    # Code text color (bright green)
    tutorial_content.add_theme_color_override(
        "font_code_color",
        Color(0.2, 0.9, 0.6, 1.0)
    )

    # Code background (dark)
    tutorial_content.add_theme_color_override(
        "font_code_bg_color",
        Color(0.08, 0.12, 0.15, 1.0)
    )

    # Code font size
    tutorial_content.add_theme_font_size_override(
        "mono_font_size",
        16
    )

    # Optional: Custom monospace font
    var mono_font = load("res://commons/font/JetBrainsMono-Regular.ttf")
    tutorial_content.add_theme_font_override("mono_font", mono_font)
```

## Color Scheme Presets

### Preset 1: Matrix Green (Current)
```gdscript
font_code_color = Color(0.2, 0.9, 0.6, 1)      # Bright green
font_code_bg_color = Color(0.08, 0.12, 0.15, 1) # Dark blue-gray
```

### Preset 2: Dracula
```gdscript
font_code_color = Color(0.95, 0.91, 0.82, 1)    # Cream
font_code_bg_color = Color(0.16, 0.14, 0.21, 1) # Purple-black
```

### Preset 3: Monokai
```gdscript
font_code_color = Color(0.97, 0.97, 0.95, 1)    # Off-white
font_code_bg_color = Color(0.16, 0.15, 0.13, 1) # Dark brown
```

### Preset 4: Solarized Dark
```gdscript
font_code_color = Color(0.51, 0.58, 0.59, 1)    # Gray-blue
font_code_bg_color = Color(0, 0.17, 0.21, 1)    # Dark teal
```

### Preset 5: Cyberpunk (Recommended for Ada Research!)
```gdscript
font_code_color = Color(0, 0.95, 0.98, 1)       # Cyan
font_code_bg_color = Color(0.1, 0.02, 0.18, 1)  # Deep purple
```

### Preset 6: Queer Pride Rainbow (Animated)
```gdscript
# Changes color over time - implement in _process()
func _process(delta):
    var hue = fmod(Time.get_ticks_msec() / 5000.0, 1.0)
    var rainbow_color = Color.from_hsv(hue, 0.8, 0.95)
    tutorial_content.add_theme_color_override("font_code_color", rainbow_color)
```

## Advanced: Syntax Highlighting

For true syntax highlighting, use custom BBCode tags:

```gdscript
# In tutorial text:
var text = '''
[code]
[color=#ff6188]func[/color] [color=#ffd866]fibonacci[/color]([color=#a9dc76]n[/color]: [color=#78dce8]int[/color]) -> [color=#78dce8]int[/color]:
    [color=#ff6188]if[/color] n <= 1:
        [color=#ff6188]return[/color] n
    [color=#ff6188]return[/color] fibonacci(n - 1) + fibonacci(n - 2)
[/code]
'''
```

Or use a syntax highlighter:

```gdscript
extends RichTextLabel

var syntax_colors = {
    "keyword": Color(1.0, 0.38, 0.53),  # Pink
    "function": Color(1.0, 0.85, 0.4),  # Yellow
    "number": Color(0.67, 0.87, 0.46),  # Green
    "string": Color(0.47, 0.86, 0.91),  # Cyan
    "comment": Color(0.6, 0.6, 0.6)     # Gray
}

func highlight_code(code: String) -> String:
    # Replace keywords
    var keywords = ["func", "var", "if", "return", "for", "while", "class"]
    for kw in keywords:
        var regex = RegEx.new()
        regex.compile("\\b" + kw + "\\b")
        code = regex.sub(code, "[color=#%s]%s[/color]" % [
            syntax_colors.keyword.to_html(false),
            kw
        ], true)

    return code
```

## Custom Font for Code Blocks

Use a proper monospace font for better readability:

### Recommended Fonts:
1. **JetBrains Mono** - Free, designed for code
2. **Fira Code** - Includes ligatures (→ becomes arrow)
3. **Source Code Pro** - Clean, professional
4. **IBM Plex Mono** - Modern, readable

### How to Add:

1. Download `.ttf` file
2. Place in `res://commons/font/`
3. Reference in theme or code:

```gdscript
var code_font = preload("res://commons/font/JetBrainsMono-Regular.ttf")
tutorial_content.add_theme_font_override("mono_font", code_font)
```

## Border/Box Styling

Add a border around code blocks:

```gdscript
# Create StyleBox for code background
var code_stylebox = StyleBoxFlat.new()
code_stylebox.bg_color = Color(0.08, 0.12, 0.15, 1)
code_stylebox.border_color = Color(0.2, 0.9, 0.6, 0.3)
code_stylebox.border_width_left = 3
code_stylebox.border_width_right = 1
code_stylebox.border_width_top = 1
code_stylebox.border_width_bottom = 1
code_stylebox.corner_radius_top_left = 4
code_stylebox.corner_radius_top_right = 4
code_stylebox.corner_radius_bottom_left = 4
code_stylebox.corner_radius_bottom_right = 4

# Note: RichTextLabel doesn't directly support StyleBox for code blocks
# You'd need to use a custom BBCode effect or wrap code in a Panel
```

## Testing Your Styles

Create a test scene to preview different styles:

```gdscript
extends Control

@onready var preview = $RichTextLabel

func _ready():
    preview.bbcode_text = '''
[b]Code Block Style Preview[/b]

Normal text goes here with some explanation.

[code]
func example_function(param: int) -> String:
    var result = "Test " + str(param)
    if param > 0:
        result += " is positive"
    return result
[/code]

More normal text after the code block.
'''
```

## Current Style Preview

With the current settings (`Matrix Green`), code blocks will look like:

```
┌──────────────────────────────────────────┐
│ func dijkstra(graph, source):            │
│     var distances = {}                   │
│     distances[source] = 0                │
│     return distances                     │
└──────────────────────────────────────────┘
```

- **Text**: Bright green (#33FF99)
- **Background**: Very dark blue (#141E26)
- **Font**: Monospace, 16px

## Quick Style Switcher

Add a style switcher to tutorial_display_2d.gd:

```gdscript
enum CodeStyle { MATRIX, DRACULA, MONOKAI, CYBERPUNK }

var current_style = CodeStyle.MATRIX

func apply_code_style(style: CodeStyle):
    match style:
        CodeStyle.MATRIX:
            set_code_colors(Color(0.2, 0.9, 0.6), Color(0.08, 0.12, 0.15))
        CodeStyle.DRACULA:
            set_code_colors(Color(0.95, 0.91, 0.82), Color(0.16, 0.14, 0.21))
        CodeStyle.MONOKAI:
            set_code_colors(Color(0.97, 0.97, 0.95), Color(0.16, 0.15, 0.13))
        CodeStyle.CYBERPUNK:
            set_code_colors(Color(0, 0.95, 0.98), Color(0.1, 0.02, 0.18))

func set_code_colors(text_color: Color, bg_color: Color):
    tutorial_content.add_theme_color_override("font_code_color", text_color)
    tutorial_content.add_theme_color_override("font_code_bg_color", bg_color)
```

## Accessibility Considerations

Ensure good contrast for readability:

- **Minimum contrast ratio**: 4.5:1 (WCAG AA)
- **Recommended**: 7:1 (WCAG AAA)

Test your colors:
```gdscript
func get_contrast_ratio(fg: Color, bg: Color) -> float:
    var l1 = get_relative_luminance(fg)
    var l2 = get_relative_luminance(bg)
    var lighter = max(l1, l2)
    var darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

func get_relative_luminance(c: Color) -> float:
    var r = c.r if c.r <= 0.03928 else pow((c.r + 0.055) / 1.055, 2.4)
    var g = c.g if c.g <= 0.03928 else pow((c.g + 0.055) / 1.055, 2.4)
    var b = c.b if c.b <= 0.03928 else pow((c.b + 0.055) / 1.055, 2.4)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
```

Current contrast: Green (#33FF99) on Dark (#141E26) ≈ 12:1 ✅ Excellent!
