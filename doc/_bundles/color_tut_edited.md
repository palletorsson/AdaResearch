<<<ADA_BUNDLE>>>
sequence: color
file: tutorial.md
maps: 8
skipped_passing: 0
created: 2026-04-24T08:42:06
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Color_Nails>>>
# Color Nails

Apply colour to a surface. Palette as data, surface as canvas.

Define a colour.

```gdscript
var red := Color(1.0, 0.0, 0.0)
var custom := Color.from_hsv(0.33, 0.8, 0.7)  # saturated green
```

Colour is four floats — red, green, blue, alpha. The from_hsv constructor takes hue, saturation, value instead.

Build a palette.

```gdscript
var palette: Array[Color] = [
    Color.RED, Color.ORANGE, Color.YELLOW,
    Color.GREEN, Color.BLUE, Color.PURPLE,
]
```

A typed array of Color. Access by index; mutate by assignment.

Apply a colour to a mesh.

```gdscript
func apply_color(mesh: MeshInstance3D, color: Color) -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material
```

material_override replaces the default surface material. The colour is the new albedo.

Select a palette index by nail.

```gdscript
class_name NailColorController extends Node3D

var selected_index: int = 0

func _on_nail_pressed(index: int) -> void:
    selected_index = index
    emit_signal("color_selected", palette[index])
```

One nail per palette entry. Pressing a nail emits the signal with the chosen colour.

Apply to a hand model.

```gdscript
func paint_hand(hand: Node3D, color: Color) -> void:
    for mesh in hand.find_children("", "MeshInstance3D"):
        apply_color(mesh, color)
```

Recursive find for every mesh under the hand. Each is retinted to the selected colour.

Add hue display.

```gdscript
func hsv_of(color: Color) -> Vector3:
    return Vector3(color.h, color.s, color.v)
```

Godot's Color exposes h, s, v directly. The Vector3 packaging is just for display.

Save the selected palette to disk.

```gdscript
func save_palette(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    for c in palette:
        file.store_line("%f %f %f %f" % [c.r, c.g, c.b, c.a])
```

One colour per line, four floats each. The file is human-readable.

Load a palette back.

```gdscript
func load_palette(path: String) -> Array[Color]:
    var loaded: Array[Color] = []
    var file := FileAccess.open(path, FileAccess.READ)
    while not file.eof_reached():
        var parts := file.get_line().split_whitespace()
        if parts.size() == 4:
            loaded.append(Color(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3])))
    return loaded
```

Parse four floats per line. The loaded palette can be applied directly to any nail controller.

You can now build a palette, apply colours to meshes, select palette entries by nail, and persist palettes to disk. Color_Grid_Pallet extends colour into a grid-based canvas.

<<<MAP: Color_Grid_Pallet>>>
# Color Grid Pallet

A grid becomes a palette. Each cell holds a colour.

Build the grid.

```gdscript
const GRID_SIZE := Vector2i(4, 4)
var palette_grid: Array = []  # 2D array of Color

func build_grid() -> void:
    palette_grid.clear()
    for y in GRID_SIZE.y:
        var row: Array = []
        for x in GRID_SIZE.x:
            row.append(Color.WHITE)
        palette_grid.append(row)
```

Sixteen cells, all white. The grid is a small image with each pixel editable.

Paint a cell.

```gdscript
func paint_cell(x: int, y: int, color: Color) -> void:
    palette_grid[y][x] = color
    emit_signal("palette_changed")
```

Direct assignment. The signal lets listeners know to re-render.

Render the grid as a texture.

```gdscript
func grid_to_texture() -> ImageTexture:
    var image := Image.create(GRID_SIZE.x, GRID_SIZE.y, false, Image.FORMAT_RGBA8)
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            image.set_pixel(x, y, palette_grid[y][x])
    return ImageTexture.create_from_image(image)
```

Each grid cell becomes one texel. The result is a 4x4 texture ready to apply to any surface.

Scale the texture up without blurring.

```gdscript
func apply_pixelated(mesh: MeshInstance3D, texture: ImageTexture) -> void:
    var material := StandardMaterial3D.new()
    material.albedo_texture = texture
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    mesh.material_override = material
```

Nearest-neighbour filtering preserves the discrete blocks. Linear filtering would blur them into gradients.

Link cells to a painting controller.

```gdscript
func _on_cell_clicked(cell_coords: Vector2i) -> void:
    var selected_color: Color = color_picker.selected_color
    paint_cell(cell_coords.x, cell_coords.y, selected_color)
```

The user picks a colour, then clicks a cell. The cell updates to the picked colour.

Spawn a 3D constellation from the grid.

```gdscript
func spawn_color_constellation() -> void:
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            var sphere := MeshInstance3D.new()
            sphere.mesh = SphereMesh.new()
            sphere.position = Vector3(x, y, 0) * 0.5
            var mat := StandardMaterial3D.new()
            mat.albedo_color = palette_grid[y][x]
            sphere.material_override = mat
            add_child(sphere)
```

Each grid cell becomes a coloured sphere. The grid's 2D layout becomes a spatial relationship.

Interpolate between cells for a smooth palette.

```gdscript
func smooth_sample(u: float, v: float) -> Color:
    var x: float = u * (GRID_SIZE.x - 1)
    var y: float = v * (GRID_SIZE.y - 1)
    var x0: int = int(floor(x)); var x1: int = min(x0 + 1, GRID_SIZE.x - 1)
    var y0: int = int(floor(y)); var y1: int = min(y0 + 1, GRID_SIZE.y - 1)
    var fx: float = x - x0; var fy: float = y - y0
    var c00: Color = palette_grid[y0][x0]; var c10: Color = palette_grid[y0][x1]
    var c01: Color = palette_grid[y1][x0]; var c11: Color = palette_grid[y1][x1]
    return c00.lerp(c10, fx).lerp(c01.lerp(c11, fx), fy)
```

Bilinear interpolation between four corner cells. The result is a smooth palette at any (u, v) position.

You can now build a grid palette, paint cells, render the grid as a pixelated texture, and sample a smooth palette via interpolation. Color_Rainbow extends into a continuous spectrum.

<<<MAP: Color_Rainbow>>>
# Color Rainbow

Move through the spectrum. Hue is an angle on a circle.

Cycle through hue.

```gdscript
var hue_time: float = 0.0

func _process(delta: float) -> void:
    hue_time = fmod(hue_time + delta * 0.2, 1.0)
    var color := Color.from_hsv(hue_time, 1.0, 1.0)
    apply_current_color(color)
```

hue_time wraps at 1.0. At speed 0.2, one full cycle takes 5 seconds.

Build a rainbow emitter.

```gdscript
class_name RainbowEmitter extends Node3D

@export var cycle_speed: float = 0.15
@export var saturation: float = 0.9
@export var value: float = 0.9

var phase: float = 0.0

func _process(delta: float) -> void:
    phase = fmod(phase + delta * cycle_speed, 1.0)
    var current := Color.from_hsv(phase, saturation, value)
    update_emission(current)
```

Per-emitter phase and speed. A row of emitters with staggered phases produces a running gradient.

Stagger phases along a corridor.

```gdscript
func spawn_corridor_of_emitters(count: int, length: float) -> void:
    for i in count:
        var em := RainbowEmitter.new()
        em.position = Vector3(0, 2, -i * length / count)
        em.phase = float(i) / count
        add_child(em)
```

Each emitter starts at a different point in the hue cycle. Over time, they all cycle through the full spectrum.

Interpolate hue between two colours.

```gdscript
func lerp_hue(a: Color, b: Color, t: float) -> Color:
    var ha := a.h; var hb := b.h
    var diff: float = hb - ha
    if abs(diff) > 0.5:
        if diff > 0: ha += 1.0
        else: hb += 1.0
    var new_h: float = fmod(lerp(ha, hb, t), 1.0)
    return Color.from_hsv(new_h, lerp(a.s, b.s, t), lerp(a.v, b.v, t))
```

Handle the wrap-around. Interpolating from red (0.0) to violet (0.83) through the short arc gives the classical rainbow; through the long arc, mud.

Build a temporal gradient on a surface.

```gdscript
func rainbow_texture(width: int, height: int, time_offset: float = 0.0) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    for x in width:
        var hue: float = fmod(float(x) / width + time_offset, 1.0)
        var color := Color.from_hsv(hue, 1.0, 1.0)
        for y in height:
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)
```

Horizontal sweep through hue. Shifting time_offset scrolls the gradient.

Drop a grabbable Mario cube in the corridor.

```gdscript
func spawn_mario_cube() -> RigidBody3D:
    var cube := RigidBody3D.new()
    cube.mesh = preload("res://commons/color/mario_cube.tscn").instantiate()
    cube.add_to_group("grabbable")
    add_child(cube)
    return cube
```

A grabbable artifact the learner can pull out of the rainbow and inspect. Its material stays fixed as a colour sample.

Display the current hue value.

```gdscript
func update_hue_label(label: Label3D, color: Color) -> void:
    label.text = "h=%.2f s=%.2f v=%.2f" % [color.h, color.s, color.v]
```

The label updates as the colour changes. Reads like a frequency meter rather than a colour name.

You can now build rainbow emitters with staggered phases, interpolate hue around the circle, generate a rainbow texture, and track hue live. Color_Pillar extends colour into a mixable, stackable form.

<<<MAP: Color_Pillar>>>
# Color Pillar

Pillars collect colour. Mixing reveals process.

Build a pillar of coloured segments.

```gdscript
class_name ColorPillar extends Node3D

@export var segments: int = 12

func _ready() -> void:
    for i in segments:
        var segment := MeshInstance3D.new()
        segment.mesh = CylinderMesh.new()
        segment.position.y = i * 0.4
        var hue: float = float(i) / segments
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color.from_hsv(hue, 0.9, 0.9)
        segment.material_override = mat
        add_child(segment)
```

Twelve segments. Each carries a different hue. The stack reads as a vertical palette.

Grab a colour stick from the pillar.

```gdscript
class_name ColorStick extends RigidBody3D

@export var source_color: Color

func _on_grab_released() -> void:
    apply_to_world(source_color)
```

Releasing the stick applies its colour to whatever it touches. The stick becomes a paint-pickup.

Mix two colours additively.

```gdscript
func mix_additive(a: Color, b: Color) -> Color:
    return Color(
        min(1.0, a.r + b.r),
        min(1.0, a.g + b.g),
        min(1.0, a.b + b.b),
    )
```

Red plus green makes yellow. Red plus green plus blue makes white. This is how light mixes.

Mix two colours subtractively.

```gdscript
func mix_subtractive(a: Color, b: Color) -> Color:
    return Color(a.r * b.r, a.g * b.g, a.b * b.b)
```

Cyan times magenta makes blue. Paint mixing: each pigment absorbs certain wavelengths. Multiplication models absorption.

Build a mixing station.

```gdscript
class_name MixingStation extends Node3D

var input_colors: Array[Color] = []

func add_input(color: Color) -> void:
    input_colors.append(color)
    recompute_output()

func recompute_output() -> Color:
    if input_colors.is_empty(): return Color.BLACK
    var result: Color = input_colors[0]
    for i in range(1, input_colors.size()):
        result = mix_additive(result, input_colors[i])
    return result
```

Accumulate inputs; recompute on each addition. The output updates continuously.

Visualise a spectrum.

```gdscript
func spawn_spectrum_visualizer() -> void:
    for i in 32:
        var hue: float = float(i) / 32
        var bar := MeshInstance3D.new()
        bar.mesh = BoxMesh.new()
        bar.scale = Vector3(0.1, 1.0, 0.1)
        bar.position = Vector3(i * 0.15, 0, 0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color.from_hsv(hue, 1.0, 1.0)
        bar.material_override = mat
        add_child(bar)
```

Thirty-two vertical bars across the hue circle. A compact spectrum display.

Demonstrate flashlight-dependent colour.

```gdscript
func apply_flashlight_color(target: Node3D, light_color: Color) -> void:
    for mesh in target.find_children("", "MeshInstance3D"):
        var mat: StandardMaterial3D = mesh.material_override
        if mat:
            mat.albedo_color = mix_subtractive(mat.albedo_color, light_color)
```

A red object under green light absorbs most of the illumination and appears dark. The multiplicative mix is physically accurate.

You can now build a pillar of colour samples, grab colour sticks, mix additively or subtractively, display a spectrum, and apply flashlight-dependent colour. Color_Paint extends into gestural application.

<<<MAP: Color_Paint>>>
# Color Paint

Paint is gestural. Throw a ball; the surface accepts the splash.

Spawn a paintable sphere.

```gdscript
class_name PaintableSphere extends MeshInstance3D

var paint_image: Image

func _ready() -> void:
    paint_image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
    paint_image.fill(Color.WHITE)
    refresh_material()

func refresh_material() -> void:
    var texture := ImageTexture.create_from_image(paint_image)
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = texture
    material_override = mat
```

The sphere carries an editable image. Refreshing the material pushes the image back to the GPU.

Apply a paint splash.

```gdscript
func splash(uv: Vector2, color: Color, radius: float = 10.0) -> void:
    var centre: Vector2i = Vector2i(uv * Vector2(paint_image.get_size()))
    for dy in range(-int(radius), int(radius) + 1):
        for dx in range(-int(radius), int(radius) + 1):
            var d: float = Vector2(dx, dy).length()
            if d > radius: continue
            var alpha: float = 1.0 - d / radius
            var p := centre + Vector2i(dx, dy)
            if p.x < 0 or p.x >= paint_image.get_width(): continue
            if p.y < 0 or p.y >= paint_image.get_height(): continue
            var existing := paint_image.get_pixel(p.x, p.y)
            var blended := existing.lerp(color, alpha)
            paint_image.set_pixel(p.x, p.y, blended)
    refresh_material()
```

Soft-edge brush. Each pixel within the radius gets a weighted blend with the new colour.

Convert a ball impact to a UV coordinate.

```gdscript
func impact_to_uv(impact_world: Vector3) -> Vector2:
    var local: Vector3 = to_local(impact_world)
    var u: float = 0.5 + atan2(local.z, local.x) / TAU
    var v: float = 0.5 - asin(local.y / local.length()) / PI
    return Vector2(u, v)
```

Spherical coordinates for a sphere's UV. Works for any point on the surface.

Detect ball collision with sphere.

```gdscript
func _on_area_body_entered(body: RigidBody3D) -> void:
    if body.is_in_group("paint_ball"):
        var impact_point: Vector3 = body.global_position
        var uv := impact_to_uv(impact_point)
        splash(uv, body.paint_color)
```

Contact triggers the splash. The ball's colour determines the splash colour.

Build an Albers wall.

```gdscript
func build_albers_square(inner: Color, outer: Color, centre: Vector3) -> Node3D:
    var outer_quad := build_quad(centre, Vector2(1.5, 1.5), outer)
    var inner_quad := build_quad(centre + Vector3.FORWARD * 0.01, Vector2(0.75, 0.75), inner)
    var group := Node3D.new()
    group.add_child(outer_quad); group.add_child(inner_quad)
    return group
```

Josef Albers's nested squares. The inner colour looks different depending on the outer.

Compare two colours in context.

```gdscript
func spawn_comparison(left: Color, right: Color, shared_inner: Color) -> void:
    var left_square := build_albers_square(shared_inner, left, Vector3(-2, 1, 0))
    var right_square := build_albers_square(shared_inner, right, Vector3(2, 1, 0))
    add_child(left_square); add_child(right_square)
```

Same inner colour, different surroundings. The inner colour reads differently in each context.

Reset the painted surface.

```gdscript
func clear_paint() -> void:
    paint_image.fill(Color.WHITE)
    refresh_material()
```

Return to a blank canvas. Subsequent splashes start fresh.

You can now build a paintable sphere, splash colour at any UV position, detect ball impacts, and set up Albers-style comparisons. Color_Walls extends into environmental colour.

<<<MAP: Color_Walls>>>
# Color Walls

The corridor becomes a gradient. Surface is continuous flow.

Generate a gradient texture.

```gdscript
func gradient_texture(width: int, height: int, start: Color, end: Color) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    for x in width:
        var t: float = float(x) / (width - 1)
        var color := start.lerp(end, t)
        for y in height:
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)
```

Linear interpolation between start and end. The result is a horizontal stripe of smooth colour.

Apply to a wall.

```gdscript
func apply_gradient_wall(wall: MeshInstance3D, texture: ImageTexture) -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = texture
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
    wall.material_override = mat
```

Linear filtering gives smooth transitions. The wall reads as continuous colour rather than as a sequence of pixels.

Build a multi-stop gradient.

```gdscript
func multi_stop_gradient(stops: Array, width: int, height: int) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    for x in width:
        var t: float = float(x) / (width - 1)
        var color: Color = sample_stops(stops, t)
        for y in height:
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)

func sample_stops(stops: Array, t: float) -> Color:
    for i in range(stops.size() - 1):
        if t <= stops[i + 1].position:
            var segment_t: float = (t - stops[i].position) / (stops[i + 1].position - stops[i].position)
            return stops[i].color.lerp(stops[i + 1].color, segment_t)
    return stops[-1].color
```

Each stop has a position (0..1) and a colour. The sampler finds the correct segment and interpolates within it.

Build a corridor of gradients.

```gdscript
func spawn_corridor() -> void:
    for i in 8:
        var wall := MeshInstance3D.new()
        wall.mesh = BoxMesh.new()
        wall.scale = Vector3(5, 3, 0.1)
        wall.position = Vector3(0, 1.5, -i * 3)
        var start_hue: float = float(i) / 8
        var end_hue: float = float(i + 1) / 8
        var tex := gradient_texture(512, 128, Color.from_hsv(start_hue, 0.9, 0.9), Color.from_hsv(end_hue, 0.9, 0.9))
        apply_gradient_wall(wall, tex)
        add_child(wall)
```

Each wall is one segment of the full hue cycle. Walking the corridor walks the spectrum.

Map colour to a mood.

```gdscript
func mood_for_color(color: Color) -> String:
    var hue: float = color.h
    if hue < 0.1 or hue > 0.9: return "alert"
    elif hue < 0.3: return "warm"
    elif hue < 0.5: return "calm"
    elif hue < 0.7: return "fresh"
    else: return "cool"
```

Heuristic mapping. The colour's dominant hue range suggests a mood label.

Animate the gradient through time.

```gdscript
func _process(delta: float) -> void:
    gradient_offset = fmod(gradient_offset + delta * 0.1, 1.0)
    for wall in gradient_walls:
        update_gradient_offset(wall, gradient_offset)
```

The full gradient scrolls along the wall. The corridor appears to flow.

You can now build a gradient texture, multi-stop gradients, a gradient corridor, and animate the flow. Color_Flashlight extends colour into the interaction between light and surface.

<<<MAP: Color_Flashlight>>>
# Color Flashlight

Colour is not property but event. Light hits surface; colour happens.

Spawn a flashlight.

```gdscript
class_name Flashlight extends Node3D

@export var light_color: Color = Color(1.0, 0.95, 0.8)
@export var light_intensity: float = 5.0

var light: SpotLight3D

func _ready() -> void:
    light = SpotLight3D.new()
    light.light_color = light_color
    light.light_energy = light_intensity
    light.spot_range = 8.0
    light.spot_angle = 30.0
    add_child(light)
```

SpotLight3D is Godot's cone-shaped light. Colour, intensity, range, and angle are exposed.

Toggle the flashlight.

```gdscript
var is_on: bool = true

func toggle() -> void:
    is_on = not is_on
    light.visible = is_on
```

When off, the scene goes dark. Objects lose their visible colour.

Change the light's hue.

```gdscript
func set_light_hue(hue: float) -> void:
    light_color = Color.from_hsv(hue, 1.0, 1.0)
    light.light_color = light_color
```

Rotate the flashlight's colour through the spectrum. Surfaces respond differently to each hue.

Observe reflection.

```gdscript
# A red object's material:
var red_mat := StandardMaterial3D.new()
red_mat.albedo_color = Color(1.0, 0.0, 0.0)
red_mat.roughness = 0.5
```

Under white light, the red wall looks red. Under blue light, it looks dark — the red pigment absorbs blue.

Use a per-instance material for MultiMesh.

```gdscript
class_name ColoredMultiMesh extends MultiMeshInstance3D

func _ready() -> void:
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.use_colors = true
    multimesh.instance_count = 64

func set_instance_color(i: int, color: Color) -> void:
    multimesh.set_instance_color(i, color)
```

Each instance carries its own colour. The GPU renders them all in one draw call.

Integrate NextCube's colour code.

```gdscript
func apply_next_cube_palette(cube: Node3D, palette_index: int) -> void:
    var palette := NEXT_CUBE_PALETTE
    cube.set_cube_color(palette[palette_index])
```

NEXT_CUBE_PALETTE is a constant array of colours. The index selects one; the cube's method applies it to all sub-meshes.

Toggle fluorescence on a material.

```gdscript
func make_fluorescent(mesh: MeshInstance3D, emission_color: Color, energy: float = 1.5) -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color.WHITE
    mat.emission_enabled = true
    mat.emission = emission_color
    mat.emission_energy_multiplier = energy
    mesh.material_override = mat
```

Emissive materials appear to glow. Fluorescent paint under UV is the physical analogue.

Trigger a completion cue.

```gdscript
func on_sequence_complete() -> void:
    var save := get_tree().get_first_node_in_group("save_manager")
    save.mark_milestone("color_complete")
    unlock_next_sequences(["forces", "array_tutorial", "wavefunctions"])
```

Completing this map is the gate that opens Forces, Array Tutorial, and Wavefunctions. The save manager records the milestone.

You can now build a flashlight, toggle it, change its hue, render MultiMesh instances with per-instance colour, and make materials fluorescent. Chamber_Color extends colour into a chamber encounter.

<<<MAP: Chamber_Color>>>
# Chamber Color

Four hues, four creature responses. The catalyst speaks.

Build the chromatic catalyst.

```gdscript
class_name ChromaticCatalyst extends Node3D

@export var current_hue: Color = Color.RED

func cycle_hue() -> void:
    const HUE_CYCLE := [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
    var i: int = HUE_CYCLE.find(current_hue)
    current_hue = HUE_CYCLE[(i + 1) % HUE_CYCLE.size()]
```

Four hues cycle. Each press of a dedicated button advances to the next.

Fire a hue projectile.

```gdscript
func fire(direction: Vector3) -> void:
    var projectile := HUE_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 10.0
    projectile.hue = current_hue
    get_tree().root.add_child(projectile)
```

The projectile carries the current hue as metadata. On impact, the hue determines the response.

Build the kaleidocycle creature.

```gdscript
class_name KaleidocycleEnemy extends CharacterBody3D

enum Face { FIRE, ICE, SPIKE, SHIELD }
const FACE_HUES := {
    Face.FIRE: Color.RED, Face.ICE: Color.BLUE,
    Face.SPIKE: Color.GREEN, Face.SHIELD: Color.YELLOW,
}

var current_face: int = Face.FIRE
@export var cycle_interval: float = 2.0

var time_since_cycle: float = 0.0

func _process(delta: float) -> void:
    time_since_cycle += delta
    if time_since_cycle >= cycle_interval:
        time_since_cycle = 0.0
        current_face = (current_face + 1) % 4
        update_visual()
```

Four faces cycle in order. Each face is associated with one hue.

Match a hue to the current face.

```gdscript
func hue_match(incoming: Color) -> float:
    var expected := FACE_HUES[current_face]
    var hue_diff: float = abs(incoming.h - expected.h)
    if hue_diff > 0.5: hue_diff = 1.0 - hue_diff
    return 1.0 - hue_diff * 2.0
```

Compare hues on the circle. Score is 1.0 for exact match, 0.0 for opposite.

Respond to a hit.

```gdscript
func on_projectile_hit(hue: Color) -> void:
    var match_strength: float = hue_match(hue)
    if match_strength > 0.8:
        on_face_triggered()
    else:
        on_hue_mismatch()

func on_face_triggered() -> void:
    # Brief flash; possibly state transition
    pass

func on_hue_mismatch() -> void:
    # Reflect the projectile
    pass
```

High match triggers the face; low match is a mismatch. Different creatures interpret these events differently.

Log hits on the science screen.

```gdscript
func log_hit(hue: Color, face: int, success: bool) -> void:
    var screen = get_tree().get_first_node_in_group("science_screen")
    screen.log_event({
        "hue_angle": hue.h * 360.0,
        "face_name": ["fire", "ice", "spike", "shield"][face],
        "success": success,
        "time": Time.get_ticks_msec() / 1000.0,
    })
```

Each hit becomes a data point. Colour angle on one axis, face on the other, success as a colour.

Add a miura observer.

```gdscript
func spawn_miura_witness() -> void:
    var miura := preload("res://commons/transformation/miura_crawler.tscn").instantiate()
    miura.position = Vector3(3, 0, -3)
    miura.set_friendly_posture(true)
    add_child(miura)
```

The miura befriended in the transformation sequence appears as a witness. It confirms the chamber's non-hostile mode.

Detect befriending.

```gdscript
var sustained_match_time: float = 0.0

func _process(delta: float) -> void:
    super(delta)
    if recent_match_strength > 0.9:
        sustained_match_time += delta
    else:
        sustained_match_time = 0.0
    if sustained_match_time > 4.0:
        befriend()
```

Four seconds of sustained hue matching. The kaleidocycle settles, the creature is befriended, and the hue catalyst is added to your kit.

You can now build the chromatic catalyst, fire hue-tagged projectiles, evaluate the match between a hue and a creature face, log hits as scatter data, and befriend the kaleidocycle through sustained matching. The Color sequence closes and hands you forward.
