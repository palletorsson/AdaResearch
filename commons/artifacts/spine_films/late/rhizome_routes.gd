extends "res://commons/artifacts/spine_films/late/late_stage.gd"
const SOURCE := "res://commons/artifacts/rhizome_grower/rhizome_grower.gd"
var _points := PackedVector3Array()
var _one_edges: Array = []
var _three_edges: Array = []
var _bodies: Array[MeshInstance3D] = []
var _one_rods: Array[MeshInstance3D] = []
var _three_rods: Array[MeshInstance3D] = []
var _removed := 0
var _readout: Label3D

func _build() -> void:
	title_text = "NO NAMED ROOT, UNEQUAL CONNECTIONS"
	phases.assign(["THE SAME POSITIONS","ONE EARLIER NEIGHBOUR","THREE EARLIER NEIGHBOURS","REMOVE ONE BODY"])
	notes.assign(["The source keeps a seeded sequence of positions. The first two are near the centre.","Each later node chooses its nearest earlier neighbour. Birth order matters.","The same positions now allow three earlier neighbours. Routes multiply.","One node and its incident edges disappear. A network diagram is not a social proof."])
	source_paths.assign([SOURCE])
	frame_scene(Vector3(0,1.25,0),11.2,.30,.75)
	film_deck()
	var source = load(SOURCE).new()
	source.interactive = true
	source.max_nodes = 18
	source.spread = .50
	source.links_per_node = 1
	source._build()
	while source._node_total<source.max_nodes: source._grow_shoot()
	for point in source._positions: _points.append(point)
	_one_edges = source._edges.duplicate(true)
	var one_components: int = source._components
	source.links_per_node = 3
	source._rewire()
	source._refresh_graph()
	_three_edges = source._edges.duplicate(true)
	var degrees: Array = source._degrees.duplicate()
	_removed = degrees.find(degrees.max())
	var before_components: int = source._components
	source._active[_removed] = false
	source._refresh_graph()
	for i in _points.size(): _bodies.append(add_ball(_place(_points[i]),.10 if i==_removed else .072,CHALK.lerp(TEAL,float(i)/_points.size())))
	for edge in _one_edges: _one_rods.append(add_rod(_place(_points[edge.a]),_place(_points[edge.b]),.020,TEAL))
	for edge in _three_edges: _three_rods.append(add_rod(_place(_points[edge.a]),_place(_points[edge.b]),.020,GOLD if edge.a==_removed or edge.b==_removed else TEAL))
	_readout = add_label("",Vector3(0,2.6,0),CHALK)
	evidence = {"nodes":_points.size(),"one_link_edges":_one_edges.size(),"three_link_edges":_three_edges.size(),"one_link_components":one_components,"three_link_components":before_components,"removed_node":_removed,"removed_degree":degrees[_removed],"after_removal_components":source._components,"positions_hash":hash(_points),"sample_seed":47,"actual_functions":["_build","_grow_shoot","_rewire","_refresh_graph"],"limitation":"The source's shallow annular geometry is preserved; connectivity does not establish social equality"}
	source.free()

func _place(p: Vector3) -> Vector3:
	return p*6+Vector3(0,1.15,0)

func _draw(time: float) -> void:
	var phase := phase_index(time)
	var u := phase_progress(time)
	var born := clampi(2+int(u*(_points.size()-1)),2,_points.size())
	for i in _bodies.size():
		_bodies[i].visible = i<born if phase<=1 else not(phase==3 and i==_removed)
	for i in _one_rods.size(): _one_rods[i].visible = phase==1 and _one_edges[i].a<born
	for i in _three_rods.size():
		var edge: Dictionary = _three_edges[i]
		_three_rods[i].visible = (phase==2 and i<int(u*(_three_edges.size()+1))) or (phase==3 and edge.a!=_removed and edge.b!=_removed)
	_readout.text = ["18 stored positions / seed 47","%d edges / %d components" % [_one_edges.size(),evidence.one_link_components],"%d edges / %d components" % [_three_edges.size(),evidence.three_link_components],"node %d removed / %d components remain" % [_removed+1,evidence.after_removal_components]][phase]
