"""Validate planning coverage and preservation; never declare a lesson tested."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
plan = read(HERE/'plan.json')
spine = sorted(read(ROOT/'commons/maps/curriculum_spine.json')['spine']['sequences'], key=lambda s:s['order'])
order = [m for s in spine for m in read(ROOT/f"commons/maps/sequences/{s['name']}.json")['sequences'][s['name']]['maps']]
positions = {m:i for i,m in enumerate(order)}
errors, warnings = [], []
lessons = {r['id']:r for r in plan['lessons']}
if len(lessons)!=len(plan['lessons']): errors.append('Duplicate lesson plans')
if set(lessons)!=set(order): errors.append('Plan/live hall coverage differs')
if {s['id'] for s in plan['sequences']}!={s['name'] for s in spine}: errors.append('Sequence coverage differs')
if {t['id'] for t in plan['topics'] if t['id'].startswith('topic-')}!={f'topic-{i}' for i in range(116)}: errors.append('Source inventory coverage differs')
for t in plan['topics']:
    for m in [t['first'],*t['returns']]:
        if m is not None and m not in positions: errors.append(f"Unknown topic placement {t['id']}: {m}")
for l in plan['lessons']:
    summary=l.get('summary','')
    if not isinstance(summary,str) or not summary.strip() or '\n' in summary or '\r' in summary:
        errors.append(f"Missing or non-paragraph summary: {l['id']}")
    for d in l['dependsOn']:
        if d not in positions: errors.append(f"Unknown predecessor {l['id']}: {d}")
        elif positions[d]>=positions[l['id']]: warnings.append(f"Later prerequisite {l['id']}: {d}")
    if not l['checks']: warnings.append(f"Source audit/contract still required: {l['id']}")
protected = read(HERE/'protected-sources.json')
revision_file = HERE/'authorized-revisions.json'
revisions = read(revision_file) if revision_file.exists() else {}
for name, revision in revisions.items():
    if name not in protected or revision.get('before') != protected.get(name) or not revision.get('reason') or not revision.get('date'):
        errors.append(f'Invalid authorized revision: {name}')
unchanged = 0
for name,expected in protected.items():
    p=ROOT/name
    current = hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
    allowed = revisions[name].get('after') if name in revisions else expected
    if current != allowed: errors.append(f'Protected source changed without a matching recorded revision: {name}')
    if current == expected: unchanged += 1
report=dict(passed=not errors,scope='Plan structure and protected sources with explicit authorized revisions; no Godot or learner claims.',
            halls=len(order),sequences=len(spine),source_topics=116,ada_topics=sum(t['id'].startswith('ada-') for t in plan['topics']),
            concrete_contracts=sum(bool(l['checks']) for l in lessons.values()),unresolved_contracts=sum(not l['checks'] for l in lessons.values()),
            protected_sources=len(protected),unchanged_sources=unchanged,authorized_revisions=len(revisions),errors=errors,warnings=warnings)
report['summaries']=sum(bool(l.get('summary','').strip()) for l in lessons.values())
report['summary_scope']='Structural coverage only; editorial progression judgment is recorded separately in REVIEW.md.'
(HERE/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='warnings'}))
raise SystemExit(bool(errors))
