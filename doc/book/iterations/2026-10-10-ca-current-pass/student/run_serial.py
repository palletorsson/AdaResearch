from pathlib import Path
import subprocess, json, datetime, hashlib, sys, re
ROOT=Path(__file__).resolve().parent
ENGINE=Path('C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
ORDER=json.loads((ROOT.parent/'packet/order.json').read_text())
BASE=[str(ENGINE),'--path',str(ROOT),'--no-window','--rendering-method','gl_compatibility','--xr-mode','off','--audio-driver','Dummy']
RESULTS=ROOT/'results.json'
results=json.loads(RESULTS.read_text()) if RESULTS.exists() else {'scope':'AI reconstruction and transfer; no physical headset or human-learning evidence','runs':{}}

def execute(args, folder, timeout=60):
    folder.mkdir(parents=True,exist_ok=True)
    command=BASE+['--log-file',str(folder/'engine.log')]+args
    (folder/'command.json').write_text(json.dumps(command,indent=2))
    start=datetime.datetime.now(datetime.timezone.utc).isoformat()
    try:
        p=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,timeout=timeout,creationflags=subprocess.CREATE_NO_WINDOW)
        exitcode=p.returncode; stdout=p.stdout; stderr=p.stderr; expired=False
    except subprocess.TimeoutExpired as ex:
        exitcode=124; stdout=ex.stdout or ''; stderr=ex.stderr or ''; expired=True
        if isinstance(stdout,bytes): stdout=stdout.decode(errors='replace')
        if isinstance(stderr,bytes): stderr=stderr.decode(errors='replace')
    (folder/'stdout.log').write_text(stdout,encoding='utf-8')
    (folder/'stderr.log').write_text(stderr,encoding='utf-8')
    engine=(folder/'engine.log').read_text(encoding='utf-8',errors='replace') if (folder/'engine.log').exists() else ''
    errors=[line for line in (stdout+'\n'+stderr+'\n'+engine).splitlines() if re.search(r'(?:SCRIPT ERROR|ERROR:|Parse Error|STUDENT ASSERTION)',line)]
    record={'started_utc':start,'engine_exit_code':exitcode,'timeout':expired,'errors':list(dict.fromkeys(errors)),'latest_log':str(folder/'engine.log'),'stdout':str(folder/'stdout.log'),'stderr':str(folder/'stderr.log')}
    record['effective_exit_code']=exitcode if exitcode else (1 if errors else 0)
    return record

if '--import' in sys.argv:
    rec=execute(['--editor','--quit','--','--no-bridges'],ROOT/'runs/import_01',90)
    results['import']=rec; RESULTS.write_text(json.dumps(results,indent=2))
    print(json.dumps(rec,indent=2)); sys.exit(rec['effective_exit_code'])

selected=ORDER if len(sys.argv)==1 or sys.argv[1]=='all' else sys.argv[1].split(',')
for hall in selected:
    for variant in ('original','variation'):
        key=hall+'/'+variant
        if '--remaining' in sys.argv and results['runs'].get(key,{}).get('latest',{}).get('effective_exit_code') == 0:
            continue
        previous=results['runs'].get(key,{}).get('attempts',[])
        run_id=f'run_{len(previous)+1:02d}'
        folder=ROOT/hall/variant/'runs'/run_id
        rec=execute(['--','--no-bridges','--hall',hall,'--variant',variant,'--run-id',run_id],folder,45)
        checkfile=folder/'checks.json'
        rec['checks_file']=str(checkfile)
        rec['checks']=json.loads(checkfile.read_text()) if checkfile.exists() else None
        if rec['checks'] is None or not rec['checks']['passed']: rec['effective_exit_code']=rec['effective_exit_code'] or 1
        rec['source_hashes']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/hall/variant).glob('*.gd')}
        rec['test_sha256']=hashlib.sha256((ROOT/'tests'/f'{hall}.gd').read_bytes()).hexdigest()
        rec['harness_sha256']=hashlib.sha256((ROOT/'runner.gd').read_bytes()).hexdigest()
        (folder/'run.json').write_text(json.dumps(rec,indent=2))
        results['runs'][key]={'hall':hall,'variant':variant,'latest':rec,'attempts':previous+[rec]}
        RESULTS.write_text(json.dumps(results,indent=2))
        print(hall,variant,'exit',rec['effective_exit_code'],'checks',len(rec['checks']['checks']) if rec['checks'] else 0,'errors',rec['errors'][:6],flush=True)
        if rec['effective_exit_code'] and '--continue' not in sys.argv: sys.exit(rec['effective_exit_code'])
sys.exit(0 if all(v['latest']['effective_exit_code']==0 for v in results['runs'].values()) else 1)
