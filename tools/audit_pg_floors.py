"""Compare PG source floors, historical grids and portable museum snapshots.

Read-only by default. --repair-cache updates only existing plan tiles and their
floor count; it never fills a source void or moves an artifact.
"""
from pathlib import Path
from collections import Counter, deque
import argparse, copy, hashlib, json, subprocess
from em_map_halls import derive_row

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/space/pg-floor-audit-2026-09-14'
PLANS = ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json']
REF = 'a36f33c996004abcdc67ea2a0ac3fce72eba42fd'

def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def encoded(d): return (json.dumps(d, ensure_ascii=False, indent=2)+'\n').encode()
def sha(data): return hashlib.sha256(data).hexdigest()
def zeros(tile): return [[x,z] for z,row in enumerate(tile) for x,c in enumerate(row) if str(c)=='0']

def components(cells):
    remaining={tuple(c) for c in cells}; groups=[]
    while remaining:
        seed=min(remaining);remaining.remove(seed);q=deque([seed]);group=[]
        while q:
            x,z=q.popleft();group.append([x,z])
            for p in [(x-1,z),(x+1,z),(x,z-1),(x,z+1)]:
                if p in remaining:remaining.remove(p);q.append(p)
        groups.append(group)
    return sorted(groups,key=lambda g:(-len(g),g))

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--repair-cache',action='store_true');args=ap.parse_args()
    sequence=read(ROOT/'commons/maps/sequences/proceduralgeneration.json')['sequences']['proceduralgeneration']
    plans={p:read(ROOT/p) for p in PLANS};original={p:(ROOT/p).read_bytes() for p in PLANS}
    primary=plans[PLANS[1]];source_bytes={};report=[];checks=[]
    for i,name in enumerate(sequence['maps']):
        rel=f'commons/maps/{name}/map_data.json';source_bytes[rel]=(ROOT/rel).read_bytes();d=read(ROOT/rel)
        old_bytes=subprocess.run(['git','-c',f'safe.directory={ROOT.as_posix()}','show',f'{REF}:{rel}'],capture_output=True,check=True).stdout
        old=json.loads(old_bytes);row=next((r for r in primary['plans'] if r.get('map')==name),None)
        mus=d['map_info'].get('museum',{});wall_h=int(mus.get('wall_height',2));raw=d['layers']['structure']
        fallback={'pearl':name,'museum':'audit-only','pearl_index':i,'pearls_total':len(sequence['maps'])}
        p=row or fallback;fresh=derive_row(p['pearl'],name,p['museum'],p['pearl_index'],p['pearls_total'],'proceduralgeneration')
        stale=[]
        if row:
            assert [len(r) for r in row['tile']]==[len(r) for r in fresh['tile']],name
            stale=[[x,z,c,fresh['tile'][z][x]] for z,rr in enumerate(row['tile']) for x,c in enumerate(rr) if c!=fresh['tile'][z][x]]
        zero=zeros(raw);offset=[0,0] if name=='PG_Space_Colonization' else [1,1]
        oz=set(map(tuple,zeros(old['layers']['structure'])))
        inherited=[c for c in zero if (c[0]-offset[0],c[1]-offset[1]) in oz]
        utility_voids=[[x,z,c] for z,rr in enumerate(d['layers']['utilities']) for x,c in enumerate(rr) if str(c).strip() and [x,z] in zero]
        raised_as_wall=[[x,z,c] for z,rr in enumerate(raw) for x,c in enumerate(rr) if str(c).isdigit() and int(c)>=wall_h]
        rec={'map':name,'active':row is not None,'current_structure':raw,'current_tile':fresh['tile'],
             'cached_tile':row['tile'] if row else None,'historical_structure':old['layers']['structure'],
             'source_voids':len(zero),'cached_voids':len(zeros(row['tile'])) if row else None,
             'inherited_voids':len(inherited),'historical_offset':offset,'void_regions':components(zero),
             'utility_voids':utility_voids,'numeric_cells_read_as_walls':raised_as_wall,'wall_threshold':wall_h,
             'artifacts':[[x,z,c] for z,rr in enumerate(d['layers']['interactables']) for x,c in enumerate(rr) if str(c).strip()],
             'cache_changes':stale,'historical_sha256':sha(old_bytes),'source_sha256':sha(source_bytes[rel])}
        assert len(inherited)==len(zero),(name,'unexplained new source void')
        checks.append(name+': all current source zeros also existed in the July grid')
        report.append(rec)
        if args.repair_cache:
            for path,plan in plans.items():
                rr=next((r for r in plan['plans'] if r.get('map')==name),None)
                if rr is None:continue
                assert rr['tile']==row['tile'],(path,name,'different cached layout; inspect before repair')
                rr['tile']=copy.deepcopy(fresh['tile'])
                rr['interior_count']=sum(c=='1' for tr in fresh['tile'] for c in tr)
            hist=OUT/'historical'/rel;hist.parent.mkdir(parents=True,exist_ok=True)
            if hist.exists():assert hist.read_bytes()==old_bytes
            else:hist.write_bytes(old_bytes)
    # Every change has an exact source-derived tile and leaves all curation intact.
    for path,plan in plans.items():
        before=json.loads(original[path]);restored=copy.deepcopy(plan)
        for a,b in zip(before['plans'],restored['plans']):
            if a.get('map') in sequence['maps']:
                b['tile']=a['tile'];b['interior_count']=a['interior_count']
        assert restored==before,path+': unrelated plan data changed'
        checks.append(path+': artifact placements, curation and other sequences unchanged')
    assert all((ROOT/rel).read_bytes()==data for rel,data in source_bytes.items())
    checks.append('All seven source maps remain byte-identical')
    if args.repair_cache:
        OUT.mkdir(parents=True,exist_ok=True)
        for rel,data in {**original,**source_bytes}.items():
            dest=OUT/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True)
            if dest.exists():raise RuntimeError('Existing archive: refusing to overwrite '+str(dest))
            dest.write_bytes(data)
        for path,data in original.items():assert (ROOT/path).read_bytes()==data,'Concurrent plan edit; retry audit'
        for path,plan in plans.items():
            if plan!=json.loads(original[path]):(ROOT/path).write_bytes(encoded(plan))
        for path,plan in plans.items():assert read(ROOT/path)==plan
        result={'historical_ref':REF,'maps':report,'checks':checks,'cache_repaired':True,
                'plans_after_sha256':{p:sha((ROOT/p).read_bytes()) for p in PLANS},
                'scope':'Plan tile/count synchronization only; no source floor, artifact, role or order change.',
                'runtime_collision_review':False}
        (OUT/'audit.json').write_bytes(encoded(result))
    print(json.dumps({'active_halls':sum(r['active'] for r in report),'active_source_voids':sum(r['source_voids'] for r in report if r['active']),
                      'stale_cells_per_plan':sum(len(r['cache_changes']) for r in report),'checks':len(checks),
                      'repaired':args.repair_cache},indent=2))

if __name__=='__main__':main()
