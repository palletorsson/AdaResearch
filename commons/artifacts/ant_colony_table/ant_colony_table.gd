extends Node3D
## Original Ant Colony V2, viewed at table scale without shrinking its physics.
const World = preload("res://commons/artifacts/ant_scale_atlas/v2_world.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
var model:Node
var screen:MeshInstance3D
var pause_button:Node3D
var status:Label3D

func _ready()->void:
	model=World.new();model.name="OriginalAntWorld";add_child(model)
	model.viewport.size=Vector2i(1024,1024)
	model.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var view:=Camera3D.new();model.viewport.add_child(view)
	view.projection=Camera3D.PROJECTION_ORTHOGONAL;view.size=54
	view.position=Vector3(0,60,0);view.rotation_degrees=Vector3(-90,0,0);view.current=true
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("1a2630")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.5
	model.viewport.add_child(environment)
	screen=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(1.8,1.8)
	screen.mesh=plane;screen.position=Vector3(0,1.01,0)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture=model.viewport.get_texture();screen.material_override=material;add_child(screen)
	box(Vector3(2,.1,2),Vector3(0,.95,0),Color("28313b"))
	box(Vector3(.65,.9,.65),Vector3(0,.45,0),Color("e3dfd6"))
	box(Vector3(.32,.08,.35),Vector3(.68,.95,1.2),Color("28313b"))
	pause_button=PushButton.instantiate();add_child(pause_button)
	pause_button.position=Vector3(.68,1.03,1.2);pause_button.rotation=Vector3.ZERO
	pause_button.pressed.connect(toggle_play)
	words("ANT COLONY V2",Vector3(0,1.8,-.7),34)
	words("Travellers write their own trails.\nOne original colony / 50 m shown at 1.8 m",Vector3(0,1.58,-.7),18)
	status=words("PAUSE / PLAY",Vector3(.68,1.25,1.2),12)
	model.set_running(true)

func box(size:Vector3,at:Vector3,colour:Color)->void:
	var body:=StaticBody3D.new();body.position=at;add_child(body)
	var mesh:=BoxMesh.new();mesh.size=size
	var visual:=MeshInstance3D.new();visual.mesh=mesh;body.add_child(visual)
	var material:=StandardMaterial3D.new();material.albedo_color=colour;visual.material_override=material
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size
	collision.shape=shape;body.add_child(collision)

func words(text:String,at:Vector3,size:int)->Label3D:
	var label:=Label3D.new();label.text=text;label.position=at;label.font_size=size
	label.pixel_size=.002;label.outline_size=5;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label);return label

func toggle_play()->void:
	model.set_running(not model.running)
	pause_button.set_selected(not model.running)
	status.text="PAUSED / press to play" if not model.running else "PAUSE / PLAY"

func get_museum_occupied_cells()->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	for rect in [Rect2(-1,-1,2,2),Rect2(.52,1.02,.32,.36)]:
		for x in range(ceili(rect.size.x*4)+1):
			for z in range(ceili(rect.size.y*4)+1):
				var p:=to_global(Vector3(rect.position.x+x*.25,0,rect.position.y+z*.25))
				var c:=Vector2i(floori(p.x),floori(p.z))
				if not result.has(c):result.append(c)
	return result
