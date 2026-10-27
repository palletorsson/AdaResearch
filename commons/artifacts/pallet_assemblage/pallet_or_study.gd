extends "res://commons/artifacts/pallet_assemblage/pallet_logic_study.gd"
## Parallel material routes. Each real ball can independently strike the same cone.
## No input flags choose a route, add a floor, steer a ball or signal success.
const TURN := .11
const GAP := -.4
var ball_y: XRToolsPickable
var lost: Array[XRToolsPickable] = []

func line_y(s: float) -> float:return board_top+.189-(.078/1.15)*s
func ready_text() -> String:return "OR / EITHER SUPPORT CARRIES A BALL TO TRUE"
func path_point(s: float,side: float) -> Vector3:
	return Vector3(s*cos(TURN),line_y(s),side*(.16-s*sin(TURN)))
func path_basis(side: float) -> Basis:
	return Basis(Vector3.UP,side*TURN)*Basis(Vector3.BACK,-atan(.078/1.15))

func build(host: Node3D) -> void:
	super.build(host)
	# Two staggered starting places avoid a head-on merge while both release together.
	var start := path_point(-1.43,-1)+Vector3(0,.09,0)
	var release := work.get_node("BallAndRelease") as Node3D
	release.position = start-ball_rest
	remember(release,Vector3(-1.08,.25,-.07),Vector3(.15,.4,.14),"X / white gravity ball / release from above")
	ball_y = make_ball("BallAndReleaseY",path_point(-1.60,1)+Vector3(0,.09,0))
	for carrier in [ball,ball_y]:carrier.collision_mask = 1|BALL_LAYER
	for i in range(4):
		var side := -1.0 if i<2 else 1.0
		var s := -1.06 if i%2==0 else .26
		var rail: XRToolsPickable = ramp_pieces[i]
		rail.position = path_point(s,side)+path_basis(side)*Vector3(0,.022,side*.1225)
		rail.basis = path_basis(side)
		remember(rail,Vector3(-.6,-.011,-.0725),Vector3(1.2,.022,.145),"Outer route edge / standard 1.2 m timber")
		PhysicsServer3D.body_set_state(rail.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,rail.global_transform)
	var controls := work.get_node("LogicControls") as Node3D
	for child in controls.get_children():
		if child is Label3D and child!=work.status:child.free()
	for side in [-1.0,1.0]:
		var label := Label3D.new();label.text = "X" if side<0 else "Y";label.font_size = 36;label.pixel_size = .001;label.outline_size = 0;label.modulate = Color("302b27")
		label.position = path_point(GAP,side)-controls.position+Vector3(-.03,-.07,side*.12);label.rotation.x = -PI/2;controls.add_child(label)
	work.set_meta("void_preview_kind","OR / two visible gravity lanes, one removable timber support per lane, two white balls released together, one shared inverted TRUE cone. Original timber dimensions; independently editable parts.")

func stage_timber() -> void:
	for side in [-1.0,1.0]:
		var offset := 0 if side<0 else 2
		for i in range(2):
			var s := -1.06 if i==0 else .26
			pose("deck_"+str(offset+i+1),path_point(s,side),path_basis(side).get_euler())
		var id := "block_1_1" if side<0 else "block_3_1"
		pose(id,path_point(GAP,side)+path_basis(side)*Vector3(0,.011-.039,0),path_basis(side).get_euler())
		work.part_defaults[id].label = ("X" if side<0 else "Y")+" / OR lane support / present = 1"
		# Inner edges end at the input. The two lanes open towards the shared landing.
		pose("bottom_1" if side<0 else "bottom_2",path_point(-1.06,side)+path_basis(side)*Vector3(0,.022,-side*.10),path_basis(side).get_euler())
	pose("deck_5",Vector3(.72,line_y(.72),0),Vector3(0,0,-atan(.078/1.15)))
	pose("bottom_3",Vector3(GAP+.16,board_top+.05,0),Vector3(PI/2,PI/2,0))
	for i in range(3):
		var x := (i-1)*1.15
		pose("bearer_"+str(i+1),Vector3(x,line_y(x)-.022,0),Vector3(0,0,-atan(.078/1.15)))
	var ids := ["block_1_2","block_1_3","block_2_1","block_2_2","block_2_3","block_3_2"]
	for i in range(6):
		var x := -1.15 if i<3 else 0.0 if i<5 else 1.15
		var level := i if i<3 else i-3 if i<5 else 0
		pose(ids[i],Vector3(x,board_top+.039+level*.078,0))
	pose("block_3_3",Vector3(1.85,board_top+.039,-.42))

func carried_parts() -> Array:return super.carried_parts()+[ball_y]
func reset_ball() -> void:
	if is_instance_valid(ball_y) and ball_y.is_picked_up():work.status.text = "RELEASE BOTH BALLS BEFORE RESET";return
	super.reset_ball();lost.clear()
	if is_instance_valid(ball_y):
		ball_y.freeze = true;ball_y.position = ball_rest;ball_y.linear_velocity = Vector3.ZERO;ball_y.angular_velocity = Vector3.ZERO
		PhysicsServer3D.body_set_state(ball_y.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,ball_y.global_transform)

func begin_run() -> void:
	super.begin_run();lost.clear()
func release_ball() -> void:
	if not is_instance_valid(ball_y):return
	if ball.is_picked_up() or ball_y.is_picked_up():work.status.text = "RELEASE BOTH BALLS BEFORE STARTING";return
	if not ball.freeze or not ball_y.freeze:return
	begin_run()
	for carrier in [ball,ball_y]:carrier.freeze = false;carrier.sleeping = false

func contact_from(body: Node3D,carrier: XRToolsPickable) -> void:
	if not running:return
	if body==output:
		outcome = 1;running = false;passage_times["TRUE"] = elapsed;work.status.text = "TRUE / "+("X" if carrier==ball else "Y")+" BALL HIT THE CONE"
	elif body==work.pieces.block_1_1 or body==work.pieces.block_3_1:
		var id := "X" if body==work.pieces.block_1_1 else "Y"
		if not hit_inputs.has(id):hit_inputs.append(id);passage_times[id] = elapsed
	elif body==work.get_node("Board") or body==work.get_node("Board2"):
		lose(carrier)
func lose(carrier: XRToolsPickable) -> void:
	if lost.has(carrier):return
	lost.append(carrier);passage_times["LOSS_X" if carrier==ball else "LOSS_Y"] = elapsed
	if lost.size()==2:outcome = 0;running = false;work.status.text = "0 / BOTH BALLS FELL THROUGH THE GAPS"
func _physics_process(delta: float) -> void:
	if not running:return
	elapsed += delta
	for carrier in [ball,ball_y]:
		if not is_instance_valid(carrier):continue
		if carrier.global_position.y<work.global_position.y-.1:lose(carrier)
	if elapsed>14:running = false;outcome = 0;work.status.text = "NO ARRIVAL / RESET THE BALLS"
