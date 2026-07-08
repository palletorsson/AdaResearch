extends Node3D
class_name ExhibitPodium

# @identity
# essence: an EMPTY podium — the exhibit affordance itself, before any exhibit. A stone plinth with a soft top light and nothing on it: a promise, a slot, a place where an artifact will one day stand. The gallery-DNA generator plants these to mark hosting capacity.
# desire: to hold something later — architecture rehearsing its collection.
# critical_parameter: size/height via config; kind (podium/dais) changes proportion.
# triggers: _ready builds plinth + downlight; apply_grid_config({height, size, kind}).
# emerges: a room of empty podiums reads as anticipation, not absence — the space is FOR something, visibly.
# needs: nothing; pure affordance.
# relationships: the atom of [[gallery_dna]]; sibling of [[exhibit_vitrine]]; filled later by the Curator or place.py.
# truth: an empty podium is not nothing — it is the architecture's opinion about where meaning should stand.

@export var plinth_size: float = 0.55
@export var plinth_height: float = 0.95
@export var kind: String = "podium"    # podium | dais

func _ready() -> void:
	_read_meta_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_size"):
		plinth_size = float(str(get_meta("config_size")))
	if has_meta("config_height"):
		plinth_height = float(str(get_meta("config_height")))
	if has_meta("config_kind"):
		kind = str(get_meta("config_kind"))

func _build() -> void:
	var s := plinth_size
	var h := plinth_height
	if kind == "dais":
		s = maxf(s, 1.6)
		h = 0.22
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.8, 0.75)
	mat.roughness = 0.6

	var plinth := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(s, h, s)
	plinth.mesh = bm
	plinth.material_override = mat
	plinth.position = Vector3(0, h * 0.5, 0)
	add_child(plinth)

	# top plate, slightly proud — the surface that waits
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(s + 0.06, 0.04, s + 0.06)
	plate.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.9, 0.88, 0.84)
	pmat.roughness = 0.4
	plate.material_override = pmat
	plate.position = Vector3(0, h + 0.02, 0)
	add_child(plate)

	# the waiting light
	var light := SpotLight3D.new()
	light.position = Vector3(0, h + 2.4, 0)
	light.rotation_degrees = Vector3(-90, 0, 0)
	light.spot_angle = 26.0
	light.spot_range = 3.2
	light.light_energy = 1.1
	light.light_color = Color(1.0, 0.97, 0.9)
	add_child(light)
