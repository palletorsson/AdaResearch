# edge_of_chaos_unlocked.gd
# Reaction-diffusion system with an UNLOCKED lambda slider.
# The companion to the locked-lambda map. Now the learner controls lambda.
#
# @identity
# essence: Gray-Scott reaction-diffusion on a 64x64 grid with an UNLOCKED lambda slider — the control the map withheld, now given
# desire: to answer the critical.md question by letting the learner discover that adjusting lambda IS knowledge and witnessing lambda locked IS knowledge — different kinds
# critical_parameter: lambda (0.0-1.0) — maps to feed/kill rate balance; 0=frozen crystal, 0.4=Turing patterns emerge, 1.0=pure noise
# triggers: dragging lambda slowly from 0 toward 0.4 produces the moment of emergence — spots appear from nothing; pushing past 0.7 dissolves everything into static
# emerges: Turing spots, stripes, labyrinthine patterns at the edge; the learner discovers the parameter space has texture, not just a gradient
# needs: [has] lambda slider via ArtifactControls; [has] regime label (FROZEN/EDGE/CHAOS); [has] display rate control; [missing] no pattern save; no comparison view
# relationships: companion to QFEP_Edge_Of_Chaos map where lambda_slider is locked at 0.4; the map withholds what this artifact gives
# truth: when you control lambda, you understand the parameter space; when you witness it locked, you understand what it feels like to be at the edge; both are knowledge

extends Node3D

class_name EdgeOfChaosUnlocked

## Grid resolution for reaction-diffusion
@export var grid_size: int = 64

## Lambda parameter: 0=frozen, 0.4=edge, 1.0=chaos
@export_range(0.0, 1.0, 0.01) var lambda: float = 0.4:
	set(value):
		lambda = clampf(value, 0.0, 1.0)
		_update_reaction_params()
		_update_regime_label()

## Display update rate (frames between texture updates)
@export_range(1, 10) var display_rate: int = 2

## Simulation steps per frame
@export_range(1, 8) var sim_steps: int = 4

# Gray-Scott parameters derived from lambda
var _feed_rate: float = 0.037
var _kill_rate: float = 0.06
var _diffusion_a: float = 1.0
var _diffusion_b: float = 0.5

# Grid state (two chemicals: A and B)
var _grid_a: PackedFloat32Array
var _grid_b: PackedFloat32Array
var _grid_a_next: PackedFloat32Array
var _grid_b_next: PackedFloat32Array

# Display
var _texture: ImageTexture
var _image: Image
var _display_quad: MeshInstance3D
var _frame_count: int = 0

# UI
var _controls: Node
var _regime_label: Label3D
var _lambda_label: Label3D
var _title_label: Label3D


func _ready() -> void:
	_init_grid()
	_build_display()
	_build_controls()
	_build_labels()
	_update_reaction_params()
	_seed_pattern()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_frame_count += 1
	for _step in range(sim_steps):
		_simulate_step()
	if _frame_count % display_rate == 0:
		_update_texture()


# ── Grid Init ───────────────────────────────────────────────

func _init_grid() -> void:
	var total := grid_size * grid_size
	_grid_a = PackedFloat32Array()
	_grid_b = PackedFloat32Array()
	_grid_a_next = PackedFloat32Array()
	_grid_b_next = PackedFloat32Array()
	_grid_a.resize(total)
	_grid_b.resize(total)
	_grid_a_next.resize(total)
	_grid_b_next.resize(total)

	# Fill with chemical A=1, B=0
	for i in range(total):
		_grid_a[i] = 1.0
		_grid_b[i] = 0.0


func _seed_pattern() -> void:
	# Seed a few spots of chemical B in the center region
	var center := grid_size / 2
	var radius := grid_size / 8
	for _s in range(12):
		var sx := center + randi_range(-radius, radius)
		var sz := center + randi_range(-radius, radius)
		for dx in range(-2, 3):
			for dz in range(-2, 3):
				var x := clampi(sx + dx, 0, grid_size - 1)
				var z := clampi(sz + dz, 0, grid_size - 1)
				var idx := z * grid_size + x
				_grid_b[idx] = 1.0
				_grid_a[idx] = 0.5


# ── Reaction-Diffusion ─────────────────────────────────────

func _update_reaction_params() -> void:
	# Map lambda to Gray-Scott feed/kill parameter space
	# lambda=0: very low feed, high kill -> frozen, nothing grows
	# lambda~0.4: feed=0.037, kill=0.06 -> Turing patterns (spots/stripes)
	# lambda=1: high feed, low kill -> everything activates, noise
	_feed_rate = lerpf(0.01, 0.08, lambda)
	_kill_rate = lerpf(0.08, 0.03, lambda)
	_diffusion_a = lerpf(0.8, 1.2, lambda)
	_diffusion_b = lerpf(0.3, 0.7, lambda)


func _simulate_step() -> void:
	var dt := 1.0
	var gs := grid_size

	for z in range(gs):
		for x in range(gs):
			var idx := z * gs + x

			var a := _grid_a[idx]
			var b := _grid_b[idx]

			# Laplacian (5-point stencil with wrapping)
			var lap_a := -4.0 * a
			var lap_b := -4.0 * b

			var xl := ((x - 1) + gs) % gs
			var xr := (x + 1) % gs
			var zu := ((z - 1) + gs) % gs
			var zd := (z + 1) % gs

			lap_a += _grid_a[z * gs + xl] + _grid_a[z * gs + xr] + _grid_a[zu * gs + x] + _grid_a[zd * gs + x]
			lap_b += _grid_b[z * gs + xl] + _grid_b[z * gs + xr] + _grid_b[zu * gs + x] + _grid_b[zd * gs + x]

			# Gray-Scott equations
			var ab2 := a * b * b
			var new_a := a + (_diffusion_a * lap_a - ab2 + _feed_rate * (1.0 - a)) * dt
			var new_b := b + (_diffusion_b * lap_b + ab2 - (_kill_rate + _feed_rate) * b) * dt

			_grid_a_next[idx] = clampf(new_a, 0.0, 1.0)
			_grid_b_next[idx] = clampf(new_b, 0.0, 1.0)

	# Swap buffers
	var temp_a := _grid_a
	var temp_b := _grid_b
	_grid_a = _grid_a_next
	_grid_b = _grid_b_next
	_grid_a_next = temp_a
	_grid_b_next = temp_b


# ── Display ─────────────────────────────────────────────────

func _build_display() -> void:
	_image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGB8)
	_texture = ImageTexture.create_from_image(_image)

	_display_quad = MeshInstance3D.new()
	_display_quad.name = "ReactionDiffusionDisplay"

	var quad := QuadMesh.new()
	quad.size = Vector2(1.5, 1.5)
	_display_quad.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _texture
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_display_quad.material_override = mat

	# Tilt the quad to face the viewer
	_display_quad.position = Vector3(0, 0.85, 0)
	_display_quad.rotation_degrees.x = -15
	add_child(_display_quad)

	# Base
	var base := MeshInstance3D.new()
	base.name = "Base"
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.06, 0.3)
	base.mesh = box
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.1, 0.1, 0.12)
	bmat.metallic = 0.5
	bmat.roughness = 0.4
	base.material_override = bmat
	base.position = Vector3(0, 0.03, 0)
	add_child(base)


func _update_texture() -> void:
	for z in range(grid_size):
		for x in range(grid_size):
			var idx := z * grid_size + x
			var b_val := _grid_b[idx]

			# Turing pattern palette:
			# Low B (no pattern) -> deep teal
			# Medium B (edge patterns) -> warm amber/green
			# High B (active) -> bright cream
			var col: Color
			if b_val < 0.15:
				col = Color(0.05, 0.15, 0.18).lerp(Color(0.1, 0.3, 0.25), b_val / 0.15)
			elif b_val < 0.4:
				var t := (b_val - 0.15) / 0.25
				col = Color(0.1, 0.3, 0.25).lerp(Color(0.7, 0.55, 0.2), t)
			else:
				var t := clampf((b_val - 0.4) / 0.6, 0.0, 1.0)
				col = Color(0.7, 0.55, 0.2).lerp(Color(0.95, 0.9, 0.8), t)

			_image.set_pixel(x, z, col)

	_texture.update(_image)


# ── Controls ────────────────────────────────────────────────

func _build_controls() -> void:
	_controls = ArtifactControls.new()
	_controls.name = "Controls"
	_controls.position = Vector3(1.2, 1.0, 0.0)
	add_child(_controls)

	_controls.add_slider("LAMBDA", lambda, func(v: float):
		lambda = v
	)
	_controls.add_slider("SIM SPEED", float(sim_steps - 1) / 7.0, func(v: float):
		sim_steps = int(round(v * 7.0)) + 1
	)
	_controls.add_button("RESEED", func():
		_init_grid()
		_seed_pattern()
	)


func _build_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "Title"
	_title_label.text = "EDGE OF CHAOS — UNLOCKED"
	_title_label.font_size = 36
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 2.0, 0)
	_title_label.modulate = Color(0.4, 1.0, 0.6, 0.9)
	add_child(_title_label)

	var sub := Label3D.new()
	sub.name = "Subtitle"
	sub.text = "The slider the map withheld. Now it is yours."
	sub.font_size = 20
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sub.position = Vector3(0, 1.85, 0)
	sub.modulate = Color(0.7, 0.8, 0.7, 0.7)
	add_child(sub)

	_regime_label = Label3D.new()
	_regime_label.name = "RegimeLabel"
	_regime_label.font_size = 28
	_regime_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_regime_label.position = Vector3(0, 0.0, 0.3)
	add_child(_regime_label)

	_lambda_label = Label3D.new()
	_lambda_label.name = "LambdaValue"
	_lambda_label.font_size = 22
	_lambda_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lambda_label.position = Vector3(0, -0.15, 0.3)
	_lambda_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
	add_child(_lambda_label)

	_update_regime_label()


func _update_regime_label() -> void:
	if not _regime_label:
		return
	if lambda < 0.2:
		_regime_label.text = "FROZEN"
		_regime_label.modulate = Color(0.4, 0.6, 1.0, 0.9)
	elif lambda < 0.55:
		_regime_label.text = "EDGE OF CHAOS"
		_regime_label.modulate = Color(0.2, 1.0, 0.5, 0.9)
	else:
		_regime_label.text = "CHAOS"
		_regime_label.modulate = Color(1.0, 0.3, 0.2, 0.9)

	if _lambda_label:
		_lambda_label.text = "lambda = %.2f" % lambda
