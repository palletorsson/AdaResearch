"""Run real Godot checks and photograph the installed station in an isolated museum."""
from pathlib import Path
import argparse,json,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-cutting-a-suit'
STAGE=ROOT/'ada_run/garment_tailor_review'
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--museum-only',action='store_true');parser.add_argument('--tests-only',action='store_true');args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True);STAGE.mkdir(parents=True,exist_ok=True)
    for ext in ['gd','tscn']:
        data=(ROOT/f'commons/scenes/endless_museum.{ext}').read_text(encoding='utf-8-sig')
        if ext=='tscn':
            data=re.sub(r' uid="uid://[^"]+"','',data).replace('res://commons/scenes/endless_museum.gd','res://ada_run/garment_tailor_review/museum_snapshot.gd')
        else:
            data=data.replace('add_child(_wardrobe)','_wardrobe.set("appearance_save_path", "res://doc/book/iterations/2026-10-10-cutting-a-suit/museum-appearance.cfg")\n\tadd_child(_wardrobe)')
        (STAGE/f'museum_snapshot.{ext}').write_text(data,encoding='utf-8')
    for src,dest in [('commons/data/museum/em_plan.json','plan.json'),('commons/data/museum/em_overrides.json','em_overrides.json'),('ada_run/necklace_hand.json','necklace_hand.json')]:
        if (ROOT/src).exists():shutil.copy2(ROOT/src,STAGE/dest)
    (STAGE/'control.json').write_text(json.dumps({'first_chapter':'tiling','first_map':'Ribbon_Patterns_03','gate_open':1.0,'grid_pack':0.0,'dollhouse':0}),encoding='utf-8')
    jobs=[] if args.museum_only else ['test']
    if not args.tests_only:jobs.append('museum')
    for job in jobs:
        cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--headless' if job=='test' else '--no-window','--script',f'res://tools/probes/garment_tailor_{job}.gd']
        log=OUT/f'{job}-log.txt'
        with log.open('w',encoding='utf-8') as f:r=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=125,creationflags=subprocess.CREATE_NO_WINDOW)
        print(job,'exit',r.returncode,flush=True)
        errors=[line for line in log.read_text(encoding='utf-8').splitlines() if 'SCRIPT ERROR' in line or line.startswith('FAIL ')]
        for line in errors:print(line)
        if r.returncode or errors:raise SystemExit(r.returncode or 1)
if __name__=='__main__':main()
