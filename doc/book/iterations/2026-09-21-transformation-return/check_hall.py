from pathlib import Path
import json,subprocess,sys,shutil
sys.stdout.reconfigure(encoding='utf-8')
H=Path(__file__).resolve().parent;R=H.parents[3]
room='Trans_Rotation'
(H/'museum-spec.json').write_text('{"walks":[],"shots":[]}',encoding='utf-8')
original=R/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','transformation','--spec',str(H/'museum-spec.json')]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(R/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
base=base.replace('func run() -> void:', 'func run() -> void:\n\tOS.low_processor_usage_mode = false')
base=base.replace('\tawait physics_frame\n\tvar space :=',(H/'checks.gd.txt').read_text(encoding='utf-8')+'\n\tawait physics_frame\n\tvar space :=')
base=base.replace('\t\twalker.global_position = origin + vec(row["from"])','\t\tif report.walks.is_empty(): walker.global_position = origin + vec(row["from"])')
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):\n\t\t\tstudy.set_shape("triangle" if row.state=="triangle-boundary" else "cube")\n\t\t\tstudy.set_envelope(row.state!="cube")\n\t\t\tstudy.seek(1.5)\n\t\t\tif is_instance_valid(walker): walker.hide()')
base+='\nfunc check(report: Dictionary, ok: bool, message: String) -> void:\n\treport.checks.append({"ok":ok,"message":message})\n\tif not ok: failures.append(message)\n'
(H/'probe_museum.gd').write_text(base,encoding='utf-8')
run=R/'ada_run/encounter_pilot'/room
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--resolution','1280x900','--audio-driver','Dummy','--log-file',str(H/'museum-engine.log'),'--script','res://'+(H/'probe_museum.gd').relative_to(R).as_posix(),'--','res://'+(run/'spec.json').relative_to(R).as_posix(),'--em-no-costume']
with (H/'museum-process.log').open('w',encoding='utf-8') as f:
 startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
 p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=startup)
 try:code=p.wait(timeout=150)
 except subprocess.TimeoutExpired:p.kill();p.wait();code=124
print('Museum exit',code)
if (run/'report.json').exists():
 report=json.loads((run/'report.json').read_text(encoding='utf-8'));shutil.copy2(run/'report.json',H/'museum-runtime.json');shutil.copy2(run/'source_manifest.json',H/'source-manifest.json')
 for name in report.get('shots',[]):
  p=R/name.removeprefix('res://');shutil.copy2(p,H/p.name)
 print('Checks',len(report.get('checks',[])),'walks',len(report.get('walks',[])),'Failures',report['failures'])
else:print((H/'museum-process.log').read_text(encoding='utf-8',errors='replace')[-3000:])
raise SystemExit(code)
