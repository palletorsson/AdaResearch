@tool
extends Node3D

# @identity
# essence: B5+/S4+ on a 3D grid → density texture → FogVolume — CA rules become visible atmosphere
# desire: To be walked through — fog that has opinions about where it clumps, thinning and thickening by local rules
# critical_parameter: smooth_factor and birth/survival thresholds (B5/S4) — control whether fog dissipates or aggregates
# triggers: High survival threshold → fog evaporates; low → dense permanent clouds; grid resolution → fine mist vs chunky blocks
# emerges: Cloud-like formations from binary CA rules — no fluid dynamics, yet the fog moves like weather
# needs: VR density controls [missing], rule parameter sliders [missing]
# relationships: Feeds into CA_EdgeOfChaos. Unique in using CA to drive Godot's FogVolume system directly.
# truth: Fog is a cellular automaton — local density rules produce clouds no one shaped.

# Volumetric Fog CA
# A 3D CA (B5+/S4+) whose live cells are fog.
#
# VISIBLE EVERYWHERE, AND IT KEEPS MOVING (2026-11-10, improvement pass). It drew only through a FogVolume, which
# renders only when the Environment enables volumetric fog on Forward+: not in the Void tower (its environment does
# not), not on the Quest (Mobile renderer), not standalone (no environment of its own) - the tower review photographed
# an empty corner on floor 116. Now each live cell is a soft billboard puff (one MultiMesh, a shader that fades each
# puff between steps and folds dead ones away), in every renderer; the FogVolume stays as display "volume" where a
# scene enables volumetric fog. The rule settled into frozen clumps after a few steps, so a slow wind now carries the
# field across the box (periodic edges) and a little turbulence flips a few cells each step: the clumps drift, fray and
# re-form. The step counted 26 neighbours per cell over untyped Arrays - the scene asked for 64^3 every 0.05 s, ~6.8
# million reads a second in GDScript - now separable sums over packed arrays, 16^3 by default.

@export var grid_size: Vector3i = Vector3i(16, 16, 16)
@export var update_interval: float = 0.2
@export_range(1, 26) var birth := 14                   ## an empty cell fills with at least this many of its 26 neighbours
@export_range(1, 26) var survive := 12                 ## a fog cell stays with at least this many
@export_range(0.0, 1.0) var initial_fill := 0.45
@export_range(0.0, 0.9) var humidity := 0.22           ## the share of the box the weather keeps as cloud: below it vapour condenses, well above it fog evaporates
@export var vapour_radius := 2.4                       ## cells
@export var smooth_factor: float = 0.5                 ## the share of a step over which a puff fades in or out
@export_enum("auto", "puffs", "volume") var display: String = "auto"   ## auto: the volume only where the environment draws volumetric fog
@export var wind := Vector3i(1, 0, 0)                  ## cells the field drifts every wind_steps steps (periodic edges)
@export var wind_steps := 3
@export_range(0.0, 0.1) var turbulence := 0.012        ## share of cells set at random each step
@export var extent := 10.0                             ## metres: the box the fog fills

var fog_volume: FogVolume

var current_state := PackedByteArray()
var next_state := PackedByteArray()
var texture: ImageTexture3D
var image_data: Array[Image] = []
var timer: float = 0.0
var steps := 0
var slice_preview: MeshInstance3D      # kept for the Void's trial adapter (fog_preview.gd)
var slice_texture: ImageTexture
var _puffs: MultiMeshInstance3D
var _puff_material: ShaderMaterial
var _buffer := PackedFloat32Array()
var _sum_a := PackedInt32Array()
var _sum_b := PackedInt32Array()
var _built_size := Vector3i.ZERO

const PUFF_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float blend = 1.0;
uniform vec4 tint : source_color = vec4(0.84, 0.91, 1.0, 1.0);
uniform float opacity = 0.34;
varying float v_alpha;
void vertex() {
	v_alpha = mix(COLOR.r, COLOR.g, clamp(blend, 0.0, 1.0));
	// a billboard that keeps the cell's place and size; a dead cell folds to a point and draws nothing
	float s = length(MODEL_MATRIX[0].xyz) * step(0.003, v_alpha);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}
void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float soft = 1.0 - smoothstep(0.0, 1.0, d);
	ALBEDO = tint.rgb;
	ALPHA = soft * soft * v_alpha * opacity;
}
"""

func _ready() -> void:
	_initialize_grid()
	_setup_fog()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if grid_size != _built_size:   # the Void applies preview_grid after _ready: rebuild at the new size
		_initialize_grid()
		_setup_fog()
	timer += delta
	if timer >= update_interval:
		timer = 0.0
		_step()
		_update_texture()
	if _puff_material:
		_puff_material.set_shader_parameter("blend", timer / maxf(0.01, update_interval * maxf(0.05, smooth_factor) * 2.0))

func _count() -> int:
	return grid_size.x * grid_size.y * grid_size.z

func _initialize_grid() -> void:
	var n := _count()
	current_state.resize(n); next_state.resize(n); _sum_a.resize(n); _sum_b.resize(n)
	for i in n:
		current_state[i] = 1 if randf() < initial_fill else 0
	_built_size = grid_size

func _use_volume() -> bool:
	if display == "puffs": return false
	if display == "volume": return true
	if RenderingServer.get_current_rendering_method() != "forward_plus": return false
	var env: Environment = get_world_3d().environment if is_inside_tree() and get_world_3d() else null
	return env != null and env.volumetric_fog_enabled

func _setup_fog() -> void:
	for old in [_puffs, fog_volume, slice_preview]:
		if old and is_instance_valid(old): old.queue_free()
	_puffs = null; fog_volume = null; slice_preview = null; image_data.clear()
	if _use_volume():
		_setup_volume()
	else:
		_setup_puffs()
	_update_texture()

func _setup_volume() -> void:
	fog_volume = FogVolume.new()
	fog_volume.size = Vector3.ONE * extent
	add_child(fog_volume)
	var mat = FogMaterial.new()
	mat.density = 2.0
	mat.albedo = Color(0.8, 0.9, 1.0)
	mat.emission = Color(0.1, 0.2, 0.3)
	fog_volume.material = mat
	var img = Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_R8)
	for z in range(grid_size.z):
		image_data.append(img.duplicate())
	texture = ImageTexture3D.new()
	texture.create(Image.FORMAT_R8, grid_size.x, grid_size.y, grid_size.z, false, image_data)
	mat.density_texture = texture

func _setup_puffs() -> void:
	var shader := Shader.new(); shader.code = PUFF_SHADER
	_puff_material = ShaderMaterial.new(); _puff_material.shader = shader
	var quad := QuadMesh.new(); quad.size = Vector2.ONE
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true; mm.mesh = quad
	var n := _count()
	mm.instance_count = n
	var cell := extent / float(maxi(grid_size.x, maxi(grid_size.y, grid_size.z)))
	var puff := cell * 2.3   # neighbouring puffs overlap into one cloud
	_buffer.resize(n * 16)
	var origin := -Vector3(grid_size) * cell * 0.5 + Vector3.ONE * cell * 0.5
	for z in grid_size.z:
		for y in grid_size.y:
			for x in grid_size.x:
				var o := (x + y * grid_size.x + z * grid_size.x * grid_size.y) * 16
				var p := origin + Vector3(x, y, z) * cell
				_buffer[o] = puff; _buffer[o + 1] = 0.0; _buffer[o + 2] = 0.0; _buffer[o + 3] = p.x
				_buffer[o + 4] = 0.0; _buffer[o + 5] = puff; _buffer[o + 6] = 0.0; _buffer[o + 7] = p.y
				_buffer[o + 8] = 0.0; _buffer[o + 9] = 0.0; _buffer[o + 10] = puff; _buffer[o + 11] = p.z
				_buffer[o + 12] = 0.0; _buffer[o + 13] = 0.0; _buffer[o + 14] = 0.0; _buffer[o + 15] = 1.0
	mm.buffer = _buffer
	_puffs = MultiMeshInstance3D.new(); _puffs.name = "Fog"
	_puffs.multimesh = mm; _puffs.material_override = _puff_material
	_puffs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_puffs.custom_aabb = AABB(-Vector3.ONE * extent * 0.5, Vector3.ONE * extent)
	add_child(_puffs)
	# the capture frames MeshInstance3D only: an unseen box the size of the fog (layers 0 draws nothing)
	var anchor := MeshInstance3D.new(); anchor.name = "FogExtent"
	var box := BoxMesh.new(); box.size = Vector3.ONE * extent * 0.8; anchor.mesh = box; anchor.layers = 0
	_puffs.add_child(anchor)

## Birth/survival over the 26 neighbours with periodic edges: neighbours by three separable box sums (x, then y, then z) over packed arrays,
## then a slow wind and a little turbulence so the clumps never freeze.
func _step() -> void:
	var sx := grid_size.x; var sy := grid_size.y; var sz := grid_size.z
	var plane := sx * sy
	var c := current_state
	for z in sz:
		for y in sy:
			var row := y * sx + z * plane
			for x in sx:
				_sum_a[row + x] = c[row + (x + sx - 1) % sx] + c[row + x] + c[row + (x + 1) % sx]
	for z in sz:
		for y in sy:
			var row := y * sx + z * plane
			var up := ((y + 1) % sy) * sx + z * plane
			var dn := ((y + sy - 1) % sy) * sx + z * plane
			for x in sx:
				_sum_b[row + x] = _sum_a[dn + x] + _sum_a[row + x] + _sum_a[up + x]
	var n := sx * sy * sz
	var live := 0
	for i in n:
		var z := i / plane
		var neighbours: int = _sum_b[i - z * plane + ((z + sz - 1) % sz) * plane] + _sum_b[i] + _sum_b[i - z * plane + ((z + 1) % sz) * plane] - c[i]
		var alive: int = 1 if (neighbours >= survive if c[i] == 1 else neighbours >= birth) else 0
		next_state[i] = alive
		live += alive
	var temp := current_state
	current_state = next_state
	next_state = temp
	steps += 1
	if wind != Vector3i.ZERO and wind_steps > 0 and steps % wind_steps == 0:
		var moved := PackedByteArray(); moved.resize(n)
		for z in sz:
			for y in sy:
				for x in sx:
					moved[(x + wind.x + sx) % sx + ((y + wind.y + sy) % sy) * sx + ((z + wind.z + sz) % sz) * plane] = current_state[x + y * sx + z * plane]
		current_state = moved
		next_state.resize(n)
	for k in int(turbulence * n):
		current_state[randi() % n] = 1 if randf() < 0.5 else 0
	# Humidity, a thermostat: on their own these threshold rules either fill the box or let every cloud evaporate
	# (measured on 12^3: B5/S4 99 %, majority 0 %, and in between it flips from run to run).
	var fill := float(live) / float(n)
	if fill > humidity * 1.6:
		for k in int((fill - humidity) * 0.08 * n):
			current_state[randi() % n] = 0
	elif fill < humidity:   # loose seeds of vapour condense - more the drier it is: the rule rounds them into clouds, or lets them go
		var r := int(ceil(vapour_radius))
		var seed_cells := 0.75 * 4.18879 * pow(vapour_radius, 3.0)
		for seed in clampi(int((humidity - fill) * n / seed_cells) + 1, 1, 6):
			var at := Vector3i(randi() % sx, randi() % sy, randi() % sz)
			for dz in range(-r, r + 1):
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						if Vector3(dx, dy, dz).length() <= vapour_radius and randf() < 0.75:
							current_state[(at.x + dx + sx) % sx + ((at.y + dy + sy) % sy) * sx + ((at.z + dz + sz) % sz) * plane] = 1

func _update_texture() -> void:
	if slice_preview != null:
		var img := Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_RGBA8)
		var z: int = grid_size.z / 2
		for y in range(grid_size.y):
			for x in range(grid_size.x): img.set_pixel(x, y, Color("c5dfde") if current_state[x + y * grid_size.x + z * grid_size.x * grid_size.y] > 0 else Color("213641"))
		slice_texture.update(img)
		return
	if _puffs:
		var n := _count()
		for i in n:   # colour r = where the puff was, g = where it is going; the shader fades between them
			var o := i * 16 + 12
			_buffer[o] = _buffer[o + 1]
			_buffer[o + 1] = float(current_state[i])
		_puffs.multimesh.buffer = _buffer
		return
	if fog_volume and texture:
		var sx = grid_size.x
		var sy = grid_size.y
		for z in range(grid_size.z):
			var img = image_data[z]
			for y in range(sy):
				for x in range(sx):
					img.set_pixel(x, y, Color(float(current_state[x + y * sx + z * sx * sy]), 0, 0))
		texture.update(image_data)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("preview_grid"):
		var n: int = clampi(int(config.preview_grid), 4, 32); grid_size = Vector3i(n, n, n)
