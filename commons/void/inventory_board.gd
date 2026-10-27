extends Node3D
## Pointer-operated inventory works with the desktop pointer and both XR hands.
var game: Node3D
var inventory: Node
var readout: Label3D
var place_button: Node3D
var selected := ""
var placement_from := Vector3.ZERO
var placement_direction := Vector3.FORWARD

func _ready() -> void:
	readout = Label3D.new()
	readout.name = "InventoryReadout"
	readout.font_size = 36; readout.pixel_size = .0015; readout.outline_size = 0
	readout.modulate = Color("f1eadc"); readout.position.y = .17
	add_child(readout)
	var panel := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = Vector3(1.35,.82,.035); panel.mesh = mesh
	var finish := StandardMaterial3D.new(); finish.albedo_color = Color("20282a"); finish.roughness = .85
	panel.material_override = finish; panel.position.z = -.035; add_child(panel)
	place_button = _button("Place", "PLACE AND", Vector3(-.25,-.23,.03))
	place_button.pressed.connect(func(): game.place_inventory_prefab(selected))
	_button("Close", "CLOSE", Vector3(.25,-.23,.03)).pressed.connect(func(): hide())
	inventory.changed.connect(refresh)
	visibility_changed.connect(_sync_colliders)
	refresh(); hide()

func _button(title: String, label: String, at: Vector3) -> Node3D:
	var button := preload("res://commons/interactables/cube_button.tscn").instantiate()
	button.name = title; button.label = label; button.cube_size = .09; button.position = at
	button.accent = Color("e5b889"); add_child(button)
	return button

func refresh() -> void:
	selected = ""
	for id in inventory.definitions:
		if inventory.definitions[id].has("completion"): selected = str(id); break
	if selected.is_empty(): return
	var definition: Dictionary = inventory.definitions[selected]
	var available: bool = inventory.unlocked(selected)
	readout.text = "PLAYER INVENTORY\n%s\n%s" % [definition.title, "UNLOCKED / reusable assembly\nAim at a clear slab, then place.\nSession copy; permanent editing in the lab." if available else "LOCKED / Cube floor 7\nObserve 00, 01, 10 and 11.\nTwo gaps. Two cubes. One ball."]
	place_button.visible = available
	# Hide also removes its input collider; a locked invisible button cannot fire.
	place_button.process_mode = Node.PROCESS_MODE_INHERIT if available else Node.PROCESS_MODE_DISABLED
	for shape in place_button.find_children("*","CollisionShape3D",true,false): shape.set_deferred("disabled", not available)
	_sync_colliders()

func _sync_colliders() -> void:
	for shape in find_children("*","CollisionShape3D",true,false):
		shape.set_deferred("disabled",not visible or (place_button.is_ancestor_of(shape) and not inventory.unlocked(selected)))

func toggle() -> void:
	if visible: hide(); return
	refresh()
	var view: Camera3D = game.camera
	placement_from = view.global_position
	placement_direction = -view.global_basis.z
	global_position = view.global_position - view.global_basis.z * 1.35
	global_rotation = Vector3(0,view.global_rotation.y,0)
	show()
