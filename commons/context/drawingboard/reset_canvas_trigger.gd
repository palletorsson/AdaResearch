extends Area3D

@onready var paper_surface =   $"../DrawingArea3D/PaperDrawSurface"

# Called when the area is entered
func _on_area_entered(area: Area3D) -> void:
	paper_surface._next_page()
