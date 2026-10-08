"""Capture the placed monitors in unchanged museum code with isolated output files."""
from pathlib import Path
import argparse,json,os,re,shutil,subprocess
import build_spine_films as build
ROOT=build.ROOT;OUT=build.OUT;RUN=build.RUN

def capture(item):
    run=RUN/'museum'/item['id'];run.mkdir(parents=True,exist_ok=True)
    out=OUT/item['id'];out.mkdir(parents=True,exist_ok=True)
    prefix='res://'+run.relative_to(ROOT).as_posix()+'/'
    source=(ROOT/'commons/scenes/endless_museum.gd').read_text(encoding='utf-8')
    for name in ['em_inventory.json','em_showing_cards.json','em_live_footprints.json','em_bake.json','em_layout_walk.json','em_adoptions.json','em_built.json','em_foes.json','em_boot_last.json','em_pack_report.json','em_basin_plan.txt']:
        original=ROOT/'ada_run'/name
        if original.exists():shutil.copy2(original,run/name)
        source=source.replace('res://ada_run/'+name,prefix+name)
    (run/'museum_snapshot.gd').write_text(source,encoding='utf-8')
    scene=(ROOT/'commons/scenes/endless_museum.tscn').read_text(encoding='utf-8')
    scene=re.sub(r' uid="[^"]+"','',scene).replace('res://commons/scenes/endless_museum.gd',prefix+'museum_snapshot.gd')
    (run/'museum_snapshot.tscn').write_text(scene,encoding='utf-8')
    control=build.read(ROOT/'ada_run/em_control.json')
    control.update(first_chapter=item['sequence'],first_map=item['map'],dollhouse=0)
    for key in ['resume_eye','resume_hall','resume_yaw','resume_pitch']:control.pop(key,None)
    build.write(run/'control.json',control)
    for name in ['necklace_hand.json','em_overrides.json']:
        if (ROOT/'ada_run'/name).exists():shutil.copy2(ROOT/'ada_run'/name,run/name)
        else:build.write(run/name,{})
    shutil.copy2(ROOT/'ada_run/em_plan.json',run/'plan.json')
    build.write(run/'spec.json',{'run':prefix,'item':item,'output':'res://'+out.relative_to(ROOT).as_posix()+'/'})
    cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--script','res://tools/probes/spine_film_museum.gd','--',prefix+'spec.json']
    try:
        with (run/'run.log').open('w',encoding='utf-8') as log:
            result=subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=170,creationflags=subprocess.CREATE_NO_WINDOW)
    except subprocess.TimeoutExpired:
        print('TIMEOUT',item['id'],flush=True);return False
    log=(run/'run.log').read_text(encoding='utf-8',errors='replace')
    errors=[s for s in log.splitlines() if any(k in s for k in ['SCRIPT ERROR','Parse Error','FAIL ','BLOCKER','MONITOR_POSITION'])]
    print(item['id'],result.returncode,('\n'.join(errors)).encode('ascii',errors='backslashreplace').decode('ascii'),flush=True)
    return result.returncode==0 and 'SCRIPT ERROR' not in log

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--only',nargs='+');args=parser.parse_args()
    entries=build.read(build.BASE/'catalog.json')
    placements={p['id']:p for p in build.read(OUT/'placements.json')}
    for item in entries:
        if item['id'] in placements:
            item['view_offset']=placements[item['id']]['view_offset']
            item['view_fov']=placements[item['id']].get('view_fov',68)
    good=True
    for item in entries:
        if not args.only or item['id'] in args.only:good=capture(item) and good
    raise SystemExit(0 if good else 1)
