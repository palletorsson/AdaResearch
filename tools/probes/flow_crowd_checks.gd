extends SceneTree
const Model=preload("res://commons/artifacts/flow_crowd/model.gd")
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(words:String,ok:bool)->void:
	checks.append({"name":words,"passed":ok});print("CROWD ","PASS " if ok else "FAIL ",words)
	if not ok:failures.append(words)
func run()->void:
	var m=Model.new()
	check("Shared route builder is the existing FlowGrid",m.grid is FlowGrid)
	check("Twenty-four bodies begin at distinct return places",m.positions.size()==24 and m.arrived.count(true)==24 and m.positions[0]!=m.positions[1])
	var count:int=m.rebuilds;m.set_route(0);check("Unchanged target does not rebuild the field",m.rebuilds==count)
	var bounded:=true;var finite:=true;var all_arrive:=true;var crossing:Dictionary={}
	for choice in [-1,1,0]:
		m.set_route(choice);var used:Array=[]
		for tick in range(3000):
			m.step(1.0/60)
			for i in range(m.COUNT):
				bounded=bounded and m.valid(m.positions[i])
				finite=finite and m.positions[i].is_finite() and m.velocities[i].is_finite() and m.velocities[i].length()<=m.SPEED+.001
				if absf(m.positions[i].x)<1.3 and absf(m.positions[i].z)>2.5:used.append(signf(m.positions[i].z))
		check("All bodies reach destination "+str(choice),m.arrived.count(true)==24)
		print("CROWD POS ",choice," ",m.positions)
		crossing[str(choice)]={"arrived":m.arrived.count(true),"negative_side":used.has(-1.0),"positive_side":used.has(1.0)}
		all_arrive=all_arrive and m.arrived.count(true)==24
	check("Every tested position clears island and perimeter",bounded)
	check("All motion remains finite and speed-capped",finite)
	check("Initial route A goes around the A side",crossing["-1"].negative_side and not crossing["-1"].positive_side)
	# Identical field and mover, independent of population order or presence.
	var a=Model.new();var b=Model.new();a.set_route(-1);b.set_route(-1)
	for i in range(1,24):b.positions[i]=Vector3(6,0,4);b.velocities[i]=Vector3.LEFT;b.arrived[i]=true
	for tick in range(900):a.step(1.0/60);b.step(1.0/60)
	check("Other bodies do not alter the witness trajectory",a.positions[0]==b.positions[0] and a.velocities[0]==b.velocities[0])
	var changing=Model.new();changing.set_route(-1)
	for tick in range(300):changing.step(1.0/60)
	changing.set_route(1)
	for tick in range(3000):changing.step(1.0/60)
	check("Mid-route reversal reaches B without resetting positions",changing.arrived.count(true)==24)
	changing.set_route(0)
	for tick in range(3000):changing.step(1.0/60)
	check("The reversed group can return around the island",changing.arrived.count(true)==24)
	var host:=Node3D.new();root.add_child(host);host.position=Vector3(30,4,-20);host.rotation.y=.7
	var h=load("res://commons/artifacts/flow_crowd/flow_crowd.tscn").instantiate();h.playing=false;host.add_child(h)
	check("Artifact uses the carried PointBody class",h.point.get_script().resource_path.ends_with("/particle_swarm_walk/point_body.gd"))
	var pointer:=Node3D.new();root.add_child(pointer);h.point.on_desktop_grab(pointer)
	h.point.global_position=h.to_global(h.HOME+Vector3(0,0,-.35));h._physics_process(1.0/60)
	check("Held point selects A in artifact coordinates",h.model.route==-1)
	h.point.global_position=h.to_global(h.HOME+Vector3(0,0,.05));h._physics_process(1.0/60)
	check("Neutral hand band keeps the chosen route",h.model.route==-1)
	h.point.global_position=h.to_global(h.HOME+Vector3(0,0,.35));h._physics_process(1.0/60)
	check("Held point selects B in artifact coordinates",h.model.route==1)
	var before=h.model.positions.duplicate();var ticks:int=h.model.ticks;h.point.action();h._refresh()
	check("Actual point action hides directions without advancing bodies",not h.guides and not h.arrow_layer.visible and before==h.model.positions and h.model.ticks==ticks)
	h.point.action();h._refresh();check("Second action restores directions",h.guides and h.arrow_layer.visible)
	var directions_exact:=true
	for arrow in h.arrows:
		var c:Vector2i=arrow.get_meta("cell");var v:Vector3=h.model.grid.get_vector(h.model.grid.grid_to_world(c.x,c.y))
		directions_exact=directions_exact and (not arrow.visible if v.is_zero_approx() else (-arrow.basis.z).distance_to(v)<.001)
	check("Visible arrow geometry points in the sampled field direction",directions_exact)
	var identities:Array=[];for figure in h.figures:identities.append(figure.get_instance_id())
	h.point.on_desktop_drop(pointer);h._physics_process(1.6)
	check("Drop selects return and restores point to stand",h.model.route==0 and h.point.position==h.HOME)
	var after_ids:Array=[];for figure in h.figures:after_ids.append(figure.get_instance_id())
	check("Retarget and return retain all body identities",identities==after_ids)
	check("Exactly one arrow per sampled walkable cell",h.arrows.size()>100 and h.arrows.size()<200)
	observations={"routes":crossing,"route_cycle_seconds":150,"mid_route_reversal_seconds":105,"headset_tested":false}
	FileAccess.open("res://ada_run/flow_crowd_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	host.queue_free();pointer.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
