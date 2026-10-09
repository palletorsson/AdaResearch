extends SceneTree
var failures: Array=[]
var checks: Array=[]
var measurements: Dictionary={}
var e: Node3D
var world: Node3D
func _initialize() -> void:run.call_deferred()
func check(message: String,good: bool) -> void:
	checks.append(message)
	if not good:failures.append(message);push_error(message)
func wait(t: float) -> void:await create_timer(t).timeout
func run() -> void:
	await process_frame
	world=Node3D.new();root.add_child(world)
	var kinds=["mass","tower","gravity","trolley","puzzle","bowling","recoil","friction","liquids","springs","swings","torque","constraints","magnet","vortex","mutual","support","flight"]
	if not OS.get_cmdline_user_args().is_empty():kinds=Array(OS.get_cmdline_user_args())
	for kind in kinds:
		e=load("res://commons/artifacts/force_play/encounter.gd").new();e.kind=kind;world.add_child(e);await wait(0.1)
		# This regression exercises the original full experiments. The separate
		# forces_lesson_chain probe checks the new focused starting states.
		if kind in ["springs","mutual","vortex"]:
			e.action("PAIR / FIVE" if kind=="mutual" else "ONE / MANY");await wait(0.1)
		check(kind+": constructed with finite bodies and a reset",e.bodies.size()>0 and e.buttons.has("RESET"))
		await exercise(kind)
		check(kind+": finite motion",e.bodies.all(func(b):return b.position.is_finite() and b.linear_velocity.is_finite()))
		for b in e.bodies:
			if b.has_meta("capability_desktop_held"):b.remove_meta("capability_desktop_held")
		check(kind+": reset restores original transforms",e.reset() and e.bodies[0].transform.is_equal_approx(e.homes[0]))
		await physics_frame;await physics_frame;await process_frame
		check(kind+": reset survives the next physics frames",e.bodies[0].position.distance_to(e.homes[0].origin)<0.15)
		if kind in ["mutual","vortex"]:check(kind+": reset retains the specified orbital launch",e.bodies[0].linear_velocity.length()>1)
		e.queue_free();await process_frame;await physics_frame
	var backend=str(ProjectSettings.get_setting("physics/3d/physics_engine"))
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements,"physics_engine":backend,"physics_server":PhysicsServer3D.get_class(),"godot_version":Engine.get_version_info().string,"scope":"Real "+backend+" bodies, contact, joints and force integration. Simulated hand/receiver inputs; no headset claim."}
	FileAccess.open("res://ada_run/force_play_models.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("FORCE PLAY: ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)

func exercise(kind: String) -> void:
	match kind:
		"mass":
			for b in e.bodies:check("mass: mesh height, collider diameter and radius agree",is_equal_approx(b.sphere.height,2*b.sphere.radius) and is_equal_approx(b.get_child(1).shape.radius,b.sphere.radius))
			e.buttons["PUSH 1 s"].pressed.emit();await wait(0.75)
			var a=e.bodies[0].linear_velocity.z;var b=e.bodies[1].linear_velocity.z;var c=e.bodies[2].linear_velocity.z
			measurements.mass_velocities=[a,b,c]
			check("mass: equal force gives inverse-mass acceleration",absf(a/b-2)<0.1 and absf(b/c-2)<0.1)
			await wait(0.4);var speed=e.bodies[0].linear_velocity.z;await wait(0.2)
			check("mass: coasting continues after force ends",e.pulse==0 and absf(e.bodies[0].linear_velocity.z-speed)<0.03)
		"tower":
			await wait(2);var top=e.bodies.back();var height=top.position.y
			check("tower: tall brick stack initially supported",height>5.2)
			e.members.key.freeze=true;await physics_frame
			# Pull over one second, like the held object. A one-frame four-metre
			# teleport invents a 240 m/s contact velocity and can fling the stack.
			for step in range(60):
				e.members.key.position.x=4.0*(step+1)/60.0;await physics_frame
			await wait(3)
			check("tower: removed key stays outside the stack",e.members.key.position.x>3)
			measurements.tower_top=[height,top.position.y]
			measurements.tower_recovered=e.recovered
			check("tower: removing the bottom brick causes real collapse",top.position.y<height-2)
			check("tower: collapse stays in bounds without recovery",e.recovered==0)
		"gravity":
			var height=e.members.released[2].position.y;e.action("RELEASE");await wait(1)
			check("gravity: released cargo falls",e.members.released[2].position.y<height-1)
			check("gravity: actual hinge lets trapdoor turn",e.members.released[1].rotation.length()>0.2)
		"trolley":
			var start=e.members.cart.position;e.members.cart.apply_central_impulse(Vector3(0,0,8));await wait(0.7)
			check("trolley: a physical push moves the carrier",e.members.cart.position.distance_to(start)>0.4)
		"puzzle":
			check("puzzle: three distinct masses",e.bodies[0].mass<e.bodies[1].mass and e.bodies[1].mass<e.bodies[2].mass)
		"bowling":
			check("bowling: ten actual rigid pins",e.members.pins.size()==10)
			e.action("ROLL");await wait(5)
			var fallen=0
			for pin in e.members.pins:
				if pin.global_basis.y.dot(Vector3.UP)<0.7:fallen+=1
			measurements.bowling_fallen=fallen
			measurements.bowling_ball=[str(e.members.ball.position),str(e.members.ball.linear_velocity)]
			measurements.pin_positions=e.members.pins.map(func(b):return [str(b.position),str(b.rotation)])
			check("bowling: rolling sphere hits and topples pins",fallen>0)
		"recoil":
			e.action("FIRE");await wait(0.15)
			var p=e.members.carts[0].mass*e.members.carts[0].linear_velocity.z+e.members.balls[0].mass*e.members.balls[0].linear_velocity.z
			check("recoil: equal opposite impulses conserve pair momentum",absf(p)<0.05)
			check("recoil: brace stops cart, free cart recoils",e.members.carts[0].linear_velocity.z< -1 and e.members.carts[1].linear_velocity.length()<0.01)
		"friction":
			e.action("RELEASE");await wait(3)
			measurements.friction=e.members.runners.map(func(b):return [b.position.z,b.angular_velocity.length()])
			check("friction: smooth cube travels farther than rough cube",e.members.runners[0].position.z>e.members.runners[2].position.z+0.5)
			check("friction: sphere rolls",e.members.runners[3].angular_velocity.length()>0.5)
			check("friction: paths retain moving samples",e.trails.size()>=4)
		"liquids":
			e.action("DROP");await wait(0.8)
			var speeds=e.bodies.map(func(b):return absf(b.linear_velocity.y));measurements.liquid_speeds=speeds
			check("liquids: greater drag slows the same falling point",speeds[0]>speeds[1] and speeds[1]>speeds[2])
			var player=CharacterBody3D.new();world.add_child(player)
			var outputs: Array=[]
			for x in [-7.2,0,7.2]:player.position=Vector3(x,1,0);e._carry.clear();outputs.append(e.carry_velocity(player,0.1,Vector3(3,0,0)).length())
			check("liquids: visitor crosses the same resistance regions",outputs[0]>outputs[1] and outputs[1]>outputs[2]);player.queue_free()
		"springs":
			await wait(0.5);e.bodies[0].apply_central_impulse(Vector3(3,0,2));await wait(1.2)
			check("springs: disturbing one point moves its neighbour",e.bodies[1].linear_velocity.length()>0.1)
			check("springs: seven hanging points with six coupling springs",e.bodies.size()==7 and e.links.size()==13)
		"swings":
			e.action("NUDGE");await wait(3.5)
			var low=e.bodies[0].angular_velocity.length()+absf(e.bodies[0].rotation.x);var high=e.bodies[4].angular_velocity.length()+absf(e.bodies[4].rotation.x)
			measurements.swing_remaining=[low,high]
			check("swings: strong damping leaves less movement",low>high*1.4)
			check("swings: each seat remains hinged",e.joints.size()==6)
		"torque":
			var gate=e.bodies[0];var handle=e.grips[0];var anchor=e.joints[0].global_position
			handle.set_meta("capability_desktop_held",true);handle.freeze=true;handle.position.z+=0.6;await wait(0.7)
			check("torque: pulling grip turns a constrained gate",absf(gate.rotation.y)>0.1)
			check("torque: hinge anchor stays attached",gate.to_global(Vector3(-1.64,0,0)).distance_to(anchor)<0.25)
			handle.remove_meta("capability_desktop_held")
		"constraints":
			check("constraints: basket, chain, plank and arm use real joints",e.joints.size()==8)
			e.grips.back().action_pressed.emit(null);await wait(0.4)
			check("constraints: held trigger closes physical claw",not e.members.jaw_open and absf(e.members.jaws[0][1].position.z)<0.33)
		"magnet":
			e.action("MAGNET 3 s");await wait(1)
			check("magnet: cargo rises under attraction",e.bodies[0].position.y>0.8)
			await wait(2.15);check("magnet: automatically releases after three seconds",e.magnet_remaining==0 and e.magnet_releases==1)
			var vy=e.bodies[0].linear_velocity.y;await wait(0.2)
			check("magnet: gravity acts after release",e.bodies[0].linear_velocity.y<vy)
			check("magnet: point gun retains twelve eligible prefabs",e.members.gun.candidates.size()==12)
			check("magnet: gravity gun does not also thrust the player",not e.members.gun.is_in_group("ada_thrust_points"))
			await gun_input()
		"vortex":
			var start=e.bodies[0].position;await wait(1)
			check("vortex: tangential field bends cargo paths",e.bodies[0].position.z>start.z+0.5)
			check("vortex: populated solid vector field",e.field_arrows.size()==49 and e.bodies.size()==18)
		"mutual":
			e.update_mutual();var sum=Vector3.ZERO
			for f in e.last_forces:sum+=f
			check("mutual: pair forces balance without visitor",sum.length()<0.001)
			var source=Node3D.new();source.position=Vector3(2,0,1);world.add_child(source);e.visitor_override=source;e.update_mutual();sum=Vector3.ZERO
			for f in e.last_forces:sum+=f
			check("mutual: visitor becomes an additional source",sum.length()>0.1);source.queue_free();e.visitor_override=null
			await wait(3);check("mutual: orbits retain spread instead of centre pile",e.bodies.any(func(b):return Vector2(b.position.x,b.position.z).length()>3))
		"support":
			await wait(8);var height=e.members.table.position.y
			check("support: table initially supported",height>1.2)
			var top=e.members.load.back();var load_height=top.position.y
			measurements.support_before=[load_height,top.global_basis.y.dot(Vector3.UP)]
			check("support: load remains stacked until the visitor acts",load_height>3.0 and top.global_basis.y.dot(Vector3.UP)>0.95)
			e.members.leg.freeze=true;await physics_frame;e.members.leg.position.x+=4;await wait(4)
			measurements.support=[height,e.members.table.position.y,e.members.table.rotation.length()]
			check("support: moving the leg overturns the loaded table",e.members.table.position.y<height-0.3 or e.members.table.rotation.length()>0.4)
			check("support: the load falls after the leg moves",top.position.y<load_height-1)
		"flight":
			check("flight: two inherited thrust points and four gates",e.flight_points.size()==2 and e.members.gates.size()==4)
			var player=CharacterBody3D.new();world.add_child(player);player.position=Vector3(0,0,-10)
			var v=e.carry_velocity(player,0.1,Vector3.ZERO)
			check("flight: boarding assigns the actual receiver",e.members.get("rider",0)==player.get_instance_id())
			check("flight: unpowered rider still experiences gravity",v.y<0)
			var eye=Camera3D.new();player.add_child(eye);eye.position.y=1.5
			var pointer=load("res://commons/scenes/em/em_desktop_pointer.gd").new();pointer.cam=eye;player.add_child(pointer);pointer.set_process(false);pointer.set_physics_process(false)
			pointer._grab_held(e.flight_points[0]);eye.rotation.x=PI/2;pointer._try_held_action(true)
			check("flight: real grab connects thrust to this rider",e.flight_points[0].receiver()==player and e.flight_points[0].acceleration().y>10)
			v=e.carry_velocity(player,0.25,Vector3.ZERO);player.velocity=v;e.record_carry(player)
			check("flight: trigger overcomes gravity",v.y>0.2)
			pointer._try_held_action(false);var coast=e.carry_velocity(player,0.01,v)
			check("flight: release removes thrust but retains upward motion",coast.y>0 and coast.y<v.y)
			check("flight: reset refuses to steal a held point",not e.reset())
			pointer._drop_held();check("flight: dropping point ends thrust",not e.flight_points[0].firing and not e.flight_points[0].held())
			var carried=load("res://commons/artifacts/force_capability_lab/force_point.gd").new();world.add_child(carried)
			pointer._grab_held(carried);pointer._try_held_action(true);e._carry.clear()
			check("flight: a point carried from the earlier court also works",e.carry_velocity(player,0.25,Vector3.ZERO).y>0.2)
			pointer._drop_held();carried.queue_free()
			player.queue_free()

func gun_input() -> void:
	e.reset();await wait(0.05)
	var player=CharacterBody3D.new();world.add_child(player);player.position=Vector3(0,0,-4)
	var eye=Camera3D.new();player.add_child(eye);eye.position.y=1.5;eye.rotation.y=PI
	var pointer=load("res://commons/scenes/em/em_desktop_pointer.gd").new();pointer.cam=eye;player.add_child(pointer);pointer.set_process(false);pointer.set_physics_process(false)
	for i in e.members.gun.candidates.size():
		var body=e.members.gun.candidates[i];body.freeze=true;body.position=Vector3(4,0.5+i*0.6,3)
	var target=e.members.gun.candidates[0];target.position=Vector3(0,1.5,0);target.gravity_scale=0;target.freeze=false
	pointer._grab_held(e.members.gun);pointer._try_held_action(true);await wait(0.3)
	check("gravity gun: held trigger acquires the aimed prefab",e.members.gun.caught==target)
	check("gravity gun: spring pulls target without freezing it",not target.freeze and target.position.z< -0.1)
	pointer._try_held_action(false);await wait(0.05)
	check("gravity gun: trigger release clears target",e.members.gun.caught==null and not e.members.gun.beam.visible)
	pointer._drop_held();player.queue_free()
