extends Control

# Code Block Style Tester
# Run this scene to preview different code block styles
# Press 1-6 to switch between presets

@onready var rich_label: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel
@onready var style_label: Label = $MarginContainer/VBoxContainer/StyleLabel

enum Style {
    MATRIX,
    DRACULA,
    MONOKAI,
    SOLARIZED,
    CYBERPUNK,
    RAINBOW
}

var current_style = Style.MATRIX
var rainbow_hue = 0.0

var sample_code = '''[center][font_size=24][b]Code Block Style Preview[/b][/font_size][/center]

[b]Example 1: Simple Function[/b]

[code]
func fibonacci(n: int) -> int:
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)
[/code]

[b]Example 2: Class Definition[/b]

[code]
class BloomFilter

var bit_array: PackedByteArray
var m: int  # Size
var k: int  # Hash functions

func _init(size: int, num_hashes: int):
    m = size
    k = num_hashes
    bit_array.resize((m + 7) / 8)
[/code]

[b]Example 3: Algorithm Pseudocode[/b]

[code]
# Dijkstra's Algorithm
distances[source] = 0
while not unvisited.is_empty():
    current = get_min_distance_node()
    for neighbor in graph.neighbors(current):
        alt = distances[current] + edge_weight
        if alt < distances[neighbor]:
            distances[neighbor] = alt
[/code]

[color=cyan][b]Press 1-6 to change code style:[/b][/color]
1 = Matrix Green  |  2 = Dracula  |  3 = Monokai
4 = Solarized     |  5 = Cyberpunk  |  6 = Rainbow (animated)
'''

func _ready():
    rich_label.bbcode_text = sample_code
    apply_style(current_style)
    update_style_label()

func _process(delta):
    if current_style == Style.RAINBOW:
        rainbow_hue += delta * 0.2
        if rainbow_hue > 1.0:
            rainbow_hue = 0.0

        var color = Color.from_hsv(rainbow_hue, 0.8, 0.95)
        rich_label.add_theme_color_override("font_code_color", color)

func _input(event):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1:
                apply_style(Style.MATRIX)
            KEY_2:
                apply_style(Style.DRACULA)
            KEY_3:
                apply_style(Style.MONOKAI)
            KEY_4:
                apply_style(Style.SOLARIZED)
            KEY_5:
                apply_style(Style.CYBERPUNK)
            KEY_6:
                apply_style(Style.RAINBOW)

func apply_style(style: Style):
    current_style = style

    match style:
        Style.MATRIX:
            set_code_colors(
                Color(0.2, 0.9, 0.6, 1),      # Bright green text
                Color(0.08, 0.12, 0.15, 1),   # Dark background
                "Matrix Green"
            )

        Style.DRACULA:
            set_code_colors(
                Color(0.95, 0.91, 0.82, 1),   # Cream text
                Color(0.16, 0.14, 0.21, 1),   # Purple-black
                "Dracula"
            )

        Style.MONOKAI:
            set_code_colors(
                Color(0.97, 0.97, 0.95, 1),   # Off-white
                Color(0.16, 0.15, 0.13, 1),   # Dark brown
                "Monokai"
            )

        Style.SOLARIZED:
            set_code_colors(
                Color(0.51, 0.58, 0.59, 1),   # Gray-blue
                Color(0, 0.17, 0.21, 1),      # Dark teal
                "Solarized Dark"
            )

        Style.CYBERPUNK:
            set_code_colors(
                Color(0, 0.95, 0.98, 1),      # Cyan
                Color(0.1, 0.02, 0.18, 1),    # Deep purple
                "Cyberpunk"
            )

        Style.RAINBOW:
            set_code_colors(
                Color(1, 1, 1, 1),            # White (will be animated)
                Color(0.05, 0.05, 0.1, 1),    # Very dark
                "Rainbow (Animated)"
            )

    update_style_label()

func set_code_colors(text_color: Color, bg_color: Color, name: String):
    rich_label.add_theme_color_override("font_code_color", text_color)
    rich_label.add_theme_color_override("font_code_bg_color", bg_color)

    # Calculate contrast ratio
    var contrast = get_contrast_ratio(text_color, bg_color)
    var accessibility = "Unknown"
    if contrast >= 7.0:
        accessibility = "AAA (Excellent)"
    elif contrast >= 4.5:
        accessibility = "AA (Good)"
    else:
        accessibility = "Fail (Poor)"

    print("[%s] Contrast: %.1f:1 - %s" % [name, contrast, accessibility])

func update_style_label():
    var style_name = ""
    match current_style:
        Style.MATRIX: style_name = "Matrix Green"
        Style.DRACULA: style_name = "Dracula"
        Style.MONOKAI: style_name = "Monokai"
        Style.SOLARIZED: style_name = "Solarized Dark"
        Style.CYBERPUNK: style_name = "Cyberpunk"
        Style.RAINBOW: style_name = "Rainbow (Animated)"

    style_label.text = "Current Style: %s (Press 1-6 to change)" % style_name

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
