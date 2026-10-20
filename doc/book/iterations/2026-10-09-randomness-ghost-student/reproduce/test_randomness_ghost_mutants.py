"""Check that the new learner predictions reject executable conceptual faults."""
from concurrent.futures import ThreadPoolExecutor,as_completed
import json,shutil
import run_randomness_ghost_student as g

FAULTS=[
 (0,'01_seed_picture.gd','var c := rng.randf()','var c := 0.0','A channel edit silently changes draw consumption.'),
 (2,'03_eligible_addresses.gd','candidates.remove_at(last_offset)','pass # faulty: selected address stays eligible','Selection with replacement breaks the promised exhaustion.'),
 (6,'07_a_point_keeps_steps.gd','proposed = current + displacement','proposed = positions[0] + displacement','An observed trail entry is substituted for the current position.'),
 (11,'12_a_visit_guides.gd','guidance := 0.0','guidance := 1.0','The rule still consults history when the student disabled guidance.'),
 (12,'13_fields_add.gd','raw.append(total)','raw.append(total * 2.0)','The displayed sum gains an undeclared scale.'),
 (13,'wait_cycle.gd','notice_ms := 300','notice_ms := 1200','The requested warning edit has no effect.'),
]

def main():
    rows=json.loads((g.OUT/'predictions.json').read_text());tasks=[]
    for i,name,old,new,reason in FAULTS:
        row=rows[i].copy();dest=g.OUT/'mutants'/row['map']
        shutil.copytree(g.OUT/'learner'/row['map']/'changed',dest,dirs_exist_ok=True)
        p=dest/name;text=p.read_text();assert text.count(old)==1,(name,old)
        p.write_text(text.replace(old,new),encoding='utf-8')
        row.update(changed=str(dest/row['entry']),tag='fault',fault=reason);tasks.append(row)
    (g.OUT/'mutation-predictions.json').write_text(json.dumps(tasks,indent=2)+'\n')
    results=[]
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures={pool.submit(g.run_one,row,'transfer'):row for row in tasks}
        for future in as_completed(futures):
            r=future.result();r['fault']=futures[future]['fault']
            r['rejected_as_expected']=not r['passed'] and r['checks']>0 and bool(r['failures']) and not any('SCRIPT ERROR' in s for s in r['diagnostics'])
            results.append(r);print(r['map'],r['rejected_as_expected'],r['failures'],flush=True)
    (g.OUT/'mutations.json').write_text(json.dumps({'results':results,'all_rejected':all(r['rejected_as_expected'] for r in results)},indent=2)+'\n')
    assert all(r['rejected_as_expected'] for r in results)

if __name__=='__main__':main()
