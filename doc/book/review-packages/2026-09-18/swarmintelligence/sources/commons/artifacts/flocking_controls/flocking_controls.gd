extends Node3D
class_name FlockingControls

## Boid flocking with exposed parameter sliders — separation, alignment, cohesion,
## speed, and perception radius. Open-air with wrap-around boundaries.
## Highlights one boid and draws its force vectors so learners can see what drives
## each agent in the swarm.

# --- Configuration ---

@export var boid_count: int = 30
@export var bounds: Vector3 = Vector3(0.8, 0.6, 0.8)

@export_group("Flocking")
@export var separation_weight: float = 1.5:
	set(value):
		separation_weight = clampf(value, 0.0, 5.0)
		_sync_slider(_sep_slider, value / 5.0)
		_update_info()

@export var alignment_weight: float = 1.0:
	set(value):
		alignment_weight = clampf(value, 0.0, 5.0)
		_sync_slider(_align_slider, value / 5.0)
		_update_info()

@export var cohesion_weight: float = 1.5:
	set(value):
		cohesion_weight = clampf(value, 0.0, 5.0)
		_sync_slider(_coh_slider, value / 5.0)
		_update_info()

@export var max_speed: float = 0.5:
	set(value):
		max_speed = clampf(value, 0.1, 1.5)
		_sync_slider(_speed_slider, (value - 0.1) / 1.4)
		_update_info()

@export var perception_radius: float = 0.2:
	set(value):
		perception_radius = clampf(value, 0.05, 0.5)
		_sync_slider(_radius_slider, (value - 0.05) / 0.45)
		_update_info()

# --- Colors ---

var _palette: Array[Color] = [
	Color(1.0, 0.35, 0.3),   # Red-orange
	Color(0.3, 1.0, 0.45),   # Green
	Color(0.35, 0.55, 1.0),  # Blue
	Color(1.0, 0.85, 0.2),   # Yellow
	Color(1.0, 0.4, 0.8),    # Pink
	Color(0.4, 1.0, 1.0),    # Cyan
	Color(0.8, 0.5, 1.0),    # Lavender
	Color(1.0, 0.6, 0.25),   # Orange
]
var color_sep: Color = Color(1.0, 0.3, 0.3)       # Red — separation
var color_align: Color = Color(0.3, 0.6, 1.0)     # Blue — alignment
var color_coh: Color = Color(0.3, 1.0, 0.4)       # Green — cohesion
var color_highlight: Color = Color(1.0, 1.0, 0.4)  # Yellow — highlighted boid

# --- Boid data ---

class BoidData:
	var position: Vector3
	var velocity: Vector3
	# Cached forces for the highlighted boid
	var f_sep: Vector3
	var f_align: Vector3
	var f_coh: Vector3

	func _init(pos: Vector3, vel: Vector3):
		position = pos
		velocity = vel
		f_sep = Vector3.ZERO
		f_align = Vector3.ZERO
		f_coh = Vector3.ZERO

var _boids: Array = []
var _highlighted: int = 0  # Index of the boid we show forces on

# --- Nodes ---

var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _highlight_mesh: MeshInstance3D
var _force_mesh: MeshInstance3D  # ImmediateMesh for force arrows
var _bounds_mesh: MeshInstance3D
var _title_label: Label3D
var _info_label: Label3D
var _control_panel: Node3D

# Sliders
var _sep_slider: Node
var _align_slider: Node
var _coh_slider: Node
var _speed_slider: Node
var _radius_slider: Node

# Signal tracking for cleanup
var _signal_connections: Array = []


func _ready() -> void:
	_create_bounds_wireframe()
	_create_multimesh()
	_create_highlight_ring()
	_create_force_mesh()
	_create_labels()
	_create_vr_controls()
	_spawn_boids()


# ------------------------------------------------------------------
# Bounds wireframe (open-air feel, just edges)
# ------------------------------------------------------------------

func _create_bounds_wireframe() -> void:
	_bounds_mesh = MeshInstance3D.new()
	_bounds_mesh.name = "BoundsWireframe"
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var hx = bounds.x / 2.0
	var hy = bounds.y / 2.0
	var hz = bounds.z / 2.0

	# 12 edges of the box
	var corners: Array[Vector3] = [
		Vector3(-hx, -hy, -hz), Vector3( hx, -hy, -hz),
		Vector3( hx, -hy,  hz), Vector3(-hx, -hy,  hz),
		Vector3(-hx,  hy, -hz), Vector3( hx,  hy, -hz),
		Vector3( hx,  hy,  hz), Vector3(-hx,  hy,  hz),
	]
	var edges: Array[int] = [
		0,1, 1,2, 2,3, 3,0,  # bottom
		4,5, 5,6, 6,7, 7,4,  # top
		0,4, 1,5, 2,6, 3,7,  # verticals
	]

	var edge_color = Color(0.35, 0.4, 0.5, 0.35)
	for idx in range(0, edges.size(), 2):
		im.surface_set_color(edge_color)
		im.surface_add_vertex(corners[edges[idx]])
		im.surface_set_color(edge_color)
		im.surface_add_vertex(corners[edges[idx + 1]])

	im.surface_end()
	_bounds_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bounds_mesh.material_override = mat
	add_child(_bounds_mesh)


# ------------------------------------------------------------------
# MultiMesh for boids
# ------------------------------------------------------------------

func _create_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = boid_count

	# Elongated wedge-like shape (box stretched along Z)
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.008, 0.006, 0.022)
	_multimesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "BoidMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)


# ------------------------------------------------------------------
# Highlight ring around selected boid
# ------------------------------------------------------------------

func _create_highlight_ring() -> void:
	_highlight_mesh = MeshInstance3D.new()
	_highlight_mesh.name = "HighlightRing"
	var torus = TorusMesh.new()
	torus.inner_radius = 0.02
	torus.outer_radius = 0.028
	torus.rings = 12
	torus.ring_segments = 16
	_highlight_mesh.mesh = torus

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color_highlight, 0.6)
	mat.emission_enabled = true
	mat.emission = color_highlight
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_mesh.material_override = mat
	add_child(_highlight_mesh)


# ------------------------------------------------------------------
# Force vector arrows (ImmediateMesh rebuilt each frame)
# ------------------------------------------------------------------

func _create_force_mesh() -> void:
	_force_mesh = MeshInstance3D.new()
	_force_mesh.name = "ForceVectors"
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_force_mesh.material_override = mat
	add_child(_force_mesh)


func _update_force_arrows() -> void:
	if _highlighted < 0 or _highlighted >= _boids.size():
		return
	var boid: BoidData = _boids[_highlighted]
	var origin = boid.position

	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var arrow_scale = 0.3  # Visual amplification
	_draw_arrow(im, origin, boid.f_sep * arrow_scale, color_sep)
	_draw_arrow(im, origin, boid.f_align * arrow_scale, color_align)
	_draw_arrow(im, origin, boid.f_coh * arrow_scale, color_coh)

	im.surface_end()
	_force_mesh.mesh = im


func _draw_arrow(im: ImmediateMesh, origin: Vector3, vec: Vector3, col: Color) -> void:
	if vec.length() < 0.001:
		return
	var tip = origin + vec
	# Shaft
	im.surface_set_color(col)
	im.surface_add_vertex(origin)
	im.surface_set_color(col)
	im.surface_add_vertex(tip)
	# Simple arrowhead — two short lines angled back
	var dir = vec.normalized()
	var perp = dir.cross(Vector3.UP)
	if perp.length() < 0.001:
		perp = dir.cross(Vector3.RIGHT)
	perp = perp.normalized() * vec.length() * 0.25
	var back = -dir * vec.length() * 0.25
	im.surface_set_color(col)
	im.surface_add_vertex(tip)
	im.surface_set_color(col)
	im.surface_add_vertex(tip + back + perp)
	im.surface_set_color(col)
	im.surface_add_vertex(tip)
	im.surface_set_color(col)
	im.surface_add_vertex(tip + back - perp)


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "FLOCKING CONTROLS"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, bounds.y / 2.0 + 0.06, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 14
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, bounds.y / 2.0 + 0.02, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.7, 0.75, 0.85, 0.9)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)
	_update_info()


func _update_info() -> void:
	if not _info_label:
		return
	_info_label.text = "Sep:%.1f  Align:%.1f  Coh:%.1f  Spd:%.1f  Rad:%.2f  [%d boids]" % [
		separation_weight, alignment_weight, cohesion_weight, max_speed, perception_radius, boid_count
	]


# ------------------------------------------------------------------
# VR Controls — 5 sliders + reset button
# ------------------------------------------------------------------

func _create_vr_controls() -> void:
	# Use RackTemplates for Rams-styled parameter panel
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var param_panel: Node3D = RackTpl.create_parameter_panel(
		5,
		["SEP", "ALIGN", "COH", "SPEED", "RADIUS"],
		[separation_weight / 5.0, alignment_weight / 5.0, cohesion_weight / 5.0,
		 (max_speed - 0.1) / 1.4, (perception_radius - 0.05) / 0.45]
	)
	param_panel.name = "ControlPanel"
	param_panel.position = Vector3(0, -bounds.y / 2.0 - 0.05, bounds.z / 2.0 + 0.14)
	param_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(param_panel)
	_control_panel = param_panel

	# Extract slider references for callbacks
	_sep_slider = param_panel.get_node_or_null("Param_0")
	_align_slider = param_panel.get_node_or_null("Param_1")
	_coh_slider = param_panel.get_node_or_null("Param_2")
	_speed_slider = param_panel.get_node_or_null("Param_3")
	_radius_slider = param_panel.get_node_or_null("Param_4")

	# Connect signals
	if _sep_slider and _sep_slider.has_signal("slider_moved"):
		_sep_slider.slider_moved.connect(_on_sep_slider)
		_signal_connections.append([_sep_slider, &"slider_moved", _on_sep_slider])
	if _align_slider and _align_slider.has_signal("slider_moved"):
		_align_slider.slider_moved.connect(_on_align_slider)
		_signal_connections.append([_align_slider, &"slider_moved", _on_align_slider])
	if _coh_slider and _coh_slider.has_signal("slider_moved"):
		_coh_slider.slider_moved.connect(_on_coh_slider)
		_signal_connections.append([_coh_slider, &"slider_moved", _on_coh_slider])
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_slider)
		_signal_connections.append([_speed_slider, &"slider_moved", _on_speed_slider])
	if _radius_slider and _radius_slider.has_signal("slider_moved"):
		_radius_slider.slider_moved.connect(_on_radius_slider)
		_signal_connections.append([_radius_slider, &"slider_moved", _on_radius_slider])

	# Reset button is already in the template as "ResetButton"
	var reset_btn: Node = param_panel.get_node_or_null("ResetButton")
	if reset_btn:
		var area: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if area and area.has_signal("button_pressed"):
			var cb := func(_b): _spawn_boids()
			area.button_pressed.connect(cb)
			_signal_connections.append([area, &"button_pressed", cb])

	call_deferred("_sync_all_sliders")


# --- Slider sync helpers ---

func _sync_slider(slider: Node, normalized: float) -> void:
	if slider and slider.has_method("set_normalized_value"):
		slider.set_normalized_value(clampf(normalized, 0.0, 1.0))


func _sync_all_sliders() -> void:
	_sync_slider(_sep_slider, separation_weight / 5.0)
	_sync_slider(_align_slider, alignment_weight / 5.0)
	_sync_slider(_coh_slider, cohesion_weight / 5.0)
	_sync_slider(_speed_slider, (max_speed - 0.1) / 1.4)
	_sync_slider(_radius_slider, (perception_radius - 0.05) / 0.45)


# --- Slider callbacks ---

func _on_sep_slider(_pos) -> void:
	if _sep_slider and _sep_slider.has_method("get_normalized_value"):
		separation_weight = _sep_slider.get_normalized_value() * 5.0

func _on_align_slider(_pos) -> void:
	if _align_slider and _align_slider.has_method("get_normalized_value"):
		alignment_weight = _align_slider.get_normalized_value() * 5.0

func _on_coh_slider(_pos) -> void:
	if _coh_slider and _coh_slider.has_method("get_normalized_value"):
		cohesion_weight = _coh_slider.get_normalized_value() * 5.0

func _on_speed_slider(_pos) -> void:
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		max_speed = 0.1 + _speed_slider.get_normalized_value() * 1.4

func _on_radius_slider(_pos) -> void:
	if _radius_slider and _radius_slider.has_method("get_normalized_value"):
		perception_radius = 0.05 + _radius_slider.get_normalized_value() * 0.45


# ------------------------------------------------------------------
# Boid spawning
# ------------------------------------------------------------------

func _spawn_boids() -> void:
	_boids.clear()
	var half = bounds * 0.35

	for i in range(boid_count):
		var pos = Vector3(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y),
			randf_range(-half.z, half.z)
		)
		var vel = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized() * max_speed * 0.5
		_boids.append(BoidData.new(pos, vel))

		var col = _palette[i % _palette.size()]
		col.h = fmod(col.h + randf() * 0.04 - 0.02 + 1.0, 1.0)
		col.a = 0.8
		_multimesh.set_instance_color(i, col)

	# Highlight first boid differently
	_multimesh.set_instance_color(_highlighted, Color(color_highlight, 0.95))


# ------------------------------------------------------------------
# Simulation
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	_update_boids(delta)
	_update_multimesh()
	_update_highlight()
	_update_force_arrows()


func _update_boids(delta: float) -> void:
	var hx = bounds.x / 2.0
	var hy = bounds.y / 2.0
	var hz = bounds.z / 2.0

	for i in range(_boids.size()):
		var boid: BoidData = _boids[i]
		var sep = Vector3.ZERO
		var ali = Vector3.ZERO
		var coh = Vector3.ZERO
		var neighbors = 0

		for j in range(_boids.size()):
			if i == j:
				continue
			var other: BoidData = _boids[j]
			var dist = boid.position.distance_to(other.position)

			if dist < perception_radius and dist > 0.001:
				neighbors += 1

				# Separation — inversely proportional to distance squared
				var diff = boid.position - other.position
				sep += diff / (dist * dist)

				# Alignment — average neighbor velocity
				ali += other.velocity

				# Cohesion — average neighbor position
				coh += other.position

		if neighbors > 0:
			ali /= neighbors
			ali = (ali - boid.velocity) * alignment_weight

			coh /= neighbors
			coh = (coh - boid.position) * cohesion_weight

			sep *= separation_weight

		# Store raw forces for the highlighted boid visualization
		boid.f_sep = sep
		boid.f_align = ali
		boid.f_coh = coh

		# Apply forces
		var accel = sep + ali + coh
		boid.velocity += accel * delta

		# Limit speed
		var spd = boid.velocity.length()
		if spd > max_speed:
			boid.velocity = boid.velocity.normalized() * max_speed
		elif spd < max_speed * 0.15:
			# Minimum speed so boids don't stall
			boid.velocity = boid.velocity.normalized() * max_speed * 0.15

		# Move
		boid.position += boid.velocity * delta

		# Wrap-around boundaries (open-air, no bounce)
		if boid.position.x > hx:
			boid.position.x -= bounds.x
		elif boid.position.x < -hx:
			boid.position.x += bounds.x
		if boid.position.y > hy:
			boid.position.y -= bounds.y
		elif boid.position.y < -hy:
			boid.position.y += bounds.y
		if boid.position.z > hz:
			boid.position.z -= bounds.z
		elif boid.position.z < -hz:
			boid.position.z += bounds.z


func _update_multimesh() -> void:
	for i in range(_boids.size()):
		var boid: BoidData = _boids[i]
		var t = Transform3D()
		t.origin = boid.position

		if boid.velocity.length() > 0.001:
			var forward = boid.velocity.normalized()
			var up = Vector3.UP
			if abs(forward.dot(up)) > 0.99:
				up = Vector3.FORWARD
			t = t.looking_at(boid.position + forward, up)
			t.basis = t.basis.rotated(t.basis.x, -PI / 2)

		_multimesh.set_instance_transform(i, t)


func _update_highlight() -> void:
	if _highlighted >= 0 and _highlighted < _boids.size():
		_highlight_mesh.position = _boids[_highlighted].position


# ------------------------------------------------------------------
# Grid system integration
# ------------------------------------------------------------------

func _exit_tree() -> void:
	for conn in _signal_connections:
		if is_instance_valid(conn[0]) and conn[0].is_connected(conn[1], conn[2]):
			conn[0].disconnect(conn[1], conn[2])
	_signal_connections.clear()

## Accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("separation"):
		separation_weight = float(config_data["separation"])
	if config_data.has("alignment"):
		alignment_weight = float(config_data["alignment"])
	if config_data.has("cohesion"):
		cohesion_weight = float(config_data["cohesion"])
	if config_data.has("speed"):
		max_speed = float(config_data["speed"])
	if config_data.has("perception_radius"):
		perception_radius = float(config_data["perception_radius"])
	if config_data.has("boid_count"):
		boid_count = int(config_data["boid_count"])
		_multimesh.instance_count = boid_count
		_spawn_boids()
