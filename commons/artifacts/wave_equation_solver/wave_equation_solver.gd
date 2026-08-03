extends Node3D
class_name WaveEquationSolver

## 2D wave equation on a membrane — drum simulation with visible ripples.
## Finite difference PDE: u_tt = c²(u_xx + u_yy) with fixed boundary u=0
## and viscous damping. Starts with a Gaussian pulse that propagates and
## reflects off the clamped edges like a struck drumhead.

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `boundary`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT MAKES THIS A PHYSICAL CLAIM RATHER THAN A FORMULA.
#
# Everything this artifact exported was a dial on the same one experiment —
# membrane size, grid resolution, height scale, wave speed, damping, pulse
# amplitude and width. Not one of them changes what the solver is solving. The
# equation u_tt = c²∇²u is identical on a drumhead, on an open pond, in an
# anechoic tank and on a torus; the thing that distinguishes them is the
# BOUNDARY CONDITION, and this solver had exactly one, welded twice into the
# source: `for j in range(1, grid_res - 1)` leaves the edge at zero forever, and
# _create_frame() builds four clamped bars around it to say so. That was never
# offered as a choice.
#
#   boundary
#     fixed       u = 0 on the rim. THE SHIPPED BUILD, byte for byte — the same
#                 interior-only stencil and the same four brown clamped bars. A
#                 struck drumhead: the crest comes back INVERTED off the edge.
#     free        du/dn = 0. The rim is unheld; the edge row copies its neighbour
#                 so the membrane can rise at its own border. Reflection WITHOUT
#                 inversion — an open pipe end, a plate resting on corner posts.
#                 The frame goes with it: four corner posts, no rail.
#     absorbing   a sponge layer six cells deep tapering to 0.80 per substep, so
#                 the wave leaves and does not come back. The claim that the
#                 membrane is a window onto something larger rather than a closed
#                 room. Drawn as the matte gutter that would do it in the world.
#     periodic    opposite edges are the same edge; the stencil wraps. A wave
#                 crossing the right rim arrives at the left. No frame at all —
#                 flat coloured pairs instead, the topologist's identification
#                 marks, because there is nothing here to clamp.
#
# WHAT A STILL SEES. Two things, and they are not the same thing. The FIELD
# difference is real but time-dependent: at t = 0 all four are the identical
# Gaussian and only diverge once the pulse has crossed to the rim, so a capture
# taken early would photograph four identical drumheads. That is why the
# boundary is also built into the FURNITURE, which is static and true at every
# instant — a ring of upstanding bars, four corner posts, a wide dark gutter, or
# two colour-paired flat strips. The value is legible in the frame whether or
# not the wave has arrived yet, and once it has, the edge behaviour confirms it.
@export_enum("fixed", "free", "absorbing", "periodic") var boundary: String = "fixed"

## Allow-list. An unknown word in a map token falls back to the shipped clamped
## drumhead rather than stranding a placement with a solver it cannot run.
const BOUNDARIES: PackedStringArray = ["fixed", "free", "absorbing", "periodic"]
## Depth of the absorbing sponge, in cells, and the per-substep floor at the rim.
const SPONGE_CELLS: int = 6
const SPONGE_FLOOR: float = 0.80

# --- Configuration ---

@export var membrane_size: float = 0.8
@export var grid_res: int = 48
@export var height_scale: float = 0.15
@export var wave_speed: float = 2.0
@export var damping: float = 0.002
@export var initial_amplitude: float = 1.0
@export var initial_sigma: float = 0.08

# --- Colors ---

var color_positive: Color = Color(0.15, 0.4, 1.0)    # Blue for positive displacement
var color_negative: Color = Color(1.0, 0.2, 0.15)     # Red for negative displacement
var color_zero: Color = Color(0.06, 0.06, 0.1)        # Dark for zero

# --- State ---

var _u: PackedFloat32Array          # Current displacement
var _u_prev: PackedFloat32Array     # Previous timestep
var _time: float = 0.0
var _dx: float = 0.0
var _dt: float = 1.0 / 60.0        # Fixed physics timestep
var _courant: float = 0.0          # c*dt/dx — must stay < 1/sqrt(2) for stability
var _max_displacement: float = 0.0

# --- Nodes ---

var _surface_mesh: MeshInstance3D
var _surface_mat: StandardMaterial3D
var _frame_node: Node3D
var _title_label: Label3D
var _info_label: Label3D
var _control_panel: Node3D
var _damping_slider: Node
var _speed_slider: Node
## Built only for boundary != "fixed"; null on every shipped placement.
var _boundary_label: Label3D = null

var RackTpl = load("res://commons/audio/rack_templates/RackTemplates.gd")


func _ready() -> void:
	_read_grid_config_meta()
	_dx = membrane_size / float(grid_res - 1)
	_init_grids()
	_apply_gaussian_pulse(0.5, 0.5, initial_amplitude, initial_sigma)
	_create_frame()
	_create_surface()
	_create_labels()
	_create_vr_controls()
	_update_courant()


# --- Grid initialisation ---

func _init_grids() -> void:
	var count: int = grid_res * grid_res
	_u = PackedFloat32Array()
	_u.resize(count)
	_u_prev = PackedFloat32Array()
	_u_prev.resize(count)
	for k in range(count):
		_u[k] = 0.0
		_u_prev[k] = 0.0


func _apply_gaussian_pulse(cx: float, cy: float, amp: float, sigma: float) -> void:
	for j in range(grid_res):
		for i in range(grid_res):
			var nx: float = float(i) / float(grid_res - 1)
			var ny: float = float(j) / float(grid_res - 1)
			var dx_val: float = nx - cx
			var dy_val: float = ny - cy
			var r2: float = dx_val * dx_val + dy_val * dy_val
			var val: float = amp * exp(-r2 / (2.0 * sigma * sigma))
			var idx: int = j * grid_res + i
			_u[idx] = val
			_u_prev[idx] = val  # Zero initial velocity


# --- Wave equation integration (finite differences) ---

func _step_wave() -> void:
	# `periodic` cannot be expressed as an edge treatment applied after an
	# interior-only sweep — the wrap is in the stencil itself — so it takes its
	# own loop rather than pretending to be a special case of this one.
	if boundary == "periodic":
		_step_wave_periodic()
		return

	var c2: float = wave_speed * wave_speed
	var dt2: float = _dt * _dt
	var dx2: float = _dx * _dx
	var factor: float = c2 * dt2 / dx2
	var damp: float = 1.0 - damping

	var u_new: PackedFloat32Array = PackedFloat32Array()
	u_new.resize(grid_res * grid_res)

	# Interior points — fixed boundary means edge stays 0
	for j in range(1, grid_res - 1):
		for i in range(1, grid_res - 1):
			var idx: int = j * grid_res + i
			var laplacian: float = (
				_u[idx + 1] + _u[idx - 1]
				+ _u[idx + grid_res] + _u[idx - grid_res]
				- 4.0 * _u[idx]
			)
			u_new[idx] = damp * (2.0 * _u[idx] - _u_prev[idx] + factor * laplacian)

	# Boundary stays at zero (already initialized to 0)

	var u_old: PackedFloat32Array = _u

	if boundary == "free":
		# du/dn = 0: the rim takes its neighbour's value, so the edge is free to
		# rise. The interior sweep above already read those edge cells, which is
		# what makes the reflection non-inverting.
		u_new = _apply_free_edges(u_new)
	elif boundary == "absorbing":
		# A sponge on BOTH levels — tapering only the new one leaves the previous
		# frame's energy to be re-injected by the leapfrog and the layer barely
		# bites.
		u_new = _apply_sponge(u_new)
		u_old = _apply_sponge(u_old)

	_u_prev = u_old
	_u = u_new


## Wrapped stencil: the right rim's neighbour is the left rim. Every cell is
## interior, so there is no edge treatment at all — which is the claim.
func _step_wave_periodic() -> void:
	var c2: float = wave_speed * wave_speed
	var dt2: float = _dt * _dt
	var dx2: float = _dx * _dx
	var factor: float = c2 * dt2 / dx2
	var damp: float = 1.0 - damping

	var n: int = grid_res
	var u_new: PackedFloat32Array = PackedFloat32Array()
	u_new.resize(n * n)

	for j in range(n):
		var jp: int = (j + 1) % n
		var jm: int = (j - 1 + n) % n
		for i in range(n):
			var ip: int = (i + 1) % n
			var im: int = (i - 1 + n) % n
			var idx: int = j * n + i
			var laplacian: float = (
				_u[j * n + ip] + _u[j * n + im]
				+ _u[jp * n + i] + _u[jm * n + i]
				- 4.0 * _u[idx]
			)
			u_new[idx] = damp * (2.0 * _u[idx] - _u_prev[idx] + factor * laplacian)

	_u_prev = _u
	_u = u_new


## Returns a copy — PackedFloat32Array is a value type, so a helper that mutated
## its argument would quietly do nothing to the caller's array.
func _apply_free_edges(arr: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = grid_res
	for i in range(n):
		arr[i] = arr[n + i]
		arr[(n - 1) * n + i] = arr[(n - 2) * n + i]
	for j in range(n):
		arr[j * n + 0] = arr[j * n + 1]
		arr[j * n + n - 1] = arr[j * n + n - 2]
	return arr


func _apply_sponge(arr: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = grid_res
	for j in range(n):
		for i in range(n):
			var d: int = mini(mini(i, j), mini(n - 1 - i, n - 1 - j))
			if d >= SPONGE_CELLS:
				continue
			var t: float = float(d) / float(SPONGE_CELLS)
			var f: float = SPONGE_FLOOR + (1.0 - SPONGE_FLOOR) * t
			arr[j * n + i] = arr[j * n + i] * f
	return arr


func _update_courant() -> void:
	_courant = wave_speed * _dt / _dx


# --- Frame (clamped boundary visual) ---

## The rim is the boundary condition made furniture. `fixed` is the shipped build
## unchanged; the other three replace it with what would actually hold — or not
## hold — the membrane under that condition.
func _create_frame() -> void:
	_frame_node = Node3D.new()
	_frame_node.name = "Frame"
	add_child(_frame_node)

	var want: String = String(boundary).strip_edges().to_lower()
	if not BOUNDARIES.has(want):
		want = "fixed"
	boundary = want

	if want == "free":
		_build_frame_free()
	elif want == "absorbing":
		_build_frame_absorbing()
	elif want == "periodic":
		_build_frame_periodic()
	else:
		_build_frame_fixed()

	_build_boundary_caption()


## Byte for byte what shipped: four clamped bars around a drumhead pinned at u = 0.
func _build_frame_fixed() -> void:
	var half: float = membrane_size / 2.0
	var bar_thickness: float = 0.008
	var bar_height: float = 0.015

	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.35, 0.25, 0.18)
	frame_mat.roughness = 0.9

	# Four sides of the rectangular frame
	var sides: Array = [
		[Vector3(0, 0, -half), Vector3(membrane_size + bar_thickness * 2, bar_height, bar_thickness)],
		[Vector3(0, 0, half), Vector3(membrane_size + bar_thickness * 2, bar_height, bar_thickness)],
		[Vector3(-half, 0, 0), Vector3(bar_thickness, bar_height, membrane_size)],
		[Vector3(half, 0, 0), Vector3(bar_thickness, bar_height, membrane_size)],
	]

	for side in sides:
		var bar: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = side[1]
		bar.mesh = box
		bar.material_override = frame_mat
		bar.position = side[0]
		_frame_node.add_child(bar)


## Nothing runs along the rim, because nothing holds it. Four corner posts carry
## the sheet and every edge between them is free to move.
func _build_frame_free() -> void:
	var half: float = membrane_size / 2.0

	var post_mat: StandardMaterial3D = StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.35, 0.25, 0.18)
	post_mat.roughness = 0.9

	var corners: Array = [
		Vector3(-half, 0, -half), Vector3(half, 0, -half),
		Vector3(-half, 0, half), Vector3(half, 0, half),
	]
	for c in corners:
		var post: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.top_radius = 0.009
		cyl.bottom_radius = 0.011
		cyl.height = 0.05
		post.mesh = cyl
		post.material_override = post_mat
		post.position = c + Vector3(0, -0.01, 0)
		_frame_node.add_child(post)


## A matte gutter the depth of the sponge layer. The membrane is a window onto a
## larger sheet and the surround is where the energy goes to not come back.
func _build_frame_absorbing() -> void:
	var half: float = membrane_size / 2.0
	var band: float = _dx * float(SPONGE_CELLS)
	var outer: float = membrane_size + band * 2.0

	var foam: StandardMaterial3D = StandardMaterial3D.new()
	foam.albedo_color = Color(0.09, 0.08, 0.10)
	foam.roughness = 1.0
	foam.metallic = 0.0

	var sides: Array = [
		[Vector3(0, -0.002, -half - band * 0.5), Vector3(outer, 0.006, band)],
		[Vector3(0, -0.002, half + band * 0.5), Vector3(outer, 0.006, band)],
		[Vector3(-half - band * 0.5, -0.002, 0), Vector3(band, 0.006, membrane_size)],
		[Vector3(half + band * 0.5, -0.002, 0), Vector3(band, 0.006, membrane_size)],
	]
	for side in sides:
		var plate: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = side[1]
		plate.mesh = box
		plate.material_override = foam
		plate.position = side[0]
		_frame_node.add_child(plate)


## No rim at all. Two colour-paired strips instead — the identification marks that
## say this edge IS that edge, which is the only honest thing to draw when the
## domain has no border.
func _build_frame_periodic() -> void:
	var half: float = membrane_size / 2.0
	var strip: float = 0.02

	var mat_x: StandardMaterial3D = StandardMaterial3D.new()
	mat_x.albedo_color = Color(0.20, 0.85, 0.95)
	mat_x.emission_enabled = true
	mat_x.emission = Color(0.20, 0.85, 0.95)
	mat_x.emission_energy_multiplier = 0.9

	var mat_z: StandardMaterial3D = StandardMaterial3D.new()
	mat_z.albedo_color = Color(0.95, 0.30, 0.80)
	mat_z.emission_enabled = true
	mat_z.emission = Color(0.95, 0.30, 0.80)
	mat_z.emission_energy_multiplier = 0.9

	var sides: Array = [
		[Vector3(-half - strip * 0.5, -0.001, 0), Vector3(strip, 0.004, membrane_size), mat_x],
		[Vector3(half + strip * 0.5, -0.001, 0), Vector3(strip, 0.004, membrane_size), mat_x],
		[Vector3(0, -0.001, -half - strip * 0.5), Vector3(membrane_size, 0.004, strip), mat_z],
		[Vector3(0, -0.001, half + strip * 0.5), Vector3(membrane_size, 0.004, strip), mat_z],
	]
	for side in sides:
		var plate: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = side[1]
		plate.mesh = box
		plate.material_override = side[2]
		plate.position = side[0]
		_frame_node.add_child(plate)


## Names the condition, and only when there is a choice to name. The shipped
## reading builds no caption, so its two labels read exactly as they always did.
func _build_boundary_caption() -> void:
	if boundary == "fixed":
		return
	_boundary_label = Label3D.new()
	_boundary_label.name = "BoundaryLabel"
	_boundary_label.text = "boundary: " + boundary
	_boundary_label.font_size = 14
	_boundary_label.pixel_size = 0.001
	_boundary_label.position = Vector3(0, height_scale * initial_amplitude + 0.015, 0)
	_boundary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boundary_label.modulate = Color(0.95, 0.80, 0.55, 0.95)
	_boundary_label.outline_size = 2
	_boundary_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_frame_node.add_child(_boundary_label)


# --- Surface mesh ---

func _create_surface() -> void:
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "MembraneSurface"
	add_child(_surface_mesh)

	_surface_mat = StandardMaterial3D.new()
	_surface_mat.vertex_color_use_as_albedo = true
	_surface_mat.emission_enabled = true
	_surface_mat.emission_energy_multiplier = 0.2
	_surface_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_surface_mesh.material_override = _surface_mat

	_build_surface()


func _build_surface() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half: float = membrane_size / 2.0
	var cell: float = membrane_size / float(grid_res - 1)

	_max_displacement = 0.0

	for j in range(grid_res - 1):
		for i in range(grid_res - 1):
			var idx00: int = j * grid_res + i
			var idx10: int = j * grid_res + i + 1
			var idx01: int = (j + 1) * grid_res + i
			var idx11: int = (j + 1) * grid_res + i + 1

			var h00: float = _u[idx00]
			var h10: float = _u[idx10]
			var h01: float = _u[idx01]
			var h11: float = _u[idx11]

			_max_displacement = maxf(_max_displacement, maxf(absf(h00), maxf(absf(h10), maxf(absf(h01), absf(h11)))))

			var x0: float = -half + i * cell
			var x1: float = -half + (i + 1) * cell
			var z0: float = -half + j * cell
			var z1: float = -half + (j + 1) * cell

			var v00: Vector3 = Vector3(x0, h00 * height_scale, z0)
			var v10: Vector3 = Vector3(x1, h10 * height_scale, z0)
			var v01: Vector3 = Vector3(x0, h01 * height_scale, z1)
			var v11: Vector3 = Vector3(x1, h11 * height_scale, z1)

			var c00: Color = _displacement_color(h00)
			var c10: Color = _displacement_color(h10)
			var c01: Color = _displacement_color(h01)
			var c11: Color = _displacement_color(h11)

			# Triangle 1
			im.surface_set_color(c00)
			im.surface_add_vertex(v00)
			im.surface_set_color(c10)
			im.surface_add_vertex(v10)
			im.surface_set_color(c11)
			im.surface_add_vertex(v11)

			# Triangle 2
			im.surface_set_color(c00)
			im.surface_add_vertex(v00)
			im.surface_set_color(c11)
			im.surface_add_vertex(v11)
			im.surface_set_color(c01)
			im.surface_add_vertex(v01)

	im.surface_end()
	_surface_mesh.mesh = im


func _displacement_color(h: float) -> Color:
	# Normalise to roughly [-1, 1] using initial amplitude
	var t: float = clampf(h / maxf(initial_amplitude, 0.001), -1.0, 1.0)
	if t > 0.0:
		return color_zero.lerp(color_positive, t)
	else:
		return color_zero.lerp(color_negative, -t)


# --- Labels ---

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "2D WAVE EQUATION"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, height_scale * initial_amplitude + 0.08, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 14
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, height_scale * initial_amplitude + 0.04, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.7, 0.75, 0.85, 0.9)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)
	_update_info()


# --- VR Controls ---

func _create_vr_controls() -> void:
	_control_panel = RackTpl.create_panel("WAVE EQUATION", [
		[{"type": "slider_h", "label": "DAMP", "default": damping / 0.02},
		 {"type": "slider_h", "label": "SPEED", "default": (wave_speed - 0.5) / 4.5}],
		[{"type": "button", "label": "STRIKE"},
		 {"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0, 0.02, membrane_size / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	_damping_slider = _control_panel.find_child("Param_0", true, false)
	if _damping_slider and _damping_slider.has_signal("slider_moved"):
		_damping_slider.slider_moved.connect(_on_damping_changed)

	_speed_slider = _control_panel.find_child("Param_1", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_changed)

	var strike_btn = _control_panel.find_child("Btn_0", true, false)
	if strike_btn:
		var area = strike_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(Callable(self, "_on_strike"))

	var reset_btn = _control_panel.find_child("Btn_1", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(Callable(self, "_on_reset"))

	call_deferred("_sync_sliders")


func _sync_sliders() -> void:
	if _damping_slider and _damping_slider.has_method("set_normalized_value"):
		# Damping range: 0.0 — 0.02
		_damping_slider.set_normalized_value(damping / 0.02)
	if _speed_slider and _speed_slider.has_method("set_normalized_value"):
		# Speed range: 0.5 — 5.0
		_speed_slider.set_normalized_value((wave_speed - 0.5) / 4.5)


func _on_damping_changed(_pos) -> void:
	if _damping_slider and _damping_slider.has_method("get_normalized_value"):
		damping = _damping_slider.get_normalized_value() * 0.02


func _on_speed_changed(_pos) -> void:
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		wave_speed = 0.5 + _speed_slider.get_normalized_value() * 4.5
		_update_courant()


func _on_strike(_b = null) -> void:
	# Apply a new Gaussian pulse at a slightly offset position
	var cx: float = 0.35 + randf() * 0.3
	var cy: float = 0.35 + randf() * 0.3
	_apply_gaussian_pulse(cx, cy, initial_amplitude * 0.6, initial_sigma)


func _on_reset(_b = null) -> void:
	_init_grids()
	_apply_gaussian_pulse(0.5, 0.5, initial_amplitude, initial_sigma)
	_time = 0.0


# --- Per-frame update ---

func _process(delta: float) -> void:
	_time += delta

	# Sub-step for stability — run multiple small steps per frame
	var sub_steps: int = 3
	_dt = delta / float(sub_steps)
	_update_courant()

	for _s in range(sub_steps):
		# Clamp courant for stability: c*dt/dx must be < 1/sqrt(2) ≈ 0.707
		if _courant < 0.707:
			_step_wave()

	_build_surface()
	_update_info()


func _update_info() -> void:
	if _info_label:
		_info_label.text = "u_tt = c²∇²u  ·  c=%.1f  damp=%.3f  peak=%.3f" % [
			wave_speed, damping, _max_displacement
		]


## Grid config arrives twice and by two routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config(),
## and the capture harness calls apply_grid_config() before the scene enters the
## tree. Reading the metadata on the way in means the rim is built once, correctly,
## instead of built clamped and then torn down. Costs nothing when no token is
## present: the export keeps its default and no existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_boundary"):
			boundary = str(node.get_meta("config_boundary"))
		node = node.get_parent()


## Grid system integration — accept configuration from map data.
## Token form: #boundary:free  ·  #boundary:absorbing  ·  #boundary:periodic
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("wave_speed"):
		wave_speed = float(config_data["wave_speed"])
	if config_data.has("damping"):
		damping = float(config_data["damping"])
	if config_data.has("height_scale"):
		height_scale = float(config_data["height_scale"])
	if config_data.has("initial_amplitude"):
		initial_amplitude = float(config_data["initial_amplitude"])

	# GUARDED ON CHANGE, deliberately. The grid reaches this twice for one
	# placement and a placement carrying any other token arrives with no
	# `boundary` key at all; an unguarded rebuild would tear the rim down and
	# raise it again on both of those, for nothing. `_frame_node != null` is the
	# "_ready has already built once" test — before that, _ready does this itself.
	if config_data.has("boundary"):
		var b: String = str(config_data["boundary"]).strip_edges().to_lower()
		if BOUNDARIES.has(b) and b != boundary:
			boundary = b
			if _frame_node != null:
				_rebuild_frame()


func _rebuild_frame() -> void:
	if _frame_node != null:
		# Out of the tree first — queue_free() alone leaves the old rim parented
		# until the end of the frame and the new "Frame" would be auto-renamed.
		remove_child(_frame_node)
		_frame_node.queue_free()
		_frame_node = null
	_boundary_label = null   # parented to the frame; freed with it
	_create_frame()
