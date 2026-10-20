"""Stage an isolated copy of the current museum, run native probes, publish evidence."""
from pathlib import Path
import argparse
import json
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-10-jacquard-cards-and-layers'
STAGE = ROOT/'ada_run/jacquard_review'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
    parser.add_argument('--museum-only', action='store_true')
    parser.add_argument('--chain', action='store_true', help='Capture the hanging-chain revision separately')
    parser.add_argument('--samples', action='store_true', help='Verify six selectable woven samples')
    args = parser.parse_args()
    out = ROOT/'doc/book/iterations/2026-10-10-jacquard-hanging-chain' if args.chain else OUT
    if args.samples:
        out = ROOT/'doc/book/iterations/2026-10-10-six-woven-patterns'
    out.mkdir(parents=True, exist_ok=True)
    STAGE.mkdir(parents=True, exist_ok=True)
    for ext in ['gd','tscn']:
        text=(ROOT/('commons/scenes/endless_museum.'+ext)).read_text(encoding='utf-8-sig')
        if ext=='tscn':
            # A snapshot must not impersonate the real resource through its UID.
            text=re.sub(r' uid="uid://[^"]+"','',text)
            text=text.replace('res://commons/scenes/endless_museum.gd','res://ada_run/jacquard_review/museum_snapshot.gd')
        (STAGE/('museum_snapshot.'+ext)).write_text(text,encoding='utf-8')
    for src,dest in [('commons/data/museum/em_plan.json','plan.json'),('commons/data/museum/em_overrides.json','em_overrides.json'),('ada_run/necklace_hand.json','necklace_hand.json')]:
        if (ROOT/src).exists():shutil.copy2(ROOT/src,STAGE/dest)
    (STAGE/'control.json').write_text(json.dumps({'first_chapter':'tiling','first_map':'Symmetry_Seventeen','gate_open':1.0,'grid_pack':0.0,'dollhouse':0}),encoding='utf-8')
    jobs=[] if args.museum_only else [('runtime','jacquard_weaver_test')]
    if args.samples and not args.museum_only:
        jobs.append(('samples','jacquard_samples_test'))
    jobs.append(('museum','jacquard_museum_test'))
    for kind,script in jobs:
        with (out/(kind+'-log.txt')).open('w',encoding='utf-8') as log:
            result=subprocess.run([args.godot,'--path',str(ROOT),'--xr-mode','off','--no-window','--audio-driver','Dummy','--script','res://tools/probes/'+script+'.gd','--','--capture']+(['--chain'] if args.chain else [])+(['--samples'] if args.samples else []),cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=115,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
        print(kind,'exit',result.returncode,flush=True)
        if result.returncode:raise SystemExit(result.returncode)
    if not args.chain and not args.samples:
        subprocess.run([sys.executable,str(ROOT/'tools/publish_jacquard_review.py')],cwd=ROOT,check=True)


if __name__=='__main__':main()
