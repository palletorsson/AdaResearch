extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-ghost-prefab-playtest/"
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok});print("PASS " if ok else "FAIL ",label)
func run() -> void:
	AudioServer.set_bus_mute(0,true);root.size=Vector2i(1700,1050)
	var preview: Node3D=load("res://commons/artifacts/prefab_disorder/preview.tscn").instantiate();root.add_child(preview)
	var bench: Node3D=preview.bench;var ghost: Node3D=bench.ghost
	ghost.auto_enabled=false;ghost.speed=4
	for i in 4: await physics_frame;await process_frame
	var baseline: String=ghost.state_hash()
	check("CRT screen identified by source and stable part key",bench.witness.part_index>=0)
	bench.act("FOLLOW PART")
	check("identity marker does not change the experiment",bench.witness.enabled and ghost.state_hash()==baseline)
	bench.act("FOLLOW PART")
	check("rehearsal starts",ghost.start())
	for i in 5000:
		await process_frame
		if not ghost.active and not ghost.walk.requested: break
	var report: Dictionary=ghost.report
	check("all nine native actions pass",report.status=="completed" and report.steps.size()==9 and report.steps.all(func(s):return s.passed))
	check("all eleven observation pairs saved",report.observations.size()==11 and report.observations.all(func(s):return s.status=="saved" and s.same_process_frame))
	check("starting artifact and marker restored",ghost.state_hash()==baseline and not bench.witness.enabled)
	check("standalone scene reports missing next artifact",ghost.walk.receipt.get("status")=="no next artifact in this scene")
	var by_label: Dictionary={}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR+"captures"))
	for pair in report.observations:
		by_label[pair.label]=pair
		for ref in pair.thought_stream:
			if ref.has("path"): check(pair.label+" source excerpt exists",FileAccess.get_file_as_string(ref.path).contains(ref.text))
		for channel in ["eyes","outside"]:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(pair.folder+"/"+pair.files[channel].name),ProjectSettings.globalize_path(DIR+"captures/"+pair.files[channel].name))
		DirAccess.copy_absolute(ProjectSettings.globalize_path(pair.record),ProjectSettings.globalize_path(DIR+"captures/"+pair.label+".json"))
	if by_label.has("03-separated-left") and by_label.has("04-separated-right"):
		check("both tables inspected at exactly the same arrangement",by_label["03-separated-left"].state_hash==by_label["04-separated-right"].state_hash)
		check("head actually turns between tables",by_label["03-separated-left"].head.world!=by_label["04-separated-right"].head.world)
	for label in ["05-follow-early","06-follow-middle","07-follow-late","08-first-hybrid"]:
		check(label+" follows the same screen inside the frustum",by_label.has(label) and by_label[label].part_witness.centre_in_frustum and by_label[label].part_witness.part_key==by_label["04-separated-right"].part_witness.part_key)
	check("KEEP and REPLAY capture the same state",by_label.has("10-kept") and by_label.has("11-replayed") and by_label["10-kept"].state_hash==by_label["11-replayed"].state_hash)
	var fresh: Node3D=load("res://commons/artifacts/prefab_disorder/prefab_disorder.tscn").instantiate();root.add_child(fresh);fresh.ghost.auto_enabled=false
	for i in 3: await physics_frame;await process_frame
	for pair in report.observations: check(pair.label+" reconstructs in a fresh instrument",fresh.restore(pair.artifact_state) and fresh.ghost.state_hash()==pair.state_hash)
	fresh.queue_free();await process_frame
	ghost.tour_enabled=false;ghost.start();bench.user_disorder(0.31)
	check("visitor input ends rehearsal and retains visitor change",not ghost.active and is_equal_approx(bench.disorder,0.31))
	var file:=FileAccess.open(DIR+"verification.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"report":report},"\t",true,true));file.close()
	preview.queue_free();await process_frame;await process_frame
	quit(0 if checks.all(func(c):return c.passed) else 1)
