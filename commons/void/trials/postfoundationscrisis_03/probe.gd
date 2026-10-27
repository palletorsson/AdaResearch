extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	if level == 1:
		await collective_checks(tag)
	else:
		await network_checks(tag)

func collective_checks(tag: String) -> void:
	var peer: Node3D = artifact("peer_production_tool")
	check(tag+"original full workbench is interactive at source rate",peer.interactive and is_equal_approx(peer.add_period,.7) and peer._peers.size()==12)
	await approach(peer)
	await frames(130)
	check(tag+"original timed packets land as attributed pieces",peer._placed>1 and peer._records.size()==peer._placed and peer._records.all(func(r): return int(r.source)>=0 and int(r.source)<12))
	await press(peer._controls.find_child("Btn_0",true,false))
	var count: int = peer._placed
	await frames(70)
	check(tag+"FLOW pointer holds incoming work",peer._paused and peer._placed==count)
	await press(peer._controls.find_child("Btn_1",true,false))
	check(tag+"COLOUR pointer reveals source identity",peer._show_sources and peer._facets.multimesh.get_instance_color(0).is_equal_approx(peer._source_colour(peer._records[0].source)))
	var selected: int = peer._selected
	await press(peer._controls.find_child("Btn_2",true,false))
	check(tag+"PIECE pointer selects the next existing contribution",peer._selected==(selected+1)%count and peer._paused)
	selected=peer._selected
	var source: int = peer._records[selected].source
	var pose: Transform3D = peer._records[selected].current
	await press(peer._controls.find_child("Btn_3",true,false))
	check(tag+"DISPUTE pointer marks without adding or erasing",peer._records[selected].disputed and peer._placed==count)
	await press(peer._controls.find_child("Btn_4",true,false))
	check(tag+"REVISE pointer changes pose and records visitor",not peer._records[selected].current.is_equal_approx(pose) and peer._records[selected].revised_by=="VISITOR" and peer._records[selected].revision==1)
	check(tag+"revision keeps count and original source",peer._placed==count and peer._records[selected].source==source and peer._records[selected].original.is_equal_approx(pose))
	var total: int = peer._edits
	var ever: int = peer._ever_seen.size()
	await press(peer._controls.find_child("Btn_5",true,false))
	check(tag+"VERSION pointer retains prior version and cumulative counts",peer._version==2 and peer._placed==0 and peer._last_version.size()==count and peer._edits==total and peer._ever_seen.size()==ever)
	await press(peer._controls.find_child("Btn_0",true,false))
	await frames(80)
	check(tag+"FLOW resumes arrivals in new version",not peer._paused and peer._placed>0)
	var wiki: Node3D = artifact("wiki_fragment")
	check(tag+"NORTH fragment survives relocation",wiki._resolve_fragment_key()=="NORTH" and wiki._title_label.text==wiki.FRAGMENTS.NORTH.title and wiki._cf_label.text.contains("EAST"))
	var gates: Node3D = artifact("the_fourth_limit")
	check(tag+"four static gates retain glass fourth limit and lamp",gates.gate_iv=="glass" and gates.behind=="lamp" and gates.NUMERALS.size()==4 and not gates.is_processing())
	var table: Node3D = artifact("the_commons_table")
	check(tag+"commons table retains original seeded assembly",table.seed==17 and table.specimens==18 and is_equal_approx(table.table_r,1.15) and table.get_child_count()>80)

func network_checks(tag: String) -> void:
	var grower: Node3D = artifact("rhizome_grower")
	check(tag+"grower retains original interactive seeded sample",grower.interactive and grower.sample_seed==47 and is_equal_approx(grower.spread,.85) and is_equal_approx(grower.grow_period,.8))
	await approach(grower)
	await press(grower._controls.find_child("Btn_5",true,false))
	var sample: Array = grower._samples.duplicate()
	check(tag+"REPLAY pointer resets to two seeds and holds",grower._node_total==2 and grower._paused)
	await press(grower._controls.find_child("Btn_1",true,false))
	check(tag+"STEP pointer adds next stored sample and nearest links",grower._node_total==3 and grower._positions[2]==sample[2] and grower._edge_total==2)
	await press(grower._controls.find_child("Btn_1",true,false))
	var before: Array = grower._positions.duplicate()
	check(tag+"fourth shoot links to three prior nodes",grower._node_total==4 and grower._edge_total==5 and grower._components==1)
	await press(grower._controls.find_child("Btn_2",true,false))
	check(tag+"LINKS pointer rewires same positions with one neighbour",grower.links_per_node==1 and grower._positions==before and grower._edge_total==2)
	await press(grower._controls.find_child("Btn_2",true,false))
	await press(grower._controls.find_child("Btn_3",true,false))
	var selected: int = grower._selected
	var visible: int = grower._visible_edges
	await press(grower._controls.find_child("Btn_4",true,false))
	check(tag+"CUT pointer removes selected node from active graph",not grower._active[selected] and grower._visible_edges<visible)
	await press(grower._controls.find_child("Btn_0",true,false))
	await frames(65)
	check(tag+"cut graph refuses growth until restoration",grower._paused and grower._node_total==4)
	await press(grower._controls.find_child("Btn_4",true,false))
	check(tag+"CUT again restores original edges",grower._active[selected] and grower._visible_edges==visible and grower._positions==before)
	await press(grower._controls.find_child("Btn_0",true,false))
	await frames(65)
	check(tag+"GROW pointer resumes timed nearest-neighbour growth",not grower._paused and grower._node_total>4)
	await press(grower._controls.find_child("Btn_5",true,false))
	await press(grower._controls.find_child("Btn_1",true,false))
	check(tag+"REPLAY reuses exactly the same sample cloud",grower._samples==sample and grower._positions[2]==sample[2])
	var film: Node3D = artifact("film_rhizome_routes")
	await approach(film)
	# Reuse the input driver at the monitor's original Area3D buttons.
	await monitor_press(film,"step")
	check(tag+"film STEP pointer holds a phase",not film.stage.running and film.stage.playhead>=6)
	var time: float = film.stage.playhead
	await frames(15)
	check(tag+"film held phase remains stable",film.stage.playhead==time)
	var view: float = film.stage._view_offset
	await monitor_press(film,"route")
	check(tag+"film TURN VIEW pointer changes private camera",film.stage._view_offset>view and film.viewport.own_world_3d)
	await monitor_press(film,"replay")
	check(tag+"film REPLAY starts its original sample",film.stage.running and film.stage.playhead<1)
	await monitor_press(film,"pause")
	check(tag+"film PAUSE pointer holds playback",not film.stage.running)
	check(tag+"film retains measured graph comparison",film.stage.evidence.nodes==18 and film.stage.evidence.three_link_edges>film.stage.evidence.one_link_edges)
	var cave: Node3D = artifact("rhizome_cave_demo")
	for i in 600:
		if cave._passages != null and cave._passages.ready_to_walk: break
		await frames(1)
	var passage: Node3D = cave._passages
	check(tag+"original authored passage shell finishes",cave.passage_study and passage!=null and passage.ready_to_walk and passage.shell_mesh.get_surface_count()==2)
	check(tag+"cave retains fifteen junctions and twenty connections",passage.points.size()==15 and passage.links.size()==20)
	check(tag+"cave leaves visitor camera and environment intact",not cave.has_node("Environment") and not cave.has_node("Camera3D") and game.get_viewport().get_camera_3d()==game.camera)
	var hit: Dictionary = ray(passage.to_global(Vector3(0,1,-3)),passage.to_global(Vector3(0,-.5,-3)))
	check(tag+"original tunnel floor has collision",not hit.is_empty() and hit.collider==passage.get_node("WalkableShell"))
	var upper: Dictionary = ray(passage.to_global(Vector3(2,4.7,1)),passage.to_global(Vector3(2,3.2,1)))
	check(tag+"upper crossing retains separate walkable height",not upper.is_empty() and upper.collider==passage.get_node("WalkableShell"))
	var deaths: int = game.deaths
	game.place_player(cave.to_global(Vector3(0,.06,-14.2)))
	await frames(20)
	var entered: bool = await move_to(cave.to_global(Vector3(-3,.06,-9.5)))
	check(tag+"walk across slab edge into original passage",entered and game.deaths==deaths and game.body.is_on_floor() and not game.recovering)
	check(tag+"exterior passage is supported without opening the whole void",game._exterior_walk_support(game.body.global_position) and not game._exterior_walk_support(cave.to_global(Vector3(20,.06,0))))
	game.place_player(cave.to_global(Vector3(2,3.76,1)))
	await frames(40)
	check(tag+"upper crossing supports desktop or XR body",game.deaths==deaths and game.body.is_on_floor() and game.checkpoint==2 and not game.recovering)
	game.place_player(game.spawn_for(2));await frames(15)

func monitor_press(monitor: Node3D, key: String) -> void:
	# Proxy nodes locate the real button without adding collision or callbacks.
	var proxy := Node3D.new()
	monitor.buttons[key].add_child(proxy)
	var area := Node3D.new(); area.name="InteractableAreaButton"; proxy.add_child(area)
	var point := Node3D.new(); point.name="CollisionShape3D"; area.add_child(point)
	await press(proxy)
	proxy.queue_free()

func capture_floor() -> void:
	if level==1:
		await super.capture_floor()
	else:
		var cave: Node3D = artifact("rhizome_cave_demo")
		await photo("03-rhizome-passages",cave.to_global(Vector3(22,15,15)),cave.to_global(Vector3(0,2,0)))
	var subject: Node3D = artifact("peer_production_tool" if level==1 else "rhizome_grower")
	await photo("02-common-work" if level==1 else "04-network-workbench",subject.to_global(Vector3(2.5,2.2,3.9)),subject.to_global(Vector3(0,1.1,0)))
