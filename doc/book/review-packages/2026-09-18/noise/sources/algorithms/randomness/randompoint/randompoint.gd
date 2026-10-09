extends Node3D

# @identity
# essence: initial XY coordinates are uniform draws; subsequent coordinates are continuously clipped
# desire: carry a point and discover which coordinates this frame permits
# critical_parameter: area_half_extent — the size of the possible universe this point can inhabit
# triggers: moving or dropping the point invokes bounds, not another random draw
# emerges: a visible plane is maintained by repeatedly discarding depth
# needs: grab_sphere_point [has]; opt-in stand:bounds frame [has]
# relationships: contrasts with randompoints (blue noise enforces spacing); precedes noiselayers (noise adds memory); pairs with randompoints for white vs blue comparison
# truth: white noise is the null hypothesis of space — the universe before it learned to care where things go

@export var area_half_extent: float = 0.8  # random within [-0.8, 0.8] on X and Y

var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")
var point_node: Node3D
var stand: String = "none"
var _frame: Node3D

func _ready() -> void:
	randomize()
	_spawn_random_point_xy()
	if stand == "bounds":
		_build_frame()

func _spawn_random_point_xy() -> void:
	var p := point_scene.instantiate()
	p.name = "RandomPoint"
	add_child(p)
	point_node = p
	var x := randf_range(-area_half_extent, area_half_extent)
	var y := randf_range(-area_half_extent, area_half_extent)
	p.position = Vector3(x, y, 0.0)
	_update_label(p)
	if p.has_signal("dropped"):
		p.connect("dropped", _on_point_dropped)

func _on_point_dropped(_pickable) -> void:
	var p: Node3D = _pickable
	var x = clamp(p.position.x, -area_half_extent, area_half_extent)
	var y = clamp(p.position.y, -area_half_extent, area_half_extent)
	p.position = Vector3(x, y, 0.0)
	_update_label(p)

func _update_label(p: Node3D) -> void:
	var label: Label3D = p.get_node_or_null("XYLabel")
	if label == null:
		label = Label3D.new()
		label.name = "XYLabel"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.transform.origin = Vector3(0, 0.06, 0)
		p.add_child(label)
	# Set label scale to 0.1
	label.scale = Vector3.ONE * 0.1
	if stand == "bounds":
		label.scale = Vector3.ONE
		label.font_size = 24
		label.pixel_size = 0.001
	label.text = "(%.2f, %.2f)" % [p.position.x, p.position.y]

func _process(_delta):
	if point_node == null:
		return
	var pos := point_node.position
	var clamped := Vector3(
		clamp(pos.x, -area_half_extent, area_half_extent),
		clamp(pos.y, -area_half_extent, area_half_extent),
		0.0
	)
	if clamped != pos:
		point_node.position = clamped
	_update_label(point_node)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("stand"):
		stand = "bounds" if str(config["stand"]) == "bounds" else "none"
	if config.has("size"):
		area_half_extent = clampf(float(config["size"]), 0.1, 0.8)
	if is_node_ready():
		if is_instance_valid(_frame):
			remove_child(_frame)
			_frame.queue_free()
		if stand == "bounds":
			_build_frame()


## Optional casing; the frame shows the centre's bounds, not a colliding wall.
func _build_frame() -> void:
	var kit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	_frame = Node3D.new()
	_frame.name = "BoundsFrame"
	_frame.set_meta("em_local_instrument", true)
	add_child(_frame)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.22, 0.30, 0.33)
	metal.metallic = 0.5
	var e: float = area_half_extent
	for axis in range(2):
		for side in [-1, 1]:
			var at := Vector3.ZERO
			at[axis] = side * e
			var size := Vector3(0.018, 0.018, 0.018)
			size[1 - axis] = 2.0 * e
			_frame.add_child(kit.box(at, size, metal))
	_frame.add_child(kit.box(Vector3(0, -0.95, -0.08), Vector3(0.70, 0.60, 0.40), metal))
	_frame.add_child(kit.box(Vector3(0, -0.63, 0), Vector3(1.30, 0.035, 0.42), metal))
	var plate := StandardMaterial3D.new()
	plate.albedo_color = Color(0.035, 0.07, 0.085)
	_frame.add_child(kit.box(Vector3(0, -0.80, 0.145), Vector3(1.10, 0.25, 0.02), plate))
	var text := Label3D.new()
	text.name = "BoundsReadout"
	text.text = "CARRY A POINT\nx,y: -%.1f to +%.1f m | z = 0\nRelease it. Which coordinates remain?" % [e, e]
	text.font_size = 24
	text.pixel_size = 0.0016
	text.position = Vector3(0, -0.80, 0.16)
	_frame.add_child(text)
