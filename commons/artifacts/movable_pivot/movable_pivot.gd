extends "res://commons/void/lines_area.gd"
## One hand-adjusted bearing changes the path of a real walkable timber deck.
## Mechanism stays coupled; the two landing islands and entry ramp are separate
## editable parts. Local coordinates work after moving/rotating the whole kit.
const Mechanism = preload("res://commons/artifacts/movable_pivot/mechanism.gd")
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Finish = preload("res://commons/artifacts/machine_finish.gd")
var mechanism: Node3D

func _ready() -> void:
	mechanism=Mechanism.new();mechanism.name="PivotWalkway";add_child(mechanism)
	for entry in [["EntryLanding",Vector3(-3.8,0,0)],["NearLanding",Vector3(3.8,0,-1.2)],["FarLanding",Vector3(3.8,0,1.2)]]:
		var part:=Node3D.new();part.name=entry[0];part.position=entry[1];add_child(part)
		Mechanism.box(part,"TimberTop",Vector3(1.6,.16,1.2),Vector3(0,.64,0),Timber.material(),true)
		Mechanism.box(part,"TemporaryBlock",Vector3(.9,.56,.9),Vector3(0,.28,0),Finish.ivory(),true)
	var ramp:=Node3D.new();ramp.name="EntryRamp";ramp.position=Vector3(-5.3,0,0);add_child(ramp)
	# A four-vertex incline plus matching convex collider, not decorative slope.
	# Crest overlaps the landing slightly above its top: a capsule can roll
	# over the join instead of catching the landing's exposed vertical face.
	var vertices:=PackedVector3Array([Vector3(-.8,0,-.6),Vector3(-.8,0,.6),Vector3(.8,0,-.6),Vector3(.8,0,.6),Vector3(.8,.84,-.6),Vector3(.8,.84,.6)])
	var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();shape.shape=ConvexPolygonShape3D.new();shape.shape.points=vertices;body.add_child(shape);ramp.add_child(body)
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[0,4,2],[0,1,5],[0,5,4],[1,3,5],[0,2,3],[0,3,1],[2,4,5],[2,5,3]]:
		for i in tri: st.set_uv(Vector2(vertices[i].x,vertices[i].z));st.add_vertex(vertices[i])
	st.generate_normals();var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=Timber.material();ramp.add_child(mesh)
	var caption:=words("MOVE THE PINK PIVOT / THEN TURN THE END GRIP",Vector3(0,.018,2.15),true,.0018);caption.name="Instruction"
	for child in get_children():
		if child is Node3D:
			var b:=_mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]}
	# Full moving envelope, including grips, at every allowed bearing position.
	part_defaults.PivotWalkway.bounds=[-3.25,0,-2.25,6.5,1.16,4.5]

func apply_grid_config(config: Dictionary) -> void:
	if is_instance_valid(mechanism):mechanism.configure(float(config.get("pivot_x",0)),float(config.get("angle_degrees",0)))
	super.apply_grid_config(config)

func prepare_editor_preview() -> void:
	if is_instance_valid(mechanism):mechanism.prepare_editor_preview()
