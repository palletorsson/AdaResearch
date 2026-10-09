from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import zipfile
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
HALLS = ['Trans_Pre', 'Trans_Introduction', 'Trans_Translation', 'Trans_Rotation', 'Trans_Scale', 'Trans_Body', 'Trans_Pit']
BRIEFS = [
    ('One cube, cumulative motion', 'Cube rises → add turn → add pulse → collect by walking. Teach whole-object transforms; time supports motion; overlap supports collection. Keep geometry fixed.', 'Cube shape and creation, coordinates, initialization and updates.', 'One box; elapsed wave; three transform assignments; area and player-filtered signal.', 'Disable operations independently; stretch the wave period; collect through actual overlap.', 'Score, flourish, a general interaction framework.'),
    ('Three ways to reach', 'Reuse translate/rotate/scale in three models of the installed crossings. Hold poses; animate; move the far bank and inspect the gap.', 'Pre’s cube and transforms; functions and loops from Primitives.', 'Repeat known construction with a returning box function; interpolate a pose fraction.', 'At full pose, compare bank edges; move the far bank half a metre without changing the span.', 'Rider transport, physical support and detailed control wiring.'),
    ('Position, then route', 'Move a level box diagonally. Compare a rise-then-across journey to the same destination. Keep orientation and size.', 'Travel study; displacement from Lines; time and interpolation.', 'Two endpoints; direct interpolation; one optional corner and a branch.', 'Predict halfway and final positions for both paths; add Z to the destination.', 'General waypoint machines, curved paths and constant-speed reparameterization.'),
    ('A chosen centre', 'Turn the box through a parent pivot. Mark a face; offset the box; change the axis. Separate local position from world movement.', 'Cube, time, local/world coordinates; hierarchy already encountered.', 'Pivot node; fixed child offset; axis-angle orientation; attached mark.', 'Quarter-turn centre and face position; fixed internal distances; full return; another axis.', 'Multiple rotation order, rider orientation and sweep rendering.'),
    ('A group changes size', 'Three boxes make a doorway; a black point remains outside its parent. Compare uniform enlargement and width-only change.', 'Parent-child relation; box function; familiar sphere construction.', 'One scaled parent; known meshes placed around a threshold origin.', 'Predict clear dimensions and unchanged witness under 4×, width-only and 2× XY changes.', 'Room relocation, solid passage and material theory.'),
    ('Approach supplies the value', 'World-space horizontal distance drives one cube’s bounded scale or turn. Preserve its floor contact; departure restores it.', 'Scale, turn, vectors, conditions and the museum player contract.', 'Declared player group lookup; range mapping; response function.', 'Near/middle/far values; height independence; return; extend the sensing reach.', 'Multi-visitor blending, smoothing and cell removal.'),
    ('Compose an opening', 'Two boxes translate, turn and shrink beside a fixed frame. Actual player overlap requests opening; absence requests return.', 'All three transforms; construction function; array, loop and Area3D.', 'Two leaves; one bounded progress value; continuing occupancy query.', 'Closed/middle/open poses; slower duration; greater slide; props ignored; either visitor holds it open.', 'Solid leaf collision, staged movement and the installed closing delay.'),
]

def put(p, text):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding='utf-8', newline='\n')

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    baseline = HERE / 'preserved-before.json'
    if not baseline.exists():
        pins = {}
        for hall in HALLS:
            for name in ['tutorial.md', 'final.md', 'map_data.json']:
                source = ROOT / 'commons/maps' / hall / name
                pins[source.relative_to(ROOT).as_posix()] = sha(source)
                put(HERE / 'before' / hall / name, source.read_text(encoding='utf-8-sig'))
        put(baseline, json.dumps(pins, indent=2) + '\n')
    for path, digest in json.loads(baseline.read_text()).items():
        assert sha(ROOT / path) == digest, 'Concurrent source change: ' + path
    contract = []
    book = ['# Transformation — seven tutorial drafts\n\n6 October 2026 · For author and independent AI review. Not yet accepted or installed as the canonical tutorial track.\n\nWe are working inside the existing Endless Museum. Each lesson prints one complete reduced study. The museum supplies the room, camera, light and player; named player groups are the only scene lookup. All new lesson geometry is built in code. A new study root in each hall reconstructs the selected relation; no claim is made that a runtime node travels between halls. The familiar BoxMesh and learned operations continue. The reflective final.md track and installed exhibits are unchanged.\n\nRead for spatial progression and explanatory sufficiency. The illustrations are imagined encounters, not runtime test evidence. Full code and native checks are available with this draft.\n']
    previous = None
    for i, hall in enumerate(HALLS):
        code = (HERE / hall / 'lesson.gd').read_text(encoding='utf-8')
        template = (HERE / hall / 'text.md').read_text(encoding='utf-8')
        assert template.count('{{CODE}}') == 1
        text = template.replace('{{CODE}}', '<!-- student-code:lesson.gd -->\n```gdscript\n' + code + '```')
        put(HERE / hall / 'tutorial.md', text)
        book.append('\n---\n\n<!-- hall:' + hall + ' -->\n\n' + text)
        title, short, bring, build, check, later = BRIEFS[i]
        contract.append({'map': hall, 'status': 'draft-awaiting-author-review', 'title': title, 'short': short, 'bring': bring, 'given': 'Existing Endless Museum room, camera, light and player; desktop em_walker/layer 1 or XR player_body/layer 20. Collision and riding in installed artifacts only, except the explicitly created overlap areas.', 'build': build, 'check': check, 'later': later, 'predecessor': previous, 'printed_files': ['lesson.gd'], 'source_sha256': sha(HERE / hall / 'lesson.gd'), 'tutorial_sha256': sha(HERE / hall / 'tutorial.md')})
        old = (HERE / previous / 'lesson.gd').read_text(encoding='utf-8').splitlines(keepends=True) if previous else (HERE / 'before' / hall / 'tutorial.md').read_text(encoding='utf-8').splitlines(keepends=True)
        put(HERE / hall / 'continuation.diff', ''.join(difflib.unified_diff(old, code.splitlines(keepends=True), fromfile=previous or 'previous Trans_Pre tutorial', tofile=hall + '/lesson.gd')))
        previous = hall
    put(HERE / 'ALL_TUTORIALS.md', '\n'.join(book))
    put(HERE / 'contracts.json', json.dumps(contract, ensure_ascii=False, indent=2) + '\n')
    report = json.loads((HERE / 'verification.json').read_text()) if (HERE / 'verification.json').exists() else None
    status = f"{report['assertions']} native checks passed; {len(report['faults'])} deliberate faults rejected; {report['variant_count']} exercise variants executed." if report else 'Native verification pending.'
    put(HERE / 'ALL_TUTORIALS.md', '\n'.join(book) + '\n\n---\n\n## For the independent reviewer\n\n' + status + '\n\nThese checks execute the exact printed code and exercise edits in Godot 4.6, including actual physics overlap with simulated player bodies. They do not establish human understanding or physical-headset comfort. Crossing and solid-door physics remain in the installed museum artifacts; the reduced reconstructions clearly name that boundary.\n\nPlease assess each hall as KEEP / CHANGE / MISSING. Is transformation still the subject? Are the new operations sufficiently explained? Does each lesson reuse earlier understanding and leave a useful capability? Identify the smallest correction to a specific passage. Do not turn the sequence into an exhaustive programming syllabus or require every illustrated artifact to become an exercise.\n')
    put(HERE / 'REVIEW.md', '# Transformation review handoff\n\n' + status + '\n\nRead [all seven tutorials](ALL_TUTORIALS.md). These are review drafts. Canonical tutorial.md, final.md and museum code are preserved.\n\n## What the author has asked us to preserve\n\n- Existing Endless Museum, existing encounters. Select what to teach; do not reconstruct every artifact.\n- Transformation is the subject. Programming gives access to movement, turning, size, space and response.\n- One familiar whole BoxMesh; no face-list machinery in this sequence. Black, white and grey.\n- Pre accumulates rise, turning and pulsing, then explains walk-over collection. Pickup here means overlap, not grabbing.\n- One complete small program per hall, printed once. No hidden lesson nodes, no unexplained scene references.\n- Name what was kept, removed and added. Final reflection has another job.\n- Test exact printed code and exact exercise edits; do not infer understanding from a pass.\n\n## Questions for the independent reader\n\n1. Can you follow the spatial purpose of each lesson before reading its code?\n2. Does each new operation have enough explanation to reconstruct and vary it? Where is there too much?\n3. Does the sequence reuse earned understanding without pretending different runtime objects are literally the same instance?\n4. Is sine as a short timing tool in Pre sufficient, or does it need a simpler introductory sentence or diagram?\n5. Do the model/installed-artifact boundaries remain clear, especially crossing physics and the final door?\n6. Does the complete code stay readable without repeated setup explanations?\n\nReply per hall: KEEP / CHANGE / MISSING, with the exact passage and the smallest useful correction. Do not expand into a general programming syllabus. Do not treat every illustrated artifact as a required exercise.\n\n## Verification scope\n\nNative Godot executes code extracted from each printed tutorial plus tested source edits. Tests compare transforms and geometry, timing, reference frames and real physics overlap with synthetic bodies on the declared desktop/XR layers. The harness supplies the declared room context and simulated player; it does not construct missing lesson objects. No new in-headset trial, human learner study or verification of the full museum’s rider system is claimed.\n\n[Machine-readable evidence](verification.json) · [Focus contracts](contracts.json)\n')
    make_pages(status, contract)
    with zipfile.ZipFile(HERE / 'transformation-review.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in ['ALL_TUTORIALS.md', 'REVIEW.md', 'contracts.json', 'verification.json', 'verify.gd', 'run_checks.py', 'native-project.godot']:
            p = HERE / name
            if p.exists(): archive.write(p, name)
        for hall in HALLS:
            for name in ['lesson.gd', 'tutorial.md', 'continuation.diff']:
                archive.write(HERE / hall / name, hall + '/' + name)
        for p in (HERE / 'variants').rglob('*.gd') if (HERE / 'variants').exists() else []:
            archive.write(p, p.relative_to(HERE))
    print('Built seven review drafts; canonical sources preserved.')

CSS = '''body{margin:0;background:#f1eee8;color:#242321;font:19px/1.65 Georgia,serif}header,main{max-width:980px;margin:auto;padding:30px}h1{font-size:2.4em;line-height:1.12}h2{margin-top:2em;line-height:1.25}h3{line-height:1.3}a{color:#684c62}nav{display:flex;gap:18px;flex-wrap:wrap;font:15px/1.5 system-ui}pre{background:#22252b;color:#f5f3eb;padding:23px;border-radius:6px;overflow:auto;font:13px/1.65 Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere}code{font-size:.9em}pre code{font-size:inherit}table{border-collapse:collapse;font-size:16px;width:100%}td,th{padding:10px;border-bottom:1px solid #ccc;text-align:left;vertical-align:top}img{max-width:100%;height:auto}.badge{font:13px system-ui;letter-spacing:.1em;text-transform:uppercase}.quiet{font:15px/1.6 system-ui;color:#595651}.card{background:#fffdf8;padding:28px;margin:28px 0;border-top:3px solid #6a5965}.spread{display:grid;grid-template-columns:1fr 1fr;gap:36px;max-width:1700px}.spread article{min-width:0}details{margin:20px 0}summary{cursor:pointer}.plate{max-width:430px;display:block;margin:auto}@media(max-width:1000px){.spread{display:block}}@media print{nav,details,.badge{display:none}body{background:white;font-size:11pt}header,main{padding:0}.spread{display:block}pre{white-space:pre-wrap;background:#f4f4f4;color:black}h1{break-before:page}}'''

def shell(title, content, nav='', wide=False):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + CSS + '</style></head><body><header><p class="badge">Endless Museum · Transformation · Review draft</p><nav>' + nav + '</nav></header><main' + (' class="spread"' if wide else '') + '>' + content + '</main></body></html>'

def render(text):
    out = markdown.markdown(text, extensions=['fenced_code', 'tables'])
    # Existing reflective relative assets are normalized for the localhost review viewer.
    out = re.sub(r'(src|href)="/book-review/', r'\1="http://localhost:3003/book-review/', out)
    return out

def make_pages(status, contracts):
    links = '<a href="index.html">Overview</a><a href="all.html">Read all</a><a href="ALL_TUTORIALS.md">Markdown</a><a href="transformation-review.zip">Code + review ZIP</a>'
    content = '<h1>From a moving cube to an opening</h1><p>Seven tutorial drafts, ready to question before acceptance.</p><p class="quiet">' + html.escape(status) + '</p><p>The existing museum supplies the encounter. Each lesson reconstructs one selected relation in a complete small program. The printed examples use a whole BoxMesh; the reflective manuscripts remain unchanged.</p><p><a href="REVIEW.md">Brief for your other AI</a> · <a href="verification.json">Native evidence</a></p>'
    slugs = ['trans-pre', 'trans-introduction', 'trans-translation', 'trans-rotation', 'trans-scale', 'trans-body', 'trans-pit']
    for i, (hall, contract) in enumerate(zip(HALLS, contracts)):
        content += '<section class="card"><p class="badge">' + str(i + 1) + ' / ' + hall + '</p><h2>' + html.escape(contract['title']) + '</h2><p>' + html.escape(contract['short']) + '</p><p><a href="' + hall + '/tutorial.html">Read tutorial</a> · <a href="' + hall + '/parallel.html">Tutorial left / reflection right</a> · <a href="' + hall + '/lesson.gd">Working code</a></p><details><summary>Illustrated encounter</summary><img class="plate" alt="Transformation reflective comic for ' + hall + '" src="../2026-10-06-final-comic-plates/' + slugs[i] + '.png"><p class="quiet">Existing imagined illustration, not a capture of the tutorial code. Some plates retain earlier colours; the new studies use grayscale.</p></details></section>'
        nav = '<a href="../index.html">Overview</a><a href="../all.html">All seven</a>'
        if i > 0: nav += '<a href="../' + HALLS[i-1] + '/tutorial.html">Previous</a>'
        if i < len(HALLS)-1: nav += '<a href="../' + HALLS[i+1] + '/tutorial.html">Next</a>'
        text = (HERE / hall / 'tutorial.md').read_text(encoding='utf-8')
        put(HERE / hall / 'tutorial.html', shell(contract['title'], render(text), nav + '<a href="parallel.html">Facing texts</a>'))
        final = (ROOT / 'commons/maps' / hall / 'final.md').read_text(encoding='utf-8')
        put(HERE / hall / 'parallel.html', shell(contract['title'], '<article><p class="badge">Tutorial · draft</p>' + render(text) + '</article><article><p class="badge">Reflection · existing final.md</p>' + render(final) + '</article>', nav, True))
    put(HERE / 'index.html', shell('Transformation tutorial drafts', content, links))
    put(HERE / 'all.html', shell('Transformation — all seven tutorials', render((HERE / 'ALL_TUTORIALS.md').read_text(encoding='utf-8')), links))

if __name__ == '__main__':
    main()
