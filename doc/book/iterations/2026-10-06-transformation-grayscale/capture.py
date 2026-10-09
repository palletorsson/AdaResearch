from pathlib import Path
import subprocess,sys,json,shutil
root=Path.cwd(); out=root/'doc/book/iterations/2026-10-06-transformation-grayscale'
rooms=json.loads((root/'commons/maps/sequences/transformation.json').read_text())['sequences']['transformation']['maps']
selected=[a for a in sys.argv[1:] if a.startswith('Trans_')]
if selected: rooms=[r for r in rooms if r in selected]
for room in rooms:
 for mode in (('after',) if '--after' in sys.argv else ('before','after')):
  cmd=[sys.executable,'-X','utf8','tools/run_encounter_probe.py',room,'--sequence','transformation','--render','--spec',str(out/f'{room}-{mode}.json'),'--probe','tools/probes/transformation_grayscale.gd']
  r=subprocess.run(cmd,capture_output=True,text=True,encoding='utf-8')
  run=root/'ada_run/encounter_pilot'/room
  dest=out/room/mode;dest.mkdir(parents=True,exist_ok=True)
  for name in ('report.json','source_manifest.json','stdout.log',mode+'.png'):
   if (run/name).exists():shutil.copy2(run/name,dest/name)
  if r.returncode:
   print(room,mode,'FAILED',r.stdout[-900:],r.stderr[-300:],flush=True);sys.exit(r.returncode)
  report=json.loads((dest/'report.json').read_text())
  print(room,mode,len(report['checks']),'checks',report['failures'],flush=True)
print('All seven halls captured before and after.',flush=True)
