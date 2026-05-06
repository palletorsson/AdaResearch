# sdf_gallery_artifact.gd
# Ada-integrated version of the SDF gallery — drops the gallery's form rows
# into any map cell as an artifact. Does NOT build its own floor/lights;
# the host map provides those.
#
# Registered in artifact registry as `sdf_gallery_room`. Place a single
# interactable cell in map_data.json with this token and the full seven-row
# gallery appears at that cell, extending north from it.

extends Node3D

const SDFGalleryBody = preload("res://commons/morphology/sdf/gallery/sdf_gallery.gd")


func _ready() -> void:
	# Spawn the gallery body with chrome disabled — host map supplies floor/lights.
	var gallery := Node3D.new()
	gallery.name = "GalleryBody"
	gallery.set_script(SDFGalleryBody)
	gallery.set("include_chrome", false)
	add_child(gallery)


# Accept apply_grid_config for compatibility with Ada's grid artifact loader.
# No grid config is needed here — the gallery is self-positioning.
func apply_grid_config(_config_data: Dictionary) -> void:
	pass
