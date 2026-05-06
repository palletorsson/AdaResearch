extends Area3D

@onready var paper_surface =   $"../DrawingArea3D/PaperDrawSurface"

# Called when the area is entered
func _on_area_entered(_area: Area3D) -> void:
	if paper_surface and paper_surface.has_method("reset_canvas"):
		paper_surface.reset_canvas()
