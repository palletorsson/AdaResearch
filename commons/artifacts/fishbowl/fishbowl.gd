extends Node3D
class_name Fishbowl

# @identity
# essence: a small spherical-ish glass bowl with translucent walls, a faint-blue water volume filling most of the interior, several small orange "fish" particles drifting inside, a few rising bubbles, and a fading trail of dots showing where ONE fish has wandered. In the lab's grammar, the fishbowl is the BROWNIAN MOTION / RANDOM WALK CHAMBER — a confined fluid where particles take small, uncorrelated, hash-deterministic jumps and trace out the diffusive paths Robert Brown saw in pollen.
# desire: every random-walk demo wants to be SEEN as a path, not just a number. The fishbowl wants to be the architectural form of "here is a particle, here is the bounded fluid it moves in, and here is the trail of all the places it has been". It wants the player to follow the trail of one fish and read it as a continuous-time random walk.
# critical_parameter: fish_trail_visible — together with trail_dot_count, this IS the Brownian-motion statement of the prop. When true, ONE fish leaves a visible chain of fading dots: each dot offset from the previous by a hash-deterministic small jitter — a discrete sample of dW. When false, the fish are just present; their motion is implicit. Same bowl, two readings: "particles in a fluid" vs "particles WITH visible diffusive history".
# triggers: _ready() builds bowl + water + fish + trail + bubbles + accent ring from exports; apply_grid_config rebuilds
# emerges: a bowl with a long trail reads as MEMORY OF A WALK. A bowl with many fish but no trail reads as DIFFUSION-IN-EQUILIBRIUM. The bubbles rising reads as DIRECTED MOTION (gravity), in contrast to the random walk's UNDIRECTED MOTION (kT) — the prop quietly distinguishes drift from diffusion.
# needs: spherical glass bowl [present]; interior water volume [present]; small fish spheres at deterministic positions [present]; one fish's random-walk trail [present when fish_trail_visible]; rising bubble spheres [present]; accent rim ring [present]
# relationships: sibling to terrarium (both are GLASS containers of small ecology — terrarium is rectangular and predator-prey, fishbowl is spherical and single-particle random walk); cousin to petri_dish (both bound a substrate where motion is visible — dish hosts discrete grid-CA, bowl hosts continuous Brownian); peer to oscilloscope (scope shows a wave's deterministic curve, fishbowl shows a particle's STOCHASTIC curve)
# truth: Brownian motion is what you get when small particles in a fluid are kicked by molecules thermally. Mathematically it is a Wiener process — the path has independent increments and is nowhere differentiable. The fishbowl is the lab's plainspoken version of that: a bowl with a fish, and a chain of dots saying "the fish has been here, and here, and here".

## A small fishbowl with fish and a Brownian-walk trail.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER
## of the bowl. The bowl sits on a surface. Bubbles rise along +Y. The
## trail belongs to the FIRST fish and shows a hash-deterministic walk.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var bowl_radius: float = 0.18
@export var bowl_height: float = 0.22

@export_group("Color")
@export var glass_color: Color = Color(0.85, 0.92, 0.95, 0.30)
@export_range(0.0, 1.5, 0.01) var glass_emission: float = 0.10
@export var water_color: Color = Color(0.55, 0.78, 0.95, 0.55)
@export_range(0.0, 1.0, 0.01) var water_height_fraction: float = 0.75
@export var fish_color: Color = Color(0.95, 0.65, 0.20)
@export var trail_color: Color = Color(0.95, 0.65, 0.20, 0.40)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Population")
@export_range(0, 20) var fish_count: int = 5
@export var fish_trail_visible: bool = true
@export_range(1, 32) var trail_dot_count: int = 8
@export_range(0, 12) var bubble_count: int = 3

# ── Constants ─────────────────────────────────────────────────────────

const FISH_RADIUS: float = 0.008
const BUBBLE_RADIUS: float = 0.004
const TRAIL_DOT_BASE_RADIUS: float = 0.005
const TRAIL_STEP_SCALE: float = 0.018       # base jump distance per trail step
const ACCENT_STRIP_HEIGHT: float = 0.005

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_fishbowl()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_fishbowl()


func _read_metadata_overrides() -> void:
	if has_meta("config_bowl_radius"):
		bowl_radius = float(str(get_meta("config_bowl_radius")))
	if has_meta("config_bowl_height"):
		bowl_height = float(str(get_meta("config_bowl_height")))
	if has_meta("config_glass_color"):
		glass_color = _parse_color(str(get_meta("config_glass_color")), glass_color)
	if has_meta("config_glass_emission"):
		glass_emission = float(str(get_meta("config_glass_emission")))
	if has_meta("config_water_color"):
		water_color = _parse_color(str(get_meta("config_water_color")), water_color)
	if has_meta("config_water_height_fraction"):
		water_height_fraction = float(str(get_meta("config_water_height_fraction")))
	if has_meta("config_fish_color"):
		fish_color = _parse_color(str(get_meta("config_fish_color")), fish_color)
	if has_meta("config_trail_color"):
		trail_color = _parse_color(str(get_meta("config_trail_color")), trail_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_fish_count"):
		fish_count = int(str(get_meta("config_fish_count")))
	if has_meta("config_fish_trail_visible"):
		var fv := str(get_meta("config_fish_trail_visible")).to_lower()
		fish_trail_visible = fv in ["true", "1", "yes", "on"]
	if has_meta("config_trail_dot_count"):
		trail_dot_count = int(str(get_meta("config_trail_dot_count")))
	if has_meta("config_bubble_count"):
		bubble_count = int(str(get_meta("config_bubble_count")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_fishbowl() -> void:
	_built = true
	_build_glass_bowl()
	_build_water()
	_build_fish()
	if fish_trail_visible:
		_build_trail()
	_build_bubbles()
	_build_rim_ring()


func _build_glass_bowl() -> void:
	# Spherical-ish bowl. Use a SphereMesh scaled vertically; position so bottom touches y=0.
	var bowl := MeshInstance3D.new()
	bowl.name = "Bowl"
	var mesh := SphereMesh.new()
	mesh.radius = bowl_radius
	mesh.height = bowl_radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 14
	bowl.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = Color(glass_color.r, glass_color.g, glass_color.b)
	mat.emission_energy_multiplier = glass_emission
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	bowl.material_override = mat
	bowl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Scale vertically so the bowl is squashed to bowl_height; bottom touches origin.
	var y_scale: float = (bowl_height) / (bowl_radius * 2.0)
	bowl.scale = Vector3(1.0, y_scale, 1.0)
	# After scaling, sphere center sits at bowl_radius*y_scale = bowl_height/2.
	bowl.position = Vector3(0.0, bowl_height * 0.5, 0.0)
	add_child(bowl)


func _build_water() -> void:
	# Interior water — a smaller sphere scaled vertically, filling to water_height_fraction.
	var water := MeshInstance3D.new()
	water.name = "Water"
	var mesh := SphereMesh.new()
	var inner_r: float = bowl_radius * 0.92
	mesh.radius = inner_r
	mesh.height = inner_r * 2.0
	mesh.radial_segments = 22
	mesh.rings = 12
	water.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = water_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic = 0.05
	mat.emission_enabled = true
	mat.emission = Color(water_color.r, water_color.g, water_color.b)
	mat.emission_energy_multiplier = 0.08
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Scale vertically and shift so water surface sits at fraction of bowl_height.
	var wf: float = clampf(water_height_fraction, 0.0, 1.0)
	var water_y_scale: float = (bowl_height * wf) / (inner_r * 2.0)
	water.scale = Vector3(0.96, water_y_scale, 0.96)
	water.position = Vector3(0.0, bowl_height * wf * 0.5, 0.0)
	add_child(water)


func _build_fish() -> void:
	if fish_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Fish"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = fish_color
	mat.roughness = 0.5
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = fish_color
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	for i in range(fish_count):
		var pos: Vector3 = _fish_position(i)
		var fish := MeshInstance3D.new()
		fish.name = "Fish_%d" % i
		var sm := SphereMesh.new()
		sm.radius = FISH_RADIUS
		sm.height = FISH_RADIUS * 2.0
		sm.radial_segments = 10
		sm.rings = 6
		fish.mesh = sm
		fish.material_override = mat
		fish.position = pos
		root.add_child(fish)


func _build_trail() -> void:
	if trail_dot_count <= 0 or fish_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Trail"
	add_child(root)

	var start_pos: Vector3 = _fish_position(0)
	var current: Vector3 = start_pos

	var n: int = trail_dot_count
	for i in range(n):
		# Each trail dot is a hash-deterministic jitter from the previous, simulating a random walk step.
		var dx: float = (_hash_fraction(i + 1, 12347) - 0.5) * 2.0 * TRAIL_STEP_SCALE
		var dy: float = (_hash_fraction(i + 1, 23561) - 0.5) * 2.0 * TRAIL_STEP_SCALE
		var dz: float = (_hash_fraction(i + 1, 31627) - 0.5) * 2.0 * TRAIL_STEP_SCALE
		current = current + Vector3(dx, dy, dz)
		# Clamp inside the water volume (rough sphere of inner radius * water_height_fraction).
		current = _clamp_inside_water(current)

		var dot := MeshInstance3D.new()
		dot.name = "TrailDot_%d" % i
		var sm := SphereMesh.new()
		# Earlier dots are slightly larger; later dots fade in radius.
		var t_norm: float = float(i) / float(max(1, n - 1))
		var r: float = TRAIL_DOT_BASE_RADIUS * (1.0 - 0.55 * t_norm)
		sm.radius = max(0.0015, r)
		sm.height = sm.radius * 2.0
		sm.radial_segments = 8
		sm.rings = 4
		dot.mesh = sm

		var mat := StandardMaterial3D.new()
		# Fade alpha based on position along trail.
		var fade: float = 1.0 - 0.65 * t_norm
		var c: Color = Color(trail_color.r, trail_color.g, trail_color.b, max(0.05, trail_color.a * fade))
		mat.albedo_color = c
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(trail_color.r, trail_color.g, trail_color.b)
		mat.emission_energy_multiplier = 1.0 * fade
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		dot.material_override = mat
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dot.position = current
		root.add_child(dot)


func _build_bubbles() -> void:
	if bubble_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Bubbles"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.97, 1.0, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.97, 1.0)
	mat.emission_energy_multiplier = 0.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var wf: float = clampf(water_height_fraction, 0.0, 1.0)
	var water_max_y: float = bowl_height * wf

	for i in range(bubble_count):
		var fx: float = (_hash_fraction(i, 5557) - 0.5)
		var fz: float = (_hash_fraction(i, 6661) - 0.5)
		# Bubbles sit on a vertical column inside the water at a hash-determined x/z.
		var lateral_scale: float = bowl_radius * 0.45
		var height_t: float = _hash_fraction(i, 7771)        # 0..1
		var x: float = fx * lateral_scale
		var z: float = fz * lateral_scale
		var y: float = water_max_y * (0.15 + 0.7 * height_t)
		var b := MeshInstance3D.new()
		b.name = "Bubble_%d" % i
		var sm := SphereMesh.new()
		sm.radius = BUBBLE_RADIUS * (0.7 + _hash_fraction(i, 8881) * 0.6)
		sm.height = sm.radius * 2.0
		sm.radial_segments = 8
		sm.rings = 5
		b.mesh = sm
		b.material_override = mat
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.position = Vector3(x, y, z)
		root.add_child(b)


func _build_rim_ring() -> void:
	# Thin emissive accent ring at the top rim of the bowl.
	var ring := MeshInstance3D.new()
	ring.name = "AccentRim"
	var mesh := TorusMesh.new()
	mesh.inner_radius = bowl_radius * 0.85
	mesh.outer_radius = bowl_radius * 0.95
	ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0.0, bowl_height - 0.004, 0.0)
	add_child(ring)


# ── Helpers ───────────────────────────────────────────────────────────

func _fish_position(i: int) -> Vector3:
	# Deterministic position spread inside the water sphere.
	var wf: float = clampf(water_height_fraction, 0.05, 1.0)
	var lateral_scale: float = bowl_radius * 0.55
	var fx: float = (_hash_fraction(i, 11117) - 0.5) * 2.0
	var fz: float = (_hash_fraction(i, 22227) - 0.5) * 2.0
	var fy: float = _hash_fraction(i, 33337)
	var x: float = fx * lateral_scale
	var z: float = fz * lateral_scale
	var y: float = bowl_height * wf * (0.20 + 0.65 * fy)
	return Vector3(x, y, z)


func _clamp_inside_water(p: Vector3) -> Vector3:
	# Keep trail dots inside a rough cylinder/sphere region of the water.
	var wf: float = clampf(water_height_fraction, 0.05, 1.0)
	var max_lat: float = bowl_radius * 0.70
	var lat: float = Vector2(p.x, p.z).length()
	var x: float = p.x
	var z: float = p.z
	if lat > max_lat:
		var s: float = max_lat / lat
		x = p.x * s
		z = p.z * s
	var y: float = clampf(p.y, bowl_height * 0.08, bowl_height * wf * 0.95)
	return Vector3(x, y, z)


func _hash_fraction(i: int, salt: int) -> float:
	var h: int = ((i + 1) * 73856093) ^ (salt * 19349663)
	h = h & 0x7fffffff
	return float(h % 1000) / 1000.0


func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
