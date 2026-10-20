extends "res://commons/void/lines_area.gd"
## Placement adapters for the remaining Primitives halls. Existing scenes own
## their geometry and interaction. Every named direct child is an editor part.
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const Library = preload("res://commons/artifacts/ignorance_gallery/primitive_mesh_library.gd")
const Columns = preload("res://commons/artifacts/resolution_colonnade/resolution_colonnade_museum.gd")
const Profiles = preload("res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.gd")
const Court = preload("res://commons/artifacts/ignorance_gallery/geometry_courtyard.gd")
const ResolutionPoint = preload("res://commons/artifacts/ignorance_gallery/resolution_catalyst.gd")
const CubeEdgeStudy = preload("res://commons/void/cube_edge_study.gd")
const PlatonicStudy = preload("res://commons/void/platonic_study.gd")
const ColumnsStudy = preload("res://commons/void/columns_study.gd")
const ProfilesStudy = preload("res://commons/void/profiles_study.gd")
const Composition = preload("res://commons/void/melencolia_composition.gd")
@export_enum("cube", "primitives", "godot", "columns", "profiles", "portals", "melencolia") var hall := "cube"
const TITLES := {"cube":"CUBE / SAME CORNERS, DIFFERENT SURFACES", "primitives":"PRIMITIVES / A FORM HAS TO BE MADE", "godot":"GODOT / FORMS THE ENGINE GIVES US", "columns":"COLUMNS / ONE PROFILE, MANY BODIES", "profiles":"PROFILES / AN OUTLINE BECOMES A SPACE", "portals":"PORTALS / ANOTHER STEP TOWARDS A CIRCLE", "melencolia":"MELENCOLIA / WHAT WILL YOU MAKE WITH THESE?"}
var homes: Dictionary = {}

func apply_grid_config(config: Dictionary) -> void:
	# The authored long span replaces this hall's compact version only.
	if hall=="portals" and config.get("portal_span",false) and not config.has("only_parts"):
		var compact := get_node_or_null("RefinementPassage")
		if compact!=null: compact.free()
		part_defaults.erase("RefinementPassage")
	super.apply_grid_config(config)

func _ready() -> void:
	add_to_group("void_lines_area")
	match hall:
		"cube": _cube()
		"primitives": _primitives()
		"godot": _godot()
		"columns": _columns()
		"profiles": _profiles()
		"portals": _portals()
		"melencolia": _melencolia()
	# Read from the south aisle. These are movable, authored signs.
	words(TITLES[hall],Vector3(0,3.2,-7.4),false,.0018).modulate=Color("efe6e7")
	words("THE ENDLESS MUSEUM\nalways another room",Vector3(-17,3.25,-7.4),false,.0016).modulate=Color("efe6e7")
	for child in get_children():
		if child is Node3D:
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}
			if child.has_meta("editor_label"): part_defaults[str(child.name)]["label"]=child.get_meta("editor_label")
	_remember.call_deferred()

func specimen(path: String, title: String, at: Vector3, yaw := 0.0, config := {}) -> Node3D:
	var packed := load(path) as PackedScene
	assert(packed != null,"Missing original artifact: "+path)
	var node := packed.instantiate() as Node3D
	node.name=title;node.position=at;node.rotation_degrees.y=yaw
	node.set_meta("void_source",path)
	for key in config:
		node.set_meta("config_"+key,config[key])
		if key in node: node.set(key,config[key])
	add_child(node)
	if node.has_method("apply_grid_config") and not config.is_empty(): node.apply_grid_config(config)
	# The tower supplies the visitor and world illumination. Standalone cameras
	# and extra suns must not take over a streamed floor.
	for camera in node.find_children("*","Camera3D",true,false): camera.current=false
	for sun in node.find_children("*","DirectionalLight3D",true,false): sun.hide()
	return node

func bench(title: String, at: Vector3, width: float, depth: float, height := .78) -> Node3D:
	var group := Node3D.new();group.name=title;group.position=at;add_child(group)
	Kit.block(group,Vector3(width,.08,depth),Vector3(0,height-.04,0),Color("d7d0c2"))
	for x in [-width*.42,width*.42]:
		for z in [-depth*.38,depth*.38]: Kit.block(group,Vector3(.07,height-.08,.07),Vector3(x,(height-.08)*.5,z),Color("35343d"))
	return group

func _cube() -> void:
	var pair := specimen("res://commons/artifacts/primitive_encounters/paired_cube_diagonals.tscn","PairedCubeDiagonals",Vector3(-16,0,0))
	var study := CubeEdgeStudy.new()
	study.name = "EdgeStudy"
	pair.add_child(study)
	specimen("res://commons/artifacts/cube_diagonal_plate/cube_diagonal_plate.tscn","CubeConnections",Vector3(-16,.8,-4))
	bench("ConnectionTable",Vector3(-16,0,-4),2.2,1.4,.8)
	specimen("res://commons/infoboards_3d/visualizations/polyhedron_nets_cube.tscn","FoldingCubeNet",Vector3(0,1.15,-3.2),0,{"edge_length":.7,"fall_cycle":true,"loop_fold":true,"fold_duration":2.6,"think_hold":2.2,"max_dropped_cubes":12})
	bench("NetTable",Vector3(0,0,-3.2),3.8,3.4,.75)
	specimen("res://commons/artifacts/prefab_box_library/prefab_box_library.tscn","BoxLibrary",Vector3(16.5,0,-.6),90,{"worktable_x":0.0,"worktable_z":2.3,"column_pitch":1.2})
	words("ONE CORNER / TWO SURFACES\nMove it. Compare. Restore. Try again.",Vector3(-16,.025,2.8),true,.0014)
	words("A NET CLOSES. A BOX CAN BE CARRIED.",Vector3(0,.025,.2),true,.0014)

func _primitives() -> void:
	# Reuse the five source solids and the museum's pickable-mesh factory,
	# without importing the courtyard's room or columns into the tower.
	for i in Court.TYPES.size():
		var group := Node3D.new();group.name=String(Court.TYPES[i]).capitalize();group.position=Vector3(-4.4+i*2.2,0,-4.7);add_child(group)
		var source := load(Court.SOURCES[i]).instantiate() as Node3D
		group.add_child(source)
		var mesh: Mesh
		for visual in source.find_children("*","MeshInstance3D",true,false):
			if visual.mesh != null and not str(visual.name).begins_with("Highlight"): mesh=visual.mesh;break
		assert(mesh != null)
		Kit.pedestal(group,Vector3.ZERO,.88,1.12)
		var body := Kit.pickable_mesh(group,mesh,Vector3(0,.885,0),Kit.BLACK if i%2==0 else Kit.WHITE,.88)
		body.name="Solid";body.set_meta("solid_type",Court.TYPES[i]);body.set_meta("void_source",Court.SOURCES[i])
		var study := PlatonicStudy.new();study.name="Study";group.add_child(study)
		study.setup(body)
		source.free()
	specimen("res://commons/artifacts/ignorance_gallery/sphere_resolution_atlas.tscn","SphereResolutionAtlas",Vector3(-16,0,0),180)
	specimen("res://commons/artifacts/budget_of_smoothness/budget_of_smoothness.tscn","BudgetOfSmoothness",Vector3(0,0,2.3),0,{"discovery":true})
	var point := ResolutionPoint.new();point.name="PointBecomesCatalyst";point.position=Vector3(16,1.45,0);add_child(point)
	words("GRIP THE POINT / FEWER DIVISIONS\nTRIGGER / SEND ITS CURRENT FORM",Vector3(16,2.3,-1),false,.0013)
	words("FIVE REGULAR SOLIDS\nEqual faces. The same meeting at every vertex.",Vector3(0,.025,-2.9),true,.0011)
	# The original six sphere records stay independent of their furniture.
	# Equal supports and a clear central aisle make the overlay comparison fair.
	for row in 3:
		var z := 2.5-row*2.5
		for side in 2:
			var support := Node3D.new()
			support.name="ComparisonStand_%d_%s"%[row+1,"Edges" if side==0 else "Surface"]
			support.position=Vector3(-1.6 if side==0 else 1.6,0,z)
			add_child(support)
			Kit.pedestal(support,Vector3.ZERO,.85,1.12)
			var counts: String=["16 AROUND / 16 RINGS","7 AROUND / 7 RINGS","10 AROUND / 1 RING"][row]
			Kit.label(support,("EDGES VISIBLE" if side==0 else "PLAIN SURFACE")+"\n"+counts,Vector3(0,.59,.57),.0011)
	var entrance := Node3D.new();entrance.name="EntranceSphereStand";entrance.position=Vector3(4.8,0,2.5);add_child(entrance)
	Kit.pedestal(entrance,Vector3.ZERO,.85,1.12)
	Kit.label(entrance,"BEGIN WITH A SPHERE",Vector3(0,.58,.57),.0011)
	var prompt := words("01 / SAME MESH, WITH AND WITHOUT EDGES\nWalk between the pairs. Watch the outline.",Vector3(0,.026,4.1),true,.0012)
	prompt.name="ComparisonEntrance"
	var counts_prompt := words("02 / CHOOSE A USE, THEN REVEAL THE COUNT",Vector3(-4.7,.026,2.0),true,.0010)
	counts_prompt.name="CountPrompt"
	var atlas_prompt := words("03 / TWO DIRECTIONS OF RESOLUTION",Vector3(-16,.026,4.0),true,.0011)
	atlas_prompt.name="AtlasPrompt"

func _godot() -> void:
	for i in Library.TYPES.size():
		var title: String=Library.TYPES[i]
		var at := Vector3(-3 if i%2==0 else 3,0,-4.5+floorf(i/2.0)*3)
		var group := Node3D.new();group.name=title;group.position=at;add_child(group)
		Kit.pedestal(group,Vector3.ZERO,.82,1.65)
		var source := load("res://commons/artifacts/ignorance_gallery/prefabs/"+title+".tscn").instantiate() as Node3D
		source.position=Vector3(0,1.48,0);source.set_meta("void_source",source.scene_file_path);group.add_child(source)
		Kit.label(group,title,Vector3(0,.58,.831),.0019)
		Kit.label(group,Library.NOTES[i],Vector3(0,.37,.832),.0011)
	bench("ChoirTable",Vector3(-16,0,-1.5),4.2,2,.78)
	specimen("res://commons/artifacts/seven_words_choir/seven_words_choir.tscn","SevenWordsChoir",Vector3(-16,.78,-1.5))
	words("A RESOURCE IS A STARTING VOCABULARY",Vector3(0,.025,6.7),true,.0015)

func _columns() -> void:
	ColumnsStudy.build(self)

func _profiles() -> void:
	ProfilesStudy.build(self)

func _portals() -> void:
	var portals := specimen("res://commons/primitives/combines/combine_portals.tscn","RefinementPassage",Vector3(-16,0,-6),0,{"portal_count":7,"portal_spacing":1.8,"discovery":true})
	# Preserve all seven progressively refined meshes. Fit each ring's outer
	# width into the west wing while keeping the controls at their original size.
	for portal in portals._portals: portal.scale=Vector3.ONE*.58;portal.position.y=2.33
	bench("LimitTable",Vector3(0,0,-1),2.8,7.3,.82)
	var chase := specimen("res://commons/primitives/combines/achilles_tortoise.tscn","AchillesAndTortoise",Vector3(0,.84,2),0,{"discovery":true})
	# Keep the experiment controls above this table, including after editor turns.
	chase.get_node("ExperimentPanel").position.y = .9
	words("A FINITE MESH / ANOTHER REFINEMENT",Vector3(-16,.025,7),true,.0014)
	words("A SMALLER GAP / CHOOSE WHEN TO STOP",Vector3(0,.025,4.5),true,.0014)

func _melencolia() -> void:
	specimen("res://commons/scenes/demos/durer/EngravingScene.tscn","MelencoliaEngraving",Vector3(-16,0,-1),0,{"figure":"skull"})
	# The nine original court solids remain separately editable layout records.
	# Carry the grid's raised support and original wp joins into the tower.
	var deck := Kit.block(self,Vector3(5,1,5),Vector3(0,.5,-2),Color("b8b5ab"))
	deck.name="CourtDeck"
	for i in 2:
		specimen("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn","CourtRampLeft" if i==0 else "CourtRampRight",Vector3(-.5+i,0,1.5),180)
	var table := bench("CompositionTable",Vector3(4,0,4.5),5,3,.8)
	table.set_meta("editor_label","Composition table / restore and compare")
	var composition := Composition.new(); composition.name="Study"; table.add_child(composition)
	for i in 3:
		var source: String=["res://commons/primitives/tetrahedron/grab_tetrahedron.tscn","res://commons/primitives/cubes/grab_cube.tscn","res://commons/primitives/octahedron/grab_octahedron.tscn"][i]
		var body := specimen(source,"CompositionSolid%d"%i,Vector3(2.6+i*1.4,1.35,4.5)) as XRToolsPickable
		Composition.prepare(body,[Color("c98bb2"),Color("a8bfd5"),Color("dfb46f")][i])
	specimen("res://commons/artifacts/prefab_box_library/prefab_box_library.tscn","ReturnToTheBoxLibrary",Vector3(16.5,0,-.6),90,{"worktable_x":0.0,"worktable_z":2.3,"column_pitch":1.2})
	words("SAME FORMS / YOUR ARRANGEMENT",Vector3(0,.025,.8),true,.0015)
	words("CARRY A BODY\nCHANGE ITS RELATION",Vector3(0,1.8,6.8),false,.0015).rotation.y=PI
	var view := words("SAME BODIES / ANOTHER VIEW\nWalk up. Then look back from the side.",Vector3(0,.026,3),true,.0012)
	view.name="CourtViewpoint"
	var counter := words("THE COUNTER IS STILL RUNNING",Vector3(17,.026,7),true,.0012)
	counter.name="CounterReturn"

func _remember() -> void:
	for body in find_children("*","RigidBody3D",true,false):
		if body.has_method("is_picked_up"): homes[body]=body.transform

func reset_after_fall() -> void:
	for body in homes:
		if not is_instance_valid(body) or body.is_picked_up(): continue
		if body.global_position.y<global_position.y-1:
			body.transform=homes[body];body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO
			PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
