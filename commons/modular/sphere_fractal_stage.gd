extends "res://commons/modular/recipe_area.gd"
## Reused boards and blocks, flattened into the existing editable-part contract.
const Finish=preload("res://commons/modular/sphere_fractal_finish.gd")

func rebuild() -> void:
	recipe="fractal_stage"
	if recipe_document.is_empty():recipe_document="res://commons/void/trials/spatial_lab_ca573ae619/stage/recipe.json"
	super.rebuild()
	for child in get_children():
		var role: String="ivory" if child.name=="Backdrop" else "pink" if str(child.name).begins_with("Edge") else "steel"
		Finish.apply(child,role)
