extends Node3D
## Twelve independent points share one local graph. No barrier is wired to it.
const Kit=preload("geometry.gd")
const Point=preload("res://commons/primitives/snappoint/snap_point.tscn")
const Driver=preload("corridor_point.gd")
const Manager=preload("res://commons/primitives/snappoint/snap_connection_manager.gd")
var points: Array[Node3D]=[]
var manager: Node
func _ready() -> void:
	manager=Manager.new();manager.name="SnapConnectionManager";add_child(manager)
	for i in 12:
		var p:=Point.instantiate() as Node3D;p.set_script(Driver)
		p.name="Point%02d"%i;p.position=Vector3(-1.5+(i%4),1.05+0.13*(i%2),-1.4+(i/4)*1.4)
		p.snap_distance=0.28;p.release_mode=XRToolsPickable.ReleaseMode.FROZEN
		var sphere:=SphereShape3D.new();sphere.radius=0.055
		p.get_node("CollisionShape3D").shape=sphere
		p.get_node("MeshInstance3D/Sphere").set("radius",0.045)
		p.get_node("MeshInstance3D/Sphere").set("color",Color("25212b"))
		add_child(p);points.append(p)
	Kit.label(self,"Bring two points close. Release.\nMove them apart: the line follows.",Vector3(0,0.015,2.0),28).rotation.x=-PI/2
