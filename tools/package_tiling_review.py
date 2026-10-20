"""Bundle the complete nine-hall Tiling review for an external reader."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote, urlparse
import hashlib
import json
import re
import shutil
import zipfile
import markdown
from publish_tiling_making_and_wearing import MAPS, ROOT, OUT, shell, rendered

PACKAGE = OUT/'review-package'

BRIEF = '''# Start here — Tiling review

Endless Museum / Ada Research · 9 October 2026 · nine halls

Please read this as a chapter within an existing book and working VR museum. It follows Primitives, Transformation, Arrays and Colour. The learner already has a grabbable point, a cube-grid display, a palette class, and experience with positions, variables, arrays, loops, conditions, functions and transformations. Do not judge this as a course starting from zero.

## What to read

1. **final.md** or **final.html** — the complete current reflective sequence, in hall order.
2. **tutorial.md** or **tutorial.html** — the complete tutorials, including all printed code and carried helper files.
3. Each hall's **parallel.html** — tutorial on the left, reflection on the right.
4. **changes.html** — previous and revised reflections side by side. Assess the current version first; the comparison preserves what was shortened.
5. **textile-note.md** — source context for Mamma Mönster and Sadie Plant, with distinctions between printing, weaving and knitting.
6. **loom.html** — the newly installed hand loom, native museum captures, scope and test evidence. It is a wider museum encounter; it is not a new compulsory coding lesson.

Extract the ZIP, then open index.html for the browsable version. Images and reading pages are included. Bibliographic links lead online.

## The two texts have different jobs

The tutorial gives context, complete minimal code, declared dependencies and independent changes the student can make. It develops known objects and operations. The reflection follows an encounter into critical and poetic questions, with little code. The museum contains more artifacts than either text teaches. Every visible object need not become a lesson.

Tutorials run within the supplied museum project. The museum provides the player, camera, lighting, XR Tools and input setup. This archive contains the written chapter, not the whole runnable Godot project. Do not mistake a declared museum dependency for an omitted lesson, but flag dependencies that are not adequately declared.

The book's imagined student studies for pleasure and inquiry as well as capacity. Read generously, but test its claims: can a student make, predict, explain and investigate something beyond copying the example?

## Review questions

- Does each hall add a distinct, useful operation or investigation? Is the cumulative progression clear?
- Do the smallest printed examples contain what their stated task requires? Identify exact omissions or contradictions rather than requesting an entire engine course.
- Do the two tracks complement each other? Where does the reflection become another manual, or lose material exactness?
- Does the path from authored mark through reading rule, surface, construction and garment hold?
- Does the optional volume excursion interrupt the route appropriately, or still need less emphasis?
- Do the loom, Mamma Mönster and Plant give the chapter material and cultural stakes without equating weaving, knitting, printed images and code?
- Does the ending earn its return to the desire that clothing might change people?

Report the strongest passages worth keeping, then the few most consequential changes. Name the hall and passage. Separate a demonstrated technical error from an editorial preference or proposed new feature. Recommend reordering only where a specific dependency or learning gain justifies it.

## Known boundaries and validation

Several halls supply their own starting sources. The sequence carries classes and reading operations, not every student's edited motif automatically. The loom's woven sample does not become the garment. Its thread paths are geometry; yarn tension, friction and cloth dynamics are not simulated.

This editorial pass shortened the nine reflections from approximately 6,404 to 3,990 whitespace-separated words. Temple is unchanged; eight reflections were revised. All nine tutorials were checked byte-for-byte against their pre-edit snapshots and are unchanged. Hall order and museum behavior were not changed by the prose edit.

Godot was not rerun for this text-only pass. The archive separately includes the hand loom's earlier 23 runtime assertions and four museum placement checks, including simulated XR pickup and trigger use. Those receipts do not certify all tutorial examples, physical headset comfort or human learning. State what you can and cannot verify from this package.
'''


def portable_md(text, prefix=''):
    def replace(match):
        url=match.group(1)
        name=hashlib.sha256(url.encode()).hexdigest()[:8]+'-'+Path(url).name
        assert (OUT/'images'/name).is_file()
        return ']('+prefix+'images/'+name+')'
    text=re.sub(r'\]\((/book-images/[^)]+)\)',replace,text)
    text=text.replace('(../Symmetry_Seventeen/textile-note.md)','('+prefix+'textile-note.md)')
    text=text.replace('(textile-note.md)','('+prefix+'textile-note.md)') if not prefix else text
    if prefix: text=text.replace('](textile-note.md)',']('+prefix+'textile-note.md)')
    return text.replace('(further-encounters.md)','('+prefix+'foundry-further.md)')


def main():
    PACKAGE.mkdir(exist_ok=True)
    # Curated files only; do not recursively include the output ZIP or unrelated work.
    for name in ['index.html','final.html','final.md','changes.html','REPORT.md','validation.json',
                 'textile-note.html','textile-note.md','foundry-further.html','foundry-further.md']:
        shutil.copy2(OUT/name,PACKAGE/name)
    shutil.copytree(OUT/'images',PACKAGE/'images',dirs_exist_ok=True)
    for m in MAPS:
        target=PACKAGE/m; target.mkdir(exist_ok=True)
        for name in ['final.md','tutorial.md','parallel.html','changes.html','changes.diff']:
            shutil.copy2(OUT/m/name,target/name)
        # Ensure this publication still describes the current canonical chapter.
        for name in ['final.md','tutorial.md']:
            assert (OUT/m/name).read_text(encoding='utf-8-sig')==(ROOT/'commons/maps'/m/name).read_text(encoding='utf-8-sig'), f'Stale publication: {m}/{name}'
        (target/'final.md').write_text(portable_md((target/'final.md').read_text(encoding='utf-8-sig'),'../'),encoding='utf-8')
    (PACKAGE/'final.md').write_text(portable_md((OUT/'final.md').read_text(encoding='utf-8-sig')),encoding='utf-8')
    (PACKAGE/'START_HERE.md').write_text(BRIEF,encoding='utf-8')
    (PACKAGE/'start-here.html').write_text(shell('Reviewer brief','<article class="reading">'+markdown.markdown(BRIEF,extensions=['tables','fenced_code'])+'</article>'),encoding='utf-8')
    tutorials=[]; tutorial_html=[]
    for i,m in enumerate(MAPS):
        text=(ROOT/'commons/maps'/m/'tutorial.md').read_text(encoding='utf-8-sig')
        tutorials.append(f'<!-- hall: {m} -->\n\n'+text)
        tutorial_html.append(f'<section class="chapter" id="{m}"><p class="eyebrow">{i+1} / {m}</p>'+rendered(text,m)+'</section>')
    (PACKAGE/'tutorial.md').write_text('# Tiling — complete tutorial sequence\n\n'+('\n\n---\n\n'.join(tutorials)),encoding='utf-8')
    (PACKAGE/'tutorial.html').write_text(shell('Tiling / complete tutorials','<div class="reading">'+''.join(tutorial_html)+'</div>'),encoding='utf-8')
    loom=OUT.parent/'2026-10-09-thread-loom'
    evidence=PACKAGE/'loom'; evidence.mkdir(exist_ok=True)
    for name in ['museum.png','player-view.png','crossings.png','tests.json','museum-tests.json']:
        shutil.copy2(loom/name,evidence/name)
    for name in ['README.md','thread_loom.gd','shuttle.gd','thread_loom.tscn']:
        shutil.copy2(ROOT/'commons/artifacts/thread_loom'/name,evidence/name)
    for name in ['thread_loom_test.gd','thread_loom_museum.gd']:
        shutil.copy2(ROOT/'tools/probes'/name,evidence/name)
    loom_body='<article class="reading"><h1>Follow the Thread</h1><p>The installed geometric hand loom in Symmetry Seventeen. These are native Godot captures. The cloth shown contains twelve passes after the placement test.</p><img src="loom/museum.png" alt="Hand loom inside the museum"><h2>At the loom</h2><img src="loom/player-view.png" alt="Working position"><img src="loom/crossings.png" alt="Warp and weft crossings">'+markdown.markdown((evidence/'README.md').read_text(encoding='utf-8-sig'))+'<p><a href="loom/tests.json">23 runtime assertions</a> · <a href="loom/museum-tests.json">Four museum assertions</a></p><p>The scripts and test probes in the loom folder depend on the full museum project.</p></article>'
    (PACKAGE/'loom.html').write_text(shell('The working hand loom',loom_body),encoding='utf-8')
    for f in PACKAGE.rglob('*.html'):
        t=f.read_text(encoding='utf-8')
        t=t.replace('../2026-10-09-thread-loom/index.html','loom.html')
        if f.parent==PACKAGE:
            t=t.replace('<nav>','<nav><a href="start-here.html">Reviewer brief</a><a href="tutorial.html">Complete tutorials</a>',1)
        f.write_text(t,encoding='utf-8')
    files=sorted(p for p in PACKAGE.rglob('*') if p.is_file())
    manifest={f.relative_to(PACKAGE).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in files}
    (PACKAGE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    archive=OUT/'tiling-review.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for f in sorted(PACKAGE.rglob('*')):
            if f.is_file():z.write(f,Path('tiling-review')/f.relative_to(PACKAGE))
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert sum(n.endswith('/tutorial.md') for n in z.namelist())==10
        assert sum(n.endswith('/final.md') for n in z.namelist())==10
        print(f'{archive}\n{len(z.namelist())} files · {archive.stat().st_size/1024/1024:.1f} MiB · ZIP CRC check passed')


if __name__=='__main__':
    main()
