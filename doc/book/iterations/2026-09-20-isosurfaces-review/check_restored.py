"""Check that the restored halls actually instantiate their named encounters."""
from pathlib import Path
import json
import subprocess
import sys

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
targets={'ISO_CaveGeneration':'marchingcubes_cave','ISO_AnimatedNoise':'animated_noise_explorer','ISO_ImplicitModeling':'implicit_surface_modeling','ISO_RhizomeBody':'rhizome_inside'}
if len(sys.argv)>1: targets={k:v for k,v in targets.items() if k in sys.argv[1:]}
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
needle='\tawait physics_frame\n\tvar space :='
check='''
	var required: String = spec["required"]
	if not nodes.has(required): failures.append("Restored hall has no " + required)
	for token in spec.get("scales", {}):
		if not nodes.has(token) or not nodes[token].scale.is_equal_approx(Vector3.ONE * float(spec.scales[token])):
			failures.append("Incorrect display scale: " + token)
	if nodes.has("iso_specimen_stage") and not nodes.iso_specimen_stage.ready_for_display:
		failures.append("Specimen staging did not bind both retained artifacts")
	var dims: Array = spec["dimensions"]
	for token in spec.get("scales", {}):
		if not nodes.has(token): continue
		var bound: AABB = museum.call("_seat_extent",nodes[token])
		bound.position -= origin
		if bound.position.x < 0.9 or bound.end.x > float(dims[0])-0.9 or bound.position.z < 0.9 or bound.end.z > float(dims[1])-0.9:
			failures.append("Specimen exceeds the hall's interior: " + token)
	report["required_artifact"] = required
	report["required_present"] = nodes.has(required)
'''
probe=HERE/'probe_restored.gd'
probe.write_text(base.replace(needle,check+needle),encoding='utf-8')
out=json.loads((HERE/'restored-checks.json').read_text()) if (HERE/'restored-checks.json').exists() else []
out=[r for r in out if r['map'] not in targets]
for room,token in targets.items():
    scales={
        'ISO_CaveGeneration':{'marchingcave':0.02,'marchingcubes_cave':0.02},
        'ISO_AnimatedNoise':{'mc_base':0.02,'animated_noise_explorer':1.5},
        'ISO_ImplicitModeling':{'implicit_surface_modeling':1.0},
        'ISO_RhizomeBody':{'rhizome_inside':1.0},
    }[room]
    dims=json.loads((ROOT/'commons/maps'/room/'map_data.json').read_text(encoding='utf-8'))['map_info']['dimensions']
    w,h=dims['width'],dims['depth']
    walk_x=2.5 if room in ['ISO_ImplicitModeling','ISO_RhizomeBody'] else w//2+0.5
    shot={'tag':'restored','from':[w/2,3.2,3],'look_at':[w/2,1.5,h*0.58],'fov':80}
    if room=='ISO_RhizomeBody':shot.update({'from':[4,2,4],'look_at':[17,2,17]})
    spec=HERE/(room+'-spec.json');spec.write_text(json.dumps({'required':token,'dimensions':[w,h],'scales':scales,'shots':[shot],'walks':[{'tag':'gallery passage','from':[walk_x,0.1,3.5],'to':[walk_x,0.1,h-3.5],'seconds':(h-7)/2+1}]}),encoding='utf-8')
    sys.argv=[str(original),room,'--sequence','isosurfaces','--spec',str(spec)]
    exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
    run=ROOT/'ada_run/encounter_pilot'/room
    if (run/'report.json').exists(): (run/'report.json').unlink()
    cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(room+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix()]
    with (HERE/(room+'-process.log')).open('w',encoding='utf-8') as log:
        try: code=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=110,creationflags=subprocess.CREATE_NO_WINDOW).returncode
        except subprocess.TimeoutExpired: code=124
    record={'map':room,'exit':code}
    if (run/'report.json').exists():
        data=json.loads((run/'report.json').read_text(encoding='utf-8'))
        record.update(present=data.get('required_present'),failures=data.get('failures'),walks=data['walks'],artifacts=[{k:a[k] for k in ['token','position','scale','bounds_position','bounds_size']} for a in data['artifacts'] if a['token'] in scales])
        import shutil
        if (run/'restored.png').exists():shutil.copy2(run/'restored.png',HERE/(room+'.png'))
    out.append(record)
    (HERE/'restored-checks.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
    print(room,record,flush=True)
