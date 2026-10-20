"""Fresh-file reconstruction of Tiling from the current printed tutorials."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import datetime
import hashlib
import importlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-tiling-ghost-student'
BLOCKS = r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl|ini)\n(.*?)\n```'
LESSONS = [
    ('Pattern_Disco', 'disco', '01_palette_return.gd', 'equal-grey', [
        ('Palette.new([Color("172051"), Color("fc62ad")])', 'Palette.new([Color(0.4, 0.4, 0.4), Color(0.4, 0.4, 0.4)])')],
     'Equal palette entries hide phase changes; a different palette reveals the retained phase. Geometry stays fixed.'),
    ('Pattern_Foundry', 'foundry', '02_source_motif.gd', 'third-row', [
        ('[[0, 1, 0], [0, 0, 1]]', '[[0, 1, 0], [0, 0, 1], [2, 0, 0]]')],
     'Adding a third source row changes the vertical period to three. The five-by-five receiver stays the same size; (0,2) becomes mint.'),
    ('Tutorial_Pattern', 'pattern', '03_reflected_reader.gd', 'symmetric', [
        ('[[0, 1, 0], [0, 0, 1]]', '[[0, 1, 0], [2, 0, 2]]')],
     'Symmetric rows conceal the difference between reading forward and backward. Editing one edge reveals it again.'),
    ('Array_Patterns', 'surface', '04_surface_frame.gd', 'narrower', [
        ('[0.32, 0.48]', '[0.24, 0.36]')],
     'Three source columns span .72 or 1.08 metres. Table/wall placement preserves addresses, colours and point-height gating.'),
    ('Symmetry_Seventeen', 'symmetry', '05_glide_reader.gd', 'four_rows', [
        ('    assert(source.size()', '    source = [[0, 1, 0], [0, 0, 1], [2, 0, 0], [0, 2, 0]]\n    assert(source.size()')],
     'Four rows give a two-row shift on reflected blocks. Surface [0,3] reads [2,2]; [2,4] reads [0,1].'),
    ('Pattern_Temple', 'temple', '06_receivers.gd', 'four_columns', [
        ('var source := [[0, 1, 0], [0, 0, 1]]', 'var source := [[0, 1, 2, 0], [2, 0, 1, 2]]')],
     'A four-column source changes repeat widths. Copying records gives equal values without making later edits shared.'),
    ('Ribbon_Patterns_01', 'ribbon01', '07_layer_reader.gd', 'three_reverse', [
        ('const LAYER_COUNT := 4\nconst SHIFT_STEP := 1', 'const LAYER_COUNT := 3\nconst SHIFT_STEP := -1')],
     'Three layers store 75 values; a slice displays 25. Negative shifts wrap to valid source columns. Hiding is not deletion.'),
    ('Ribbon_Patterns_02', 'ribbon02', '08_equal_targets.gd', 'grey_mint', [
        ('var source := [[0, 1, 0], [0, 0, 1]] # [z][x]\nvar palette = Palette.new([Color("172051")', 'var source := [[0, 1, 0], [0, 0, 2]] # [z][x]\nvar palette = Palette.new([Color(0.5, 0.5, 0.5)')],
     'Selecting the edited last source cell gives mint to both targets and the connector. Surround operations preserve their shared colour.'),
    ('Ribbon_Patterns_03', 'ribbon03', '09_studio_lesson.tscn', 'three_vertical', [
        ('vec2(repeats, 2.0)', 'vec2(repeats, 3.0)')],
     'Three vertical repeats span two-thirds of a metre on the wall. UV (.15,.20) reads gold at four horizontal repeats. Saving still sends the original two-repeat shader to the wardrobe.'),
]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')


def prepare():
    assert not (OUT / 'manifest.json').exists(), 'Preserve first reconstruction; do not overwrite its manifest.'
    sequence = ROOT / 'commons/maps/sequences/tiling.json'
    order = json.loads(sequence.read_text())['sequences']['tiling']['maps']
    assert order == [lesson[0] for lesson in LESSONS]
    protected = {sequence.relative_to(ROOT).as_posix(): sha(sequence)}
    rows = []
    for hall, probe, main, variation, edits, prediction in LESSONS:
        text = (ROOT / 'commons/maps' / hall / 'tutorial.md').read_text(encoding='utf-8-sig')
        blocks = dict(re.findall(BLOCKS, text, re.S))
        assert blocks and main in blocks
        for filename in ['tutorial.md', 'final.md', 'map_data.json', 'em_plan.json']:
            path = ROOT / 'commons/maps' / hall / filename
            if path.exists():
                protected[path.relative_to(ROOT).as_posix()] = sha(path)
                if filename.endswith('.md'):
                    write(OUT / 'packet' / hall / filename, path.read_text(encoding='utf-8-sig'))
        for kind in ['printed', variation]:
            for name, original in blocks.items():
                code = original
                edited_file = '09_fabric_sample.gdshader' if probe == 'ribbon03' else main
                if kind == variation and name == edited_file:
                    for old, new in edits:
                        assert code.count(old) == 1, (hall, old)
                        code = code.replace(old, new)
                write(OUT / hall / 'learner' / kind / name, code + '\n')
        dependencies = []
        for name, code in blocks.items():
            for dependency in re.findall(r'["\']((?:res://)?[^"\'\n]+\.(?:gd|gdshader|tscn))["\']', code):
                path = ROOT / dependency[6:] if dependency.startswith('res://') else OUT / hall / 'learner/printed' / dependency
                assert path.exists(), (hall, name, dependency)
                dependencies.append({'from': name, 'dependency': dependency, 'exists': True, 'sha256': sha(path)})
        row = {'hall': hall, 'probe': probe, 'main': main, 'variation': variation,
               'prediction': prediction, 'printed_files': list(blocks), 'dependencies': dependencies,
               'source_sha256': sha(ROOT / 'commons/maps' / hall / 'tutorial.md'),
               'printed_sha256': {name: sha(OUT / hall / 'learner/printed' / name) for name in blocks}}
        rows.append(row)
        for filename in [f'tools/test_tiling_{probe}.py', f'tools/probes/tiling_{probe}_student.gd']:
            p = ROOT / filename
            write(OUT / 'reproduce' / p.name, p.read_text(encoding='utf-8-sig'))
            protected[filename] = sha(p)
    text = '# Predictions before execution\n\nSame-assistant ghost-student rehearsal. This assistant already knows the work; this is not a blind reader or human learning study. Fresh files come only from complete printed listings. The museum project and XR Tools are declared prerequisites. Existing teacher probes are labelled regressions, not independent new evidence of understanding.\n\n'
    text += '\n\n'.join(f'## {i+1}. {r["hall"]}\n\n{r["prediction"]}' for i, r in enumerate(rows))
    write(OUT / 'predictions-before.md', text + '\n')
    manifest = {'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                'scope': 'fresh-file same-assistant reconstruction in supplied museum project',
                'rows': rows, 'protected': protected, 'predictions_sha256': sha(OUT / 'predictions-before.md')}
    write(OUT / 'manifest.json', json.dumps(manifest, indent=2) + '\n')
    print(f'Prepared {len(rows)} halls, {sum(len(r["printed_files"]) for r in rows)} printed files; no production code copied to fill omissions.')


def run_hall(row):
    module = importlib.import_module('test_tiling_' + row['probe'])
    module.OUT = OUT / row['hall']
    results = [module.run('printed'), module.run(row['variation'], True)]
    return {'hall': row['hall'], 'passed': all(r['passed'] for r in results), 'results': results}


def run():
    manifest = json.loads((OUT / 'manifest.json').read_text())
    assert sha(OUT / 'predictions-before.md') == manifest['predictions_sha256']
    assert not (OUT / 'regression-results.json').exists(), 'Preserve first run results.'
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(run_hall, manifest['rows']))
    protected = {path: sha(ROOT / path) == digest for path, digest in manifest['protected'].items()}
    result = {'completed_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'all_passed': all(r['passed'] for r in results),
              'checks': sum(case['checks'] for r in results for case in r['results']),
              'runs': sum(len(r['results']) for r in results), 'results': results, 'protected_unchanged': protected}
    write(OUT / 'regression-results.json', json.dumps(result, indent=2) + '\n')
    print(json.dumps({k: result[k] for k in ['all_passed', 'checks', 'runs']}))
    assert result['all_passed'] and all(protected.values())


if __name__ == '__main__':
    {'prepare': prepare, 'run': run}[sys.argv[1]]()
