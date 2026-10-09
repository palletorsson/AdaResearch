"""Revise two Change teaching plans; preserve code and complete map texts."""
from pathlib import Path
import copy, difflib, hashlib, json, re

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
ROUTE = ROOT / 'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p, d): p.write_text(json.dumps(d, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

ARC = ('PROPOSED. Bring functions, position differences, loops and retained traces. '
       'After Tiling, supply a smooth callable curve rather than treating a sampled texture as one. '
       'In the first hall, separate writing a finite-rate function from writing a finite-sum function; '
       'return to the bridge as a signed-change comparison. In the second, let a supplied field '
       'choose each next displacement. Carry explicit inputs, units and update rules into Forces, '
       'where velocity will be retained and changed by acceleration. Keep field construction, '
       'analytic calculus and controlled step-size comparisons outside the first making task. '
       'Existing museum hosts remain; exact learner edit locations and full lessons are pending.')

UPDATES = [
 dict(id='Change_Intro', title='Measure, then accumulate',
  storyboard='The wide joining line falls while the curve rises at its first sample. Bring functions and position differences; use the supplied smooth curve to write a finite-rate function from two heights and a nonzero horizontal interval. Predict the sign on another interval, then compare it with the supplied tangent. On a second visit to the next bench, reuse that callable curve in a loop summing height-times-width contributions. Keep the interval fixed while changing either count or sample position, and predict one rectangle before checking the total. Plots and controls are supplied. The reference is another finite sum, not the exact integral. The bridge introduces a different arch: use its supplied signed-rate comparison to ask why a rise and fall can leave no net height change. Carry two small functions with named inputs and units; x is position here, not elapsed time.',
  storyboard_short='Reuse functions/differences/loops. Supply smooth f(x), plots, tangent and controls. First: finite rate over nonzero h; predict sign elsewhere. Next: sum f(sample)*width over fixed interval; vary count or sample fraction alone; predict one contribution. Carry rate/sum functions with units. x=position, not time. Reference=finite 4096-midpoint sum. Bridge uses DIFFERENT arch: supplied signed-rate comparison, net change not total travel. Exact learner edit location pending.',
  brings=['callable functions and differences between positions','loop totals and explicitly named inputs'],
  learns=['finite rate over a nonzero interval','finite accumulation from height-times-width contributions'],
  carries='Two reusable finite calculation functions with explicit interval, sampling rule and units; signed change distinct from total travel.',
  supplied=['the existing smooth curve and plotting hosts','analytic tangent and finite reference calculation','bridge arch and its signed-rate comparison'],
  independent_check='Predict the rate sign on another interval and explain its units. In the sum lesson, predict one contribution after moving the sample within its rectangle while keeping the count fixed.',
  prior_maps=['Point_Lines','Point_Trace','Ribbon_Patterns_03'],
  source_refs=['commons/artifacts/tangent_slope_workbench/tangent_slope_workbench.gd','commons/artifacts/tangent_slope_workbench/rate_comparison.gd','commons/artifacts/riemann_sum_workbench/riemann_sum_workbench.gd','commons/artifacts/riemann_sum_workbench/accumulation_comparison.gd','algorithms/change/ftc_bridge.gd'],
  review_note='Two small making lessons, not a calculus survey. Keep the smooth function shared by the first two benches separate from the bridge arch. A tangent formula and finite reference are supplied comparisons; the student need not derive either. Finer samples do not guarantee monotonically smaller error. Choose the exact learner edit/receiver connection before expanding code; no replacement workbench. The bridge is a reflective return, not a third compulsory coding task.',
  before='Rate, area and the bridge were compressed into one paragraph, with the bridge curve and numerical reference insufficiently distinguished.',
  after='Teach a small rate function, then a separate sum using the same curve. Keep the bridge as a return with a different arch and signed-change question.',
  reason='Give each new operation room to become usable without turning the hall into a calculus survey.'),
 dict(id='Flow_Field', title='Let the next address follow the last',
  storyboard='Particles keep moving while FIELD HELD stops the field clock. Bring position updates, elapsed seconds and Trace’s retained list. Read the supplied direction function at one position in the two-dimensional canvas; multiply its unit direction by speed and elapsed seconds to get a displacement, then use the new position for the next lookup. Predict two updates from another starting address. Rendering, the field sampler and boundary handling remain supplied; state the canvas frame before relating it to the hall. Carry a follower and its position record, with no stored velocity or inertia. On a return, compare one step with two half-steps using the same start, held field, speed and total duration. This is a proposed calculation, not the SPEED button. Inspect the installed trail across a wrap: its joining stroke can invent a crossing. Separating trail segments remains an optional future extension.',
  storyboard_short='Use FIELD HELD: field clock stops, particles continue. Reuse position/delta/retained list. Supply field_direction(Vector2 canvas_position), renderer/boundary policy; declare frame. Teach unit direction*speed*seconds→displacement; next address→next lookup. Predict two updates from another start. Carry follower/record, no inertia. Optional return: dt versus two dt/2, same start/field/speed/duration; SPEED is not time step and RESET rescatters. Current trails join wraps; segment break only proposed. Defer noise/angle construction and Forces velocity state.',
  brings=['position updates with elapsed seconds','Trace’s retained-position list and neighbouring entries'],
  learns=['sampling at an address produced by the previous update','direction, speed and time step have different roles'],
  carries='A repeated field-sampling update and retained path; a clear distinction between prescribed velocity and carried velocity state.',
  supplied=['existing unit-direction sampler and two-dimensional canvas frame','particle/arrow rendering, input controls and boundary handling'],
  independent_check='Choose another starting canvas position, predict the first displacement and next sampling address, then repeat once. Explain what FIELD HELD freezes and why a wrap can create a misleading joining line.',
  prior_maps=['Point_Coordinates','Point_Trace','Trans_Translation','Change_Intro'],
  source_refs=['commons/artifacts/flow_field_painter/flow_field_painter.gd','commons/artifacts/flow_field_painter/shared_field_lesson.gd'],
  review_note='Select one reduced update in the existing shared_field host; state the Vector2 canvas coordinates and the conversion to museum display separately. The sampler and noise/angle construction remain supplied. SPEED changes prescribed speed; RESET chooses fresh positions. Neither is a controlled numerical-step comparison. Keep such a comparison for a return with identical conditions and equal total duration. Trail segmentation is an unimplemented proposal, not something this summary pass fixes.',
  before='The plan asked for a step-size comparison and a broken trail at wraps without clearly separating them from existing controls and behavior.',
  after='Start with two predicted field-following updates. Put the controlled step comparison on a return; identify the current wrap line honestly.',
  reason='Teach the feedback in the path before adding a numerical experiment or an unbuilt trail repair.')
]

HEADING = '## 6. Change: Rate, Accumulation, and Flow'
PATTERN = r'^## 6\. Change: Rate, Accumulation, and Flow.*?(?=^## 7\.)'
def replace_section(path, section):
    text = path.read_text(encoding='utf-8')
    assert len(re.findall(PATTERN, text, re.M|re.S)) == 1, path
    after = re.sub(PATTERN, lambda _: section.rstrip()+'\n\n', text, flags=re.M|re.S)
    assert re.sub(PATTERN, '', text, flags=re.M|re.S) == re.sub(PATTERN, '', after, flags=re.M|re.S)
    path.write_text(after, encoding='utf-8')

def main():
    p = ROOT/'doc/book/course/storyboards/early.json'; data = load(p); old = copy.deepcopy(data)
    seq = next(s for s in data if s['sequence']=='change')
    before = next(s for s in load(OUT/'before/doc/book/course/storyboards/early.json') if s['sequence']=='change')
    assert [h['id'] for h in seq['halls']] == [u['id'] for u in UPDATES]
    changes = []
    for hall, update in zip(seq['halls'], UPDATES):
        for path in update['source_refs']: assert (ROOT/path).is_file(), path
        for mid in update['prior_maps']: assert (ROOT/'commons/maps'/mid).is_dir(), mid
        hall.update({k:v for k,v in update.items() if k not in ['before','after','reason']})
        hall['change_reason'] = update['reason']
        changes.append(dict(id=hall['id'], title=hall['title'], **{k:update[k] for k in ['before','after','reason']}))
    seq.update(arc=ARC, status='Revised teaching proposals; review each map before full lessons', tutorial_guidance='doc/book/course/storyboards/CHANGE.md')
    assert [s for s in data if s['sequence']!='change'] == [s for s in old if s['sequence']!='change']
    save(p, data); save(OUT/'changes.json', changes)

    p = ROOT/'commons/maps/sequences/change.json'; meta = load(p); bmeta = copy.deepcopy(meta); s = meta['sequences']['change']
    s['learning_objectives_status'] = 'Revised summary proposals; existing companion texts retained, reduced learner edit locations and lessons pending.'
    s['learning_objectives'] = [
      'Write a finite-rate function over a nonzero horizontal interval, with the independent variable and units stated',
      'On a separate lesson, accumulate height-times-width samples of the same supplied smooth function',
      'Vary count or sample position independently; distinguish finite reference sums from exact integrals',
      'Use the different bridge arch as a signed-change comparison; separate net change from total travel',
      'Sample a supplied direction field at the position produced by the previous update',
      'Distinguish unit direction, speed, elapsed seconds and displacement in the declared canvas frame',
      'Inspect field time, particle updates and misleading trail joins at wraps without claiming an unimplemented repair',
      'On a return, compare one step with two half-steps under identical start, field, speed and duration; distinguish this from changing SPEED',
      'Prepare Forces by distinguishing an immediately prescribed velocity from velocity retained and changed by acceleration']
    report = 'doc/book/iterations/2026-10-04-change-capacity-return/index.html'
    s['local_review_history'] = [h for h in s.get('local_review_history', []) if h.get('report')!=report]
    s['local_review_history'].append(dict(date='2026-10-04', report=report, decision='Separate rate and sum lessons; preserve bridge as a return; teach field feedback before optional numerical-step comparison.', status='Proposed summaries only; no runtime or full companion changes'))
    for key in ['maps','prerequisites','unlocks','artifact_groups']: assert s[key] == bmeta['sequences']['change'][key]
    save(p, meta)

    p = ROUTE/'route.json'; route = load(p); broute = copy.deepcopy(route); byid = {h['id']:h for h in seq['halls']}
    for hall in route['halls']:
        if hall['sequence']=='change': hall.update(byid[hall['id']])
    next(s for s in route['sequences'] if s['id']=='change')['arc'] = ARC
    assert [h for h in route['halls'] if h['sequence']!='change'] == [h for h in broute['halls'] if h['sequence']!='change']
    assert [h['id'] for h in route['halls']] == [h['id'] for h in broute['halls']]
    save(p, route)
    p = ROUTE/'index.html'; text = p.read_text(encoding='utf-8'); pat = r'(<script id="route-data" type="application/json">).*?(</script>)'
    assert len(re.findall(pat, text, re.S)) == 1
    p.write_text(re.sub(pat, lambda m:m[1]+json.dumps(route, ensure_ascii=False).replace('</','<\\/')+m[2], text, count=1, flags=re.S), encoding='utf-8')

    full = [HEADING, ARC, '']; short = [HEADING, '']
    for hall in seq['halls']:
        full += [f'### {hall["id"]} — {hall["title"]}',hall['storyboard'],'','**Short AI alternative**',hall['storyboard_short'],'',f'*For correction:* {hall["review_note"]}','']
        short += [f'### {hall["id"]}',hall['storyboard_short'],'']
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS.md',ROUTE/'storyboards.md']: replace_section(p,'\n'.join(full))
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS_SHORT.md',ROUTE/'storyboards-short.md']: replace_section(p,'\n'.join(short))
    for p in [ROOT/'doc/book/course/storyboards/SEQUENCES.md',ROUTE/'sequences.md']:
        text=p.read_text(encoding='utf-8'); a=text.index(HEADING); b=text.index('## 7.',a)
        lines=text[a:b].splitlines(); lines[1]=ARC; replace_section(p,'\n'.join(lines))

    diff=[]
    for oldhall,hall in zip(before['halls'],seq['halls']):
        for key in ['title','storyboard','storyboard_short','review_note']:
            diff.extend(difflib.unified_diff([oldhall[key]+'\n'],[hall[key]+'\n'],fromfile=hall['id']+'/'+key+'/before',tofile=hall['id']+'/'+key+'/after'))
    (OUT/'summaries.diff').write_text(''.join(diff),encoding='utf-8')
    for record in load(OUT/'unchanged-evidence-before.json'):
        assert hashlib.sha256((ROOT/record['path']).read_bytes()).hexdigest()==record['sha256'],record['path']
    save(OUT/'checks.json',dict(sequence='change',maps=2,other_route_halls_unchanged=len(route['halls'])-2,order_unchanged=True,other_authored_sequences_unchanged=True,other_markdown_sections_unchanged=True,finals_tutorials_map_data_unchanged=True,runtime_checked=False))
    print('Two Change proposals updated; other sequences, order and full map documents preserved.')

if __name__=='__main__': main()
