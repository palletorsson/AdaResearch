extends "res://algorithms/color/colortrails/colortrails.gd"
## Keep the original ribbon sampler. Bind it to this visitor and retain its
## world-space vertices when the instrument is moved on a Void floor.
var desktop_tip: Node3D
func _ready() -> void:
	super._ready()
	for mesh in [_left_mesh_inst,_right_mesh_inst]:
		mesh.top_level=true
		mesh.global_transform=Transform3D.IDENTITY

func _process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("void_game")
	if game != null and is_instance_valid(game.camera):
		if game.vr:
			_left_hand=game.get_node("XROrigin3D/LeftHand")
			_right_hand=game.get_node("XROrigin3D/RightHand")
		else:
			if not is_instance_valid(desktop_tip):
				desktop_tip=Node3D.new();desktop_tip.name="MouseRibbonTip";add_child(desktop_tip)
			desktop_tip.global_transform=game.camera.global_transform*Transform3D(Basis.IDENTITY,Vector3(.25,-.2,-.8))
			_left_hand=null;_right_hand=desktop_tip
	super._process(delta)

func prepare_editor_preview() -> void:
	# Sample the real ribbon builder; this is explicitly an arrangement preview.
	var previous := get_viewport().get_camera_3d()
	var view := Camera3D.new();add_child(view)
	view.position=Vector3(0,2,4);view.make_current()
	_right_points.clear()
	for i in 24:
		var t:=float(i)/23.0
		_right_points.append({K_POS:to_global(Vector3(-1.5+t*3,1.3+sin(t*TAU)*.4,0)),K_AGE:0.8-t*.7,K_VEL:Vector3.ZERO})
	_build_ribbon(_right_mesh,_right_points,_right_mesh_inst,right_gradient)
	if previous!=null:previous.make_current()
	view.queue_free()
	var label:=Label3D.new();label.text="HAND TRAILS / sample preview";label.position=Vector3(0,.7,0);label.pixel_size=.002;add_child(label)
