extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Ten-Print Maze[/b][/font_size][/center]
[center][i]One Line of Code, Infinite Pattern[/i][/center]

**The most famous one-liner in programming:**

[code]
10 PRINT CHR$(205.5+RND(1)); : GOTO 10
[/code]

**One line. Infinite maze. Pure randomness as art.**

[hr]

[b]The Original (Commodore 64 BASIC)[/b]

**Historical context (1982):**

[color=yellow][b]Code: Original Ten-Print[/b][/color]
[code]
# Commodore 64 BASIC:
# 10 PRINT CHR$(205.5+RND(1)); : GOTO 10

# Translation:
# - CHR$(205) = "/" character
# - CHR$(206) = "\" character
# - RND(1) returns random 0 or 1
# - 205.5 + 0 = 205 → "/"
# - 205.5 + 1 = 206 → "\"
# - GOTO 10 → loop forever

# Result: Infinite stream of random slashes
# / \ \ / / \ / / \ \ / \ ...
[/code]

**Output visualization:**
[code]
/\/\\/\//\/\
\/\/\\/\/\\/
/\//\\/\\/\/
\/\\/\//\/\/
[/code]

**Emergent maze** - no explicit maze algorithm, just random binary choice.

[hr]

[b]Why Is This Profound?[/b]

**Minimal complexity, maximal emergence:**

1. **One line creates pattern** - Not planned, but emerges from randomness
2. **Binary choice** - Simplest decision (/ or \)
3. **Infinite variation** - Never repeats exactly (probabilistically)
4. **Maze-like structure** - Looks designed, but purely random
5. **Poetic code** - Minimal, elegant, beautiful

**It's procedural generation in its purest form.**

[hr]

[b]GDScript Version[/b]

**Modern implementation:**

[color=yellow][b]Code: Ten-Print in Godot[/b][/color]
[code]
extends Node2D

var chars = ["/", "\\"]
var cell_size = 20
var grid_x = 0
var grid_y = 0

func _ready():
    print_maze()

func print_maze():
    for y in range(20):
        var line = ""
        for x in range(40):
            line += chars[randi() % 2]
        print(line)

# Output to console:
# /\/\\/\//\/\\/\/\//\...
# \/\/\\/\/\\/\/\/\\/\...
# (20 rows × 40 columns)
[/code]

[hr]

[b]Visual Ten-Print (Rendered)[/b]

**Draw to screen instead of text:**

[color=yellow][b]Code: Visual Maze[/b][/color]
[code]
extends Node2D

var cell_size = 20
var line_width = 2

func _draw():
    for y in range(30):
        for x in range(40):
            var pos = Vector2(x * cell_size, y * cell_size)

            if randi() % 2 == 0:
                # Draw "/"
                draw_line(
                    pos + Vector2(0, cell_size),
                    pos + Vector2(cell_size, 0),
                    Color.WHITE,
                    line_width
                )
            else:
                # Draw "\"
                draw_line(
                    pos,
                    pos + Vector2(cell_size, cell_size),
                    Color.WHITE,
                    line_width
                )

# Result: Infinite maze pattern on screen
# Can zoom, pan, admire emergent structure
[/code]

[hr]

[b]Variations: Beyond Binary[/b]

**What if not just two choices?**

[color=yellow][b]1. Four-Way (Cross Pattern)[/b][/color]
[code]
# Use four characters: / \ | —
var chars = ["/", "\\", "|", "-"]

func draw_ten_print_variant():
    for y in range(20):
        for x in range(20):
            var choice = randi() % 4
            var pos = Vector2(x * cell_size, y * cell_size)

            match choice:
                0:  # "/"
                    draw_line(pos + Vector2(0, cell_size), pos + Vector2(cell_size, 0), Color.WHITE, 2)
                1:  # "\"
                    draw_line(pos, pos + Vector2(cell_size, cell_size), Color.WHITE, 2)
                2:  # "|"
                    draw_line(pos + Vector2(cell_size/2, 0), pos + Vector2(cell_size/2, cell_size), Color.WHITE, 2)
                3:  # "—"
                    draw_line(pos + Vector2(0, cell_size/2), pos + Vector2(cell_size, cell_size/2), Color.WHITE, 2)

# Result: More complex, less maze-like
# Interesting texture, but loses ten-print elegance
[/code]

[hr]

[b]Weighted Randomness[/b]

**Not 50/50 - bias toward one slash:**

[color=yellow][b]Code: Biased Ten-Print[/b][/color]
[code]
# 70% "/", 30% "\"
func biased_ten_print():
    for y in range(20):
        var line = ""
        for x in range(40):
            if randf() < 0.7:
                line += "/"
            else:
                line += "\\"
        print(line)

# Result: Diagonal bias
# Pattern leans right (more "/" than "\")
# Less balanced, more directional flow
[/code]

**Bias creates directionality** - 50/50 is balanced, other ratios flow.

[hr]

[b]Animated Ten-Print[/b]

**Generate maze in real-time:**

[color=yellow][b]Code: Growing Maze[/b][/color]
[code]
extends Node2D

var cell_size = 20
var current_x = 0
var current_y = 0
var max_x = 40
var max_y = 30
var cells = []

func _ready():
    set_process(true)

func _process(_delta):
    # Add one cell per frame
    var choice = randi() % 2
    cells.append({"x": current_x, "y": current_y, "slash": choice})

    current_x += 1
    if current_x >= max_x:
        current_x = 0
        current_y += 1
        if current_y >= max_y:
            current_y = 0
            cells.clear()  # Reset and start over

    queue_redraw()

func _draw():
    for cell in cells:
        var pos = Vector2(cell.x * cell_size, cell.y * cell_size)
        if cell.slash == 0:
            draw_line(pos + Vector2(0, cell_size), pos + Vector2(cell_size, 0), Color.WHITE, 2)
        else:
            draw_line(pos, pos + Vector2(cell_size, cell_size), Color.WHITE, 2)

# Result: Maze grows before your eyes
# Hypnotic, meditative, infinite scroll
[/code]

[hr]

[b]Colored Ten-Print[/b]

**Add color based on position or randomness:**

[color=yellow][b]Code: Rainbow Maze[/b][/color]
[code]
func _draw():
    for y in range(30):
        for x in range(40):
            var pos = Vector2(x * cell_size, y * cell_size)
            var hue = fmod(x * 0.05 + y * 0.05, 1.0)
            var color = Color.from_hsv(hue, 1.0, 1.0)

            if randi() % 2 == 0:
                draw_line(pos + Vector2(0, cell_size), pos + Vector2(cell_size, 0), color, 2)
            else:
                draw_line(pos, pos + Vector2(cell_size, cell_size), color, 2)

# Result: Gradient maze, psychedelic
# Pattern + color = more visual complexity
[/code]

[hr]

[b]3D Ten-Print (Voxel Maze)[/b]

**Extend to three dimensions:**

[color=yellow][b]Code: 3D Slash Field[/b][/color]
[code]
# Place diagonal planes in 3D grid
func generate_3d_ten_print():
    for z in range(20):
        for y in range(20):
            for x in range(20):
                var choice = randi() % 2

                # Create diagonal plane mesh
                var plane = PlaneMesh.new()
                plane.size = Vector2(1, 1)

                var instance = MeshInstance3D.new()
                instance.mesh = plane
                instance.position = Vector3(x, y, z)

                if choice == 0:
                    instance.rotation_degrees.y = 45  # "/" diagonal
                else:
                    instance.rotation_degrees.y = -45  # "\" diagonal

                add_child(instance)

# Result: 3D maze-like structure
# Navigable, complex, infinite variation
[/code]

[hr]

[b]Ten-Print as Texture[/b]

**Use for procedural materials:**

[color=yellow][b]Code: Ten-Print Shader[/b][/color]
[code]
shader_type canvas_item;

// Hash function for pseudo-random
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 grid_pos = floor(UV * 20.0);  // 20×20 grid
    vec2 local_pos = fract(UV * 20.0);  // Position within cell

    float random = hash(grid_pos);
    float line_dist;

    if (random < 0.5) {
        // "/" diagonal: distance to line from (0,1) to (1,0)
        line_dist = abs(local_pos.x + local_pos.y - 1.0) / sqrt(2.0);
    } else {
        // "\" diagonal: distance to line from (0,0) to (1,1)
        line_dist = abs(local_pos.x - local_pos.y) / sqrt(2.0);
    }

    float line_thickness = 0.05;
    float line = smoothstep(line_thickness, 0.0, line_dist);

    COLOR = vec4(vec3(line), 1.0);
}

// Result: Infinite ten-print pattern as texture
// Can apply to any surface, scale arbitrarily
[/code]

[hr]

[b]The Philosophy of Ten-Print[/b]

**What does this one-liner teach us?**

[color=yellow][b]1. Minimalism is Power[/b][/color]
- One line, infinite complexity
- Less code ≠ less interesting
- Constraints breed creativity

[color=yellow][b]2. Emergence from Simplicity[/b][/color]
- No maze algorithm, just randomness
- Pattern emerges from accumulation
- Complexity is not complexity of parts

[color=yellow][b]3. Binary Is Enough[/b][/color]
- Two choices create rich structure
- Don't need many variables for beauty
- / and \ are all you need

[color=yellow][b]4. Poetry in Code[/b][/color]
- Code can be beautiful
- Elegance matters
- Form and function unite

[color=yellow][b]5. Historical Continuity[/b][/color]
- 1982 to now, still compelling
- Transcends platform (C64 to Godot)
- Timeless idea

[hr]

[b]Ten-Print Relatives[/b]

**Other one-line wonders:**

[color=yellow][b]1. Sierpinski Triangle[/b][/color]
[code]
# One line (conceptually):
for i in range(16):
    print(" " * (16 - i) + "* " * i if i & (i - 1) == 0 else "")

# Result: Fractal triangle from binary AND
[/code]

[color=yellow][b]2. Mandelbrot Set[/b][/color]
[code]
# Compact complex number iteration:
print("\n".join("".join(" .*:;+=xX$&#"[int(max([abs(sum([(0.02*x+0.05*y*1j)**(2**k) for k in range(50)])) - 2, 0]))] for x in range(-60, 20)) for y in range(-20, 20)))

# Result: ASCII Mandelbrot (one statement)
[/code]

[color=yellow][b]3. Conway's Game of Life (One-Liner)[/b][/color]
- Possible but unreadable
- Demonstrates one-line ≠ good practice
- Ten-print works BECAUSE it's simple

[hr]

[b]Interactive Ten-Print[/b]

**Let user control parameters:**

[color=yellow][b]Code: Parameter Control[/b][/color]
[code]
extends Node2D

@export var cell_size: float = 20.0
@export var line_width: float = 2.0
@export var slash_probability: float = 0.5
@export var use_seed: bool = false
@export var random_seed: int = 0

func _ready():
    if use_seed:
        seed(random_seed)
    queue_redraw()

func _draw():
    for y in range(int(get_viewport_rect().size.y / cell_size)):
        for x in range(int(get_viewport_rect().size.x / cell_size)):
            var pos = Vector2(x * cell_size, y * cell_size)

            if randf() < slash_probability:
                draw_line(pos + Vector2(0, cell_size), pos + Vector2(cell_size, 0), Color.WHITE, line_width)
            else:
                draw_line(pos, pos + Vector2(cell_size, cell_size), Color.WHITE, line_width)

# Result: Tweakable ten-print
# Adjust in inspector, see changes
[/code]

[hr]

[b]What Ten-Print Reveals[/b]

Ten-print shows us:

1. **Simplicity scales** - One concept, infinite application
2. **Randomness creates structure** - Chaos organizes itself
3. **Constraints are creative** - Binary choice is enough
4. **Code is poetry** - Elegance in brevity
5. **History persists** - 1982 idea still relevant
6. **Emergence over design** - Pattern without planning
7. **Minimalism is radical** - Resist feature creep

**Ten-print is punk** - DIY, minimal, immediate, beautiful.

**One line. Infinite maze. Proof that less is more.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Ten-print maze: one line of code (`10 PRINT CHR$(205.5+RND(1)); : GOTO 10`) generates infinite maze pattern from random binary choice (/ or \). Emergent complexity from minimal rules. Variations include visual rendering, animation, color, 3D extension, shader implementation. Demonstrates minimalism, emergence, poetry in code. Historical (1982 Commodore 64) but timeless. Binary choice sufficient for rich structure.

[hr]

[color=orange][b]Next:[/b] Procedural Placement[/color]
If ten-print creates pattern from binary choice, procedural placement scatters objects intelligently - trees, rocks, NPCs positioned by algorithm, not hand. Blue noise, Poisson disks, terrain-aware spawning.

'''
