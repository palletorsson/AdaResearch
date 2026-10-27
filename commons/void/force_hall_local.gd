extends "res://commons/artifacts/force_halls/hall_display.gd"
## Keep the museum's actual lectern, title and catalyst. Its long-hall floor
## markings are architecture, not force instruments; Void supplies that floor.
func _ready() -> void:
	super._ready()
	for child in get_children():
		if not child is Node3D: continue
		if child.name == "ForcesCatalyst":
			child.position = Vector3(2.4,0.55,0)
		elif child is Label3D and child.text.begins_with("CATALYST / FORCES"):
			child.position = Vector3(2.4,1.95,0)
		elif child.position.z >= 2.7 and child.position.z <= 3.1 and child.position.x < 3:
			child.position -= Vector3(2.1,0,3)
		elif child.position.y >= 3.0:
			child.position = Vector3(0,child.position.y-0.7,-0.6)
		else:
			remove_child(child)
			child.queue_free()

func travel(direction: int) -> bool:
	var game: Node = self
	while game != null and not game.has_method("spawn_for"):game=game.get_parent()
	var floor_root: Node = self
	while floor_root.get_parent() and not floor_root.has_meta("em_map"):
		floor_root = floor_root.get_parent()
	if game == null or not game.has_method("spawn_for"):
		travel_status.text = "PLAY IN THE VOID TO CHANGE FLOORS"
		return false
	var current := -1
	for i in game.building.content.data.floors.size():
		if game.building.content.data.floors[i].map == floor_root.get_meta("em_map", ""):
			current = i
	var target: int = current + direction
	if current < 1 or target < 1 or target >= game.building.content.data.floors.size()-1:
		travel_status.text = "END OF THIS TRANSFER COLLECTION"
		return false
	game.place_player(game.spawn_for(target))
	return true
