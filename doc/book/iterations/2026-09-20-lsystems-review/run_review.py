"""Check reveal timing and restore the actual three-hall museum continuation."""
from pathlib import Path
import json
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/LSystems_Architecture'
PREFIX = 'res://' + HERE.relative_to(ROOT).as_posix() + '/'
base = (ROOT / 'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
setup = r'''
	var old_cam: Camera3D = museum.get("_cam")
	if old_cam != null:
		for timer in old_cam.find_children("*", "Timer", true, false): timer.stop()
	var actor: CharacterBody3D = museum.get("_player")
	actor.global_position = origin + Vector3(2,0.1,2)
	var dungeon: Node3D = nodes.get("lsystem_dungeon")
	var desk: Node3D = dungeon.get_node_or_null("ArchitectureLesson") if dungeon != null else null
	review_check(desk != null, "Architecture lesson instantiated")
	if desk != null:
		var records: Dictionary = desk.records.duplicate(true)
		review_check(records.rooms.size()==2 and desk.room_addresses.size()==1, "two room records still share one address")
		review_check(not revealed(desk) and not desk.address_revealed, "opening leaves the address answer undisclosed in both labels")
		await photo(origin+Vector3(9.5,1.65,4.6), origin+Vector3(9.5,1.3,7.2), folder+"after-opening.png",65)
		await press(desk,"BUILD")
		review_check(desk.built and not revealed(desk), "BUILD preserves the unanswered comparison")
		await press(desk,"WIDTH")
		review_check(desk.width_index==2 and not revealed(desk), "WIDTH does not give away the address")
		await press(desk,"RULE")
		review_check(desk.address_revealed and revealed(desk), "RULE reveals the shared address in both labels")
		review_check(desk.readout.text.contains("mark this position"), "RULE retains the interpreter explanation")
		await press(desk,"RESET")
		review_check(not desk.address_revealed and not revealed(desk), "RESET restores discovery before ROOMS")
		await press(desk,"ROOMS")
		review_check(desk.rooms_enabled and revealed(desk) and desk.room_cells.size()==196, "ROOMS reveals one address while constructing its footprint")
		await photo(origin+Vector3(9.5,1.65,4.6), origin+Vector3(9.5,1.3,7.2), folder+"revealed.png",65)
		await press(desk,"ROOMS")
		review_check(not desk.rooms_enabled and revealed(desk), "removing the footprint keeps the discovered answer")
		await press(desk,"RESET")
		review_check(not desk.address_revealed and not revealed(desk) and not desk.built and desk.width_index==1, "RESET returns the complete opening state")
		review_check(desk.records==records, "all controls preserve the original sentence and records")
	# Exercise the actual streaming selection; never substitute a bespoke room order.
	var next_map: String = museum.call("_peek_next_authored_map")
	review_check(next_map=="LSystems_Competition", "museum selects Competition after Architecture")
	if next_map=="LSystems_Competition":
		museum.call("_build_segment")
		museum.call("flush_stamps")
		await create_timer(1).timeout
		var competition: Node3D = find_hall(museum,"LSystems_Competition")
		review_check(competition!=null, "Competition builds as the next museum segment")
		if competition != null:
			var forest: Node3D = null
			for record in museum.get("_edit_records"):
				if record.get("seg")==competition and record.get("token")=="ForestCompetition": forest=record.get("node")
			var pair: Node3D = forest.get_node_or_null("CompetitionLesson") if forest != null else null
			review_check(pair!=null, "restored forest includes its controlled pair")
			if pair != null:
				await press(pair,"STEP"); await press(pair,"STEP")
				review_check(is_equal_approx(pair.last_takes[0],2.25) and is_equal_approx(pair.last_takes[1],1.98), "restored encounter gives A first uptake 2.250 and B 1.980")
				await press(pair,"ORDER"); await press(pair,"STEP"); await press(pair,"STEP")
				review_check(is_equal_approx(pair.last_takes[1],2.25) and is_equal_approx(pair.last_takes[0],1.98), "changing the first turn reverses the advantage")
				await photo(pair.to_global(Vector3(5,5,4)),pair.to_global(Vector3(0,0,-3)),folder+"competition.png",73)
				await press(pair,"SEASON"); await press(pair,"STEP"); await press(pair,"STEP")
				review_check(pair.winter and pair.model._trees[0].generation==0 and pair.model._trees[1].generation==0 and pair.last_takes[0]>0 and pair.last_takes[1]>0, "winter still consumes without rewriting")
				report["competition_placement"] = arr(forest.global_position-competition.global_position-Vector3(0,0,4))
			next_map= museum.call("_peek_next_authored_map")
			review_check(next_map=="LSystems_Living", "museum selects Living after Competition")
			if next_map=="LSystems_Living":
				museum.call("_build_segment")
				museum.call("flush_stamps")
				await create_timer(1).timeout
				review_check(find_hall(museum,"LSystems_Living")!=null, "Living builds as the third segment")
	var route: Array = []
	for child in museum.get_children():
		if child.has_meta("em_map"): route.append(str(child.get_meta("em_map")))
	report["built_route"]=route
	report["review_checks"]=review_results
	report["review_scope"]="Real museum segment selection/building and real button signals. No end-to-end walk, headset comfort or learner acceptance claimed."
'''
helpers = r'''

var review_results: Array = []

func review_check(ok: bool, name_: String) -> void:
	review_results.append({"check":name_,"passed":ok})
	if not ok: failures.append(name_)

func revealed(desk: Node3D) -> bool:
	return desk.program.text.contains("1 shared address") and desk.readout.text.contains("1 shared address")

func press(desk: Node3D, id: String) -> void:
	var button: Node = desk.buttons[id].get_node("InteractableAreaButton")
	button.emit_signal("button_pressed",button)
	await create_timer(0.08).timeout

func find_hall(museum: Node3D, id: String) -> Node3D:
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))==id: return child
	return null

func photo(from: Vector3, toward: Vector3, path: String, fov_: float) -> void:
	var c:=Camera3D.new()
	root.add_child(c);c.global_position=from;c.look_at(toward);c.fov=fov_;c.current=true
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	review_check(root.get_camera_3d()==c,"capture camera owns "+path.get_file())
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	c.queue_free()
'''
needle = '\tawait physics_frame\n\tvar space :='
assert base.count(needle)==1
source = base.replace(needle,setup+'\n'+needle).replace('folder + "report.json"','folder + "review-report.json"')+helpers
(HERE/'probe_review.gd').write_text(source,encoding='utf-8')
# Refresh only the probe's private plan after the authored route repair.
shutil.copy2(ROOT/'ada_run/em_plan.json',RUN/'plan.json')
spec=json.loads((RUN/'spec.json').read_text(encoding='utf-8'));spec['shots']=[]
(HERE/'review-spec.json').write_text(json.dumps(spec,indent=2))
report_path=RUN/'review-report.json'
if report_path.exists():report_path.unlink()
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--audio-driver','Dummy','--log-file',str(HERE/'engine.log'),'--script',PREFIX+'probe_review.gd','--',PREFIX+'review-spec.json']
with (HERE/'process.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
print('Review exit:',result.returncode)
print((HERE/'process.log').read_text(encoding='utf-8',errors='replace')[-1800:])
if report_path.exists():shutil.copy2(report_path,HERE/'review-report.json')
if result.returncode==0:
    for name in ['after-opening.png','revealed.png','competition.png']:shutil.copy2(RUN/name,HERE/name)
raise SystemExit(result.returncode)
