extends SceneTree
## Exercise the actual VR code path with a synthetic XR eye; no GPU claims.
const OUT := "res://doc/space/randomness-performance-2026-09-16/"
var failures: Array[String]=[]
var transitions: Array=[]

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func drain(em: Node3D, rig: XROrigin3D) -> Dictionary:
	var peaks: Array=[]
	for i in range(200):
		if (em.get("_stamp_queue") as Array).is_empty(): break
		var t:=Time.get_ticks_usec()
		em.call("_drain_stamps")
		peaks.append((Time.get_ticks_usec()-t)/1000.0)
		await process_frame
	return {"drain_calls_ms":peaks,"pending":(em.get("_stamp_queue") as Array).size()}

func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var rig:=XROrigin3D.new();rig.name="ProbeRig";rig.current=true
	var eye:=XRCamera3D.new();eye.name="ProbeEye";eye.position.y=1.65;rig.add_child(eye);world.add_child(rig)
	var ctl:=OUT+"stream-control.json"
	var f:=FileAccess.open(ctl,FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"randomness","first_map":"Random_Definition","dollhouse":0,"grid_pack":1}));f.close()
	var em: Node3D=load(OUT+"measured_museum.gd").new()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","randomness");em.set("start_map","Random_Definition")
	em.set("_force_vr",true);em.set("_force_patient",true)
	world.add_child(em)
	# Wait for startup deferred work, then drive the VR tick explicitly so the
	# shell-build and drain durations are recorded separately.
	await create_timer(0.3).timeout
	em.set_process(false);em.set_physics_process(false)
	var segs: Array=em.get("_segments")
	expect(not segs.is_empty(),"opening hall exists")
	if segs.is_empty():quit(1);return
	rig.position=Vector3(float(segs[0].w)/2.0,0,(float(segs[0].z0)+float(segs[0].z1))/2.0)
	await drain(em,rig)
	em.set("_museum_ready",true)
	expect(bool(em.get("_vr")),"uses VR lane")
	for step in range(4):
		var t:=Time.get_ticks_usec()
		em.call("_vr_single_map_stream",rig.position.z,0.016)
		var sync_ms:=(Time.get_ticks_usec()-t)/1000.0
		await process_frame
		await process_frame
		var drain_result:=await drain(em,rig)
		segs=em.get("_segments")
		var shells: Array=[]
		var owners:=0
		for rec: Dictionary in segs:
			var content: Array=[]
			em.call("_vr_collect_content_roots",rec.node,content)
			if not content.is_empty():owners+=1
			expect(not bool(rec.get("shell",false)) or content.is_empty(),"shell has no exhibit roots")
			shells.append({"map":rec.node.get_meta("em_map",""),"shell":rec.get("shell",false),"content_roots":content.size()})
		expect(segs.size()<=3,"at most three architecture shells")
		expect(owners<=1,"at most one exhibit owner")
		expect(drain_result.pending==0,"current hall construction drains")
		transitions.append({"step":step,"sync_transition_ms":sync_ms,"shells":shells,"drain":drain_result})
		var target: Dictionary=segs[-1] if step<2 else segs[0]
		rig.position=Vector3(float(target.w)/2.0,0,(float(target.z0)+float(target.z1))/2.0)
	var report:={"headless":true,"headset_verified":false,"transitions":transitions,
		"stamps":em.get("stamp_times"),"segments":em.get("segment_times"),"failures":failures}
	f=FileAccess.open(OUT+"stream.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print("[randomness-stream] failures=",failures)
	quit(0 if failures.is_empty() else 1)
