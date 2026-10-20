from pathlib import Path
import shutil, json
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).parent
summary={}
for name, shots in {
    'Random_Space_Geometry':['seeded-room-overview','seeded-room-entrance','inside-seeded-room','seed-plan','flat-seeded-plan'],
    'Random_Remove':['lightning-strike','lightning-crossing','lightning-overview','crossing-entrance']
}.items():
    run=ROOT/'ada_run/encounter_pilot'/name/'seeded-lightning-20261015'
    report=json.loads((run/'report.json').read_text(encoding='utf-8'))
    assert report['passed']
    summary[name]={'passed':report['passed'],'checks':len(report['checks']),'failures':report['failures']}
    shutil.copy2(run/'report.json',HERE/(name+'-report.json'))
    for shot in shots:shutil.copy2(run/(shot+'.png'),HERE/(shot+'.png'))
    for kind in ['tutorial','final']:
        shutil.copy2(ROOT/'commons/maps'/name/(kind+'.md'),HERE/(name+'-'+kind+'.md'))
summary['scope']='Desktop Godot museum render, actual collision and body traversal, supplied controls. Quest hand interaction and headset performance remain untested. Strike photographs hold a real strike for the camera.'
summary['known_diagnostics']='The museum reports the seeded artifact bounding box as a sealed region although the capsule traverses its internal path and connecting doorway. Existing second-chamber content also emits renderer resource warnings at shutdown; no script error was logged.'
(HERE/'verification.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(summary)
