extends Node3D
## Full-size ground for accumulating capabilities. The hall supplies the stage;
## the visitor supplies movement. No table, handles, control panels or in-world controls.
const Model := preload("res://commons/artifacts/biome_primitives/encounter_model.gd")
const DATA := "res://commons/artifacts/biome_primitives/pilot.json"
const DISPLAY_SCALE := 1.0
@export var seed: int = 7
@export_enum("Point_One", "Point_Lines", "Point_Trace", "Point_Line_Grid", "Point_Triangle_Context", "Primitives_Polythedra", "Trans_Rotation", "Trans_Scale") var stage: String = "Point_One"
@export var demo: bool = false
@export var withdraw: bool = false
## Authored capture pose only. Live visitors encounter the automatic cycle.
@export_range(-1.0, 90.0) var hinge_preview_degrees: float = -1.0
@export_range(-1.0, 1.25) var scale_preview_factor: float = -1.0
var model = Model.new()
var _surface: Node3D
var _marker: MeshInstance3D
var _ink: MeshInstance3D
var _anchor: MeshInstance3D
var _data: Dictionary
var _ui_tick: float = 0.0
var _forms: Node3D
var _built_level: int = -99
var _built_stage: int = -99
var _form_bodies: Array[Node3D] = []
var _visitor_on_ground: bool = false
var _hinge_arcs: Array[MeshInstance3D] = []

func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed"): seed = int(config.seed)
	if config.has("stage") and Model.STAGES.has(str(config.stage)): stage = str(config.stage)
	if is_inside_tree():
		model.seed = seed
		model.set_stage(Model.STAGES.find(stage))
		_refresh()

func _ready() -> void:
	_data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	model.seed = seed
	model.set_stage(maxi(0, Model.STAGES.find(stage)))
	if demo:
		for action in (_data.hinge_demo if model.stage_index >= 6 else (_data.form_demo if model.level() >= 4 else _data.demo)):
			model.move_point(Model._vec(action.p))
			model.advance(float(action.dt))
	if withdraw: model.toggle_capability()
	if demo and hinge_preview_degrees >= 0: model.hinge_angle = deg_to_rad(hinge_preview_degrees)
	if demo and scale_preview_factor >= .6: model.width_factor = scale_preview_factor
	_surface = Node3D.new()
	_surface.name = "Ground"
	add_child(_surface)
	_box(_surface, Vector3(0, -0.08, 0), Vector3(12, 0.16, 12), Color("ddd9cd"))
	var floor_body := StaticBody3D.new()
	floor_body.name = "WalkableFloor"
	floor_body.collision_layer = 1
	var shape := BoxShape3D.new()
	shape.size = Vector3(12, 0.16, 12)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = -0.08
	floor_body.add_child(collider)
	_surface.add_child(floor_body)
	_forms = Node3D.new()
	_forms.name = "Forms"
	_surface.add_child(_forms)
	_marker = _ball(_surface, 0.15, Color("11141b"))
	_marker.name = "PositionMarker"
	_anchor = _ball(_surface, 0.09, Color("ba6a35"))
	_ink = MeshInstance3D.new()
	_ink.name = "GroundMarks"
	_ink.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_surface.add_child(_ink)
	_ink.material_override = _material(Color.WHITE, true)
	_refresh()
	if demo:
		set_process(false)
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	if model.stage_index < 6: return
	model.advance_hinge(delta, _visitor_on_ground)
	_update_form_poses()

func _process(delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var ancestor: Node = camera
	var found := false
	while ancestor != null:
		if ancestor is Node3D and (ancestor.is_in_group("em_walker") or ancestor is XROrigin3D):
			var at: Vector3 = ancestor.global_position
			if ancestor is XROrigin3D:
				# Room-scale steps move the headset inside its origin. Project to ground;
				# this is a chosen footprint, not a measurement of the feet.
				at.x = camera.global_position.x
				at.z = camera.global_position.z
			observe_player(at, delta)
			found = true
			break
		ancestor = ancestor.get_parent()
	if not found:
		_visitor_on_ground = false
		model.advance(delta, false)
	_ui_tick += delta
	if _ui_tick >= 0.033:
		_ui_tick = 0
		_refresh()

## A hall or test harness can supply a stage; there is no exhibit control panel.
func set_hall(hall: String) -> void:
	if not Model.STAGES.has(hall): return
	stage = hall
	model.set_stage(Model.STAGES.find(hall))
	_refresh()

func observe_player(world_position: Vector3, delta: float) -> void:
	var local := to_local(world_position)
	var inside := absf(local.x) < 6.0 and absf(local.z) < 6.0 and absf(local.y) < 3.0
	_visitor_on_ground = inside
	if inside:
		model.move_point(Vector3(local.x, 0.05, local.z))
	model.advance(delta, inside)

func _refresh() -> void:
	if not is_instance_valid(_ink): return
	if _built_level != model.level() or _built_stage != model.stage_index: _rebuild_forms()
	_marker.visible = model.level() >= 0
	_marker.position = model.point
	_anchor.visible = model.level() >= 1
	_anchor.position = model.anchor * DISPLAY_SCALE
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# A degenerate triangle keeps the empty stage legal. Marks have world-space
	# width so they remain legible at eye height, independent of pixel line width.
	for i in range(3):
		mesh.surface_set_color(Color.TRANSPARENT)
		mesh.surface_add_vertex(Vector3.ZERO)
	if model.level() >= 3:
		for n in range(13):
			var k: float = float(n) - 6.0
			_segment(mesh, Vector3(k, 0.012, -6), Vector3(k, 0.012, 6), Color("aeb9b1"), 0.012)
			_segment(mesh, Vector3(-6, 0.012, k), Vector3(6, 0.012, k), Color("aeb9b1"), 0.012)
		var cell: Vector2i = model.address()
		var a := Vector3(float(cell.x) - 6, 0.025, float(cell.y) - 6)
		for pair in [[a, a+Vector3.RIGHT], [a+Vector3.RIGHT,a+Vector3(1,0,1)], [a+Vector3(1,0,1),a+Vector3.BACK], [a+Vector3.BACK,a]]:
			_segment(mesh, pair[0], pair[1], Color("b16d28"))
	if model.level() >= 1:
		_segment(mesh, model.anchor, model.point, Color("303b48"))
	if model.level() >= 2:
		for i in range(model.samples.size()):
			var p := Model._vec(model.samples[i].p)
			_segment(mesh, p-Vector3(0.05,0,0), p+Vector3(0.05,0,0), Color("792d28"), 0.07)
			if i > 0 and not bool(model.samples[i].start):
				_segment(mesh, Model._vec(model.samples[i-1].p), p, Color("c14b44"))
	mesh.surface_end()
	_ink.mesh = mesh

func _rebuild_forms() -> void:
	_built_level = model.level()
	_built_stage = model.stage_index
	_form_bodies.clear()
	_hinge_arcs.clear()
	# Remove both appearance and collision when a capability is withdrawn.
	for child in _forms.get_children(): child.free()
	for form in model.forms():
		var body: StaticBody3D = AnimatableBody3D.new() if model.stage_index >= 6 else StaticBody3D.new()
		if body is AnimatableBody3D: body.sync_to_physics = false
		body.name = str(form.id)
		body.position = Model._vec(form.center)
		body.rotation.y = float(form.get("yaw", 0.0))
		body.collision_layer = 1
		_forms.add_child(body)
		_form_bodies.append(body)
		if form.has("pivot"): _build_hinge(Model._vec(form.pivot))
		var size := Model._vec(form.size)
		body.set_meta("built_width", size.x)
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		_box(body, Vector3.ZERO, size, Color("ba593d"))
		# The front face has two explicit triangles. Different tones reveal the
		# diagonal; the underlying thin slab makes the collision choice tangible.
		var mesh := ArrayMesh.new()
		var z := size.z * .5 + .001
		var a := Vector3(-size.x*.5, -size.y*.5, z)
		var b := Vector3(size.x*.5, -size.y*.5, z)
		var c := Vector3(size.x*.5, size.y*.5, z)
		var d := Vector3(-size.x*.5, size.y*.5, z)
		for face in [[a,c,b], [a,d,c]]:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(face)
			arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK,Vector3.BACK,Vector3.BACK])
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var face_material := _material(Color("ca7959"))
		face_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_set_material(0, face_material)
		var other := _material(Color("c47455"))
		other.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_set_material(1, other)
		var front := MeshInstance3D.new()
		front.name = "TwoTriangles"
		front.mesh = mesh
		body.add_child(front)
	_update_form_poses()

func _update_form_poses() -> void:
	var forms: Array = model.forms()
	for i in range(mini(forms.size(), _form_bodies.size())):
		_form_bodies[i].position = Model._vec(forms[i].center)
		_form_bodies[i].rotation.y = float(forms[i].get("yaw", 0.0))
		if model.stage_index == 7:
			var size := Model._vec(forms[i].size)
			var factor := size.x / float(_form_bodies[i].get_meta("built_width"))
			for child in _form_bodies[i].get_children():
				if child is MeshInstance3D: child.scale.x = factor
				elif child is CollisionShape3D: child.shape.size = size
			# Resize the shape and visual meshes; never non-uniformly scale a body.
		if i < _hinge_arcs.size():
			var factor: float = model.active_width_factor()
			_hinge_arcs[i].scale = Vector3(factor, 1, factor)

func _build_hinge(pivot: Vector3) -> void:
	var pin := MeshInstance3D.new()
	pin.name = "FixedHinge"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = .022
	cylinder.bottom_radius = .022
	cylinder.height = float(model.form_dna.height) + .14
	cylinder.radial_segments = 12
	pin.mesh = cylinder
	pin.position = pivot + Vector3.UP * cylinder.height * .5
	pin.material_override = _material(Color("272c2b"))
	_forms.add_child(pin)
	var arc := ImmediateMesh.new()
	arc.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(24):
		var a := float(i) / 24 * PI * .5
		var b := float(i+1) / 24 * PI * .5
		var radius := float(model.form_dna.width)
		_segment(arc, Vector3(cos(a)*radius,.028,-sin(a)*radius), Vector3(cos(b)*radius,.028,-sin(b)*radius), Color("8c684a"), .018)
	arc.surface_end()
	var guide := MeshInstance3D.new()
	guide.name = "SweepOnGround"
	guide.position = pivot
	guide.mesh = arc
	guide.material_override = _material(Color.WHITE, true)
	guide.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_forms.add_child(guide)
	_hinge_arcs.append(guide)

func get_state() -> Dictionary:
	return model.snapshot()

func _segment(mesh: ImmediateMesh, a: Vector3, b: Vector3, color: Color, width: float = 0.025) -> void:
	var direction := b-a
	if direction.length_squared() < 0.000001: return
	var side := Vector3(-direction.z, 0, direction.x).normalized() * width * 0.5
	if side.length_squared() < 0.000001: side = Vector3.RIGHT * width * 0.5
	for v in [a-side, b-side, b+side, a-side, b+side, a+side]:
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(v * DISPLAY_SCALE)

func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _ball(parent: Node3D, radius: float, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2
	m.radial_segments = 16
	m.rings = 8
	n.mesh = m
	n.material_override = _material(color)
	parent.add_child(n)
	return n

func _box(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color) -> void:
	var n := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = dimensions
	n.mesh = m
	n.position = at
	n.material_override = _material(color)
	parent.add_child(n)
