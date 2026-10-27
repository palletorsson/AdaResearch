extends "res://commons/artifacts/spine_studies/station.gd"
## Fit the two existing headings below the slab; cameras and recordings stay native.
func _ready() -> void:
	study = "witness"
	super._ready()
	for label in specimen.find_children("*", "Label3D", true, false):
		if label.position.y > 5.3:
			label.position.y -= .4

func activate(index: int) -> void:
	# The source delay control clears a dictionary also stored in its history.
	# Detach the delayed selection first so buffered frame timestamps survive.
	if index == 1:
		specimen.delayed_frame = {}
	super.activate(index)
