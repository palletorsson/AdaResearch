extends "res://commons/artifacts/spine_films/late/late_stage.gd"
const SOURCE := "res://commons/artifacts/boolean_burrow/boolean_burrow.gd"
## Captured by the probe from _plan_walk(), seed 20260907, defaults. Keeping
## this record prevents the observer calling seed() on the museum's global RNG.
const CENTRES: Array[Vector3] = [Vector3(-4.5225,1.13,3.314583),Vector3(-3.233004,1.13,2.367376),Vector3(-1.890622,1.13,1.496738),Vector3(-.336376,1.13,1.116842),Vector3(1.206999,1.13,.694951),Vector3(2.776136,1.13,.382209),Vector3(4.360115,1.13,.608071),Vector3(2.764927,1.13,.732074),Vector3(2.338856,1.13,-.810153),Vector3(2.544359,1.13,-2.396901),Vector3(3.187513,1.13,-.931857)]
var _route: Array[MeshInstance3D] = []
var _cutters: Array[MeshInstance3D] = []
var _stock: Node3D
var _spoil: Node3D
var _ghost: MeshInstance3D
var _readout: Label3D

func _build() -> void:
	title_text = "A WALK TAKEN OUT OF A BLOCK"
	phases.assign(["THE PATH","ELEVEN CUTTERS","ONE UNION","THE ROOM AND THE REMOVED BODY"])
	notes.assign(["The source's seeded walk places eleven centres inside the block.","Each centre carries the same sphere. Neighbouring cutters overlap.","The source unions the cutters before subtracting that body from the block.","A section opens the view. Connected cutters do not guarantee body clearance."])
	source_paths.assign([SOURCE])
	frame_scene(Vector3(0,1,0),12,.48,.43)
	film_deck()
	var source = load(SOURCE).new()
	source.walkable = false
	source.stone_color = Color("cbc9bc")
	source.spoil_color = Color("deaa82")
	source._centres.assign(CENTRES)
	source._measure_connectivity()
	_stock = film_group()
	_stock.add_child(source._build_stock())
	_stock.scale = Vector3.ONE*.43
	_spoil = film_group()
	_spoil.add_child(source._build_spoil_body())
	_spoil.scale = Vector3.ONE*.43
	var points := PackedVector3Array()
	for centre in CENTRES:
		points.append(centre*.43)
		_cutters.append(add_ball(centre*.43,source.carver_radius*.43,Color(PINK,.20)))
	_route = film_path(points,GOLD,null,.035)
	_ghost = add_box(Vector3(0,2.5,0)*.43,source.block_size*.43,Color(SLATE,.15))
	_readout = add_label("",Vector3(0,3.0,0),CHALK)
	evidence = {"seed":source.generation_seed,"centres":CENTRES.size(),"components":source._components,"graph_cycles":source._cycles,"cutters_union":true,"subtraction_operations":2,"section_cut":true,"uses_shared_rng":false,"fixture_tolerance":.000002,"actual_functions":["_build_stock","_build_spoil_body","_measure_connectivity"],"limitation":"The orange body is the full cutter union; it is not clipped to the stock. No traversal claim."}
	source.free()

func _draw(time: float) -> void:
	var phase := phase_index(time)
	var u := phase_progress(time)
	film_reveal(_route,minf(1,u*1.3) if phase==0 else (1.0 if phase==1 else 0.0))
	for i in _cutters.size(): _cutters[i].visible = phase==1 and i<=int(u*_cutters.size())
	_stock.visible = phase==3
	_spoil.visible = phase>=2
	_ghost.visible = phase<2
	var separation := smoothstep(.05,.6,u) if phase==3 else 0.0
	_stock.position.x = -1.75*separation
	_stock.scale = Vector3.ONE*lerpf(.43,.27,separation)
	_spoil.position = Vector3(1.75*separation,.45*separation,0)
	_spoil.scale = Vector3.ONE*lerpf(.43,.27,separation)
	_readout.text = ["11 stored centres / seed 20260907","same radius / overlapping solids","S = union of the cutters","A − S     /     S, shown alongside"][phase]
