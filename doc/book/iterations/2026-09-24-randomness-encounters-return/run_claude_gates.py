from pathlib import Path
import subprocess,sys,json
sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
si=subprocess.STARTUPINFO();si.dwFlags |= subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
names=['probe_ten_print_hall','probe_ten_print_walkable','probe_random_cubes','probe_rotation_study','probe_ca_stop_and_fit']
names=sys.argv[1:] or names
results=json.loads((OUT/'claude-gates.json').read_text(encoding='utf-8')) if (OUT/'claude-gates.json').exists() else []
results=[r for r in results if r['gate'] not in names]
for name in names:
 with (OUT/(name+'.log')).open('w',encoding='utf-8') as log:
  p=subprocess.Popen(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://commons/testing/'+name+'.gd']+(['--fixed-fps','120'] if name=='probe_random_cubes' else []),stdout=log,stderr=subprocess.STDOUT,startupinfo=si,creationflags=subprocess.CREATE_NO_WINDOW)
  print(name,'owned PID',p.pid,flush=True)
  try: code=p.wait(timeout=600)
  except subprocess.TimeoutExpired:p.terminate();p.wait(timeout=10);code=124
 s=(OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace')
 result={'gate':name,'exit_code':code,'script_error':'SCRIPT ERROR' in s,'failure_lines':[l for l in s.splitlines() if 'FAIL' in l and '0 failed' not in l]}
 results.append(result);print(result,flush=True)
 (OUT/'claude-gates.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
raise SystemExit(0 if all(r['exit_code']==0 and not r['script_error'] and not r['failure_lines'] for r in results) else 1)
