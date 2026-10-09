"""Build the six complete, progressively editable Random Definition lessons."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[4]
OUT = ROOT / 'doc/book/studies/random-definition'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'steps').mkdir(exist_ok=True)

def write(name, content):
    (OUT / name).write_text(content.strip() + '\n', encoding='utf-8')

for step in range(1, 7):
    source = 'extends Node3D\n\nvar rng := RandomNumberGenerator.new()\n'
    if step > 1:
        source += 'var seed_value := 42\n'
    size = 1 if step < 3 else 4
    source += f'\nfunc _ready() -> void:\n\t$Display.build({size}, {"true" if step >= 4 else "false"})\n\treplay()\n'
    source += '\nfunc replay() -> void:\n'
    if step < 3:
        if step == 2:
            source += '\trng.seed = seed_value\n'
        source += '\tvar cube: MeshInstance3D = $Display.left[0]\n'
        source += '\tvar material: StandardMaterial3D = cube.material_override\n'
        source += '\tvar a := rng.randf()\n\tvar b := rng.randf()\n\tvar c := rng.randf()\n'
        source += '\tmaterial.albedo_color = Color(a, b, c)\n'
    else:
        if step == 3:
            source += '\trng.seed = seed_value\n\tfor cube in $Display.left:\n'
        else:
            argument = '' if step == 4 else ', false'
            second = '' if step == 4 else ', true'
            source += f'\tcolour_grid($Display.left{argument})\n\tcolour_grid($Display.right{second})\n'
            param = '' if step == 4 else ', skip_first: bool' if step == 5 else ', swap_channels: bool'
            source += f'\nfunc colour_grid(cubes: Array[MeshInstance3D]{param}) -> void:\n\trng.seed = seed_value\n'
            if step == 5:
                source += '\tif skip_first:\n\t\trng.randf()\n'
            source += '\tfor cube in cubes:\n'
        source += '\t\tvar a := rng.randf()\n\t\tvar b := rng.randf()\n\t\tvar c := rng.randf()\n'
        source += '\t\tvar colour := Color(a, b, c)\n'
        if step == 6:
            source += '\t\tif swap_channels:\n\t\t\tcolour = Color(c, b, a)\n'
        source += '\t\tvar material: StandardMaterial3D = cube.material_override\n\t\tmaterial.albedo_color = colour\n'
    name = ['01-colour', '02-seed', '03-grid', '04-pair', '05-unused-draw', '06-channel-roles'][step-1]
    write('steps/' + name + '.gd', source)
shutil.copy2(OUT / 'steps/01-colour.gd', OUT / 'study.gd')

write('project.godot', '''
config_version=5
[application]
config/name="Random Definition — a pattern that returns"
run/main_scene="res://study.tscn"
config/features=PackedStringArray("4.6", "GL Compatibility")
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
''')
write('study.tscn', '''
[gd_scene load_steps=5 format=3]
[ext_resource type="Script" path="res://study.gd" id="1"]
[ext_resource type="Script" path="res://display.gd" id="2"]
[sub_resource type="Environment" id="Environment"]
background_mode = 1
background_color = Color(0.07, 0.09, 0.11, 1)
ambient_light_source = 3
ambient_light_color = Color(0.8, 0.87, 1, 1)
ambient_light_energy = 0.6
tonemap_mode = 0
[sub_resource type="StandardMaterial3D" id="UnusedPlaceholder"]
albedo_color = Color(1, 1, 1, 1)
[node name="Study" type="Node3D"]
script = ExtResource("1")
[node name="Display" type="Node3D" parent="."]
script = ExtResource("2")
[node name="Camera3D" type="Camera3D" parent="."]
position = Vector3(0, 2.45, 7.5)
rotation = Vector3(-0.07, 0, 0)
current = true
fov = 42.0
[node name="Light" type="DirectionalLight3D" parent="."]
rotation = Vector3(-0.55, -0.55, 0)
light_energy = 1.05
shadow_enabled = true
[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment")
''')
write('display.gd', '''
extends Node3D
## Supplied display: geometry, individual materials, labels and replay input.
## It never requests a random value or changes the learner's generator.
var left: Array[MeshInstance3D] = []
var right: Array[MeshInstance3D] = []
var replay_button: Button

func _ready() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var title := Label.new()
	title.text = "A PATTERN THAT RETURNS"
	title.position = Vector2(48, 28)
	title.add_theme_font_size_override("font_size", 28)
	canvas.add_child(title)
	var hint := Label.new()
	hint.text = "Edit study.gd  /  one change at a time"
	hint.position = Vector2(48, 65)
	hint.modulate = Color(0.67, 0.75, 0.78)
	canvas.add_child(hint)
	replay_button = Button.new()
	replay_button.text = "REPLAY   [space]"
	replay_button.position = Vector2(523, 624)
	replay_button.size = Vector2(234, 48)
	replay_button.add_theme_font_size_override("font_size", 21)
	replay_button.pressed.connect(func(): get_parent().replay())
	canvas.add_child(replay_button)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		get_parent().replay()
		get_viewport().set_input_as_handled()

func build(side: int, paired: bool) -> void:
	# Construction runs once, from the learner's _ready(). Replay only colours.
	assert(left.is_empty(), "Build once in _ready; replay changes only colours.")
	left = _grid(side, -1.5 if paired else 0.0, "LEFT" if paired else "ONE COLOUR" if side == 1 else "ONE GRID")
	if paired:
		right = _grid(side, 1.5, "RIGHT")

func _grid(side: int, centre: float, caption: String) -> Array[MeshInstance3D]:
	var cubes: Array[MeshInstance3D] = []
	var board := MeshInstance3D.new()
	var backing := BoxMesh.new()
	backing.size = Vector3(2.4, 2.4, 0.08)
	board.mesh = backing
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.15, 0.17)
	board.material_override = dark
	board.position = Vector3(centre, 1.85, -0.23)
	add_child(board)
	for row in range(side):
		for col in range(side):
			var cube := MeshInstance3D.new()
			var box := BoxMesh.new()
			var edge := 1.8 / float(side)
			box.size = Vector3(edge * 0.88, edge * 0.88, 0.16)
			cube.mesh = box
			var material := StandardMaterial3D.new()
			material.albedo_color = Color.WHITE
			material.roughness = 0.8
			cube.material_override = material
			cube.position = Vector3(centre + (col - (side-1) * 0.5) * edge, 1.85 + (row - (side-1) * 0.5) * edge, 0)
			add_child(cube)
			cubes.append(cube)
	var label := Label3D.new()
	label.text = caption
	label.position = Vector3(centre, 0.42, 0)
	label.font_size = 28
	label.pixel_size = 0.003
	label.outline_size = 0
	add_child(label)
	return cubes
''')
write('README.md', '''
# Random Definition — a pattern that returns

A standalone Godot 4.6 desktop study. Day Zero's editor/run workflow is assumed. No Ada assets, plugins, XR rig, API keys or network access are needed.

Open this `project.godot`. It starts with one cube and `study.gd`, the first lesson. Follow `TUTORIAL.md`. Edit that script; the six complete versions in `steps/` are recovery points. Copy a step's contents into `study.gd` to start from that point. `study.tscn` remains the main scene throughout.

REPLAY or Space calls the script's `replay()` function. Before you add a fixed seed, it continues the generator. Later the function resets the seed before drawing. A run can repeat a colour by chance; difference is not guaranteed on every request.

`display.gd` supplies one cube, a 4 × 4 grid or a pair of grids, plus separate materials, camera framing and replay input. Arrays are ordered left to right, bottom row first, like the museum instrument. The helper draws no random numbers. The lesson owns the generator, seed, draw order and RGB assignment. The museum uses 8 × 8 grids; the study uses 4 × 4 to keep individual cells easy to follow.

Step 6 returns to step 4's matched beginning and exchanges red and blue only on the right. It does **not** retain step 5's unused draw. Those are two separate comparisons.

For verification: `godot --path . --headless --script res://verify.gd`. A rendered run additionally captures each stage. Results describe desktop software checks, not a learner or headset trial.
''')
print(OUT)
