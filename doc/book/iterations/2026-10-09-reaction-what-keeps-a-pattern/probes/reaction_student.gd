extends SceneTree
const OUT:="res://doc/book/iterations/2026-10-09-reaction-what-keeps-a-pattern/"
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("REACTION ","PASS " if ok else "FAIL ",title)
func ticks()->void:await physics_frame;await process_frame
func press(key:Key,echo:bool=false)->void:
	var event:=InputEventKey.new();event.keycode=key;event.pressed=true;event.echo=echo;Input.parse_input_event(event);await ticks()
func difference(a:PackedFloat32Array,b:PackedFloat32Array)->float:
	var maximum:=0.0
	for i in a.size():maximum=maxf(maximum,absf(a[i]-b[i]))
	return maximum
func model(folder:String):return load(OUT+folder+"/field.gd").new()
func fixture(folder:String):
	var n=load(OUT+folder+"/study.tscn").instantiate();n.position=Vector3(3,.4,-2);n.rotation.y=.7;root.add_child(n);return n
func reverse_answer(f)->Array:
	var a:=PackedFloat32Array();var b:=PackedFloat32Array();a.resize(1024);b.resize(1024)
	for y in range(31,-1,-1):
		for x in range(31,-1,-1):
			var i:int=f.index(x,y);var answer:Vector2=f.next_pair(f.u[i],f.v[i],f.laplacian(f.u,x,y),f.laplacian(f.v,x,y))
			a[i]=answer.x;b[i]=answer.y
	return [a,b]
func faults(f)->Array:
	var out:Array=[]
	if not f.next_pair(.5,.25,0,0).is_equal_approx(Vector2(.48725,.257)):out.append("local balance")
	var expected:Array=reverse_answer(f);f.step()
	if difference(f.u,expected[0])>0.000001 or difference(f.v,expected[1])>0.000001:out.append("simultaneous update")
	return out
func run()->void:
	var f=model("printed")
	check("Complete field owns two 32 by 32 arrays",f.u.size()==1024 and f.v.size()==1024)
	var seeds:=0
	for x in f.v:if x==.25:seeds+=1
	check("Starting square has 36 seeded addresses",seeds==36 and f.ticks==0)
	check("Indices wrap across each edge",f.index(-1,0)==31 and f.index(0,-1)==992 and f.index(32,32)==0)
	var uniform:=PackedFloat32Array();uniform.resize(1024);uniform.fill(.5)
	check("Uniform four-neighbour field contributes zero exchange",is_zero_approx(f.laplacian(uniform,0,0)))
	uniform.fill(0);uniform[31]=1
	check("Wrapped neighbour contributes across left boundary",is_equal_approx(f.laplacian(uniform,0,0),1.0))
	check("Local reaction balances the printed one-step prediction",f.next_pair(.5,.25,0,0).is_equal_approx(Vector2(.48725,.257)))
	check("Uniform U1 V0 is a fixed point",f.next_pair(1,0,0,0)==Vector2(1,0))
	f.local_terms=false
	check("Disabling local terms retains the stated diffusion",f.next_pair(.5,.25,1,-1).is_equal_approx(Vector2(.66,.17)))
	f.local_terms=true
	check("Complete output stays bounded",f.next_pair(.9,.9,100,-100)==Vector2(1,0))
	check("Reverse traversal agrees with actual synchronous step",faults(f).is_empty())
	f=model("printed");var ca=load("res://doc/book/studies/cellular-automata-through-the-hands/CA_SoftRules/field.gd").new()
	for i in 100:f.step();ca.step()
	observations.ca_max_difference=maxf(difference(f.u,ca.u),difference(f.v,ca.v))
	check("Opened local rule retains CA model behaviour at 100 steps",observations.ca_max_difference<0.000002)
	var study=fixture("printed");await ticks()
	check("Printed scene creates both displays and inherited point",study.textures.size()==2 and study.point!=null and not study.reading.text.is_empty())
	check("Both copies begin identically, only local-term switch differs",study.left.u==study.right.u and study.left.v==study.right.v and study.left.exchange and study.right.exchange and study.left.local_terms and not study.right.local_terms)
	await press(KEY_ENTER)
	var w:int=study.left.index(15,15)
	check("Actual STEP produces predicted A values at W",is_equal_approx(study.left.u[w],.48725) and is_equal_approx(study.left.v[w],.257) and study.left.ticks==1)
	check("B first step is unchanged inside but changes at the edge",is_equal_approx(study.right.u[w],.5) and is_equal_approx(study.right.v[w],.25) and study.right.v[study.right.index(12,15)]>0)
	await press(KEY_ENTER,true);check("Keyboard echo does not advance time",study.left.ticks==1)
	await press(KEY_SPACE);check("Actual batch advances both by exactly 100",study.left.ticks==101 and study.right.ticks==101)
	var old_u:PackedFloat32Array=study.left.u.duplicate();var old_v:PackedFloat32Array=study.left.v.duplicate()
	await press(KEY_V);check("View switch leaves concentrations and clock unchanged",study.show_u and study.left.u==old_u and study.left.v==old_v and study.left.ticks==101)
	var image:Image=study.textures[0].get_image();var want:Color=study.tint(study.left.u[w]);var got:Color=image.get_pixel(15,15)
	check("Texture shows the selected stored concentration",absf(want.r-got.r)<.005 and absf(want.g-got.g)<.005 and absf(want.b-got.b)<.005)
	await press(KEY_C);check("Enabling B restores a matched beginning",study.right.local_terms and study.left.ticks==0 and study.right.ticks==0 and study.left.u==study.right.u and study.left.v==study.right.v)
	study.advance(100);check("Matching complete rules produce identical equal-step fields",study.left.u==study.right.u and study.left.v==study.right.v)
	await press(KEY_R);check("Replay restores arrays and keeps comparison choice",study.left.ticks==0 and study.right.local_terms and is_equal_approx(study.left.v[w],.25))
	study.plant();check("Unheld point cannot plant",study.injections==0)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await ticks()
	var target:Vector3=study.to_global(Vector3(-.85+(5.5-16)*.04,1.06,.5+(7.5-16)*.04))
	hand.global_position=target
	for i in 5:await ticks()
	observations.targeting={"site":str(study.target_site()),"point_local":str(study.to_local(study.point.global_position)),"target":str(target),"hand":str(hand.global_position)}
	print("TARGETING ",observations.targeting)
	check("Held point maps world position to selected address",study.point.held() and study.target_site()==Vector2i(5,7))
	study.point.action();await ticks();var index:int=study.left.index(5,7)
	check("XR trigger plants both fields without advancing time",study.injections==1 and study.left.v[index]==.25 and study.right.v[index]==.25 and study.left.ticks==0)
	hand.global_position+=Vector3(0,2,0);await ticks();study.point.action();await ticks();check("Trigger away from surface leaves state alone",study.injections==1)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks();check("Release returns the carried point to its shelf",not study.point.held() and study.point.position.is_equal_approx(Vector3(0,1.12,-.35)))
	study.queue_free();origin.queue_free();await ticks()
	var variation=fixture("variation");variation.advance(1);w=variation.left.index(15,15)
	check("Independent feed edit matches both predicted local values",is_equal_approx(variation.left.u[w],.49375) and is_equal_approx(variation.left.v[w],.25375))
	check("Feed edit leaves diffusion-only comparison unchanged",is_equal_approx(variation.right.u[w],.5) and is_equal_approx(variation.right.v[w],.25))
	variation.queue_free();await ticks()
	for folder in ["fault-conversion","fault-supply","fault-inplace"]:
		var failures_found:Array=faults(model(folder));check("Contract catches "+folder,not failures_found.is_empty());observations[folder]=failures_found
	var bad=fixture("fault-replay");bad.advance(10);bad.reset()
	check("Contract catches counter-only replay",bad.left.ticks==0 and bad.left.v!=model("printed").v)
	bad.queue_free();await ticks()
	var output:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE);output.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Exact printed Godot code; real keyboard and synthetic XRTools; independent edit and four executing faulty programs. No headset/independent human learner."},"\t"));output.close()
	quit(0 if failures.is_empty() else 1)
