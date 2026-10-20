extends Node3D
const Builder = preload("res://commons/primitives/animatedcubebuilder/animatedcubebuilder.gd")
const G = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
var cubes: Array[Node3D] = []
var diagonals: Array[MeshInstance3D] = []
var initial: Array = []
var free_edit := false
var desktop_held := false
var replaying := false
var replay_time := 0.0
var status: Label3D
var _last: Array = []
func _ready() -> void:
	G.box(self,"Worktop",Vector3(0,.53,0),Vector3(3.45,.06,1.32),Color("bcb9b3"))
	for x in [-1.45,1.45]:G.box(self,"Leg",Vector3(x,.25,0),Vector3(.07,.50,1.0),Color("75797b"))
	for side in 2:
		var cube:=Builder.new();cube.name="CubeA" if side==0 else "CubeB"
		cube.vertices=cube.vertices.duplicate();cube.triangles=cube.triangles.duplicate(true)
		if side==1:cube.triangles[4]=[4,5,6];cube.triangles[5]=[4,6,7]
		cube.position=Vector3(-.95 if side==0 else .95,1.06,0)
		add_child(cube);cube.set_process(false);cube.current_state=cube.BuildState.COMPLETE
		for i in 8:
			var h:Node3D=cube.handle_nodes[i];h.visible=true
			h.set_meta("desktop_hook_target",self)
			h.get_node("MeshInstance3D/Sphere").set_radius(.042 if i==6 else .018)
			var m:=G.material(Color("e96da5") if i==6 else Color("555563"))
			h.get_node("MeshInstance3D").material_override=m
		for line in cube.edge_lines:line.visible=true
		for i in cube.triangle_meshes.size():
			var face:MeshInstance3D=cube.triangle_meshes[i];face.visible=true
			face.material_override=G.material(Color("dcc1c9") if i==4 else (Color("c9bfd7") if i==5 else Color("b8bdc1")))
		var pair:Vector2i=Vector2i(5,7) if side==0 else Vector2i(4,6)
		var line:MeshInstance3D=cube.create_line_mesh(cube.vertices[pair.x],cube.vertices[pair.y])
		line.name="FrontDiagonal";line.material_override=G.material(Color("b77827"));cube.add_child(line)
		diagonals.append(line);cubes.append(cube)
		G.label(self,"A · diagonal 5–7" if side==0 else "B · diagonal 4–6",Vector3(cube.position.x,.36,.69),27)
	initial=cubes[0].vertices.duplicate();_permissions();_sync()
	status=G.label(self,"Same corners. Why a different fold?\nHold the pink corner. Its partner follows.",Vector3(0,.91,1.12),25)
	G.box(self,"ControlRail",Vector3(0,.71,1.08),Vector3(1.55,.05,.38),Color("3d434b"))
	for i in 3:
		var b=load("res://commons/interactables/push_button.tscn").instantiate()
		b.name=["Restore","Replay","FreeEdit"][i];b.position=Vector3((i-1)*.49,.75,1.08);b.rotation.x=-PI/2
		add_child(b);b.pressed.connect([restore,replay,toggle_free][i])
		var label:=G.label(self,["RESTORE","REPLAY","FREE / ONE"][i],Vector3((i-1)*.49,.745,1.26),23);label.rotation.x=-PI/2
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-35,0);light.light_energy=.45;add_child(light)
func on_desktop_grab(_pointer:Node) -> void:desktop_held=true
func on_desktop_drop(_pointer:Node) -> void:desktop_held=false
func held() -> bool:
	if desktop_held:return true
	for h in cubes[0].handle_nodes:
		if h.is_picked_up():return true
	return false
func _permissions() -> void:
	for side in 2:
		for i in 8:
			var h:CollisionObject3D=cubes[side].handle_nodes[i]
			h.collision_layer=4 if side==0 and not replaying and (i==6 or free_edit) else 0
			h.collision_mask=0
func _sync() -> void:
	for side in 2:
		var cube:Node3D=cubes[side]
		for i in 8:
			if side==1:cube.handle_nodes[i].position=cubes[0].handle_nodes[i].position
		cube._update_geometry_from_handles()
		# Clockwise visible triangles with outward normals. No reverse duplicates.
		for i in cube.triangles.size():
			var t:Array=cube.triangles[i]
			var vertices:=PackedVector3Array([cube.vertices[t[0]],cube.vertices[t[1]],cube.vertices[t[2]]])
			cube.triangle_meshes[i].mesh=G.mesh(vertices,[[0,1,2]])
		var pair:Vector2i=Vector2i(5,7) if side==0 else Vector2i(4,6)
		var a:Vector3=cube.vertices[pair.x];var b:Vector3=cube.vertices[pair.y]
		var d:MeshInstance3D=diagonals[side];d.position=(a+b)/2;d.mesh.height=maxf(.001,a.distance_to(b))
		if a.distance_to(b)>.001:d.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	_last=cubes[0].vertices.duplicate()
func _process(delta:float) -> void:
	if cubes.is_empty():return
	if replaying:
		replay_time+=delta
		var count:=int(replay_time/.13)
		for cube in cubes:
			var items:Array=cube.vertex_spheres+cube.edge_lines+cube.triangle_meshes
			for i in items.size():items[i].visible=i<count
		if count>=32:replaying=false;_permissions()
		for d in diagonals:d.visible=not replaying
		return
	var changed:=false
	for i in 8:
		var h:Node3D=cubes[0].handle_nodes[i]
		if not free_edit and i!=6:h.position=initial[i]
		if not h.position.is_equal_approx(_last[i]):changed=true
	if changed:_sync()
func restore() -> void:
	if held():return
	replaying=false
	for cube in cubes:
		for i in 8:cube.handle_nodes[i].position=initial[i]
		for n in cube.vertex_spheres+cube.edge_lines+cube.triangle_meshes:n.visible=true
	for d in diagonals:d.visible=true
	_sync();_permissions()
func replay() -> void:
	if held():return
	replay_time=0;replaying=true;_permissions()
func toggle_free() -> void:
	if held() or replaying:return
	free_edit=not free_edit;_permissions()
	status.text="All A corners move; B follows.\nSame positions, different front diagonal." if free_edit else "Same corners. Why a different fold?\nHold the pink corner. Its partner follows."
func centre_depth(side:int) -> float:
	var v:Array=cubes[side].vertices
	return (v[4].z+v[6].z)/2 if side==1 else (v[5].z+v[7].z)/2
