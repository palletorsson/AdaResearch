extends "res://tools/probes/void_charger_probe.gd"
## Real locomotion, input, contact and recharge. Saved museum state is isolated.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1); return
	for use_xr in [false,true]:
		await start(use_xr)
		var mode := "XR" if use_xr else "desktop"
		var museum_health: float=root.get_node("GameManager").get_health()
		print("[charge initial] ",mode," charge=",game.charge.get_charge()," cause=",game.charge.last_cause)
		check(mode+": starts fully charged with one resource",game.charge==game.health and is_equal_approx(game.charge.get_charge(),100))
		check(mode+": charge readout replaces health",game.charge_display.text.begins_with("CHARGE"))
		check(mode+": plain body is present",game.has_node("CareBody/PlainTorso/Chest"))
		check(mode+": first-person view excludes head and neck",(game.camera.cull_mask & game.get_node("CareBody/PlainTorso/Head").layers)==0 and (game.camera.cull_mask & game.get_node("CareBody/PlainTorso/Neck").layers)==0)
		game.place_player(Vector3(-4,0.06,4.5)); await frames(45)
		game.charge.set_charge(100)
		await frames(90)
		check(mode+": idle does not drain",is_equal_approx(game.charge.get_charge(),100))
		var travelled: float=game.charge.metres_travelled
		var walk_start: Vector3=game.body.global_position
		axes(Vector2(0,-1)); await frames(60); axes(Vector2.ZERO); await frames(40)
		var distance: float=game.charge.metres_travelled-travelled
		var displacement: Vector3=game.body.global_position-walk_start
		displacement.y=0
		print("[charge walk] ",mode," metres=",distance," charge=",game.charge.get_charge()," cause=",game.charge.last_cause)
		check(mode+": actual walking drains by distance",displacement.length()>1.0 and absf(distance-displacement.length())<0.05 and absf(game.charge.get_charge()-(100-displacement.length()*0.1))<0.01)
		var before: float=game.charge.get_charge()
		if use_xr:
			right.set_input("primary",Vector2.RIGHT); await frames(15); right.set_input("primary",Vector2.ZERO)
		else: game.body.rotate_y(PI/4)
		await frames(25)
		check(mode+": turning does not drain",absf(game.charge.get_charge()-before)<0.02)
		game.place_player(Vector3(-4,0.06,4.5)); await frames(30)
		game.charge.set_charge(100)
		await press_jump(); await frames(10); await release_jump()
		check(mode+": takeoff does not charge landing cost early",game.charge.get_charge()>99.9 and not game.body.is_on_floor())
		await frames(100)
		check(mode+": jump landing costs five once",absf(game.charge.get_charge()-95)<0.02 and game.body.is_on_floor())
		await frames(60)
		check(mode+": remaining grounded does not repeat landing cost",absf(game.charge.get_charge()-95)<0.02)
		var junction: Node3D=game.building.content.props["0/roof-live-junction"].get_node("Prefab")
		game.place_player(junction.to_global(Vector3(0,0.06,0.5))); await frames(10)
		check(mode+": real electrical contact discharges twenty",junction.zone.shock_count==1 and absf(game.charge.get_charge()-75)<0.05)
		await frames(40)
		check(mode+": shock has a cooldown",junction.zone.shock_count==1)
		game.place_player(Vector3(-4,0.06,4.5)); await frames(100)
		before=game.charge.get_charge(); await frames(30)
		check(mode+": leaving the electrical contact stops discharge",is_equal_approx(before,game.charge.get_charge()))
		if not use_xr and "--capture" in OS.get_cmdline_user_args():
			await photograph("live-junction.png",junction.to_global(Vector3(1.1,1.7,2.8)),junction.to_global(Vector3(0,1.3,0)))
		await reach_charger()
		game.place_player(charger.to_global(Vector3(0,0.06,1.1))); await frames(35)
		game.charge.set_charge(50)
		await hold(charger.charge_button,true); await frames(90)
		check(mode+": actual charger replenishes the same battery",game.charge.get_charge()>55 and game.charge.get_charge()<85 and charger._readout.title=="BODY CHARGE")
		await hold(charger.charge_button,false)
		before=game.charge.get_charge(); await frames(35)
		check(mode+": releasing stops recharge",absf(game.charge.get_charge()-before)<0.02)
		if not use_xr and "--capture" in OS.get_cmdline_user_args():
			await photograph("charge-station.png",charger.to_global(Vector3(0,1.65,1.6)),charger.to_global(Vector3(0,1.5,0)))
		if use_xr: await wrist_checks()
		var deaths_before: int=game.deaths
		var home: int=game.checkpoint
		game.charge.set_charge(0.01)
		game.charge.travel(1.0)
		check(mode+": empty charge starts shutdown",game.recovering and game.deaths==deaths_before+1 and game.last_death=="Charge depleted")
		await frames(100)
		check(mode+": checkpoint restarts charged",not game.recovering and game.checkpoint==home and is_equal_approx(game.charge.get_charge(),100))
		check(mode+": museum health is untouched",is_equal_approx(root.get_node("GameManager").get_health(),museum_health))
		game.queue_free(); await frames(5)
		if use_xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native desktop and synthetic XR physics/input. BoneAttachment measurements after rendering; physical headset comfort not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func wrist_checks() -> void:
	var origin: Node3D=game.get_node("XROrigin3D")
	var custom: Node=origin.get_node("PlayerCustomization")
	check("XR: ordinary arms, no growing costume",custom.is_active("body_arms") and not custom.is_active("costume") and not origin.has_node("CostumeWardrobe"))
	var arms: Node3D=origin.get_node("PlayerBodyIK")
	var arm: Node3D=arms._right_arm
	var hand: Node3D=origin.get_node("RightHand/XRToolsCollisionHand/RightHand")
	check("XR: original hand scene is retained",hand.scene_file_path=="res://commons/body/hands/right_hand.tscn")
	# Position and orientation are separate: solve to a real wrist while rotating
	# the visible hand. Observe final bones through attachments after modifiers.
	game.place_player(Vector3(-4,0.06,4.5)); await frames(30)
	var pose := Transform3D(Basis.IDENTITY,Vector3(0.3,1.25,-0.35))
	right.set_pose("aim",pose,Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	left.set_pose("aim",Transform3D(Basis.IDENTITY,Vector3(-0.3,1.25,-0.35)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	var elbow := BoneAttachment3D.new()
	elbow.bone_idx=arm._idx_lower
	arm._skeleton.add_child(elbow)
	var wrist := BoneAttachment3D.new()
	wrist.bone_idx=arm._idx_hand
	arm._skeleton.add_child(wrist)
	await frames(65)
	var target: Vector3=arm._wrist_xform().origin
	var elbow_before: Vector3=elbow.global_position
	var lower_before: Basis=elbow.global_basis
	var hand_before: Basis=arm._wrist_xform().basis
	pose.basis=Basis(Vector3.FORWARD,deg_to_rad(40))
	# Counter the grip-to-wrist offset; test rotation at a fixed wrist position.
	for i in range(25):
		right.set_pose("aim",pose,Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(2)
		pose.origin += origin.global_basis.inverse()*(target-arm._wrist_xform().origin)
	await frames(30)
	var angle: float=hand_before.orthonormalized().get_rotation_quaternion().angle_to(arm._wrist_xform().basis.orthonormalized().get_rotation_quaternion())
	check("XR: hand can rotate forty degrees",angle>deg_to_rad(30))
	check("XR: wrist stays joined to the arm",wrist.global_position.distance_to(arm._wrist_xform().origin)<0.065)
	check("XR: elbow is not dragged by wrist roll",elbow.global_position.distance_to(elbow_before)<0.04)
	check("XR: forearm does not copy hand rotation",lower_before.orthonormalized().get_rotation_quaternion().angle_to(elbow.global_basis.orthonormalized().get_rotation_quaternion())<deg_to_rad(12))
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("care-body.png",game.body.global_position+Vector3(1.6,1.5,-2.2),game.body.global_position+Vector3(0,1.0,0))
		await photograph("free-wrist.png",game.camera.global_position+Vector3(0,0.1,0.15),arm._wrist_xform().origin,game.camera.cull_mask)
