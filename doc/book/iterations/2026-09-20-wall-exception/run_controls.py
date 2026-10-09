"""Exercise the opening in the real museum with its desktop CharacterBody."""
from pathlib import Path
import json
import shutil
import subprocess

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
RUN=ROOT/'ada_run/encounter_pilot/Tutorial_Tiling_Walls'
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
setup='''
	var cam: Camera3D = museum.get("_cam")
	if cam != null:
		for timer in cam.find_children("*","Timer",true,false): timer.stop()
	var wall: Node3D = nodes.get("wall_exception") as Node3D
	var tiling: Node3D = nodes.get("tiling_principles") as Node3D
	var actor: CharacterBody3D = museum.get("_player")
	var results: Array = []
	if wall == null or tiling == null or actor == null:
		failures.append("Required live artifact or body missing")
	else:
		actor.global_position = origin+Vector3(18.4,0.05,26.5)
		actor.velocity = Vector3.ZERO
		await physics_frame
		await physics_frame
		results.append({"check":"six original fields and wall pattern linked", "passed":tiling.surfaces.size()==6 and wall.study==tiling and wall.face.material_override.albedo_texture==tiling.surfaces[5].material_override.albedo_texture})
		var before_image: PackedByteArray = tiling.surfaces[5].material_override.albedo_texture.get_image().get_data()
		tiling.toggle_exception()
		results.append({"check":"image exception propagates without opening wall", "passed":wall.face.material_override.albedo_texture==tiling.surfaces[5].material_override.albedo_texture and tiling.surfaces[5].material_override.albedo_texture.get_image().get_data()!=before_image and not wall.open and is_zero_approx(wall.hinge.rotation.y)})
		var at: Vector3 = wall.global_position-origin
		results.append({"check":"wall root remains on intended cell and floor", "passed":at.distance_to(Vector3(20.5,0,25.5))<0.03,"position":arr(at)})
		results.append({"check":"museum omitted both replaced wall layers", "passed":(hall.get_meta("em_turning_wall_cells",{}) as Dictionary).size()==4})
		# Exercise the declaration guard independently: no owner means no hole.
		var dummy:=Node3D.new()
		museum.call("_prepare_turning_wall",dummy,{"turning_wall":{"side":"east","start_z":25},"artifacts":[]},hall.get_meta("em_tile"))
		results.append({"check":"opening refused without its placed owner", "passed":not dummy.has_meta("em_turning_wall_cells")})
		dummy.free()
		await capture(origin,folder,"closed",Vector3(16.8,1.65,25.8),Vector3(20.5,1.8,26))
		var stop: Dictionary = await travel(actor,origin,Vector3(18.4,0.05,26.5),Vector3(23.8,0,26.5),3.5)
		results.append({"check":"closed wall stops the walking body", "passed":float(stop.end[0])<20.35 and float(stop.end[0])>19.5,"end":stop.end})
		actor.global_position=origin+Vector3(18.4,0.05,26.5)
		actor.velocity=Vector3.ZERO
		await create_timer(0.15).timeout
		var printed: Texture2D=wall.face.material_override.albedo_texture
		wall.turn_button.get_node("InteractableAreaButton").emit_signal("button_pressed",wall.turn_button.get_node("InteractableAreaButton"))
		await create_timer(0.7).timeout
		results.append({"check":"wall turns gradually with its collider", "passed":wall.moving and wall.angle>0.05 and wall.angle<PI/2 and absf(wall.hinge.rotation.y-wall.angle)<0.03 and wall.hinge.get_child_count()>1,"angle":wall.angle,"body_angle":wall.hinge.rotation.y})
		await create_timer(2.3).timeout
		results.append({"check":"quarter turn completes without changing image", "passed":wall.open and not wall.moving and absf(wall.angle-PI/2)<0.01 and wall.face.material_override.albedo_texture==printed})
		await capture(origin,folder,"open",Vector3(16.8,1.65,25.8),Vector3(20.5,1.8,26))
		var outward: Dictionary = await travel(actor,origin,Vector3(18.4,0.05,26.5),Vector3(23.8,0,26.5),3.5)
		results.append({"check":"walk through both former wall layers onto landing", "passed":outward.passed,"end":outward.end})
		await capture(origin,folder,"outside",Vector3(23.9,1.65,27.0),Vector3(20.5,1.7,25.3))
		await capture(origin,folder,"reverse",Vector3(23.9,1.65,24.3),Vector3(21.5,1.7,25.0))
		wall.turn_button.pressed.emit()
		results.append({"check":"visitor outside prevents closing", "passed":wall.open and not wall.moving and wall.caption.text.contains("RETURN INSIDE")})
		var home: Dictionary=await travel(actor,origin,Vector3(23.8,0.05,26.5),Vector3(18.4,0,26.5),3.5)
		results.append({"check":"walk back into museum", "passed":home.passed,"end":home.end})
		await create_timer(0.15).timeout
		wall.turn_button.pressed.emit()
		await create_timer(2.8).timeout
		results.append({"check":"wall closes after return", "passed":not wall.open and not wall.moving and is_zero_approx(wall.angle)})
		tiling.toggle_exception()
		results.append({"check":"original image restores exactly", "passed":tiling.surfaces[5].material_override.albedo_texture.get_image().get_data()==before_image})
	for result in results:
		if not result.passed:failures.append(str(result.check))
	report["controls"]=results
	report["interaction_scope"]="Actual museum, real button signals, moving collision and controlled CharacterBody walking; no headset comfort or learner acceptance."
'''
helpers='''

func travel(actor: CharacterBody3D, origin: Vector3, from: Vector3, to: Vector3, seconds: float) -> Dictionary:
	actor.global_position=origin+from
	actor.velocity=Vector3.ZERO
	var target:=origin+to
	for i in range(int(seconds*60)):
		var delta:=target-actor.global_position
		delta.y=0
		var direction:=delta.normalized() if delta.length()>0.06 else Vector3.ZERO
		actor.velocity=Vector3(direction.x*2,0 if actor.is_on_floor() else actor.velocity.y-11.0/60,direction.z*2)
		actor.move_and_slide()
		await physics_frame
	return {"passed":actor.global_position.distance_to(target)<0.25,"end":arr(actor.global_position-origin)}

func capture(origin:Vector3,folder:String,tag:String,from:Vector3,towards:Vector3) -> void:
	var c:=Camera3D.new()
	root.add_child(c)
	c.global_position=origin+from
	c.look_at(origin+towards)
	c.fov=75
	c.current=true
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	if root.get_camera_3d()!=c:failures.append("capture camera replaced")
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+tag+".png"))
	c.queue_free()
'''
needle='\tawait physics_frame\n\tvar space :='
assert base.count(needle)==1
source=base.replace(needle,setup+'\n'+needle).replace('folder + "report.json"','folder + "controls-report.json"')+helpers
(HERE/'probe_controls.gd').write_text(source,encoding='utf-8')
spec=json.loads((RUN/'spec.json').read_text(encoding='utf-8'))
spec['rays'] += [{'tag':'landing','x':23.8,'z':26.5,'top':0}]
spec['shots'] = []
(HERE/'controls-spec.json').write_text(json.dumps(spec,indent=2)+'\n')
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--audio-driver','Dummy','--log-file',str(HERE/'controls-engine.log'),'--script','res://doc/book/iterations/2026-09-20-wall-exception/probe_controls.gd','--','res://doc/book/iterations/2026-09-20-wall-exception/controls-spec.json']
with (HERE/'controls-process.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
print('Control probe exit:',result.returncode)
print((HERE/'controls-process.log').read_text(encoding='utf-8')[-1300:])
if (RUN/'controls-report.json').exists():shutil.copy2(RUN/'controls-report.json',HERE/'controls-report.json')
if result.returncode==0:
    for name in ['closed.png','open.png','outside.png','reverse.png','source_manifest.json']:shutil.copy2(RUN/name,HERE/name)
raise SystemExit(result.returncode)
