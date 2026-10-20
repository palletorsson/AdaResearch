extends Node3D
## Presentation/control adapter. The original thirty-boid integrator is untouched.
const Original=preload("res://commons/artifacts/flocking_controls/flocking_controls.tscn")
const Point=preload("res://commons/artifacts/particle_swarm_walk/point_body.gd")
const PushButton=preload("res://commons/interactables/push_button.tscn")
const HOME:=Vector3(-.72,1.15,.65)
const COLOURS=[Color("ff6666"),Color("68aaff"),Color("63ee98"),Color.WHITE]
var flock:Node3D
var point:Node3D
var playing:=true
var was_held:=false
var anchor_x:=0.0
var anchor_radius:=.2
var dropped_time:=0.0
var info:Label3D
var values:Label3D
var pause_button:Node3D
var links:MultiMeshInstance3D
var rings:Array[MeshInstance3D]=[]
var shafts:Array[MeshInstance3D]=[]
var tips:Array[MeshInstance3D]=[]
var reading:Dictionary={}

func _ready()->void:
	flock=Original.instantiate();flock.position=Vector3(0,1.32,0);add_child(flock)
	flock.set_process(false)
	flock._control_panel.position=Vector3(0,-.16,.65)
	# The lens shows fresh requests for body zero, before its next turn.
	# Original cached arrows refer to the preceding integration step.
	flock._force_mesh.hide();flock._title_label.hide();flock._info_label.hide()
	box(Vector3(1.12,.12,1.32),Vector3(0,.94,.16),Color("303743"))
	box(Vector3(.6,.88,.6),Vector3(0,.44,0),Color("e0ddd5"))
	box(Vector3(.26,1,.28),Vector3(HOME.x,.5,HOME.z),Color("e0ddd5"))
	point=Point.new();point.name="PointBody";add_child(point);point.position=HOME
	point.action_pressed.connect(func(_p):
		if point.held():toggle_play())
	pause_button=PushButton.instantiate();add_child(pause_button);pause_button.position=Vector3(.72,1.06,.65)
	pause_button.pressed.connect(toggle_play)
	box(Vector3(.26,1,.28),Vector3(.72,.5,.65),Color("e0ddd5"))
	words("WHO ENTERS THE RADIUS?",Vector3(0,2.1,-.15),25)
	info=words("",Vector3(0,1.95,-.15),17)
	values=words("",Vector3(0,1.79,-.15),12)
	words("Hold point / move left or right\nNARROW  <   RADIUS   >  WIDE\nTrigger: pause / play",Vector3(-.76,1.44,.84),12)
	words("PAUSE / PLAY",Vector3(.72,1.3,.7),12)
	words("Arrows: next requests for the gold body\nRed: separate / Blue: align / Green: cohere / White: sum\nLength compressed; numbers show full magnitude",Vector3(0,.69,.86),12)
	for axis in range(3):
		var ring:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=.995;torus.outer_radius=1.005;torus.rings=48;torus.ring_segments=6
		ring.mesh=torus;ring.material_override=material(Color("f2d278"));flock.add_child(ring)
		if axis==1:ring.rotation.x=PI/2
		if axis==2:ring.rotation.z=PI/2
		rings.append(ring)
	links=MultiMeshInstance3D.new();links.multimesh=MultiMesh.new();links.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	links.multimesh.mesh=cylinder(.0014);links.multimesh.instance_count=29;links.multimesh.visible_instance_count=0
	links.material_override=material(Color("f2d278"));flock.add_child(links)
	for c in COLOURS:
		var shaft:=MeshInstance3D.new();shaft.mesh=cylinder(.003);shaft.material_override=material(c);flock.add_child(shaft);shafts.append(shaft)
		var tip:=MeshInstance3D.new();var cone:=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=.012;cone.height=.035;cone.radial_segments=8
		tip.mesh=cone;tip.material_override=shaft.material_override;flock.add_child(tip);tips.append(tip)
	refresh()

func _process(delta:float)->void:
	hand_input(delta)
	if playing:flock._process(delta)
	refresh()

func hand_input(delta:float)->void:
	var held:bool=point.held()
	if held:
		if not was_held:anchor_x=point.position.x;anchor_radius=flock.perception_radius
		var next_radius:=clampf(anchor_radius+point.position.x-anchor_x,.05,.5)
		if not is_equal_approx(next_radius,flock.perception_radius):flock.perception_radius=next_radius
		dropped_time=0
	else:
		dropped_time+=delta
		if dropped_time>1.5 and point.position.distance_to(HOME)>.001:point.position=HOME
	was_held=held

func toggle_play()->void:
	playing=not playing;pause_button.set_selected(not playing)

func sample()->Dictionary:
	# Read-only preview of the original body-zero calculation. It is first in
	# the original sequential loop, so no earlier body has advanced in this read.
	var b=flock._boids[0];var neighbours:Array[int]=[]
	var sep:=Vector3.ZERO;var ali:=Vector3.ZERO;var coh:=Vector3.ZERO
	for i in range(1,flock._boids.size()):
		var other=flock._boids[i];var dist:float=b.position.distance_to(other.position)
		if dist<flock.perception_radius and dist>.001:
			neighbours.append(i);sep+=(b.position-other.position)/(dist*dist)
			ali+=other.velocity;coh+=other.position
	if not neighbours.is_empty():
		sep*=flock.separation_weight
		ali=(ali/neighbours.size()-b.velocity)*flock.alignment_weight
		coh=(coh/neighbours.size()-b.position)*flock.cohesion_weight
	return {"neighbours":neighbours,"parts":[sep,ali,coh],"sum":sep+ali+coh}

func refresh()->void:
	reading=sample();var origin:Vector3=flock._boids[0].position
	for ring in rings:ring.position=origin;ring.scale=Vector3.ONE*flock.perception_radius
	links.multimesh.visible_instance_count=reading.neighbours.size()
	for j in reading.neighbours.size():links.multimesh.set_instance_transform(j,rod(origin,flock._boids[reading.neighbours[j]].position))
	var vectors:Array=reading.parts.duplicate();vectors.append(reading.sum)
	for i in range(4):
		var v:Vector3=vectors[i];var length:=.32*v.length()/(1.0+v.length())
		shafts[i].visible=length>.0001;tips[i].visible=length>.0001
		if length>.0001:
			var end:=origin+v.normalized()*length
			shafts[i].transform=rod(origin,end)
			tips[i].transform=Transform3D(Basis(Quaternion(Vector3.UP,v.normalized())),end)
	info.text="%s   RADIUS %.2f m   NEIGHBOURS %d / 29" % ["RUNNING" if playing else "PAUSED",flock.perception_radius,reading.neighbours.size()]
	values.text="SEP %.2f   ALIGN %.2f   COH %.2f   SUM %.2f" % [vectors[0].length(),vectors[1].length(),vectors[2].length(),vectors[3].length()]

func rod(a:Vector3,b:Vector3)->Transform3D:
	var d:=b-a
	return Transform3D(Basis(Quaternion(Vector3.UP,d.normalized())).scaled_local(Vector3(1,d.length(),1)),(a+b)*.5)
func cylinder(radius:float)->CylinderMesh:
	var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=1;mesh.radial_segments=8;return mesh
func material(colour:Color)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=colour;m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;return m
func box(size:Vector3,at:Vector3,colour:Color)->void:
	var body:=StaticBody3D.new();body.position=at;add_child(body)
	var surface:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;surface.mesh=mesh
	var m:=StandardMaterial3D.new();m.albedo_color=colour;surface.material_override=m;body.add_child(surface)
	var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)
func words(text:String,at:Vector3,size:int)->Label3D:
	var label:=Label3D.new();label.text=text;label.position=at;label.font_size=size;label.pixel_size=.002;label.outline_size=4
	add_child(label);return label
func get_museum_occupied_cells()->Array[Vector2i]:
	var cells:Array[Vector2i]=[]
	for rect in [Rect2(-.56,-.5,1.12,1.32),Rect2(-.85,.51,.26,.28),Rect2(.59,.51,.26,.28)]:
		for x in range(ceili(rect.size.x*4)+1):
			for z in range(ceili(rect.size.y*4)+1):
				var p:=to_global(Vector3(rect.position.x+x*.25,0,rect.position.y+z*.25));var c:=Vector2i(floori(p.x),floori(p.z))
				if not cells.has(c):cells.append(c)
	return cells
