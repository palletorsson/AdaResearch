extends "res://addons/godot-xr-tools/objects/pickable.gd"
## One physical delivery, shared by desktop and XR hands.
signal grabbed_by_player(body)

var kind := -1
var printed := false
var sorting := false
var desktop_held := false
var desktop_holder: Node
var edge := 0.32
var visual: MeshInstance3D
var shape_node: CollisionShape3D

func _ready() -> void:
	super._ready()
	picked_up.connect(_on_pickup)

func _on_pickup(_body: Node) -> void:
	grabbed_by_player.emit(self)

func is_held() -> bool:
	return desktop_held or is_picked_up()

func on_desktop_grab(pointer: Node) -> void:
	desktop_held = true
	desktop_holder = pointer
	grabbed_by_player.emit(self)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	desktop_holder = null
	freeze = false
	sleeping = false

func release_for_reset() -> void:
	if desktop_held and is_instance_valid(desktop_holder) and desktop_holder.has_method("_drop_held"):
		desktop_holder.call("_drop_held")
	desktop_held = false
	desktop_holder = null
	drop()

func resize_to(size: float) -> void:
	edge = maxf(0.01, size)
	if is_instance_valid(visual): visual.scale = Vector3.ONE * edge
	if is_instance_valid(shape_node): shape_node.shape.size = Vector3.ONE * edge
