"""Native behavior/geometry assertions plus real Mobile/Forward+/GL screenshots."""
from pathlib import Path
import json, os, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-crawler-sight'
OUT.mkdir(parents=True,exist_ok=True)
if '--staged' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for source in (ROOT/'commons/void').glob('*'):
    if source.suffix in {'.gd','.gdshader'}: shutil.copy2(source,stage/'commons/void'/source.name)
shutil.copy2(ROOT/'tools/probes/void_crawler_sight_probe.gd',stage/'tools/probes/void_crawler_sight_probe.gd')
godot=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
capture='--capture' in sys.argv
renderer=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--renderer=')),'mobile')
folder=OUT/(renderer if capture else 'behavior'); folder.mkdir(exist_ok=True)
with (folder/'engine.log').open('w',encoding='utf-8') as log:
    args=['--no-window','--rendering-method',renderer] if capture else ['--headless']
    result=subprocess.run([godot,*args,'--fixed-fps','60','--path',str(stage),'--xr-mode','off',
        '--script','res://tools/probes/void_crawler_sight_probe.gd','--','--out='+str(folder),
        *(['--capture'] if capture else [])],stdout=log,stderr=log,timeout=180,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(folder/'engine.log').read_text(encoding='utf-8',errors='replace')
if result.returncode or 'SCRIPT ERROR' in log or '\nERROR:' in log:
    lines=log.splitlines()
    relevant=[line for i,line in enumerate(lines) if any('SCRIPT ERROR' in s or s.startswith('ERROR:') for s in lines[max(0,i-1):i+1])]
    raise SystemExit('\n'.join(relevant[:50]) or log[-2000:])
data=json.loads((folder/'checks.json').read_text()); assert data['passed'], data
if capture:
    from PIL import Image, ImageChops, ImageStat, ImageFilter
    pictures={name:Image.open(folder/(name+'.png')).convert('RGB') for name in ['clear','bite','repeated-bites','healed']}
    difference=lambda a,b:sum(ImageStat.Stat(ImageChops.difference(a,b)).mean)/3
    edge=lambda im:ImageStat.Stat(im.convert('L').filter(ImageFilter.FIND_EDGES).crop((10,10,1590,990))).mean[0]
    scores={name:{'difference':difference(pictures['clear'],im),'edge_energy':edge(im)} for name,im in pictures.items()}
    pixel_checks=[
        {'name':'A bite visibly changes rendered pixels','passed':scores['bite']['difference']>.5},
        {'name':'Repeated bites change the image more','passed':scores['repeated-bites']['difference']>scores['bite']['difference']},
        {'name':'Blur reduces sharp edge detail','passed':scores['repeated-bites']['edge_energy']<scores['bite']['edge_energy']<scores['clear']['edge_energy']},
        {'name':'Healing restores the original image','passed':scores['healed']['difference']<.1},
    ]
    data['checks'].extend(pixel_checks); data['pixel_scores']=scores
    data['passed']=all(c['passed'] for c in data['checks'])
    (folder/'checks.json').write_text(json.dumps(data,indent=2))
    assert data['passed'], data
print(f'{folder.name}: {len(data["checks"])} checks passed',flush=True)
