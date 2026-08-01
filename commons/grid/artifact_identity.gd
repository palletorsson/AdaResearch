extends RefCounted
class_name ArtifactIdentity
## The stamp a registered artifact needs before it enters the tree.
##
## GridInteractablesComponent does this for every artifact a MAP places: it writes
## `artifact_lookup_name` and one `config_<key>` meta per config entry onto the root, BEFORE
## add_child, so the metadata is already there when the children's _ready() runs.
##
## Artifacts placed by a COMPOSER never got it. curation_station and sim_cube each scan the
## registry themselves, load the scene and add_child it, and neither stamped anything. Two
## consequences, both invisible until measured:
##
##   - An artifact whose registry entry declares `default_params` never received them. Four
##     registry names share one grab-sphere scene and declare four different colours; the
##     seven placed directly by the grid render red, blue, green and magenta, and the
##     seventeen composed inside a wrapper all render the fallback pink. Same artifact, same
##     map, two different answers depending on who placed it.
##   - An artifact that is ONE SCENE UNDER MANY NAMES — specimen_plinth, chair_kit,
##     dome_kit, sculpture_kit, array_probe, constraint_demo, qfep_term_grasp — reads
##     `artifact_lookup_name` to decide WHICH member to build. Without the stamp it cannot
##     know, so a map asking a curation bay for `cube_specimen` was handed the fallback.
##
## So this exists to be called from exactly one place per composer, and to make the next
## composer correct by construction rather than by remembering.
##
## ORDERING IS THE WHOLE CONTRACT: call it BEFORE add_child. A consumer reads these in its
## own _ready(), which fires on tree entry, so a stamp applied afterwards is a stamp the
## artifact never saw.


## Write identity + declared defaults onto `inst`.
##
## `entry` is the artifact's own registry dict. Only `default_params` is read from it; a
## caller that has no entry can pass {} and still get the identity stamp, which is the half
## that costs nothing and fixes the one-scene-many-names families.
static func stamp(inst: Node, lookup_name: String, entry: Dictionary = {}) -> void:
	if inst == null or lookup_name == "":
		return
	inst.set_meta("artifact_lookup_name", lookup_name)

	var dp: Variant = entry.get("default_params", null)
	if not (dp is Dictionary):
		return
	# Same channel a map token uses — `#color:4080FF` and a declared default arrive at the
	# artifact as the identical `config_color` meta, so a consumer needs one code path and
	# cannot tell (or need to tell) which of the two placed it.
	for k in (dp as Dictionary).keys():
		var key := "config_" + str(k)
		# A value already stamped WINS. The grid layers weakest-first — registry defaults,
		# then delegate params, then the map token — and a composer must not overwrite a
		# more specific value that is already present.
		if not inst.has_meta(key):
			inst.set_meta(key, (dp as Dictionary)[k])


## The registry entry for a lookup name, or {} if there is none.
##
## Both composers already walk commons/artifacts/registry/*.json with their own copy of this
## loop, and both kept only the scene path — which is exactly why neither could stamp
## default_params. Returning the whole entry means a caller keeps the option.
static func registry_entry(lookup_name: String) -> Dictionary:
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return {}
	for fn in dir.get_files():
		if not fn.ends_with(".json"):
			continue
		var f := FileAccess.open("res://commons/artifacts/registry/" + fn, FileAccess.READ)
		if f == null:
			continue
		var data: Variant = JSON.parse_string(f.get_as_text())
		if not (data is Dictionary):
			continue
		var arts: Variant = (data as Dictionary).get("artifacts", {})
		if arts is Dictionary and (arts as Dictionary).has(lookup_name):
			var e: Variant = (arts as Dictionary)[lookup_name]
			if e is Dictionary:
				return e
	return {}
