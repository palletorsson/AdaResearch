extends SceneTree
var failures: Array[String]=[]
var checks: int=0
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok: failures.append(description)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var ruin=load("res://commons/artifacts/randomness_space/entropy_ruin.tscn").instantiate()
	root.add_child(ruin); ruin.set_process(false)
	check(ruin.pieces.size()==116,"116 retained pieces")
	ruin.restore()
	for i in range(32): ruin.weather_one()
	var first: Array=ruin.history.duplicate()
	check(first.size()==32,"Single steps select unique exposed pieces")
	check(ruin.pieces.size()==116,"No stones deleted")
	var transforms: Array=[]
	for piece in ruin.pieces: transforms.append(piece.node.transform)
	ruin.restore()
	for piece in ruin.pieces:
		check(piece.node.transform.is_equal_approx(piece.home),"Restore recovers piece transform")
	check(ruin.history.is_empty() and not ruin.running,"Restore waits in intact state")
	for i in range(32): ruin.weather_one()
	check(ruin.history==first,"Seed repeats selection order")
	for i in range(116): check(ruin.pieces[i].node.transform.is_equal_approx(transforms[i]),"Seed repeats landing")
	for i in range(100): ruin.weather_one()
	check(ruin.history.size()==84,"Finite loss stops with 32 pieces in their original positions")
	for stack in ruin.stacks: check(stack.size()==2,"Two foundation courses retained")
	for piece in ruin.pieces:
		if not piece.fallen: continue
		var box: AABB=piece.node.transform*piece.node.get_aabb()
		check(box.position.x>=-3.01 and box.end.x<=3.01 and box.position.z>=-1.36 and box.end.z<=1.36 and box.position.y>=0.079,"Rubble stays in bed above floor")
	ruin.restore(); ruin.running=true; ruin.weather_one()
	var falling=ruin.pieces[ruin.history[0]]
	check(falling.body.collision_layer==0,"Moving stone collider disabled")
	ruin.running=false; var pos: Vector3=falling.node.position; ruin._process(0.1)
	check(falling.node.position==pos,"Pause freezes descent")
	for i in range(9): ruin._animate(0.1)
	check(falling.body.collision_layer==1 and falling.age<0,"Landed stone regains collider")
	ruin.restore(); ruin.running=true
	for i in range(800): ruin._process(0.1)
	check(ruin.history.size()==84 and not ruin.running,"Automatic run completes all eligible pieces")
	for piece in ruin.pieces: check(piece.age<0 and piece.body.collision_layer==1,"Automatic run leaves no frozen airborne piece")
	print("ENTROPY RUIN: ",checks," checks; failures=",failures)
	var file:=FileAccess.open("res://doc/space/entropy-ruin-2026-09-16/unit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures})); file.close()
	quit(0 if failures.is_empty() else 1)
