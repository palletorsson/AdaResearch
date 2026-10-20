"""Publish the fresh post-revision engine rehearsal without replacing old receipts."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib, html, json, re, shutil
import markdown
from test_soft_sequence_ghost import ROWS

R=Path(__file__).resolve().parents[1]
PACK=R/'doc/book/iterations/2026-10-09-soft-bodies-complete-readings'
O=PACK/'ghost-rerun'
RUN=R/'ada_run/encounter_pilot/SoftBodies_Cloth_Physics/ghost-three-attachments-recheck'
EXT=R/'doc/book/iterations/2026-10-09-soft-bodies-three-attachments'
def read(p): return p.read_text(encoding='utf8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes(s.encode('utf8'))
def dump(p,d): write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')

checks=json.loads(read(O/'ghost-checks.json'))
assert checks['passed'] and checks['total_checks']==263 and checks['printed_files']==28
assert len(checks['halls'])==9 and len(checks['continuity'])==5
for row in checks['halls']:
    assert row['fresh_engine_run'] and not row.get('reused_this_pass_receipt')
    assert sha(R/'commons/maps'/row['map']/'tutorial.md')==row['tutorial_sha256']
    receipt=json.loads(read(O/'halls'/row['map']/'evidence/checks.json'))
    assert receipt['passed'] and not receipt['failures'] and len(receipt['checks'])==row['checks']
    for log in (O/'halls'/row['map']/'evidence').glob('*.log'):
        assert 'SCRIPT ERROR' not in read(log) and 'Parse Error' not in read(log),log
    for name,digest in row['files'].items():
        assert sha(O/'halls'/row['map']/'code'/name)==digest

composition=json.loads(read(RUN/'report.json'))
assert composition['passed'] and not composition['failures'] and len(composition['checks'])==21
assert all(c['passed'] for c in composition['checks'])
assert any(c['name']=='All planned composition checks completed' for c in composition['checks'])
for name in ['stdout.log','engine.log']:
    assert 'SCRIPT ERROR' not in read(RUN/name) and 'Parse Error' not in read(RUN/name)
before=json.loads(read(O/'composition-inputs.json'))
assert datetime.fromtimestamp((RUN/'report.json').stat().st_mtime,timezone.utc)>datetime.fromisoformat(before['recorded_before_composition_at'])
for name,digest in before['files'].items():
    assert sha(EXT/'student'/name)==digest
    dest=O/'composition/student'/name
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(EXT/'student'/name,dest)
for name in ['report.json','stdout.log','engine.log','source_manifest.json']:
    dest=O/'composition/evidence'/name
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(RUN/name,dest)
shutil.copyfile(R/'tools/probes/soft_three_attachments.gd',O/'composition/evidence/probe.gd')
for name in ['three-places.png','in-the-hall.png']:
    dest=O/'composition/images'/name
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(RUN/name,dest)
for relative,digest in json.loads(read(PACK/'protected-hashes.json')).items():assert sha(R/relative)==digest

v=composition['observations']['comparison']
old=json.loads(read(EXT/'evidence/report.json'))['observations']['comparison']
assert v['largest_pin_error_m']<.001 and v['free_corner_motion_m']>.005
titles=['Deformation','Cloth','Carusell','Pressure','Contact','Sampling','Affect','Reaction–diffusion','Morphogenesis']
report=f'''# Ghost student — fresh run after revision

9 October 2026 · Nine lessons rerun in Godot · Existing Endless Museum project

**263 of 263 lesson checks passed again, plus 21 of 21 checks in the repeated museum composition.** All nine lesson processes were started afresh. No cached results were used. The printed code and museum behaviour needed no repair.

This is an author-operated rehearsal with prior context. It checks reconstruction, declared interactions and specific variations. It is not a blind independent reader, a continuous walk through all portals, or a physical-headset assessment.

## Following the revised instructions

The student starts inside the prepared museum with its player, camera, lighting, XRTools and Jolt. Every lesson now identifies its carried files, new work and supplied components. We extracted all 28 printed scripts, checked the dependencies and ran each lesson's complete known assertion set. A zero exit code alone was not accepted: logs were checked for script/parse errors and each expected assertion had to be present and pass.

|Hall|New operation named in the tutorial|Fresh checks|
|---|---|---:|
'''
for i,row in enumerate(checks['halls']):
    tutorial=read(O/'halls'/row['map']/'tutorial.md')
    focus=re.search(r'\*\*New work:\*\* (.*)',tutorial)[1].strip()
    report+=f"|{i+1}. {titles[i]}|{focus}|{row['checks']} passed|\n"
report+='''
The exercises also executed their stated independent edits. These included changing cloth subdivisions without supplying new pin indices, changing pressure amplitude while retaining the response settings, capturing a later surface, altering a reaction rate, and separating a threshold edit from the field's other parameters. Deliberately faulty variants were exercised where the existing lesson probes provide them.

Five source-continuity checks passed: the same PointBody across nine halls; sheet from Cloth to Carusell; panel from Pressure to Contact; vessel and solver from Sampling to Affect. Each host creates its own instances. Matching source files does not demonstrate cross-hall inventory persistence.

## Does the reading follow the construction?

The first five lessons keep the simulated body's conditions visible: a chosen attachment, a moved support, a pressure drive, a matched fall. Sampling explicitly changes from Jolt to the supplied vessel solver so the learner can read its positions. Affect reconstructs the known step-40 specimen; it does not load an arbitrary previous capture. Reaction returns to the earlier CA field. Morphogenesis starts a different spatial field with no simulation clock.

Those changes of model are now declared in the prose. The final texts carry the question of persistence across them: physical relations, a record, continuing exchange, and a reconstructible rule. This is an editorial judgment checked against the implementation. The engine assertions cannot establish whether that argument convinces a future reader.

## Repeat a composition, leave its fold open

'''
report+=f'''The optional Cloth exercise was run again in the real museum. A holds two upper corners; B holds three distinct reference positions. Both use the same sheet, connectivity and material settings. After {v['wait_physics_callbacks']} awaited physics callbacks, B's released corner had moved **{v['free_corner_motion_m']:.3f} metres**; its held points drifted at most **{v['largest_pin_error_m']:.8f} metres**. The earlier run recorded {old['free_corner_motion_m']:.3f} metres of corner movement. The assertion concerns a free corner moving and selected points staying, not an exact repeated fold or distance.

The inherited point's synthetic XRTools grip, trigger, rebuild and release passed again, as did actual keyboard dispatch, transformed reference selection and the explicit completion check. All **21 checks passed**. The temporary study adds no permanent museum artifact.

## What changed this time

No student code or chapter repair was needed. The test runner now preserves this fresh run separately and checks that a passing receipt contains every known lesson assertion. The earlier receipts and the rejected checker attempt remain available. The blog is updated from this run's evidence.

The remaining questions need another kind of test: an unfamiliar reader rebuilding a lesson without prior context, a complete controller-only session, and comfort and performance in the headset. None is implied by these passes.

## Evidence

- [Nine fresh lesson receipts and text hashes](ghost-checks.json)
- [Plan and composition predictions](RERUN-PLAN.md)
- [Fresh composition checks](composition/evidence/report.json)
- [Complete composition host](composition/student/study.gd)
- [Earlier composition, including the rejected first checker](../extensions/three-attachments/index.html)
'''
write(O/'REPORT.md',report)
css=re.search(r'<style>(.*?)</style>',read(PACK/'index.html'),re.S)[1]
body=markdown.markdown(report,extensions=['fenced_code','tables'])
body+='<figure><img src="composition/images/three-places.png" alt="Two sheets with two and three selected attachments in the new museum run"><figcaption>Fresh native capture. The selected boundary changes; the sheet and material settings remain shared.</figcaption></figure>'
body+='<figure><img src="composition/images/in-the-hall.png" alt="The temporary comparison inside the existing Cloth hall"><figcaption>The same study in its museum setting. Native desktop rendering, not a headset capture.</figcaption></figure>'
write(O/'index.html','<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soft Bodies — fresh ghost-student run</title><style>'+css+'</style></head><body><header><nav><a href="../index.html">Full chapter</a><a href="REPORT.md">Report source</a><a href="../soft-bodies-review.zip">Review ZIP</a></nav></header><main>'+body+'</main></body></html>')
dump(O/'validation.json',{'passed':True,'fresh_lesson_checks':checks['total_checks'],'fresh_composition_checks':len(composition['checks']),'fresh_lesson_processes':9,'code_files':28,'source_continuity_checks':5,'all_expected_checks_present':True,'script_errors':False,'learner_code_changed':False,'protected_sources_unchanged':True,'comparison':v,'independent_reader':False,'headset_test':False})
print(read(O/'validation.json'))
