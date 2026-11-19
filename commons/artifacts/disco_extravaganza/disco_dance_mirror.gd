extends Node3D
## Massive Studio-54 style full-wall live planar dance mirror for Care Unit Model B.
## Uses an exact off-axis frustum SubViewport + Camera3D sharing the live world_3d.
## Reserves layer 19 for the glass pane so layer 20 (Care Unit Model B's head and
## headwear) renders crisply in the reflection.

const WIDTH := 5.6
const HEIGHT := 3.15
const CENTRE := 1.68
# Layer 19 holds SuperDragOutfit's head/crown and layer 20 holds CareBody's head;
# place the mirror glass on layer 18 so BOTH heads render crisply in the reflection!
const PANE_LAYER := 18
const ACTIVE_DISTANCE := 18.0

var viewport: SubViewport
var reflection: Camera3D
var _pane: MeshInstance3D
var _bulbs: Array[StandardMaterial3D] = []
var _frame_trim_mats: Array[StandardMaterial3D] = []

const BULB_PALETTE := [
	Color("ff44c8"), Color("00f5ff"), Color("ffe64d"), Color("ffffff"), Color("b855ff"),
]

func _ready() -> void:
	name = "DiscoDanceMirror"
	process_priority = 50
	_build_frame_and_bulbs()
	_build_reflection_surface()

func _build_frame_and_bulbs() -> void:
	var chrome := StandardMaterial3D.new()
	chrome.albedo_color = Color("241b30")
	chrome.metallic = 0.78
	chrome.roughness = 0.22

	var trim_gold := StandardMaterial3D.new()
	trim_gold.albedo_color = Color("ffd966")
	trim_gold.metallic = 0.85
	trim_gold.roughness = 0.18
	trim_gold.emission_enabled = true
	trim_gold.emission = Color("ffbf36")
	trim_gold.emission_energy_multiplier = 0.45
	_frame_trim_mats.append(trim_gold)

	# Heavy dark chrome mirror backing
	_box("MirrorBack", Vector3(0, CENTRE, -0.11), Vector3(WIDTH + 0.36, HEIGHT + 0.36, 0.16), chrome, true)
	# Frame rails
	for side in [-1.0, 1.0]:
		_box("SideFrame_%d" % int(side + 2), Vector3(side * (WIDTH * 0.5 + 0.10), CENTRE, 0.0),
			Vector3(0.20, HEIGHT + 0.40, 0.18), chrome)
		_box("SideTrim_%d" % int(side + 2), Vector3(side * (WIDTH * 0.5 + 0.015), CENTRE, 0.085),
			Vector3(0.03, HEIGHT + 0.06, 0.03), trim_gold)
	for sy in [CENTRE - HEIGHT * 0.5 - 0.10, CENTRE + HEIGHT * 0.5 + 0.10]:
		_box("HorizFrame_%d" % int(sy * 10), Vector3(0, sy, 0.0), Vector3(WIDTH + 0.40, 0.20, 0.18), chrome)
		_box("HorizTrim_%d" % int(sy * 10), Vector3(0, sy + (-0.08 if sy > CENTRE else 0.08), 0.085),
			Vector3(WIDTH + 0.06, 0.03, 0.03), trim_gold)

	# 44 Chasing Vanity Marquee Bulbs ringing all 4 edges of the mirror!
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.044
	bulb_mesh.height = 0.088
	bulb_mesh.radial_segments = 12
	bulb_mesh.rings = 8
	var bulb_positions: Array[Vector3] = []
	# Bottom & Top rows (13 bulbs each)
	for i in range(13):
		var bx := lerpf(-WIDTH * 0.5 - 0.09, WIDTH * 0.5 + 0.09, float(i) / 12.0)
		bulb_positions.append(Vector3(bx, CENTRE + HEIGHT * 0.5 + 0.10, 0.105))
	# Right side going down (9 bulbs)
	for i in range(1, 10):
		var by := lerpf(CENTRE + HEIGHT * 0.5 + 0.10, CENTRE - HEIGHT * 0.5 - 0.10, float(i) / 10.0)
		bulb_positions.append(Vector3(WIDTH * 0.5 + 0.10, by, 0.105))
	# Bottom row right-to-left (13 bulbs)
	for i in range(13):
		var bx := lerpf(WIDTH * 0.5 + 0.09, -WIDTH * 0.5 - 0.09, float(i) / 12.0)
		bulb_positions.append(Vector3(bx, CENTRE - HEIGHT * 0.5 - 0.10, 0.105))
	# Left side going up (9 bulbs)
	for i in range(1, 10):
		var by := lerpf(CENTRE - HEIGHT * 0.5 - 0.10, CENTRE + HEIGHT * 0.5 + 0.10, float(i) / 10.0)
		bulb_positions.append(Vector3(-WIDTH * 0.5 - 0.10, by, 0.105))

	for i in range(bulb_positions.size()):
		var b := MeshInstance3D.new()
		b.name = "VanityBulb_%d" % i
		b.mesh = bulb_mesh
		b.position = bulb_positions[i]
		var mat := StandardMaterial3D.new()
		var col: Color = BULB_PALETTE[i % BULB_PALETTE.size()]
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.6
		b.material_override = mat
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(b)
		_bulbs.append(mat)

	# Glowing Marquee Crown above the mirror
	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color("2b0d42")
	crown_mat.emission_enabled = true
	crown_mat.emission = Color("ff2fa6")
	crown_mat.emission_energy_multiplier = 0.25
	_box("MirrorMarqueeBox", Vector3(0, CENTRE + HEIGHT * 0.5 + 0.44, -0.02), Vector3(4.8, 0.44, 0.14), crown_mat)
	var sign := Label3D.new()
	sign.text = "★  CARE UNIT MODEL B  •  DISCO DANCE MIRROR  ★"
	sign.font_size = 52
	sign.pixel_size = 0.0026
	sign.outline_size = 7
	sign.modulate = Color("fff5c2")
	sign.position = Vector3(0, CENTRE + HEIGHT * 0.5 + 0.44, 0.07)
	add_child(sign)

	# Warm flattering vanity stage fill lights for Care Unit Model B's reflection
	for side in [-1.0, 1.0]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(side * 2.1, 2.55, 1.35)
		lamp.light_color = Color("ffeef8")
		lamp.light_energy = 1.05
		lamp.omni_range = 7.5
		lamp.shadow_enabled = false
		lamp.distance_fade_enabled = true
		lamp.distance_fade_begin = 14.0
		lamp.distance_fade_length = 4.0
		add_child(lamp)

func _build_reflection_surface() -> void:
	viewport = SubViewport.new()
	viewport.name = "MirrorViewport"
	viewport.size = Vector2i(1024, roundi(1024.0 * HEIGHT / WIDTH))
	viewport.world_3d = get_world_3d()
	viewport.use_xr = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)

	reflection = Camera3D.new()
	reflection.name = "MirrorReflectionCamera"
	var pane_mask := 1 << (PANE_LAYER - 1)
	# Include layer 20 (Care Unit Model B's head & pearl crown!) while excluding layer 19 (mirror pane).
	reflection.cull_mask = ((1 << 20) - 1) & ~pane_mask
	reflection.keep_aspect = Camera3D.KEEP_HEIGHT
	viewport.add_child(reflection)
	reflection.current = true

	_pane = MeshInstance3D.new()
	_pane.name = "DiscoLookingGlass"
	var quad := QuadMesh.new()
	quad.size = Vector2(WIDTH, HEIGHT)
	_pane.mesh = quad
	_pane.position = Vector3(0, CENTRE, 0.02)
	_pane.layers = pane_mask
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.albedo_texture = viewport.get_texture()
	# Reverse horizontal UV for true mirror parity.
	mat.uv1_scale = Vector3(-1.0, 1.0, 1.0)
	mat.uv1_offset = Vector3(1.0, 0.0, 0.0)
	_pane.material_override = mat
	_pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pane)

func pulse_bulbs(beat: float, kick: float) -> void:
	var chase := int(floor(beat * 4.0))
	for i in range(_bulbs.size()):
		var mat := _bulbs[i]
		var lit := ((i + chase) % 3) == 0
		var col: Color = BULB_PALETTE[(i + int(floor(beat * 0.5))) % BULB_PALETTE.size()]
		mat.albedo_color = col
		mat.emission = col
		mat.emission_energy_multiplier = (2.6 + kick * 1.4) if lit else (0.45 + kick * 0.5)

func _process(_delta: float) -> void:
	var viewer := get_viewport().get_camera_3d()
	if not is_instance_valid(viewer) or viewer == reflection:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var local_eye := to_local(viewer.get_camera_transform().origin)
	var active := is_visible_in_tree() and local_eye.z > 0.14 and local_eye.length() < ACTIVE_DISTANCE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if not active:
		return
	reflection.current = true
	if viewer.environment != null:
		reflection.environment = viewer.environment
	else:
		var game := get_tree().get_first_node_in_group("void_game")
		if is_instance_valid(game) and is_instance_valid(game.get("atmosphere")):
			reflection.environment = game.atmosphere.get("environment")
	var mirror_basis := global_basis.orthonormalized()
	var reflected_position := to_global(Vector3(local_eye.x, local_eye.y, -local_eye.z))
	reflection.global_transform = Transform3D(mirror_basis * Basis(Vector3.UP, PI), reflected_position)
	var unit := global_basis.y.length()
	var near_d := maxf(0.10, local_eye.z * unit)
	reflection.set_frustum(HEIGHT * unit, Vector2(local_eye.x, CENTRE - local_eye.y) * unit, near_d, near_d + 40.0 * unit)

func _box(label: String, at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	if solid:
		mi.create_convex_collision()
	return mi
