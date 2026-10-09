"""Inspect the actual museum desk using the existing isolated museum probe."""
from pathlib import Path
import json
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RUN = ROOT/'ada_run/encounter_pilot/ISO_PortalLandscape'
PREFIX = 'res://' + HERE.relative_to(ROOT).as_posix() + '/'
base = (ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
setup = r'''
	for timer in museum.get("_cam").find_children("*", "Timer", true, false): timer.stop()
	var desk: Node3D = nodes.get("iso_portal_console")
	check(desk != null, "comparison desk is placed in the actual hall")
	if desk != null:
		for attempt in 100:
			if desk.ready_for_input: break
			await create_timer(0.1).timeout
		check(desk.ready_for_input and desk.actual_mesh(), "desk binds a generated GPU surface, not fallback terrain")
		if desk.ready_for_input and desk.actual_mesh():
			var m = desk.model
			var fixed: Array = m.get_params_array().slice(1,11)
			var placement: Transform3D = m.global_transform
			check(m.landform == "hillside", "arrival begins with the height field")
			check(is_equal_approx(m.chunk_scale,300.0) and desk.field_root.scale.is_equal_approx(Vector3.ONE*0.02), "fixed domain and six-metre display")
			await photo(origin+Vector3(14.5,3.2,4),origin+Vector3(14.5,1.2,12.5),folder+"hillside.png",75)
			await press(desk,"HOLD")
			var held_mesh: Mesh = desk.held.mesh
			var held_faces: PackedVector3Array = held_mesh.get_faces()
			var held_transform: Transform3D = desk.held.global_transform
			check(held_mesh != m.mesh and held_faces == m.mesh.get_faces(), "HOLD duplicates the actual current geometry")
			check(desk.held.find_children("*","CollisionObject3D",true,false).is_empty(), "held surface adds no collision")
			check((desk.held.global_position-m.global_position).is_equal_approx(Vector3(12,0,0)), "held specimen has a separate bay with unchanged orientation and scale")
			var states: Array = []
			for term in ["overhung","quarried","arched","compound","hillside"]:
				await press(desk,"TERMS")
				check(m.landform == term and desk.TERMS[desk.term_index] == term, "TERMS selects "+term)
				check(m.get_params_array().slice(1,11) == fixed and m.global_transform.is_equal_approx(placement), term+": only the weighted contributions change")
				check(desk.held.mesh == held_mesh and desk.held.mesh.get_faces() == held_faces and desk.held.global_transform.is_equal_approx(held_transform),term+": held geometry and placement survive")
				check(desk.actual_mesh() and not m.waiting_for_compute and not m.waiting_for_meshthread,term+": build completes before another action")
				states.append({"term":term,"triangles":m.num_triangles,"weights":m._weights(),"bounds":str(m.mesh.get_aabb())})
				if term in ["overhung","quarried","compound"]:
					await photo(origin+Vector3(14.5,3.2,4),origin+Vector3(14.5,1.2,12.5),folder+term+".png",75)
			await press(desk,"TERMS")
			await press(desk,"HOLD")
			check(desk.held_term=="overhung" and desk.held.mesh!=held_mesh, "HOLD replaces its single previous comparison")
			await press(desk,"RESET")
			check(m.landform=="hillside" and desk.held_term=="overhung", "RESET preserves the held comparison")
			await press(desk,"CLEAR")
			check(desk.held==null and m.landform=="hillside", "CLEAR removes only the comparison")
			await press(desk,"RULE")
			check(desk.rule_card.visible, "explanation is available after observation")
			await press(desk,"RULE")
			m.use_fallback=true
			await press(desk,"TERMS")
			check(m.landform=="hillside" and desk.readout.text.contains("UNAVAILABLE"), "fallback cannot masquerade as a working comparison")
			m.use_fallback=false;desk.refresh()
			await press(desk,"HOLD")
			for i in 4: await press(desk,"TERMS")
			await photo(origin+Vector3(14.5,1.7,3),origin+Vector3(14.5,1.2,12),folder+"encounter.png",78)
			await photo(origin+Vector3(8.5,1.7,8),origin+Vector3(8.5,1.0,12.5),folder+"boundary.png",64)
			report["field_states"] = states
	report["review_checks"] = checks
'''
helpers = r'''

var checks: Array = []
func check(ok: bool, message: String) -> void:
	checks.append({"check":message,"passed":ok})
	if not ok: failures.append(message)

func press(desk: Node3D,id: String) -> void:
	var b: Node = desk.buttons[id].get_node("InteractableAreaButton")
	b.emit_signal("button_pressed",b)
	await create_timer(0.25).timeout

func photo(from: Vector3,toward: Vector3,path: String,fov_: float) -> void:
	var c := Camera3D.new();root.add_child(c)
	c.global_position=from;c.look_at(toward);c.fov=fov_;c.current=true
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d()==c,"capture camera owns "+path.get_file())
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	c.queue_free()
'''
needle='\tawait physics_frame\n\tvar space :='
assert base.count(needle)==1
(HERE/'probe_review.gd').write_text(base.replace(needle, setup+'\n'+needle)+helpers,encoding='utf-8')
spec=json.loads((RUN/'spec.json').read_text(encoding='utf-8'))
spec['shots']=[]  # Explicit camera-ownership checks above cover all shots.
(HERE/'review-spec.json').write_text(json.dumps(spec,indent=2),encoding='utf-8')
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/'engine.log'),'--script',PREFIX+'probe_review.gd','--',PREFIX+'review-spec.json']
report=RUN/'report.json'
if report.exists(): report.unlink()
with (HERE/'process.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
print('Review exit:',result.returncode)
print((HERE/'process.log').read_text(encoding='utf-8',errors='replace')[-1500:])
if report.exists():
    shutil.copy2(report,HERE/'review-report.json')
    d=json.loads(report.read_text(encoding='utf-8')); print('Failures:',d.get('failures'))
    for p in RUN.glob('*.png'): shutil.copy2(p,HERE/('after-'+p.name))
raise SystemExit(result.returncode)
