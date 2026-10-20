extends StaticBody3D
## Pointer and near-hand input share the same declared wall-to-UV conversion.
var chamber: Node3D
var pressed: Dictionary = {}
var touches: Dictionary = {}
var elapsed:=0.0

func pointer_event(event:XRToolsPointerEvent)->void:
	var key:int=event.pointer.get_instance_id() if is_instance_valid(event.pointer) else 0
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			pressed[key]=true;chamber.mark_world(event.position)
		XRToolsPointerEvent.Type.MOVED:
			if pressed.has(key):chamber.mark_world(event.position)
		XRToolsPointerEvent.Type.RELEASED,XRToolsPointerEvent.Type.EXITED:pressed.erase(key)

func _physics_process(delta:float)->void:
	elapsed+=delta
	if elapsed<.05:return
	elapsed=0
	var live:Dictionary={}
	for hand in get_tree().get_nodes_in_group("xr_controllers"):
		if not hand is Node3D:continue
		if hand is XRController3D and not hand.get_is_active():continue
		var key:int=hand.get_instance_id();var at:Vector3=to_local(hand.global_position)
		if at.z<-.03 or at.z>.12 or absf(at.x)>2.8 or absf(at.y)>2.8:continue
		live[key]=true
		if not touches.has(key) or at.distance_to(touches[key])>.045:
			chamber.mark_world(hand.global_position);touches[key]=at
	for key in touches.keys():
		if not live.has(key):touches.erase(key)
