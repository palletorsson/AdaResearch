# friction_ramp.gd
# Inclined plane with adjustable friction coefficient
# Block slides or sticks based on μ vs angle — mg·sin(θ) vs μ·mg·cos(θ)
extends Node3D

class_name FrictionRamp

# --- Configuration ---

@export var ramp_length: float = 0.5
@export var ramp_width: float = 0.2
@export var ramp_angle_deg: float = 30.0  # Slope angle in degrees
@export var friction_mu: float = 0.5:
	set(value):
		friction_mu = clampf(value, 0.0, 1.5)
		_sync_slider(_mu_slider, value / 1.5)
		_update_physics_state()

@export var block_size: Vector3 = Vector3(0.04, 0.03, 0.04)

# --- Colors ---

var color_ramp: Color = Color(0.35, 0.35, 0.4)
var color_block_static: Color = Color(0.2, 0.6, 0.9)
var color_block_sliding: Color = Color(0.9, 0.3, 0.2)
var color_gravity: Color = Color(1.0, 1.0, 0.3)      # Yellow — weight
var color_normal: Color = Color(0.3, 1.0, 0.4)        # Green — normal force
var color_friction: Color = Color(0.9, 0.5, 0.2)      # Orange — friction
var color_net: Color = Color(1.0, 0.3, 0.6)           # Pink — net force along slope

# --- Physics state ---

var _is_sliding: bool = false
var _block_pos_along_slope: float = 0.0  # 0 = top of ramp, increases downhill
var _block_velocity: float = 0.0
var _acceleration: float = 0.0
const G: float = 9.81

# --- Nodes ---

var _ramp_mesh: MeshInstance3D
var _block_mesh: MeshInstance3D
var _block_mat: StandardMaterial3D
var _force_mesh: MeshInstance3D
var _title_label: Label3D
var _info_label: Label3D
var _status_label: Label3D
var _control_panel: Node3D
var _mu_slider: Node
var _angle_slider: Node

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")


func _ready() -> void:
	_create_ramp()
	_create_block()
	_create_force_mesh()
	_create_labels()
	_create_vr_controls()
	_reset_block()
	_update_physics_state()


# ------------------------------------------------------------------
# Ramp — tilted BoxMesh
# ------------------------------------------------------------------

func _create_ramp() -> void:
	_ramp_mesh = MeshInstance3D.new()
	_ramp_mesh.name = "Ramp"
	var box = BoxMesh.new()
	box.size = Vector3(ramp_width, 0.01, ramp_length)
	_ramp_mesh.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_ramp
	mat.roughness = 0.85
	mat.metallic = 0.1
	_ramp_mesh.material_override = mat

	# Tilt around X axis so the ramp slopes downward along +Z (local)
	# Pivot at lower edge: position center of ramp elevated
	_update_ramp_transform()
	add_child(_ramp_mesh)


func _update_ramp_transform() -> void:
	var angle_rad = deg_to_rad(ramp_angle_deg)
	# Ramp center positioned so bottom edge sits near y=0
	var half_len = ramp_length / 2.0
	var cx = 0.0
	var cy = sin(angle_rad) * half_len
	var cz = cos(angle_rad) * half_len
	_ramp_mesh.position = Vector3(cx, cy, -cz)
	_ramp_mesh.rotation.x = -angle_rad


# ------------------------------------------------------------------
# Block on the ramp
# ------------------------------------------------------------------

func _create_block() -> void:
	_block_mesh = MeshInstance3D.new()
	_block_mesh.name = "Block"
	var box = BoxMesh.new()
	box.size = block_size
	_block_mesh.mesh = box

	_block_mat = StandardMaterial3D.new()
	_block_mat.albedo_color = color_block_static
	_block_mat.emission_enabled = true
	_block_mat.emission = color_block_static
	_block_mat.emission_energy_multiplier = 0.3
	_block_mesh.material_override = _block_mat
	add_child(_block_mesh)


func _reset_block() -> void:
	_block_pos_along_slope = ramp_length * 0.15  # Start near top
	_block_velocity = 0.0
	_update_block_visual()


func _update_block_visual() -> void:
	var angle_rad = deg_to_rad(ramp_angle_deg)
	# Block position along the ramp surface
	# Slope goes from top (small pos_along_slope) to bottom (large pos_along_slope)
	var dist_from_bottom = ramp_length - _block_pos_along_slope
	var bx = 0.0
	var by = sin(angle_rad) * dist_from_bottom + block_size.y / 2.0 + 0.005
	var bz = -cos(angle_rad) * dist_from_bottom
	_block_mesh.position = Vector3(bx, by, bz)
	_block_mesh.rotation.x = -angle_rad

	# Color based on sliding state
	if _is_sliding:
		_block_mat.albedo_color = color_block_sliding
		_block_mat.emission = color_block_sliding
	else:
		_block_mat.albedo_color = color_block_static
		_block_mat.emission = color_block_static


# ------------------------------------------------------------------
# Force arrows (ImmediateMesh rebuilt each frame)
# ------------------------------------------------------------------

func _create_force_mesh() -> void:
	_force_mesh = MeshInstance3D.new()
	_force_mesh.name = "ForceArrows"
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_force_mesh.material_override = mat
	add_child(_force_mesh)


func _update_force_arrows() -> void:
	var angle_rad = deg_to_rad(ramp_angle_deg)
	var origin = _block_mesh.position

	# Directions in world space
	var slope_down = Vector3(0, -sin(angle_rad), cos(angle_rad)).normalized()  # Down the slope
	var normal_up = Vector3(0, cos(angle_rad), sin(angle_rad)).normalized()    # Perpendicular to slope, outward

	var arrow_scale = 0.012  # Scale factor: force in N -> visual length

	# Forces (unit mass, so force = acceleration component * visual_mass)
	var mg = G
	var gravity_component_along = mg * sin(angle_rad)
	var gravity_component_normal = mg * cos(angle_rad)
	var friction_force = friction_mu * gravity_component_normal

	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	# Gravity (straight down)
	_draw_arrow(im, origin, Vector3.DOWN * mg * arrow_scale, color_gravity)

	# Normal force (perpendicular to slope, outward)
	_draw_arrow(im, origin, normal_up * gravity_component_normal * arrow_scale, color_normal)

	# Friction force (up the slope, opposing motion)
	var friction_dir = -slope_down  # Friction opposes sliding direction (which is down the slope)
	if _is_sliding:
		_draw_arrow(im, origin, friction_dir * friction_force * arrow_scale, color_friction)
	else:
		# Static friction matches the gravitational component exactly
		_draw_arrow(im, origin, friction_dir * gravity_component_along * arrow_scale, color_friction)

	# Net force along slope (only if sliding)
	if _is_sliding:
		var net = gravity_component_along - friction_force
		_draw_arrow(im, origin, slope_down * net * arrow_scale, color_net)

	im.surface_end()
	_force_mesh.mesh = im


func _draw_arrow(im: ImmediateMesh, origin: Vector3, vec: Vector3, col: Color) -> void:
	if vec.length() < 0.002:
		return
	var tip = origin + vec
	# Shaft
	im.surface_set_color(col)
	im.surface_add_vertex(origin)
	im.surface_set_color(col)
	im.surface_add_vertex(tip)
	# Arrowhead
	var dir = vec.normalized()
	var perp = dir.cross(Vector3.RIGHT)
	if perp.length() < 0.001:
		perp = dir.cross(Vector3.UP)
	perp = perp.normalized() * vec.length() * 0.2
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
	_title_label.text = "FRICTION RAMP"
	_title_label.font_size = 22
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, ramp_length * 0.55 + 0.08, -ramp_length * 0.3)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 13
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, ramp_length * 0.55 + 0.03, -ramp_length * 0.3)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.75, 0.78, 0.88, 0.95)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)

	_status_label = Label3D.new()
	_status_label.name = "StatusLabel"
	_status_label.font_size = 18
	_status_label.pixel_size = 0.001
	_status_label.position = Vector3(0, ramp_length * 0.55 - 0.02, -ramp_length * 0.3)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.outline_size = 3
	_status_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_status_label)


func _update_labels() -> void:
	if not _info_label:
		return
	var angle_rad = deg_to_rad(ramp_angle_deg)
	var f_gravity_along = G * sin(angle_rad)
	var f_friction_max = friction_mu * G * cos(angle_rad)

	_info_label.text = (
		"θ=%.0f°  μ=%.2f\n" % [ramp_angle_deg, friction_mu]
		+ "mg·sin(θ)=%.2f  μ·mg·cos(θ)=%.2f\n" % [f_gravity_along, f_friction_max]
		+ "a=%.2f m/s²  v=%.2f m/s" % [_acceleration, _block_velocity]
	)

	if _is_sliding:
		_status_label.text = "SLIDING"
		_status_label.modulate = Color(1.0, 0.3, 0.2)
	else:
		_status_label.text = "STATIC"
		_status_label.modulate = Color(0.3, 1.0, 0.5)


# ------------------------------------------------------------------
# Physics
# ------------------------------------------------------------------

func _update_physics_state() -> void:
	var angle_rad = deg_to_rad(ramp_angle_deg)
	# Condition: block slides if mg·sin(θ) > μ·mg·cos(θ)
	# Simplifies to: tan(θ) > μ
	_is_sliding = sin(angle_rad) > friction_mu * cos(angle_rad)

	if _is_sliding:
		_acceleration = G * (sin(angle_rad) - friction_mu * cos(angle_rad))
	else:
		_acceleration = 0.0
		_block_velocity = 0.0

	_update_block_visual()
	_update_labels()


func _physics_process(delta: float) -> void:
	if _is_sliding:
		_block_velocity += _acceleration * delta
		_block_pos_along_slope += _block_velocity * delta * 0.01  # Scale to artifact size

		# Reset when block reaches bottom or goes past
		if _block_pos_along_slope >= ramp_length * 0.85:
			_reset_block()

	_update_block_visual()
	_update_force_arrows()
	_update_labels()


# ------------------------------------------------------------------
# VR Controls — μ slider + angle slider + reset button
# ------------------------------------------------------------------

func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.04, 0.2)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.12, 0.008)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.06, 0.06, 0.08)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.008
	_control_panel.add_child(panel_back)

	# μ slider
	_mu_slider = _add_slider("μ", -0.1, _on_mu_slider)

	# Angle slider
	_angle_slider = _add_slider("ANGLE", 0.1, _on_angle_slider)

	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(0, -0.035, 0)
	reset_btn.rotation_degrees.x = -30
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")
	reset_btn.pressed.connect(func(): _reset_block(); _update_physics_state())

	call_deferred("_sync_all_sliders")


func _add_slider(label_text: String, x_pos: float, callback: Callable) -> Node:
	var slider = SLIDER_HORIZONTAL.instantiate()
	slider.name = label_text.to_upper() + "Slider"
	slider.position = Vector3(x_pos, 0.02, 0)
	slider.rotation_degrees.x = -30
	slider.scale = Vector3(0.75, 0.75, 0.75)
	var lbl = slider.get_node_or_null("Frame/LabelName")
	if lbl:
		lbl.text = label_text
	_control_panel.add_child(slider)
	slider.slider_moved.connect(callback)
	return slider


func _add_button_label(btn: Node, text: String) -> void:
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)


# --- Slider sync helpers ---

func _sync_slider(slider: Node, normalized: float) -> void:
	if slider and slider.has_method("set_normalized_value"):
		slider.set_normalized_value(clampf(normalized, 0.0, 1.0))


func _sync_all_sliders() -> void:
	_sync_slider(_mu_slider, friction_mu / 1.5)
	_sync_slider(_angle_slider, ramp_angle_deg / 60.0)


# --- Slider callbacks ---

func _on_mu_slider(_pos) -> void:
	if _mu_slider and _mu_slider.has_method("get_normalized_value"):
		friction_mu = _mu_slider.get_normalized_value() * 1.5

func _on_angle_slider(_pos) -> void:
	if _angle_slider and _angle_slider.has_method("get_normalized_value"):
		ramp_angle_deg = clampf(_angle_slider.get_normalized_value() * 60.0, 5.0, 60.0)
		_update_ramp_transform()
		_reset_block()
		_update_physics_state()


# ------------------------------------------------------------------
# Grid system integration
# ------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("friction_mu"):
		friction_mu = float(config_data["friction_mu"])
	if config_data.has("angle"):
		ramp_angle_deg = float(config_data["angle"])
		_update_ramp_transform()
	if config_data.has("block_size"):
		var s = float(config_data["block_size"])
		block_size = Vector3(s, s * 0.75, s)
	_reset_block()
	_update_physics_state()
