# ===========================================================================
# QuantumSuperposition — Gates, Bloch Sphere & Teleportation
# Interactive quantum computing visualization in VR
# Elevated features:
#   - Quantum gate operations (Hadamard, CNOT, Phase, Pauli-X)
#   - Bloch sphere with state vector and trajectory trail
#   - Entanglement and quantum teleportation protocol
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

extends Node3D

## Quantum superposition visualization with gate operations and Bloch sphere.
## Modes: GATES applies quantum gates to a 2-qubit register and shows the
## state vector bar chart; BLOCH maps single-qubit state onto a Bloch sphere
## with theta/phi controls and trail; TELEPORT animates the quantum
## teleportation protocol step by step.

# --- Configuration ---
@export var num_qubits: int = 2
@export var bloch_radius: float = 0.9
@export var gate_speed: float = 1.5
@export var step_speed: float = 1.0
@export var trail_length: int = 120

# --- Mode ---
enum Mode { GATES, BLOCH, TELEPORT }
var _mode: int = Mode.GATES

# --- Quantum state (2-qubit: 4 complex amplitudes as Vector2) ---
var _amplitudes: Array = []  # Array[Vector2] — (re, im)
var _target_amplitudes: Array = []  # For animated interpolation
var _gate_lerp: float = 1.0  # 0..1 animation progress

# --- Bloch sphere state ---
var _bloch_theta: float = 0.0  # polar angle 0..PI
var _bloch_phi: float = 0.0    # azimuthal angle 0..2PI
var _bloch_trail: Array = []   # Array[Vector3] — trail positions on sphere

# --- Teleportation protocol ---
enum TeleportStep { IDLE, PREPARE_EPR, ENCODE, BELL_MEASURE, CORRECT, DONE }
var _teleport_step: int = TeleportStep.IDLE
var _teleport_time: float = 0.0
const TELEPORT_STEP_DUR := 2.0
# Alice's qubit to teleport (theta, phi on Bloch sphere)
var _alice_theta: float = 0.6
var _alice_phi: float = 1.2
# Bob's reconstructed state
var _bob_theta: float = 0.0
var _bob_phi: float = 0.0
# Classical bits from Bell measurement
var _classical_bits: Vector2i = Vector2i.ZERO

# --- Gate history ---
var _gate_history: Array = []  # Array[String]
const MAX_HISTORY := 8

# --- Internal ---
var _time: float = 0.0

# --- ImmediateMesh rendering ---
var _bars_im: ImmediateMesh
var _bars_mi: MeshInstance3D
var _sphere_im: ImmediateMesh
var _sphere_mi: MeshInstance3D
var _vector_im: ImmediateMesh
var _vector_mi: MeshInstance3D
var _circuit_im: ImmediateMesh
var _circuit_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _info_label: Label3D
var _state_label: Label3D

# VR controls
const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")
const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
var _mode_button: Node3D
var _gate_button: Node3D  # Cycles gates in GATES mode / steps in TELEPORT
var _reset_button: Node3D
var _theta_slider: Node3D
var _phi_slider: Node3D

# Current gate to apply
enum Gate { HADAMARD, PAULI_X, PHASE, CNOT }
var _current_gate: int = Gate.HADAMARD
const GATE_NAMES := ["H", "X", "S", "CNOT"]

# Colors
const COL_ZERO := Color(0.2, 0.5, 1.0, 0.85)
const COL_ONE := Color(1.0, 0.3, 0.5, 0.85)
const COL_PHASE := Color(0.4, 1.0, 0.6, 0.85)
const COL_ENTANGLED := Color(1.0, 0.85, 0.2, 0.9)
const COL_SPHERE_WIRE := Color(0.4, 0.5, 0.7, 0.25)
const COL_STATE_VEC := Color(0.1, 1.0, 0.4, 0.95)
const COL_TRAIL := Color(0.6, 0.3, 1.0, 0.5)
const COL_ALICE := Color(0.3, 0.7, 1.0, 0.85)
const COL_BOB := Color(1.0, 0.5, 0.2, 0.85)
const COL_EPR := Color(1.0, 0.85, 0.2, 0.7)
const COL_CLASSICAL := Color(0.9, 0.9, 0.9, 0.6)
const COL_BAR_BG := Color(0.15, 0.15, 0.25, 0.4)


func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_init_state()
	_init_mode()


func _process(delta: float) -> void:
	_time += delta * step_speed
	match _mode:
		Mode.GATES:
			_animate_gate(delta)
			_draw_state_bars()
			_draw_gate_circuit()
		Mode.BLOCH:
			_update_bloch_trail()
			_draw_bloch_sphere()
			_draw_bloch_state()
		Mode.TELEPORT:
			_advance_teleport(delta)
			_draw_teleport()
	_update_labels()


# =========================================================================
# Materials
# =========================================================================

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = StandardMaterial3D.new()
	_mat_alpha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alpha.vertex_color_use_as_albedo = true
	_mat_alpha.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


# =========================================================================
# Mesh instances
# =========================================================================

func _create_mesh_instances() -> void:
	_bars_im = ImmediateMesh.new()
	_bars_mi = MeshInstance3D.new()
	_bars_mi.mesh = _bars_im
	_bars_mi.material_override = _mat_alpha
	add_child(_bars_mi)

	_sphere_im = ImmediateMesh.new()
	_sphere_mi = MeshInstance3D.new()
	_sphere_mi.mesh = _sphere_im
	_sphere_mi.material_override = _mat_alpha
	add_child(_sphere_mi)

	_vector_im = ImmediateMesh.new()
	_vector_mi = MeshInstance3D.new()
	_vector_mi.mesh = _vector_im
	_vector_mi.material_override = _mat_unshaded
	add_child(_vector_mi)

	_circuit_im = ImmediateMesh.new()
	_circuit_mi = MeshInstance3D.new()
	_circuit_mi.mesh = _circuit_im
	_circuit_mi.material_override = _mat_alpha
	add_child(_circuit_mi)


# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 28
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 2.2, 0)
	_title_label.modulate = Color.WHITE
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.font_size = 22
	_info_label.outline_size = 3
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, 1.8, 0)
	_info_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_info_label)

	_state_label = Label3D.new()
	_state_label.font_size = 20
	_state_label.outline_size = 3
	_state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_state_label.position = Vector3(0, -1.4, 0)
	_state_label.modulate = Color(0.7, 0.8, 1.0)
	add_child(_state_label)


# =========================================================================
# VR controls
# =========================================================================

func _create_vr_controls() -> void:
	# Mode cycle button
	_mode_button = BUTTON_SCENE.instantiate()
	_mode_button.position = Vector3(-1.6, -1.0, 0)
	add_child(_mode_button)
	var btn_mode = _mode_button.get_node_or_null("InteractableAreaButton")
	if btn_mode:
		btn_mode.button_pressed.connect(_cycle_mode)

	# Gate / step button
	_gate_button = BUTTON_SCENE.instantiate()
	_gate_button.position = Vector3(-0.8, -1.0, 0)
	add_child(_gate_button)
	var btn_gate = _gate_button.get_node_or_null("InteractableAreaButton")
	if btn_gate:
		btn_gate.button_pressed.connect(_on_gate_pressed)

	# Reset button
	_reset_button = BUTTON_SCENE.instantiate()
	_reset_button.position = Vector3(0.0, -1.0, 0)
	add_child(_reset_button)
	var btn_reset = _reset_button.get_node_or_null("InteractableAreaButton")
	if btn_reset:
		btn_reset.button_pressed.connect(_on_reset)

	# Theta slider (Bloch polar angle)
	_theta_slider = SLIDER_SCENE.instantiate()
	_theta_slider.position = Vector3(1.2, -0.8, 0)
	add_child(_theta_slider)
	_theta_slider.set_param_name("Theta")
	_theta_slider.set_normalized_value(0.0)
	_theta_slider.slider_moved.connect(_on_theta_changed)

	# Phi slider (Bloch azimuthal angle)
	_phi_slider = SLIDER_SCENE.instantiate()
	_phi_slider.position = Vector3(1.2, -1.2, 0)
	add_child(_phi_slider)
	_phi_slider.set_param_name("Phi")
	_phi_slider.set_normalized_value(0.0)
	_phi_slider.slider_moved.connect(_on_phi_changed)


func _cycle_mode() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()


func _on_gate_pressed() -> void:
	match _mode:
		Mode.GATES:
			_apply_gate()
		Mode.BLOCH:
			# In Bloch mode, cycle the gate type
			_current_gate = (_current_gate + 1) % 4
		Mode.TELEPORT:
			_step_teleport()


func _on_reset() -> void:
	_init_state()
	_init_mode()


func _on_theta_changed(_value: float) -> void:
	_bloch_theta = _theta_slider.get_normalized_value() * PI


func _on_phi_changed(_value: float) -> void:
	_bloch_phi = _phi_slider.get_normalized_value() * TAU


func _init_mode() -> void:
	_bars_mi.visible = (_mode == Mode.GATES)
	_sphere_mi.visible = (_mode != Mode.GATES)
	_vector_mi.visible = true
	_circuit_mi.visible = (_mode != Mode.BLOCH)

	_theta_slider.visible = (_mode == Mode.BLOCH)
	_phi_slider.visible = (_mode == Mode.BLOCH)

	match _mode:
		Mode.GATES:
			_init_state()
			_gate_history.clear()
		Mode.BLOCH:
			_bloch_theta = 0.0
			_bloch_phi = 0.0
			_bloch_trail.clear()
			_theta_slider.set_normalized_value(0.0)
			_phi_slider.set_normalized_value(0.0)
		Mode.TELEPORT:
			_teleport_step = TeleportStep.IDLE
			_teleport_time = 0.0
			_alice_theta = 0.6
			_alice_phi = 1.2
			_bob_theta = 0.0
			_bob_phi = 0.0
			_classical_bits = Vector2i.ZERO


# =========================================================================
# Quantum state
# =========================================================================

func _init_state() -> void:
	# 2-qubit register: |00⟩ = [1, 0, 0, 0]
	_amplitudes = [Vector2(1, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]
	_target_amplitudes = _amplitudes.duplicate()
	_gate_lerp = 1.0
	_current_gate = Gate.HADAMARD


func _complex_mul(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x)


func _complex_add(a: Vector2, b: Vector2) -> Vector2:
	return a + b


func _complex_scale(a: Vector2, s: float) -> Vector2:
	return a * s


# =========================================================================
# Gate operations
# =========================================================================

func _apply_gate() -> void:
	if _gate_lerp < 1.0:
		return  # Still animating previous gate

	# Save current as start, compute target
	var start := _amplitudes.duplicate()
	var result := _amplitudes.duplicate()
	var inv_sqrt2 := 1.0 / sqrt(2.0)

	match _current_gate:
		Gate.HADAMARD:
			# H on qubit 0: H⊗I
			for i in range(4):
				var partner: int = i ^ 1  # flip qubit 0
				var sign: float = -1.0 if (i & 1) else 1.0
				result[i] = _complex_scale(
					_complex_add(start[i & ~1], _complex_scale(start[i | 1], sign)),
					inv_sqrt2
				)
			_gate_history.append("H₀")

		Gate.PAULI_X:
			# X on qubit 0: swap |0⟩↔|1⟩ for qubit 0
			for i in range(4):
				var partner: int = i ^ 1
				result[i] = start[partner]
			_gate_history.append("X₀")

		Gate.PHASE:
			# S gate on qubit 0: |1⟩ → i|1⟩
			for i in range(4):
				if i & 1:
					result[i] = _complex_mul(start[i], Vector2(0, 1))
				else:
					result[i] = start[i]
			_gate_history.append("S₀")

		Gate.CNOT:
			# CNOT: control=qubit1, target=qubit0
			# |10⟩↔|11⟩
			result[0] = start[0]
			result[1] = start[1]
			result[2] = start[3]
			result[3] = start[2]
			_gate_history.append("CX")

	if _gate_history.size() > MAX_HISTORY:
		_gate_history.pop_front()

	_target_amplitudes = result
	_gate_lerp = 0.0
	# Cycle to next gate
	_current_gate = (_current_gate + 1) % 4


func _animate_gate(delta: float) -> void:
	if _gate_lerp >= 1.0:
		return
	_gate_lerp = minf(_gate_lerp + delta * gate_speed, 1.0)
	# Smooth interpolation
	var t := _gate_lerp * _gate_lerp * (3.0 - 2.0 * _gate_lerp)
	for i in range(4):
		_amplitudes[i] = _amplitudes[i].lerp(_target_amplitudes[i], t)
	# Snap when done
	if _gate_lerp >= 1.0:
		_amplitudes = _target_amplitudes.duplicate()


# =========================================================================
# Draw state bars (GATES mode)
# =========================================================================

func _draw_state_bars() -> void:
	_bars_im.clear_surfaces()
	_bars_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var bar_width := 0.35
	var max_height := 1.5
	var spacing := 0.5
	var x_start := -1.5 * spacing - 0.5 * bar_width
	var labels := ["|00⟩", "|01⟩", "|10⟩", "|11⟩"]

	for i in range(4):
		var x := x_start + i * (bar_width + spacing)
		var amp: Vector2 = _amplitudes[i]
		var prob: float = amp.length_squared()
		var phase: float = atan2(amp.y, amp.x)
		var height: float = prob * max_height

		# Background bar
		_im_quad(_bars_im, Vector3(x, 0, 0), Vector3(x + bar_width, 0, 0),
			Vector3(x + bar_width, max_height, 0), Vector3(x, max_height, 0), COL_BAR_BG)

		# Probability bar — color by phase
		var col := Color.from_hsv(fmod(phase / TAU + 1.0, 1.0), 0.7, 0.95, 0.85)
		if height > 0.001:
			_im_quad(_bars_im, Vector3(x, 0, 0), Vector3(x + bar_width, 0, 0),
				Vector3(x + bar_width, height, 0), Vector3(x, height, 0), col)

		# Phase indicator: small triangle at top of bar
		var cx := x + bar_width * 0.5
		var cy := height + 0.15
		var pr := 0.08
		var px := cx + cos(phase) * pr
		var py := cy + sin(phase) * pr
		_im_triangle(_bars_im, Vector3(cx, cy, 0.01), Vector3(px, py, 0.01),
			Vector3(cx, cy + pr * 0.5, 0.01), COL_PHASE)

	_bars_im.surface_end()


# =========================================================================
# Draw gate circuit diagram (GATES mode)
# =========================================================================

func _draw_gate_circuit() -> void:
	_circuit_im.clear_surfaces()
	_circuit_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	if _mode == Mode.GATES:
		# Draw two qubit lines
		var y0 := -0.4
		var y1 := -0.7
		var x_start := -1.5
		var x_end := 1.5
		var lw := 0.015

		_im_quad(_circuit_im, Vector3(x_start, y0 - lw, 0.02), Vector3(x_end, y0 - lw, 0.02),
			Vector3(x_end, y0 + lw, 0.02), Vector3(x_start, y0 + lw, 0.02), COL_CLASSICAL)
		_im_quad(_circuit_im, Vector3(x_start, y1 - lw, 0.02), Vector3(x_end, y1 - lw, 0.02),
			Vector3(x_end, y1 + lw, 0.02), Vector3(x_start, y1 + lw, 0.02), COL_CLASSICAL)

		# Draw gate boxes from history
		var count := mini(_gate_history.size(), MAX_HISTORY)
		for gi in range(count):
			var gx := x_start + 0.3 + gi * 0.35
			var gname: String = _gate_history[gi]
			var gy := y0  # default on qubit 0
			var box_r := 0.1

			if gname == "CX":
				# CNOT: dot on control (qubit 1), plus on target (qubit 0)
				_im_circle(_circuit_im, Vector3(gx, y1, 0.03), 0.04, COL_ENTANGLED, 8)
				_im_circle(_circuit_im, Vector3(gx, y0, 0.03), 0.08, COL_ENTANGLED, 8)
				# Vertical line connecting
				_im_quad(_circuit_im, Vector3(gx - lw, y1, 0.03), Vector3(gx + lw, y1, 0.03),
					Vector3(gx + lw, y0, 0.03), Vector3(gx - lw, y0, 0.03), COL_ENTANGLED)
			else:
				# Single-qubit gate box
				var gc := COL_ZERO if gname.begins_with("H") else (COL_ONE if gname.begins_with("X") else COL_PHASE)
				_im_quad(_circuit_im, Vector3(gx - box_r, gy - box_r, 0.03),
					Vector3(gx + box_r, gy - box_r, 0.03),
					Vector3(gx + box_r, gy + box_r, 0.03),
					Vector3(gx - box_r, gy + box_r, 0.03), gc)

	elif _mode == Mode.TELEPORT:
		_draw_teleport_circuit()

	_circuit_im.surface_end()


# =========================================================================
# Bloch sphere (BLOCH mode)
# =========================================================================

func _draw_bloch_sphere() -> void:
	_sphere_im.clear_surfaces()
	_sphere_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var r := bloch_radius
	var segs := 32

	# Wireframe circles — equator, meridian XZ, meridian YZ
	_im_circle_ring(_sphere_im, Vector3.ZERO, r, Vector3.UP, COL_SPHERE_WIRE, segs)
	_im_circle_ring(_sphere_im, Vector3.ZERO, r, Vector3.RIGHT, COL_SPHERE_WIRE, segs)
	_im_circle_ring(_sphere_im, Vector3.ZERO, r, Vector3.FORWARD, COL_SPHERE_WIRE, segs)

	# Axis indicators — small cones at +X, +Y, +Z
	var axis_len := r + 0.15
	var aw := 0.02
	# Z axis (|0⟩ top, |1⟩ bottom)
	_im_quad(_sphere_im, Vector3(-aw, -axis_len, 0), Vector3(aw, -axis_len, 0),
		Vector3(aw, axis_len, 0), Vector3(-aw, axis_len, 0), COL_SPHERE_WIRE)
	# X axis
	_im_quad(_sphere_im, Vector3(-axis_len, -aw, 0), Vector3(axis_len, -aw, 0),
		Vector3(axis_len, aw, 0), Vector3(-axis_len, aw, 0), COL_SPHERE_WIRE)
	# Y axis
	_im_quad(_sphere_im, Vector3(0, -aw, -axis_len), Vector3(0, -aw, axis_len),
		Vector3(0, aw, axis_len), Vector3(0, aw, -axis_len), COL_SPHERE_WIRE)

	# Trail
	for ti in range(_bloch_trail.size() - 1):
		var p0: Vector3 = _bloch_trail[ti]
		var p1: Vector3 = _bloch_trail[ti + 1]
		var alpha := float(ti) / maxf(_bloch_trail.size(), 1.0)
		var tc := COL_TRAIL
		tc.a = alpha * 0.6
		_im_line_3d(_sphere_im, p0, p1, 0.012, tc)

	_sphere_im.surface_end()


func _draw_bloch_state() -> void:
	_vector_im.clear_surfaces()
	_vector_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# State vector on Bloch sphere
	var sv := _bloch_to_cartesian(_bloch_theta, _bloch_phi) * bloch_radius
	_im_line_3d(_vector_im, Vector3.ZERO, sv, 0.025, COL_STATE_VEC)

	# Arrowhead
	_im_circle(_vector_im, sv, 0.05, COL_STATE_VEC, 6)

	# |0⟩ and |1⟩ pole markers
	_im_circle(_vector_im, Vector3(0, bloch_radius, 0), 0.04, COL_ZERO, 8)
	_im_circle(_vector_im, Vector3(0, -bloch_radius, 0), 0.04, COL_ONE, 8)

	# |+⟩ and |−⟩ equator markers
	_im_circle(_vector_im, Vector3(bloch_radius, 0, 0), 0.03, COL_PHASE, 6)
	_im_circle(_vector_im, Vector3(-bloch_radius, 0, 0), 0.03, COL_PHASE, 6)

	_vector_im.surface_end()


func _update_bloch_trail() -> void:
	var pos := _bloch_to_cartesian(_bloch_theta, _bloch_phi) * bloch_radius
	if _bloch_trail.is_empty() or _bloch_trail[-1].distance_to(pos) > 0.01:
		_bloch_trail.append(pos)
		if _bloch_trail.size() > trail_length:
			_bloch_trail.pop_front()


func _bloch_to_cartesian(theta: float, phi: float) -> Vector3:
	# Bloch sphere: Y is up (|0⟩), X and Z are equatorial
	return Vector3(
		sin(theta) * cos(phi),
		cos(theta),
		sin(theta) * sin(phi)
	)


# =========================================================================
# Teleportation protocol (TELEPORT mode)
# =========================================================================

func _step_teleport() -> void:
	if _teleport_step < TeleportStep.DONE:
		_teleport_step += 1
		_teleport_time = 0.0
		if _teleport_step == TeleportStep.BELL_MEASURE:
			# Random Bell measurement outcome
			_classical_bits = Vector2i(randi() % 2, randi() % 2)
		elif _teleport_step == TeleportStep.CORRECT:
			# Apply corrections: Bob reconstructs Alice's state
			_bob_theta = _alice_theta
			_bob_phi = _alice_phi
			# Classical corrections modify the state
			if _classical_bits.x == 1:
				_bob_phi += PI  # Z correction
			if _classical_bits.y == 1:
				_bob_theta = PI - _bob_theta  # X correction
	else:
		# Reset
		_teleport_step = TeleportStep.IDLE
		_teleport_time = 0.0
		_bob_theta = 0.0
		_bob_phi = 0.0


func _advance_teleport(delta: float) -> void:
	_teleport_time += delta * step_speed


func _draw_teleport() -> void:
	_sphere_im.clear_surfaces()
	_sphere_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_vector_im.clear_surfaces()
	_vector_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var alice_x := -1.2
	var bob_x := 1.2
	var sphere_r := 0.55

	# Alice's mini Bloch sphere
	_im_circle_ring_at(_sphere_im, Vector3(alice_x, 0, 0), sphere_r, Vector3.UP, COL_SPHERE_WIRE, 24)
	_im_circle_ring_at(_sphere_im, Vector3(alice_x, 0, 0), sphere_r, Vector3.RIGHT, COL_SPHERE_WIRE, 24)

	# Bob's mini Bloch sphere
	_im_circle_ring_at(_sphere_im, Vector3(bob_x, 0, 0), sphere_r, Vector3.UP, COL_SPHERE_WIRE, 24)
	_im_circle_ring_at(_sphere_im, Vector3(bob_x, 0, 0), sphere_r, Vector3.RIGHT, COL_SPHERE_WIRE, 24)

	# Alice's state vector
	if _teleport_step >= TeleportStep.IDLE:
		var asv := _bloch_to_cartesian(_alice_theta, _alice_phi) * sphere_r
		_im_line_3d(_vector_im, Vector3(alice_x, 0, 0), Vector3(alice_x, 0, 0) + asv, 0.02, COL_ALICE)
		_im_circle(_vector_im, Vector3(alice_x, 0, 0) + asv, 0.035, COL_ALICE, 6)

	# EPR pair visualization
	if _teleport_step >= TeleportStep.PREPARE_EPR:
		var wave_y := -0.8
		var anim := minf(_teleport_time / TELEPORT_STEP_DUR, 1.0) if _teleport_step == TeleportStep.PREPARE_EPR else 1.0
		var epr_width := (bob_x - alice_x) * anim
		# Wavy entanglement line
		var segs := 20
		for si in range(segs):
			var t0 := float(si) / segs
			var t1 := float(si + 1) / segs
			var x0 := alice_x + t0 * epr_width
			var x1 := alice_x + t1 * epr_width
			var y0 := wave_y + sin(t0 * TAU * 3.0 + _time * 4.0) * 0.1
			var y1 := wave_y + sin(t1 * TAU * 3.0 + _time * 4.0) * 0.1
			_im_line_3d(_vector_im, Vector3(x0, y0, 0), Vector3(x1, y1, 0), 0.015, COL_EPR)

	# Bell measurement flash
	if _teleport_step == TeleportStep.BELL_MEASURE:
		var flash := absf(sin(_teleport_time * 8.0))
		var fc := COL_ENTANGLED
		fc.a = flash * 0.6
		_im_circle(_vector_im, Vector3(alice_x, 0, 0), sphere_r * 0.5 * flash, fc, 12)

	# Classical channel (dashed line)
	if _teleport_step >= TeleportStep.BELL_MEASURE:
		var dash_y := -1.2
		var num_dashes := 8
		var anim := minf(_teleport_time / TELEPORT_STEP_DUR, 1.0) if _teleport_step == TeleportStep.BELL_MEASURE else 1.0
		for di in range(num_dashes):
			var t := float(di) / num_dashes
			if t > anim:
				break
			if di % 2 == 0:
				var dx0 := alice_x + t * (bob_x - alice_x)
				var dx1 := alice_x + (t + 0.5 / num_dashes) * (bob_x - alice_x)
				_im_line_3d(_vector_im, Vector3(dx0, dash_y, 0), Vector3(dx1, dash_y, 0), 0.01, COL_CLASSICAL)

	# Bob's reconstructed state
	if _teleport_step >= TeleportStep.CORRECT:
		var bsv := _bloch_to_cartesian(_bob_theta, _bob_phi) * sphere_r
		var bob_alpha: float = minf(_teleport_time / TELEPORT_STEP_DUR, 1.0) if _teleport_step == TeleportStep.CORRECT else 1.0
		var bc := COL_BOB
		bc.a = bob_alpha * 0.85
		_im_line_3d(_vector_im, Vector3(bob_x, 0, 0), Vector3(bob_x, 0, 0) + bsv * bob_alpha, 0.02, bc)
		_im_circle(_vector_im, Vector3(bob_x, 0, 0) + bsv * bob_alpha, 0.035, bc, 6)

	# Success glow at DONE
	if _teleport_step == TeleportStep.DONE:
		var glow := 0.5 + 0.5 * sin(_time * 3.0)
		var gc := COL_STATE_VEC
		gc.a = glow * 0.4
		_im_circle(_vector_im, Vector3(bob_x, 0, 0), sphere_r * 0.6, gc, 16)

	_sphere_im.surface_end()
	_vector_im.surface_end()


func _draw_teleport_circuit() -> void:
	# Protocol step labels drawn as part of circuit
	var steps := ["Idle", "EPR Pair", "Encode", "Bell Meas.", "Correct", "Done!"]
	# Just draw step indicator boxes
	var y := -0.3
	for si in range(steps.size()):
		var x := -1.5 + si * 0.55
		var active := (si == _teleport_step)
		var col := COL_ENTANGLED if active else COL_BAR_BG
		_im_quad(_circuit_im, Vector3(x, y - 0.08, 0.02), Vector3(x + 0.45, y - 0.08, 0.02),
			Vector3(x + 0.45, y + 0.08, 0.02), Vector3(x, y + 0.08, 0.02), col)


# =========================================================================
# Labels
# =========================================================================

func _update_labels() -> void:
	match _mode:
		Mode.GATES:
			_title_label.text = "Quantum Gates"
			var state_str := _format_state_vector()
			_info_label.text = "State: " + state_str
			var next_gate := GATE_NAMES[_current_gate]
			_state_label.text = "Next: " + next_gate + "  |  History: " + " ".join(_gate_history.slice(-4))
		Mode.BLOCH:
			_title_label.text = "Bloch Sphere"
			_info_label.text = "θ=%.2f  φ=%.2f" % [_bloch_theta, _bloch_phi]
			# Show state as ket
			var alpha := cos(_bloch_theta / 2.0)
			var beta := sin(_bloch_theta / 2.0)
			_state_label.text = "|ψ⟩ = %.2f|0⟩ + %.2f·e^(i%.1f)|1⟩" % [alpha, beta, _bloch_phi]
		Mode.TELEPORT:
			_title_label.text = "Quantum Teleportation"
			var step_names := ["Ready", "Creating EPR pair", "Encoding qubit",
				"Bell measurement", "Applying corrections", "Teleportation complete"]
			_info_label.text = step_names[_teleport_step]
			if _teleport_step >= TeleportStep.BELL_MEASURE:
				_state_label.text = "Classical bits: %d%d" % [_classical_bits.x, _classical_bits.y]
			else:
				_state_label.text = "Alice → Bob"


func _format_state_vector() -> String:
	var parts: Array[String] = []
	var basis := ["|00⟩", "|01⟩", "|10⟩", "|11⟩"]
	for i in range(4):
		var amp: Vector2 = _amplitudes[i]
		var prob := amp.length_squared()
		if prob > 0.005:
			var mag := amp.length()
			if absf(amp.y) < 0.01:
				parts.append("%.2f%s" % [amp.x, basis[i]])
			else:
				parts.append("(%.2f+%.2fi)%s" % [amp.x, amp.y, basis[i]])
	if parts.is_empty():
		return "|00⟩"
	return " + ".join(parts)


# =========================================================================
# ImmediateMesh drawing helpers
# =========================================================================

func _im_quad(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	im.surface_set_color(col)
	im.surface_set_normal(Vector3.FORWARD)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_add_vertex(c)
	im.surface_add_vertex(a)
	im.surface_add_vertex(c)
	im.surface_add_vertex(d)


func _im_triangle(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	im.surface_set_color(col)
	im.surface_set_normal(Vector3.FORWARD)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_add_vertex(c)


func _im_circle(im: ImmediateMesh, center: Vector3, radius: float, col: Color, segs: int) -> void:
	for i in range(segs):
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		im.surface_set_color(col)
		im.surface_set_normal(Vector3.FORWARD)
		im.surface_add_vertex(center)
		im.surface_add_vertex(center + Vector3(cos(a0), sin(a0), 0) * radius)
		im.surface_add_vertex(center + Vector3(cos(a1), sin(a1), 0) * radius)


func _im_line_3d(im: ImmediateMesh, from: Vector3, to: Vector3, width: float, col: Color) -> void:
	var dir := (to - from).normalized()
	# Choose a perpendicular vector
	var perp := dir.cross(Vector3.UP)
	if perp.length_squared() < 0.001:
		perp = dir.cross(Vector3.RIGHT)
	perp = perp.normalized() * width * 0.5
	im.surface_set_color(col)
	im.surface_set_normal((dir.cross(perp)).normalized())
	im.surface_add_vertex(from - perp)
	im.surface_add_vertex(to - perp)
	im.surface_add_vertex(to + perp)
	im.surface_add_vertex(from - perp)
	im.surface_add_vertex(to + perp)
	im.surface_add_vertex(from + perp)


func _im_circle_ring(im: ImmediateMesh, center: Vector3, radius: float, normal: Vector3, col: Color, segs: int) -> void:
	_im_circle_ring_at(im, center, radius, normal, col, segs)


func _im_circle_ring_at(im: ImmediateMesh, center: Vector3, radius: float, normal: Vector3, col: Color, segs: int) -> void:
	# Great circle on sphere
	var up := normal.normalized()
	var right: Vector3
	if absf(up.dot(Vector3.UP)) < 0.99:
		right = up.cross(Vector3.UP).normalized()
	else:
		right = up.cross(Vector3.RIGHT).normalized()
	var fwd := right.cross(up).normalized()
	var lw := 0.01

	for i in range(segs):
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var p0 := center + (right * cos(a0) + fwd * sin(a0)) * radius
		var p1 := center + (right * cos(a1) + fwd * sin(a1)) * radius
		_im_line_3d(im, p0, p1, lw, col)


# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("num_qubits"):
		num_qubits = clampi(int(config["num_qubits"]), 1, 4)
	if config.has("bloch_radius"):
		bloch_radius = clampf(float(config["bloch_radius"]), 0.3, 2.0)
	if config.has("gate_speed"):
		gate_speed = clampf(float(config["gate_speed"]), 0.3, 5.0)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 5.0)
	if config.has("trail_length"):
		trail_length = clampi(int(config["trail_length"]), 10, 500)
	if config.has("bloch_theta"):
		_bloch_theta = clampf(float(config["bloch_theta"]), 0.0, PI)
	if config.has("bloch_phi"):
		_bloch_phi = clampf(float(config["bloch_phi"]), 0.0, TAU)
	if config.has("alice_theta"):
		_alice_theta = clampf(float(config["alice_theta"]), 0.0, PI)
	if config.has("alice_phi"):
		_alice_phi = clampf(float(config["alice_phi"]), 0.0, TAU)
	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"GATES": _mode = Mode.GATES
			"BLOCH": _mode = Mode.BLOCH
			"TELEPORT": _mode = Mode.TELEPORT

	_init_mode()


# =========================================================================
# Cleanup
# =========================================================================

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
