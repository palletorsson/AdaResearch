extends Node3D
## Four operations on the actual bay parts from architecture_spine.
## Visual geometry only; the courtyard supplies the walking/collision plane.
const Source = preload("res://commons/artifacts/architecture_spine/architecture_spine.gd")
const Console = preload("res://commons/artifacts/architecture_variations/variation_console.gd")
const Handle = preload("res://algorithms/randomness/proceduralrandomness/geometrybased/omoss/pivot_handle.gd")
const L := 1.2
const H := 2.6
const HOME := Vector3(1.3,1.15,8.5)
const PINK := Color("dd6f9e")
const TITLES := ["THE SOURCE", "A CURVED COURT", "THE MOVING CENTRE", "THE REPEATED FIELD", "THE STRETCHED ROOF"]
var mode := 0
var amount := .75
var count := 12
var anchor := Vector3.ZERO
var panel: Node3D
var handle: RigidBody3D
var body: Node3D
var reference: Node3D
var readout: Label3D
var marker: MeshInstance3D
var original: Array = []
var materials: Array[Material] = []
var rendered: Array[MeshInstance3D] = []
var joint_poses: Array[Transform3D] = []
var dirty := false
var syncing := false
var elapsed := 0.0
var version := 0

func _ready() -> void:
	panel=Console.new();panel.position=Vector3(0,0,8.8);add_child(panel)
	for i in 5:panel.buttons[["SOURCE","CURVE","HINGE","FIELD","STRETCH"][i]].pressed.connect(set_preset.bind(i))
	panel.change_dial.hinge_moved.connect(read_controls)
	panel.count_dial.hinge_moved.connect(read_controls)
	build_source()
	body=Node3D.new();body.name="ChangedArcade";body.position=Vector3(0,.04,-3);add_child(body)
	reference=Node3D.new();reference.name="UnchangedArcade";reference.position=Vector3(-7.5,.65,6.6);reference.scale=Vector3.ONE*.26;add_child(reference)
	for i in 8:
		var copy:=MeshInstance3D.new();copy.mesh=source_mesh();copy.position.x=(i-4)*L;reference.add_child(copy)
	panel.box(self,Vector3(-7.5,.31,6.6),Vector3(3.5,.62,1.5),Color("25313a"),true)
	panel.text(self,"UNCHANGED / EIGHT BAYS",Vector3(-7.5,.39,7.365),.0010,Color("f2eee4"))
	readout=panel.text(self,"",Vector3(0,.56,8.85),.00095,Color("ddd8cb"))
	handle=Handle.new();handle.name="MoveCentre";handle.freeze=true;handle.gravity_scale=0
	handle.release_mode=XRToolsPickable.ReleaseMode.FROZEN;handle.collision_layer=(1<<2)|(1<<18);handle.collision_mask=0
	var col:=CollisionShape3D.new();var sphere:=SphereShape3D.new();sphere.radius=.1;col.shape=sphere;handle.add_child(col)
	var ball:=MeshInstance3D.new();var sm:=SphereMesh.new();sm.radius=.09;sm.height=.18;ball.mesh=sm;ball.material_override=panel.material(PINK);handle.add_child(ball)
	add_child(handle);handle.position=HOME
	panel.box(self,HOME+Vector3(0,-.20,0),Vector3(.3,.035,.3),Color("25313a"))
	panel.text(self,"MOVE THE PINK POINT",HOME+Vector3(0,-.35,.15),.00062,Color("25313a"))
	marker=MeshInstance3D.new();var ms:=SphereMesh.new();ms.radius=.13;ms.height=.26;marker.mesh=ms;marker.material_override=panel.material(PINK);body.add_child(marker)
	set_preset(1)

func build_source() -> void:
	# Call the earlier artifact's bay constructor. No duplicate architectural recipe.
	var donor=Source.new();donor.panel=Console.new()
	var bay:=Node3D.new();donor.build_bay(bay,0)
	var groups:Dictionary={}
	for part in donor.original_meshes:
		var colour:Color=part.material_override.albedo_color
		var key:=colour.to_html()
		if not groups.has(key):groups[key]=[];materials.append(part.material_override)
		var shape:BoxMesh=part.mesh.duplicate()
		# More roof samples make the pulled surface a deformation, not a single spike.
		if shape.size.x>.5:shape.subdivide_width=7
		if shape.size.z>1:shape.subdivide_depth=11
		if shape.size.y>1:shape.subdivide_height=5
		var data:Array=shape.get_mesh_arrays()
		var verts:PackedVector3Array=data[Mesh.ARRAY_VERTEX]
		var ids:PackedInt32Array=data[Mesh.ARRAY_INDEX]
		for i in ids:groups[key].append(part.transform*verts[i])
	for key in groups:original.append(PackedVector3Array(groups[key]))
	bay.free();donor.panel.free();donor.free()

func source_mesh() -> ArrayMesh:
	var mesh:=ArrayMesh.new()
	for i in original.size():append_surface(mesh,original[i],materials[i])
	return mesh

func append_surface(mesh:ArrayMesh,vertices:PackedVector3Array,mat:Material) -> void:
	var normals:=PackedVector3Array();normals.resize(vertices.size())
	for i in range(0,vertices.size(),3):
		# Godot's front faces are clockwise.
		var n:Vector3=(vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i]).normalized()
		for j in 3:normals[i+j]=n
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(mesh.get_surface_count()-1,mat)

func warp(p:Vector3) -> Vector3:
	if mode==1:
		var angle:=amount*TAU*.87
		if angle<.0001:return p
		var radius:=float(count)*L/angle
		var theta:=p.x/radius
		return Vector3((radius-p.z)*sin(theta),p.y,radius-(radius-p.z)*cos(theta))
	if mode==4:
		# Continuous compact roof influence. Ground points retain their position.
		var centre:=Vector3(.8+anchor.x*2.0,H,anchor.z)
		var d:=Vector2(p.x-centre.x,p.z-centre.z).length()
		var weight:=pow(maxf(0,1.0-d/7.5),2)*pow(clampf(p.y/H,0,1),2)
		return p+Vector3(9+anchor.x*5,7+anchor.y*7,-5+anchor.z*4)*amount*weight
	return p

func rebuild() -> void:
	for mesh in rendered:mesh.free()
	rendered.clear();joint_poses.clear()
	var total:=float(count)*L
	var shared: ArrayMesh=source_mesh() if mode==0 or mode==2 or mode==3 else null
	var pose:=Transform3D(Basis.IDENTITY,Vector3(-total*.5,0,0))
	var pivot:=Vector3(anchor.x,clampf((anchor.y+.4)*H/.9,0,H),anchor.z)
	for i in count:
		if i>0 and mode==2:
			var b:=Basis(Vector3.BACK,deg_to_rad(amount*29))
			pose=pose*Transform3D(b,Vector3(L,0,0)+pivot-b*pivot)
		elif mode!=2:pose=Transform3D(Basis.IDENTITY,Vector3(-total*.5+i*L,0,0))
		joint_poses.append(pose)
		var mesh:=shared
		if mode==1 or mode==4:
			mesh=ArrayMesh.new()
			for s in original.size():
				var vertices:PackedVector3Array=original[s].duplicate()
				for v in vertices.size():vertices[v]=warp(pose*vertices[v])
				append_surface(mesh,vertices,materials[s])
		var rows:=1+roundi(amount*3) if mode==3 else 1
		var tiers:=1+roundi(amount*2) if mode==3 else 1
		for row in rows:
			for tier in tiers:
				var item:=MeshInstance3D.new();item.mesh=mesh;body.add_child(item);rendered.append(item)
				if mode==0 or mode==2 or mode==3:item.transform=pose
				if mode==3:item.position+=Vector3(0,tier*(H+.22),-row*3.2)
	marker.visible=mode==2 or mode==4
	marker.position=joint_poses[mini(2,count-1)]*pivot if mode==2 else warp(Vector3(.8+anchor.x*2,H,anchor.z))
	panel.screen_title.text=TITLES[mode]
	panel.screen_state.text="%d BAYS / %.0f%%\n%s"%[count,amount*100,"PINK POINT: HINGE HEIGHT" if mode==2 else ("PINK POINT: PULL THE ROOF" if mode==4 else "TURN CHANGE / BAYS")]
	readout.text="%s\n%d modules / same source parts"%[TITLES[mode],rendered.size()]
	version+=1;dirty=false

func set_preset(value:int) -> void:
	mode=clampi(value,0,4);count=12;amount=.75;anchor=Vector3.ZERO
	if mode==0:amount=0
	if mode==1:count=18;amount=.88
	if mode==2:count=12;amount=.72;anchor.y=.3
	if mode==3:count=18;amount=.7
	if mode==4:count=16;amount=.95
	handle.position=HOME+anchor
	sync_controls();rebuild()

func sync_controls() -> void:
	syncing=true
	panel.change_dial.set_normalized_value(amount)
	panel.count_dial.set_normalized_value((count-4)/20.0)
	for i in 5:panel.buttons[["SOURCE","CURVE","HINGE","FIELD","STRETCH"][i]].set_selected(i==mode)
	syncing=false

func read_controls(_value:float) -> void:
	if syncing:return
	amount=panel.change_dial.get_normalized_value()
	count=clampi(4+roundi(panel.count_dial.get_normalized_value()*20),4,24)
	dirty=true

func _process(delta:float) -> void:
	elapsed+=delta
	var value:Vector3=(handle.position-HOME).clamp(Vector3(-.4,-.4,-.4),Vector3(.4,.5,.4))
	if not value.is_equal_approx(anchor):anchor=value;dirty=mode==2 or mode==4 or dirty
	if not handle.is_picked_up() and handle.pointer_owner==null:handle.position=HOME+anchor
	# Mesh generation is on change only, bounded to 12 Hz while dragging.
	if dirty and elapsed>.083:rebuild();elapsed=0

func _unhandled_key_input(event:InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var key:int=event.physical_keycode
	if key>=KEY_1 and key<=KEY_5:set_preset(key-KEY_1)
	elif key==KEY_R:set_preset(0)
	elif key==KEY_LEFT or key==KEY_RIGHT:
		amount=clampf(amount+(.05 if key==KEY_RIGHT else -.05),0,1);sync_controls();dirty=true
	elif key==KEY_UP or key==KEY_DOWN:
		count=clampi(count+(1 if key==KEY_UP else -1),4,24);sync_controls();dirty=true

func apply_grid_config(_config:Dictionary) -> void:
	pass
