extends Node3D
## An exploded reading of one real neighbourhood. No second solver or state edits.
const ADDRESS := Vector3i(26, 22, 24)
const SPACING := 1.13
const Kit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
var work: Node3D
var study: Node3D
var cells: MultiMesh
var offsets: Array[Vector3i] = []
var states := PackedInt32Array()
var colours := PackedColorArray()
var caption: Label3D
var source_marker: MeshInstance3D
var active_neighbours := 0

func build(owner_study: Node3D) -> void:
	name = "NeighbourRoom"
	study = owner_study
	work = study.work
	position = Vector3(-3.85, 1.5, -1.8)
	cells = MultiMesh.new()
	cells.transform_format = MultiMesh.TRANSFORM_3D
	cells.use_colors = true
	cells.instance_count = 27
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * .52
	cells.mesh = cube
	var view := MultiMeshInstance3D.new()
	view.name = "TwentySevenAddresses"
	view.multimesh = cells
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	view.material_override = material
	add_child(view)
	var frames := ImmediateMesh.new()
	frames.surface_begin(Mesh.PRIMITIVE_LINES)
	for z in range(-1,2):
		for y in range(-1,2):
			for x in range(-1,2):
				var offset := Vector3i(x,y,z)
				offsets.append(offset)
				frames.surface_set_color(Color("ffd77d") if offset == Vector3i.ZERO else Color("9faea6"))
				wire_cube(frames,Vector3(offset)*SPACING,.65)
	frames.surface_end()
	var frame := MeshInstance3D.new()
	frame.name = "AddressesRemain"
	frame.mesh = frames
	frame.material_override = material
	add_child(frame)
	# The central address has a thicker golden outline, also after its cell empties.
	for axis in range(3):
		for a in [-1,1]:
			for b in [-1,1]:
				var size:=Vector3.ONE*.014;size[axis]=.68
				var p:=Vector3.ZERO;p[(axis+1)%3]=a*.34;p[(axis+2)%3]=b*.34
				add_child(Kit.box(p,size,Kit.emissive(Color("ffd77d"),.3)))
	caption=Label3D.new()
	caption.text="CELL (26, 22, 24) / ENLARGED NEIGHBOURHOOD"
	caption.font_size=32;caption.pixel_size=.0015
	caption.position=Vector3(0,1.72,-1.17);caption.rotation.y=PI
	caption.double_sided=false;caption.outline_size=3;add_child(caption)
	# A depth-tested outline locates this address in the original specimen.
	var marker_mesh:=ImmediateMesh.new();marker_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	marker_mesh.surface_set_color(Color("ffd77d"));wire_cube(marker_mesh,Vector3.ZERO,.148);marker_mesh.surface_end()
	source_marker=MeshInstance3D.new();source_marker.name="NeighbourAddress"
	source_marker.mesh=marker_mesh;source_marker.material_override=material
	work.mesh_instance.add_child(source_marker)
	source_marker.position=Vector3(ADDRESS)*work.cell_size
	refresh()

func wire_cube(mesh: ImmediateMesh, centre: Vector3, side: float) -> void:
	for axis in range(3):
		for a in [-1,1]:
			for b in [-1,1]:
				var p:=centre;p[axis]-=side*.5;p[(axis+1)%3]+=a*side*.5;p[(axis+2)%3]+=b*side*.5
				var q:=p;q[axis]+=side
				mesh.surface_add_vertex(p);mesh.surface_add_vertex(q)

func colour_for(state: int, address: Vector3i) -> Color:
	if work.use_gradient and work.gradient:
		return work.gradient.sample(float(address.y)/work.grid_size.y)
	if state > 1:
		return work.color_alive.lerp(work.color_dying,float(state-1)/float(work.rule_states-2))
	return work.color_alive

func refresh() -> void:
	states.clear();colours.clear();active_neighbours=0
	for i in range(offsets.size()):
		var p:Vector3i=ADDRESS+offsets[i]
		var index:int=p.x+p.y*work.stride_y+p.z*work.stride_z
		var state:int=work.current_state[index]
		states.append(state)
		if offsets[i]!=Vector3i.ZERO and state==1:active_neighbours+=1
		var colour:Color=colour_for(state,p);colours.append(colour)
		var basis:=Basis.IDENTITY if state>0 else Basis.IDENTITY.scaled(Vector3.ZERO)
		cells.set_instance_transform(i,Transform3D(basis,Vector3(offsets[i])*SPACING))
		cells.set_instance_color(i,colour)

func readback() -> Dictionary:
	return {"address":[ADDRESS.x,ADDRESS.y,ADDRESS.z],"generation":work.generation,
		"centre":states[13],"active_neighbours":active_neighbours,"states":Array(states),
		"state_colours":study.state_colours}

func _exit_tree() -> void:
	if is_instance_valid(source_marker):source_marker.queue_free()
