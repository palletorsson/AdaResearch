from pathlib import Path
import json,subprocess,sys,shutil

H=Path(__file__).resolve().parent;R=H.parents[3]
room=sys.argv[1]
assembly=room.startswith('Advanced')
spec={'required':'MolecularDesigner' if assembly else 'accountability_ledger','walks':[], 'shots':[]}
points=([[6.5,.1,.8],[6.5,.1,2.5],[3,.1,3],[3,.1,5.5],[9.5,.1,5.5],[9.5,.1,9],[6.5,.1,10.7],[6.5,.1,11.6]] if assembly else [[7.5,.1,.8],[7.5,.1,1.6],[3.5,.1,1.6],[2.5,.1,1.4],[4.8,.1,3.6],[4.8,.1,12],[7.5,.1,13],[7.5,.1,15.6]])
for i in range(len(points)-1):spec['walks'].append({'tag':'segment-'+str(i+1),'from':points[i],'to':points[i+1],'seconds':max(2,abs(points[i+1][2]-points[i][2])+abs(points[i+1][0]-points[i][0]))})
for mode in (['float','VRBody','Chair'] if assembly else ['ledger','later','gallery']):spec['shots'].append({'tag':('assembly-' if assembly else 'synthesis-')+mode.lower(),'mode':mode})
path=H/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=R/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','postfoundationscrisis','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(R/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition=(H/('assembly-checks.gd.txt' if assembly else 'synthesis-checks.gd.txt')).read_text(encoding='utf-8')
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'''\tvar gate: Dictionary=museum.get("_gate")
	if not gate.is_empty():
		gate.scanner.palm_scanned.emit()
		museum.get("_mod_gate").call("step_open",gate,10.0)
		await physics_frame
	await physics_frame
	var space :=''')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','''
		for row in spec.get("shots", []):
			prepare_view(study,str(row.mode))
			await process_frame
			row["from"]=arr(study.to_global(Vector3(0,1.25,2.2))-origin)
			row["look_at"]=arr(study.to_global(Vector3(0,.85,0))-origin)
			row["fov"]=65
			if str(row.tag).begins_with("synthesis"):
				row["fov"]=85
				row["from"]=arr(study.to_global(Vector3(0,.57,.68))-origin)
				row["look_at"]=arr(study.to_global(Vector3(0,.57,0))-origin)
				if row.mode=="gallery":
					row["from"]=[4.8,1.7,5.5]
					row["look_at"]=[8,1.3,11]
			report.get_or_add("states",[]).append(capture_state(study,str(row.mode)))
''')
base+='''
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
'''+(H/('assembly-helpers.gd.txt' if assembly else 'synthesis-helpers.gd.txt')).read_text(encoding='utf-8')
probe=H/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=R/'ada_run/encounter_pilot'/room
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(H/(room+'-engine.log')),'--script','res://'+probe.relative_to(R).as_posix(),'--','res://'+(run/'spec.json').relative_to(R).as_posix(),'--em-no-costume']
with (H/(room+'-process.log')).open('wb') as out:
 try: result=subprocess.run(cmd,stdout=out,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired:result=124
(H/(room+'-exit.json')).write_text(json.dumps({'exit':result}),encoding='utf-8')
if (run/'report.json').exists():
 shutil.copy2(run/'report.json',H/(room+'-runtime.json'))
 data=json.loads((run/'report.json').read_text(encoding='utf-8'))
 for img in data['shots']:shutil.copy2(R/img.removeprefix('res://'),H/Path(img).name)
 print(room,result,'checks',len(data.get('checks',[])),'failures',data['failures'])
else:print(room,result,'no report')
raise SystemExit(result)
