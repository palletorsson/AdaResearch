extends Node3D
class_name TerrainErosion

## Hydraulic erosion on a procedural heightmap — generates terrain with layered
## sin-wave noise, then simulates water droplets flowing downhill carrying sediment.
## ImmediateMesh surface colored by altitude bands: water, beach, grass, rock, snow.

# --- Configuration ---

@export var terrain_size: float = 0.8
@export var grid_res: int = 48
@export var height_scale: float = 0.25
@export var droplet_count: int = 800
@export var droplet_lifetime: int = 64
@export var erosion_rate: float = 0.3
@export var deposition_rate: float = 0.3
@export var evaporation_rate: float = 0.02
@export var min_sediment_capacity: float = 0.01
@export var sediment_capacity_factor: float = 4.0
@export var inertia: float = 0.3
@export var gravity: float = 4.0

# --- Height bands ---

var color_water: Color = Color(0.15, 0.35, 0.75)
var color_beach: Color = Color(0.82, 0.76, 0.55)
var color_grass: Color = Color(0.3, 0.6, 0.2)
var color_forest: Color = Color(0.18, 0.42, 0.14)
var color_rock: Color = Color(0.52, 0.5, 0.48)
var color_snow: Color = Color(0.95, 0.96, 0.98)

# --- Internal ---

var _heightmap: PackedFloat32Array
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _height_min: float = 0.0
var _height_max: float = 1.0
var _water_level: float = 0.0

# --- Nodes ---

var _surface_mesh: MeshInstance3D
var _title_label: Label3D
var _info_label: Label3D


func _ready() -> void:
	_rng.seed = 42
	_generate_heightmap()
	_erode()
	_compute_height_range()
	_water_level = _height_min + (_height_max - _height_min) * 0.22
	_create_surface()
	_create_labels()


# --- Heightmap generation (layered sin waves as Perlin substitute) ---

func _generate_heightmap() -> void:
	_heightmap = PackedFloat32Array()
	_heightmap.resize(grid_res * grid_res)

	# Octave parameters: [freq_x, freq_y, phase_x, phase_y, amplitude]
	var octaves: Array = []
	var amp: float = 1.0
	var freq: float = 2.0
	for i in range(6):
		var px = _rng.randf() * TAU
		var py = _rng.randf() * TAU
		octaves.append([freq, freq * (0.9 + _rng.randf() * 0.2), px, py, amp])
		amp *= 0.5
		freq *= 2.05

	for j in range(grid_res):
		for i in range(grid_res):
			var nx: float = float(i) / float(grid_res - 1)
			var ny: float = float(j) / float(grid_res - 1)
			var h: float = 0.0
			for oct in octaves:
				var fx: float = oct[0]
				var fy: float = oct[1]
				var px: float = oct[2]
				var py: float = oct[3]
				var a: float = oct[4]
				h += a * sin(nx * fx + px) * sin(ny * fy + py)
				h += a * 0.5 * cos(nx * fx * 1.7 + py) * sin(ny * fy * 1.3 + px)
			# Edge falloff — island shape
			var dx: float = nx - 0.5
			var dy: float = ny - 0.5
			var dist: float = sqrt(dx * dx + dy * dy) * 2.0
			var falloff: float = clampf(1.0 - dist * dist, 0.0, 1.0)
			h *= falloff
			_heightmap[j * grid_res + i] = h


# --- Hydraulic erosion ---

func _erode() -> void:
	for _drop in range(droplet_count):
		_simulate_droplet()


func _simulate_droplet() -> void:
	# Random starting position
	var pos_x: float = _rng.randf() * (grid_res - 2) + 0.5
	var pos_y: float = _rng.randf() * (grid_res - 2) + 0.5
	var dir_x: float = 0.0
	var dir_y: float = 0.0
	var speed: float = 1.0
	var water: float = 1.0
	var sediment: float = 0.0

	for _step in range(droplet_lifetime):
		var ix: int = int(pos_x)
		var iy: int = int(pos_y)
		if ix < 1 or ix >= grid_res - 2 or iy < 1 or iy >= grid_res - 2:
			break

		# Bilinear interpolation offsets
		var fx: float = pos_x - float(ix)
		var fy: float = pos_y - float(iy)

		# Heights at corners
		var h00: float = _heightmap[iy * grid_res + ix]
		var h10: float = _heightmap[iy * grid_res + ix + 1]
		var h01: float = _heightmap[(iy + 1) * grid_res + ix]
		var h11: float = _heightmap[(iy + 1) * grid_res + ix + 1]

		# Gradient via bilinear
		var grad_x: float = (h10 - h00) * (1.0 - fy) + (h11 - h01) * fy
		var grad_y: float = (h01 - h00) * (1.0 - fx) + (h11 - h10) * fx

		# Update direction with inertia
		dir_x = dir_x * inertia - grad_x * (1.0 - inertia)
		dir_y = dir_y * inertia - grad_y * (1.0 - inertia)

		# Normalize direction
		var dir_len: float = sqrt(dir_x * dir_x + dir_y * dir_y)
		if dir_len < 0.0001:
			# Random direction
			var angle: float = _rng.randf() * TAU
			dir_x = cos(angle)
			dir_y = sin(angle)
		else:
			dir_x /= dir_len
			dir_y /= dir_len

		# Move
		var new_x: float = pos_x + dir_x
		var new_y: float = pos_y + dir_y

		var nix: int = int(new_x)
		var niy: int = int(new_y)
		if nix < 0 or nix >= grid_res - 1 or niy < 0 or niy >= grid_res - 1:
			break

		# Height at new position (bilinear)
		var nfx: float = new_x - float(nix)
		var nfy: float = new_y - float(niy)
		var nh00: float = _heightmap[niy * grid_res + nix]
		var nh10: float = _heightmap[niy * grid_res + nix + 1]
		var nh01: float = _heightmap[(niy + 1) * grid_res + nix]
		var nh11: float = _heightmap[(niy + 1) * grid_res + nix + 1]
		var new_height: float = nh00 * (1.0 - nfx) * (1.0 - nfy) + nh10 * nfx * (1.0 - nfy) + nh01 * (1.0 - nfx) * nfy + nh11 * nfx * nfy

		var old_height: float = h00 * (1.0 - fx) * (1.0 - fy) + h10 * fx * (1.0 - fy) + h01 * (1.0 - fx) * fy + h11 * fx * fy
		var height_diff: float = new_height - old_height

		# Sediment capacity based on speed and slope
		var capacity: float = maxf(-height_diff * speed * water * sediment_capacity_factor, min_sediment_capacity)

		if sediment > capacity or height_diff > 0:
			# Deposit sediment
			var deposit: float
			if height_diff > 0:
				# Uphill — deposit minimum of sediment or height difference
				deposit = minf(sediment, height_diff)
			else:
				deposit = (sediment - capacity) * deposition_rate
			sediment -= deposit
			_deposit_at(ix, iy, fx, fy, deposit)
		else:
			# Erode
			var erode_amount: float = minf((capacity - sediment) * erosion_rate, -height_diff)
			sediment += erode_amount
			_erode_at(ix, iy, fx, fy, erode_amount)

		# Update speed
		speed = sqrt(maxf(speed * speed + height_diff * gravity, 0.01))

		# Evaporate water
		water *= (1.0 - evaporation_rate)

		pos_x = new_x
		pos_y = new_y


func _deposit_at(ix: int, iy: int, fx: float, fy: float, amount: float) -> void:
	# Bilinear deposit
	_heightmap[iy * grid_res + ix] += amount * (1.0 - fx) * (1.0 - fy)
	_heightmap[iy * grid_res + ix + 1] += amount * fx * (1.0 - fy)
	_heightmap[(iy + 1) * grid_res + ix] += amount * (1.0 - fx) * fy
	_heightmap[(iy + 1) * grid_res + ix + 1] += amount * fx * fy


func _erode_at(ix: int, iy: int, fx: float, fy: float, amount: float) -> void:
	# Bilinear erosion
	_heightmap[iy * grid_res + ix] -= amount * (1.0 - fx) * (1.0 - fy)
	_heightmap[iy * grid_res + ix + 1] -= amount * fx * (1.0 - fy)
	_heightmap[(iy + 1) * grid_res + ix] -= amount * (1.0 - fx) * fy
	_heightmap[(iy + 1) * grid_res + ix + 1] -= amount * fx * fy


# --- Height range ---

func _compute_height_range() -> void:
	_height_min = INF
	_height_max = -INF
	for i in range(_heightmap.size()):
		_height_min = minf(_height_min, _heightmap[i])
		_height_max = maxf(_height_max, _heightmap[i])


# --- Surface mesh ---

func _create_surface() -> void:
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "TerrainSurface"
	add_child(_surface_mesh)
	_build_surface()


func _build_surface() -> void:
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half: float = terrain_size / 2.0
	var cell: float = terrain_size / float(grid_res - 1)

	for j in range(grid_res - 1):
		for i in range(grid_res - 1):
			var h00: float = _heightmap[j * grid_res + i]
			var h10: float = _heightmap[j * grid_res + i + 1]
			var h01: float = _heightmap[(j + 1) * grid_res + i]
			var h11: float = _heightmap[(j + 1) * grid_res + i + 1]

			var x0: float = -half + i * cell
			var x1: float = -half + (i + 1) * cell
			var z0: float = -half + j * cell
			var z1: float = -half + (j + 1) * cell

			# Clamp below water level for flat water surface
			var y00: float = maxf(h00, _water_level) * height_scale
			var y10: float = maxf(h10, _water_level) * height_scale
			var y01: float = maxf(h01, _water_level) * height_scale
			var y11: float = maxf(h11, _water_level) * height_scale

			var v00 = Vector3(x0, y00, z0)
			var v10 = Vector3(x1, y10, z0)
			var v01 = Vector3(x0, y01, z1)
			var v11 = Vector3(x1, y11, z1)

			var c00 = _altitude_color(h00)
			var c10 = _altitude_color(h10)
			var c01 = _altitude_color(h01)
			var c11 = _altitude_color(h11)

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

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.15
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_surface_mesh.material_override = mat


func _altitude_color(h: float) -> Color:
	var range_size: float = _height_max - _height_min
	if range_size < 0.001:
		return color_grass
	var t: float = clampf((h - _height_min) / range_size, 0.0, 1.0)

	# Below water level → water
	var water_t: float = (_water_level - _height_min) / range_size
	if t < water_t:
		# Deep to shallow water
		var wt: float = t / maxf(water_t, 0.001)
		return color_water.lerp(Color(0.25, 0.5, 0.8), wt)

	# Remap above-water to 0..1
	var land_t: float = (t - water_t) / maxf(1.0 - water_t, 0.001)

	if land_t < 0.05:
		return color_beach
	elif land_t < 0.15:
		return color_beach.lerp(color_grass, (land_t - 0.05) / 0.1)
	elif land_t < 0.4:
		return color_grass.lerp(color_forest, (land_t - 0.15) / 0.25)
	elif land_t < 0.65:
		return color_forest.lerp(color_rock, (land_t - 0.4) / 0.25)
	elif land_t < 0.85:
		return color_rock
	else:
		return color_rock.lerp(color_snow, (land_t - 0.85) / 0.15)


# --- Labels ---

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "HYDRAULIC EROSION"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, height_scale * _height_max + 0.08, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 14
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, height_scale * _height_max + 0.04, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.7, 0.75, 0.85, 0.9)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_info_label.text = "%dx%d grid · %d droplets · %d steps each" % [grid_res, grid_res, droplet_count, droplet_lifetime]
	add_child(_info_label)


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("droplet_count"):
		droplet_count = int(config_data["droplet_count"])
	if config_data.has("erosion_rate"):
		erosion_rate = float(config_data["erosion_rate"])
	if config_data.has("height_scale"):
		height_scale = float(config_data["height_scale"])
