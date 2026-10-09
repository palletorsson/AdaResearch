from pathlib import Path
import json, hashlib, shutil
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'doc/research/possible-bodies'
RECORD=Path(__file__).parent
read=lambda p:json.loads(Path(p).read_text(encoding='utf-8'))
report=read(ROOT/'ada_run/timing_probe.json')
assert not report['failures'],report
report.update(date='2026-09-11',conditions='Desktop Godot compatibility renderer; scripted pointer presses and real physics. Supplied capture viewpoints, with target-hall artifacts made visible.',limitations=['Headset reach, comfort, legibility and sustained VR performance untested.','Boxes have rigid bodies but no pick-up interface; a designed climbing route is future work.','Known project UID and renderer-feature warnings remain; no script errors in the probe.'])
(OUT/'timing-check.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
for name in ['rods_wave','rods_drift','backlog','recovered','console','hall']:
 shutil.copy2(ROOT/f'ada_run/timing_{name}.png',OUT/f'timing_{name}.png')
files=list((ROOT/'commons/artifacts/timing_machines').glob('*.gd'))+list((ROOT/'commons/artifacts/timing_machines').glob('*.tscn'))+list((ROOT/'commons/maps/Change_Choreography').glob('*.md'))+[ROOT/'commons/maps/Change_Choreography/map_data.json',ROOT/'commons/testing/probe_timing_machines.gd',ROOT/'commons/artifacts/conveyor_belt/conveyor_belt.gd']
v=read(OUT/'verification.json');v['Change_Choreography']={'date':'2026-09-11','summary':str(report['checks'])+' desktop checks pass: phase offsets and drift, pointer controls, approach lane, real conveyor transport, receiving-tray backlog, recovery and reset. Headset deferred.','report':'timing-check.json','capture':'timing_rods_wave.png','comparisons':[{'file':'timing_backlog.png','caption':'Slower collection: physical parcels accumulate in the tray and on the belt.'},{'file':'timing_recovered.png','caption':'Faster collection drains the existing backlog.'}],'source_sha256':{str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
(OUT/'verification.json').write_text(json.dumps(v,indent=2),encoding='utf-8')
p=ROOT/'commons/data/museum_core_encounters.json';d=read(p);d['rooms']['Change_Choreography']={'sequence':'forces','primary_tokens':['phase_rod_array','conveyor_backlog'],'status':'desktop_verified_headset_pending','learner_verified':False,'reason':'Fixed phase difference, relative frequency drift and mismatched throughput are distinct inspectable relations.','map_sha256':hashlib.sha256((ROOT/'commons/maps/Change_Choreography/map_data.json').read_bytes()).hexdigest()};p.write_text(json.dumps(d,indent=2),encoding='utf-8')
o=report['observations'];summary=f"Observed live parcel counts: matched {o['matched']['here']}, backlog {o['backlog']['here']}, recovered {o['recovered']['here']}. The exact heap varies with physical contacts."
for suffix in ['md','html']:
 p=OUT/('timing-machines.'+suffix);s=p.read_text(encoding='utf-8')
 if suffix=='md':s=s.replace('[Read the runtime report](timing-check.json).',f"**{report['checks']} checks pass.** {summary} [Read the runtime report](timing-check.json).")
 else:s=s.replace('<a href="timing-check.json">Read the runtime report</a>.',f"<strong>{report['checks']} checks pass.</strong> {summary} <a href=\"timing-check.json\">Read the runtime report</a>.")
 p.write_text(s,encoding='utf-8')
(RECORD/'README.md').write_text('# Timing machines, 11 September 2026\n\nNew hall Change_Choreography follows Vectors_Act4b_Oscillation in Forces. The two introductory Change halls remain unchanged. Both new artifacts are primary and have matching final.md anchors.\n\n'+summary+'\n\n'+str(report['checks'])+' desktop checks pass. See the published timing-machines.html and timing-check.json for conditions and limits. before/ preserves touched existing content; new artifact scripts and map documents are the implementation. No headset test was performed.\n',encoding='utf-8')
print(summary)
