extends "res://addons/godot-xr-tools/objects/pickable.gd"
## Same release-to-slot operation for desktop grab and XR pickup.
signal placement_requested(cube)
signal lifted(cube)
var cube_id := 0
var desktop_held := false

func _ready() -> void:
	super._ready()
	picked_up.connect(func(_body): lifted.emit(self))
	dropped.connect(func(_body): placement_requested.emit(self))

func held() -> bool:
	return desktop_held or is_picked_up()

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true
	lifted.emit(self)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	placement_requested.emit(self)
