extends SceneTree
var checks:Array=[]
var failures:Array=[]
var artifact:Node3D
var pointer:Node3D
var event_script
func _initialize()->void:call_deferred("run")
func check(label:String,passed:bool,value:Variant=null)->void:
	checks.append({"name":label,"passed":passed,"value":value})
	if not passed:failures.append(label)
func button(index:int)->void:
	var node:Node3D=artifact.controls.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	for kind in [2,3]:node.pointer_event(event_script.new(kind,pointer,node,node.global_position,node.global_position))
func run()->void:
	artifact=load("res://commons/artifacts/related_weather/related_weather.tscn").instantiate()
	artifact.position=Vector3(17,0,-12);artifact.rotation.y=PI;root.add_child(artifact)
	pointer=Node3D.new();root.add_child(pointer);event_script=load("res://addons/godot-xr-tools/events/pointer_event.gd")
	await process_frame;await physics_frame
	check("empty arrival, held clock",artifact.records.is_empty() and not artifact.running)
	check("three banks of eight slits",artifact.shutters.size()==24)
	button(1);await create_timer(0.35).timeout
	check("production NEXT starts one sample",artifact.records.size()==1 and artifact.moving)
	button(1);button(1);check("repeated NEXT resumes rather than redraws",artifact.records.size()==1)
	await create_timer(0.9).timeout
	check("one step reaches its target and holds",not artifact.moving and not artifact.running and artifact.states==artifact.targets)
	var first:Array=artifact.records[0].duplicate()
	check("walk uses the same innovation",absf(first[1]-first[0]*0.1)<0.000001)
	button(0);await create_timer(0.3).timeout;button(0)
	var held:Dictionary=artifact.get_state()
	await create_timer(0.4).timeout
	check("HOLD pauses aperture and clock",artifact.states==held.visible and artifact.phase==held.phase and artifact.records.size()==held.count)
	button(1);await create_timer(1.1).timeout
	check("NEXT finishes paused stroke without another draw",artifact.records.size()==held.count and not artifact.moving and artifact.states==artifact.targets)
	button(2);check("REPLAY clears pending travel and record",artifact.records.is_empty() and not artifact.moving and not artifact.running)
	button(1);await create_timer(1.1).timeout
	check("replay repeats all three channels including preparation",artifact.records[0]==first)
	for i in range(10):button(1);artifact._process(1.0)
	check("history bounded to eight visible moments",artifact.records.size()==11 and artifact.shutters[0].labels[0].text=='11' and artifact.shutters[7].labels[0].text=='4')
	for channel in range(3):
		for slot in range(8):
			var display:Array=load("res://commons/artifacts/related_weather/weather_signals.gd").display_values(artifact.records[10-slot])
			check("correct historical target %d %d"%[channel,slot],absf(artifact.targets[channel*8+slot].x-(1.7+0.75*clampf(display[channel],-1,1)))<0.00001)
	artifact.source.sum=20.0;button(1);artifact._process(1.0)
	check("raw positive walk survives display ceiling",artifact.records.back()[1]>19.8 and absf(artifact.targets[8].x-2.45)<0.00001 and artifact.shutters[8].labels[0].text.contains("LIMIT"))
	artifact.source.sum=-20.0;button(1);artifact._process(1.0)
	check("raw negative walk survives display floor",artifact.records.back()[1]<-19.8 and absf(artifact.targets[8].x-0.95)<0.00001 and artifact.shutters[8].labels[0].text.contains("LIMIT"))
	button(2);button(0);await create_timer(0.25).timeout;button(2);await create_timer(1.5).timeout
	check("reset during travel cannot leave a stale opening",artifact.records.is_empty() and not artifact.moving and artifact.states[0].y==0)
	for i in range(128):button(1);artifact._process(1.0)
	button(0);button(1);await create_timer(0.2).timeout
	check("explicit 128 sample budget never silently loops",artifact.records.size()==128 and not artifact.running and not artifact.moving and artifact.status.text.contains("FULL"))
	check("all visible slits stay within aperture bounds",artifact.states.all(func(v):return v.x>=0.949 and v.x<=2.451 and absf(v.y-0.64)<0.00001))
	var old_seed:int=artifact.run_seed;button(3)
	check("new seed is different and held empty",artifact.run_seed!=old_seed and artifact.records.is_empty() and not artifact.running)
	await physics_frame
	var space:=artifact.get_world_3d().direct_space_state
	for i in range(3):
		var x:float=(1-i)*3.3
		var ray:=PhysicsRayQueryParameters3D.create(artifact.to_global(Vector3(x-0.7,1.7,-3.5)),artifact.to_global(Vector3(x+0.7,1.7,-3.5)),1)
		var hit:=space.intersect_ray(ray)
		check("fixed glass retains collision %d"%i,not hit.is_empty() and str(hit.collider.get_parent().name)=="FixedGlass%d"%i)
	# Export production model output, before gain/clamp/easing. Not the 8-slot display.
	var model=load("res://commons/artifacts/related_weather/weather_signals.gd").new();model.reset(4321)
	var csv:=FileAccess.open("res://doc/book/iterations/2026-09-24-related-weather/raw-signals.csv",FileAccess.WRITE)
	csv.store_line("white,walk,pink")
	for i in range(65536):
		var v:Array=model.next_sample();csv.store_line("%.12f,%.12f,%.12f"%[v[0],v[1],v[2]])
	csv.close()
	FileAccess.open("res://doc/book/iterations/2026-09-24-related-weather/native-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Production pointer controls and native real-time pause/replay. Record-limit and bound cases advance the production update with explicit delta; forced walk state tests the display boundary. Raw export uses the production signal model. No headset or performance claim."},"  "))
	print("RELATED WEATHER ",checks.size()," CHECKS; FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
