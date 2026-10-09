from pathlib import Path
import subprocess,sys,shutil,json
root=Path.cwd();out=root/'doc/book/iterations/2026-10-06-transformation-grayscale'
r=subprocess.run([sys.executable,'-X','utf8',str(out/'capture.py'),'--after']);assert r.returncode==0
for room,probe in [('Trans_Rotation','transformation_encounters.gd'),('Trans_Introduction','transformation_encounters.gd'),('Trans_Translation','translation_paths.gd')]:
 r=subprocess.run([sys.executable,'-X','utf8','tools/run_encounter_probe.py',room,'--sequence','transformation','--render','--probe','tools/probes/'+probe],capture_output=True,text=True,encoding='utf-8')
 run=root/'ada_run/encounter_pilot'/room;dest=out/room/'behaviour';dest.mkdir(parents=True,exist_ok=True)
 for name in ('report.json','source_manifest.json','stdout.log'):
  if (run/name).exists():shutil.copy2(run/name,dest/name)
 assert r.returncode==0,(room,r.stdout[-1000:])
 d=json.loads((dest/'report.json').read_text());assert d['passed'],d['failures'];print(room,'behaviour',len(d['checks']),'passed',flush=True)
 for name in ('order-comparison.png','marked-sweep.png','translation-exit-terrace.png','bank-moved.png'):
  if (run/name).exists():shutil.copy2(run/name,dest/name)
subprocess.run([sys.executable,'-X','utf8',str(out/'publish.py')],check=True)
