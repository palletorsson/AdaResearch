"""Publish the prose-only Wavefunctions pass, checking every printed program."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import zipfile
import markdown

from publish_wavefunctions_opening import STYLE, block

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-08-wavefunctions-reading-pass'
STUDY = ROOT / 'doc/book/studies/wavefunctions-lineage'
PATTERN = r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```'
ROWS = [
    ('intro', 'Cube', 'Movement', 'One returning height: amplitude, frequency and phase.'),
    ('pendulum', 'Pendulum', 'Movement → record', 'A responding swing; positions and timestamps kept together.'),
    ('sine-space', 'Sine Space', 'Spatial composition', 'A grid becomes a surface that can receive the carried sphere.'),
    ('unit-circle', 'Unit Circle', 'Movement → coordinates', 'One angle supplies two coordinates and a graph.'),
    ('propagation', 'Propagation', 'Movement through relations', 'Neighbours read one shared old state before advancing together.'),
    ('effect-sound', 'Effect Sound', 'Sound → comparison', 'One control changes phase depth; a stored note makes comparison possible.'),
    ('bernini', 'Bernini', 'Spatial composition', 'A turn remains in the form when whole-object rotation stops.'),
    ('cage', 'Cage', 'Record → composition', 'Keep six chosen events and their times; replay without choosing again.'),
    ('air-music', 'Air Music', 'Contact → continuing voices', 'A new onset restarts one voice while another continues.'),
    ('sky-stairs', 'Sky Stairs', 'Spatial composition → support', 'Return to the cube: sampled centres need treads and collision.'),
    ('beats', 'Beats', 'Composition through time', 'Return to two waves: their signed sum reveals their changing relation.'),
    ('synthesis', 'Synthesis', 'Composition → what is kept', 'Five harmonic amounts make one curve; restoring a recipe differs from restoring an instant.'),
]

EXTRA_STYLE = '''
.reading{max-width:900px;margin:auto}.reading article{margin:32px 0}
.chapter{scroll-margin-top:20px}.chapter>h2{border-top:2px solid #809289;padding-top:28px}
.thread{font:15px/1.6 system-ui;background:#e2ebe7;padding:16px;max-width:none}
.parallel article>h1{font-size:30px}.parallel{align-items:start}
.toc{columns:3;column-gap:32px}.toc a{display:block;margin-bottom:12px;break-inside:avoid}
.interlude{border-top:2px solid #809289;margin-top:3em;padding-top:2em}
.pictures{margin:28px 0}.pictures img{aspect-ratio:16/10;object-fit:cover}
details{margin:20px 0}summary{cursor:pointer;font:16px system-ui}pre{tab-size:4}
@media(max-width:950px){.toc{columns:1}.parallel article>h1{font-size:26px}}
@media print{.chapter{break-before:page}.reading article{break-inside:auto}details{display:none}}
'''


def page(title, body):
    nav = '<nav><a href="index.html">Sequence & changes</a><a href="tutorial.html">Whole tutorial</a><a href="final.html">Whole reflection</a><a href="wavefunctions-readings.zip">Download texts & code</a></nav>'
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{STYLE}{EXTRA_STYLE}</style><header><div class="tag">Endless Museum · Wavefunctions · Reading pass</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main></html>'


def prose(text):
    return markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes']).replace('<h2>Interlude', '<h2 class="interlude">Interlude').replace('<h2>Return —', '<h2 class="interlude">Return —')


def words(text):
    return len(re.sub(r'```.*?```', '', text, flags=re.S).split())


def main():
    maps = json.loads((ROOT / 'commons/maps/sequences/wavefunctions.json').read_text(encoding='utf8'))['sequences']['wavefunctions']['maps']
    assert len(maps) == len(ROWS) == 12
    protected = json.loads((OUT / 'protected-before.json').read_text(encoding='utf8'))
    assert all(hashlib.sha256((ROOT / p).read_bytes()).hexdigest() == value for p, value in protected.items())
    lessons, changes, listings = [], [], []
    for map_id, (stem, title, thread, purpose) in zip(maps, ROWS):
        folder = ROOT / 'commons/maps' / map_id
        texts = {}
        diffs = ''
        before_tutorial = (OUT / 'before/commons/maps' / map_id / 'tutorial.md').read_text(encoding='utf8')
        old_blocks = re.findall(PATTERN, before_tutorial, re.S)
        token_map = {'CODE': old_blocks[0][0], 'POINT_CODE': 'point_body.gd', 'LINE_CODE': 'line_skin.gd', 'VOICE_CODE': 'ring_voice.gd' if stem == 'air-music' else 'note_voice.gd'}
        for kind in ['tutorial', 'final']:
            source = STUDY / f'{stem}-{kind}.md'
            original_source = OUT / 'before' / source.relative_to(ROOT)
            before = (OUT / 'before' / (folder / f'{kind}.md').relative_to(ROOT)).read_text(encoding='utf8')
            expanded = source.read_text(encoding='utf8')
            old_expanded = original_source.read_text(encoding='utf8')
            if kind == 'tutorial':
                for token, name in token_map.items():
                    code = block(name, (STUDY / name).read_text(encoding='utf8'))
                    expanded = expanded.replace('{' + token + '}', code)
                    old_expanded = old_expanded.replace('{' + token + '}', code)
            assert old_expanded.strip() == before.strip(), (map_id, kind, 'old template/source mismatch')
            if expanded.strip() != before.strip():
                current = expanded.rstrip() + '\n'
                (folder / f'{kind}.md').write_text(current, encoding='utf8')
                changes.append({'map': map_id, 'text': kind, 'before_words': words(before), 'after_words': words(current)})
                diff = ''.join(difflib.unified_diff(before.splitlines(True), current.splitlines(True), fromfile='Before ' + kind, tofile='After ' + kind))
                diffs += f'<details><summary>{kind}.md — show exact prose changes</summary><pre>{html.escape(diff)}</pre></details>'
            else:
                current = before
            texts[kind] = current
            dest = OUT / 'manuscripts' / map_id
            dest.mkdir(parents=True, exist_ok=True)
            (dest / f'{kind}.md').write_text(current, encoding='utf8')
        new_blocks = re.findall(PATTERN, texts['tutorial'], re.S)
        assert new_blocks == old_blocks, (map_id, 'printed code changed')
        for name, code in new_blocks:
            assert code == (STUDY / name).read_text(encoding='utf8').rstrip(), (map_id, name)
            listings.append({'map': map_id, 'file': name, 'unchanged': True, 'matches_source': True, 'sha256': hashlib.sha256(code.encode()).hexdigest()})
        lessons.append(dict(map=map_id, title=title, thread=thread, purpose=purpose, texts=texts, diffs=diffs))

    toc = '<div class="toc">' + ''.join(f'<a href="{x["map"]}.html">{i:02}. {x["title"]}</a>' for i, x in enumerate(lessons, 1)) + '</div>'
    compiled = {'tutorial': '', 'final': ''}
    for i, lesson in enumerate(lessons):
        map_id = lesson['map']
        controls = '<nav>'
        if i: controls += f'<a href="{lessons[i-1]["map"]}.html">← {lessons[i-1]["title"]}</a>'
        if i + 1 < len(lessons): controls += f'<a href="{lessons[i+1]["map"]}.html">{lessons[i+1]["title"]} →</a>'
        controls += '</nav>'
        body = controls + f'<p class="thread">{html.escape(lesson["thread"])} · {html.escape(lesson["purpose"])}</p>'
        body += '<div class="parallel"><article><div class="tag">Tutorial · build and investigate</div>' + prose(lesson['texts']['tutorial']) + '</article><article><div class="tag">Reflection · encounter and question</div>' + prose(lesson['texts']['final']) + '</article></div>'
        body += lesson['diffs'] + controls
        (OUT / f'{map_id}.html').write_text(page(f'{i+1:02}. {lesson["title"]}', body), encoding='utf8')
        for kind in compiled:
            compiled[kind] += f'<section class="chapter" id="{map_id}"><h2>{i+1:02}. {lesson["title"]}</h2><p><a href="{map_id}.html">Read both texts together</a></p><article>{prose(lesson["texts"][kind])}</article></section>'
    for kind, content in compiled.items():
        title = 'Wavefunctions — the complete ' + ('tutorial' if kind == 'tutorial' else 'reflective sequence')
        book_toc = '<div class="toc">' + ''.join(f'<a href="#{x["map"]}">{i:02}. {x["title"]}</a>' for i, x in enumerate(lessons, 1)) + '</div>'
        (OUT / f'{kind}.html').write_text(page(title, book_toc + '<div class="reading">' + content + '</div>'), encoding='utf8')
        (OUT / f'{kind}.md').write_text('# ' + title + '\n\n' + '\n\n---\n\n'.join(x['texts'][kind] for x in lessons), encoding='utf8')
    checks = {'scope': 'Prose-only pass. No new native execution claimed.', 'halls': 12, 'printed_listings': listings, 'protected_files_unchanged': protected, 'changes': changes}
    (OUT / 'verification.json').write_text(json.dumps(checks, indent=2), encoding='utf8')
    rows = ''.join(f'<tr><td><a href="{x["map"]}.html">{i:02}. {x["title"]}</a></td><td>{x["thread"]}</td><td>{x["purpose"]}</td></tr>' for i, x in enumerate(lessons, 1))
    distinctions = lessons[0]['texts']['tutorial'].split('## Four distinctions for the journey\n\n', 1)[1]
    (OUT / 'feedback.html').write_text(page('Assessment — what we keep and clarify', '<article>' + prose((OUT / 'FEEDBACK.md').read_text(encoding='utf8')) + '</article>'), encoding='utf8')
    body = '''<p>Follow a returning cube through a record, a surface, a sound and a sum. The twelve halls keep their order. This pass clarifies the returns between subjects and gives the reflective text more space.</p>
<p class="thread"><strong>Movement</strong> — what changes, and what makes it change?<br><strong>Record</strong> — what survives when the movement has passed?<br><strong>Composition</strong> — what can those parts make together?</p>
<h2>Read the sequence</h2>''' + toc + '<h2>Four mathematical distinctions</h2>' + prose(distinctions) + '''
<p><a href="feedback.html">Assessment decisions and proposed optional extension</a>. Room Memory is an optional artistic investigation. The five-harmonic study completes the formal tutorial sequence. The proposed shared visual-and-sound composition is not yet implemented.</p>
<h2>What changed</h2><ul><li>The opening names the three recurring questions. The middle makes the returns to spatial construction, saved events and overlapping voices explicit.</li><li>Effect Sound keeps phase depth and comparison at the centre. Audio encoding and envelope detail follow the experiment as supporting construction.</li><li>Cage keeps a small, bounded introduction to chance, with replay as its main task.</li><li>Sky Stairs and Beats begin with an event and ask fewer consecutive instructions. Their mathematical and material distinctions remain.</li><li>Room Memory becomes a clearly marked listening interlude, followed by a return to the synthesis bench.</li></ul>
<div class="pictures"><figure><img src="../2026-10-08-effect-sound-a-phase-you-can-hear/after/student.png" alt="The reduced Effect Sound study in Endless Museum"><figcaption>Effect Sound: keep one control and one audible comparison in focus. Existing native capture.</figcaption></figure><figure><img src="../2026-10-08-sky-stairs-a-place-for-a-foot/after/stair.png" alt="The staircase in Endless Museum"><figcaption>Sky Stairs: the eye follows a route before the foot tests it. Existing native capture.</figcaption></figure></div>
<h2>The route remains</h2><table><thead><tr><th>Hall</th><th>Thread</th><th>What travels</th></tr></thead><tbody>''' + rows + '''</tbody></table>
<h2>Review evidence</h2>''' + f'<p>All {len(listings)} printed code listings match their pre-edit versions and saved source. All {len(protected)} protected source, map and sequence files are unchanged. This pass updates {len(changes)} manuscripts and their publishing templates.</p>' + '''<p><a href="verification.json">Checks and word counts</a> · <a href="CHANGES.md">Editorial notes</a>. Each paired hall page includes its exact prose diff. Earlier native tests remain earlier evidence; they were not rerun for this prose pass. Independent reader understanding and headset experience remain separate questions.</p>'''
    (OUT / 'index.html').write_text(page('What returns — movement, record, composition', body), encoding='utf8')
    with zipfile.ZipFile(OUT / 'wavefunctions-readings.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for p in (OUT / 'manuscripts').rglob('*.md'): z.write(p, p.relative_to(OUT).as_posix())
        printed_names = {x['file'] for x in listings}
        for name in sorted(printed_names): z.write(STUDY / name, 'code/' + name)
        mentioned_names = set(re.findall(r'`(\d\d_[a-z_]+\.gd)`', (OUT / 'tutorial.md').read_text(encoding='utf8')))
        for name in sorted(mentioned_names - printed_names):
            candidates = list((ROOT / 'doc/book/iterations').glob('2026-10-08-*/extracted/' + name))
            assert len(candidates) == 1, (name, candidates)
            z.write(candidates[0], 'code/' + name)
        for name in ['tutorial.md', 'final.md', 'verification.json', 'CHANGES.md', 'FEEDBACK.md']: z.write(OUT / name, name)
        z.writestr('READ-ME.txt', 'Wavefunctions: all twelve current tutorials and reflections. Complete printed programs use the prepared Endless Museum and installed XR Tools. Attach one hall study at a time at the placement declared in its tutorial. This is a prose-only revision; verification.json checks unchanged code, maps and order, not a new Godot or headset run.\n')
    print(json.dumps({'halls': 12, 'changed_manuscripts': len(changes), 'unchanged_listings': len(listings), 'protected_files': len(protected)}, indent=2))


if __name__ == '__main__':
    main()
