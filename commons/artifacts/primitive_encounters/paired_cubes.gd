extends Node3D
## One deformable cube using the original grid builder's eight handles and face
## recipes. Pink, red and black remain translucent. Every corner is editable.
## The legacy scene/part key stays PairedCubeDiagonals so saved layouts survive.
const Builder = preload("res://commons/primitives/animatedcubebuilder/animatedcubebuilder.gd")
const G = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
var cubes: Array[Node3D] = []
var diagonals: Array[MeshInstance3D] = []
var initial: Array = []
var free_edit := true
var desktop_held := false
var replaying := false
var replay_time := 0.0
var alternate_diagonal := false
var status: Label3D
var _last: Array = []

func _ready() -> void:
	G.box(self,"Worktop",Vector3(0,.53,0),Vector3(1.55,.06,1.32),Color("bcb9b3"))
	for x in [-.6,.6]:G.box(self,"Leg",Vector3(x,.25,0),Vector3(.07,.50,1.0),Color("75797b"))
	var cube:Node3D=Builder.new();cube.name="Cube"
	cube.vertices=cube.vertices.duplicate();cube.triangles=cube.triangles.duplicate(true)
	cube.position=Vector3(0,1.06,0);add_child(cube)
	cube.set_process(false);cube.current_state=cube.BuildState.COMPLETE
	for i in 8:
		var handle:Node3D=cube.handle_nodes[i];handle.visible=true
		handle.set_meta("desktop_hook_target",self)
		handle.get_node("MeshInstance3D/Sphere").set_radius(.035)
		var ink:StandardMaterial3D=G.material(Color("25232b"))
		var mesh:MeshInstance3D=handle.get_node("MeshInstance3D")
		mesh.material_override=null;mesh.set_surface_override_material(0,ink)
		handle._original_material=ink;handle.alternate_material=null
		# Keep the original grab sphere collider and actual XRTools grip path.
		handle.collision_layer=4;handle.collision_mask=0
	for line in cube.edge_lines:line.visible=true
	# Keep the source builder's pink/red/black translucent materials, rather
	# than the opaque comparison skins previously applied by this wrapper.
	for face in cube.triangle_meshes:face.visible=true
	var line:MeshInstance3D=cube.create_line_mesh(cube.vertices[5],cube.vertices[7])
	line.name="FrontDiagonal";line.material_override=G.material(Color("b77827"));cube.add_child(line)
	diagonals.append(line);cubes.append(cube)
	initial=cube.vertices.duplicate();_sync()
	status=G.label(self,"ONE CUBE / EIGHT MOVABLE CORNERS\nPick up any corner. The connected faces follow.",Vector3(0,.93,1.12),21)
	G.box(self,"ControlRail",Vector3(0,.71,1.08),Vector3(1.55,.05,.38),Color("3d434b"))
	for i in 3:
		var button:Node3D=load("res://commons/interactables/push_button.tscn").instantiate()
		button.name=["Restore","Replay","Diagonal"][i];button.position=Vector3((i-1)*.49,.75,1.08);button.rotation.x=-PI/2
		add_child(button);button.pressed.connect([restore,replay,toggle_diagonal][i])
		var caption:=G.label(self,["RESTORE","REPLAY","DIAGONAL"][i],Vector3((i-1)*.49,.745,1.26),21);caption.rotation.x=-PI/2

func on_desktop_grab(_pointer:Node) -> void:desktop_held=true
func on_desktop_drop(_pointer:Node) -> void:desktop_held=false
func held() -> bool:
	if desktop_held:return true
	for handle in cubes[0].handle_nodes:
		if handle.is_picked_up():return true
	return false

func _permissions() -> void:
	for handle in cubes[0].handle_nodes:
		handle.collision_layer=0 if replaying else 4
		handle.collision_mask=0

func _sync() -> void:
	var cube:Node3D=cubes[0]
	cube._update_geometry_from_handles()
	# One double-sided triangle per face fragment. Reverse coincident geometry
	# would blend the transparent material twice and make the skin too opaque.
	for i in cube.triangles.size():
		var t:Array=cube.triangles[i]
		var points:=PackedVector3Array([cube.vertices[t[0]],cube.vertices[t[1]],cube.vertices[t[2]]])
		cube.triangle_meshes[i].mesh=G.mesh(points,[[0,1,2]])
	var indices:=Vector2i(4,6) if alternate_diagonal else Vector2i(5,7)
	var a:Vector3=cube.vertices[indices.x];var b:Vector3=cube.vertices[indices.y]
	var diagonal:MeshInstance3D=diagonals[0];diagonal.position=(a+b)/2;diagonal.mesh.height=maxf(.001,a.distance_to(b))
	if a.distance_to(b)>.001:diagonal.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	_last=cube.vertices.duplicate()

func _process(delta:float) -> void:
	if cubes.is_empty():return
	var cube:Node3D=cubes[0]
	if replaying:
		replay_time+=delta
		var count:=int(replay_time/.13)
		var items:Array=cube.vertex_spheres+cube.edge_lines+cube.triangle_meshes
		for i in items.size():items[i].visible=i<count
		if count>=32:replaying=false;_permissions()
		diagonals[0].visible=not replaying
		return
	for i in 8:
		if not cube.handle_nodes[i].position.is_equal_approx(_last[i]):_sync();break

func restore() -> void:
	if held():return
	replaying=false
	var cube:Node3D=cubes[0]
	for i in 8:
		var handle:Node3D=cube.handle_nodes[i];handle.position=initial[i]
		PhysicsServer3D.body_set_state(handle.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,handle.global_transform)
	for node in cube.vertex_spheres+cube.edge_lines+cube.triangle_meshes:node.visible=true
	diagonals[0].visible=true;_sync();_permissions()

func replay() -> void:
	if held():return
	replay_time=0;replaying=true;_permissions()

func toggle_diagonal() -> void:
	if held() or replaying:return
	alternate_diagonal=not alternate_diagonal
	cubes[0].triangles[4]=[4,5,6] if alternate_diagonal else [4,5,7]
	cubes[0].triangles[5]=[4,6,7] if alternate_diagonal else [5,6,7]
	_sync()
	status.text="ONE CUBE / EIGHT MOVABLE CORNERS\nFront diagonal: %s. Corner positions stay the same."%("4-6" if alternate_diagonal else "5-7")
