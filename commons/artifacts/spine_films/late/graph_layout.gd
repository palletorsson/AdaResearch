extends "res://commons/artifacts/spine_films/late/late_stage.gd"
const SOURCE := "res://algorithms/graphtheory/forcedirected3d/forcedirected3d.gd"
var _snapshots: Array[PackedVector3Array] = []
var _pairs: Array[Vector2i] = []
var _bodies: Array[MeshInstance3D] = []
var _edges: Array[MeshInstance3D] = []
var _repulsion: Node3D
var _spring: Node3D
var _readout: Label3D
var _center := Vector3.ZERO
var _display_scale := .25

func _build() -> void:
	title_text = "THE GRAPH KEEPS ITS CONNECTIONS"
	phases.assign(["ADJACENCY","REPULSION","SPRING TENSION","ANOTHER ARRANGEMENT"])
	notes.assign(["Nine source-generated nodes form a tree: eight recorded connections.","Repulsion separates nodes. It acts between pairs beyond the drawn edges.","As the layout spreads, the connected springs pull against their rest lengths.","The layout moves in three dimensions. Every original connection remains."])
	source_paths.assign([SOURCE])
	frame_scene(Vector3(0,1.3,0),12.0,.45,.26)
	film_deck()
	var source = load(SOURCE).new()
	source.node_count = 9
	source.mutuality = "none"
	source.layout_seed = 47
	source.initial_distribution = "sphere"
	source.layout_bounds = Vector3(15,15,15)
	source._open_rng()
	source.initialize_graph()
	for node in source.nodes: _center += node.position
	_center /= source.nodes.size()
	for edge in source.edges: _pairs.append(Vector2i(edge.from_id,edge.to_id))
	_snapshots.append(_snapshot(source))
	for node in source.nodes: node.force = Vector3.ZERO
	source.calculate_repulsion_forces()
	var repulsion_at: Vector3 = source.nodes[0].position
	var repulsion_vector: Vector3 = source.nodes[0].force
	var spring_at := Vector3.ZERO
	var spring_vector := Vector3.ZERO
	for i in 400:
		source.simulation_step(.04)
		_snapshots.append(_snapshot(source))
		if i==49:
			for node in source.nodes: node.force = Vector3.ZERO
			source.calculate_spring_forces()
			spring_at = source.nodes[0].position
			spring_vector = source.nodes[0].force
	var lower: Vector3 = _snapshots[0][0]
	var upper := lower
	for snapshot in _snapshots:
		for point in snapshot:
			lower = lower.min(point)
			upper = upper.max(point)
	_center = (lower+upper)*.5
	var span := upper-lower
	_display_scale = minf(6.0/span.x,minf(2.7/span.y,4.5/span.z))
	_repulsion = film_arrow(_place(repulsion_at),repulsion_vector*.06,PINK)
	_spring = film_arrow(_place(spring_at),spring_vector*2.0,TEAL)
	for i in source.nodes.size(): _bodies.append(add_ball(_place(_snapshots[0][i]),.12 if i==0 else .075,GOLD if i==0 else CHALK))
	for pair in _pairs: _edges.append(film_unit_rod(TEAL,null,.025))
	_readout = add_label("",Vector3(0,3.4,0),CHALK)
	evidence = {"nodes":source.nodes.size(),"edges":source.edges.size(),"adjacency_hash":hash(_pairs),"snapshot_count":_snapshots.size(),"source_delta":.04,"source_steps":400,"layout_seed":47,"mutuality":"none","actual_functions":["initialize_graph","calculate_repulsion_forces","calculate_spring_forces","simulation_step"],"display_scale":_display_scale,"source_separate_from_scene":true}
	source.free()

func _snapshot(source: Node3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	for node in source.nodes: points.append(node.position)
	return points

func _place(p: Vector3) -> Vector3:
	return (p-_center)*_display_scale+Vector3(0,1.5,0)

func _draw(time: float) -> void:
	var phase := phase_index(time)
	var u := phase_progress(time)
	var index := 0
	if phase==1: index = int(u*50)
	if phase==2: index = 50
	if phase==3: index = 50+mini(349,int(u*350))
	for i in _bodies.size(): _bodies[i].position = _place(_snapshots[index][i])
	for i in _pairs.size(): film_rod_pose(_edges[i],_bodies[_pairs[i].x].position,_bodies[_pairs[i].y].position)
	_repulsion.visible = phase==1 and u<.22
	_spring.visible = phase==2
	_readout.text = "9 nodes / 8 edges / %d solver steps" % index
