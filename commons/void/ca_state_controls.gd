extends Node
## Remount the same original controls/point facing the three receivers.
## The study remains local to its original artifact, including editor rotation.
const Block = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
func _ready() -> void:install.call_deferred()
func install() -> void:
	var work: Node3D = get_parent();var study: Node3D = work.get_node("StructureStudy")
	var at := Vector3(-2.45,1.05,2.65)
	var console: Node3D = study.get_node("Console")
	console.position = at;console.rotation_degrees = Vector3(-28,0,0)
	for title in ["ConsoleFoot","ConsoleStem"]:study.get_node(title).queue_free()
	var podium: Node3D = Block.instantiate();podium.name = "OperatingPodium";podium.platform_size = Vector3(1.25,.75,.65)
	work.add_child(podium);podium.position = at-Vector3(0,1.05,0)
	var hand: Node3D = study.get_node("StateHand")
	var old_dock := Vector3(-1.65,1.12,-3.55)
	var dock := Vector3(-1.45,1.12,2.65)
	hand.position = dock-old_dock
	for child in hand.get_children():
		if child is Label3D:child.rotation.y = 0;child.position.z = -3.535
	var card: Node3D = study.get_node("HandInstructions");card.position = Vector3(dock.x,.8,dock.z)
	var shelf: Node3D = Block.instantiate();shelf.name = "PointDock";shelf.platform_size = Vector3(.6,.9,.55)
	work.add_child(shelf);shelf.position = Vector3(dock.x,0,dock.z)
