# reaction_diffusion_intro.gd
# Reaction-Diffusion Intro — Turing morphogenesis from noise.
# A 32x32 Gray-Scott simulation rendered as an ImageTexture on a quad.
# Two chemicals U and V interact: feed, kill, diffuse. Spots, stripes, coral emerge.
#
# QFEP: Form without blueprint — pattern is not designed, it is the inevitable
# consequence of two chemicals diffusing at different rates. The rule is simple;
# the form is complex. This is emergence.
#
# @identity
# essence: du/dt = Du*laplacian(U) - U*V^2 + f*(1-U) — the Gray-Scott reaction-diffusion model
# desire: watch a flat grey field bloom into spots or stripes — pattern from nothing but math and noise
# critical_parameter: feed_rate (f) and kill_rate (k) — tiny changes switch between spots, stripes, coral, and extinction
# triggers: _step_simulation() runs N Gray-Scott iterations per frame, updating U and V concentrations
# emerges: Turing patterns — spatially periodic chemical concentrations that self-organize from random seeds
# needs: Image + ImageTexture for display [has]; RackTemplates panel with FEED/KILL/SPEED sliders + RESET [has]
# relationships: depends on perlin_noise_bridge (noise as starting condition); feeds cellular automata (local rules → global pattern)
# truth: A leopard does not design its spots — two chemicals racing at different speeds do it for free.

extends Node3D

class_name ReactionDiffusionIntro

# ── Simulation ─────────────────────────────────────────────────────────────
const W := 32
const H := 32
const DU := 0.16   # diffusion rate of U
const DV := 0.08   # diffusion rate of V
const DT := 1.0    # time step

var _feed: float = 0.055
var _kill: float = 0.062
var _speed: int = 10  # iterations per frame

var _u: PackedFloat32Array
var _v: PackedFloat32Array
var _u_next: PackedFloat32Array
var _v_next: PackedFloat32Array

# ── Display ────────────────────────────────────────────────────────────────
var _image: Image
var _texture: ImageTexture
var _quad_mesh: MeshInstance3D

# ── Presets label ──────────────────────────────────────────────────────────
var _preset_label: Label3D


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_init_arrays()
	_seed_center()
	_create_display()
	_create_labels()
	_create_vr_controls()
	_render_to_image()


func _process(_delta: float) -> void:
	for _i in range(_speed):
		_step_simulation()
	_render_to_image()


# ═════════════════════════════════════════════════════════════════════════════
# SIMULATION
# ═════════════════════════════════════════════════════════════════════════════

func _init_arrays() -> void:
	var size := W * H
	_u = PackedFloat32Array()
	_v = PackedFloat32Array()
	_u_next = PackedFloat32Array()
	_v_next = PackedFloat32Array()
	_u.resize(size)
	_v.resize(size)
	_u_next.resize(size)
	_v_next.resize(size)
	_u.fill(1.0)
	_v.fill(0.0)
	_u_next.fill(0.0)
	_v_next.fill(0.0)


func _seed_center() -> void:
	# Seed V with random spots in a central region
	var cx := W / 2
	var cy := H / 2
	var radius := 6
	for y in range(cy - radius, cy + radius):
		for x in range(cx - radius, cx + radius):
			if x >= 0 and x < W and y >= 0 and y < H:
				if randf() < 0.4:
					var idx := y * W + x
					_v[idx] = 1.0
					_u[idx] = 0.5


func _step_simulation() -> void:
	for y in range(H):
		for x in range(W):
			var idx := y * W + x
			var u_val: float = _u[idx]
			var v_val: float = _v[idx]

			# Laplacian with wrap-around
			var lap_u := _laplacian(_u, x, y)
			var lap_v := _laplacian(_v, x, y)

			# Gray-Scott equations
			var uvv: float = u_val * v_val * v_val
			var du: float = DU * lap_u - uvv + _feed * (1.0 - u_val)
			var dv: float = DV * lap_v + uvv - (_feed + _kill) * v_val

			_u_next[idx] = clampf(u_val + du * DT, 0.0, 1.0)
			_v_next[idx] = clampf(v_val + dv * DT, 0.0, 1.0)

	# Swap buffers
	var tmp_u := _u
	_u = _u_next
	_u_next = tmp_u
	var tmp_v := _v
	_v = _v_next
	_v_next = tmp_v


func _laplacian(arr: PackedFloat32Array, x: int, y: int) -> float:
	var center: float = arr[y * W + x]
	var left: float = arr[y * W + ((x - 1 + W) % W)]
	var right: float = arr[y * W + ((x + 1) % W)]
	var up: float = arr[((y - 1 + H) % H) * W + x]
	var down: float = arr[((y + 1) % H) * W + x]
	return left + right + up + down - 4.0 * center


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAY
# ═════════════════════════════════════════════════════════════════════════════

func _create_display() -> void:
	_image = Image.create(W, H, false, Image.FORMAT_RGB8)
	_texture = ImageTexture.create_from_image(_image)

	_quad_mesh = MeshInstance3D.new()
	_quad_mesh.name = "DisplayQuad"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	_quad_mesh.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.emission_enabled = true
	mat.emission_texture = _texture
	mat.emission_energy_multiplier = 0.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_quad_mesh.material_override = mat

	_quad_mesh.position = Vector3(0, 1.2, 0)
	add_child(_quad_mesh)

	# Dark backing panel
	var backing := MeshInstance3D.new()
	backing.name = "Backing"
	var back_quad := QuadMesh.new()
	back_quad.size = Vector2(0.56, 0.56)
	backing.mesh = back_quad
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.08, 0.08, 0.1)
	back_mat.metallic = 0.2
	back_mat.roughness = 0.8
	backing.material_override = back_mat
	backing.position = Vector3(0, 1.2, -0.002)
	add_child(backing)


func _render_to_image() -> void:
	for y in range(H):
		for x in range(W):
			var idx := y * W + x
			var u_val: float = _u[idx]
			# U=1 → light (background), U=0 → dark (pattern)
			# Mix with blue tint for low-U regions
			var brightness: float = u_val
			var color := Color(
				brightness * 0.95,
				brightness * 0.92 + (1.0 - brightness) * 0.1,
				brightness * 0.85 + (1.0 - brightness) * 0.4
			)
			_image.set_pixel(x, y, color)
	_texture.update(_image)


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# Title
	var title := Label3D.new()
	title.text = "REACTION-DIFFUSION"
	title.pixel_size = 0.002
	title.font_size = 18
	title.modulate = Color(0.9, 0.9, 0.95)
	title.position = Vector3(0, 1.58, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Subtitle
	var sub := Label3D.new()
	sub.text = "Turing morphogenesis — patterns from noise"
	sub.pixel_size = 0.0013
	sub.font_size = 10
	sub.modulate = Color(0.6, 0.6, 0.7)
	sub.position = Vector3(0, 1.54, 0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Preset hint
	_preset_label = Label3D.new()
	_preset_label.name = "PresetLabel"
	_preset_label.text = "f=0.055 k=0.062 → spots"
	_preset_label.pixel_size = 0.001
	_preset_label.font_size = 10
	_preset_label.modulate = Color(0.7, 0.8, 0.6)
	_preset_label.position = Vector3(0.32, 1.3, 0)
	_preset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_preset_label)

	# Formula
	var formula := Label3D.new()
	formula.text = "du = Du*lap(U) - U*V*V + f*(1-U)\ndv = Dv*lap(V) + U*V*V - (f+k)*V"
	formula.pixel_size = 0.0008
	formula.font_size = 9
	formula.modulate = Color(0.5, 0.5, 0.55)
	formula.position = Vector3(0, 0.9, 0)
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(formula)


func _update_preset_label() -> void:
	if not _preset_label:
		return
	var pattern_name := "unknown"
	if _feed > 0.05 and _kill > 0.06:
		pattern_name = "spots"
	elif _feed < 0.045 and _kill > 0.055 and _kill < 0.065:
		pattern_name = "stripes"
	elif _feed < 0.03 and _kill > 0.055:
		pattern_name = "coral"
	elif _feed > 0.06:
		pattern_name = "decay"
	else:
		pattern_name = "mixed"
	_preset_label.text = "f=%.3f k=%.3f → %s" % [_feed, _kill, pattern_name]


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("GRAY-SCOTT", [
		[
			{"type": "slider_h", "label": "FEED", "default": (_feed - 0.01) / 0.07},
			{"type": "slider_h", "label": "KILL", "default": (_kill - 0.04) / 0.03},
		],
		[
			{"type": "slider_h", "label": "SPEED", "default": (_speed - 1.0) / 19.0},
			{"type": "button", "label": "RESET"},
		],
	])
	panel.position = Vector3(0, 0.7, 0.15)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# FEED slider (Param_0) — maps [0, 1] to [0.01, 0.08]
	var feed_slider: Node = panel.find_child("Param_0", true, false)
	if feed_slider and feed_slider.has_signal("slider_moved"):
		feed_slider.slider_moved.connect(func(_val: float):
			_feed = feed_slider.get_normalized_value() * 0.07 + 0.01
			_update_preset_label()
		)

	# KILL slider (Param_1) — maps [0, 1] to [0.04, 0.07]
	var kill_slider: Node = panel.find_child("Param_1", true, false)
	if kill_slider and kill_slider.has_signal("slider_moved"):
		kill_slider.slider_moved.connect(func(_val: float):
			_kill = kill_slider.get_normalized_value() * 0.03 + 0.04
			_update_preset_label()
		)

	# SPEED slider (Param_2) — maps [0, 1] to [1, 20]
	var speed_slider: Node = panel.find_child("Param_2", true, false)
	if speed_slider and speed_slider.has_signal("slider_moved"):
		speed_slider.slider_moved.connect(func(_val: float):
			_speed = int(speed_slider.get_normalized_value() * 19.0) + 1
		)

	# RESET button (Btn_0)
	var reset_btn: Node = panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset())


func _reset() -> void:
	_u.fill(1.0)
	_v.fill(0.0)
	_seed_center()
	_render_to_image()
	_update_preset_label()


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
