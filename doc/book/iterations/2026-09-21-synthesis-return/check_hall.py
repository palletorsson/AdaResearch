from pathlib import Path
import json,math,subprocess,sys,shutil
sys.stdout.reconfigure(encoding='utf-8')
H=Path(__file__).resolve().parent;R=H.parents[3];room='PostCrisis_Synthesis'
points=[[7.5,.05,.8],[7.5,.05,1.8],[10.5,.05,4],[11,.05,9.8],[9.7,.05,11.2],[7.5,.05,11.5],[4.8,.05,13.8],[7.5,.05,13.8],[10.3,.05,13.8],[7.5,.05,13.8],[7.5,.05,15.7]]
spec={'walks':[dict(tag=f'waypoint-{i}',**{'from':a,'to':b},seconds=math.ceil(math.dist(a,b)/2)+2) for i,(a,b) in enumerate(zip(points,points[1:]))],'shots':[
 dict(tag='museum-return',**{'from':[7.5,1.7,9.7],'look_at':[7.5,1.35,12.5]},fov=96),
 dict(tag='museum-ledger',**{'from':[11.5,1.6,9.1],'look_at':[11.5,1.65,10.5]},fov=64),
 dict(tag='museum-passage',**{'from':[4,2.1,11],'look_at':[9.5,1.2,12.5]},fov=78),
 dict(tag='museum-hall',**{'from':[13.4,5.2,8.8],'look_at':[7.5,1.1,12]},fov=75)]}
(H/'museum-spec.json').write_text(json.dumps(spec),encoding='utf-8')
original=R/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','postfoundationscrisis','--spec',str(H/'museum-spec.json')]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(R/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
base=base.replace('extends SceneTree','extends SceneTree\nconst Store=preload("res://algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd")')
base=base.replace('func run() -> void:','func run() -> void:\n\tOS.low_processor_usage_mode=false')
base=base.replace('\tvar map_id: String = spec["room"]','''
	var map_id: String = spec["room"]
	var pose_path: String=folder+"pose-probe.json"
	set_meta(Store.PATH_KEY,pose_path)
	# A unique, nonexistent path avoids reading or replacing a user's saved pose.
	pose_path=folder+"pose-probe-"+str(Time.get_ticks_usec())+".json"
	set_meta(Store.PATH_KEY,pose_path)
''')
base=base.replace('\tawait physics_frame\n\tvar space :=',(H/'checks.gd.txt').read_text(encoding='utf-8')+'\n\tawait physics_frame\n\tvar space :=')
base=base.replace('\tfor row in spec.get("walks", []):','\tEngine.time_scale=4\n\tfor row in spec.get("walks", []):')
base=base.replace('\t\twalker.global_position = origin + vec(row["from"])','\t\tif report.walks.is_empty():walker.global_position = origin + vec(row["from"])')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tEngine.time_scale=1\n\tif is_instance_valid(walker):walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base+='''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok:failures.append(message)

func take_view(report: Dictionary, folder: String, tag: String, from: Vector3, to: Vector3, fov: float) -> void:
	var camera:=Camera3D.new()
	root.add_child(camera)
	camera.global_position=from
	camera.look_at(to)
	camera.fov=fov
	camera.current=true
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	var output:=folder+tag+".png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	report.shots.append(output)
	camera.queue_free()
'''
(H/'probe_museum.gd').write_text(base,encoding='utf-8')
run=R/'ada_run/encounter_pilot'/room
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(H/'museum-engine.log'),'--script','res://'+(H/'probe_museum.gd').relative_to(R).as_posix(),'--','res://'+(run/'spec.json').relative_to(R).as_posix(),'--em-no-costume']
with (H/'museum-process.log').open('w',encoding='utf-8') as out:
 p=subprocess.Popen(cmd,stdout=out,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 try:code=p.wait(timeout=170)
 except subprocess.TimeoutExpired:p.kill();p.wait();code=124
print('Museum exit',code)
if (run/'report.json').exists():
 d=json.loads((run/'report.json').read_text(encoding='utf-8'));shutil.copy2(run/'report.json',H/'museum-runtime.json')
 shutil.copy2(run/'source_manifest.json',H/'source-manifest.json')
 for name in d['shots']:shutil.copy2(R/name.removeprefix('res://'),H/Path(name).name)
 print('Failures',d['failures'])
else:print((H/'museum-process.log').read_text(encoding='utf-8',errors='replace')[-2500:])
raise SystemExit(code)
