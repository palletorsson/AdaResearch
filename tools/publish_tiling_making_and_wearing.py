"""Publish the applied reflective edit, with previous versions beside it."""
from pathlib import Path
from urllib.parse import urlparse, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-tiling-making-and-wearing'
PREVIOUS = ROOT / 'doc/book/iterations/2026-10-09-tiling-different-jobs'
WEB = ROOT.parent / 'ada_encyclopedia/public'
MAPS = ['Pattern_Disco', 'Pattern_Foundry', 'Tutorial_Pattern', 'Array_Patterns',
        'Symmetry_Seventeen', 'Pattern_Temple', 'Ribbon_Patterns_01',
        'Ribbon_Patterns_02', 'Ribbon_Patterns_03']
JOBS = [
    ('Recognise', 'A short return to the coloured floor; retain movement and rhythm, shorten the control tour.'),
    ('Author', 'Give the source a desire: the hope behind patterned clothing. Keep the shared-source limit.'),
    ('Read differently', 'Keep one comparison between changing the source and changing its reading.'),
    ('Place', 'Let the corridor carry the argument; connect scale to the work of making the tennis court.'),
    ('Construct', 'Shorten classification and controls; give repeated shuttle passes and retained work room.'),
    ('Compose', 'Keep the concise reflection intact: agreement can be copied without binding later decisions.'),
    ('Explore an inside', 'Mark volume as an optional excursion and reduce its procedural explanation.'),
    ('Pause and compare', 'Keep the perceptual comparison; shorten shader and control descriptions.'),
    ('Wear', 'Reach the mirror sooner; return to the desire behind clothing and distinguish what actually travels.'),
]
STYLE = '''
*{box-sizing:border-box}html{background:#f0eee5;color:#282c28}body{margin:0;font:19px/1.65 Georgia,serif}main{max-width:1440px;margin:auto;padding:30px 30px 80px}a{color:#8c3154;text-underline-offset:3px}nav,.eyebrow,.meta,figcaption,.route,.tag{font:14px/1.5 system-ui,sans-serif}nav{display:flex;gap:12px 24px;flex-wrap:wrap;border-bottom:1px solid #c6c8b9;padding:0 0 18px;margin-bottom:30px}h1{font-size:clamp(38px,5.2vw,70px);line-height:1.1;font-weight:400;letter-spacing:-.035em}h2{font-size:30px;line-height:1.2;font-weight:400}h3{font-size:22px}.reading{max-width:820px;margin:0 auto}.eyebrow,.meta,figcaption{color:#606b5d}.eyebrow{letter-spacing:.07em;text-transform:uppercase}.lead{font-size:25px;line-height:1.45;max-width:950px}.status{border-left:4px solid #75805f;padding:18px 24px;background:#e1e6d9;max-width:1000px}.route{display:flex;flex-wrap:wrap;gap:8px;margin:24px 0}.route a{padding:6px 11px;border:1px solid #b6bdae;text-decoration:none}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}.card,.sheet{min-width:0;padding:24px;background:#faf8f1;border-top:3px solid #66745d}.card p{font-size:17px}.card h2{font-size:25px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:28px}.sheet h1{font-size:36px}.sheet{overflow-wrap:anywhere}img{display:block;max-width:100%;height:auto}.card img{width:100%;aspect-ratio:1.45;object-fit:cover}figure{margin:24px 0}figcaption{margin-top:9px}.chapter{padding:35px 0;border-top:1px solid #bcc5b5}.chapter:first-of-type{border-top:none}pre{overflow:auto;padding:18px;background:#25362e;color:#f1f3e9;font:13px/1.5 Consolas,monospace;tab-size:4}code{font-size:.86em}pre code{font-size:inherit}table{border-collapse:collapse;font:15px/1.5 system-ui;width:100%}th,td{border-bottom:1px solid #c3c7ba;text-align:left;vertical-align:top;padding:12px}details{border-top:1px solid #c3c7ba;padding:12px 0}summary{cursor:pointer;font:15px system-ui}.tag{padding:3px 8px;background:#e5e4d8}blockquote{border-left:3px solid #8c3154;margin-left:0;padding-left:22px}@media(max-width:950px){.grid{grid-template-columns:1fr 1fr}}@media(max-width:720px){main{padding:22px 16px 55px}.grid,.pair{grid-template-columns:1fr}.sheet,.card{padding:18px}body{font-size:18px}}@media print{nav,.route,.meta a{display:none}.grid,.pair{display:block}.chapter{break-before:page}.sheet{background:white}body{font-size:11pt}pre{white-space:pre-wrap;font-size:8pt}}
'''


def shell(title, body, prefix=''):
    nav = ''.join(f'<a href="{prefix}{file}">{label}</a>' for file, label in [
        ('index.html','Sequence review'), ('final.html','Read the reflections'),
        ('changes.html','Before / after'), ('final.md','Markdown')])
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{STYLE}</style></head><body><main><nav>{nav}</nav>{body}</main></body></html>'


def source(m, name='final.md', before=False):
    p = OUT/'before'/m/name if before else ROOT/'commons/maps'/m/name
    return p.read_text(encoding='utf-8-sig')


def rendered(text, m, prefix=''):
    def asset(match):
        value = match.group(1)
        original = WEB / value.lstrip('/')
        assert original.is_file(), f'Missing published image: {original}'
        name = hashlib.sha256(value.encode()).hexdigest()[:8]+'-'+original.name
        shutil.copy2(original, OUT/'images'/name)
        return ']('+prefix+'images/'+name+')'
    text = re.sub(r'\]\((/book-images/[^)]+)\)', asset, text)
    text = text.replace('(../Symmetry_Seventeen/textile-note.md)', '('+prefix+'textile-note.html)')
    text = text.replace('(textile-note.md)', '('+prefix+'textile-note.html)')
    text = text.replace('(further-encounters.md)', '('+prefix+'foundry-further.html)')
    return markdown.markdown(text, extensions=['tables', 'fenced_code'])


def main():
    (OUT/'images').mkdir(exist_ok=True)
    original_hashes = json.loads((OUT/'before-hashes.json').read_text())
    rows, cards, chapters, comparisons, readings = [], [], [], [], []
    tutorial_checks = []
    for i, m in enumerate(MAPS):
        old, new = source(m, before=True), source(m)
        tutorial = ROOT/'commons/maps'/m/'tutorial.md'
        unchanged = hashlib.sha256(tutorial.read_bytes()).hexdigest() == original_hashes[tutorial.relative_to(ROOT).as_posix()]
        assert unchanged, f'Tutorial changed during editorial pass: {m}'
        tutorial_checks.append({'map':m, 'tutorial_byte_identical':unchanged})
        before, after = len(old.split()), len(new.split())
        title = new.splitlines()[0].lstrip('# ')
        verb, change = JOBS[i]
        directory = OUT/m; directory.mkdir(exist_ok=True)
        image_source = PREVIOUS/'images'/f'{m}.png'
        if m == 'Symmetry_Seventeen': image_source = OUT.parent/'2026-10-09-thread-loom/museum.png'
        shutil.copy2(image_source, OUT/'images'/f'{m}.png')
        (directory/'final.md').write_text(new,encoding='utf-8')
        shutil.copy2(tutorial, directory/'tutorial.md')
        (directory/'changes.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/final.md',tofile='final.md')),encoding='utf-8')
        meter=f'<p class="meta">{before:,} → {after:,} words · {html.escape(change)}</p>'
        before_html, after_html = rendered(old,m,'../'), rendered(new,m,'../')
        pair=f'<p class="eyebrow">{i+1} / {html.escape(m)}</p><h1>{html.escape(verb)}</h1>{meter}<div class="pair"><section class="sheet"><p class="meta">BEFORE</p>{before_html}</section><section class="sheet"><p class="meta">AFTER</p>{after_html}</section></div>'
        (directory/'changes.html').write_text(shell(title+' / before and after',pair,'../'),encoding='utf-8')
        neighbors=''
        if i: neighbors+=f'<a href="../{MAPS[i-1]}/parallel.html">← Previous hall</a> · '
        if i+1<len(MAPS): neighbors+=f'<a href="../{MAPS[i+1]}/parallel.html">Next hall →</a>'
        parallel=f'<p class="eyebrow">{i+1} / {html.escape(m)}</p><p class="meta">{neighbors}</p><div class="pair"><section class="sheet"><p class="meta">TUTORIAL · UNCHANGED</p>{rendered(source(m,"tutorial.md"),m,"../")}</section><section class="sheet"><p class="meta">REFLECTION · REVISED</p>{after_html}</section></div>'
        (directory/'parallel.html').write_text(shell(title+' / tutorial and reflection',parallel,'../'),encoding='utf-8')
        tag='<span class="tag">Optional excursion</span>' if m=='Ribbon_Patterns_01' else ''
        cards.append(f'<section class="card" id="{m}"><img loading="lazy" src="images/{m}.png" alt="Existing museum capture of {html.escape(m)}"><p class="eyebrow">{i+1}. {html.escape(verb)}</p><h2>{html.escape(title)}</h2>{tag}<p>{html.escape(change)}</p><p class="meta">{before:,} → {after:,} words</p><p class="meta"><a href="final.html#{m}">Read</a> · <a href="{m}/changes.html">Before / after</a> · <a href="{m}/parallel.html">Tutorial beside reflection</a></p></section>')
        chapters.append(f'<section class="chapter" id="{m}"><p class="eyebrow">{i+1} / {html.escape(m)}</p>{rendered(new,m)}<p class="meta"><a href="{m}/parallel.html">Read beside the unchanged tutorial</a></p></section>')
        comparisons.append(f'<section class="chapter" id="{m}"><p class="eyebrow">{i+1} / {html.escape(m)}</p>{meter}<div class="pair"><section class="sheet"><p class="meta">BEFORE</p>{rendered(old,m)}</section><section class="sheet"><p class="meta">AFTER</p>{rendered(new,m)}</section></div></section>')
        rows.append({'map':m,'before_words':before,'after_words':after,'change':change,'unchanged':old==new})
        # Make the combined Markdown portable alongside its own note files.
        portable=new.replace('(../Symmetry_Seventeen/textile-note.md)','(textile-note.md)').replace('(further-encounters.md)','(foundry-further.md)')
        readings.append(f'<!-- hall: {m} -->\n\n'+portable)
    n=sum(r['before_words'] for r in rows); total=sum(r['after_words'] for r in rows)
    summary=f'The nine reflections are now about {total:,} words, down from {n:,}. Temple is unchanged. The other eight passages are revised. All nine tutorial files remain byte-identical; hall order, artifacts and runtime code were not changed by this edit.'
    route='<div class="route">'+''.join(f'<a href="final.html#{m}">{i+1}. {html.escape(JOBS[i][0])}</a>' for i,m in enumerate(MAPS))+'</div>'
    intro=f'<p class="eyebrow">Endless Museum / Tiling / applied editorial pass / 9 October 2026</p><h1>Making, repetition, wearing.</h1><p class="lead">What do we hope a pattern will change—an image, a material, a room, or the way we live together?</p><p class="status">{summary}</p>{route}<p class="reading">The opening wish returns at the garment. The loom gives making its own time. Volume becomes an explicit side path; perception becomes a pause before wearing. Each passage keeps enough action to locate the encounter while letting the consequence carry more of the reading.</p><p class="meta">Images document existing museum installations. This pass changes the writing, not the room layout. <a href="../2026-10-09-thread-loom/index.html">The working loom and its runtime tests</a> · <a href="textile-note.html">Sources and textile distinctions</a> · <a href="validation.json">Editorial checks</a></p>'
    (OUT/'index.html').write_text(shell('Making, repetition, wearing',intro+'<div class="grid">'+''.join(cards)+'</div>'),encoding='utf-8')
    (OUT/'final.html').write_text(shell('Tiling / complete reflective sequence',route+'<div class="reading">'+''.join(chapters)+'</div>'),encoding='utf-8')
    (OUT/'changes.html').write_text(shell('Tiling / before and after','<h1>The edit, beside its beginning.</h1><p class="lead">'+summary+'</p>'+route+''.join(comparisons)),encoding='utf-8')
    (OUT/'final.md').write_text('# Tiling — making, repetition, wearing\n\n'+('\n\n---\n\n'.join(readings)),encoding='utf-8')
    note=ROOT/'commons/maps/Symmetry_Seventeen/textile-note.md'
    shutil.copy2(note,OUT/'textile-note.md')
    (OUT/'textile-note.html').write_text(shell('The thread and the work','<article class="reading">'+rendered(note.read_text(encoding='utf-8-sig'),'Symmetry_Seventeen')+'</article>'),encoding='utf-8')
    further=ROOT/'commons/maps/Pattern_Foundry/further-encounters.md'
    shutil.copy2(further,OUT/'foundry-further.md')
    (OUT/'foundry-further.html').write_text(shell('Foundry / further encounters','<article class="reading">'+rendered(further.read_text(encoding='utf-8-sig'),'Pattern_Foundry')+'</article>'),encoding='utf-8')
    validation={'kind':'Editorial checks, not a new Godot execution','hall_order':MAPS,'before_words':n,'after_words':total,'tutorials':tutorial_checks,'changes':rows}
    (OUT/'validation.json').write_text(json.dumps(validation,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    report='# Tiling — making, repetition, wearing\n\n'+summary+'\n\n## Applied\n\n'+('\n'.join(f'- **{r["map"]}**: {r["change"]}' for r in rows))+'\n\n## Boundaries\n\nNo automatic continuity is claimed between the loom sample and the garment. Several halls supply their own sources; the sequence carries reading operations and classes, not all student edits. The technical reconstruction remains in the unchanged tutorials. Before versions and diffs are included for every hall. The autobiographical references are paraphrases of the user-supplied Mamma Mönster manuscript (July 2022), with source context in textile-note.md. No new quotation from Plant was introduced.\n\n## Validation\n\nNine tutorial hashes match the pre-edit snapshots. Every revised reflection has one title and no code fences. This is a prose revision; Godot tests were not rerun.\n'
    (OUT/'REPORT.md').write_text(report,encoding='utf-8')
    for m in MAPS:
        t=source(m)
        assert len(re.findall(r'^# ',t,re.M))==1
        assert '```' not in t
    print(summary)


if __name__=='__main__':
    main()
