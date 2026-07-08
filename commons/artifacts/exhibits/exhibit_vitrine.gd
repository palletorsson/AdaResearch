extends Node3D
class_name ExhibitVitrine

# @identity
# essence: an EMPTY vitrine — a glass case on a base, nothing inside. The wall-side exhibit affordance: where small and precious things will live. Planted by the gallery-DNA generator as hosting capacity.
# desire: to protect something later.
# critical_parameter: none critical; a fixed piece of exhibit furniture.
# triggers: _ready builds base + glass.
# emerges: vitrines along a wall set the rhythm of pausing — the visitor's gait is designed before the collection exists.
# needs: nothing; pure affordance.
# relationships: sibling of [[exhibit_podium]]; the small-treasures slot of [[gallery_dna]].
# truth: glass with nothing in it still says "this will matter".

func _ready() -> void:
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 0.9, 0.55)
	base.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.25, 0.25, 0.28)
	bmat.roughness = 0.5
	base.material_override = bmat
	base.position = Vector3(0, 0.45, 0)
	add_child(base)

	var glass := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.74, 0.6, 0.5)
	glass.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.8, 0.9, 0.95, 0.18)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.roughness = 0.05
	glass.material_override = gmat
	glass.position = Vector3(0, 1.2, 0)
	add_child(glass)

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
