extends Node
## Curated CA laboratory: the old hall never supplied its required palm scanner.
## Keep the original door/tweens/collision; connect its existing proximity sensor.
func _ready() -> void:
	install.call_deferred()
func install() -> void:
	var door: Node = get_parent().find_child("DoorHandler",true,false)
	if door==null:return
	door.auto_open_on_proximity = true
	if door.area!=null:
		if not door.area.body_entered.is_connected(door._on_body_entered):door.area.body_entered.connect(door._on_body_entered)
		if not door.area.body_exited.is_connected(door._on_body_exited):door.area.body_exited.connect(door._on_body_exited)
