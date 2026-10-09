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

# --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
# THE PROBLEM. sphere_radius and sphere_offset are this artifact's own declared
# critical_parameter ("sphere_radius vs cube_size ... sphere_offset slides the
# carving off-centre"), and both were reachable only as raw floats nobody could
# name. 37 placements, and every one of them shows the same 0.34. The artifact
# argued that subtraction is generative and then shipped exactly one subtraction.
#
# breach — HOW FAR the void has eaten, as a ratio of cube_size. Not a size knob:
#   cube_size is 0.5 at every value, so the object occupies the same cell and the
#   same footprint. What changes is the TOPOLOGY of what survives, and the four
#   values are the four topologically distinct states this geometry has, measured
#   against the cube's own three critical distances (half-extent 0.5, edge-midpoint
#   0.707, corner 0.866, all times cube_size):
#     pierced  0.54  past the half-extent only — six round mouths in solid matter.
#                    Fontana's buchi: the cube is dented through, not hollowed.
#     opened   0.68  SHIPPED. Mouths of 0.46 m on a 0.5 m face, and still connected
#                    (0.68 < 0.707) — a thin frame around a void that has won.
#     severed  0.74  past the edge-midpoint: the twelve edges are cut and the cube
#                    survives as eight disconnected corner pieces. A different
#                    OBJECT, not a smoother one.
#     husk     0.80  the corners down to a twentieth of the extent — matter as the
#                    residue of its own absence, the limit before nothing renders.
#   Deliberately stops short of 0.866: past that the cube is gone entirely and the
#   frame would measure as NO RENDER, which is a fact about the capture, not the art.
#
# strike — WHERE the void struck. breach is the amount axis, strike is the
#   direction axis, the same pairing sphere_mid established with
#   resolution/budget_bias. Offsets are fractions of cube_size so they track the
#   cube. centred says the void is the object's core; the other three say it is an
#   event that happened at a place, and the matter is asymmetric proof of it. All
#   three displaced values move on Y or on all three axes at once, so no single
#   camera yaw can hide the axis behind the silhouette.
#
# WHY THIS PAIR AND NOT "one puncture or many". A second subtractive solid (a
# slash, a scatter of punctures) is the obvious third axis and it is the one to
# add next — but a taglio is a cut in ONE face, and the sweep photographs from one
# fixed camera. Half the yaws would show an uncut cube and the critic would report
# a fact about camera placement as a verdict on Fontana. Both axes shipped here are
# spherically or vertically legible, so no frame can lie about them.
const BREACH = {
	"pierced": 0.54,
	"opened": 0.68,
	"severed": 0.74,
	"husk": 0.80,
}
## The allow-list, and a match rather than a const Dictionary of Vector3s on
## purpose: this file could not be compile-checked in the session that wrote it
## (captures are serialised centrally), and a PackedStringArray plus a match is
## the same shape the sibling capsule.gd already ships and Godot already parses.
## Offsets are FRACTIONS of cube_size, applied in _cut_offset.
const STRIKES: PackedStringArray = ["centred", "raised", "corner", "grazing"]

@export_group("Form")
@export_enum("pierced", "opened", "severed", "husk") var breach: String = "opened"
@export_enum("centred", "raised", "corner", "grazing") var strike: String = "centred"
@export var cube_size: float = 0.5
## Radius of the subtractive sphere. Default > cube_size*0.5 so the void
## breaches every face (the cube is "a bit smaller than the sphere").
## A placement that sets this explicitly OVERRIDES breach — see _build.
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
## A placement that names sphere_radius / sphere_offset directly keeps them. The
## named axes are a vocabulary laid OVER the raw floats, never a replacement for
## them, so no existing token can change meaning.
var _radius_explicit: bool = false
var _offset_explicit: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	# Guarded: an empty dict is not a reason to tear the artifact down and build
	# it again. Every real placement passes at least one key, so this preserves
	# all 37 of them (including the eight that embed a live point, which need the
	# rebuild) while removing the gratuitous churn of a no-op reconfigure.
	if _built and config_data.size() > 0:
		for c in get_children():
			c.queue_free()
		_built = false
		_combiner = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_breach"):
		var b: String = str(get_meta("config_breach")).strip_edges().to_lower()
		if BREACH.has(b):
			breach = b
	if has_meta("config_strike"):
		var s2: String = str(get_meta("config_strike")).strip_edges().to_lower()
		if STRIKES.has(s2):
			strike = s2
	if has_meta("config_cube_size"):
		cube_size = float(str(get_meta("config_cube_size")))
	if has_meta("config_sphere_radius"):
		sphere_radius = float(str(get_meta("config_sphere_radius")))
		_radius_explicit = true
	if has_meta("config_sphere_offset"):
		_offset_explicit = true
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

## Resolve the two named axes down to the two floats the CSG has always used.
##
## THE LEGACY SHORT-CIRCUIT, and why it is not merely belt-and-braces. The default
## pair (breach="opened", strike="centred") returns sphere_radius and sphere_offset
## UNTOUCHED rather than recomputing 0.68 * cube_size. Recomputing would be
## bit-identical at the shipped cube_size of 0.5 — and wrong for any placement that
## overrode cube_size alone, because such a map is asking for a 0.34 sphere in a
## bigger cube and the ratio path would silently rescale the void. Nothing in the
## corpus does that today; the point is that the guarantee does not depend on it.
func _cut_radius() -> float:
	if _radius_explicit or breach == "opened" or not BREACH.has(breach):
		return sphere_radius
	return float(BREACH[breach]) * cube_size


## Offsets are FRACTIONS of cube_size so the wound tracks the cube it is in.
func _strike_fraction(which: String) -> Vector3:
	match which:
		"raised":
			return Vector3(0.0, 0.30, 0.0)
		"corner":
			return Vector3(0.24, 0.24, 0.24)
		"grazing":
			return Vector3(0.0, 0.48, 0.0)
		_:
			return Vector3.ZERO


func _cut_offset() -> Vector3:
	if _offset_explicit or strike == "centred" or not STRIKES.has(strike):
		return sphere_offset
	return _strike_fraction(strike) * cube_size


func _build() -> void:
	_built = true

	var cut_r: float = _cut_radius()
	var cut_off: Vector3 = _cut_offset()

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
	sph.radius = cut_r
	sph.radial_segments = 28
	sph.rings = 18
	sph.operation = CSGShape3D.OPERATION_SUBTRACTION
	sph.position = cut_off
	_combiner.add_child(sph)

	add_child(_combiner)

	# The point that carved the void — suspended at the sphere centre,
	# visible (and, if embedded, grabbable) through the face-mouths.
	if embed_artifact != "":
		# Embed a LIVE artifact (e.g. interactive_point_origin_force) at the
		# void centre — the cube is carved AROUND the real interactive point.
		# It rides the cut, so under `strike` the point that carved the void is
		# still IN the void it carved rather than buried in the surviving matter.
		_embed_live_point(cut_off)
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
		glint.position = cut_off
		add_child(glint)

	# Bake CSG -> static mesh next idle frame (CSG needs one tick to
	# compute). The baked mesh exports to GLB and is cheaper than live
	# CSG; the live CSG is freed once baked. Fallback: keep CSG if bake
	# returns nothing (e.g. very early headless frame).
	call_deferred("_bake_and_replace", mat)


# Instantiate a live artifact (looked up by name in the registry) at the
# void centre, forwarding its mode config. Used to nest the real interactive
# point inside the puncture it carved.
func _embed_live_point(at: Vector3) -> void:
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
		(pt as Node3D).position = at
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
	# Collider matching the carved mesh — the player collides with the solid
	# frame but can still pass through the face-mouths (the void is walkable).
	mi.create_trimesh_collision()
	_combiner.queue_free()
	_combiner = null
