extends Node3D
class_name WordIs

## Text standing in space — and the one path that made it reach the museum.
##
## Palle, 2026-08-27: "in the grid system we can write text in space like can we
## add the same to endless museums as a text artifact?"
##
## The grid has three ways to write text and the museum sees NONE of them.
## `_derive_map_row` (endless_museum.gd) reads layers.structure and
## layers.interactables and never opens layers.utilities — so `an:` (433
## placements), `sub:` (123) and `3t` itself (172) are invisible to the museum,
## because every one of them is a UTILITY.
##
## `3t` was the near miss. It is registered BOTH as a utility code and as an
## artifact (lookup_name "3t", scene word_is.tscn), so it can already be written
## into layers.interactables, which the museum does read. But the scene had no
## script: its text was set from outside by GridUtilitiesComponent
## ._apply_text_display_text, on the utilities path only. So the one interactable
## placement in the corpus — `3t:Superposition` at (9,3) in ForcesComposition —
## renders the scene's DEFAULT baked sentence, "A point is entropy that has
## cooled into memory.", and nothing anywhere reports that it did.
##
## This script is what closes that: the root now carries its own text, so the
## same scene works from an interactable token in a museum hall and from a
## utility in the grid, and neither path has to know about the other.
##
##   layers.interactables   "3t#text:A_POINT_IS_A_DECISION"
##   layers.utilities       "3t:A_POINT_IS_A_DECISION"      (unchanged)
##
## UNDERSCORES BECOME SPACES, which is not decoration: a map cell is colon- and
## hash-delimited, so a token carrying real spaces survives the parser but reads
## badly in a compact-rows grid line. The utilities path already made that
## choice (GridUtilitiesComponent:1127) and this matches it rather than
## inventing a second dialect.

## The words. Underscores become spaces.
@export_multiline var text: String = ""
## Cap height in metres. The scene ships its TextMesh at Godot's default; a hall
## wants something a body can read from across it.
@export var size_m: float = 0.6
## How far off the wall it stands. 0 keeps the scene's own transform.
@export var depth_m: float = 0.0
@export var upper: bool = true
@export var colour: Color = Color(0.92, 0.90, 0.86)
## Lit rather than shaded: text on an unlit museum wall reads as a grey smear.
@export var glow: float = 0.35

var _applied: bool = false


func _ready() -> void:
	# ONLY IF A TOKEN ALREADY SPOKE. The museum calls apply_grid_config BEFORE
	# _ready and the grid calls it after, so a _ready that writes unconditionally
	# would erase the museum's own instruction. And on the utilities path nothing
	# calls it at all — there the scene must keep the text
	# GridUtilitiesComponent is about to set from outside.
	if _applied:
		_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	var msg: String = _first_string(config_data, ["text", "message", "words", "3t"])
	if msg != "":
		text = msg
	size_m = _num(config_data, ["size_m", "size", "height"], size_m)
	depth_m = _num(config_data, ["depth_m", "depth"], depth_m)
	glow = _num(config_data, ["glow", "energy"], glow)
	if config_data.has("upper"):
		upper = bool(config_data["upper"])
	_applied = true
	if is_inside_tree():
		_build()


func _first_string(cfg: Dictionary, keys: Array) -> String:
	for k in keys:
		if cfg.has(k):
			var v: Variant = cfg[k]
			# A BARE FLAG IS NOT A MESSAGE. `#text:12` is read by
			# GridInteractablesComponent as tutorial shorthand — the artifact
			# receives `true` and the map silently gains a 12 degree rotation.
			# Taking bool(true) as the words would print "True" on the wall.
			if typeof(v) == TYPE_BOOL:
				continue
			var s: String = str(v).strip_edges()
			if s != "":
				return s
	return ""


func _num(cfg: Dictionary, keys: Array, fallback: float) -> float:
	for k in keys:
		if cfg.has(k) and typeof(cfg[k]) != TYPE_BOOL:
			var s: String = str(cfg[k]).strip_edges()
			if s.is_valid_float():
				return float(s)
	return fallback


func _build() -> void:
	var mi: MeshInstance3D = _mesh()
	if mi == null:
		push_warning("word_is: no MeshInstance3D under %s — nothing to write on" % name)
		return
	var tm: TextMesh = mi.mesh as TextMesh
	if tm == null:
		push_warning("word_is: the mesh is not a TextMesh — refusing to replace it")
		return
	# DUPLICATE, never mutate. The TextMesh is a sub-resource of a scene that is
	# instanced 172 times; writing through the shared resource would rewrite
	# every other sign in the map with this one's words.
	var own: TextMesh = tm.duplicate()
	if text.strip_edges() != "":
		own.text = text.replace("_", " ").strip_edges()
	own.uppercase = upper
	if size_m > 0.0:
		own.font_size = int(max(8.0, size_m * 64.0))
		own.pixel_size = size_m / max(1.0, float(own.font_size)) * 64.0 * 0.0156
	if depth_m > 0.0:
		own.depth = depth_m
	mi.mesh = own
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = colour
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = colour
		mat.emission_energy_multiplier = glow
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat


func _mesh() -> MeshInstance3D:
	for c in get_children():
		if c is MeshInstance3D:
			return c as MeshInstance3D
	for c in find_children("*", "MeshInstance3D", true, false):
		return c as MeshInstance3D
	return null
