# @identity
# essence: a corridor whose two walls are layered sine waves — walk between standing waveforms
# desire: feel the body inside the wave — left and right walls phasing against each other across 24m
# critical_parameter: phase_offset_between_walls — how much the right wall lags the left, gating the beat-pattern between them
# triggers: _ready() rebuilds wall meshes on parameter change; animate_at_runtime tweens the phase across animation_speed
# emerges: a 200-column waveform corridor with three superposed wave_layers, plush shader gradient bottom→mid→top, optional wall collision
# needs: phase offset slider [has, 2026-09-10]; amplitude slider [has, 2026-09-10]; frequency multiplier dial [missing]; layer count picker [missing]
# relationships: cousin of OscillatingWave (single wave) and HarmonicBuilder (sum of sines); contrast to SineSpace (floor as wave, this is walls as wave)
# truth: A wave is not a thing but a relationship. Walking between two of them turns the body into a probe — the corridor reads you back.

@tool
extends Node3D

@export_range(4, 256, 1) var columns: int = 200
@export_range(4, 256, 1) var rows: int = 64
@export var corridor_length: float = 24.0
@export var corridor_width: float = 1.0
@export var corridor_height: float = 6.0

@export var base_frequency: float = 2.2
@export var base_amplitude: float = 0.45
@export var left_wall_frequency_multiplier: float = 1.6
@export var left_wall_amplitude_multiplier: float = 0.5
@export var phase: float = 0.0
@export var phase_offset_between_walls: float = 0.6

@export var wave_layers: Array = [
	{"freq_mul": 1.0, "amp_mul": 1.0, "phase_shift": 0.0},
	{"freq_mul": 1.8, "amp_mul": 0.35, "phase_shift": 0.85},
	{"freq_mul": 2.6, "amp_mul": 0.18, "phase_shift": -0.35}
]

@export var bottom_color: Color = Color(0.08, 0.18, 0.35, 1.0)
@export var mid_color: Color = Color(0.28, 0.65, 0.85, 1.0)
@export var top_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var wall_emission: Color = Color(0.05, 0.16, 0.28, 1.0)
@export var enable_collision: bool = true
@export var use_plush_shader: bool = true

@export var auto_update_in_editor: bool = false
@export var animate_at_runtime: bool = false
@export var animation_speed: float = 0.05  # Very slow animation

## THE ENTRANCE PANEL (2026-09-10, doc/research/waves-chance-noise batch W1).
## "none" builds no panel. "entrance"
## stands a RackTemplates panel beside the -Z mouth with two sliders, AMP (the
## shared base amplitude, 0..amplitude_max) and PHASE (the offset between the
## walls, 0..PI), and two buttons, FREEZE (stop/start the phase animation) and
## RESET (the placement's declared values, handles included), plus a readout that
## prints the values in force and the sampled local-X gap range.
@export_enum("none", "entrance") var panel: String = "none"
@export var amplitude_max: float = 0.45
const PHASE_OFFSET_MAX := PI

## AXIS — WHAT THE WALL IS MADE OF, which is the same as asking what a wave IS.
##
## The corridor computes a 200 x 64 grid of samples and then hides that grid completely
## under a continuous triangulated skin: you walk between two smooth solids and the sampling
## that produced them is invisible. That is one answer, and it is the default. It is not the
## only one, and the others are not decoration — each is a different claim about what the
## thing standing there actually is.
##
##   skin      the legacy lineage, byte for byte — every quad emitted, a closed surface.
##             The wave as an object: continuous, seamless, the arithmetic denied.
##   ribs      only every other run of four columns survives, so the wall becomes ~25
##             vertical fins with air between them. The wave as a FAMILY OF PROFILES — the
##             same section repeated at intervals, which is how a wave is actually drawn.
##             You can see the far wall through the near one, so the phase offset the
##             corridor teaches becomes legible for the first time.
##   strata    the same cut taken horizontally: bands of four rows, gaps between. The wave
##             as a stack of contours, the way a curved surface is really fabricated.
##   lattice   both cuts at once and almost nothing left: a cage of mullions and rails
##             standing on the sample lines. The wave as its own measuring grid, with the
##             surface withheld.
##
## Same vertices, same displacement function, same colours — the mathematics is not touched.
## What changes is which quads are emitted, and therefore whether the corridor presents a
## result or admits a method.
@export_enum("skin", "ribs", "strata", "lattice") var cut: String = "skin"
const FABRICS: PackedStringArray = ["skin", "ribs", "strata", "lattice"]

var _left_wall: MeshInstance3D
var _right_wall: MeshInstance3D
var _floor: MeshInstance3D
var _left_wall_body: StaticBody3D
var _right_wall_body: StaticBody3D
var _left_wall_shape: CollisionShape3D
var _right_wall_shape: CollisionShape3D
var _floor_body: StaticBody3D
var _floor_shape: CollisionShape3D
var _wall_material: Material
var _floor_material: StandardMaterial3D
var _last_signature: String = ""
var _panel: Node3D
var _readout: Label3D
var _amp_slider: Node
var _phase_slider: Node
## The placement's declared values, kept so RESET has something to return to.
var _declared: Dictionary = {}

func _ready() -> void:
	_read_dna_meta()
	_ensure_nodes()
	_build_corridor()
	if not Engine.is_editor_hint():
		_strip_standalone_chrome()
		_declared = {"amplitude": base_amplitude, "phase_offset": phase_offset_between_walls,
			"phase": phase, "animate": animate_at_runtime}
		if panel == "entrance":
			_build_panel()
	_update_process_state()


## The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the build and an
## unknown word keeps the default. No metadata, no change.
func _read_dna_meta() -> void:
	if has_meta("config_fabric"):
		var f: String = str(get_meta("config_fabric")).strip_edges().to_lower()
		cut = f if FABRICS.has(f) else cut
	if has_meta("config_panel"):
		var p: String = str(get_meta("config_panel")).strip_edges().to_lower()
		panel = p if p in ["none", "entrance"] else panel

## The scene carries a camera, a sun with shadows and a dark environment for running
## it on its own. Inside a map or the museum those would fight the room's; the blue
## fill light stays, it is local to the passage.
func _strip_standalone_chrome() -> void:
	if get_tree() == null or get_tree().current_scene == self:
		return
	for n in ["Camera3D", "DirectionalLight3D", "WorldEnvironment"]:
		var c := get_node_or_null(n)
		if c != null:
			c.queue_free()

func rebuild_corridor() -> void:
	_ensure_nodes()
	_build_corridor()

func _ensure_nodes() -> void:
	# Check if material needs to be switched
	if _wall_material:
		var is_shader = _wall_material is ShaderMaterial
		if is_shader != use_plush_shader:
			_wall_material = null

	if not _wall_material:
		if use_plush_shader:
			var shader = load("res://algorithms/wavefunctions/sine_wall/plush_red.gdshader")
			if shader:
				var sm = ShaderMaterial.new()
				sm.shader = shader
				_wall_material = sm
			else:
				var sm = StandardMaterial3D.new()
				sm.albedo_color = Color(0.6, 0.0, 0.1)
				_wall_material = sm
		else:
			var sm = StandardMaterial3D.new()
			sm.vertex_color_use_as_albedo = true
			sm.roughness = 0.45
			sm.metallic = 0.1
			sm.emission_enabled = true
			sm.emission = wall_emission
			sm.emission_energy_multiplier = 0.45
			sm.cull_mode = BaseMaterial3D.CULL_DISABLED
			_wall_material = sm

	# Re-assign material to meshes in case it changed
	if _left_wall: _left_wall.material_override = _wall_material
	if _right_wall: _right_wall.material_override = _wall_material

	if not _floor_material:
		_floor_material = StandardMaterial3D.new()
		_floor_material.albedo_color = Color(0.04, 0.05, 0.07, 1.0)
		_floor_material.roughness = 0.7
		_floor_material.metallic = 0.05
		_floor_material.emission_enabled = true
		_floor_material.emission = Color(0.02, 0.03, 0.05)
		_floor_material.emission_energy_multiplier = 0.25

	_left_wall = _get_or_create_mesh_instance("LeftWall", _left_wall)
	_right_wall = _get_or_create_mesh_instance("RightWall", _right_wall)
	_floor = _get_or_create_mesh_instance("Floor", _floor)
	_left_wall_body = _get_or_create_static_body("LeftWallBody", _left_wall_body)
	_right_wall_body = _get_or_create_static_body("RightWallBody", _right_wall_body)
	_left_wall_shape = _get_or_create_collision_shape(_left_wall_body, "LeftWallShape", _left_wall_shape)
	_right_wall_shape = _get_or_create_collision_shape(_right_wall_body, "RightWallShape", _right_wall_shape)
	# THE FLOOR SLAB (2026-09-10): the passage floor carries a thin collider even when
	# the walls do not. A body walks on it (12 mm), and in the museum a collider is
	# what makes the walk map treat the passage as this body's ground, so nothing
	# else — a bench, a sculpture — is dealt into it. The walls stay visible-only.
	_floor_body = _get_or_create_static_body("FloorBody", _floor_body)
	_floor_shape = _get_or_create_collision_shape(_floor_body, "FloorShape", _floor_shape)

	var existing_ceiling := get_node_or_null("Ceiling")
	if existing_ceiling:
		existing_ceiling.queue_free()

	for mesh in [_left_wall, _right_wall]:
		mesh.material_override = _wall_material
	_floor.material_override = _floor_material
	_left_wall_body.transform = Transform3D.IDENTITY
	_right_wall_body.transform = Transform3D.IDENTITY

func _get_or_create_mesh_instance(name: String, cache: MeshInstance3D) -> MeshInstance3D:
	if cache and is_instance_valid(cache):
		return cache
	var node := get_node_or_null(name) as MeshInstance3D
	if not node:
		node = MeshInstance3D.new()
		node.name = name
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(node)
	return node

func _get_or_create_static_body(name: String, cache: StaticBody3D) -> StaticBody3D:
	if cache and is_instance_valid(cache):
		return cache
	var body := get_node_or_null(name) as StaticBody3D
	if not body:
		body = StaticBody3D.new()
		body.name = name
		add_child(body)
	return body

func _get_or_create_collision_shape(parent: Node3D, name: String, cache: CollisionShape3D) -> CollisionShape3D:
	if cache and is_instance_valid(cache):
		return cache
	var shape_node := parent.get_node_or_null(name) as CollisionShape3D
	if not shape_node:
		shape_node = CollisionShape3D.new()
		shape_node.name = name
		parent.add_child(shape_node)
	return shape_node

func _build_corridor() -> void:
	if columns < 2 or rows < 2:
		return

	var signature := _make_signature()
	if signature == _last_signature:
		return

	var half_length := corridor_length * 0.5
	var half_width := corridor_width * 0.5
	var half_height := corridor_height * 0.5

	_left_wall.mesh = _create_wall_mesh(-1, half_length, half_width, half_height, phase, left_wall_frequency_multiplier, left_wall_amplitude_multiplier)
	_right_wall.mesh = _create_wall_mesh(1, half_length, half_width, half_height, phase + phase_offset_between_walls, 1.0, 1.0)
	_floor.mesh = _create_plane_mesh(half_length, half_width, half_height, false)
	_update_wall_collision(_left_wall, _left_wall_shape)
	_update_wall_collision(_right_wall, _right_wall_shape)

	# THE DECK IS THE ORIGIN (2026-09-10, observed in the museum: the map-authored
	# lane does not ground a body whose geometry is built in _ready, so a corridor
	# centred on its origin stood two metres into the floor). The meshes are built
	# about y = 0 and lifted here by half the height, so the floor sits at the
	# origin whatever lane placed it; the floor a hair above the deck so the two
	# floors do not fight. The colliders (walls when enabled, the floor slab
	# always) carry the same lift.
	_left_wall.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, half_height, 0.0))
	_right_wall.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, half_height, 0.0))
	_floor.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, half_height + 0.012, 0.0))
	_left_wall_body.transform = _left_wall.transform
	_right_wall_body.transform = _right_wall.transform
	if _floor_shape != null:
		var slab := BoxShape3D.new()
		slab.size = Vector3(corridor_width, 0.024, corridor_length)
		_floor_shape.shape = slab
		_floor_body.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.012, 0.0))

	_last_signature = signature
	_refresh_readout()

func _update_wall_collision(mesh_instance: MeshInstance3D, shape_node: CollisionShape3D) -> void:
	if not shape_node:
		return
	if not enable_collision:
		shape_node.shape = null
		return
	var mesh := mesh_instance.mesh
	if mesh:
		shape_node.shape = mesh.create_trimesh_shape()
	else:
		shape_node.shape = null

func _create_wall_mesh(side: int, half_length: float, half_width: float, half_height: float, phase_shift: float, freq_multiplier: float, amp_multiplier: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var position_columns: Array[PackedVector3Array] = []
	var color_columns: Array[PackedColorArray] = []
	var uv_columns: Array[PackedVector2Array] = []

	for col in range(columns):
		var column_positions: PackedVector3Array = PackedVector3Array()
		var column_colors: PackedColorArray = PackedColorArray()
		var column_uvs: PackedVector2Array = PackedVector2Array()

		var z_ratio: float = col / float(columns - 1)
		var z_pos: float = lerp(-half_length, half_length, z_ratio)
		var displacement: float = _wave_displacement(z_ratio, phase_shift, freq_multiplier, amp_multiplier)
		var column_color: Color = _evaluate_color(displacement)

		for row in range(rows):
			var y_ratio: float = row / float(rows - 1)
			var y_pos: float = lerp(-half_height, half_height, y_ratio)
			var base_x: float = side * half_width
			var x_pos: float = base_x - side * displacement
			column_positions.append(Vector3(x_pos, y_pos, z_pos))
			column_colors.append(column_color)
			column_uvs.append(Vector2(z_ratio, y_ratio))

		position_columns.append(column_positions)
		color_columns.append(column_colors)
		uv_columns.append(column_uvs)

	for col in range(columns - 1):
		var left_positions: PackedVector3Array = position_columns[col]
		var right_positions: PackedVector3Array = position_columns[col + 1]
		var left_colors: PackedColorArray = color_columns[col]
		var right_colors: PackedColorArray = color_columns[col + 1]
		var left_uvs: PackedVector2Array = uv_columns[col]
		var right_uvs: PackedVector2Array = uv_columns[col + 1]

		for row in range(rows - 1):
			# FABRIC gate. On "skin" this is always true and the vertex stream below is
			# emitted in full, exactly as before.
			if not _fabric_keeps(col, row):
				continue
			var v00: Vector3 = left_positions[row]
			var v10: Vector3 = right_positions[row]
			var v11: Vector3 = right_positions[row + 1]
			var v01: Vector3 = left_positions[row + 1]

			var c00: Color = left_colors[row]
			var c10: Color = right_colors[row]
			var c11: Color = right_colors[row + 1]
			var c01: Color = left_colors[row + 1]

			var uv00: Vector2 = left_uvs[row]
			var uv10: Vector2 = right_uvs[row]
			var uv11: Vector2 = right_uvs[row + 1]
			var uv01: Vector2 = left_uvs[row + 1]

			if side < 0:
				_add_triangle(st, v00, c00, uv00, v10, c10, uv10, v11, c11, uv11)
				_add_triangle(st, v00, c00, uv00, v11, c11, uv11, v01, c01, uv01)
			else:
				_add_triangle(st, v00, c00, uv00, v11, c11, uv11, v10, c10, uv10)
				_add_triangle(st, v00, c00, uv00, v01, c01, uv01, v11, c11, uv11)

	st.generate_normals()
	return st.commit()

func _add_triangle(st: SurfaceTool, a: Vector3, ca: Color, uva: Vector2, b: Vector3, cb: Color, uvb: Vector2, c: Vector3, cc: Color, uvc: Vector2) -> void:
	st.set_color(ca)
	st.set_uv(uva)
	st.add_vertex(a)
	st.set_color(cb)
	st.set_uv(uvb)
	st.add_vertex(b)
	st.set_color(cc)
	st.set_uv(uvc)
	st.add_vertex(c)

func _create_plane_mesh(half_length: float, half_width: float, half_height: float, is_ceiling: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var y: float = half_height if is_ceiling else -half_height
	var color: Color = mid_color

	var c0 := Vector3(-half_width, y, -half_length)
	var c1 := Vector3(half_width, y, -half_length)
	var c2 := Vector3(half_width, y, half_length)
	var c3 := Vector3(-half_width, y, half_length)

	if is_ceiling:
		_add_triangle(st, c0, color, Vector2(0, 0), c1, color, Vector2(1, 0), c2, color, Vector2(1, 1))
		_add_triangle(st, c0, color, Vector2(0, 0), c2, color, Vector2(1, 1), c3, color, Vector2(0, 1))
	else:
		_add_triangle(st, c0, color, Vector2(0, 0), c2, color, Vector2(1, 1), c1, color, Vector2(1, 0))
		_add_triangle(st, c0, color, Vector2(0, 0), c3, color, Vector2(0, 1), c2, color, Vector2(1, 1))

	st.generate_normals()
	return st.commit()

func _wave_displacement(z_ratio: float, phase_shift: float, freq_multiplier: float = 1.0, amp_multiplier: float = 1.0) -> float:
	var z_norm: float = z_ratio * 2.0 - 1.0
	var offset: float = 0.0
	for layer in wave_layers:
		var freq_mul: float = float(layer.get("freq_mul", 1.0))
		var amp_mul: float = float(layer.get("amp_mul", 1.0))
		var phase_layer: float = float(layer.get("phase_shift", 0.0))
		# The caller already supplies phase (plus this wall's offset). Add it once.
		offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
	return offset

func _evaluate_color(displacement: float) -> Color:
	# AMP can reach zero: a flat wall still needs finite vertex colours.
	var intensity: float = (displacement / maxf(absf(base_amplitude) * 1.6, 0.000001)) + 0.5
	intensity = clamp(intensity, 0.0, 1.0)
	var blend: float = clamp(intensity * 1.8, 0.0, 1.0)
	var color: Color = bottom_color.lerp(mid_color, blend)
	color = color.lerp(top_color, intensity)
	return color

func _make_signature() -> String:
	return str(columns, rows, corridor_length, corridor_width, corridor_height, base_frequency, base_amplitude, left_wall_frequency_multiplier, left_wall_amplitude_multiplier, phase, phase_offset_between_walls, wave_layers, bottom_color, mid_color, top_color, enable_collision, use_plush_shader, cut)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# Editor mode: check for parameter changes
		if not auto_update_in_editor:
			return
		var signature := _make_signature()
		if signature != _last_signature:
			_build_corridor()
	else:
		# Runtime mode: animate phase slowly
		if animate_at_runtime:
			phase += delta * animation_speed
			_last_signature = ""  # Force rebuild
			_build_corridor()

func _update_process_state() -> void:
	set_process(Engine.is_editor_hint() or animate_at_runtime)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# The DNA axis and the panel word are read here; every other key is ignored exactly
	# as before. The grid calls this deferred, after _ready, so _read_dna_meta has
	# normally applied the same values already and the guards below make this a no-op.
	if config.has("cut"):
		var f: String = str(config["cut"]).strip_edges().to_lower()
		var picked: String = f if FABRICS.has(f) else cut
		if picked != cut:
			cut = picked
			rebuild_corridor()
	if config.has("panel"):
		var p: String = str(config["panel"]).strip_edges().to_lower()
		if p in ["none", "entrance"] and p != panel:
			panel = p
			if panel == "entrance" and _panel == null and not Engine.is_editor_hint():
				_build_panel()
			elif panel == "none" and _panel != null:
				_panel.queue_free(); _panel = null
				if _readout != null: _readout.queue_free(); _readout = null


# ── FABRIC ───────────────────────────────────────────────────────────────────────────────
# Appended LAST. The default "skin" falls through to `_` and keeps every quad, so the mesh
# built on the legacy path is vertex-for-vertex what it was. Nothing here touches the
# displacement function, the colour ramp or the sample grid — only which cells of that grid
# are given a surface.

## The moduli are in SAMPLE units, not metres, so a fin stays a fin whatever corridor_length
## and columns are set to. At the shipped 8 m / 200 columns / 64 rows: twelve fins about
## 24 cm wide, eight bands about 25 cm tall, and a lattice of 12 cm mullions around roughly
## half-metre openings — all of them tens of pixels at the sweep's framing, not hairlines.
func _fabric_keeps(col: int, row: int) -> bool:
	match cut:
		"ribs":
			return (col % 16) < 6
		"strata":
			return (row % 8) < 4
		"lattice":
			return ((col % 15) < 3) or ((row % 12) < 3)
		_:
			return true


# ── THE ENTRANCE PANEL (2026-09-10) ───────────────────────────────────────────────────────
# Beside the -Z mouth, on the +X side of the passage so it does not stand in the doorway,
# turned to face a body arriving from -Z. RackTemplates builds it; the two sliders reach
# base_amplitude and phase_offset_between_walls, the two buttons the animation and the
# declared values. The panel's touch areas are marked a local instrument so the museum
# does not read them as this venue's footprint.

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	_panel = RackTpl.create_panel("PASSAGE", [
		[{"type": "slider_h", "label": "AMP", "default": _amp_norm(base_amplitude)}],
		[{"type": "slider_h", "label": "PHASE", "default": _phase_norm(phase_offset_between_walls)}],
		[{"type": "button", "label": "FREEZE"}, {"type": "button", "label": "RESET"}],
	])
	_panel.name = "Panel"
	_panel.set_meta("em_local_instrument", true)
	var deck: float = 0.0   # the meshes are lifted by half the height; the origin is the deck
	# -X side of the mouth, in line with that wall's end and 0.35 m short of it, turned
	# to face the arriving body. (2026-09-10: 0.45 m further out it hung over the museum's
	# low partition behind the passage; on the +X side, one row nearer the door, the
	# museum scaled the whole corridor to 0.65 and turned it — recorded in the report.)
	_panel.position = Vector3(-(corridor_width * 0.5 + 0.05), deck + 1.0, -(corridor_length * 0.5 + 0.35))
	_panel.rotation_degrees = Vector3(-15.0, 180.0, 0.0)
	add_child(_panel)
	_amp_slider = _panel.find_child("Param_0", true, false)
	if _amp_slider != null and _amp_slider.has_signal("slider_moved"):
		_amp_slider.slider_moved.connect(func(_v): set_amplitude(lerpf(0.0, amplitude_max, float(_amp_slider.get_normalized_value()))))
	_phase_slider = _panel.find_child("Param_1", true, false)
	if _phase_slider != null and _phase_slider.has_signal("slider_moved"):
		_phase_slider.slider_moved.connect(func(_v): set_phase_offset(float(_phase_slider.get_normalized_value()) * PHASE_OFFSET_MAX))
	var b0: Node = _panel.find_child("Btn_0", true, false)
	var a0: Node = b0.get_node_or_null("InteractableAreaButton") if b0 != null else null
	if a0 != null and a0.has_signal("button_pressed"):
		a0.button_pressed.connect(func(_b): toggle_animation())
	var b1: Node = _panel.find_child("Btn_1", true, false)
	var a1: Node = b1.get_node_or_null("InteractableAreaButton") if b1 != null else null
	if a1 != null and a1.has_signal("button_pressed"):
		a1.button_pressed.connect(func(_b): reset_declared())
	# the readout on a dark plate above the panel (the first capture showed pale text
	# floating over a grey wall; the pendulum's cased plate read at 1.35 m)
	var plate := MeshInstance3D.new()
	plate.name = "ReadoutPlate"
	var pbox := BoxMesh.new()
	pbox.size = Vector3(0.95, 0.36, 0.02)   # four short lines since 12 September; one long line escaped a 0.9 × 0.2 plate
	plate.mesh = pbox
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.13, 0.12, 0.13)
	pmat.roughness = 0.8
	plate.material_override = pmat
	plate.position = _panel.position + Vector3(0.0, 0.64, 0.0)
	plate.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	add_child(plate)
	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.pixel_size = 0.002
	_readout.font_size = 22
	_readout.modulate = Color(0.95, 0.88, 0.9)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.position = _panel.position + Vector3(0.0, 0.64, -0.012)
	_readout.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	add_child(_readout)
	_refresh_readout()
	# the passage's two thresholds, marked on the floor (12 September: "make the entrance/exit
	# floor boundary clear"): a dark strip across each mouth, on the deck, no collider
	for end in [-1.0, 1.0]:
		var strip := MeshInstance3D.new()
		strip.name = "Threshold_in" if end < 0.0 else "Threshold_out"
		var sbox := BoxMesh.new()
		sbox.size = Vector3(corridor_width + 0.30, 0.008, 0.14)
		strip.mesh = sbox
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.17, 0.15, 0.17)
		smat.roughness = 0.9
		strip.material_override = smat
		strip.position = Vector3(0.0, deck + 0.004, end * corridor_length * 0.5)
		add_child(strip)

func _amp_norm(a: float) -> float:
	return clampf(a / amplitude_max, 0.0, 1.0) if amplitude_max > 0.0 else 0.0

func _phase_norm(p: float) -> float:
	return clampf(p / PHASE_OFFSET_MAX, 0.0, 1.0)

## One variable: the shared amplitude of both walls.
func set_amplitude(a: float) -> void:
	base_amplitude = clampf(a, 0.0, amplitude_max)
	_build_corridor()
	_refresh_readout()

## The other variable: how far the right wall's phase runs ahead of the left's.
func set_phase_offset(p: float) -> void:
	phase_offset_between_walls = clampf(p, 0.0, PHASE_OFFSET_MAX)
	_build_corridor()
	_refresh_readout()

## FREEZE / run. Stops the phase advancing; the walls stay exactly where they are.
func toggle_animation() -> void:
	animate_at_runtime = not animate_at_runtime
	_update_process_state()
	_refresh_readout()

## RESET: the placement's declared amplitude, offset, phase and animation state, and the
## slider handles back where they were. The declared values are this passage's, not the room's.
func reset_declared() -> void:
	if _declared.is_empty():
		return
	base_amplitude = float(_declared.get("amplitude", base_amplitude))
	phase_offset_between_walls = float(_declared.get("phase_offset", phase_offset_between_walls))
	phase = float(_declared.get("phase", 0.0))
	animate_at_runtime = bool(_declared.get("animate", animate_at_runtime))
	if _amp_slider != null and _amp_slider.has_method("set_normalized_value"):
		_amp_slider.set_normalized_value(_amp_norm(base_amplitude))
	if _phase_slider != null and _phase_slider.has_method("set_normalized_value"):
		_phase_slider.set_normalized_value(_phase_norm(phase_offset_between_walls))
	_last_signature = ""
	_build_corridor()
	_update_process_state()
	_refresh_readout()

func _refresh_readout() -> void:
	if _readout == null:
		return
	var gaps: Array = gap_range()
	# four short lines inside the plate (12 September); the first line is what the probes read
	_readout.text = "amp %.2f m · phase offset %.2f rad\n%.1f cycles over %.0f m\nx-gap %.2f–%.2f m\n%s" % [
		base_amplitude, phase_offset_between_walls, base_frequency, corridor_length,
		float(gaps[0]), float(gaps[1]), "running" if animate_at_runtime else "frozen"]

# ── accessors (probes, readouts) ─────────────────────────────────────────────────────────

## The inward displacement of each wall at a point along the passage (0..1).
func wall_displacements(z_ratio: float) -> Array:
	return [_wave_displacement(z_ratio, phase, left_wall_frequency_multiplier, left_wall_amplitude_multiplier),
		_wave_displacement(z_ratio, phase + phase_offset_between_walls, 1.0, 1.0)]

## Separation along local X at the same Z, not shortest/normal clearance.
## Both walls move INWARD for a positive displacement.
func gap_at(z_ratio: float) -> float:
	var d: Array = wall_displacements(z_ratio)
	return corridor_width - float(d[0]) - float(d[1])

## [minimum, maximum] local-X gap, sampled at the mesh columns.
func gap_range() -> Array:
	var lo: float = INF
	var hi: float = -INF
	for col in range(columns):
		var g: float = gap_at(col / float(columns - 1))
		lo = minf(lo, g)
		hi = maxf(hi, g)
	return [lo, hi]

func contract() -> Dictionary:
	return {"amplitude": base_amplitude, "phase_offset": phase_offset_between_walls, "phase": phase,
		"frequency": base_frequency, "length": corridor_length, "width": corridor_width,
		"height": corridor_height, "animate": animate_at_runtime, "collision": enable_collision,
		"layers": wave_layers.size(), "cut": cut}

func declared() -> Dictionary:
	return _declared.duplicate()

func is_animating() -> bool:
	return animate_at_runtime

func has_wall_collision() -> bool:
	return _left_wall_shape != null and _left_wall_shape.shape != null

func readout_text() -> String:
	return _readout.text if _readout != null else ""
