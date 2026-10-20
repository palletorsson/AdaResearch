extends Node3D
## Permanent furniture around the exact, already printed ABM study.
const Study = preload("lesson/study.tscn")
var study:Node3D
var selected:MeshInstance3D

func _ready()->void:
	process_priority=1 # Follow the study's freshly painted point positions.
	study=Study.instantiate();add_child(study)
	box(Vector3(2.7,.08,2.7),Vector3(0,.89,0),Color("242832"),false)
	box(Vector3(1.3,.85,1.3),Vector3(0,.425,0),Color("dfdcd6"))
	box(Vector3(2.5,.12,.32),Vector3(0,.77,1.60),Color("dfdcd6"))
	box(Vector3(.18,.71,.18),Vector3(-1.04,.355,1.60),Color("dfdcd6"))
	box(Vector3(.18,.71,.18),Vector3(1.04,.355,1.60),Color("dfdcd6"))
	var instructions:Label3D=study.label("HOLD a point: pause all six / TRIGGER: select\nMOVE to FOOD / RELEASE / ONE TICK",Vector3(0,1.2,1.5),18)
	instructions.name="HandInstructions"
	selected=MeshInstance3D.new();selected.name="SelectedPointRing"
	var ring:=TorusMesh.new();ring.inner_radius=.105;ring.outer_radius=.112;ring.rings=32;ring.ring_segments=6
	selected.mesh=ring
	var finish:=StandardMaterial3D.new();finish.albedo_color=Color.WHITE;finish.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	selected.material_override=finish;add_child(selected)
	_process(0)

func _process(_delta:float)->void:
	if study==null or study.points.is_empty():return
	selected.position=to_local(study.points[study.witness].global_position)-Vector3.UP*.065
	for key in ["Run","Step","Replace","Reset"]:
		study.get_node(key).set_selected(key=="Run" and study.playing)

func box(size:Vector3,at:Vector3,colour:Color,visible_surface:bool=true)->void:
	var body:=StaticBody3D.new();body.position=at;add_child(body)
	var surface:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;surface.mesh=mesh
	var finish:=StandardMaterial3D.new();finish.albedo_color=colour;surface.material_override=finish;body.add_child(surface)
	surface.visible=visible_surface
	var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)

func get_museum_occupied_cells()->Array[Vector2i]:
	var cells:Array[Vector2i]=[]
	for rect in [Rect2(-1.35,-1.35,2.7,2.7),Rect2(-1.25,1.44,2.5,.32)]:
		for x in range(ceili(rect.size.x*4)+1):
			for z in range(ceili(rect.size.y*4)+1):
				var p:=to_global(Vector3(rect.position.x+x*.25,0,rect.position.y+z*.25));var cell:=Vector2i(floori(p.x),floori(p.z))
				if not cells.has(cell):cells.append(cell)
	return cells
