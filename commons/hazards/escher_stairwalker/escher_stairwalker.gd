extends HazardCreatureBase
class_name EscherStairwalker
## Art & Mathematics hazard — a minimalist figure walking an impossible
## staircase loop. Always appears to climb but stays at the same height.
## Invulnerable while on stairs; glitches out to lunge. Teaches Escher
## impossible geometry and the gap between representation and reality.

@export_group("Staircase")
@export var stair_count: int = 4
@export var stair_size: Vector3 = Vector3(0.2, 0.08, 0.2)
@export var loop_speed: float = 1.5
@export var glitch_interval: float = 4.0
@export var glitch_duration: float = 0.8
@export var lunge_speed: float = 6.0

@export_group("Appearance")
@export var stair_color: Color = Color(0.7, 0.7, 0.75)
@export var figure_color: Color = Color(0.15, 0.15, 0.2)
@export var glitch_color: Color = Color(1.0, 0.1, 0.3)
@export var emission_val: Color = Color(0.5, 0.5, 0.6)

# State
var _loop_phase: float = 0.0
var _glitch_timer: float = 0.0
var _is_glitching: bool = false
var _glitch_time: float = 0.0
var _on_stairs: bool = true
var _stair_positions: Array[Vector3] = []

# Visual
var _figure: Node3D = null
var _stairs: Array[MeshInstance3D] = []
var _figure_mat: StandardMaterial3D
var _stair_mat: StandardMaterial3D
var _glitch_mat: StandardMaterial3D
var _label: Label3D = null


func _on_ready() -> void:
	add_to_group("escher_enemy")


func _create_materials() -> void:
	_figure_mat = _make_material(figure_color)
	_stair_mat = _make_material(stair_color, emission_val * 0.2)
	_glitch_mat = _make_material(glitch_color, glitch_color)
	_glitch_mat.emission_energy_multiplier = 3.0


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	col.position.y = 0.4
	add_child(col)


func _build_mesh() -> void:
	# Build impossible staircase loop — 4 stairs arranged in a square
	# Each appears to go "up" visually but returns to start height
	var radius: float = 0.35
	_stair_positions.clear()

	for i in range(stair_count):
		var angle: float = float(i) / float(stair_count) * TAU
		var pos := Vector3(
			cos(angle) * radius,
			0.0,  # All at same height (the "impossible" part)
			sin(angle) * radius
		)
		_stair_positions.append(pos)

		var stair := BoxMesh.new()
		stair.size = stair_size
		# Visually tilt each stair slightly to suggest ascending
		var mi := _add_mesh(stair, _stair_mat, pos)
		mi.rotation.x = -0.1 * (float(i) / float(stair_count))
		_stairs.append(mi)

	# Build minimalist figure
	_figure = Node3D.new()
	_figure.name = "Figure"
	_mesh_root.add_child(_figure)

	# Torso (minimal box)
	var torso := BoxMesh.new()
	torso.size = Vector3(0.08, 0.12, 0.04)
	var t := MeshInstance3D.new()
	t.mesh = torso
	t.set_surface_override_material(0, _figure_mat)
	t.position = Vector3(0.0, 0.22, 0.0)
	_figure.add_child(t)

	# Head (small sphere)
	var head := SphereMesh.new()
	head.radius = 0.035
	head.height = 0.07
	var h := MeshInstance3D.new()
	h.mesh = head
	h.set_surface_override_material(0, _figure_mat)
	h.position = Vector3(0.0, 0.32, 0.0)
	_figure.add_child(h)

	# Legs (thin cylinders)
	var leg := CylinderMesh.new()
	leg.top_radius = 0.012
	leg.bottom_radius = 0.015
	leg.height = 0.14
	for side in [-1.0, 1.0]:
		var l := MeshInstance3D.new()
		l.mesh = leg
		l.set_surface_override_material(0, _figure_mat)
		l.position = Vector3(side * 0.025, 0.1, 0.0)
		_figure.add_child(l)

	# Label
	_label = Label3D.new()
	_label.text = "IMPOSSIBLE LOOP"
	_label.font_size = 20
	_label.pixel_size = 0.002
	_label.modulate = stair_color
	_label.position = Vector3(0.0, 0.6, 0.05)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _process_visual(delta: float) -> void:
	if _is_glitching:
		_glitch_time += delta
		# Figure moves toward player during glitch
		if _figure:
			var glitch_offset := _get_player_direction() * _glitch_time * lunge_speed * 0.3
			_figure.position = glitch_offset
			# Flicker
			_figure.visible = fmod(_glitch_time, 0.1) < 0.05

		if _glitch_time >= glitch_duration:
			_is_glitching = false
			_on_stairs = true
			if _figure:
				_figure.visible = true
		return

	# Walk the staircase loop
	_loop_phase += delta * loop_speed
	var t: float = fmod(_loop_phase, float(stair_count))
	var stair_idx: int = int(t) % stair_count
	var frac: float = t - floor(t)

	# Interpolate position between stairs
	var next_idx: int = (stair_idx + 1) % stair_count
	if stair_idx < _stair_positions.size() and next_idx < _stair_positions.size():
		var pos: Vector3 = _stair_positions[stair_idx].lerp(
			_stair_positions[next_idx], frac
		)
		pos.y += stair_size.y * 0.5 + sin(frac * PI) * 0.05  # Step-up illusion
		if _figure:
			_figure.position = pos
			# Face direction of travel
			var dir: Vector3 = (_stair_positions[next_idx] - _stair_positions[stair_idx]).normalized()
			if dir.length() > 0.01:
				_figure.look_at(_figure.global_position + dir, Vector3.UP)

	# Glitch timer
	_glitch_timer += delta
	if _glitch_timer >= glitch_interval and _state == BaseState.CHASE:
		_glitch_timer = 0.0
		_is_glitching = true
		_glitch_time = 0.0
		_on_stairs = false


func _on_damaged(amount: float) -> void:
	if _on_stairs:
		# Invulnerable while on the impossible staircase
		_health += amount  # Restore the damage
		if _label:
			_label.text = "IMPOSSIBLE!"
			_label.modulate = glitch_color
	else:
		_set_state(BaseState.STUNNED)
		if _label:
			_label.text = "REALITY GLITCH"
			_label.modulate = Color.WHITE
