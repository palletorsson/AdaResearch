extends "res://tools/probes/principal_places.gd"
## THE FLIGHT BAY IN THE BIOME COURT (2026-11-02), in the actual tower (floor 210) with the desktop walker or a
## synthetic XR rig. Walks the hall's own route to the court's east rim, then: the rim walk never flies; step off the
## rim through the door and hover; rise until the roof holds; the glass holds above the doors; sink below the rim and
## land on the court floor; a jump from that floor is caught by the air; fly out of the east door onto the rim. The
## control: the same bay in mode still drops us into the court - the bay, not the hall, is what holds us.
## Under the bay, the court's floor holds the PRIMITIVES STRATUM (biome_object's ladder at stage primitives, seed 7):
## checked as built and fitted, walked round from the descent ramp, and compared with the same seed's later stages.
## Run: python tools/test_flight_bay.py   (writes checks.json and photographs under --out)
## Loaded in run(), not preloaded: a parse-time preload compiles XR Tools' player body before the autoloads exist
## (XRToolsUserSettings), and the broken compile is cached for the whole run - the XR rig then never builds.
var FlightBox:GDScript
const RIM:=4.0
var bay:Node3D
var rim_flight_frames:=0
var watching_rim:=false
var y_tolerance:=.12
var observations:Array=[]

## principal_places.walk_to with the height tolerance as a parameter (the route was written before the plate's surface).
func walk_to(target:Vector3,label:String)->void:
	var start:Vector3=work.to_local(game.body.global_position)
	for i in 1000:
		var at:Vector3=work.to_local(game.body.global_position)
		var delta:=Vector2(target.x-at.x,target.z-at.z)
		if xr and delta.length()<.6:
			axes(Vector2.ZERO);await frames(60)
			at=work.to_local(game.body.global_position)
			delta=Vector2(target.x-at.x,target.z-at.z)
			if delta.length()<.12:break
		elif not xr and delta.length()<.07:break
		var speed:float=minf(1,delta.length()*1.5)
		if xr:speed=1
		axes(delta.normalized()*speed);await frames(1)
		if xr and delta.length()<.7:axes(Vector2.ZERO);await frames(16)
	axes(Vector2.ZERO);await frames(45)
	var end:Vector3=work.to_local(game.body.global_position)
	var okay:bool=Vector2(end.x-target.x,end.z-target.z).length()<.2 and absf(end.y-target.y)<y_tolerance and game.body.is_on_floor() and game.floor_stream.focus==active_floor
	check(label,okay);details.append({"name":label,"from":str(start),"target":str(target),"actual":str(end),"passed":okay})
	print("PLACE_WALK ",label," target=",target," actual=",end)

func run()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg.begins_with("--main-floor="):active_floor=int(arg.trim_prefix("--main-floor="));main_tower=true
	xr="--xr" in OS.get_cmdline_user_args();Engine.physics_ticks_per_second=90
	FlightBox=load("res://commons/movement/museum_flight_box.gd")
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
	if main_tower:
		preload("res://commons/void/room_source.gd").use_main_tower=true
		load("res://commons/void/game.gd").requested_floor=active_floor
	game=load("res://commons/void/void.tscn" if main_tower else "res://commons/void/trials/principal_places/trial.tscn").instantiate();game.force_xr=xr
	root.add_child(game);current_scene=game;game.scene_loaded();game.scene_visible();game.set_process_unhandled_key_input(false)
	if not xr:game.body.scripted_input=true;game.body.set_process_unhandled_input(false)
	await frames(45)
	work=game.building.content.exhibits[str(active_floor)+"/principal-places"].get_node("Artifact")
	bay=work.get_node_or_null("biome-plastic-bath_flight")
	check("the court's flight bay is built from the hall sidecar",bay!=null and bay.get_meta("activity_artifact","")=="flight_bay" and bay.envelope!=null)
	if bay==null:
		finish();return
	check("its origin is the court rim, its volume 9.9 x 9.9 x 8 m, doors east, west and south",bay.position.is_equal_approx(Vector3(0,RIM,0)) and is_equal_approx(bay.width,9.9) and is_equal_approx(bay.depth,9.9) and is_equal_approx(bay.height,8.0) and Array(bay.doors)==["east","west","south"])
	check("it flies: in the museum's flight group",bay.mode=="flight" and bay.is_in_group(FlightBox.GROUP))
	check("air over the court is flight, down to just under the rim",at(Vector3(0,6,0))==bay and at(Vector3(4.8,RIM+.01,4.8))==bay and at(Vector3(0,RIM-.01,0))==bay)
	check("the court floor, just below the bay, the rim walk and above the roof are not",at(Vector3(0,3.2,0))==null and at(Vector3(0,RIM-.05,0))==null and at(Vector3(5.5,RIM+.05,0))==null and at(Vector3(0,RIM+bay.height+.01,0))==null)
	the_court_stays_walkable()
	glass_clear_of_the_hall()
	await stratum_checks()
	# 1. the hall's own route to the court's east rim, watching that the rim walk never flies
	var route:Array=work.recipe.inspection_route
	physics_frame.connect(_watch)
	watching_rim=false
	var first:=1   # waypoint 0 is the spawn on the disco plate, whose noise surface (31 Oct) stands above the route's y
	if xr:
		# THE XR SPAWN on floor 210 starts under the disco plate's noise surface (measured: its feet at the slab, the
		# desktop walker's 0.28 m higher) and is held there. Not the bay's: recorded, and the XR walk starts off the plate.
		observations.append({"xr_spawn_feet":local().y,"plate_surface_at_spawn":surface_y(Vector2(local().x,local().z))})
		game.place_player(work.to_global(Vector3(route[2][0],route[2][1]+.05,route[2][2])));game.rebase_player_motion();await frames(60);first=3
	for i in range(first,11):
		watching_rim=i>=8   # from the south-west rim corner on: the rim walk, past the west door
		y_tolerance=.35 if route[i][1]<.5 else .12   # the disco plate's noise surface stands up to ~0.3 m over the route's y
		var before:=failed.size()
		await walk_to(Vector3(route[i][0],route[i][1],route[i][2]),"route to the rim %02d"%i)
		if failed.size()>before:
			finish();return
	y_tolerance=.12
	# down the descent ramp under the south door, round the stratum's plinth in the court's ring, and back up to the rim
	var court_walk:Array=[route[11],route[12],route[13],route[14],[0,3,3.75],[4.4,3,3.75],[4.4,3,0],[4.4,3,3.75],[0,3,3.75],route[14],route[13],route[12],route[11]]
	for w in court_walk:
		var before:=failed.size()
		await walk_to(Vector3(w[0],w[1],w[2]),"the court walk with the bay installed, to (%.1f, %.1f, %.1f)"%[w[0],w[1],w[2]])
		if failed.size()>before:
			finish();return
	await walk_to(Vector3(5.5,RIM,0),"the east rim walk, at the door")
	watching_rim=false
	check("walking the rim past the west and south doors, down the ramp, round the stratum and back, never flew (%d frames)"%rim_flight_frames,rim_flight_frames==0)
	# 2. step off the rim through the door: hover
	level_view()
	var entered:=await drive_until(Vector2(-1,0),func():return here()==bay,240)
	var entered_at:=local()
	# on, clear of the lip: at the threshold the capsule (r 0.2) still rests on the rim's edge
	await drive_until(Vector2(-1,0),func():return local().x<4.3,240)
	axes(Vector2.ZERO);await frames(20)
	check("the step through the door is where flight begins (entered at x %.2f, feet %.2f)"%[entered_at.x,entered_at.y],entered and entered_at.x<bay.width*.5 and entered_at.x>bay.width*.5-.3 and absf(entered_at.y-RIM)<.06)
	var y0:float=local().y;await frames(180)
	check("a step past the door, released, we hover over the court (moved %.3f m in 2 s, feet %.2f, floor 1 m below)"%[absf(local().y-y0),local().y],here()==bay and absf(local().y-y0)<.02 and not game.body.is_on_floor() and local().x<4.4)
	# 3. rise until the roof holds, where we are (the stratum's 3 m cage stands between the door and the centre)
	var peak:=await rise(1.0,900)
	var roof:=ray_up()
	check("we rise until the roof holds (feet at %.2f; above the head: %s, %.2f m)"%[peak,roof.get("name","nothing"),roof.get("gap",-1.0)],peak>RIM+5.5 and peak<RIM+bay.height-.18-1.0 and here()==bay and roof.get("name","")=="RoofCollision" and roof.get("gap",9.0)<.3)
	if not xr:await photograph("bay_from_inside_high",game.body.global_position+Vector3(0,1.6,0),work.to_global(Vector3(0,3,0)))
	# 4. the glass holds: fly north; then, back at z 0, east into the door's lintel
	await rise(-1.0,0,RIM+4.0)
	await drive_until(Vector2(0,-1),func():return false,420);axes(Vector2.ZERO)
	var north:float=local().z
	check("the north glass holds (stopped at z %.2f)"%north,north>-bay.depth*.5 and north<-bay.depth*.5+.6 and here()==bay)
	await go_to(0.0,0.0)
	await drive_until(Vector2(1,0),func():return false,480);axes(Vector2.ZERO)
	var east:=local()
	check("over the east door its lintel holds (stopped at x %.2f, z %.2f, feet %.2f)"%[east.x,east.z,east.y],east.x<bay.width*.5 and east.x>bay.width*.5-.6 and absf(east.z)<.5 and east.y>RIM+bay.door_height-.2 and here()==bay)
	# 5. sink below the rim: gravity sets us down on the court floor, unhurt
	var deaths_before:int=game.deaths
	await go_to(4.5,-2.0)   # the strip between the stratum's cage (x 4) and the bath wall (x 5)
	await rise(-1.0,0,RIM-.3)
	await frames(90)
	var floor_y:=surface_y(Vector2(local().x,local().z))
	check("sunk below the rim, we land on the court floor (feet %.2f, floor %.2f), unhurt"%[local().y,floor_y],game.body.is_on_floor() and absf(local().y-floor_y)<.08 and floor_y<RIM-.5 and here()==null and game.deaths==deaths_before and not game.recovering)
	# 6. a jump from the court floor rises into the air and is caught
	await go_to(4.5,-2.0)
	press_jump();await frames(2);release_jump()
	var caught:=false
	for i in 120:
		await frames(1)
		if here()==bay:caught=true;break
	await frames(90)
	check("a jump from the court floor is caught by the air (feet held at %.2f)"%local().y,caught and here()==bay and local().y>=RIM-.03 and not game.body.is_on_floor())
	# 7. fly out of the east door, low: gravity returns over the rim walk
	await rise(1.0,0,RIM+.3)
	await go_to(4.5,0.0)
	var left_bay:=await drive_until(Vector2(1,0),func():return local().x>5.4,720)
	axes(Vector2.ZERO);await frames(120)
	var out_at:=local()
	check("out of the east door, we land on the rim walk (at x %.2f, feet %.2f)"%[out_at.x,out_at.y],left_bay and game.body.is_on_floor() and absf(out_at.y-RIM)<.12 and out_at.x>4.99 and here()==null and game.floor_stream.focus==active_floor)
	if not xr:
		await photograph("bay_from_the_catwalk",work.to_global(Vector3(-2,7,11)),work.to_global(Vector3(0,6,0)))
		await photograph("bay_east_door",work.to_global(Vector3(9,5.6,1.5)),work.to_global(Vector3(4.95,5.2,0)))
		await photograph("bay_over_the_court",work.to_global(Vector3(-4.2,11.3,4.2)),work.to_global(Vector3(1,3,-1)))
		await photograph("bay_south_door_ramp",work.to_global(Vector3(1.2,5.6,9.0)),work.to_global(Vector3(0,4.2,4)))
		await photograph("stratum_from_the_bay",work.to_global(Vector3(.3,11.4,1.2)),work.to_global(Vector3(0,3,0)))
		await photograph("stratum_from_the_ramp",work.to_global(Vector3(0,4.7,5.6)),work.to_global(Vector3(0,3.3,-1)))
	# 8. the control: the same glass, still - stepping off the rim drops us into the court
	bay.apply_grid_config({"mode":"still"})
	var pane:=pane_hit(Vector3(5.5,RIM+1.2,3.0),Vector3(3.5,RIM+1.2,3.0))
	check("mode still keeps colliding glass and leaves the flight group (east wing: %s)"%pane,bay.mode=="still" and not bay.is_in_group(FlightBox.GROUP) and pane.begins_with("east") and at(Vector3(0,6,0))==null)
	await walk_to(Vector3(5.5,RIM,0),"back at the east door")
	level_view()
	await drive_until(Vector2(-1,0),func():return local().x<4.6,240);axes(Vector2.ZERO)
	await frames(150)
	check("still glass: stepping off the rim we fall into the court (feet at %.2f)"%local().y,game.body.is_on_floor() and local().y<RIM-.5)
	bay.apply_grid_config({"mode":"flight"})
	check("mode flight restored",bay.is_in_group(FlightBox.GROUP) and at(Vector3(0,6,0))==bay)
	finish()

func finish()->void:
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"walks":details,"observations":observations,"scope":"Actual tower floor 210, desktop walker or synthetic XR rig: entry, hover, rise, glass, landing, jump, exit and the still-glass control. Headset comfort, motion sickness and the court's look in the headset are human checks."},"  "))
	print("FLIGHT_BAY_COURT ",failed.is_empty());quit(0 if failed.is_empty() else 1)

## The flight zone at a court-local point (Vector3) - or, given the body's world position, at the visitor.
func at(p:Vector3)->Node3D:return FlightBox.at_point(self,work.to_global(p))

func here()->Node3D:return FlightBox.at_point(self,game.body.global_position)

## Fly (or walk) to a court-local x, z.
func go_to(x:float,z:float,limit:=900)->bool:
	for i in limit:
		var d:=Vector2(x-local().x,z-local().z)
		if d.length()<.15:axes(Vector2.ZERO);await frames(20);return true
		axes(d.normalized()*minf(1.0,d.length()*1.5+.3));await frames(1)
	axes(Vector2.ZERO);return false

func local()->Vector3:return work.to_local(game.body.global_position)

func _watch()->void:
	if watching_rim and here()!=null:rim_flight_frames+=1

## The desktop view level and facing north, so a drive is a world direction; XR: the left aim level and forward.
func level_view()->void:
	if xr:
		var pose:XRPose=left.get_pose("aim");left.set_pose("aim",Transform3D(Basis.IDENTITY,pose.transform.origin),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	else:
		game.body.rotation.y=0.0;game.body.camera.rotation.x=0.0

## Drive in a world direction until `done` or `limit` frames.
func drive_until(direction:Vector2,done:Callable,limit:int)->bool:
	for i in limit:
		axes(direction);await frames(1)
		if done.call():axes(Vector2.ZERO);return true
	axes(Vector2.ZERO);return false

## Fly up (+1) or down (-1); stop when the height stops changing, or at `until` (court-local feet height) if given.
## Desktop: Space / Ctrl. XR: the left aim pointed (89 degrees) up or down with the stick forward - no drift.
func rise(sign_:float,limit:int,until:=NAN)->float:
	var last:=local().y;var still:=0
	var n:=limit if limit>0 else 900
	if xr:
		var pose:XRPose=left.get_pose("aim")
		left.set_pose("aim",Transform3D(Basis(Vector3.RIGHT,deg_to_rad(89.0*sign_)),pose.transform.origin),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	for i in n:
		if xr:left.set_input("primary",Vector2(0,1))
		else:game.body.flight_vertical=sign_
		await frames(1)
		var y:=local().y
		if not is_nan(until) and (y>=until if sign_>0 else y<=until):break
		still=still+1 if absf(y-last)<.0005 else 0
		last=y
		if still>30:break
	if xr:left.set_input("primary",Vector2.ZERO);level_view()
	else:game.body.flight_vertical=0.0
	await frames(10)
	return local().y

## The standing height of the hall's static floor under a court-local x, z (balls, the body and the bay's glass ignored).
func surface_y(xz:Vector2)->float:
	var space:=game.get_world_3d().direct_space_state
	var q:=PhysicsRayQueryParameters3D.create(work.to_global(Vector3(xz.x,RIM+3,xz.y)),work.to_global(Vector3(xz.x,-1,xz.y)),0xFFFFFFFF)
	var exclude:Array[RID]=[game.body.get_rid()]
	for k in 8:
		q.exclude=exclude
		var hit:=space.intersect_ray(q)
		if hit.is_empty():return NAN
		if hit.collider is RigidBody3D or hit.collider is Area3D or (hit.collider as Node).get_parent()==bay.envelope:exclude.append(hit.collider.get_rid());continue
		return work.to_local(hit.position).y
	return NAN

## What stands above the visitor's head: the first body a ray from the feet meets going up, and its gap over the head.
func ray_up()->Dictionary:
	var space:=game.get_world_3d().direct_space_state;var from:Vector3=game.body.global_position+Vector3.UP*.3
	var q:=PhysicsRayQueryParameters3D.create(from,from+Vector3.UP*4,0xFFFFFFFF);q.exclude=[game.body.get_rid()];q.collide_with_areas=false
	var hit:=space.intersect_ray(q)
	if hit.is_empty():return {}
	var head:float=game.body.global_position.y+(1.8 if xr else 1.7)
	return {"name":str((hit.collider as Node).name),"gap":hit.position.y-head}

## The name of the bay pane a horizontal ray between two court-local points meets first, or "".
func pane_hit(a:Vector3,b:Vector3)->String:
	var q:=PhysicsRayQueryParameters3D.create(work.to_global(a),work.to_global(b),0xFFFFFFFF);q.exclude=[game.body.get_rid()]
	var hit:=game.get_world_3d().direct_space_state.intersect_ray(q)
	return str((hit.collider as Node).name) if not hit.is_empty() and (hit.collider as Node).get_parent()==bay.envelope else ""

## THE PRIMITIVES STRATUM (Palle, 2026-11-02: "yes the biome-ladder"): biome_object's ladder (/biome-ladder) at stage
## primitives, seed 7 - the gallery's own 12 m world, fitted to 7.6 m, standing 27 cm over the court floor on a walk
## top. Then the ladder's claim, measured: one seed is one world and the stages are its states, so five objects of
## seed 7 - Point_One, primitives, transformation, color and full - built side by side under the tower, standing
## layers only growing until colour retires the lattice and the mats retire the rods. Photographs the five.
const LADDER_STAGES:=["Point_One","primitives","transformation","color","full"]
func stratum_checks()->void:
	var v:Node3D=work.get_node_or_null("biome-plastic-bath_stratum")
	check("the Primitives stratum stands in the court (biome_object from the hall sidecar)",v!=null and v.get_meta("activity_artifact","")=="biome_object")
	if v==null:return
	var st:Dictionary=v.get_state()
	var lad:Dictionary=st.ladder
	check("its stage is primitives, seed 7, the gallery's 12 m world (stage %s, phase %.1f, seed %d, size %d)"%[lad.stage,lad.phase,st.dna.seed,st.dna.size],str(lad.stage)=="primitives" and is_equal_approx(float(lad.phase),1.0) and bool(lad.known) and int(st.dna.seed)==7 and int(st.dna.size)==12)
	var layers:Array=lad.layers
	check("standing: %s - the point, the rods, the lattice, the section and the stones; no relief, no hue"%str(layers),layers.has("point") and layers.has("rods") and layers.has("lattice") and layers.has("section") and layers.has("crystals") and not layers.has("relief") and not layers.has("colour") and st.height_range==[0.0,0.0])
	var box:=mesh_box(v)
	check("fitted to 7.6 m, clear of the ramp's foot and the noise wall (x %.2f..%.2f, z %.2f..%.2f, scale %.3f)"%[box.position.x,box.end.x,box.position.z,box.end.z,v.scale.x],box.size.x<7.7 and box.size.z<7.7 and box.end.z<3.5 and box.position.z>-4.35 and absf(v.scale.x-7.6/12.0)<.02)
	check("its section stays inside the bath: the slab's foot over the court floor (%.3f m)"%box.position.y,box.position.y>2.995)
	var top:=surface_y(Vector2(0.5,-0.4))
	check("its walk top carries a visitor at the plate's surface (%.3f, the plate at 3.27)"%top,absf(top-3.275)<.02)
	check("the ramp's foot is clear (no body between it and the plate's edge)",pane_named(Vector3(0,3.4,4.3),Vector3(0,3.4,3.65))=="")
	# its worker: the humanoid at the same stage and seed, dancing the dance the primitives allow
	var w:Node3D=work.get_node_or_null("biome-plastic-bath_worker")
	check("the worker stands on the stratum (worker_being at the stratum's stage and seed)",w!=null and w.get_meta("activity_artifact","")=="worker_being" and str(w.get_state().stage)=="primitives" and int(w.get_state().seed)==7)
	if w!=null:
		var q0:Quaternion=(w.joint("shoulder_l") as Node3D).global_basis.get_rotation_quaternion()
		await frames(45)
		var q1:Quaternion=(w.joint("shoulder_l") as Node3D).global_basis.get_rotation_quaternion()
		var turned:=rad_to_deg(q0.angle_to(q1))
		var mv:Array=w.get_state().moves
		check("it dances the whole walk's dance in the tower: its shoulder turned %.0f deg in half a second (moves %s)"%[turned,str(mv)],w.is_processing() and turned>3.0 and mv.has("turn") and mv.has("wave") and mv.has("bounce"))
		var foot:=work.to_local((w.joint("ankle_l") as Node3D).global_position).y
		var foot_r:=work.to_local((w.joint("ankle_r") as Node3D).global_position).y
		check("one foot stands on the plinth's top (ankles %.3f / %.3f, the top at 3.275)"%[foot,foot_r],minf(foot,foot_r)>3.29 and minf(foot,foot_r)<3.34)
		# the troupe round it: five more bodies from the halls before Primitives, each dancing, a foot on the top
		var troupe:Array=[w];var stages:Array=[str(w.get_state().stage)];var bad:Array=[]
		for n in ["lines","cord","plates","slabs","round_head"]:
			var t:Node3D=work.get_node_or_null("biome-plastic-bath_worker_"+n)
			if t==null:bad.append(n+" missing");continue
			troupe.append(t);stages.append(str(t.get_state().stage))
			var low:=minf(work.to_local((t.joint("ankle_l") as Node3D).global_position).y,work.to_local((t.joint("ankle_r") as Node3D).global_position).y)
			if not(t.is_processing() and t.get_state().moves.has("wave") and low>3.29 and low<3.34):bad.append("%s foot %.3f"%[n,low])
			if t.get_state().parts==w.get_state().parts:bad.append(n+" wears the first worker's body")
		check("six workers dance in a ring on the stratum, six bodies from the walk to Primitives (%s%s)"%[", ".join(stages),("; "+", ".join(bad)) if not bad.is_empty() else ""],troupe.size()==6 and bad.is_empty())
		if not xr:
			await photograph("worker_in_court",work.to_global(Vector3(3.6,4.5,3.2)),work.to_global(Vector3(1.6,4.05,0.6)))
			await photograph("troupe_in_court",work.to_global(Vector3(4.6,6.0,4.4)),work.to_global(Vector3(0,3.9,-0.4)))
			await photograph("worker_from_the_bay",work.to_global(Vector3(-1.5,8.5,3.8)),work.to_global(Vector3(1.4,3.6,0.2)))
	# the series, under the tower
	var objects:Array=[]
	for i in LADDER_STAGES.size():
		var o:Node3D=load("res://commons/artifacts/biome_object/biome_object.tscn").instantiate()
		o.set_meta("config_seed",7);o.set_meta("config_size",12);o.set_meta("config_moisture",.5);o.set_meta("config_relief",.5)
		o.set_meta("config_wildness",.6);o.set_meta("config_record","off");o.set_meta("config_stage",LADDER_STAGES[i])
		o.name="Ladder_"+LADDER_STAGES[i]
		game.add_child(o);o.global_position=work.to_global(Vector3(-28.0+14.0*i,-60.0,34.0))
		objects.append(o)
	await frames(10)
	var rows:Array=[]
	for i in objects.size():
		var s:Dictionary=objects[i].get_state()
		rows.append({"stage":LADDER_STAGES[i],"layers":s.ladder.layers,"present":s.kingdoms_present,"organisms":s.organisms,"build_ms":s.build_ms})
	var grows:=true
	for i in range(1,3):   # Point_One -> primitives -> transformation: nothing is retired yet
		for l in rows[i-1].layers:grows=grows and (rows[i].layers as Array).has(l)
	var court_same:bool=objects[1].get_state().ladder.layers==layers and objects[1].get_state().counts.get("mineral",0)==st.counts.get("mineral",0)
	observations.append({"ladder_series":rows})
	print("FLIGHT_BAY_LADDER ",rows)
	check("one seed, later stages keep the earlier layers (%s)"%" -> ".join(rows.slice(0,3).map(func(r):return "%s %d"%[r.stage,(r.layers as Array).size()])),grows and (rows[0].layers as Array).has("point"))
	check("the end of the walk is the full world: %s"%str(rows[4].present),(rows[4].present as Array).has("flora") and (rows[4].present as Array).has("water") and (rows[4].present as Array).has("fauna"))
	check("the court's stratum is the same world as a standalone primitives object",court_same)
	if not xr:
		await photograph("ladder_series",work.to_global(Vector3(0,-44.0,52.0)),work.to_global(Vector3(0,-60.5,34.0)))
	for o in objects:o.queue_free()

## The court-local bounds of a node's meshes (queued ones skipped).
func mesh_box(n:Node3D)->AABB:
	var box:=AABB();var first:=true
	for m in n.find_children("*","MeshInstance3D",true,false):
		var mi:=m as MeshInstance3D
		if mi.mesh==null or mi.is_queued_for_deletion() or not mi.is_visible_in_tree():continue
		var to_court:Transform3D=work.global_transform.affine_inverse()*mi.global_transform
		var b:AABB=to_court*mi.mesh.get_aabb()
		box=b if first else box.merge(b);first=false
	return box

## Court-local positions of a cage's built pieces (its composition: meshes outside the cage, the status screen and the ground).
func pieces(c:Node3D)->Array:
	var out:Array=[]
	for m in c.find_children("*","MeshInstance3D",true,false):
		var skip:=false;var n:Node=m
		while n!=null and n!=c:
			if str(n.name) in ["Cage","StatusHolder","Ground"]:skip=true;break
			n=n.get_parent()
		if not skip:out.append(c.to_local((m as Node3D).global_position))
	return out

## The first body a ray between two court-local points meets that belongs to the stratum's cage, by name, or "".
func pane_named(a:Vector3,b:Vector3)->String:
	var q:=PhysicsRayQueryParameters3D.create(work.to_global(a),work.to_global(b),0xFFFFFFFF);q.exclude=[game.body.get_rid()]
	var hit:=game.get_world_3d().direct_space_state.intersect_ray(q)
	return "" if hit.is_empty() else str((hit.collider as Node).get_path())

## The court's own floor stays below the air: sampled on a half-metre grid, the highest standing point of the static
## floor (the gaussian surface, the descent ramp) is under the bay's lower face.
func the_court_stays_walkable()->void:
	var top:=-INF;var hits:=0;var top_by:="";var envelope_hits:=0;var stratum_top:=-INF
	var space:=game.get_world_3d().direct_space_state
	for ix in range(-9,10):
		for iz in range(-9,10):
			var p:=Vector3(ix*.5,0,iz*.5)
			var q:=PhysicsRayQueryParameters3D.create(work.to_global(p+Vector3(0,RIM+3,0)),work.to_global(p+Vector3(0,2.5,0)),1)
			var exclude:Array[RID]=[]
			q.exclude=exclude
			for k in 6:
				var hit:=space.intersect_ray(q)
				if hit.is_empty():break
				if hit.collider is RigidBody3D:exclude.append(hit.collider.get_rid());q.exclude=exclude;continue   # the ball test's balls
				var stratum:=work.get_node_or_null("biome-plastic-bath_stratum")
				if stratum!=null and stratum.is_ancestor_of(hit.collider):
					stratum_top=maxf(stratum_top,work.to_local(hit.position).y)   # the stratum's walls and pieces stand into the air
					exclude.append(hit.collider.get_rid());q.exclude=exclude;continue
				if (hit.collider as Node).get_parent()==bay.envelope:envelope_hits+=1;break   # the bay over its own court
				var y:float=work.to_local(hit.position).y
				if y>top:top=y;top_by="%s at %s"%[(hit.collider as Node).name,str(p)]
				hits+=1;break
	print("FLIGHT_BAY_COURT_TOP ",top," by ",top_by)
	observations.append({"court_walk_surface_top":top,"stratum_top_in_the_air":stratum_top})
	check("the court's walking surface stays under the air: highest standing point %.3f m (%s), the bay begins at %.2f (%d samples)"%[top,top_by,RIM-.03,hits],hits>200 and top<RIM-.05)
	check("no part of the bay stands over the court floor (%d rays met it)"%envelope_hits,envelope_hits==0)

## No pane of the glass stands in a body of the hall (the rim, its railings, the noise wall, the descent ramp).
func glass_clear_of_the_hall()->void:
	var space:=game.get_world_3d().direct_space_state;var own:Array[RID]=[];var met:Array=[]
	for body in bay.envelope.get_children():
		if body is CollisionObject3D:own.append(body.get_rid())
	for body in bay.envelope.get_children():
		if not body is StaticBody3D:continue
		var shape:CollisionShape3D=body.get_child(0)
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape.shape;q.transform=shape.global_transform;q.exclude=own;q.collision_mask=0xFFFFFFFF
		for hit in space.intersect_shape(q,8):
			var c:Object=hit.collider
			if c is RigidBody3D:continue
			met.append("%s meets %s"%[body.name,(c as Node).get_path() if c is Node else str(c)])
	if not met.is_empty():print("FLIGHT_BAY_OVERLAP ",met)
	# the query is not blind: a pane-sized box set where the rim's joint spheres stand (5, 3.96, 2) must meet one
	var probe_box:=BoxShape3D.new();probe_box.size=Vector3(.04,.3,.3)
	var q2:=PhysicsShapeQueryParameters3D.new();q2.shape=probe_box;q2.transform=Transform3D(work.global_basis,work.to_global(Vector3(4.97,3.96,2)));q2.exclude=own
	check("the overlap query sees a rim joint where the glass would stand without its sill (%d)"%space.intersect_shape(q2,8).size(),not space.intersect_shape(q2,8).is_empty())
	check("no pane stands in a body of the hall (%d overlaps)"%met.size(),met.is_empty())
