extends Node3D
## One drawing, two scales. Reads the creator's actual vertices and fan indices.
## No independent composition, collision surface, or alternative triangulation.
const ENLARGEMENT := 3.3
const CENTRE := Vector3(0,1.8,0)
var source: Node3D
var white: StandardMaterial3D
var black: StandardMaterial3D
var faces: MeshInstance3D
var large_edges: MultiMeshInstance3D
var small_edges: MultiMeshInstance3D
var corners: MultiMeshInstance3D
var large_points: PackedVector3Array = []
var edge_pairs: Array = []
var triangle_count := 0
var _last_signature := 0
var _elapsed := 0.0
var restore_button: Node3D
var _source_transform := Transform3D.IDENTITY

func _ready() -> void:
	white=StandardMaterial3D.new();white.albedo_color=Color(0.96,0.955,0.94);white.roughness=0.32
	white.cull_mode=BaseMaterial3D.CULL_DISABLED
	black=StandardMaterial3D.new();black.albedo_color=Color(0.008,0.009,0.012);black.roughness=0.3
	faces=MeshInstance3D.new();faces.name="SameFacesEnlarged";faces.material_override=white;add_child(faces)
	large_edges=edges("LargeBlackEdges",0.018)
	small_edges=edges("SmallBlackEdges",0.006)
	small_edges.top_level=true
	small_edges.global_transform=Transform3D.IDENTITY
	corners=MultiMeshInstance3D.new();corners.name="SameCornersEnlarged"
	corners.multimesh=MultiMesh.new();corners.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	var sphere := SphereMesh.new();sphere.radius=0.043;sphere.height=0.086;sphere.radial_segments=16;sphere.rings=8
	corners.multimesh.mesh=sphere;corners.material_override=black;add_child(corners)
	# A floor inscription locates the enlargement without adding a console.
	var caption := Label3D.new();caption.text="ONE DRAWING / TWO SCALES";caption.font_size=42
	caption.pixel_size=0.0025;caption.modulate=black.albedo_color;caption.outline_size=0
	caption.position=Vector3(0,0.016,1.35);caption.rotation=Vector3(-PI/2,0,0);add_child(caption)
	var timer := Timer.new();timer.wait_time=0.25;timer.autostart=true
	timer.timeout.connect(_find_source);add_child(timer)

func _find_source() -> void:
	if is_instance_valid(source):return
	var hall := get_parent()
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null:return
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/draw_triangle_faces.gd"):
			source=node;_connect_source();return

func _connect_source() -> void:
	_source_transform=source.global_transform
	source.line_color=black.albedo_color;source.active_line_color=black.albedo_color
	source.triangle_colors.assign([white.albedo_color])
	if source.active_line_instance!=null:
		source.active_line_instance.material_override=black
	for mesh in source.get_node("GrabPoint").find_children("*","MeshInstance3D",true,false):
		mesh.material_override=black
	var pen: MeshInstance3D=source.get_node_or_null("GrabPoint/DrawSphere")
	if pen!=null:pen.material_override=white
	# A first visitor receives a real editable triangle; a carried outline stays open.
	if source.placed_points.is_empty():
		for point in reference_points():source._create_new_point(point)
		source._handle_snap_to_point(0)
		source._rebuild_lines()
	refresh(true)
	# A reference can be recovered after a corner collapses the face. Use the
	# existing museum hand/ray button; never reset a held drawing automatically.
	restore_button=load("res://commons/interactables/push_button.tscn").instantiate()
	restore_button.name="RestoreTriangle"
	source.add_child(restore_button)
	restore_button.position=Vector3(0,-0.40,0.35)
	restore_button.pressed.connect(restore_reference)
	var caption := Label3D.new()
	caption.text="RESTORE TRIANGLE";caption.font_size=24;caption.pixel_size=0.0008
	caption.outline_size=0;caption.modulate=Color("25282d")
	caption.position=Vector3(0,-0.30,0.40)
	source.add_child(caption)

func restore_reference() -> bool:
	if not is_instance_valid(source) or source._is_grabbed or not source._editing_points.is_empty():return false
	source.clear_all()
	source.fills_visible=true
	for point in reference_points():source._create_new_point(point)
	source._handle_snap_to_point(0)
	source._rebuild_lines()
	refresh(true)
	return true

func reference_points() -> Array[Vector3]:
	# The supplied beginning must obey the same snap rule as a visitor's drop.
	# Otherwise a released corner cannot lie exactly on its off-grid base.
	var points: Array[Vector3]=[]
	for point in [Vector3(-0.58,-0.24,0),Vector3(0.58,-0.24,0),Vector3(-0.12,0.56,0)]:
		points.append(source.snap_position_to_grid(source.to_global(point)))
	return points

func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed<0.04 or not is_instance_valid(source):return
	_elapsed=0
	# The museum can seat the station after its world-space drawing is built.
	# Carry that drawing with its support instead of enlarging the old offset.
	if not source.global_transform.is_equal_approx(_source_transform):
		var relocation: Transform3D=source.global_transform*_source_transform.affine_inverse()
		_source_transform=source.global_transform
		for i in source.placed_points.size():
			var point: Vector3=source.snap_position_to_grid(relocation*source.placed_points[i])
			source.placed_points[i]=point
			if i<source.point_indicators.size() and is_instance_valid(source.point_indicators[i]):
				source.point_indicators[i].global_position=point
		source._rebuild_all_triangles();source._rebuild_lines()
	# The existing handles normally commit on drop. Here both scales follow the hand.
	var moving := false
	for index in source._editing_points:
		if index<source.point_indicators.size():
			var handle: Node3D=source.point_indicators[index]
			if is_instance_valid(handle):
				source.placed_points[index]=handle.global_position;moving=true
	if moving:source._rebuild_all_triangles();source._rebuild_lines()
	refresh()

func refresh(force: bool=false) -> void:
	if not is_instance_valid(source):return
	var loops: Array=[]
	for face in source.completed_triangles:loops.append(face.points)
	var signature := hash([source.placed_points,loops,source.current_path,source.fills_visible])
	if signature==_last_signature and not force:return
	_last_signature=signature
	large_points.clear()
	for point: Vector3 in source.placed_points:large_points.append(CENTRE+source.to_local(point)*ENLARGEMENT)
	var pairs := {}
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	triangle_count=0
	var visible_triangles := 0
	for face in source.completed_triangles:
		face.mesh.material_override=white
		var loop: Array=face.points
		for i in range(1,loop.size()-1):
			var indices := [loop[0],loop[i],loop[i+1]]
			var a: Vector3=large_points[indices[0]]
			var b: Vector3=large_points[indices[1]]
			var c: Vector3=large_points[indices[2]]
			var cross_product := (b-a).cross(c-a)
			# Collinear corners retain their edges, but supply no surface area.
			# Avoid submitting zero-area faces and a zero normal to the renderer.
			if cross_product.length_squared()>0.00000001:
				var normal := cross_product.normalized()
				for point in [a,b,c]:st.set_normal(normal);st.add_vertex(point)
				visible_triangles+=1
			triangle_count+=1
			for j in 3:add_edge(pairs,indices[j],indices[(j+1)%3])
	for i in range(source.current_path.size()-1):add_edge(pairs,source.current_path[i],source.current_path[i+1])
	faces.mesh=st.commit() if visible_triangles>0 else null
	faces.visible=source.fills_visible
	edge_pairs=pairs.values()
	large_edges.multimesh.instance_count=edge_pairs.size()
	small_edges.multimesh.instance_count=edge_pairs.size()
	for i in edge_pairs.size():
		var pair: Array=edge_pairs[i]
		large_edges.multimesh.set_instance_transform(i,segment(large_points[pair[0]],large_points[pair[1]]))
		small_edges.multimesh.set_instance_transform(i,segment(source.placed_points[pair[0]],source.placed_points[pair[1]]))
	source.line_instance.visible=false
	corners.multimesh.instance_count=large_points.size()
	for i in large_points.size():corners.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,large_points[i]))
	for handle in source.point_indicators:
		if not is_instance_valid(handle):continue
		for mesh in handle.find_children("*","MeshInstance3D",true,false):mesh.material_override=black

func add_edge(pairs: Dictionary, a: int, b: int) -> void:
	if a==b:return
	var lo := mini(a,b);var hi := maxi(a,b)
	pairs[str(lo)+":"+str(hi)]=[lo,hi]

func segment(a: Vector3, b: Vector3) -> Transform3D:
	var length := a.distance_to(b)
	if length<0.00001:return Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),a)
	return Transform3D(Basis(Quaternion(Vector3.UP,(b-a)/length))*Basis.from_scale(Vector3(1,length,1)),(a+b)*0.5)

func edges(title: String, radius: float) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new();node.name=title
	node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	var tube := CylinderMesh.new();tube.height=1;tube.top_radius=radius;tube.bottom_radius=radius;tube.radial_segments=8
	node.multimesh.mesh=tube;node.material_override=black;add_child(node)
	return node
