extends Node3D
class_name Terrarium

# @identity
# essence: a rectangular glass terrarium tank with a thin steel frame, a recessed dark soil floor, scattered green plant prisms, white prey spheres ("rabbits"), and a larger red predator cube ("fox"). The whole assembly is a closed ecosystem visible through translucent walls. In the lab's grammar, the terrarium is the LOTKA-VOLTERRA PREDATOR-PREY SYSTEM — the canonical closed dynamical system where prey eat plants, predators eat prey, and the two populations oscillate in coupled cycles.
# desire: every population dynamics model wants a bounded substrate where the populations can be SEEN. The terrarium wants to be the architectural form of "here are predators, here are prey, here is the vegetation that feeds them, and here is the closed boundary that forces them to interact". It wants the player to count the white spheres, count the red cube, and read it as the Lotka-Volterra state vector at one instant in time.
# critical_parameter: predator_count and prey_count — together with vegetation_count, this IS the state vector of a Lotka-Volterra system at frozen time. Many rabbits + one fox reads as "early in the cycle, prey is winning". Many foxes + few rabbits reads as "the predator peak, prey is about to crash". Same tank, different snapshots of the dx/dt = αx - βxy / dy/dt = δxy - γy oscillation.
# triggers: _ready() builds tank glass walls + steel frame + soil floor + vegetation + prey spheres + predator cubes + accent stripe from exports; apply_grid_config rebuilds
# emerges: a tank with many prey and one predator reads as PREY-DOMINANT phase. A tank with several predators and few prey reads as the predator-peak. The vegetation reads as the BASE OF THE FOOD WEB. The closed glass walls read as the CONSERVATION CONSTRAINT that makes oscillation inevitable.
# needs: rectangular translucent glass tank walls [present]; steel frame edges [present]; soil floor [present]; scattered vegetation prisms [present]; prey spheres [present]; predator cube [present]; accent stripe on front top edge [present]
# relationships: sibling to petri_dish (both bound a 2D-ish substrate for a population — dish hosts a CA, terrarium hosts continuous-population coupled ODEs); cousin to fishbowl (both are GLASS containers of a small ecology — bowl is a sphere of single-population diffusion, terrarium is a box of two-species predation); peer to oscilloscope (both VISUALISE oscillation — scope shows a wave's shape, terrarium shows the steady-state of an ecological wave)
# truth: Lotka and Volterra wrote down two coupled equations in 1925-26 that say prey grow and get eaten, predators eat and starve, and the two populations chase each other in perpetual cycles. The terrarium is the lab's affirmation of those equations in physical form. You can count the spheres and cubes; the count is the value of x(t) and y(t).

## A closed terrarium hosting prey and predator cubes on a planted soil bed.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER
## of the tank footprint. The tank rests flat on a surface. The +Z face
## is the front of the tank (accent stripe along the top of that face).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var tank_width: float = 0.40
@export var tank_depth: float = 0.30
@export var tank_height: float = 0.35

@export_group("Color")
@export var glass_color: Color = Color(0.85, 0.92, 0.95, 0.30)
@export var frame_color: Color = Color(0.20, 0.20, 0.22)
@export var floor_color: Color = Color(0.30, 0.20, 0.12)
@export var vegetation_color: Color = Color(0.30, 0.65, 0.30)
@export var prey_color: Color = Color(0.85, 0.85, 0.85)
@export var predator_color: Color = Color(0.85, 0.30, 0.30)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Population")
@export_range(0, 20) var vegetation_count: int = 6
@export_range(0, 20) var prey_count: int = 4
@export_range(0, 10) var predator_count: int = 1

# ── Constants ─────────────────────────────────────────────────────────

const WALL_THICKNESS: float = 0.006
const FRAME_THICKNESS: float = 0.008
const FLOOR_THICKNESS: float = 0.018
const SOIL_INSET: float = 0.010
const PLANT_HEIGHT_BASE: float = 0.040
const PLANT_RADIUS: float = 0.012
const PREY_RADIUS: float = 0.015
const PREDATOR_HALF: float = 0.024     # half-size of predator cube
const ACCENT_STRIP_HEIGHT: float = 0.006

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_terrarium()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_terrarium()


func _read_metadata_overrides() -> void:
	if has_meta("config_tank_width"):
		tank_width = float(String(get_meta("config_tank_width")))
	if has_meta("config_tank_depth"):
		tank_depth = float(String(get_meta("config_tank_depth")))
	if has_meta("config_tank_height"):
		tank_height = float(String(get_meta("config_tank_height")))
	if has_meta("config_glass_color"):
		glass_color = _parse_color(String(get_meta("config_glass_color")), glass_color)
	if has_meta("config_frame_color"):
		frame_color = _parse_color(String(get_meta("config_frame_color")), frame_color)
	if has_meta("config_floor_color"):
		floor_color = _parse_color(String(get_meta("config_floor_color")), floor_color)
	if has_meta("config_vegetation_color"):
		vegetation_color = _parse_color(String(get_meta("config_vegetation_color")), vegetation_color)
	if has_meta("config_prey_color"):
		prey_color = _parse_color(String(get_meta("config_prey_color")), prey_color)
	if has_meta("config_predator_color"):
		predator_color = _parse_color(String(get_meta("config_predator_color")), predator_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_vegetation_count"):
		vegetation_count = int(String(get_meta("config_vegetation_count")))
	if has_meta("config_prey_count"):
		prey_count = int(String(get_meta("config_prey_count")))
	if has_meta("config_predator_count"):
		predator_count = int(String(get_meta("config_predator_count")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_terrarium() -> void:
	_built = true
	_build_floor()
	_build_glass_walls()
	_build_soil()
	_build_steel_frame()
	_build_vegetation()
	_build_prey()
	_build_predators()
	_build_accent_strip()


func _build_floor() -> void:
	# Outer floor slab (the "tank bottom") — slightly darker than soil, structural.
	var slab := MeshInstance3D.new()
	slab.name = "TankFloor"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(tank_width, FLOOR_THICKNESS, tank_depth)
	slab.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(floor_color.r * 0.55, floor_color.g * 0.55, floor_color.b * 0.55)
	mat.roughness = 0.85
	mat.metallic = 0.05
	slab.material_override = mat
	slab.position = Vector3(0.0, FLOOR_THICKNESS * 0.5, 0.0)
	add_child(slab)


func _build_soil() -> void:
	# Inset soil bed inside the tank.
	var soil := MeshInstance3D.new()
	soil.name = "SoilBed"
	var inner_w: float = max(0.001, tank_width - 2.0 * (WALL_THICKNESS + SOIL_INSET))
	var inner_d: float = max(0.001, tank_depth - 2.0 * (WALL_THICKNESS + SOIL_INSET))
	var soil_h: float = 0.020
	var mesh := BoxMesh.new()
	mesh.size = Vector3(inner_w, soil_h, inner_d)
	soil.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = floor_color
	mat.roughness = 0.95
	mat.metallic = 0.0
	soil.material_override = mat
	soil.position = Vector3(0.0, FLOOR_THICKNESS + soil_h * 0.5, 0.0)
	add_child(soil)


func _build_glass_walls() -> void:
	# 4 side walls + 1 top lid (the bottom is the floor slab).
	var root := Node3D.new()
	root.name = "Glass"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = Color(glass_color.r, glass_color.g, glass_color.b)
	mat.emission_energy_multiplier = 0.08
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var wall_y: float = FLOOR_THICKNESS + tank_height * 0.5

	# Front (+Z) and back (-Z) walls.
	var fb_sizes: Array = [Vector3(tank_width, tank_height, WALL_THICKNESS)]
	for s in fb_sizes:
		var front := MeshInstance3D.new()
		front.name = "WallFront"
		var fmesh := BoxMesh.new()
		fmesh.size = s
		front.mesh = fmesh
		front.material_override = mat
		front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		front.position = Vector3(0.0, wall_y, tank_depth * 0.5 - WALL_THICKNESS * 0.5)
		root.add_child(front)

		var back := MeshInstance3D.new()
		back.name = "WallBack"
		var bmesh := BoxMesh.new()
		bmesh.size = s
		back.mesh = bmesh
		back.material_override = mat
		back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		back.position = Vector3(0.0, wall_y, -tank_depth * 0.5 + WALL_THICKNESS * 0.5)
		root.add_child(back)

	# Left (-X) and right (+X) walls.
	var lr_size: Vector3 = Vector3(WALL_THICKNESS, tank_height, tank_depth)
	var left := MeshInstance3D.new()
	left.name = "WallLeft"
	var lmesh := BoxMesh.new()
	lmesh.size = lr_size
	left.mesh = lmesh
	left.material_override = mat
	left.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	left.position = Vector3(-tank_width * 0.5 + WALL_THICKNESS * 0.5, wall_y, 0.0)
	root.add_child(left)

	var right := MeshInstance3D.new()
	right.name = "WallRight"
	var rmesh := BoxMesh.new()
	rmesh.size = lr_size
	right.mesh = rmesh
	right.material_override = mat
	right.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	right.position = Vector3(tank_width * 0.5 - WALL_THICKNESS * 0.5, wall_y, 0.0)
	root.add_child(right)

	# Top (lid).
	var top := MeshInstance3D.new()
	top.name = "WallTop"
	var tmesh := BoxMesh.new()
	tmesh.size = Vector3(tank_width, WALL_THICKNESS, tank_depth)
	top.mesh = tmesh
	top.material_override = mat
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top.position = Vector3(0.0, FLOOR_THICKNESS + tank_height - WALL_THICKNESS * 0.5, 0.0)
	root.add_child(top)


func _build_steel_frame() -> void:
	# Thin steel strips along the 12 edges of the tank cuboid.
	var root := Node3D.new()
	root.name = "Frame"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.4
	mat.metallic = 0.7

	var w: float = tank_width
	var d: float = tank_depth
	var h: float = tank_height
	var t: float = FRAME_THICKNESS
	var y_base: float = FLOOR_THICKNESS
	var y_top: float = FLOOR_THICKNESS + h

	# 4 vertical edges (corners).
	var corners: Array = [
		Vector3(-w * 0.5, 0.0, -d * 0.5),
		Vector3(w * 0.5, 0.0, -d * 0.5),
		Vector3(-w * 0.5, 0.0, d * 0.5),
		Vector3(w * 0.5, 0.0, d * 0.5),
	]
	for i in range(corners.size()):
		var p: Vector3 = corners[i]
		var bar := MeshInstance3D.new()
		bar.name = "FrameV_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(t, h, t)
		bar.mesh = bm
		bar.material_override = mat
		bar.position = Vector3(p.x, y_base + h * 0.5, p.z)
		root.add_child(bar)

	# 4 horizontal edges along X at bottom and top.
	var x_y_pairs: Array = [
		[-d * 0.5, y_base],
		[d * 0.5, y_base],
		[-d * 0.5, y_top],
		[d * 0.5, y_top],
	]
	for i in range(x_y_pairs.size()):
		var entry: Array = x_y_pairs[i]
		var z_pos: float = entry[0]
		var y_pos: float = entry[1]
		var bar := MeshInstance3D.new()
		bar.name = "FrameX_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(w, t, t)
		bar.mesh = bm
		bar.material_override = mat
		bar.position = Vector3(0.0, y_pos, z_pos)
		root.add_child(bar)

	# 4 horizontal edges along Z at bottom and top.
	var z_y_pairs: Array = [
		[-w * 0.5, y_base],
		[w * 0.5, y_base],
		[-w * 0.5, y_top],
		[w * 0.5, y_top],
	]
	for i in range(z_y_pairs.size()):
		var entry2: Array = z_y_pairs[i]
		var x_pos: float = entry2[0]
		var y_pos2: float = entry2[1]
		var bar := MeshInstance3D.new()
		bar.name = "FrameZ_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(t, t, d)
		bar.mesh = bm
		bar.material_override = mat
		bar.position = Vector3(x_pos, y_pos2, 0.0)
		root.add_child(bar)


func _build_vegetation() -> void:
	if vegetation_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Vegetation"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = vegetation_color
	mat.roughness = 0.75
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = vegetation_color
	mat.emission_energy_multiplier = 0.18
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var inner_w: float = max(0.001, tank_width - 2.0 * (WALL_THICKNESS + SOIL_INSET) - PLANT_RADIUS * 2.0)
	var inner_d: float = max(0.001, tank_depth - 2.0 * (WALL_THICKNESS + SOIL_INSET) - PLANT_RADIUS * 2.0)
	var soil_top: float = FLOOR_THICKNESS + 0.020

	for i in range(vegetation_count):
		var pos: Vector2 = _hash_point(i, 1009, inner_w, inner_d)
		var plant := MeshInstance3D.new()
		plant.name = "Plant_%d" % i
		var pm := PrismMesh.new()
		var h: float = PLANT_HEIGHT_BASE * (0.7 + _hash_fraction(i, 3001) * 0.6)
		pm.size = Vector3(PLANT_RADIUS * 2.0, h, PLANT_RADIUS * 2.0)
		plant.mesh = pm
		plant.material_override = mat
		plant.position = Vector3(pos.x, soil_top + h * 0.5, pos.y)
		root.add_child(plant)


func _build_prey() -> void:
	if prey_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Prey"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = prey_color
	mat.roughness = 0.6
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = prey_color
	mat.emission_energy_multiplier = 0.1
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var inner_w: float = max(0.001, tank_width - 2.0 * (WALL_THICKNESS + SOIL_INSET) - PREY_RADIUS * 2.0)
	var inner_d: float = max(0.001, tank_depth - 2.0 * (WALL_THICKNESS + SOIL_INSET) - PREY_RADIUS * 2.0)
	var soil_top: float = FLOOR_THICKNESS + 0.020

	for i in range(prey_count):
		var pos: Vector2 = _hash_point(i, 4099, inner_w, inner_d)
		var prey := MeshInstance3D.new()
		prey.name = "Prey_%d" % i
		var sm := SphereMesh.new()
		sm.radius = PREY_RADIUS
		sm.height = PREY_RADIUS * 2.0
		sm.radial_segments = 12
		sm.rings = 8
		prey.mesh = sm
		prey.material_override = mat
		prey.position = Vector3(pos.x, soil_top + PREY_RADIUS, pos.y)
		root.add_child(prey)


func _build_predators() -> void:
	if predator_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Predators"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = predator_color
	mat.roughness = 0.55
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = predator_color
	mat.emission_energy_multiplier = 0.22
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var inner_w: float = max(0.001, tank_width - 2.0 * (WALL_THICKNESS + SOIL_INSET) - PREDATOR_HALF * 2.0)
	var inner_d: float = max(0.001, tank_depth - 2.0 * (WALL_THICKNESS + SOIL_INSET) - PREDATOR_HALF * 2.0)
	var soil_top: float = FLOOR_THICKNESS + 0.020

	for i in range(predator_count):
		var pos: Vector2 = _hash_point(i, 7901, inner_w, inner_d)
		var pred := MeshInstance3D.new()
		pred.name = "Predator_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(PREDATOR_HALF * 2.0, PREDATOR_HALF * 2.0, PREDATOR_HALF * 2.0)
		pred.mesh = bm
		pred.material_override = mat
		pred.position = Vector3(pos.x, soil_top + PREDATOR_HALF, pos.y)
		root.add_child(pred)


func _build_accent_strip() -> void:
	# Thin emissive band along the top of the front (+Z) face.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var bm := BoxMesh.new()
	bm.size = Vector3(tank_width, ACCENT_STRIP_HEIGHT, 0.004)
	strip.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, FLOOR_THICKNESS + tank_height - ACCENT_STRIP_HEIGHT * 0.5, tank_depth * 0.5 + 0.003)
	add_child(strip)


# ── Helpers ───────────────────────────────────────────────────────────

func _hash_point(i: int, salt: int, span_x: float, span_z: float) -> Vector2:
	# Deterministic 2D point in [-span_x/2, +span_x/2] x [-span_z/2, +span_z/2].
	var hx: int = ((i + 1) * 73856093) ^ (salt * 19349663)
	var hz: int = ((i + 1) * 83492791) ^ (salt * 2654435761)
	hx = hx & 0x7fffffff
	hz = hz & 0x7fffffff
	var fx: float = float(hx % 1000) / 1000.0
	var fz: float = float(hz % 1000) / 1000.0
	return Vector2((fx - 0.5) * span_x, (fz - 0.5) * span_z)


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
