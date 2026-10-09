extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-08-ca-what-a-neighbour-offers/"
var checks:Array=[]
var failures:Array=[]
var maximum_parity_difference:=0.0
func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("CA EXCHANGE ",label," ",ok)
func frames(n:int=3) -> void:
	for i in n:await physics_frame
func difference(a:PackedFloat32Array,b:PackedFloat32Array) -> float:
	if a.size()!=b.size():return INF
	var error:=0.0
	for i in a.size():error=maxf(error,absf(a[i]-b[i]))
	return error
func same(a,b) -> bool:return difference(a.u,b.u)<0.000001 and difference(a.v,b.v)<0.000001
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var Model=load(OUT+"printed/field.gd")
	var model=Model.new()
	check("1024 addresses each hold U and V; central 36 begin seeded",model.u.size()==1024 and model.v.size()==1024 and model.v.count(.25)==36 and model.u.count(1.0)==988)
	check("Periodic index wraps negatives and positive overflow",model.index(-1,0)==31 and model.index(32,0)==0 and model.index(0,-1)==992)
	var uniform:=PackedFloat32Array();uniform.resize(1024);uniform.fill(.25)
	check("Uniform neighbourhood contributes zero including at corner",model.laplacian(uniform,0,0)==0 and model.laplacian(uniform,15,15)==0)
	uniform[model.index(31,0)]=.75
	check("Axial difference crosses edge; diagonal does not contribute",is_equal_approx(model.laplacian(uniform,0,0),.5) and model.laplacian(uniform,0,1)==0)
	var sum:=0.0
	for y in 32:
		for x in 32:sum+=model.laplacian(uniform,x,y)
	check("Periodic difference sum cancels before reaction or clamps",absf(sum)<.000001)
	var old_u:PackedFloat32Array=model.u;var old_v:PackedFloat32Array=model.v
	model.step()
	check("First W is U .92 V .02",is_equal_approx(model.u[492],.92) and is_equal_approx(model.v[492],.02))
	check("Step retains previous arrays and advances once",old_u[492]==1 and old_v[492]==0 and model.ticks==1)
	model.exchange=false;model.reset();model.step()
	check("Exchange off keeps untouched W at U 1 V 0",model.u[492]==1 and model.v[492]==0)
	check("Exchange off still reacts inside original square",model.u[model.index(15,15)]!=.5 and model.v[model.index(15,15)]!=.25)
	check("Supplied reaction and exchange clamp both answers",model.next_pair(2,-1,0,0)==Vector2(0,1))
	var reverse=Model.new();var answer=Model.new();answer.step()
	var nu:=PackedFloat32Array();var nv:=PackedFloat32Array();nu.resize(1024);nv.resize(1024)
	for y in range(31,-1,-1):
		for x in range(31,-1,-1):
			var i:int=reverse.index(x,y);var pair:Vector2=reverse.next_pair(reverse.u[i],reverse.v[i],reverse.laplacian(reverse.u,x,y),reverse.laplacian(reverse.v,x,y));nu[i]=pair.x;nv[i]=pair.y
	check("Reverse evaluation of snapshot gives same complete answer",difference(nu,answer.u)==0 and difference(nv,answer.v)==0)
	var Production=load("res://commons/artifacts/rd_artifact/live_field.gd")
	var parity:=true;var bounded:=true
	for enabled in [true,false]:
		model=Model.new();model.exchange=enabled;var production=Production.new();production.exchange=enabled
		for tick in 2400:
			model.step();production.step()
			maximum_parity_difference=maxf(maximum_parity_difference,maxf(difference(model.u,production.u),difference(model.v,production.v)))
		parity=parity and same(model,production)
		for i in 1024:bounded=bounded and model.u[i]>=0 and model.u[i]<=1 and model.v[i]>=0 and model.v[i]<=1
		if not enabled:check("Without exchange initial seed has nearly faded at limit",model.v[model.index(15,15)]<.001)
	check("Both schedules match installed field through 2400 ticks each",parity and maximum_parity_difference<.000001)
	check("Complete fields remain bounded at limit",bounded)
	model=Model.new();model.seed_at(Vector2i.ZERO)
	check("Corner intervention replaces exactly nine extra sites and keeps time",model.v.count(.25)==45 and model.v[1023]==.25 and model.v[1]==.25 and model.ticks==0)
	model.seed_at(Vector2i.ZERO)
	check("Repeated seed replaces values instead of adding",model.v.count(.25)==45 and model.v[0]==.25)
	var fault=load(OUT+"variants/no-subtraction/field.gd").new()
	check("Missing centre subtraction fails uniform-field prediction",fault.laplacian(uniform,15,15)!=0)
	fault=load(OUT+"variants/in-place/field.gd").new();fault.step()
	check("Writing into the read state fails snapshot answer",not same(fault,answer))
	var study=load(OUT+"printed/exchange.gd").new();world.add_child(study);await frames()
	check("Printed study creates two independent fields, point and visible reading",study.point!=null and study.reading.text.contains("TICK 0") and not is_same(study.left,study.right) and study.textures.size()==2)
	study.left.seed_at(Vector2i(4,4));check("Changing A cannot edit B",study.left.v[132]==.25 and study.right.v[132]==0);study.reset()
	var saved:PackedFloat32Array=study.left.v;study.advance(1)
	check("One clock advances both once with different W",study.left.ticks==1 and study.right.ticks==1 and study.left.v[492]>study.right.v[492] and saved[492]==0)
	var before:PackedFloat32Array=study.left.v;var previous:PackedByteArray=study.textures[0].get_image().get_data();study.show_u=true;study.paint()
	check("VIEW changes pixels while preserving state and clock",difference(before,study.left.v)==0 and study.left.ticks==1 and previous!=study.textures[0].get_image().get_data())
	var mapping:=true
	for side in 2:
		var field=study.left if side==0 else study.right;var image:Image=study.textures[side].get_image()
		for y in 32:
			for x in 32:
				var actual:=image.get_pixel(x,y);var wanted:Color=study.tint(field.u[y*32+x]);mapping=mapping and absf(actual.r-wanted.r)<.004 and absf(actual.g-wanted.g)<.004 and absf(actual.b-wanted.b)<.004
	check("All displayed U pixels map their corresponding addresses",mapping)
	var sharing:=true
	for texture in study.textures:
		var count:=0
		for child in study.get_children():
			if child is MeshInstance3D and child.material_override.albedo_texture==texture:count+=1
		sharing=sharing and count==2
	check("Each table and upright panel share one texture",sharing)
	var space=world.get_world_3d().direct_space_state
	var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(.85,1.2,.5),Vector3(.85,.8,.5),1))
	check("Native table support stays at one metre",not hit.is_empty() and absf(hit.position.y-1)<.001)
	study.change_exchange();study.advance(100)
	check("Enabling B exchange resets matched histories and makes fields equal",study.right.exchange and study.left.ticks==100 and same(study.left,study.right) and study.show_u)
	var transfer=load(OUT+"variants/edge-seed/exchange.gd").new();world.add_child(transfer)
	check("Printed independent corner edit seeds both identical nine-site patches",transfer.left.v.count(.25)==45 and same(transfer.left,transfer.right))
	transfer.advance(1)
	check("Corner edit first V reaches adjacent site only through exchange",transfer.left.v[transfer.left.index(2,0)]>0 and transfer.right.v[transfer.right.index(2,0)]==0)
	transfer.queue_free();await frames()
	study.change_exchange();study.position=Vector3(3,0,-2);study.rotation.y=.8
	study.plant();check("Unheld point cannot plant",study.injections==0)
	var origin:=XROrigin3D.new();world.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=study.point.global_position;study.point.pick_up(hand);await frames()
	controller.global_position=study.to_global(Vector3(.85+(4.5-16)*.04,1.06,.5+(5.5-16)*.04));await frames(6)
	check("Held world position maps to local address despite rotated study",study.point.held() and study.target_site()==Vector2i(4,5))
	check("Moving without triggering leaves fields and clock unchanged",study.injections==0 and study.left.ticks==0 and study.left.v.count(.25)==36)
	study.point.action();await frames()
	check("Held trigger replaces same selected patch in both, without advancing",study.injections==1 and study.left.v[164]==.25 and same(study.left,study.right) and study.left.ticks==0)
	controller.global_position=study.to_global(Vector3(-.85+(8.5-16)*.04,1.06,.5+(6.5-16)*.04));await frames(6)
	study.point.action();await frames()
	check("Other table selects matching address in both fields",study.target_site()==Vector2i(8,6) and study.injections==2 and study.left.v[200]==.25 and study.right.v[200]==.25)
	controller.global_position+=Vector3.UP;await frames(6);study.point.action()
	check("Point above table range cannot plant",study.injections==2)
	study.point.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames()
	check("Release parks same sphere and withdraws input",not study.point.held() and study.point.position.is_equal_approx(Vector3(0,1.12,-.35)))
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_ENTER;study._unhandled_key_input(key);key.echo=true;study._unhandled_key_input(key)
	check("Keyboard step ignores repeated key event",study.left.ticks==1)
	key.echo=false;key.keycode=KEY_SPACE;study._unhandled_key_input(key);check("Space advances one hundred more updates",study.left.ticks==101)
	key.keycode=KEY_R;study._unhandled_key_input(key);check("Replay restores fields and seeds but preserves comparison and view",study.left.ticks==0 and study.injections==0 and not study.right.exchange and study.show_u and same(study.left,study.right))
	study.left.ticks=2399;study.right.ticks=2399;study.advance(100);before=study.left.v;study.advance(1)
	check("Both clocks stop at 2400 without an extra update",study.left.ticks==2400 and study.right.ticks==2400 and before==study.left.v)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"maximum_parity_difference":maximum_parity_difference,"scope":"Exact printed files; 4800 solver comparisons; native display/collision; supplied XRTools poses; corner transfer; two intentional faults. No physical headset or independent learner."},"  "))
	world.queue_free();await frames();quit(0 if failures.is_empty() else 1)
