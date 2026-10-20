"""Reconstruct only the printed Classification files, then run native Godot assertions."""
from pathlib import Path
import hashlib, json, re, subprocess, sys
from datetime import datetime, timezone
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-classification-a-group-without-a-name'
PRINTED = OUT / 'learner/printed'

def reconstruct():
    chapters=['ML_Classification']
    fence=chr(96)*3
    blocks=[]
    for chapter in chapters:
        text=(ROOT/f'commons/maps/{chapter}/tutorial.md').read_text(encoding='utf-8')
        blocks+=re.findall(r'<!-- student-code:([a-z_]+\.gd) -->\s*'+fence+r'gdscript\n(.*?)\n'+fence,text,re.S)
    assert {n for n,_ in blocks}=={'cluster_model.gd','cluster_study.gd'} and len(blocks)==2
    carried=ROOT/'doc/book/studies/ml-gradient/point_body.gd'
    blocks.append(('point_body.gd',carried.read_text(encoding='utf-8').rstrip()))
    PRINTED.mkdir(parents=True, exist_ok=True)
    sources = {}
    for name, body in blocks:
        assert 'algorithms/machinelearning' not in body, 'Hidden production learner import'
        (PRINTED/name).write_text(body+'\n',encoding='utf-8')
        sources[name] = hashlib.sha256((PRINTED/name).read_bytes()).hexdigest()
    (OUT/'reconstruction.json').write_text(json.dumps({
        'time':datetime.now(timezone.utc).isoformat(),'method':'Author-informed exact-print reconstruction; no independent reader claim',
        'source':['commons/maps/ML_Classification/tutorial.md',str(carried.relative_to(ROOT))],'sha256':sources,
        'supplied':['Godot 4.6','Ada museum + XR Tools','RackTemplates button factory','PointBody unchanged from Gradient Landscape'],
        'expected_before_run':['midpoint fixture assignment [0,0,1], means [-.4,0] and [.8,0], SSE .64 then .32','changed midpoint .2 assigns [0,1,1], SSE .18 after mean','empty centres retained','fixed-case alternating steps do not increase SSE','manual edit invalidates groups without moving observations','all controls keep one PointBody','production readout is pre-update unsquared distance'],
    },indent=2),encoding='utf-8')

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    reconstruct()
    (OUT/'tests.json').unlink(missing_ok=True)
    with (OUT/'tests-engine.log').open('w',encoding='utf-8') as log:
        try:
            p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--xr-mode','off','--audio-driver','Dummy','--path',str(ROOT),'--script','res://tools/probes/ml_classification_lesson_test.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=0x08000000)
            code=p.returncode
        except subprocess.TimeoutExpired: code=124
    lines=(OUT/'tests-engine.log').read_text(encoding='utf-8',errors='replace').splitlines()
    print('\n'.join(x for x in lines if any(t in x for t in ['CLASSIFICATION ','ERROR','Error','SCRIPT','at:']))[-9000:])
    if any('SCRIPT ERROR' in x for x in lines): code=code or 1
    receipt=json.loads((OUT/'tests.json').read_text(encoding='utf-8')) if (OUT/'tests.json').exists() else {}
    if not receipt.get('passed'): code=code or 1
    print(f'Printed reconstruction: {len(receipt.get("checks",[]))} checks; exit {code}')
    raise SystemExit(code)
