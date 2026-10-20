"""Publish the third Randomness pair and evidence without replacing the museum."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote
import markdown
from publish_randomness_revision import ROOT, OUT, PLAN, STYLE, page, publish_plan

HERE = OUT / 'Random_Remove'
NAMES = ['hall-before','board-before','board-empty','arena-one-gap','arena-gap-close','student-ready','student-half','student-empty','student-checker']


class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.links=[]
    def handle_starttag(self,tag,attrs):
        self.links.extend(v for k,v in attrs if k in ['href','src'])


def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert all(r['passed']==r['expected_pass'] for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot/Random_Remove'
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==34
    log=(run/'engine.log').read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for name in [*(n+'.png' for n in NAMES),'report.json','engine.log','source_manifest.json','spec.json']:
        shutil.copy2(run/name,museum/name)
    baseline=json.loads((HERE/'before-manifest.json').read_text())
    protected={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in baseline.items() if not p.endswith(('tutorial.md','final.md'))}
    assert all(protected.values()),protected
    texts={n:(ROOT/f'commons/maps/Random_Remove/{n}.md').read_text(encoding='utf8') for n in ['tutorial','final']}
    files=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S):
        extracted=HERE/'extracted'/name
        assert extracted.read_text(encoding='utf8')==code+'\n'
        assert (ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8')==code+'\n'
        assert hashlib.sha256(extracted.read_bytes()).hexdigest()==tests['printed_sha256'][name]
        files.append(name)
    assert len(files)==2 and '```' not in texts['final']
    changes=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(text,encoding='utf8')
        before=(HERE/'before'/f'commons/maps/Random_Remove/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8')
        changes.append(f'<h2>{name}.md</h2><p>Saved before text → revised canonical text.</p><pre>{html.escape(diff)}</pre>')

    report='''# Random Remove — the set before the choice

**Third of fourteen Randomness halls revised and tested.** One primary tutorial object: the familiar cube grid, operated by the unchanged PointBody. The new subject is an eligible set that shrinks after each draw.

## What changes in the lesson

The old tutorial described pieces of the installed program. The new `tutorial.md` prints a complete small reconstruction and its PointBody dependency, names the museum placement, and explains the difference between a candidate-list offset and a cube's persistent address. Offset zero initially means address eighteen, not cube zero.

The procedure is small: filter → choose an offset → look up the address → hide its cube → remove the candidate. An empty list returns without drawing. Reset restores both the list and the generator. The display retains all sixty-four slot plates, so an absence still has an address.

The eight-by-eight board connects with Random Definition, and the changing list returns to Random Entropy's arrays. This is reuse of known construction, not an invented transfer of the previous hall's saved values. The new lesson deliberately omits the size slider: the count changes here because eligibility changes.

`final.md` keeps the existing board, replacement hoppers and walkable arena. Six code blocks have become prose, retaining the distinction between a chosen member, its disappearance and the withdrawal of physical support. The row/column comparison stays because the same number of candidates can describe different possible places. Its next room is now clearly 10 PRINT.

## Independent changes the student can make

| Eligibility rule | Candidates on an 8 × 8 board | What to verify |
|---|---:|---|
| Columns 2–5 and rows 2–5 | 16 | Only the central square empties |
| Even column + row | 32 | The checkerboard empties without repetition |
| Row 3 | 8 | The other seven rows remain |
| Column 3 | 8 | Same seed gives the transposed row order |
| Always false | 0 | No draw, no deletion, no crash |

All five are actual edits of the printed eligibility function, executed as separate scripts. Each also runs on a four-by-four board to test the same address logic at another size.

## Evidence

| Check | Result |
|---|---|
| Exact printed listing | 30 checks passed |
| Checkerboard, row, column and empty-set edits | 30 checks each passed |
| Incorrectly use list offset as cube address | Rejected |
| Leave the selected member in the candidate list | Rejected |
| Reset without reseeding the generator | Rejected |
| Actual museum plus temporary student reconstruction | 34 checks passed, including nine camera checks |

The tests check initialized objects, independently specified candidate addresses, colour/eligibility agreement, request bounds, no repetition, visibility, surviving slots, exhaustion, replay, point-action dispatch and separate instance state. They also compare the row and column orders after transposing their addresses. Empty calls preserve the generator state. Larger cells must remain above their plates.

At seed 42, both the student reconstruction and the installed remover produced this complete order:

`35, 44, 20, 18, 28, 29, 43, 21, 26, 37, 45, 34, 27, 19, 42, 36`.

This is a receipt from the tested Godot build, not a promise that an engine's random-number implementation will never change.

The native museum check also verifies the board's red warning, ignored busy presses, cancellation of a pending removal on reset, and full replay. The hoppers begin with the same chosen number but retain eight versus seven eligible members. The arena's first removal disables its selected collider; a downward ray confirms there is no remaining floor support at that cell. A close capture shows the opening over the fire. Replay restores all ninety-nine. These controls were supplied by the checker, not by a physical headset session.

## What the images changed

The installed console appears in front of the board after the museum applies its control layout. The reflection now agrees with that image rather than assuming the fixture's unmodified right-side placement. In the student board, column labels moved to the near edge so the cubes do not hide them. Cell height follows cell size so a smaller grid's larger cubes clear the slot plates.

The learner bay at hall-local `(13.2, 0, 8)`, Y rotation −90 degrees, has floor and an approach clear of other collision bodies. The native images show the complete printed program in that bay, plus its checkerboard edit. This reconstruction was temporary in the inspection scene. The production artifact scripts, map configuration and inherited PointBody were unchanged.

## How the two texts progress

Definition asks what a seed needs to reproduce a picture. Entropy asks what a count keeps and loses. Remove asks what can enter a choice at all, then makes each result change the following choice. That is a cumulative progression through the same kinds of objects and records. The tutorial implements it; the reflection follows what it means when an exclusion is decided before the apparently even draw.

The next hall gives every grid cell two possible diagonal marks. Keep the local generator and the distinction between the permitted choices and the draw. Change what the result does.

## Limits of this pass

This is an author-informed reconstruction with assertions and deliberate faults, not a blind reading by an unfamiliar student. Physical pickup, headset reach and a complete walk through the arena remain untested. The temporary display plinth is visual only, as the tutorial states.

The museum log reports an existing blocked authored-entry location and uses a safe spawn fallback. The unknown-UID and renderer warnings also remain. No script or parse errors occurred in these accepted tests. This pass does not certify every passage in the hall.

Local HTML was checked for links and exact printed-code parity. Browser layout was not inspected because local file URLs are blocked by the available browser tool. Native Godot images were inspected directly.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md)

[Predictions before running](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Review ZIP](random-remove-review.zip)
'''
    (HERE/'REPORT.md').write_text(report,encoding='utf8')
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="../index.html">Sequence plan</a>'
    for name,text in texts.items():
        (HERE/f'{name}.html').write_text(page(name.title(),text,nav),encoding='utf8')
    pictures='''<figure><img src="museum/student-half.png" alt="Student board in the actual museum after eight removals"><figcaption>Printed reconstruction: eight addresses removed; their plates remain. This is a temporary learner study in the existing room.</figcaption></figure><div class="pair"><figure><img src="museum/student-ready.png" alt="Sixteen eligible cubes in the reconstructed board"><figcaption>Before: the range admits sixteen cubes.</figcaption></figure><figure><img src="museum/student-checker.png" alt="Checkerboard predicate admits thirty-two cubes"><figcaption>Student edit: one changed condition admits thirty-two.</figcaption></figure></div><details><summary>See the installed exhibit and the hall</summary><figure><img src="museum/board-before.png" alt="The installed removal board with controls in front"><figcaption>The installed exhibit inspected before testing. It remains in the museum.</figcaption></figure><img src="museum/hall-before.png" alt="Random Remove hall viewed from above"><img src="museum/arena-gap-close.png" alt="Opening above the fire after one floor cell is removed"></details>'''
    (HERE/'index.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Remove — revised lesson</title><style>{STYLE}main{{max-width:1100px}}figure{{margin:20px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav><h1>The set before the choice</h1>{pictures}{markdown.markdown(report,extensions=["extra"])}</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><title>Random Remove — changes</title><style>{STYLE}</style><main><nav>{nav}</nav><h1>Before / after</h1>'+''.join(changes)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Remove — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;letter-spacing:.1em;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Remove</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    # Re-read shared status immediately before updating this hall only.
    status=json.loads((PLAN/'STATUS.json').read_text())
    row=next(r for r in status['halls'] if r['map']=='Random_Remove')
    row.update(status='revised; ready for review',tutorial_test='30 checks × 5 programs passed; 3 faults rejected',museum_test='34 passed; native images inspected',report='doc/book/iterations/2026-10-09-randomness-revision/Random_Remove/index.html')
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8')
    a=plan.index('### 03 ·');b=plan.index('### 04 ·')
    section=re.sub(r'\*\*Status:\*\*[^\n]*', '**Status:** revised and tested; five programs with 30 checks each, three faults rejected, 34 museum checks. See `STATUS.json` and the third-hall report.', plan[a:b])
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8')
    publish_plan()
    tools_dir=HERE/'tools';tools_dir.mkdir(exist_ok=True)
    for name in ['tools/revise_random_remove.py','tools/test_random_remove_lesson.py','tools/probes/random_remove_student.gd','tools/probes/random_remove_museum.gd']:
        shutil.copy2(ROOT/name,tools_dir/Path(name).name)
    (HERE/'README.md').write_text('Hall 3 of Randomness. Start with index.html or REPORT.md; parallel.html puts the tutorial left and reflection right. Canonical sources are copied here. extracted/ contains the actual code tested, including deliberately incorrect variants: use 03_eligible_addresses.gd and point_body.gd, not the fault files. Requires prepared Endless Museum + XR Tools, not an empty-project export. museum/ contains native captures from this pass; the student reconstruction is temporary. Tests run from the original repository. before/ preserves prior sources. Physical headset and unfamiliar-reader acceptance remain open.\n',encoding='utf8')
    archive=HERE/'random-remove-review.zip'
    count=0
    for p in [*HERE.glob('*.html'),OUT/'index.html']:
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0])
            if target==archive:continue
            assert target.exists(),(p,link)
            count+=1
    verification={'printed_files':files,'protected_sources':protected,'code_checks':[30]*5,'faults_rejected':3,'museum_checks':34,'local_targets_checked':count,'native_images_inspected':True,'browser_layout':'Not inspected: local file URLs blocked.','scope':'Scripted reconstruction, not physical headset or unfamiliar-reader acceptance.'}
    (HERE/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                content=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                content=content.replace('<a href="random-remove-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-remove-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),content)
            else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">Removal report</a>'))
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        names=set(z.namelist())
        for name in names:
            if not name.endswith('.html'):continue
            parser=Links();parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if urlparse(link).scheme or link.startswith('#'):continue
                assert (Path(name).parent/unquote(link.split('#')[0])).as_posix() in names,(name,link)
    print(json.dumps({**verification,'zip_crc':'pass','zip_links':'pass'},indent=2))


if __name__=='__main__':main()
