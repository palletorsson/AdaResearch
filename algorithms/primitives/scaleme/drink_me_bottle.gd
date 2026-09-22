extends XRToolsPickable

var encounter: Node3D
var consumed := false

func _ready() -> void:
	super._ready()
	picked_up.connect(_taken_in_vr)

func _taken_in_vr(_pickable: Variant) -> void:
	var controller := get_picked_up_by_controller()
	if controller:
		_take.call_deferred(XRToolsPlayerBody.find_instance(controller), null)

func on_desktop_grab(pointer: Node) -> void:
	var actor := pointer.get_parent()
	while actor and not actor is CharacterBody3D:
		actor = actor.get_parent()
	_take.call_deferred(actor, pointer)

func _take(actor: Node3D, pointer: Node) -> void:
	if consumed or not is_instance_valid(actor):
		return
	consumed = true
	if is_instance_valid(pointer) and pointer.get("_held") == self:
		pointer.call("_drop_held")
	if is_picked_up():
		drop()
	enabled = false
	collision_layer = 0
	collision_mask = 0
	hide()
	encounter.enlarge(actor)
