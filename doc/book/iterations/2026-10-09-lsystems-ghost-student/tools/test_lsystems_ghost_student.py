"""Fresh exact-text reconstruction of all eight lessons; never overwrite earlier receipts.

Reuses established native assertions, recording that provenance explicitly. This is
an authoring-AI ghost-student simulation, not an unfamiliar human learner study.
"""
from pathlib import Path
from datetime import datetime, timezone
import hashlib, json, re, runpy

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-lsystems-ghost-student'
CASES = [
    ('LSystems_Grammar_Lab', 'grammar_sentence_lesson', 'grammar_sentence_lesson', 'lsystems-a-sentence-and-a-reading', 'One rewrite of F yields five drawn segments; changing the turn angle changes the reading, not the sentence.'),
    ('LSystems_Growth', 'growth_branch_lesson', 'growth_branch_lesson', 'growth-what-a-branch-keeps', 'The first branch sentence draws five segments; closing a bracket restores the most recently saved state, including stride.'),
    ('LSystems_Grammars_And_Curves', 'curves_reader_lesson', 'curves_reader_lesson', 'curves-one-sentence-three-readers', 'One unchanged sentence can yield different geometry; exchanging displacement components reflects across x=y without editing stored heading.'),
    ('LSystems_Architecture', 'architecture_passage', 'architecture_passage_lesson', 'architecture-a-place-to-pass', 'Moving R after F moves the two room addresses while preserving the route; a 0.6 m collision body cannot pass a 0.4 m opening.'),
    ('LSystems_Competition', 'competition_turns', 'competition_turns_lesson', 'competition-the-next-turn', 'The first two uptakes are 2.25 and 1.98. Reversing order exchanges the recipients; winter still consumes before refusing rewriting.'),
    ('LSystems_Living', 'living_design', 'living_design_lesson', 'living-a-design-kept', 'Depth values 4.2 and 4.8 map to generation 2; depth 5 maps to 3. Held and planted records must not change when editing changes.'),
    ('LSystems_Shape_Grammars', 'shape_family', 'shape_family_lesson', 'shape-grammar-a-face-continues', 'After three passes on the two selected top triangles there are 84 faces; selecting one growing face gives 48. Growing is a shared eligibility tag.'),
    ('Assemblage_Same_Desire', 'assemblage_choices', 'assemblage_choices_lesson', 'assemblage-the-choices-remain', 'Changing the alphabet leaves random samples and choices intact. Adding a row retains eleven existing row records but changes their addresses.'),
]

def dump(p, value):
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    O.mkdir(parents=True, exist_ok=True)
    # Each invocation gets a new directory; logs from a failed attempt are evidence too.
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    run = O / 'runs' / stamp
    run.mkdir(parents=True)
    manifest = {'started_utc': stamp, 'scope': 'Fresh native execution of exact printed programs, guided variations, negative controls and supplied XRTools poses. Established author-led assertions reused. No headset or independent learner claim.', 'halls': []}
    for key, test, probe, old, prediction in CASES:
        out = run / key
        out.mkdir()
        sources = {}
        for kind in ['tutorial', 'final']:
            source = R / 'commons/maps' / key / (kind+'.md')
            (out / source.name).write_bytes(source.read_bytes())
            sources[source.relative_to(R).as_posix()] = sha(source)
        blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', (out/'tutorial.md').read_text(encoding='utf-8'), re.S)
        expected = {name: hashlib.sha256((code+'\n').encode()).hexdigest() for name, code in blocks}
        # Every relative preload is declared in this printed file set. The sole external
        # base class is the already-installed XRToolsPickable, declared by the lessons.
        for name, code in blocks:
            assert '$' not in code
            for dependency in re.findall(r'preload\("([^\"]+)"\)', code):
                assert dependency in expected or dependency.startswith('res://'), (key, name, dependency)
        old_rel = 'doc/book/iterations/2026-10-09-'+old
        new_rel = out.relative_to(R).as_posix()
        test_path = R/'tools'/('test_'+test+'.py')
        probe_path = R/'tools/probes'/(probe+'.gd')
        harness = test_path.read_text(encoding='utf-8')
        harness = harness.replace('Path(__file__).resolve().parents[1]', 'Path('+repr(R.as_posix())+')')
        harness = harness.replace(old_rel, new_rel).replace('res://tools/probes/'+probe+'.gd', 'res://'+new_rel+'/run.gd')
        (out/'run.py').write_text(harness, encoding='utf-8')
        (out/'run.gd').write_text(probe_path.read_text(encoding='utf-8').replace(old_rel, new_rel), encoding='utf-8')
        entry = {'map': key, 'prediction_before_execution': prediction, 'sources': sources, 'printed': expected,
                 'directory': out.relative_to(R).as_posix(), 'harness_source': test_path.relative_to(R).as_posix(),
                 'harness_sha256': sha(test_path), 'native_probe_source': probe_path.relative_to(R).as_posix(),
                 'native_probe_sha256': sha(probe_path)}
        manifest['halls'].append(entry)
    manifest['chosen_variation_before_execution'] = {
        'hall': 'LSystems_Competition', 'edit': 'FRACTION 0.15 -> 0.25; roots, patches, rule and scheduler unchanged.',
        'prediction': '25 cells * 0.6 * 0.25 = 3.75 first. Second: (20 * 0.45 + 5 * 0.6) * 0.25 = 3.0. Remaining total 233.25. Reversing order swaps uptake but leaves the completed-pair field equal. Both sentences still advance one generation.',
        'invariant': 'Resource remaining + cumulative uptake = initial 240. Rewriting and point class unchanged.',
        'status': 'Chosen by the same authoring AI, unprescribed by the tutorial; not an independent learner.'}
    dump(run/'manifest.json', manifest)
    dump(O/'latest-run.json', {'directory': run.relative_to(R).as_posix(), 'complete': False})
    results = []
    for entry in manifest['halls']:
        out = R/entry['directory']
        print('RUN '+entry['map'], flush=True)
        try:
            runpy.run_path(str(out/'run.py'), run_name='__main__')
            receipt = json.loads((out/'checks.json').read_text(encoding='utf-8'))
            assert receipt['passed']
            for name, digest in entry['printed'].items(): assert sha(out/'printed'/name)==digest
            result = {'map': entry['map'], 'passed': True, 'checks': len(receipt['checks']),
                      'source_comparisons': receipt.get('production_comparisons', receipt.get('source_comparisons', 0)),
                      'receipt': (out/'checks.json').relative_to(R).as_posix()}
        except Exception as error:
            result = {'map': entry['map'], 'passed': False, 'error': repr(error)}
        results.append(result)
        dump(run/'results.json', {'halls': results, 'complete': len(results)==8, 'passed': all(x['passed'] for x in results)})
        print(json.dumps(result), flush=True)
    for entry in manifest['halls']:
        for source, digest in entry['sources'].items(): assert sha(R/source)==digest, 'Source changed during run: '+source
    passed = all(x['passed'] for x in results)
    dump(O/'latest-run.json', {'directory': run.relative_to(R).as_posix(), 'complete': True, 'passed': passed})
    print(json.dumps({'run': str(run), 'passed': passed, 'checks': sum(x.get('checks', 0) for x in results), 'files': sum(len(x['printed']) for x in manifest['halls'])}), flush=True)
    if not passed: raise SystemExit(1)

if __name__ == '__main__': main()
