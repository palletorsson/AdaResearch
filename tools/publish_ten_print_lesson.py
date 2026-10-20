"""Publish the fourth Randomness hall, its exact code and native evidence."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from publish_randomness_revision import ROOT, OUT, PLAN, STYLE, page, publish_plan

MAP='Randomness_10_PRINT_Algorithm'
HERE=OUT/MAP
NAMES=['hall-before','printer-before','printer-fixed-half','printer-column','student-half','student-biased','student-030']


class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[]
    def handle_starttag(self,tag,attrs):self.links.extend(v for k,v in attrs if k in ['href','src'])


def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert all(r['passed']==r['expected_pass'] for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==36
    log=(run/'engine.log').read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for name in [*(n+'.png' for n in NAMES),'report.json','engine.log','source_manifest.json','spec.json']:
        shutil.copy2(run/name,museum/name)
    baseline=json.loads((HERE/'before-manifest.json').read_text())
    protected={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in baseline.items() if not p.endswith(('tutorial.md','final.md'))}
    assert all(protected.values()),protected
    texts={n:(ROOT/f'commons/maps/{MAP}/{n}.md').read_text(encoding='utf8') for n in ['tutorial','final']}
    files=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S):
        p=HERE/'extracted'/name
        assert p.read_text(encoding='utf8')==code+'\n'
        assert (ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8')==code+'\n'
        assert hashlib.sha256(p.read_bytes()).hexdigest()==tests['printed_sha256'][name]
        files.append(name)
    assert len(files)==2
    changes=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(text,encoding='utf8')
        before=(HERE/'before'/f'commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8')
        changes.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    report='''# 10 PRINT — two choices become a field

**Fourth of fourteen Randomness halls revised.** The tutorial now prints a complete small reconstruction inside the existing museum. The reflection retains its walk from marks to passages.

## What carries forward

Definition supplied repeatable draws; Entropy separated records from counts; Remove made the eligible set explicit. Here every grid address has the same two choices. One draw selects a diagonal. The familiar grid, line rotation and PointBody return so the new work can stay focused on interpreting a number.

The historical starting point is the single-line BASIC program discussed in [*10 PRINT*](https://10print.org/). The learner's rods reinterpret its two characters as geometry. They are not a claim to reproduce every feature of the installed printer.

## What changed

The old tutorial depended on missing helpers and a prepared slash scene. It also suggested a maze and path-length exercise without providing the corresponding connectivity model. The replacement prints the whole program and its unchanged point-class dependency. It builds an8×8 board, keeps the sampled numbers, converts each through a threshold, and draws the resulting record.

The point operates replay, bias and next-seed zones. Each rod has its own material; its centreline joins two opposite cell corners. Changing the probability keeps the raw draws. Changing the seed is another decision. Rewrapping twelve draws into another rectangle changes neighbours without changing the ordered choices.

The installed printer has breathing bias, animation, scrolling, per-address seed derivation and a linked floor. The student's static field uses a sequential generator. Both replay themselves; equal seeds across those two implementations do not promise equal pictures. This difference is stated in the lesson.

`final.md` retains the strong existing text. Its opening now carries the reader from Remove; a short addition distinguishes equal odds from equal observed counts or symmetry. The four exact-count grids remain a comparison, the solid wall crop remains an encounter, and the ant remains another interpretation of the field. They have not all become compulsory coding exercises.

## What the student can test

| Field at seed42 | Actual backslashes | Expected mean |
|---|---:|---:|
|8×8, probability0.50|33|32.00|
|8×8, probability0.75|51|48.00|
|8×8, probability0.30|22|19.20|
|4×3, probability0.50|8|6.00|

These are observations from this Godot4.6 run. They are not target counts or promises across engine versions. Replaying one run retains its result; changing its threshold does not require another set of random numbers. Probability zero and one have explicit endpoint behaviour, including a possible `randf()` result of one. [Godot: RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)

## Evidence

The exact printed listing and two actual edits—probability0.30 and a4×3 board—each passed25 checks. Three faulty variants were rejected: no generator reset, reversed diagonals and omission of the probability-one guard.

Checks cover complete initialization, one draw per address, observed count, expected mean, independent materials, corner geometry, unchanged records on redraw, inherited action dispatch, threshold endpoints, monotonic change under increasing bias, replay, rewrapping the stream and independent instances. They do not enforce an exact fifty-fifty split.

The native museum run passed36 checks, including seven camera checks. The printer's semicolon changes layout while replaying its stream. The newest seven rows reach the floor; that floor has no collision body. Console bias changes later choices without rewriting old marks. The separate twelve-wall crop stays fixed. Its cell topology contains one enclosed region and a far-to-near crossing, with two mouths per open region. Rewrapping three-wide, or extending four-wide to sixteen marks, removes that crossing. This topology check is not a complete physical route test.

The four-grid comparison retains its recorded quotas of1,5,30 and50 on reseed. The temporary learner bay has floor and a clear body-sized approach. The same extracted program ran there, and its point action changed the bias. The museum captures show the actual reconstructed geometry, not generated illustrations.

## Reading and limits

The pair now asks two related questions. The tutorial makes the local choice reconstructible. The reflection follows the extra decisions needed for those marks to become a boundary, passage or world for another body. The next hall can expand two outcomes to six die faces and introduce a stopping rule without repeating the grid lesson.

This was an author-informed reconstruction using supplied actions and assertions, not a blind student or physical-headset session. The temporary board was removed when the inspection ended. Production artifact scripts, the map configuration and PointBody match their saved pre-edit hashes.

The accepted runs contain no script or parse errors. The museum retains an unknown-UID warning and a shutdown resource-leak warning seen in the initial inspection. This pass does not certify the whole room's walking route. Early parser errors in the checker were fixed before the accepted run; they were not errors in the printed learner program.

Native images were inspected directly. HTML links and code parity were checked; browser layout was not inspected because the available browser blocks local file URLs.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Review ZIP](ten-print-review.zip)
'''
    # Editorial spacing, kept separate from machine identifiers.
    for a,b in [('an8','an 8'),('seed42','seed 42'),('probability0','probability 0'),('Godot4','Godot 4'),('a4×3','a 4×3'),('passed25','passed 25'),('passed36','passed 36'),('of1,5,30 and50','of 1, 5, 30 and 50')]:report=report.replace(a,b)
    (HERE/'REPORT.md').write_text(report,encoding='utf8')
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="../index.html">Sequence plan</a>'
    for name,text in texts.items():(HERE/f'{name}.html').write_text(page(name.title(),text,nav),encoding='utf8')
    pictures='''<figure><img src="museum/student-half.png" alt="Eight-by-eight printed student reconstruction inside Endless Museum"><figcaption>The complete printed example, reconstructed temporarily in the real hall. Seed42, probability0.50:33 backslashes.</figcaption></figure><div class="pair"><figure><img src="museum/student-biased.png" alt="Same draws at probability three quarters"><figcaption>Same draws, threshold0.75:51 backslashes.</figcaption></figure><figure><img src="museum/student-030.png" alt="Actual code edit changes threshold to thirty percent"><figcaption>Student edit, threshold0.30:22 backslashes.</figcaption></figure></div><details><summary>Existing hall and printer</summary><img src="museum/hall-before.png" alt="Existing 10 PRINT hall from above"><img src="museum/printer-fixed-half.png" alt="Installed printer and its linked floor"><img src="museum/printer-column.png" alt="Semicolon removed: one column replaces the field"></details>'''
    for a,b in [('Seed42','Seed 42'),('probability0.50:33','probability 0.50: 33'),('threshold0.75:51','threshold 0.75: 51'),('threshold0.30:22','threshold 0.30: 22')]:pictures=pictures.replace(a,b)
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>10 PRINT — revised lesson</title><style>{STYLE}main{{max-width:1100px}}figure{{margin:20px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    (HERE/'index.html').write_text(shell+'<h1>Two choices become a field</h1>'+pictures+markdown.markdown(report,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(changes)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>10 PRINT — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>10 PRINT</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text())
    row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='25 checks × 3 programs passed; 3 faults rejected',museum_test='36 passed; native images inspected',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8')
    a=plan.index('### 04 ·');b=plan.index('### 05 ·')
    section=re.sub(r'\*\*Status:\*\*[^\n]*','**Status:** revised and tested; three programs with 25 checks each, three faults rejected, 36 museum checks. See `STATUS.json` and the fourth-hall report.',plan[a:b])
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8')
    publish_plan()
    tools_dir=HERE/'tools';tools_dir.mkdir(exist_ok=True)
    for name in ['tools/revise_ten_print_lesson.py','tools/test_ten_print_lesson.py','tools/probes/ten_print_student.gd','tools/probes/ten_print_museum.gd','tools/publish_ten_print_lesson.py']:shutil.copy2(ROOT/name,tools_dir/Path(name).name)
    (HERE/'README.md').write_text('Hall4 of Randomness. Start at index.html or parallel.html (tutorial left, reflection right). Use extracted/04_two_diagonals.gd and point_body.gd; other files are test variants, some deliberately broken. Requires the prepared Endless Museum and its XR Tools. The learner display is a temporary reconstruction, not a newly installed production artifact. Tests run from the original repository; this is a review packet, not a standalone Godot project. museum/ contains native captures and results. before/ preserves prior sources. Physical-headset, unfamiliar-reader and full-route acceptance remain open.\n',encoding='utf8')
    archive=HERE/'ten-print-review.zip'
    count=0
    for p in [*HERE.glob('*.html'),OUT/'index.html']:
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0])
            if target==archive:continue
            assert target.exists(),(p,link)
            count+=1
    verification={'printed_files':files,'protected_sources':protected,'code_checks':[25]*3,'faults_rejected':3,'museum_checks':36,'local_targets_checked':count,'native_images_inspected':True,'browser_layout':'Not inspected: local file URLs blocked.','scope':'Scripted reconstruction, not headset or unfamiliar-reader acceptance.'}
    (HERE/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                content=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                content=content.replace('<a href="ten-print-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](ten-print-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),content)
            else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">10 PRINT report</a>'))
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
