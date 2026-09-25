from pathlib import Path
import subprocess,sys,shutil,json
sys.stdout.reconfigure(encoding='utf-8')
H=Path(__file__).resolve().parent;R=H.parents[3];run=R/'ada_run/encounter_pilot/Noise_Inside_Noise'
original=R/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),'Noise_Inside_Noise','--sequence','noise','--spec',str(H/'museum-spec.json')]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})

report_path=run/'report.json'
if report_path.exists():report_path.unlink()
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(H/'museum-engine.log'),'--script','res://'+(H/'probe_museum.gd').relative_to(R).as_posix(),'--','res://'+(run/'spec.json').relative_to(R).as_posix(),'--em-no-costume']
with (H/'museum-process.log').open('w',encoding='utf-8') as f:
 p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 try:code=p.wait(timeout=240)
 except subprocess.TimeoutExpired:p.kill();p.wait();code=124
print('Museum exit',code)
if report_path.exists():
 report=json.loads(report_path.read_text(encoding='utf-8'));shutil.copy2(report_path,H/'museum-runtime.json')
 for name in report['shots']:
  p=R/name.removeprefix('res://');shutil.copy2(p,H/p.name)
 print('Failures',report['failures'])
else:print((H/'museum-process.log').read_text(encoding='utf-8',errors='replace')[-2500:])
errors="SCRIPT ERROR" in (H/"museum-process.log").read_text(encoding="utf-8",errors="replace")
raise SystemExit(code or (1 if errors or not report_path.exists() or report.get("failures") else 0))
