extends Node3D
## Reusable glass barrier, closed by default. Visor workstations leave it closed;
## the retained open animation is available to other experiments.
var pane:MeshInstance3D
var barrier:AnimatableBody3D
var collision:CollisionShape3D
var height:=5.4
var width:=6.6
var opening:=false
var opened:=false
var travel:Tween

func configure(size:float,tall:float,material:Material)->void:
	width=size;height=tall
	pane=MeshInstance3D.new();pane.name="RetractingGlass"
	var box:=BoxMesh.new();box.size=Vector3(width,1,.014);pane.mesh=box
	pane.material_override=material;pane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(pane)
	barrier=AnimatableBody3D.new();barrier.name="FrontBarrier";barrier.collision_layer=1;add_child(barrier)
	collision=CollisionShape3D.new();collision.shape=BoxShape3D.new();barrier.add_child(collision)
	set_fraction(1)

func set_fraction(value:float)->void:
	var tall:float=maxf(.004,height*value)
	pane.position.y=tall*.5;pane.scale.y=tall
	barrier.position.y=tall*.5;collision.shape.size=Vector3(width,tall,.035)

func open()->void:
	if opened or opening:return
	opening=true
	travel=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	travel.tween_method(set_fraction,1.0,0.0,1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	travel.tween_callback(finish_open)

func finish_open()->void:
	barrier.collision_layer=0;collision.set_deferred("disabled",true)
	pane.hide();opened=true;opening=false
