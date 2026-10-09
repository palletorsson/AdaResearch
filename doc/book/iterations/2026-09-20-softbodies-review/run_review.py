"""Check reading/feedback separation and the reconstructed skin in the real hall."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/SoftBodies_Playground_of_Joy'
PREFIX = 'res://' + HERE.relative_to(ROOT).as_posix() + '/'
base = (ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
setup = r'''
	var desk: Node3D = nodes.get("soft_workshop_console")
	check(desk!=null and desk.ready_for_input,"hall desk binds both specimens")
	if desk!=null and desk.ready_for_input:
		var m: Node3D = desk.model
		check(not m.volume_feedback,"feedback is explicitly off at arrival")
		check(is_equal_approx(m.position.y,0.84),"lesson bench is seated before reference capture")
		check(m._vertex_count>0 and m._rest_volume>0,"seated specimen has a physics reference")
		var body_bounds:=AABB()
		for i in m._vertex_count:
			var p: Vector3=PhysicsServer3D.soft_body_get_point_global_position(m._sb_rid,i)
			if i==0:body_bounds=AABB(p,Vector3.ZERO)
			else:body_bounds=body_bounds.expand(p)
		check(body_bounds.position.y-origin.y>0.65 and body_bounds.end.y-origin.y<2.0,"live body is at standing working height")
		report["specimen_y_range"]=[body_bounds.position.y-origin.y,body_bounds.end.y-origin.y]
		check(Vector2(body_bounds.get_center().x-m.global_position.x,body_bounds.get_center().z-m.global_position.z).length()<0.65,"live points remain with their placed bench")
		check(m._strain_mi.global_transform.is_equal_approx(Transform3D.IDENTITY) and m._ghost_mi.global_transform.is_equal_approx(Transform3D.IDENTITY) and m._force_mi.global_transform.is_equal_approx(Transform3D.IDENTITY),"world-space overlays align with the solver rather than being transformed twice")
		await photo(origin+Vector3(8.5,1.75,8.2),origin+Vector3(8.5,1.1,10.5),folder+"specimen.png",60)
		var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true
		Input.parse_input_event(mouse);await process_frame
		m._update_vr_hand(0.016)
		check(m._hand_active and m._hand_pos.distance_to(m._current_center)<0.5,"desktop squeeze follows the live body instead of world zero")
		mouse.pressed=false;Input.parse_input_event(mouse);await process_frame
		var ys: Dictionary={}
		var zs: Dictionary={}
		for b in desk.buttons.values():ys[b.position.y]=true;zs[b.position.z]=true
		check(desk.buttons.size()==7 and ys.size()==1 and zs.size()==2,"seven controls retain two rows and one height")
		var p0: float=m._soft_body.pressure_coefficient
		for mode in ["collision","volume","strain"]:
			await press(desk,"MEASURE")
			await create_timer(0.15).timeout
			check(m.measure==mode and is_equal_approx(m._soft_body.pressure_coefficient,p0),"reading "+mode+" does not change pressure")
		await press(desk,"MEASURE");await press(desk,"MEASURE")
		await press(desk,"FEEDBACK")
		check(m.volume_feedback and m.measure=="volume","feedback can be enabled without changing the reading")
		# Controlled nonzero error isolates pressure feedback from solver variability.
		m.set_process(false)
		var saved_rest: float=m._rest_volume
		var saved_current: float=m._current_volume
		m._rest_volume=1.0;m._current_volume=0.5
		m._soft_body.pressure_coefficient=0.3
		m._apply_volume_correction(0.1)
		check(is_equal_approx(m._soft_body.pressure_coefficient,0.315),"declared feedback error changes pressure by gain times elapsed delta")
		await press(desk,"MEASURE")
		var before: float=m._soft_body.pressure_coefficient
		m._apply_volume_correction(0.1)
		check(m.measure=="strain" and m.volume_feedback and m._soft_body.pressure_coefficient>before,"feedback continues under a different reading")
		await press(desk,"FEEDBACK")
		m._apply_volume_correction(0.1)
		check(not m.volume_feedback and is_equal_approx(m._soft_body.pressure_coefficient,m._pressure),"feedback off restores selected pressure and blocks correction")
		m._rest_volume=saved_rest;m._current_volume=saved_current
		# The instrument's local button shares the hall controller's state.
		var local_button: Node=m._rack_panel.find_child("Btn_1",true,false).get_node("InteractableAreaButton")
		local_button.emit_signal("button_pressed",local_button)
		await create_timer(0.6).timeout
		check(m.volume_feedback and desk.readout.text.contains("feedback ON"),"local feedback button updates the hall readout")
		local_button.emit_signal("button_pressed",local_button)
		m.set_process(true)
		# Root configuration must not overwrite a mode selected on the child.
		m._cycle_mode()
		desk.works.rounded_softbody_test.apply_grid_config({"volume_feedback":"true"})
		check(m.measure=="collision" and m.volume_feedback,"root forwards feedback without resetting the selected reading")
		desk.works.rounded_softbody_test.apply_grid_config({"volume_feedback":"false"})
		await press(desk,"MEASURE")
		await photo(origin+Vector3(15.5,1.7,0.7),origin+Vector3(15.5,1.1,2.8),folder+"volume-reading.png",70)
		await press(desk,"FEEDBACK")
		await photo(origin+Vector3(15.5,1.7,0.7),origin+Vector3(15.5,1.1,2.8),folder+"volume-feedback.png",70)
		await press(desk,"FEEDBACK");await press(desk,"MEASURE")
		await press(desk,"SQUEEZE");await press(desk,"STIFFNESS")
		check(is_equal_approx(m._squeeze_strength,1.0) and is_equal_approx(m._soft_body.linear_stiffness,0.1),"material and interaction controls remain separate")
		m._on_squeeze_changed("review",0.4);m._on_stiffness_changed("review",0.5)
		var vessel: Node3D=desk.other
		await check_skin(vessel,"initial 200 steps")
		for steps in [40,400,200]:
			var old_skin: Node=vessel.get_node("Vessel/FrozenSkin")
			await press(desk,"DURATION")
			check(not is_instance_valid(old_skin) or not old_skin.is_inside_tree(),"duration "+str(steps)+" removes the old collision")
			check(vessel.sim_steps==steps,"duration chooses "+str(steps)+" integration steps")
			await check_skin(vessel,str(steps)+" steps")
			if steps in [40,400]:await photo(origin+Vector3(23,2.5,10),origin+Vector3(20.5,1,13.5),folder+"vessel-"+str(steps)+".png",65)
		for gx in [2.0,-2.0,0.0]:
			await press(desk,"GRAVITY")
			check(is_equal_approx(vessel.gravity_x,gx),"lateral force chooses "+str(gx))
			await check_skin(vessel,"gravity "+str(gx))
		# Actual body support/contact, not a claim that the closed skin has an entrance.
		var actor: CharacterBody3D=museum.get("_player")
		museum.set("_player",null)
		var skin: Node=vessel.get_node("Vessel/FrozenSkin")
		var bounds: AABB=vessel._mi.mesh.get_aabb()
		var peak: Vector3=vessel._mi.to_global(Vector3(0,bounds.end.y,0))
		actor.global_position=peak+Vector3.UP
		actor.velocity=Vector3.ZERO
		var met_skin:=false
		for i in 150:
			actor.velocity=Vector3(0,actor.velocity.y-11.0/60.0,0)
			actor.move_and_slide()
			for j in actor.get_slide_collision_count():
				if actor.get_slide_collision(j).get_collider()==skin:met_skin=true
			await physics_frame
		check(met_skin and actor.global_position.y-origin.y>0.5,"CharacterBody meets and is supported by the frozen surface")
		report["body_on_skin"]={"contact":met_skin,"position":arr(actor.global_position-origin)}
		actor.global_position=origin+Vector3(27,0.1,3)
		await press(desk,"RULE")
		check(desk.rule_card.visible,"explanation remains available after the encounter")
		await press(desk,"RULE")
		# The shared desk's original six-button layout remains unchanged.
		var six: Node3D=load("res://commons/artifacts/timing_machines/pg_workshop.gd").new()
		root.add_child(six);six.position=Vector3(100,0,100)
		six._build_compact_console(["A","B","C","D","E","F"],"layout check")
		check(six.buttons.A.position.is_equal_approx(Vector3(-0.32,1.045,1.88)) and six.buttons.F.position.is_equal_approx(Vector3(0.32,1.045,2.11)),"six-button desks keep their prior layout")
		six.queue_free()
		var original: Node3D=load("res://algorithms/softbodies/rounded_softbody_test.tscn").instantiate()
		original.position=Vector3(100,10,100);root.add_child(original)
		check(is_equal_approx(original.get_node("RoundedSoftBody").position.y,3.0),"unconfigured harnesses retain their prior elevation")
		await process_frame;await process_frame
		original.queue_free()
	report["review_checks"]=checks
	report["review_scope"]="Actual museum artifacts and button signals. One controlled error tests feedback independently of solver variability. Matching mesh/collision, reconstruction replacement, support rays and a CharacterBody contact test. No headset or learner acceptance."
'''
helpers = r'''

var checks: Array=[]
func check(ok: bool, label: String) -> void:
	checks.append({"check":label,"passed":ok})
	if not ok:failures.append(label)

func press(desk: Node3D,id: String) -> void:
	var b: Node=desk.buttons[id].get_node("InteractableAreaButton")
	b.emit_signal("button_pressed",b)
	await create_timer(0.2).timeout

func check_skin(vessel: Node3D,label: String) -> void:
	await physics_frame
	var skin: StaticBody3D=vessel.get_node_or_null("Vessel/FrozenSkin")
	var bodies: Array=vessel.find_children("*","StaticBody3D",true,false)
	check(skin!=null and bodies.size()==1,label+": exactly one active skin")
	if skin==null:return
	var shape: ConcavePolygonShape3D=skin.get_node("Surface").shape
	check(shape.backface_collision and shape.get_faces()==vessel._mi.mesh.get_faces(),label+": collision matches both sides of the rendered mesh")
	var bounds: AABB=vessel._mi.mesh.get_aabb()
	check(absf(vessel._mi.position.y+bounds.position.y)<0.001,label+": full form meets its floor datum")
	var ray:=PhysicsRayQueryParameters3D.create(vessel._mi.to_global(Vector3(0,bounds.end.y+0.5,0)),vessel._mi.to_global(Vector3(0,bounds.position.y-0.1,0)),1)
	var hit:=vessel.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider==skin,label+": vertical ray meets the actual skin")

func photo(from: Vector3,toward: Vector3,path: String,fov_: float) -> void:
	var c:=Camera3D.new();root.add_child(c)
	c.global_position=from;c.look_at(toward);c.fov=fov_;c.current=true
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d()==c,"capture camera owns "+path.get_file())
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	c.queue_free()
'''
# Disable the museum's camera watchdog before the custom shots too.
setup = '\n\tfor timer in museum.get("_cam").find_children("*","Timer",true,false):timer.stop()\n' + setup
needle='\tawait physics_frame\n\tvar space :='
assert base.count(needle)==1
(HERE/'probe_review.gd').write_text(base.replace(needle,setup+'\n'+needle)+helpers,encoding='utf-8')
spec=json.loads((RUN/'spec.json').read_text());spec['walks']=[]
(HERE/'review-spec.json').write_text(json.dumps(spec,indent=2))
report=RUN/'report.json'
if report.exists():report.unlink()
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--audio-driver','Dummy','--log-file',str(HERE/'engine.log'),'--script',PREFIX+'probe_review.gd','--',PREFIX+'review-spec.json']
with (HERE/'process.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
output=(HERE/'process.log').read_text(encoding='utf-8',errors='replace')
print('Review exit:',result.returncode);print(output[-2000:])
if report.exists():shutil.copy2(report,HERE/'review-report.json')
errors=[line for line in output.splitlines() if 'SCRIPT ERROR:' in line or 'Parse Error:' in line]
if errors:print('Script errors:',errors)
if result.returncode==0 and not errors:
    for name in ['console.png','vessel.png','volume-reading.png','volume-feedback.png','vessel-40.png','vessel-400.png','specimen.png']:shutil.copy2(RUN/name,HERE/('after-'+name))
    paths=[ROOT/p for p in json.loads((HERE/'before-sha256.json').read_text())]
    paths += [HERE/'probe_review.gd',HERE/'review-spec.json',RUN/'museum_snapshot.gd',RUN/'plan.json',RUN/'necklace_hand.json',RUN/'em_overrides.json']
    (HERE/'runtime-inputs.json').write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2))
raise SystemExit(result.returncode or bool(errors))
