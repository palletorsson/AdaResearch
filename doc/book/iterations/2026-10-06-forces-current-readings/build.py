"""Export the current Forces manuscripts without rewriting their sources."""
from pathlib import Path
from hashlib import sha256
from html import escape
from urllib.parse import urlsplit, unquote
import json
import re
import zipfile
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
SEQUENCE = ROOT / 'commons/maps/sequences/forces.json'
sequence = json.loads(SEQUENCE.read_text(encoding='utf-8-sig'))['sequences']['forces']
maps = sequence['maps']
plan = json.loads((ROOT / 'doc/book/course/execution-plan/plan.json').read_text(encoding='utf-8-sig'))
lessons = [next(x for x in plan['lessons'] if x['id'] == m) for m in maps]
entries = []
files = {'build.py'}

def write(name, text):
    p = OUT / name
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding='utf-8')
    files.add(name)

def copy_source(path):
    rel = path.relative_to(ROOT).as_posix()
    dest = 'source/' + rel
    data = path.read_bytes()
    target = OUT / dest
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    files.add(dest)
    return dest, sha256(data).hexdigest()

def portable_links(text, source):
    def replace(match):
        url = match.group(2)
        parsed = urlsplit(url)
        if parsed.scheme or url.startswith('#'):
            return match.group(0)
        if url.startswith('/book-review/'):
            target = ROOT / unquote(parsed.path.removeprefix('/book-review/'))
        elif url.startswith('/'):
            return match.group(1) + 'http://localhost:3003' + url + ')'
        else:
            target = (source.parent / unquote(parsed.path)).resolve()
        if target.is_file() and target.is_relative_to(ROOT):
            dest, _ = copy_source(target)
            suffix = ('?' + parsed.query if parsed.query else '') + ('#' + parsed.fragment if parsed.fragment else '')
            return match.group(1) + dest + suffix + ')'
        return match.group(0)
    return re.sub(r'(!?\[[^\]]*\]\()([^\s)]+)\)', replace, text)

texts = {'tutorial': [], 'final': []}
for number, hall in enumerate(maps, 1):
    row = {'order': number, 'map': hall}
    for kind in texts:
        src = ROOT / 'commons/maps' / hall / (kind + '.md')
        data = src.read_bytes()
        text = data.decode('utf-8-sig')
        dest, digest = copy_source(src)
        row[kind] = {'source': src.relative_to(ROOT).as_posix(), 'file': dest, 'sha256': digest,
                     'words_whitespace': len(text.split()),
                     'gdscript_fences': len(re.findall(r'^```gdscript\s*$', text, re.M)),
                     'title': text.splitlines()[0].removeprefix('# ')}
        texts[kind].append((hall, portable_links(text, src)))
    row['plan_decision'] = lessons[number-1]['decision']
    row['plan_checks'] = lessons[number-1].get('checks', [])
    entries.append(row)

copy_source(SEQUENCE)
copy_source(ROOT / 'doc/book/course/storyboards/FORCES.md')
write('LESSON_PLAN.json', json.dumps(lessons, ensure_ascii=False, indent=2) + '\n')
write('LESSON_SUMMARIES.md', '# Forces — proposed lesson summaries\n\nSnapshot of the execution plan on 6 October 2026. These are proposals, not completed learner programs.\n\n' + '\n\n'.join(f"## {i}. {l['id']}\n\n{l['summary']}" for i,l in enumerate(lessons,1)) + '\n')

twords = sum(x['tutorial']['words_whitespace'] for x in entries)
fwords = sum(x['final']['words_whitespace'] for x in entries)
tblocks = sum(x['tutorial']['gdscript_fences'] for x in entries)
fblocks = sum(x['final']['gdscript_fences'] for x in entries)
status = f'''# Forces — current state

6 October 2026. Current working-tree snapshot of the 13-hall `forces` sequence, not an older book capture. No source manuscripts, museum code, sequence order or acceptance decisions were changed for this export.

## What is present

- All 13 halls have `tutorial.md` and `final.md`.
- Tutorials: approximately {twords:,} whitespace-separated words. Reflections: approximately {fwords:,}.
- The route is displacement → addition/routes → projection/remainder → analytic launch → retained motion → field receivers → drag/work/circular motion → restoring forces → timing → gravity → support → encounter/collision → force as place.
- The reflective sequence is the more developed continuous reading. It follows particular rooms, controls and bodily encounters, repeatedly asking what receives an instruction and what state persists.

## Tutorial readiness

The current tutorials mainly document installed mechanisms, controls, scales, model limits and earlier artifact checks. They are useful source companions, but they do not yet provide the complete reduced learner programs and tested construction lineage of the recent Colour drafts. There are {tblocks} fenced GDScript blocks across the tutorials; several are single expressions or small excerpts. Choreography has a concrete one-line rate edit and a prediction, rather than a full new program.

All 13 corresponding execution-plan lessons are marked `draft` and their `checks` arrays are empty. That is a planning status: it does not erase the older installed-artifact probes described in the texts. No new Godot test was run for this text export, and no Forces-wide Ghost Student reconstruction is certified here.

The 4 October proposal identifies Fields → Kinetic Forces → Oscillation as the main cumulative making passage: assign versus accumulate velocity, then velocity-dependent resistance, then restoration and damping. Exact reduced learner programs, inherited dependencies and bindings to their museum hosts remain to be written. Support and Arena can stay bounded comparison lessons rather than compulsory controller builds.

## Focused review points

1. Preserve the subject: vectors, motion and forces. Return to the familiar point/sphere and cube where useful, explicitly distinguishing a numerical marker, a pickable handle and an engine-integrated body. The plan proposes this continuity; the current tutorials do not yet implement it as a portable learner-code chain.
2. Supply a complete executable context for each selected making task, explain the changed operation, and test the printed code plus a learner variation. Earlier artifact tests do not automatically validate an unwritten reconstruction.
3. Preserve the distinction between analytic launch, engine integration and explicit state updates. Do not apply the time factor twice to an engine force command or silently inherit a frozen pickable's settings into a dynamic body.
4. Keep Launch before Motion unless deliberately revising the route. Vector Arithmetic's tutorial still mentions a Motion-before-Launch proposal; the current order and later plan keep Launch first.
5. The reflections contain {fblocks} fenced GDScript blocks. Some make an essential distinction visible; others may belong in the tutorial under the newer division of labour. Read before cutting, especially the long closing Force as Place text.
6. Kinetic Forces' final text makes an overly categorical claim that air resistance is square-law at any throwable cube speed. The 4 October storyboard already flags that sentence for review. Motion's Newton footnote also says Gravity is "two halls ahead", which does not match the current route. These are review flags, preserved rather than silently repaired in an export.
7. The teaching plan relies on Change's rates and accumulation, while runtime prerequisites name Primitives and Transformation. Reconcile the teaching dependency without confusing it with game unlock rules.

## Hall inventory

| # | Hall | Tutorial words | Reflection words | Tutorial code blocks | Plan |
|---|---|---:|---:|---:|---|
'''
for e in entries:
    status += f"| {e['order']} | {e['map']} | {e['tutorial']['words_whitespace']} | {e['final']['words_whitespace']} | {e['tutorial']['gdscript_fences']} | draft |\n"
status += '\nCounts include headings, captions, code and reference text, using whitespace splitting. Assessment is editorial and based on the packaged sources and plan; it is not a new runtime or historical-source validation.\n'
write('STATUS.md', status)

css = '''body{margin:0;background:#f3f0e9;color:#24252a;font:18px/1.65 Georgia,serif}main{max-width:900px;margin:auto;padding:40px 28px}h1,h2,h3,nav,.eyebrow{font-family:system-ui,sans-serif;line-height:1.2}h1{font-size:clamp(30px,5vw,52px)}h2{margin-top:2em}a{color:#7e2850}nav{display:flex;gap:20px;flex-wrap:wrap;margin:24px 0;font-size:15px}pre{padding:20px;background:#e7e3dc;overflow:auto;line-height:1.45;font-size:14px}code{font-size:.86em}img{max-width:100%;height:auto}table{border-collapse:collapse;font-size:14px;display:block;overflow:auto}td,th{padding:9px;border-bottom:1px solid #c7c1b6;text-align:left}section{padding:24px 0 42px;border-top:2px solid #bbaaaa}.eyebrow{font-size:14px;color:#746865}blockquote{border-left:3px solid #aa7885;padding-left:20px} .note{background:#e6dfd4;padding:18px 24px}@media print{nav{display:none}section{break-before:page}body{background:white}main{padding:0}pre{white-space:pre-wrap}}'''
nav = '<nav><a href="index.html">Current state</a><a href="tutorial.html">Tutorials</a><a href="final.html">Reflections</a><a href="forces-current-review.zip">Download ZIP</a></nav>'
def html_page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + escape(title) + '</title><style>' + css + '</style></head><body><main>' + nav + body + '</main></body></html>'

for kind, records in texts.items():
    title = 'Forces — ' + ('tutorial sequence' if kind == 'tutorial' else 'reflective sequence')
    intro = 'Current canonical manuscripts, 6 October 2026. Exported in museum order. Read STATUS.md for readiness and review flags.'
    combined = f'# {title}\n\n{intro}\n\n'
    sections = []
    toc = '<ol>' + ''.join(f'<li><a href="#{hall}">{escape(entries[i][kind]["title"])}</a></li>' for i,(hall,_) in enumerate(records)) + '</ol>'
    for i,(hall,text) in enumerate(records,1):
        combined += f'---\n\n## {i}. {hall}\n\n' + text + '\n\n'
        rendered = markdown.markdown(text, extensions=['extra','sane_lists'])
        rendered = re.sub(r'(id="|href="#)([^"]+)', lambda m: m[1]+hall+'-'+m[2], rendered)
        sections.append(f'<section id="{hall}"><p class="eyebrow">{i:02} / 13 · {hall}</p>{rendered}</section>')
    write('ALL_' + kind.upper() + 'S.md' if kind=='tutorial' else 'ALL_FINAL.md', combined)
    write(kind+'.html', html_page(title, f'<h1>{escape(title)}</h1><p class="note">{intro}</p>{toc}'+''.join(sections)))
write('index.html', html_page('Forces — current texts and review package', markdown.markdown(status, extensions=['extra','sane_lists'])))
write('README.md', '''# Forces — current tutorial and reflective texts

Open index.html for the status report. Read tutorial.html or final.html offline, or give ALL_TUTORIALS.md and ALL_FINAL.md to a reviewer. LESSON_SUMMARIES.md and LESSON_PLAN.json describe the proposed tutorial progression, not completed lessons.

The source/commons/maps folders contain all 26 original manuscripts, copied byte-for-byte in the current sequence. source/commons/maps/sequences/forces.json fixes their order. The two images used in final.md and directly linked local reading references are included under source/. Combined readings adjust links for this package; individual source manuscripts remain unchanged. Some historical/reference pages may require the repository or local encyclopedia for their own further links.

This is a text review package, not a runnable Godot project. Museum implementation dependencies and test harnesses are not bundled. Existing test statements in the manuscripts concern their recorded artifact probes; no new engine test or learner validation is claimed. See STATUS.md and manifest.json for scope, counts, source hashes and current plan status.

Suggested reviewer task: read both complete tracks in order; distinguish encounter writing from implementation notes; assess whether the proposed making sequence inherits sufficient knowledge and leaves an independent capacity. Identify a bounded repair for each weak hall. Do not assume a listed concept has been taught, an excerpt is runnable, or a persuasive reflection proves its historical or physical claims.
''')
manifest = {'date':'2026-10-06','sequence':'forces','scope':'Current canonical text snapshot; plan remains draft; no source edits or engine rerun',
            'map_count':len(maps),'manuscript_count':len(maps)*2,'tutorial_words':twords,'final_words':fwords,'halls':entries}
write('manifest.json', json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')

for e in entries:
    for kind in texts:
        item=e[kind]
        assert sha256((ROOT/item['source']).read_bytes()).hexdigest()==item['sha256']
        assert (ROOT/item['source']).read_bytes()==(OUT/item['file']).read_bytes()
archive = OUT/'forces-current-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for name in sorted(files):
        z.write(OUT/name, name)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert len([n for n in z.namelist() if n.startswith('source/commons/maps/') and n.endswith(('/tutorial.md','/final.md'))])==26
    for e in entries:
        for kind in texts:
            assert sha256(z.read(e[kind]['file'])).hexdigest()==e[kind]['sha256']
print(json.dumps({'zip':str(archive),'bytes':archive.stat().st_size,'files':len(files),'halls':len(maps),'tutorial_words':twords,'final_words':fwords,'source_copies_verified':26,'zip_crc':'pass'},indent=2))
