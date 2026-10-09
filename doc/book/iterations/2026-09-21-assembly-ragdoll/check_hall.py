from pathlib import Path
import json, math, subprocess, sys, shutil
sys.stdout.reconfigure(encoding='utf-8')
H=Path(__file__).resolve().parent;R=H.parents[3]
room='AdvancedLaboratory_Lab_Equipment_Simulation'
points=[[6.5,.05,.8],[6.3,.05,4.0],[6.3,.05,8.8],[5.3,.05,9.2],[6.3,.05,9.2],[6.5,.05,11.7]]
spec={'walks':[dict(tag='approach-'+str(i),**{'from':points[i],'to':points[i+1]},seconds=5) for i in range(len(points)-1)], 'shots':[
 dict(tag='museum-hanging',**{'from':[6.6,1.7,9.2],'look_at':[3.5,1.2,9.2]},fov=65),
 dict(tag='museum-pulled',pull=True,**{'from':[6.6,1.7,9.2],'look_at':[3.5,1.2,9.2]},fov=65),
 dict(tag='museum-released',drop=True,**{'from':[6.6,1.7,9.2],'look_at':[3.5,.6,9.2]},fov=65),
 dict(tag='museum-bodies',hang=True,**{'from':[6.2,3.8,11.6],'look_at':[6.0,1.2,6.7]},fov=88)]}
if '--quick' in sys.argv:spec['walks']=[];spec['shots']=[]
(H/'museum-spec.json').write_text(json.dumps(spec),encoding='utf-8')
original=R/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','postfoundationscrisis','--spec',str(H/'museum-spec.json')]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(R/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
base=base.replace('extends SceneTree','extends SceneTree\nconst Store=preload("res://algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd")')
base=base.replace('\tvar map_id: String = spec["room"]','\tvar map_id: String = spec["room"]\n\tset_meta(Store.PATH_KEY,folder+"bond-probe-"+str(Time.get_ticks_usec())+".json")')
base=base.replace('func run() -> void:', 'func run() -> void:\n\tOS.low_processor_usage_mode = false')
base=base.replace('\tawait physics_frame\n\tvar space :=',(H/'checks.gd.txt').read_text(encoding='utf-8')+'\n\tawait physics_frame\n\tvar space :=')
base=base.replace('\tfor row in spec.get("walks", []):','\tEngine.time_scale = 4.0\n\tfor row in spec.get("walks", []):')
base=base.replace('\t\twalker.global_position = origin + vec(row["from"])','\t\tif report.walks.is_empty(): walker.global_position = origin + vec(row["from"])')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tEngine.time_scale = 1.0\n\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):',"""
		for row in spec.get("shots", []):
			if row.get("pull",false):
				rag.grips.l_hand.on_desktop_grab(null)
				var start: Vector3=rag.grips.l_hand.global_position
				for i in range(90):
					rag.grips.l_hand.global_position=start+rag.global_basis*Vector3(-.4,.9,.0)*minf(float(i)/65,1)
					await physics_frame
			if row.get("drop",false):
				rag.grips.l_hand.on_desktop_drop(null)
				await create_timer(3.0).timeout
			if row.get("hang",false):
				rag.request_reset()
				await create_timer(.7).timeout
""")
helpers=(R/'doc/book/iterations/2026-09-20-last-halls-review/assembly-helpers.gd.txt').read_text(encoding='utf-8')
base+='\nfunc check(report: Dictionary, ok: bool, message: String) -> void:\n\treport.checks.append({"ok":ok,"message":message})\n\tif not ok: failures.append(message)\n'+helpers
base+='\nfunc same_points(a: Array,b: Array) -> bool:\n\tif a.size()!=b.size():return false\n\tfor i in range(a.size()):\n\t\tif a[i].distance_to(b[i])>.00001:return false\n\treturn true\n'
base+='\nfunc gap(rag: Node3D) -> float:\n\tvar maximum:=0.0\n\tfor link in rag.links: maximum=maxf(maximum,link.a.to_global(link.pa).distance_to(link.b.to_global(link.pb)))\n\treturn maximum\n'
(H/'probe_museum.gd').write_text(base,encoding='utf-8')
run=R/'ada_run/encounter_pilot'/room
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(H/'museum-engine.log'),'--script','res://'+(H/'probe_museum.gd').relative_to(R).as_posix(),'--','res://'+(run/'spec.json').relative_to(R).as_posix(),'--em-no-costume']
with (H/'museum-process.log').open('w',encoding='utf-8') as f:
 p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 try: code=p.wait(timeout=170)
 except subprocess.TimeoutExpired:p.kill();p.wait();code=124
print('Museum exit',code)
if (run/'report.json').exists():
 report=json.loads((run/'report.json').read_text(encoding='utf-8'));shutil.copy2(run/'report.json',H/'museum-runtime.json')
 shutil.copy2(run/'source_manifest.json',H/'source-manifest.json')
 for name in report['shots']:
  p=R/name.removeprefix('res://');shutil.copy2(p,H/p.name)
 print('Failures',report['failures'])
else:print((H/'museum-process.log').read_text(encoding='utf-8',errors='replace')[-3000:])
raise SystemExit(code)
