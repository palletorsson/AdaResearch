"""Recheck the two recorded portal-entry problems in isolated real halls."""
from pathlib import Path
import json,re,shutil,subprocess,sys
from run_randomness_ghost_student import ROOT,OUT,ENGINE,res

def run(m,stage):
    run=OUT/'museum'/stage/m;run.mkdir(parents=True,exist_ok=True)
    prefix=res(run)+'/'
    source=(ROOT/'commons/scenes/endless_museum.gd').read_text(encoding='utf-8')
    for name in ['em_inventory.json','em_showing_cards.json','em_live_footprints.json','em_bake.json','em_layout_walk.json','em_adoptions.json','em_built.json','em_foes.json','em_boot_last.json','em_pack_report.json','em_basin_plan.txt']:
        src=ROOT/'ada_run'/name
        if src.exists():shutil.copy2(src,run/name)
        source=source.replace('res://ada_run/'+name,prefix+name)
    (run/'museum_snapshot.gd').write_text(source,encoding='utf-8')
    scene=(ROOT/'commons/scenes/endless_museum.tscn').read_text(encoding='utf-8')
    scene=re.sub(r' uid="[^"]+"','',scene).replace('res://commons/scenes/endless_museum.gd',prefix+'museum_snapshot.gd')
    (run/'museum_snapshot.tscn').write_text(scene,encoding='utf-8')
    control=json.loads((ROOT/'ada_run/em_control.json').read_text(encoding='utf-8-sig'))
    control.update(first_chapter='randomness',first_map=m,dollhouse=0)
    for key in ['resume_eye','resume_hall','resume_yaw','resume_pitch']:control.pop(key,None)
    (run/'control.json').write_text(json.dumps(control),encoding='utf-8')
    for name in ['necklace_hand.json','em_overrides.json']:
        src=ROOT/'ada_run'/name
        if src.exists():shutil.copy2(src,run/name)
        else:(run/name).write_text('{}')
    shutil.copy2(ROOT/'commons/data/museum/em_plan.json',run/'plan.json')
    shutil.copy2(ROOT/'commons/maps'/m/'map_data.json',run/'map_data.json')
    (run/'spec.json').write_text(json.dumps({'run':prefix,'room':m,'sequence':'randomness','stage':stage}),encoding='utf-8')
    args=[ENGINE,'--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/randomness_entries.gd','--',prefix+'spec.json']
    args[1:1]=['--headless'] if stage=='before' else ['--no-window','--rendering-method','gl_compatibility','--resolution','1280x900']
    with (run/'engine.log').open('w',encoding='utf-8') as log:
        result=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=140,creationflags=subprocess.CREATE_NO_WINDOW)
    report=json.loads((run/'report.json').read_text()) if (run/'report.json').exists() else {}
    print(m,stage,'exit',result.returncode,'checks',len(report.get('checks',[])),'failures',report.get('failures',[]),'entry',report.get('observations',{}).get('authored'),flush=True)
    return report

if __name__=='__main__':
    for m in ['Random_Space','Random_Game']:run(m,sys.argv[1] if len(sys.argv)>1 else 'before')
