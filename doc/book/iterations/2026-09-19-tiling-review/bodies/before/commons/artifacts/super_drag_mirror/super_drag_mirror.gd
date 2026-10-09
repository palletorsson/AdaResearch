extends Node3D
## A local-player wardrobe and planar looking glass. The viewport shares the
## live world: it sees the actual worn geometry, not a posed duplicate.
## One head-centred view in XR; stereo-per-eye reflections are not implemented.
const Outfits := preload("res://commons/player/super_drag_outfit.gd")
const ControlPanelScript := preload("res://commons/ui/control_panel.gd")
const MIRROR_LAYER := 1 << 19
@export var viewer_path: NodePath
@export var wardrobe_path: NodePath
@export var resolution: int = 768
@export var active_distance: float = 7.0
var viewer: Camera3D
var reflection: Camera3D
var viewport: SubViewport
var selected: int = -1
var readout: Label
var buttons: Array[Node3D] = []
var _wardrobe: Node
var _pane: MeshInstance3D
const WIDTH := 1.8
const HEIGHT := 2.7
const CENTRE := 1.4

func _ready() -> void:
	_build()
	if not viewer_path.is_empty():
		viewer = get_node_or_null(viewer_path) as Camera3D
	if not wardrobe_path.is_empty():
		_wardrobe = get_node_or_null(wardrobe_path)
	process_priority = 50

func _build() -> void:
	var frame := StandardMaterial3D.new()
	frame.albedo_color = Color("35223f")
	frame.metallic = 0.65
	frame.roughness = 0.24
	_box("Back", Vector3(0, CENTRE, -0.10), Vector3(WIDTH + 0.16, HEIGHT + 0.16, 0.16), frame)
	for side in [-1.0, 1.0]:
		_box("Frame", Vector3(side * (WIDTH * 0.5 + 0.055), CENTRE, 0), Vector3(0.11, HEIGHT + 0.22, 0.15), frame)
		for i in range(9):
			var bulb := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.035
			sphere.height = 0.07
			bulb.mesh = sphere
			bulb.position = Vector3(side * (WIDTH * 0.5 + 0.055), 0.20 + i * 0.30, 0.095)
			var glow := StandardMaterial3D.new()
			glow.albedo_color = Color("ffdfb0")
			glow.emission_enabled = true
			glow.emission = Color("ffdfb0")
			glow.emission_energy_multiplier = 1.2
			bulb.material_override = glow
			add_child(bulb)
	for y in [CENTRE - HEIGHT * 0.5 - 0.055, CENTRE + HEIGHT * 0.5 + 0.055]:
		_box("Frame", Vector3(0, y, 0), Vector3(WIDTH, 0.11, 0.15), frame)
	viewport = SubViewport.new()
	viewport.name = "ReflectionViewport"
	viewport.size = Vector2i(clampi(resolution, 256, 1024), roundi(clampi(resolution, 256, 1024) * HEIGHT / WIDTH))
	viewport.world_3d = get_world_3d()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	reflection = Camera3D.new()
	reflection.name = "ReflectionCamera"
	reflection.cull_mask = ((1 << 20) - 1) & ~MIRROR_LAYER
	reflection.keep_aspect = Camera3D.KEEP_HEIGHT
	viewport.add_child(reflection)
	reflection.current = true
	_pane = MeshInstance3D.new()
	_pane.name = "LookingGlass"
	var quad := QuadMesh.new()
	quad.size = Vector2(WIDTH, HEIGHT)
	_pane.mesh = quad
	_pane.position = Vector3(0, CENTRE, 0)
	_pane.layers = MIRROR_LAYER
	var mirror := StandardMaterial3D.new()
	mirror.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mirror.albedo_texture = viewport.get_texture()
	# A proper camera basis reverses X; reversing the sampled image restores
	# the mirror's parity. Off-axis projection keeps its edges fixed in space.
	mirror.uv1_scale = Vector3(-1, 1, 1)
	mirror.uv1_offset = Vector3(1, 0, 0)
	_pane.material_override = mirror
	add_child(_pane)
	var solid := StaticBody3D.new()
	solid.name = "MirrorBacking"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WIDTH + 0.22, HEIGHT + 0.22, 0.16)
	collision.shape = box
	collision.position = Vector3(0, CENTRE, -0.10)
	solid.add_child(collision)
	add_child(solid)
	var panel := ControlPanelScript.new()
	panel.title = "SUPER DRAG / YOUR BODY"
	panel.position = Vector3(1.62, 1.10, 0.38)
	panel.spacing = 0.29
	panel.tilt_degrees = -15
	add_child(panel)
	readout = panel.add_readout("Choose your dress")
	for spec in [["PREVIOUS", -1], ["NEXT", 1], ["WALK DRESS", 0]]:
		var button := panel.add_button(spec[0])
		buttons.append(button)
		if int(spec[1]) == 0:
			button.pressed.connect(restore_walk_dress)
		else:
			button.pressed.connect(cycle_outfit.bind(int(spec[1])))
	_box("ConsoleStand", Vector3(1.62, 0.51, 0.28), Vector3(0.10, 1.02, 0.15), frame)
	_box("ConsoleFoot", Vector3(1.62, 0.035, 0.28), Vector3(0.80, 0.07, 0.60), frame)
	for side in [-1.0, 1.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(side * 0.92, 2.1, 0.6)
		light.light_color = Color("ffe3d7")
		light.light_energy = 0.8
		light.omni_range = 4.0
		add_child(light)

func _process(_delta: float) -> void:
	if not is_instance_valid(viewer):
		viewer = get_viewport().get_camera_3d()
	if not is_instance_valid(viewer) or viewer == reflection:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	update_reflection()
	_resolve_wardrobe()
	if is_instance_valid(_wardrobe) and is_instance_valid(_wardrobe.get("costume")):
		var id := String(_wardrobe.get("costume").get("outfit_id"))
		selected = Outfits.LOOKS.find(id)
		readout.text = Outfits.TITLES[selected] if selected >= 0 else "Your walking costume"

func update_reflection() -> void:
	var local_eye := to_local(viewer.global_position)
	var active := is_visible_in_tree() and local_eye.z > 0.12 and local_eye.length() < active_distance
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if active else SubViewport.UPDATE_DISABLED
	if not active:
		return
	# Museum loaders may disable embedded cameras; this one is current only
	# inside its own SubViewport and never takes over the player's view.
	reflection.current = true
	var mirror_basis := global_basis.orthonormalized()
	var reflected_position := to_global(Vector3(local_eye.x, local_eye.y, -local_eye.z))
	reflection.global_transform = Transform3D(mirror_basis * Basis(Vector3.UP, PI), reflected_position)
	# Current placements use uniform scale; dimensions and frustum share metres.
	var unit := global_basis.y.length()
	reflection.set_frustum(HEIGHT * unit, Vector2(local_eye.x, CENTRE - local_eye.y) * unit, local_eye.z * unit, (local_eye.z + 35.0) * unit)

func _resolve_wardrobe() -> void:
	if is_instance_valid(_wardrobe):
		return
	for candidate in get_tree().get_nodes_in_group("costume_wardrobes"):
		var costume: Node = candidate.get("costume")
		if is_instance_valid(costume) and costume.get("_head") == viewer:
			_wardrobe = candidate
			return

func cycle_outfit(direction: int) -> void:
	_resolve_wardrobe()
	if not is_instance_valid(_wardrobe):
		readout.text = "Waiting for your player body"
		return
	selected = posmod(selected + direction, Outfits.LOOKS.size())
	_wardrobe.call("choose_outfit", Outfits.LOOKS[selected])

func restore_walk_dress() -> void:
	_resolve_wardrobe()
	if is_instance_valid(_wardrobe):
		_wardrobe.call("choose_outfit", "")
	selected = -1

func _box(label: String, pos: Vector3, dimensions: Vector3, mat: Material) -> void:
	var item := MeshInstance3D.new()
	item.name = label
	var box := BoxMesh.new()
	box.size = dimensions
	item.mesh = box
	item.material_override = mat
	item.position = pos
	add_child(item)
