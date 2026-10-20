"""One-shot incorporation of the reviewed Transformation tutorials, preserving later reflections."""
from pathlib import Path
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DRAFT = ROOT / 'doc/book/iterations/2026-10-06-transformation-tutorial-drafts'
HALLS = json.loads((ROOT / 'commons/maps/sequences/transformation.json').read_text(encoding='utf-8'))['sequences']['transformation']['maps']

def put(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

def replace_once(text, old, new):
    assert text.count(old) == 1, old
    return text.replace(old, new)

def main():
    assert not (HERE / 'promotion.json').exists(), 'Already incorporated; edit current canonical sources deliberately.'
    protected = {}
    records = []
    # Preserve the source distinctions; the older paired final drafts are not the current reflections.
    for hall in HALLS:
        for name in ('tutorial.md', 'final.md', 'map_data.json'):
            source = ROOT / 'commons/maps' / hall / name
            target = HERE / 'before' / hall / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            if name != 'tutorial.md':
                protected[source.relative_to(ROOT).as_posix()] = sha(source)
    for relative in ('commons/maps/curriculum_spine.json', 'commons/maps/sequences/transformation.json',
                     'commons/maps/sequences/array_tutorial.json', 'commons/maps/Array/final.md',
                     'commons/maps/Array/map_data.json', 'commons/maps/Primitives_Melencolia/tutorial.md',
                     'doc/book/iterations/2026-10-06-array-a-slot-kept/tutorial.md'):
        protected[relative] = sha(ROOT / relative)
    put(HERE / 'preserved-before.json', json.dumps(protected, indent=2) + '\n')
    for hall in HALLS:
        source = DRAFT / hall / 'tutorial.md'
        text = source.read_text(encoding='utf-8')
        if hall == 'Trans_Pre':
            text = replace_once(text,
                'The construction of faces has already done its work. This lesson makes one animated pickup that you collect by walking into it.',
                'The construction of faces has already done its work. Keep CubeBody for the earlier constructions; this sequence uses a whole `BoxMesh`, so there is no face-list helper to carry. This lesson makes one animated pickup that you collect by walking into it.')
            text = replace_once(text,
                'The museum supplies the desktop walker in group `em_walker` on layer 1, and the XR body in group `player_body` on layer 20. The mask listens to both layers; the group check accepts the player. These are the declared connections to the existing museum.',
                'The museum supplies your body in group `player_body` on collision layer 20. The mask listens to that layer; the group check accepts the player. Layer 1 and `em_walker` retain the prepared preview support described in Day Zero. These names connect this small script to the existing museum; you do not build another player here.')
        elif hall == 'Trans_Scale':
            text = replace_once(text,
                'Bring back the familiar black sphere as a size witness, outside the parent that will change.',
                'Use the familiar black sphere shape as a fixed size witness, outside the parent that will change. This witness is a mesh without pickup or collision; the earlier PointBody class remains available for interactive points.')
        elif hall == 'Trans_Body':
            text = replace_once(text,
                'The lookup selects the supplied XR body in group `player_body`, or the desktop museum walker in `em_walker`. These are named connections to the existing player. If neither exists, the cube remains at its starting pose; the script does not invent a player.',
                'The lookup finds your supplied museum body through `player_body`. The fallback retains Day Zero\'s prepared preview connection. If the player is absent, the cube remains at its starting pose. This is a reference to the existing player, not a second body built by the lesson.')
        elif hall == 'Trans_Pit':
            text = replace_once(text,
                'You have made a response from three known operations. Arrays can now repeat a body and give each instance its own place or variation. Keep this working opening as one composition; not every object in the next hall needs to inherit its sensor.',
                'You have made a response from three known operations. Keep this working opening as one composition. Its two leaves also returned to arrays and indices from Trace: one index connects a body, its visible mesh and its collision shape. The fixed frame stays outside that collection.\n\nIn Arrays, return to Trans_Pre\'s one-metre `BoxMesh` and collection area. Begin with still cubes, give each copy an address, then collect one without shifting the others\' addresses. Carry the cube construction, local placement, loops and overlap detection; leave the door\'s animation and solid leaves here. We reuse code and understanding across halls, rather than transport a live node. The next question is what the collection must remember after one of its bodies disappears.')
        code = re.findall(r'<!-- student-code:lesson.gd -->\s*```gdscript\n(.*?)^```', text, re.M | re.S)
        assert len(code) == 1 and code[0] == (DRAFT / hall / 'lesson.gd').read_text(encoding='utf-8')
        assert '$' not in code[0] and code[0].count('func _ready()') == 1
        canonical = ROOT / 'commons/maps' / hall / 'tutorial.md'
        # Refuse to overwrite an intervening edit after taking the snapshot.
        assert canonical.read_bytes() == (HERE / 'before' / hall / 'tutorial.md').read_bytes()
        put(canonical, text)
        put(HERE / hall / 'tutorial.md', text)
        put(HERE / hall / 'lesson.gd', code[0])
        shutil.copyfile(ROOT / 'commons/maps' / hall / 'final.md', HERE / hall / 'final.md')
        records.append({'map':hall, 'draft':source.relative_to(ROOT).as_posix(),
                        'before_sha256':sha(HERE / 'before' / hall / 'tutorial.md'),
                        'canonical_sha256':sha(canonical), 'code_sha256':sha(HERE / hall / 'lesson.gd'),
                        'code_unchanged_from_review':True, 'reflection_preserved':True})
    shutil.copyfile(DRAFT / 'verify.gd', HERE / 'verify.gd')
    runner = (DRAFT / 'run_checks.py').read_text(encoding='utf-8')
    runner = runner.replace('from build import HERE, ROOT, HALLS, put, sha', 'from prepare import HERE, ROOT, HALLS, put, sha')
    runner = runner.replace("prefix='ada-transformation-drafts-'", "prefix='ada-transformation-book-'")
    runner = runner.replace('Ada Transformation draft tests', 'Ada Transformation canonical tutorial tests')
    runner = runner.replace("        blocks = re.findall", "        canonical = ROOT / 'commons/maps' / hall / 'tutorial.md'\n        assert text == canonical.read_text(encoding='utf-8'), 'Canonical/edition mismatch: ' + hall\n        blocks = re.findall")
    runner = runner.replace("    pins = {}", "    pins = {f'commons/maps/{hall}/tutorial.md': sha(ROOT / 'commons/maps' / hall / 'tutorial.md') for hall in HALLS}")
    put(HERE / 'run_checks.py', runner)
    put(HERE / 'promotion.json', json.dumps({'date':'2026-10-12',
        'authorization':'Author requested starting with Transformation, using existing drafts and retaining the lineage into Arrays; one sequence at a time.',
        'scope':'Seven canonical tutorials. Reviewed learner code preserved. Current final texts, museum runtime, sequence order and Arrays sources preserved.',
        'records':records}, indent=2) + '\n')
    print('Incorporated seven tutorials; learner code byte-identical to reviewed programs. Ready for fresh native checks.')

if __name__ == '__main__':
    main()
