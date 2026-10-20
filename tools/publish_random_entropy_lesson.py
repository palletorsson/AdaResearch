"""Publish the second Randomness lesson with its native evidence and review packet."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote
import markdown
from publish_randomness_revision import ROOT, OUT, PLAN, STYLE, page, publish_plan

HERE = OUT / 'Random_Entropy'


class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.links = []

    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k, v in attrs if k in ['href', 'src'])


def main():
    tests = json.loads((HERE / 'tests.json').read_text())
    assert all(r['passed'] == r['expected_pass'] for r in tests['results'])
    run = ROOT / 'ada_run/encounter_pilot/Random_Entropy'
    receipt = json.loads((run / 'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks']) == 26
    assert receipt['observations']['student_bay'][0] < 17
    log = (run / 'engine.log').read_text(encoding='utf8', errors='replace')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum = HERE / 'museum'; museum.mkdir(exist_ok=True)
    for p in run.iterdir():
        if p.suffix == '.png' or p.name in ['report.json', 'engine.log', 'source_manifest.json', 'spec.json']:
            shutil.copy2(p, museum / p.name)
    rejected = json.loads((HERE / 'first-museum-attempt/report.json').read_text())
    assert not rejected['passed']
    baseline = json.loads((HERE / 'before-manifest.json').read_text())
    protected = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == h
                 for p, h in baseline.items() if not p.endswith(('tutorial.md', 'final.md'))}
    assert all(protected.values()), protected
    texts = {n: (ROOT / f'commons/maps/Random_Entropy/{n}.md').read_text(encoding='utf8')
             for n in ['tutorial', 'final']}
    parity = []
    for name, code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```', texts['tutorial'], re.S):
        extracted = HERE / 'extracted' / name
        assert code + '\n' == extracted.read_text(encoding='utf8')
        assert code + '\n' == (ROOT / 'doc/book/studies/randomness-lineage' / name).read_text(encoding='utf8')
        assert hashlib.sha256(extracted.read_bytes()).hexdigest() == tests['printed_sha256'][name]
        parity.append(name)
    assert len(parity) == 2
    images = HERE / 'images'; images.mkdir(exist_ok=True)
    shutil.copy2(ROOT / 'doc/book/figures/randomness/ruin-waiting-museum.png', images / 'ruin-waiting-museum.png')
    def render_source(t):
        return t.replace('/book-images/figures/randomness/ruin-waiting-museum.png', 'images/ruin-waiting-museum.png')
    differences = []
    for name, text in texts.items():
        (HERE / f'{name}.md').write_text(text, encoding='utf8')
        before = (HERE / 'before' / f'{name}.md').read_text(encoding='utf8')
        diff = ''.join(difflib.unified_diff(before.splitlines(True), text.splitlines(True),
                       fromfile=f'before/{name}.md', tofile=f'after/{name}.md'))
        (HERE / f'{name}.diff').write_text(diff, encoding='utf8')
        differences.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')

    report = '''# Random Entropy — keep the counts, change the neighbours

**Second of fourteen Randomness halls revised and tested.** The tutorial now builds one small comparison from the familiar cube and held point. The reflection keeps the larger encounter with the ledger, jar, displaced points, ruin and black-and-white room.

## What the student learns

The last hall changed the assignment of random values. This hall retains a record and asks what counting it keeps. Sixteen integer symbol IDs select four colours. Two rows show the original and a copy. Sorting the copy changes the neighbours while retaining the counts, the original and the generator state. Four bars show shares on a fixed scale.

The student meets counting and copying before the entropy calculation. A deliberately regular cycle supplies the decisive test: **0123 repeated has H = 2 bits per symbol**, the maximum marginal entropy for four categories, even though its next entry is easy to predict. Sorting that cycle reduces unlike adjacent pairs from fifteen to three without changing H. The label's “neighbours” number counts unlike pairs, not all pairs.

The categorical sample is new. It is not an unexplained conversion of the previous RGB record or an invented save/load handoff. Cube construction, local RNG and the unchanged PointBody return; the new operation is explicit.

## What changed in the texts

`tutorial.md` now contains the complete 137-line study and unchanged 26-line PointBody, followed by focused explanations and two actual code edits. It distinguishes the original from its copy, category IDs from colour values, empirical counts from source probabilities, and marginal entropy from predictability or thermodynamic entropy. The complete code builds every display object and label inside the prepared museum.

`final.md` keeps its existing scenes and questions. Five code blocks became short prose, so the reader can follow what the gauge leaves out without switching into implementation. Its handoff remains concrete: the ruin already chooses among eligible exposed stones; Random Remove makes that eligible set the next subject. The historic ruin image is retained and identified as existing documentation, not a new capture from this test.

## Native evidence

| Reconstruction | Result |
|---|---|
| Printed program extracted into fresh files | 31 checks passed |
| Actual cycle edit in the printed append line | 31 checks passed |
| Actual single-symbol edit | 31 checks passed |
| Aliasing the original instead of copying | Rejected; original order is lost |
| Dividing by the alphabet size instead of the sample total | Rejected; known entropy values fail |
| Spending a random request while sorting | Rejected; generator state changes |
| Current museum with a temporary learner reconstruction | 26 checks passed, including camera checks |

The code checks cover initialized labels, distinct materials, exact draw requests, replay, copying, zero-count handling and the known values 0, 1.75 and 2 bits. A second instance with twelve entries and three categories checks transfer to another alphabet: H = log₂(3), with eleven versus two unlike pairs. Both instances keep independent records and generators.

The real museum check compares the student's counts and entropy with the installed ledger's calculation. It also verifies the installed SORT and CONTRAST operations, floor and a clear approach at the learner bay, and the inherited point's action dispatch at prescribed positions. The installed contrast has counts `[109, 46, 20, 17, 6, 2, 0, 0, 0, 0]` and H ≈ 1.818, supporting the reflection's specific description.

## What failed and changed

The first proposed placement treated the full map width as the entrance chamber's width. The study and its approach had no floor. The museum's first chamber is narrower. The corrected bay is hall-local `(14.8, 0, 8.0)`, Y rotation −90 degrees, facing into that chamber. Both floor checks now pass; the actual wall appears behind the reconstruction.

The first museum checker also assumed that a manually placed, unheld rigid body would retain its pose across capture frames. The point had returned to its initial x position, so the later action replayed the seed instead of sorting the cycle. The corrected checker explicitly places it before each supplied action. This repairs the test setup; it does not demonstrate physical headset pickup. The failed receipt, probe and images are preserved.

No production museum artifact, map placement or inherited PointBody was changed. The reconstruction was added only to the isolated test scene. Its placement instruction is now in the tutorial so a learner can create it there.

## How the pair reads

The progression holds when the operation leads: draw → retain → copy → count → compare. The entropy formula arrives as a tool for a question the student has already seen. The critical text can then ask how much authority we grant a measurement that ignores relations. It does not need to turn every artifact into another compulsory coding exercise.

The room is still visually busy. The installed ledger's control console partly hides its front account from the straight-on camera. The learner comparison is larger and legible in the captured wall bay, although headset reach and comfort are untested. This pass makes the text and reconstruction precise; it does not claim the hall's entire layout is resolved.

## Scope and next hall

These are author-informed reconstructions, not a blind student trial or proof of understanding. Physical XR grab, travel through every passage and an unfamiliar reader's experience remain open. Godot's log retains an existing unknown-UID error and compatibility-renderer warnings; there were no script or parse errors in the accepted lesson/museum runs.

The browser's URL policy blocked opening the local HTML for layout inspection. The pages and their links were checked as files, and native museum images were inspected. Browser layout remains unverified; open the saved facing pages for review.

**Next: Random Remove.** Keep a list of eligible addresses, select from that list, remove one member, and preserve its original address. Test the empty list before making another draw. Twelve halls remain planned rather than validated.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum results](museum/report.json) · [Rejected museum attempt](first-museum-attempt/report.json) · [Review ZIP](random-entropy-review.zip)
'''
    # Keep the description honest when the learner listing changes length.
    line_count = len((HERE / 'extracted/02_counts_and_neighbours.gd').read_text().splitlines())
    report = report.replace('137-line study', f'{line_count}-line study')
    (HERE / 'REPORT.md').write_text(report, encoding='utf8')
    nav = '<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Changes</a><a href="../index.html">Sequence plan</a>'
    for name, text in texts.items():
        (HERE / f'{name}.html').write_text(page(name.title(), render_source(text), nav), encoding='utf8')
    pictures = '''<div class="pictures"><figure><img src="museum/ledger-sorted.png" alt="Installed entropy ledger sorted in the actual museum"><figcaption>The installed ledger: two hundred tiles regroup while counts and H remain.</figcaption></figure><figure><img src="museum/student-sorted.png" alt="Printed learner study: original row, sorted copy and counts"><figcaption>Printed reconstruction in the entrance chamber: original above, sorted copy below; nine versus three unlike adjacent pairs.</figcaption></figure><figure><img src="museum/student-cycle-sorted.png" alt="Regular cycle compared with sorted copy, both at maximum marginal entropy"><figcaption>The student variation: a regular cycle and sorted copy both give two bits. Fifteen unlike pairs become three.</figcaption></figure><details><summary>See the hall from above</summary><img src="museum/above.png" alt="Current entropy hall seen from above"><p>The entrance chamber, displaced-point field, ruin and larger signal chamber.</p></details></div>'''
    body = markdown.markdown(report, extensions=['extra'])
    (HERE / 'index.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Entropy — revised lesson</title><style>{STYLE}.pictures{{display:grid;gap:24px}}figure{{margin:0}}figcaption{{font:14px/1.5 system-ui;margin:10px 0}}main{{max-width:1100px}}</style><main><nav>{nav}</nav><h1>Keep the counts, change the neighbours</h1>{pictures}{body}</main></html>', encoding='utf8')
    (HERE / 'changes.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><title>Random Entropy — changes</title><style>{STYLE}</style><main><nav>{nav}</nav><h1>Changes from the saved texts</h1>'+''.join(differences)+'</main></html>', encoding='utf8')
    spread = ''.join(f'<article><p class="track">{label}</p>{markdown.markdown(render_source(texts[name]),extensions=["extra"])}</article>' for name, label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE / 'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Entropy — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;letter-spacing:.1em;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Entropy</h1><p>Build and investigate on the left; follow the encounter on the right.</p><div class="spread">{spread}</div></main></html>', encoding='utf8')

    status = json.loads((PLAN / 'STATUS.json').read_text())
    row = next(r for r in status['halls'] if r['map'] == 'Random_Entropy')
    row.update(status='revised; ready for review', tutorial_test='31 + 31 + 31 passed; 3 faults rejected', museum_test='26 passed; native images inspected; failed first placement retained', report='doc/book/iterations/2026-10-09-randomness-revision/Random_Entropy/index.html')
    (PLAN / 'STATUS.json').write_text(json.dumps(status, indent=2), encoding='utf8')
    plan = (PLAN / 'PLAN.md').read_text(encoding='utf8')
    a = plan.index('### 02 ·'); b = plan.index('### 03 ·')
    section = plan[a:b].replace('**Status:** source walkthrough; complete reconstruction needed.', '**Status:** revised and tested; 31 checks for each of three programs, three faults rejected, 26 museum checks. See `STATUS.json` and the second-hall report.')
    (PLAN / 'PLAN.md').write_text(plan[:a]+section+plan[b:], encoding='utf8')
    publish_plan()
    tool_dir = HERE / 'tools'; tool_dir.mkdir(exist_ok=True)
    for p in ['tools/revise_random_entropy.py', 'tools/test_random_entropy_lesson.py', 'tools/probes/random_entropy_student.gd', 'tools/probes/random_entropy_museum.gd']:
        shutil.copy2(ROOT / p, tool_dir / Path(p).name)
    (HERE / 'README.md').write_text('Start with index.html or REPORT.md; parallel.html places the tutorial on the left and reflection on the right. This is hall 2, not the complete Randomness sequence. The complete printed code requires the prepared Endless Museum with installed XR Tools, as declared in the tutorial. Tests run from the repository; this is not an empty-project export. Extracted listings and versions are actual test inputs. The first museum attempt is rejected evidence, not a successful capture. The accepted museum reconstruction was temporary. images/ruin-waiting-museum.png is older retained documentation; museum/ contains this pass. Canonical Markdown is copied with original routes; portable HTML resolves the image locally.\n', encoding='utf8')
    archive = HERE / 'random-entropy-review.zip'
    checked = 0
    for p in [*HERE.glob('*.html'), OUT / 'index.html']:
        parser = Links(); parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'): continue
            target = p.parent / unquote(link.split('#')[0])
            if target == archive: continue  # Created after verification is written.
            checked += 1
            assert target.exists(), (p, link)
    verification = {'printed_files': parity, 'protected_sources': protected, 'code_checks': [31,31,31], 'faults_rejected': 3, 'museum_checks':len(receipt['checks']), 'local_targets_checked':checked, 'native_images_inspected':True, 'browser_layout':'Not inspected: browser URL policy blocks file URLs.', 'scope':'Author-informed scripted reconstruction; no headset or unfamiliar-reader acceptance.'}
    (HERE / 'verification.json').write_text(json.dumps(verification, indent=2), encoding='utf8')
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p == archive or p.suffix == '.uid' or '.godot' in p.parts: continue
            if p.suffix in ['.md','.html']:
                content = p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                content = content.replace('<a href="random-entropy-review.zip">Review ZIP</a>', 'Review packet: this folder').replace('[Review ZIP](random-entropy-review.zip)', 'Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(), content)
            else: z.write(p, p.relative_to(HERE).as_posix())
        z.write(PLAN / 'PLAN.md', 'sequence-plan.md')
        z.writestr('sequence-plan.html', page('Randomness — plan', (PLAN / 'PLAN.md').read_text(encoding='utf8'), '<a href="index.html">Entropy report</a>'))
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        names=set(z.namelist())
        for name in names:
            if not name.endswith('.html'): continue
            parser=Links(); parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if urlparse(link).scheme or link.startswith('#'): continue
                target=(Path(name).parent/unquote(link.split('#')[0])).as_posix()
                assert target in names,(name,link)
    print(json.dumps({**verification,'archive_crc':'pass','archive_links':'pass'},indent=2))


if __name__ == '__main__': main()
