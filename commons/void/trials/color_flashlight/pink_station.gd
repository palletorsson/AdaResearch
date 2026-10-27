extends "res://commons/artifacts/spine_studies/station.gd"
## The original five-switch sphere, with its console brought inside the bay.
const STUDY_LAYER := 1 << 18

func _build_controls() -> void:
	console_z = 3.1
	super._build_controls()

func _ready() -> void:
	super._ready()
	for mesh in specimen.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = STUDY_LAYER
		if mesh.mesh is BoxMesh and mesh.mesh.size.y < .02:
			for body in mesh.find_children("*", "StaticBody3D", true, false):
				body.set_meta("void_floor_surface", true)
	for lamp in specimen.lights:
		lamp.light_cull_mask = STUDY_LAYER
