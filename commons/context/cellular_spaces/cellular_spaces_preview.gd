extends Node3D
## F6: compare both interiors at body scale. Reusable space scenes have no player.

const Walker = preload("res://commons/context/cellular_spaces/preview_walker.gd")
const Womb = preload("res://commons/context/cellular_spaces/cellular_womb_space.tscn")
const Atrium = preload("res://commons/context/cellular_spaces/cellular_atrium_space.tscn")
var spaces: Array[Node3D] = []
var walker: CharacterBody3D
var caption: Label
var active_space: int = 0

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("151421")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8a4bd")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	for scene in [Womb, Atrium]:
		var space: Node3D = scene.instantiate()
		space.position.x = spaces.size() * 34.0
		add_child(space)
		spaces.append(space)
	walker = CharacterBody3D.new()
	walker.set_script(Walker)
	walker.name = "Walker"
	add_child(walker)
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.085, 0.88)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	hud.add_child(panel)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 19)
	panel.add_child(caption)
	enter_space(0)

func enter_space(index: int) -> void:
	active_space = index
	walker.global_position = spaces[index].get_spawn_position()
	walker.home = walker.global_position
	walker.velocity = Vector3.ZERO
	walker.rotation = Vector3.ZERO
	walker.get_node("Eyes").rotation = Vector3.ZERO
	caption.text = ("01  /  WOMB\nCurved cellular membrane" if index == 0 else "02  /  OPEN CELLS\nSmall chambers around a shared centre")
	caption.text += "\n\nWASD / arrows  Walk    Hold right mouse  Look\n1 / 2  Change space    R  Entrance    Shift  Faster"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: enter_space(0)
			KEY_2: enter_space(1)
			KEY_R: enter_space(active_space)
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
