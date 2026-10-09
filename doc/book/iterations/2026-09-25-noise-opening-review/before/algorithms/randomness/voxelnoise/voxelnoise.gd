# VoxelWorld.gd
# @identity
# essence: voxel[x,y,z] = 1 if FastNoiseLite.get_noise_3d(x,y,z) > iso_level else 0 — continuous noise field discretized into a binary 3D grid
# desire: to touch the threshold — to slide iso_level and watch a landscape of solid cubes dissolve or materialize, understanding that the voxel world is just a snapshot of a continuous noise field
# critical_parameter: iso_level — the decision boundary between solid and void; small changes cause avalanches of appearing/disappearing cubes
# triggers: iso_level crosses a noise peak → a cave collapses; noise_scale changes → the spatial frequency of the underlying field reshapes what's solid
# emerges: the iso-surface concept — that topology of solid matter is defined by a threshold value, not by explicit geometry; also the glass/pink shader makes solid cubes feel crystalline
# needs: links to perlin_terrain_sculptor via apply_perlin_terrain_controls signal bus [has]; no standalone VR sliders [missing]; responds to group "voxelnoise_receivers" [has]
# relationships: depends on perlin_terrain_sculptor for interactive control; discretizes what noiselayers shows continuously; connects to marching cubes (smoother iso-surface)
# truth: matter is a threshold — the voxel world reveals that solid and void are not intrinsic qualities but the result of where you draw the line through a continuous field
extends Node3D

# Local debug flag to gate prints (default off)
@export var debug: bool = false

@export var chunk_size: int = 32
@export var world_height: int = 64
@export var voxel_scale: float = 1.0
@export var iso_level: float = 0.0
@export var generation_offset: Vector3i = Vector3i(3, 0, 3)

@export var noise_seed: int = 1337
@export var noise_scale: float = 0.05
@export var noise_octaves: int = 4
@export var noise_persistence: float = 0.5
@export var noise_lacunarity: float = 2.0

@export_group("Perlin Sculptor Link")
@export var link_to_perlin_sculptor: bool = true
@export var linked_frequency_min: float = 0.005
@export var linked_frequency_max: float = 0.18
@export var linked_iso_bias: float = 0.0

var _contract_scale: float = 4.0
var _contract_grid: int = 24
var _occupied_cells: Dictionary = {}
var _rebuild_ms: float = 0.0
@export_enum("none", "volume") var stand: String = "none"
@export var flight_box: bool = false
var _selected_cell: Vector3i = Vector3i(12, 12, 12)
var _slice_frame: Node3D
var _cell_frame: Node3D
var _contract: bool = false     # true once a staged bench has handed over the contract

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-06).
#
#   threshold   WHERE THE LINE IS DRAWN THROUGH THE FIELD
#
# The @identity above already names iso_level the critical_parameter and states
# the artifact's truth as "matter is a threshold". This axis is that sentence
# made settable from a map token: four named stances of the one decision this
# artifact exists to demonstrate. The FIELD never changes — same simplex, same
# seed (1337, deterministic since the day it shipped), same 32³ walk. Only the
# line moves, which is precisely the lesson.
#
#   massif       n > -0.30  most of the volume is matter; void survives as caves
#                worming through a nearly solid block. Matter with holes in it.
#   sponge       n >  0.00  THE LEGACY LINEAGE, byte for byte — solid and void
#                in equal measure, one bicontinuous tangle, neither the figure
#                nor the ground. This is iso_level's shipped value read through
#                the export, so the sculptor link keeps steering it live.
#   archipelago  n > +0.25  matter has become the exception: scattered islands
#                of glass cubes hanging in mostly nothing.
#   wisp         n > +0.45  the last shreds before the field admits no matter at
#                all — a thin dust of cubes marking only the noise's peaks.
#
# WHY NOT `readout` (relief | plate | column), the word five noise artifacts
# already share: readout is the question "how is a 2D sample MATERIALIZED", and
# every one of its values flattens the field to a sheet. This artifact's whole
# argument against its siblings is that the field is VOLUMETRIC and the surface
# is an iso-surface, not a graph — rendering it as relief would teach
# perlin_noise's lesson from voxelnoise's pedestal (R5). The axis it actually
# argues is the threshold itself, a question no promoted artifact asks yet.
#
# `sponge` keeps iso_level authoritative, so apply_perlin_terrain_controls (the
# signal-bus link from perlin_terrain_sculptor) behaves exactly as today. A
# non-default threshold pins the line and wins over the live slider — declared
# behaviour, only reachable where a map asks for it.
#
# No fixture needed: _ready builds standalone, the noise is seeded, nothing
# animates, and the one MeshInstance3D spans the full 32 m volume.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — where the solid/void line is drawn through the noise field.
## `sponge` is the legacy default and reads the iso_level export unchanged.
@export_enum("massif", "sponge", "archipelago", "wisp") var threshold: String = "sponge"

## The allow-list, same spelling and order as the @export_enum. An unknown word
## keeps the default rather than re-carving five placed volumes.
const THRESHOLDS: PackedStringArray = ["massif", "sponge", "archipelago", "wisp"]

var noise: FastNoiseLite
var _generated_root: Node3D
var _rebuild_queued: bool = false

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config deferred (after this), so the meta read happens here.
	_read_meta_overrides()
	add_to_group("voxelnoise_receivers")
	_ensure_generated_root()
	_refresh_volume_staging()
	_queue_rebuild()


func _generate_chunk(chunk_pos: Vector3i) -> void:
	_occupied_cells.clear()
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Hoisted once per rebuild: `sponge` returns iso_level itself (the legacy
	# comparison, byte for byte), the other stances return their named line.
	var iso: float = _effective_iso()

	for x in range(chunk_size):
		for y in range(1, world_height + 1):  # Start at Y=1, go up to world_height
			for z in range(chunk_size):
				var world_x = chunk_pos.x * chunk_size + x + generation_offset.x
				var world_y = y + generation_offset.y
				var world_z = chunk_pos.z * chunk_size + z + generation_offset.z

				var p = Vector3(world_x, world_y, world_z)
				var val: float = 0.0
				var occupied: bool = false
				if _contract:
					# THE CONTRACT (set by a staged perlin_terrain_sculptor in this hall):
					# the same field the bench reads, asked at the same NORMALISED place,
					# through the same predicate — one field, two representations.
					var u := float(x) / float(maxi(1, chunk_size - 1))
					var v := float(y - 1) / float(maxi(1, world_height - 1))
					var w := float(z) / float(maxi(1, chunk_size - 1))
					val = PerlinTerrainSculptor.contract_value(noise, u, v, w)
					occupied = PerlinTerrainSculptor.contract_occupied(val, v, iso)
				else:
					val = noise.get_noise_3d(p.x, p.y, p.z)
					occupied = val > iso

				if occupied:
					_occupied_cells[Vector3i(x,y-1,z)] = true
					if stand != "volume":
						_add_cube(st, p * voxel_scale)

	# A fully empty threshold is a valid state, with neither surface nor collider.
	if _occupied_cells.is_empty(): return

	if stand == "volume":
		_add_volume_boundary(st)
	else:
		st.generate_normals()
	mesh = st.commit()

	# MeshInstance for rendering
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	_generated_root.add_child(mi)

	# Apply shader material
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode cull_disabled;

	uniform vec4 glass_color : source_color = vec4(0.2, 0.4, 1.0, 1.0); // solid blue glass
	uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.5, 1.0); // pink outline
	uniform float outline_width : hint_range(0.5, 5.0) = 1.5;

	varying vec3 barycentric;

	void vertex() {
		// Assign barycentric coords based on vertex ID (for edge detection)
		int vid = VERTEX_ID % 3;
		if (vid == 0) barycentric = vec3(1.0, 0.0, 0.0);
		else if (vid == 1) barycentric = vec3(0.0, 1.0, 0.0);
		else barycentric = vec3(0.0, 0.0, 1.0);
	}

	void fragment() {
		// Edge factor from barycentrics
		vec3 d = fwidth(barycentric);
		vec3 a3 = smoothstep(vec3(0.0), d * outline_width, barycentric);
		float edge = 1.0 - min(min(a3.x, a3.y), a3.z);

		// Mix between blue glassy fill and pink outline
		vec3 color = mix(glass_color.rgb, outline_color.rgb, edge);

		ALBEDO = color;

		// Give "glassiness" with smooth specular highlights
		METALLIC = 0.1;
		ROUGHNESS = 0.1;

		// Pink edge glow
		EMISSION = outline_color.rgb * edge * 1.2;
	}


	"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mi.set_surface_override_material(0, mat)

	# Collider for physics
	if mesh != null and mesh.get_surface_count() > 0:
		var col = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var concave = ConcavePolygonShape3D.new()
		concave.data = mesh.get_faces()
		shape.shape = concave
		col.add_child(shape)
		_generated_root.add_child(col)

func apply_perlin_terrain_controls(payload: Dictionary) -> void:
	if not link_to_perlin_sculptor:
		return

	var threshold_value: float = float(payload.get("threshold", iso_level))
	var scale_norm: float = clampf(float(payload.get("noise_scale_norm", 0.0)), 0.0, 1.0)
	var mapped_frequency: float = lerpf(linked_frequency_min, linked_frequency_max, scale_norm)

	iso_level = clampf(threshold_value + linked_iso_bias, -1.0, 1.0)
	noise_scale = mapped_frequency
	if payload.has("noise_octaves"):
		noise_octaves = clampi(int(payload.get("noise_octaves", noise_octaves)), 1, 8)
	if payload.has("seed"):
		noise_seed = int(payload.get("seed", noise_seed))
	# A staged bench declares the contract; anything else keeps the legacy link, in
	# which this receiver samples its own coordinates with its own iso level.
	_contract = bool(payload.get("contract", false))
	if _contract:
		_contract_scale = float(payload.get("noise_scale", 4.0))
		_contract_grid = int(payload.get("grid_size", 24))
		if stand == "volume":
			chunk_size = clampi(_contract_grid, 4, 32)
			world_height = chunk_size
		iso_level = clampf(threshold_value, -1.0, 1.0)   # no bias: the contract owns the line
		noise = PerlinTerrainSculptor.contract_noise(noise_seed, payload.get("noise_scale", noise_scale), noise_octaves)

	var selected: Array = payload.get("selected_cell", [_selected_cell.x, _selected_cell.y, _selected_cell.z])
	if selected.size() == 3:
		_selected_cell = Vector3i(int(selected[0]), int(selected[1]), int(selected[2]))
	_update_selection_markers()
	_queue_rebuild()

func _ensure_generated_root() -> void:
	if _generated_root != null:
		return

	_generated_root = get_node_or_null("Generated") as Node3D
	if _generated_root == null:
		_generated_root = Node3D.new()
		_generated_root.name = "Generated"
		add_child(_generated_root)

func _configure_noise() -> void:
	if _contract:
		noise = PerlinTerrainSculptor.contract_noise(noise_seed, _contract_scale, noise_octaves)
		return
	if noise == null:
		noise = FastNoiseLite.new()

	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = noise_seed
	noise.frequency = noise_scale
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_persistence

func _clear_generated() -> void:
	if _generated_root == null:
		return

	for child in _generated_root.get_children():
		_generated_root.remove_child(child)
		child.queue_free()

func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_now")

func _rebuild_now() -> void:
	_rebuild_queued = false
	_ensure_generated_root()
	_configure_noise()
	_clear_generated()
	var started: int = Time.get_ticks_usec()
	_generate_chunk(Vector3i.ZERO)
	_rebuild_ms = float(Time.get_ticks_usec()-started)/1000.0


func _add_cube(st: SurfaceTool, pos: Vector3) -> void:
	var s = voxel_scale * 0.5
	var verts = [
		Vector3(-s, -s, -s), Vector3(s, -s, -s),
		Vector3(s,  s, -s), Vector3(-s,  s, -s),
		Vector3(-s, -s,  s), Vector3(s, -s,  s),
		Vector3(s,  s,  s), Vector3(-s,  s,  s)
	]
	var idx = [
		0,1,2, 2,3,0,
		1,5,6, 6,2,1,
		5,4,7, 7,6,5,
		4,0,3, 3,7,4,
		3,2,6, 6,7,3,
		4,5,1, 1,0,4
	]
	for i in idx:
		st.add_vertex(pos + verts[i])


## Keep the same occupied cells; shared interior faces need neither drawing nor collision.
func _add_volume_boundary(st: SurfaceTool) -> void:
	var s: float=voxel_scale*0.5
	var verts: Array=[Vector3(-s,-s,-s),Vector3(s,-s,-s),Vector3(s,s,-s),Vector3(-s,s,-s),Vector3(-s,-s,s),Vector3(s,-s,s),Vector3(s,s,s),Vector3(-s,s,s)]
	var faces: Array=[[0,1,2,2,3,0],[1,5,6,6,2,1],[5,4,7,7,6,5],[4,0,3,3,7,4],[3,2,6,6,7,3],[4,5,1,1,0,4]]
	var directions: Array=[Vector3i(0,0,-1),Vector3i(1,0,0),Vector3i(0,0,1),Vector3i(-1,0,0),Vector3i(0,1,0),Vector3i(0,-1,0)]
	for cell: Vector3i in _occupied_cells:
		var centre: Vector3=Vector3(cell.x-(chunk_size-1)*0.5,cell.y+0.5,cell.z-(chunk_size-1)*0.5)*voxel_scale
		for face_index in range(6):
			if _occupied_cells.has(cell+directions[face_index]):continue
			st.set_normal(Vector3(directions[face_index]))
			for index in faces[face_index]:st.add_vertex(centre+verts[index])

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═════════════════════════════════════════════════════════════════════════════
# DNA plumbing
# ═════════════════════════════════════════════════════════════════════════════

## The line the generator compares against. `sponge` (the default) hands back
## the iso_level export unchanged — 0.0 as shipped, and still writable live by
## apply_perlin_terrain_controls — so the legacy path is the export itself, not
## a copy of it. The named stances pin the line regardless of the slider.
func _effective_iso() -> float:
	match threshold:
		"massif":
			return -0.30
		"archipelago":
			return 0.25
		"wisp":
			return 0.45
		_:
			return iso_level      # "sponge" — the legacy lineage


func _read_meta_overrides() -> void:
	if str(get_meta("config_stand", "")) == "volume":
		stand = "volume"
		chunk_size = 24;world_height = 24;voxel_scale = clampf(float(str(get_meta("config_cell_size", "0.2"))), 0.05, 2.0)
	if has_meta("config_flight_box"):
		flight_box = str(get_meta("config_flight_box")).to_lower() in ["true", "1", "yes"]
	if has_meta("config_threshold"):
		var v: String = str(get_meta("config_threshold")).strip_edges().to_lower()
		if THRESHOLDS.has(v):
			threshold = v
		elif v != "":
			push_warning("voxelnoise: unknown threshold '%s' — keeping '%s'" % [v, threshold])
	if has_meta("config_iso_level"):
		iso_level = clampf(float(str(get_meta("config_iso_level"))), -1.0, 1.0)
	if has_meta("config_noise_seed"):
		noise_seed = int(str(get_meta("config_noise_seed")))


## Was `pass` — every `#token: value` a map put on a voxelnoise placement was
## parsed, stashed as metadata and then discarded. Guarded like the family's:
## an unchanged config touches nothing, so curation_station's blanket
## apply_grid_config({"emissive": false}) cannot trigger a 32³ rebuild.
func apply_grid_config(config: Dictionary) -> void:
	var before_threshold: String = threshold
	var before_iso: float = iso_level
	var before_seed: int = noise_seed
	var before_staging: Array = [stand, voxel_scale, flight_box]
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	var staging_changed: bool = before_staging != [stand, voxel_scale, flight_box]
	if staging_changed and is_inside_tree(): _refresh_volume_staging()
	if not staging_changed and threshold == before_threshold and is_equal_approx(iso_level, before_iso) \
			and noise_seed == before_seed:
		return
	_queue_rebuild()

## Only explicit size/staging changes rebuild the enclosure. Field and CELL updates
## keep the flight zone and its locomotion registration alive.
func _refresh_volume_staging() -> void:
	for node_name in ["VolumeStage", "SelectedSlice", "SelectedCell", "FlightBox"]:
		var old := get_node_or_null(node_name)
		if old != null: remove_child(old); old.queue_free()
	_slice_frame = null; _cell_frame = null
	if stand != "volume": return
	_build_volume_stage()
	if flight_box:
		var zone := preload("res://commons/movement/museum_flight_box.gd").new()
		zone.name = "FlightBox"
		zone.edge_length = maxf(chunk_size, world_height) * voxel_scale + 4.0
		zone.instruction_title = "FLY THROUGH THE EMPTY CELLS"
		add_child(zone)

## Fixed museum framing; the generated body can become entirely absent within it.
func _build_volume_stage() -> void:
	var kit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var mat := StandardMaterial3D.new();mat.albedo_color=Color(0.08,0.12,0.16)
	var width: float = chunk_size * voxel_scale + 0.4
	var stage_ := Node3D.new();stage_.name="VolumeStage";add_child(stage_)
	stage_.add_child(kit.box(Vector3(0,-0.06,0),Vector3(width,0.12,width),mat))
	for x in [-width * 0.5 + 0.05, width * 0.5 - 0.05]:
		stage_.add_child(kit.box(Vector3(x,0.12,0),Vector3(0.06,0.24,width),mat))
	var label_ := Label3D.new()
	label_.text = "%s m CELLS | %d x %d x %d ADDRESSES\nSame field as the bench | %s times the spacing" % [voxel_scale, chunk_size, world_height, chunk_size, voxel_scale / 0.04]
	label_.font_size=25;label_.pixel_size=0.002;label_.position=Vector3(0,0.15,-width*0.5-0.03);label_.rotation.y=PI
	label_.set_meta("em_local_instrument",true);stage_.add_child(label_)
	# Readable from both approaches when the volume shares the model's orientation.
	var reverse_label := label_.duplicate() as Label3D
	reverse_label.position.z = width * 0.5 + 0.03; reverse_label.rotation.y = 0.0
	stage_.add_child(reverse_label)
	_build_selection_markers()


## CELL marks the screen's horizontal section in the room. These lines have no
## collider or depth override; solid cells can hide the selected address.
func _build_selection_markers() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.16)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_slice_frame = Node3D.new(); _slice_frame.name = "SelectedSlice"; add_child(_slice_frame)
	_cell_frame = Node3D.new(); _cell_frame.name = "SelectedCell"; add_child(_cell_frame)
	for i in range(4): _selection_bar(_slice_frame, mat)
	for i in range(12): _selection_bar(_cell_frame, mat)
	_update_selection_markers()

func _selection_bar(parent: Node3D, mat: Material) -> void:
	var bar := MeshInstance3D.new()
	bar.mesh = BoxMesh.new(); bar.material_override = mat
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(bar)

func apply_perlin_cell_selection(cell: Vector3i) -> void:
	if not link_to_perlin_sculptor or stand != "volume" or not _contract: return
	_selected_cell = cell
	_update_selection_markers()

func _update_selection_markers() -> void:
	if not is_instance_valid(_slice_frame): return
	var valid: bool = _contract and _selected_cell.x >= 0 and _selected_cell.x < chunk_size \
		and _selected_cell.y >= 0 and _selected_cell.y < world_height \
		and _selected_cell.z >= 0 and _selected_cell.z < chunk_size
	_slice_frame.visible = valid; _cell_frame.visible = valid
	if not valid: return
	var width: float = chunk_size * voxel_scale + 0.10
	var stroke: float = 0.012 * maxf(1.0, voxel_scale / 0.2)
	_slice_frame.position.y = (_selected_cell.y + 0.5) * voxel_scale
	for i in range(4):
		var bar: MeshInstance3D = _slice_frame.get_child(i)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		bar.position = Vector3(side * width * 0.5, 0, 0) if i < 2 else Vector3(0, 0, side * width * 0.5)
		(bar.mesh as BoxMesh).size = Vector3(stroke, stroke, width) if i < 2 else Vector3(width, stroke, stroke)
	_cell_frame.position = Vector3(_selected_cell.x - (chunk_size - 1) * 0.5, _selected_cell.y + 0.5, _selected_cell.z - (chunk_size - 1) * 0.5) * voxel_scale
	var size: float = voxel_scale * 1.06
	var index: int = 0
	for axis in range(3):
		for a in [-1.0, 1.0]:
			for b in [-1.0, 1.0]:
				var bar: MeshInstance3D = _cell_frame.get_child(index)
				var at := Vector3.ZERO; at[(axis + 1) % 3] = a * size * 0.5; at[(axis + 2) % 3] = b * size * 0.5
				var dimensions := Vector3.ONE * (stroke * 0.75); dimensions[axis] = size
				bar.position = at; (bar.mesh as BoxMesh).size = dimensions
				index += 1
