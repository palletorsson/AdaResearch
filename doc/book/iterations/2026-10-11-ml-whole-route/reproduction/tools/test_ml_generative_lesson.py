"""Reconstruct only the printed Generative and carried Memory/Perception files, then run native Godot assertions."""
from pathlib import Path
import hashlib, json, re, subprocess, sys
from datetime import datetime, timezone
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-generative-a-phrase-varied'
PRINTED = OUT / 'learner/printed'

def reconstruct():
    chapters=['ML_Perception','ML_Sequence_Memory','ML_Generative']
    fence=chr(96)*3
    blocks=[]
    for chapter in chapters:
        text=(ROOT/f'commons/maps/{chapter}/tutorial.md').read_text(encoding='utf-8')
        blocks+=re.findall(r'<!-- student-code:([a-z_]+\.gd) -->\s*'+fence+r'gdscript\n(.*?)\n'+fence,text,re.S)
    assert {n for n,_ in blocks}=={'point_body.gd','pose_learner.gd','pose_study.gd','movement_learner.gd','phrase_library.gd','sequence_study.gd','phrase_generator.gd','generative_study.gd'} and len(blocks)==8
    PRINTED.mkdir(parents=True, exist_ok=True)
    sources = {}
    for name, body in blocks:
        assert 'commons/artifacts/vogue_timeline' not in body, 'Hidden production learner import'
        (PRINTED/name).write_text(body+'\n',encoding='utf-8')
        sources[name] = hashlib.sha256((PRINTED/name).read_bytes()).hexdigest()
    (OUT/'reconstruction.json').write_text(json.dumps({
        'time':datetime.now(timezone.utc).isoformat(),'method':'Author-informed exact-print reconstruction; no independent reader claim',
        'source':['commons/maps/ML_Perception/tutorial.md','commons/maps/ML_Sequence_Memory/tutorial.md','commons/maps/ML_Generative/tutorial.md'],'sha256':sources,
        'supplied':['Godot 4.6','Ada museum + XR Tools','RackTemplates button factory'],
        'expected_before_run':['carried point and both timed hand paths','fitted mean changes with source data','whole residual coefficients retain cross-hand and cross-time relationships','zero variation gives mean','same seed/data/amount repeats output','zero residuals cannot invent variation','generation never changes examples','invalid samples remain inspectable but do not preview','native scene uses the printed code'],
    },indent=2),encoding='utf-8')

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    reconstruct()
    (OUT/'tests.json').unlink(missing_ok=True)
    with (OUT/'tests-engine.log').open('w',encoding='utf-8') as log:
        try:
            p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--xr-mode','off','--audio-driver','Dummy','--path',str(ROOT),'--script','res://tools/probes/ml_generative_lesson_test.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=0x08000000)
            code=p.returncode
        except subprocess.TimeoutExpired: code=124
    lines=(OUT/'tests-engine.log').read_text(encoding='utf-8',errors='replace').splitlines()
    print('\n'.join(x for x in lines if any(t in x for t in ['GENERATIVE ','ERROR','Error','SCRIPT','at:']))[-9000:])
    if any('SCRIPT ERROR' in x for x in lines): code=code or 1
    receipt=json.loads((OUT/'tests.json').read_text()) if (OUT/'tests.json').exists() else {}
    if not receipt.get('passed'): code=code or 1
    print(f'Printed reconstruction: {len(receipt.get("checks",[]))} checks; exit {code}')
    raise SystemExit(code)
