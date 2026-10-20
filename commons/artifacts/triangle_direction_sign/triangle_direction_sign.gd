extends Node3D
## Floor-origin sign, front +Z. The existing pink symbol turns on a round plate;
## the post stays upright. One scene keeps editor moves and copies together.
signal direction_changed(direction: int)
const Symbol = preload("res://commons/primitives/pink_triangle/pink_triangle.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")
const Stock = preload("res://commons/artifacts/construction_triangle_brace/construction_triangle_brace.gd")
@export_enum("Up", "Right", "Down", "Left") var direction: int = 0
var face: Node3D
var turn_button: Node3D
var caption: Label3D

func _ready() -> void:
	var metal := Stock.material(Color("a2a6af"), 0.75)
	var dark := Stock.material(Color("25262b"), 0.2)
	var base := StaticBody3D.new()
	base.name = "Base";base.collision_layer = 1;base.collision_mask = 0
	add_child(base)
	Stock.box(base, Vector3(0, .045, -.06), Vector3(.48, .09, .46), dark)
	var base_shape := BoxShape3D.new();base_shape.size = Vector3(.48, .09, .46)
	add_collision(base, base_shape, Vector3(0, .045, -.06))
	var pole := StaticBody3D.new()
	pole.name = "Post";pole.position = Vector3(0, 1.15, -.06)
	pole.collision_layer = 1;pole.collision_mask = 0;add_child(pole)
	disc(pole, .03, 2.2, metal)
	var pole_shape := CylinderShape3D.new();pole_shape.radius = .03;pole_shape.height = 2.2
	add_collision(pole, pole_shape)
	var rim := StaticBody3D.new()
	rim.name = "RoundPlate";rim.position = Vector3(0, 1.85, -.015)
	rim.rotation.x = PI / 2;rim.collision_layer = 1;rim.collision_mask = 0
	add_child(rim);disc(rim, .518, .05, metal)
	var plate_shape := CylinderShape3D.new();plate_shape.radius = .518;plate_shape.height = .05
	add_collision(rim, plate_shape)
	face = Symbol.instantiate()
	face.name = "Symbol";face.position.y = 1.85
	face.round_field = true;face.field_size = 1.0;face.triangle_scale = .76
	face.pink_emission_energy = .35
	add_child(face)
	# Printed colour must stay readable at grazing angles, without reflected sky.
	# Limit the override to this sign; the historical standalone symbol is unchanged.
	for surface_name in ["Field", "PinkTriangle"]:
		var surface := face.get_node(surface_name) as MeshInstance3D
		var ink := (surface.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.metallic = 0.0; ink.metallic_specular = 0.0; ink.roughness = 1.0
		ink.emission_enabled = false
		surface.material_override = ink
	face.get_node("PinkTriangle").position.z = .007
	# One normal hand/ray push button; no new input mapping is required.
	Stock.box(self, Vector3(0, 1.12, .005), Vector3(.15, .24, .06), dark)
	turn_button = ButtonScene.instantiate();turn_button.name = "TurnButton"
	turn_button.position = Vector3(0, 1.14, .04)
	turn_button.rotation.x = PI / 2
	turn_button.released_color = face.pink
	turn_button.pressed.connect(turn)
	add_child(turn_button)
	caption = Label3D.new();caption.name = "DirectionLabel"
	caption.position = Vector3(0, 1.04, .04);caption.font_size = 32
	caption.pixel_size = .00065;caption.outline_size = 0
	add_child(caption)
	set_direction(int(get_meta("config_direction", direction)))

func apply_grid_config(config: Dictionary) -> void:
	if config.has("direction"):
		set_meta("config_direction", int(config.direction))
		if is_node_ready(): set_direction(int(config.direction))

func set_direction(value: int) -> void:
	direction = posmod(value, 4)
	face.get_node("PinkTriangle").rotation.z = -direction * PI / 2
	caption.text = "TURN / " + ["UP", "RIGHT", "DOWN", "LEFT"][direction]
	direction_changed.emit(direction)

func turn() -> void:
	set_direction(direction + 1)

func disc(parent: Node3D, radius: float, depth: float, mat: Material) -> void:
	var node := MeshInstance3D.new();var mesh := CylinderMesh.new()
	mesh.top_radius = radius;mesh.bottom_radius = radius;mesh.height = depth
	mesh.radial_segments = 64
	node.mesh = mesh;node.material_override = mat;parent.add_child(node)

func add_collision(parent: Node3D, shape: Shape3D, at := Vector3.ZERO) -> void:
	var collision := CollisionShape3D.new();collision.shape = shape
	collision.position = at;parent.add_child(collision)
