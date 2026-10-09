from pathlib import Path
import json, math, subprocess, sys, shutil
sys.stdout.reconfigure(encoding='utf-8')
H=Path(__file__).resolve().parent;R=H.parents[3]
room='SpeculativeComputation_Collective_Knowledge'
points=[[6.5,.05,.8],[6.5,.05,3.7],[4.5,.05,3.7],[4.5,.05,7.6],[7.4,.05,7.6],[9.5,.05,7.6],[11.4,.05,8.5],[11.4,.05,10.5],[9.5,.05,11.4],[7.4,.05,10.5],[6.5,.05,10.5],[6.5,.05,12.65]]
spec={'walks':[dict(tag=f'waypoint-{i}',**{'from':a,'to':b},seconds=math.ceil(math.dist(a,b)/2)+2) for i,(a,b) in enumerate(zip(points,points[1:]))], 'shots':[
 dict(tag='museum-hall',**{'from':[11.4,4.0,1.3],'look_at':[5.8,1.1,7.1]},fov=84),
 dict(tag='museum-table',**{'from':[7.2,1.7,7.5],'look_at':[9.5,1.05,9.5]},fov=75),
 dict(tag='museum-classifier',**{'from':[11.45,1.55,9.5],'look_at':[10.72,1.1,9.5]},fov=76),
 dict(tag='museum-gates',**{'from':[6.0,1.7,5.5],'look_at':[2.5,1.1,5.5]},fov=108)]}
(H/'museum-spec.json').write_text(json.dumps(spec),encoding='utf-8')
original=R/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','postfoundationscrisis','--spec',str(H/'museum-spec.json')]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(R/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
base=base.replace('func run() -> void:', 'func run() -> void:\n\tOS.low_processor_usage_mode = false')
base=base.replace('\tawait physics_frame\n\tvar space :=',(H/'checks.gd.txt').read_text(encoding='utf-8')+'\n\tawait physics_frame\n\tvar space :=')
base=base.replace('\tfor row in spec.get("walks", []):','\tEngine.time_scale = 4.0\n\tfor row in spec.get("walks", []):')
base=base.replace('\t\twalker.global_position = origin + vec(row["from"])','\t\tif report.walks.is_empty(): walker.global_position = origin + vec(row["from"])')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tEngine.time_scale = 1.0\n\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base+='\nfunc check(report: Dictionary, ok: bool, message: String) -> void:\n\treport.checks.append({"ok":ok,"message":message})\n\tif not ok: failures.append(message)\n'
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
