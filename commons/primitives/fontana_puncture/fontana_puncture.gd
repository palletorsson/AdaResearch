extends Node3D
class_name FontanaPuncture

# @identity
# essence: a solid cube with a sphere subtracted from it — and the sphere is BIGGER than the cube, so the void opens a round mouth on every face and hollows the matter from inside. Lucio Fontana's Concetto Spaziale carried into three dimensions: not a slash in a flat canvas but a spherical absence carved through solid mass, the "infinite dimension" he said he had created, here literally larger than the object that holds it. At the dead centre, suspended in the hollow it made, floats a single luminous point — the 0-dimensional origin of the cut, the point that ate the cube.
# desire: it wants to prove the point is generative by SUBTRACTION. Most of the lab adds matter; this one removes it, and the removal is the form. It wants the player to walk around a cube and find it is mostly hole — to see solid red matter with windows on all six faces and understand that the void is not nothing, the void is the work. It wants to make absence sculptural and queer: the cut that is also an opening, the wound that is also a window.
# critical_parameter: sphere_radius vs cube_size. When sphere_radius is small the cube is barely dimpled (sealed, mode-collapse). As sphere_radius grows past the cube's half-extent the void breaches every face and the cube becomes a skeletal frame around an absence — the difference forced all the way through the matter. sphere_offset slides the carving off-centre for an asymmetric scoop.
# triggers: _ready builds a CSG cube + subtractive CSG sphere, bakes them to a single static mesh (so it exports and is cheap at runtime), and suspends the emissive centre-point in the hollow; apply_grid_config rebuilds on DNA change.
# emerges: a small sphere reads as a Fontana buchi (a hole); a large one reads as the void winning — the object mostly gone, the dimension behind it now in front of it. Beside `klee_walking_point` (the point that moves) this is the point that DESTROYS-and-reveals; together they teach that a point is never inert — it walks, or it cuts.
# needs: solid matter to deny [the cube, present]; a sphere of absence larger than the matter [subtractive CSG, present]; openings the eye can pass through [face-mouths from the over-sized sphere, present]; the point that carved it, made visible [centre glint, present]
# relationships: descendant of the monochrome (Malevich, Klein, Reinhardt) which it refuses by puncture; cousin to `klee_walking_point` (motion vs. rupture, the two verbs of the point); ancestor of every window, floor-window and portal in the lab grammar — they are all this scoop made architecture, the absence you can walk through; kin to boolean / CSG artifacts downstream (this is their first appearance — subtraction as meaning).
# truth: a point is position without extension — but give it a radius and aim it at solid matter and it becomes the most consequential thing in the room: the absence that defines the form. Fontana cut the canvas to let the infinite in. Here the infinite is a sphere bigger than the cube, and the cube survives only as the frame that proves there was something for the void to take.

## Fontana puncture — a cube hollowed by an oversized subtractive sphere.
##
## Built with CSG (CSGBox3D minus CSGSphere3D), baked to a single static
## mesh so it exports to GLB and is cheap at runtime. Origin at the cube
## centre. A luminous point floats in the carved hollow.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
@export var cube_size: float = 0.5
## Radius of the subtractive sphere. Default > cube_size*0.5 so the void
## breaches every face (the cube is "a bit smaller than the sphere").
@export var sphere_radius: float = 0.34
@export var sphere_offset: Vector3 = Vector3.ZERO

@export_group("Material")
@export var cube_color: Color = Color(0.70, 0.07, 0.07)   # Fontana red
@export var show_center_point: bool = true
@export var depth_color: Color = Color(0.98, 0.92, 0.70)
@export var depth_energy: float = 2.6
@export var center_radius: float = 0.03

@export_group("Embedded point")
## When set, instantiate a LIVE artifact at the void centre instead of the
## static glint — so the point the cube was carved around is the real,
## interactive point (e.g. "interactive_point_origin_force"). The cube is
## hollow (the void breaches every face), so the embedded point is reachable
## and grabbable through the openings. Empty = keep the static glint.
@export var embed_artifact: String = ""
## Mode forwarded to the embedded point (its #mode: config), e.g.
## "transformation", "chromatic", "waveform".
@export var embed_mode: String = ""

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _combiner: CSGCombiner3D = null


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_combiner = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_cube_size"):
		cube_size = float(str(get_meta("config_cube_size")))
	if has_meta("config_sphere_radius"):
		sphere_radius = float(str(get_meta("config_sphere_radius")))
	if has_meta("config_cube_color"):
		cube_color = _parse_color(str(get_meta("config_cube_color")), cube_color)
	if has_meta("config_show_center_point"):
		var s: String = str(get_meta("config_show_center_point")).to_lower()
		show_center_point = s == "true" or s == "1" or s == "yes"
	if has_meta("config_depth_color"):
		depth_color = _parse_color(str(get_meta("config_depth_color")), depth_color)
	if has_meta("config_embed_artifact"):
		embed_artifact = str(get_meta("config_embed_artifact")).strip_edges()
	if has_meta("config_embed_mode"):
		embed_mode = str(get_meta("config_embed_mode")).strip_edges()


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# CSG: cube minus an (over-sized) sphere.
	_combiner = CSGCombiner3D.new()
	_combiner.name = "Carve"

	var mat := StandardMaterial3D.new()
	mat.albedo_color = cube_color
	mat.roughness = 0.85       # matte, like painted matter
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # see the carved inner walls

	var box := CSGBox3D.new()
	box.name = "Cube"
	box.size = Vector3(cube_size, cube_size, cube_size)
	box.material = mat
	_combiner.add_child(box)

	var sph := CSGSphere3D.new()
	sph.name = "Void"
	sph.radius = sphere_radius
	sph.radial_segments = 28
	sph.rings = 18
	sph.operation = CSGShape3D.OPERATION_SUBTRACTION
	sph.position = sphere_offset
	_combiner.add_child(sph)

	add_child(_combiner)

	# The point that carved the void — suspended at the sphere centre,
	# visible (and, if embedded, grabbable) through the face-mouths.
	if embed_artifact != "":
		# Embed a LIVE artifact (e.g. interactive_point_origin_force) at the
		# void centre — the cube is carved AROUND the real interactive point.
		_embed_live_point()
	elif show_center_point:
		var glint := MeshInstance3D.new()
		glint.name = "CenterPoint"
		var gm := SphereMesh.new()
		gm.radius = center_radius
		gm.height = center_radius * 2.0
		glint.mesh = gm
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = depth_color
		gmat.emission_enabled = true
		gmat.emission = depth_color
		gmat.emission_energy_multiplier = depth_energy
		gmat.roughness = 0.2
		glint.material_override = gmat
		glint.position = sphere_offset
		add_child(glint)

	# Bake CSG -> static mesh next idle frame (CSG needs one tick to
	# compute). The baked mesh exports to GLB and is cheaper than live
	# CSG; the live CSG is freed once baked. Fallback: keep CSG if bake
	# returns nothing (e.g. very early headless frame).
	call_deferred("_bake_and_replace", mat)


# Instantiate a live artifact (looked up by name in the registry) at the
# void centre, forwarding its mode config. Used to nest the real interactive
# point inside the puncture it carved.
func _embed_live_point() -> void:
	var scene_path: String = _lookup_artifact_scene(embed_artifact)
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("FontanaPuncture: embed_artifact '%s' not found in registry" % embed_artifact)
		return
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return
	var pt: Node = packed.instantiate()
	pt.name = "EmbeddedPoint"
	# Forward the mode (the interactive point reads config_mode).
	if embed_mode != "" and pt.has_method("apply_grid_config"):
		pt.set_meta("config_mode", embed_mode)
	if pt is Node3D:
		(pt as Node3D).position = sphere_offset
	add_child(pt)
	if embed_mode != "" and pt.has_method("apply_grid_config"):
		pt.call_deferred("apply_grid_config", {"mode": embed_mode})


func _lookup_artifact_scene(lookup: String) -> String:
	const REG_DIR := "res://commons/artifacts/registry/"
	var dir := DirAccess.open(REG_DIR)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var raw := FileAccess.get_file_as_string(REG_DIR + fname)
			if not raw.is_empty():
				var parsed = JSON.parse_string(raw)
				# Registries come in two shapes: entries at the root, or
				# nested under an "artifacts" key. Check both.
				var table = null
				if parsed is Dictionary:
					if parsed.has(lookup):
						table = parsed
					elif parsed.has("artifacts") and (parsed["artifacts"] is Dictionary) \
							and parsed["artifacts"].has(lookup):
						table = parsed["artifacts"]
				if table != null:
					var entry = table[lookup]
					if entry is Dictionary and entry.has("scene"):
						dir.list_dir_end()
						return str(entry["scene"])
		fname = dir.get_next()
	dir.list_dir_end()
	return ""


func _bake_and_replace(mat: StandardMaterial3D) -> void:
	if _combiner == null or not is_instance_valid(_combiner):
		return
	var baked: ArrayMesh = _combiner.bake_static_mesh()
	if baked == null:
		return  # keep live CSG as fallback
	var mi := MeshInstance3D.new()
	mi.name = "FontanaCarved"
	mi.mesh = baked
	mi.material_override = mat
	add_child(mi)
	_combiner.queue_free()
	_combiner = null
