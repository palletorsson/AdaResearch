"""Capture elevated views of the current CA opening in an isolated museum."""
from pathlib import Path
import argparse,json,re,shutil,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-row-with-neighbours'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output',type=Path,default=O/'layout')
parser.add_argument('--probe',default='res://tools/probes/ca_room_layout.gd')
parser.add_argument('--map',default='CA_Introduction')
args=parser.parse_args()
run=args.output.resolve(); run.mkdir(parents=True,exist_ok=True)
prefix='res://'+run.relative_to(R).as_posix()+'/'
source=(R/'commons/scenes/endless_museum.gd').read_text(encoding='utf-8')
for name in ['em_inventory.json','em_showing_cards.json','em_live_footprints.json','em_bake.json','em_layout_walk.json','em_adoptions.json','em_built.json','em_foes.json','em_boot_last.json','em_pack_report.json','em_basin_plan.txt']:
 original=R/'ada_run'/name
 if original.exists(): shutil.copy2(original,run/name)
 source=source.replace('res://ada_run/'+name,prefix+name)
(run/'museum_snapshot.gd').write_text(source,encoding='utf-8')
scene=(R/'commons/scenes/endless_museum.tscn').read_text(encoding='utf-8')
scene=re.sub(r' uid="[^"]+"','',scene).replace('res://commons/scenes/endless_museum.gd',prefix+'museum_snapshot.gd')
(run/'museum_snapshot.tscn').write_text(scene,encoding='utf-8')
control=json.loads((R/'ada_run/em_control.json').read_text(encoding='utf-8-sig'))
control.update(first_chapter='cellularautomata',first_map=args.map,dollhouse=0)
for key in ['resume_eye','resume_hall','resume_yaw','resume_pitch']: control.pop(key,None)
(run/'control.json').write_text(json.dumps(control),encoding='utf-8')
for name in ['necklace_hand.json','em_overrides.json']:
 if (R/'ada_run'/name).exists(): shutil.copy2(R/'ada_run'/name,run/name)
 else: (run/name).write_text('{}',encoding='utf-8')
shutil.copy2(R/'commons/data/museum/em_plan.json',run/'plan.json')
(run/'spec.json').write_text(json.dumps({'run':prefix,'room':args.map,'sequence':'cellularautomata'}),encoding='utf-8')
with (run/'stdout.log').open('w',encoding='utf-8') as out:
 result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--resolution','1800x1600','--audio-driver','Dummy','--log-file',str(run/'engine.log'),'--script',args.probe,'--',prefix+'spec.json'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (run/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert result.returncode==0 and not errors,(result.returncode,errors)
data=json.loads((run/'report.json').read_text(encoding='utf-8')); assert data['passed'],data['failures']
for name in ['overhead','raised-oblique']: assert (run/(name+'.png')).exists()
print(json.dumps({'checks':len(data['checks']),'passed':True,'captures':len(list(run.glob('*.png')))}))
