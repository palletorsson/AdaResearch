extends "res://commons/modular/recipe_area.gd"
## Reused boards and blocks, flattened into the existing editable-part contract.
const Finish=preload("res://commons/modular/sphere_fractal_finish.gd")

func rebuild() -> void:
	# Keep old trial-local studies; new stages share the reusable catalogue term.
	recipe="fractal_studio_stage" if recipe_document.is_empty() else "fractal_stage"
	super.rebuild()
	for child in get_children():
		var role: String="ivory" if child.name=="Backdrop" else "pink" if str(child.name).begins_with("Edge") else "steel"
		Finish.apply(child,role)
