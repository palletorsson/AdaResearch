"""Reconstruct the nine lessons from their printed code and reuse executable checks.

This is an author-operated ghost-student rehearsal, not an independent learner.
Existing per-hall probes test predictions, transfers and deliberately faulty code.
"""
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, subprocess, sys, time
from datetime import datetime, timezone

R = Path(__file__).resolve().parents[1]
O = R/'doc/book/iterations/2026-10-09-soft-bodies-complete-readings'
sys.stdout.reconfigure(encoding='utf8')
ROWS = [
 ('SoftBodies_Soft_Body_Deformation','soft_yield','soft-a-point-that-stays'),
 ('SoftBodies_Cloth_Physics','cloth_boundary','cloth-which-points-stay'),
 ('SoftBodies_Carusell','carousel_lesson','carousel-the-support-moves'),
 ('SoftBodies_Obsticals','pressure_lesson','pressure-a-drive-and-a-room'),
 ('SoftBodies_Obsticals_Part2','contact_lesson','contact-the-same-start'),
 ('SoftBodies_Playground_of_Joy','sampling_lesson','sampling-a-shape-kept'),
 ('SoftBodies_Affect_Theory_Visualization','affect_lesson','affect-one-cue'),
 ('ProceduralGeneration_Reaction_Diffusion_Systems','reaction_lesson','reaction-what-keeps-a-pattern'),
 ('Topology_Entropy_Morphogenesis','morphogenesis_lesson','morphogenesis-who-connected-the-controls'),
]

def sha(data): return hashlib.sha256(data).hexdigest()
def dump(p, data): p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', help='Separate repository directory for a new rehearsal and its evidence.')
    parser.add_argument('--resume', action='store_true')
    args = parser.parse_args()
    out = (R/args.output).resolve() if args.output else O
    assert out.is_relative_to(R), out
    if args.output and not args.resume:
        assert not out.exists(), 'Preserve an existing run; choose a fresh output directory.'
    out.mkdir(parents=True, exist_ok=True)
    started_at = datetime.now(timezone.utc).isoformat()
    expected = {}
    for name, _, _ in ROWS:
        prior = O/'halls'/name/'evidence/checks.json'
        if prior.exists():
            expected[name] = {c['name'] for c in json.loads(prior.read_text(encoding='utf8'))['checks']}
    maps = json.loads((R/'commons/maps/sequences/softbodies.json').read_text(encoding='utf8'))['sequences']['softbodies']['maps']
    assert maps == [r[0] for r in ROWS]
    results, files, transfers = [], {}, []
    for name, tool, slug in ROWS:
        dest = out/'halls'/name
        (dest/'code').mkdir(parents=True,exist_ok=True)
        (dest/'evidence').mkdir(exist_ok=True)
        source = R/'commons/maps'/name/'tutorial.md'
        text = source.read_text(encoding='utf8')
        shutil.copyfile(source,dest/'tutorial.md')
        shutil.copyfile(source.with_name('final.md'),dest/'final.md')
        blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
        assert blocks and len(blocks)==len(dict(blocks))
        files[name] = {}
        same_extraction = True
        for filename, code in blocks:
            actual = (code+'\n').encode('utf8')
            assert '$' not in code
            supplied = R/'doc/book/studies/soft-bodies-through-the-hands'/name/filename
            assert code+'\n' == supplied.read_text(encoding='utf8'), (name,filename)
            prior = dest/'code'/filename
            same_extraction = same_extraction and prior.exists() and prior.read_bytes() == actual
            (dest/'code'/filename).write_bytes(actual)
            files[name][filename] = sha(actual)
            for dep in re.findall(r'(?:preload|load)\("([^"\n]+)"\)', code):
                path = R/dep[6:] if dep.startswith('res://') else supplied.parent/dep
                assert path.exists(), (name,filename,dep)
        shutil.copyfile(R/'doc/book/studies/soft-bodies-through-the-hands'/name/'study.tscn',dest/'code/study.tscn')
        old = R/'doc/book/iterations'/('2026-10-09-'+slug)
        started = time.time()
        if args.resume and same_extraction and (dest/'evidence/checks.json').exists():
            receipt = json.loads((dest/'evidence/checks.json').read_text(encoding='utf8'))
            assert receipt['passed'] and not receipt['failures']
            row={'map':name,'passed':True,'checks':len(receipt['checks']),'tutorial_sha256':sha(source.read_bytes()),'files':files[name],'reused_this_pass_receipt':True,'runner':'tools/test_'+tool+'.py'}
            results.append(row)
            print(name+': retained '+str(row['checks'])+' passed checks for identical extracted code',flush=True)
            continue
        env = dict(os.environ, PYTHONIOENCODING='utf-8')
        with (dest/'evidence/runner.log').open('w',encoding='utf8') as log:
            result = subprocess.run([sys.executable,str(R/'tools'/('test_'+tool+'.py'))],cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=160)
        if result.returncode:
            print((dest/'evidence/runner.log').read_text(encoding='utf8')[-6500:],flush=True)
        assert result.returncode==0, name
        receipt_path = old/'checks.json'
        assert receipt_path.stat().st_mtime >= started-1
        receipt = json.loads(receipt_path.read_text(encoding='utf8'))
        assert receipt['passed'] and not receipt['failures']
        assert all(c['passed'] for c in receipt['checks']), name
        assert expected.get(name,set()) <= {c['name'] for c in receipt['checks']}, (name,'Incomplete check set')
        shutil.copyfile(receipt_path,dest/'evidence/checks.json')
        shutil.copyfile(R/'tools'/('test_'+tool+'.py'),dest/'evidence'/('test_'+tool+'.py'))
        for evidence_file in ['run.gd','printed-hashes.json']:
            if (old/evidence_file).exists():shutil.copyfile(old/evidence_file,dest/'evidence'/evidence_file)
        for log_name in ['code.log','stdout.log','engine.log']:
            log_path=old/log_name
            if log_path.exists() and log_path.stat().st_mtime >= started-1:
                data=log_path.read_text(encoding='utf8',errors='replace')
                assert 'SCRIPT ERROR' not in data and 'Parse Error' not in data
                shutil.copyfile(log_path,dest/'evidence'/log_name)
        variation = old/'variation'
        if variation.exists():
            (dest/'variation').mkdir(exist_ok=True)
            for p in variation.glob('*'):
                if p.suffix in ['.gd','.tscn']:shutil.copyfile(p,dest/'variation'/p.name)
        assert text == source.read_text(encoding='utf8'), 'Tutorial changed during test: '+name
        row={'map':name,'passed':True,'checks':len(receipt['checks']),'tutorial_sha256':sha(source.read_bytes()),'files':files[name],'seconds':round(time.time()-started,2),'runner':'tools/test_'+tool+'.py','fresh_engine_run':True}
        results.append(row)
        print(name+': '+str(row['checks'])+' checks passed',flush=True)

    point_hashes = {v['point_body.gd'] for v in files.values()}
    assert len(point_hashes)==1
    transfers.append({'name':'Same PointBody source in all nine halls','passed':True})
    for a,b,names in [
      ('SoftBodies_Cloth_Physics','SoftBodies_Carusell',['hanging_sheet.gd']),
      ('SoftBodies_Obsticals','SoftBodies_Obsticals_Part2',['pressure_panel.gd']),
      ('SoftBodies_Playground_of_Joy','SoftBodies_Affect_Theory_Visualization',['vessel_surface.gd','solver.gd']),
    ]:
        for name in names:
            assert files[a][name]==files[b][name]
            transfers.append({'name':a+' → '+b+': '+name+' unchanged','passed':True})
    for path,digest in json.loads((O/'protected-hashes.json').read_text()).items():
        assert sha((R/path).read_bytes()) == digest, path
    result={'passed':True,'started_at':started_at,'finished_at':datetime.now(timezone.utc).isoformat(),'scope':'Author-operated ghost-student reconstruction from exact printed code, existing executable per-hall probes and declared independent edits. Not an independent AI/human assessment or new headset test.','halls':results,'continuity':transfers,'total_checks':sum(x['checks'] for x in results),'printed_files':sum(len(v) for v in files.values()),'protected_sources_unchanged':True}
    dump(out/'ghost-checks.json',result)
    print(json.dumps({'passed':True,'halls':len(results),'checks':result['total_checks'],'carried_file_checks':len(transfers),'printed_files':result['printed_files']}),flush=True)

if __name__=='__main__': main()
