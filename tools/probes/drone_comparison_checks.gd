extends SceneTree
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok});print("DRONES ","PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)
func run() -> void:
	var scene=load("res://commons/artifacts/drone_comparison/drone_comparison.tscn")
	if scene==null:quit(1);return
	var host:=Node3D.new();root.add_child(host);host.position=Vector3(30,4,-20);host.rotation.y=.7
	var h=scene.instantiate();h.playing=false;host.add_child(h);h._physics_process(0)
	check("Two flights of twelve reuse original Boid integration",h.flights.size()==2 and h.flights[0].drones.size()==12 and h.flights[1].drones[0] is Boid)
	var starts_same:=true
	for i in range(h.COUNT):
		starts_same=starts_same and h.flights[0].drones[i].position==h.flights[1].drones[i].position and h.flights[0].drones[i].velocity==h.flights[1].drones[i].velocity
	check("Flights start with identical relative positions and velocities",starts_same)
	check("Each flight reads only its own twelve neighbours",h.flights[0].get_boids()==h.flights[0].drones and not h.flights[0].get_boids().has(h.flights[1].drones[0]))
	var assigned=h.flights[0].drones[0];var local=h.flights[1].drones[0]
	check("Assigned controller reads a per-body slot",assigned.destination().is_equal_approx(h.flights[0].to_global(assigned.slot)))
	check("Neighbour controller reads shared destination",local.destination().is_equal_approx(h.flights[1].global_position))
	check("Only local flight enables alignment and cohesion",assigned.alignment_weight==0 and assigned.cohesion_weight==0 and local.alignment_weight>0 and local.cohesion_weight>0)
	check("Separation and speed limits match in both flights",assigned.separation_weight==local.separation_weight and assigned.max_speed==local.max_speed and assigned.min_speed==local.min_speed)
	check("Arrive request at destination brakes existing velocity",assigned.steering_at(assigned.destination(),Vector3.RIGHT).x<0)
	check("Destination request has bounded strength",assigned.steering_at(assigned.global_position+Vector3(40,20,30),Vector3.ZERO).length()<=3.001)
	check("PointBody class is reused unchanged",h.point.get_script().resource_path.ends_with("particle_swarm_walk/point_body.gd"))
	var pointer:=Node3D.new();root.add_child(pointer);h.point.on_desktop_grab(pointer)
	h.point.global_position=h.to_global(h.HOME+Vector3(1,.3,.4));h._physics_process(0)
	check("Hand displacement is read in transformed host coordinates",h.target_offset.is_equal_approx(Vector3(1,.3,.4)))
	check("Same hand offset reaches both flights",(assigned.destination()-h.flights[0].to_global(assigned.slot)).is_equal_approx(local.destination()-h.flights[1].global_position))
	h.point.global_position=h.to_global(h.HOME+Vector3(30,30,30));h._physics_process(0)
	check("Control is bounded to the flight volume",h.target_offset.is_equal_approx(Vector3(1.6,.45,.65)))
	var positions:Array=[];var velocities:Array=[]
	for flight in h.flights:
		for d in flight.drones:positions.append(d.position);velocities.append(d.velocity)
	h.point.action();h._refresh()
	check("Actual action hides guidance",not h.guides and not h.arrows[0].visible and not h.slots[0].visible)
	var unchanged:=true;var k:=0
	for flight in h.flights:
		for d in flight.drones:
			unchanged=unchanged and d.position==positions[k] and d.velocity==velocities[k];k+=1
	check("Changing display does not change flight state",unchanged)
	h.point.action();check("Second action restores guidance",h.guides)
	h.point.on_desktop_drop(pointer);h._physics_process(2)
	check("Release returns both targets to centre and point to stand",h.target_offset==Vector3.ZERO and h.point.global_position.is_equal_approx(h.to_global(h.HOME)))
	var finite:=true;var bounded:=true;var speeds:=true
	for step in range(2400):
		for flight in h.flights:
			for d in flight.drones:
				d._physics_process(1.0/60)
				var p:Vector3=flight.to_local(d.global_position)
				finite=finite and p.is_finite() and d.velocity.is_finite()
				speeds=speeds and d.velocity.length()<=d.max_speed+.001
				bounded=bounded and absf(p.x)<4.65 and absf(p.y)<1.25 and absf(p.z)<2.25
	check("Forty seconds remain finite and speed-capped",finite and speeds)
	check("Both flights stay near their own translated volume",bounded)
	var error_assigned:=0.0;var error_neighbours:=0.0
	for i in range(h.COUNT):
		error_assigned+=h.flights[0].drones[i].position.distance_to(h.flights[0].drones[i].slot)
		error_neighbours+=h.flights[1].drones[i].position.distance_to(h.flights[1].drones[i].slot)
	error_assigned/=h.COUNT;error_neighbours/=h.COUNT
	observations.assigned_mean_slot_error=error_assigned;observations.neighbours_mean_slot_error=error_neighbours
	print("SLOT ERRORS ",error_assigned," ",error_neighbours)
	check("Assigned flight settles on assigned positions",error_assigned<.1)
	check("Local flight does not reproduce those assigned slots",error_neighbours>error_assigned+.3)
	var held_bounds:=true
	for direction in [-1.0,1.0]:
		h.target_offset=Vector3(1.6,.45,.65)*direction
		for step in range(900):
			for flight in h.flights:
				for d in flight.drones:
					d._physics_process(1.0/60)
					var p:Vector3=flight.to_local(d.global_position)
					held_bounds=held_bounds and p.is_finite() and absf(p.x)<4.65 and absf(p.y)<1.25 and absf(p.z)<2.25
	check("Extreme hand targets keep both flights inside their court volumes",held_bounds)
	h._refresh()
	var a:Vector3=h.to_local(assigned.global_position);var b:Vector3=a+h.global_basis.inverse()*assigned.acceleration*.25
	check("Witness arrow length represents actual acceleration",is_equal_approx(h.arrows[0].basis.y.length(),a.distance_to(b)) or a.distance_to(b)<.001)
	check("Only stand seals navigation cells",h.get_museum_occupied_cells().size()<=4)
	FileAccess.open("res://ada_run/drone_comparison_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Original production Boid integration plus new guidance adapter; actual PointBody actions with synthetic pickup. No physical headset."},"  "))
	quit(0 if failures.is_empty() else 1)
