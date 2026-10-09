from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-22-point-trace-kept-positions'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-22-point-lines-walk-and-trace'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_Trace/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-lines-walk.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-trace-kept-positions.json'
PURPOSE = ROOT / 'doc/research/possible-bodies/primitives-purpose.html'

def sha(b): return hashlib.sha256(b).hexdigest()
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p, value): p.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
def write_like(p, text, original):
    p.write_bytes(text.replace('\r\n','\n').replace('\n', '\r\n' if b'\r\n' in original else '\n').encode('utf-8'))
def backup(p):
    q = OUT / 'before' / p.relative_to(ROOT)
    q.parent.mkdir(parents=True,exist_ok=True)
    q.write_bytes(p.read_bytes())

original = MANUSCRIPT.read_bytes()
assert sha(original) == 'a118e22509df395ff46bcfa57fd5a7a4c756ed6697c3a3ca74909073190f00a3', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @draw_dot -->'
end = '## Another resolution, another gesture'
fence = chr(96)*3
checks = {
    'all_three_edits_applied': all(after.count(e['new']) == 1 for e in edits),
    'opening_unchanged': before.split(start)[0] == after.split(start)[0],
    'resolution_stick_board_close_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
    'artifact_markers_unchanged': re.findall(r'<!--\s*@.*?-->',before) == re.findall(r'<!--\s*@.*?-->',after),
    'all_code_blocks_unchanged': re.findall(fence+r'.*?'+fence,before,re.S) == re.findall(fence+r'.*?'+fence,after,re.S),
    'all_footnote_definitions_unchanged': re.findall(r'^\[\^.+',before,re.M) == re.findall(r'^\[\^.+',after,re.M),
}
checks['point_one_unchanged'] = sha((ROOT/'commons/maps/Point_One/final.md').read_bytes()) == 'f95cd4dc84616a0eb8a826d3f1b23268aa1c8bf0a20f07471e9a6419d80ff273'
checks['point_lines_unchanged'] = sha((ROOT/'commons/maps/Point_Lines/final.md').read_bytes()) == '813522cc9fbb898583c37dbeb7c6d5fb969fd52019c15e975ff94a64cb3c7933'
assert all(checks.values()), checks
for p in [MANUSCRIPT,BUILDER,CORE,OLD_SNAPSHOT,REPORT/'early.json',REPORT/'audit.json',PURPOSE]:
    backup(p)
OUT.joinpath('Point_Trace.before.md').write_bytes(original)
new_bytes = after.replace('\n','\r\n' if b'\r\n' in original else '\n').encode('utf-8')
new_sha = sha(new_bytes)

snapshot = load(OLD_SNAPSHOT)
source = next(s for s in snapshot['sources'] if s['map']=='Point_Trace')
old_blocks = {b['id']:b for b in source['blocks']}
new_blocks = parse_blocks(after)
for b in new_blocks:
    if b['id'] in old_blocks:
        for key in ['status','registers','model','request_sha256']:
            if key in old_blocks[b['id']]:
                b[key] = old_blocks[b['id']][key]
source['blocks'],source['sha256'] = new_blocks,new_sha
snapshot['generated_at'] = datetime.now(timezone.utc).isoformat()
snapshot['derived_from'] = OLD_SNAPSHOT.relative_to(ROOT).as_posix()
snapshot['note'] = 'Current ten-hall reading snapshot. Three Point Trace list, pause and display paragraphs revised locally; unchanged annotations retained by block identity. No remote classification. Frozen book and audio captures remain unchanged.'

early = load(REPORT/'early.json')
hall = next(h for h in early['maps'] if h['map']=='Point_Trace')
assert hall['source_sha256']==sha(original)
old_notes = {p['block_id']:p for p in hall['paragraphs']}
new_note_by_id = {}
id_map = {}
for e in edits:
    old_block = next(b for b in old_blocks.values() if b['source_text']==e['old'])
    new_block = next(b for b in new_blocks if b['source_text']==e['new'])
    note = copy.deepcopy(old_notes[old_block['id']])
    note.update(block_id=new_block['id'],block_sha256=new_block['sha256'],
        purpose=e['purpose'],reader_move=e['reader_move'],why_here=e['why_here'],
        without=e['without'],assessment=e['assessment'],evidence_ids=e['evidence'],
        opportunity='',incitement=e['incitement'])
    new_note_by_id[new_block['id']] = note
    id_map[old_block['id']] = new_block['id']
hall['paragraphs'] = [new_note_by_id[b['id']] if b['id'] in new_note_by_id else old_notes[b['id']]
                      for b in new_blocks if b['kind'] in ['paragraph','footnote']]
hall['source_sha256'] = new_sha
for action in hall['actions']:
    action['block_ids'] = [id_map.get(b,b) for b in action['block_ids']]

def evidence(eid, path, match, count, kind, note):
    lines = ROOT.joinpath(path).read_text(encoding='utf-8').splitlines()
    hits = [i for i,line in enumerate(lines) if match in line]
    assert len(hits)==1, (eid,hits)
    a=hits[0]; b=min(a+count,len(lines))
    return {'id':eid,'path':path,'start_line':a+1,'end_line':b,
            'excerpt':'\n'.join(lines[a:b]),'kind':kind,'note':note}
time_lines=(ROOT/'commons/primitives/point/draw_dot.gd').read_text(encoding='utf-8').splitlines()
assert time_lines[430].strip()=='if fade_trail:' and time_lines[431].strip()=='_trail_times.append(_time_elapsed)'
hall['evidence'].append({'id':'optional-times','path':'commons/primitives/point/draw_dot.gd','start_line':431,'end_line':432,'excerpt':'\n'.join(time_lines[430:432]),'kind':'artifact','note':'Per-point times are appended only with fading enabled. These placements retain the default false setting.'})
for ev in hall['evidence']:
    if ev['path']=='commons/maps/Point_Trace/final.md':
        assert after.count(ev['excerpt'])==1, ev['id']
        ev['start_line'] = after[:after.index(ev['excerpt'])].count('\n')+1
        ev['end_line'] = ev['start_line']+ev['excerpt'].count('\n')

core_raw = CORE.read_bytes()
core = json.loads(core_raw)
assert core['rooms']['Point_Trace']['text_sha256']==sha(original)
assert core_raw.count(sha(original).encode())==1
core_after = core_raw.replace(sha(original).encode(),new_sha.encode())

builder_raw = BUILDER.read_bytes()
builder = builder_raw.decode('utf-8').replace('\r\n','\n')
old_snapshot_literal = OLD_SNAPSHOT.relative_to(ROOT).as_posix()
assert builder.count(old_snapshot_literal)==1
builder = builder.replace(old_snapshot_literal,NEW_SNAPSHOT.relative_to(ROOT).as_posix(),1)
assert MANUSCRIPT.read_bytes()==original
MANUSCRIPT.write_bytes(new_bytes)
CORE.write_bytes(core_after)
save(NEW_SNAPSHOT,snapshot)
save(REPORT/'early.json',early)
write_like(BUILDER,builder,builder_raw)
from tools import primitives_purpose_view as purpose
audit = purpose.build_audit()
save(REPORT/'audit.json',audit)
purpose.render_report(audit)

OUT.joinpath('Point_Trace.after.md').write_bytes(new_bytes)
diff = ''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),
                                  fromfile='Point_Trace.before.md',tofile='Point_Trace.after.md'))
OUT.joinpath('Point_Trace.diff').write_text(diff,encoding='utf-8')

def render(text,prefix,encounters=False):
    if encounters:
        text = re.sub(r'<!--\s*@([^>]*?)\s*-->\s*',
            lambda m: '<a id="encounter-'+(m[1].strip() or 'closing')+'"></a>'+chr(10)*2,text)
    else:
        text = re.sub(r'<!--\s*@.*?-->\s*','',text)
    text = text.replace('~~you~~','<del>you</del>')
    rendered = markdown.markdown(text,extensions=['fenced_code','footnotes'])
    rendered = re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',rendered)
    rendered = re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',rendered)
    if not encounters:
        names = re.findall(r'^\[\^([^\]]+)\]:',after,re.M)
        rendered = re.sub(r'\[\^([^\]]+)\]',lambda m: '<sup><a href="#reading-fn:'+m[1]+'">'+str(names.index(m[1])+1)+'</a></sup>',rendered)
    return rendered
style = re.search(r'<style>(.*?)</style>',PREVIOUS.joinpath('index.html').read_text(encoding='utf-8'),re.S)[1]
toc=[('draw_dot','Drawing point'),('draw_stick','Drawing stick'),('whiteboard','Whiteboard'),('closing','Carry it onward')]
chunks=[
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point Trace — the time between positions</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point Trace · the first drawing encounter · 22 September 2026</div>',
 '<h1>The time between positions.</h1>',
 '<p class="intro">Three small edits clarify what the drawing keeps, how its count works, and what can leave the screen while remaining in the line. The loop, pause and release that open the encounter are preserved.</p>',
 '<p class="status">Applied to the current chapter. The later resolution, stick and whiteboard passages, all code and footnotes are unchanged. Source correspondence was checked; no new headset test was performed. The full-book export and audiobook remain earlier captures.</p>',
 '<nav><a href="#reading">Read the chapter</a><a href="#changes">Compare three edits</a><a href="Point_Trace.diff">Exact diff</a><a href="/compose/sources?map=Point_Trace&amp;doc=final">Read and comment</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_Trace&amp;view=reading">Text + purpose</a></nav>',
 '<nav class="encounters" aria-label="Encounters in this chapter">'+''.join('<a href="#reading-encounter-'+token+'">'+label+'</a>' for token,label in toc)+'</nav>',
 '<section class="reading" id="reading">'+render(after,'reading-',True)+'</section>',
 '<section id="changes"><h2>Three edits, beside their originals</h2>'
]
for i,e in enumerate(edits,1):
    chunks.append('<section class="change" id="change-'+str(i)+'"><div class="eyebrow">Edit '+str(i)+'</div><h2>'+html.escape(e['title'])+'</h2><p class="reason">'+html.escape(e['incitement'])+'</p><div class="pair"><article><h3>Before</h3>'+render(e['old'],'before-'+str(i)+'-')+'</article><article><h3>Revised</h3>'+render(e['new'],'after-'+str(i)+'-')+'</article></div></section>')
chunks.extend([
 '</section><section class="reading-notes"><h2>What the reader can now follow</h2>',
 '<p>The previous room connected two positions. This recorder keeps another position, then another, and repeats that construction. The new curve has a legible relation to something the reader already knows how to make.</p>',
 '<p>A pause gives the count a question to answer. Time continues, yet another position need not enter the list. The prose stays with holding a line still and asks what in this particular record could tell us how long that took.</p>',
 '<p>The screen supplies a second distinction. At eleven retained positions it begins with row 2, while the drawing still includes its beginning. The instrument reports the same list through a smaller window.</p>',
 '<p>The next comparison is already in the chapter: different spatial resolutions can swallow a small flourish and make a chosen corner easier to repeat. Keep both possibilities in view.</p></section>',
 '<footer><a href="SUMMARY.md">Decisions and source checks</a> · <a href="Point_Trace.before.md">Before this edit</a> · <a href="Point_Trace.after.md">Complete revised chapter</a> · <a href="../2026-09-22-point-lines-walk-and-trace/index.html#reading">Previous hall</a></footer></main></body></html>'
])
OUT.joinpath('index.html').write_text(chr(10).join(chunks),encoding='utf-8')
checks.update(before_sha256=sha(original),after_sha256=new_sha,
              purpose_halls=len(audit['maps']),purpose_paragraphs=audit['total_paragraphs'],
              annotation_blocks=len(new_blocks),new_historical_claims=False,
              scene_or_behavior_changes=False,new_headset_test=False,audiobook_regenerated=False)
save(OUT/'checks.json',checks)
summary="""# Point Trace: the time between positions

Three paragraph edits in the first drawing encounter. The opening loop, pause, release and change of viewpoint already give the reader something to do and notice; they are preserved.

## Decisions

- Name the existing list and explain size(). Carry the previous room's two-point construction into repeated connections that can form a curve. Preserve the joints image and the distinction between a drawn connection and the intervening hand movement.
- Make the movement comparison precise without a control inventory. The reference position advances when the movement gate passes, before any later shaping or duplicate rejection. It is not necessarily the last saved point. Keep the return to Point One's running counter and give the pause a concrete consequence: the position list does not report how long the reader waited.
- Make the last-ten display window easy to picture. At eleven retained positions, rows 2–11 are displayed while all eleven still belong to the line. Disappearing from this window is not the same as eviction from the stored list.

## Preserved

“Bring the detour”; the opening encounter; the current code; the shared unread machinery; the resolution comparison and its invitation to find a use for coarseness; the drawing stick; the whiteboard's meaningful lifting; the release-and-copy route into Grid; all footnotes and artifact anchors. Point One and Point Lines are unchanged.

Compared the current chapter with the earlier version in doc/space/point-trace-focus-2026-09-16/previous/final.md. Its strongest passages already survive. No wholesale restoration, shortening or further historical claims are needed here.

## Source correspondence

The current dot scene observes GrabPoint, uses a 0.005 m movement threshold and retains up to 4096 positions. draw_dot.gd compares current_global with _last_global_position; below threshold it returns before appending. Passing advances the comparison position before shaping and duplicate checks.

size() supplies the retained count. The table starts at max(0, size - 10), and displayed row numbers add one to the current list index. The mesh joins the retained positions as a line strip.

Per-point timestamps are appended only when fading is enabled. These placements keep fading off. The script has elapsed time for other work; that does not mean the position list records the duration of a still pause. No claim is made that the whole engine stops measuring time.

The source permits these investigations. No new Godot, headset or learner test was performed. No map, scene, script behavior or artifact roles changed.

## Reading records and next step

The canonical chapter, encounter text hash and paragraph-purpose notes are synchronized in a new derived snapshot. The frozen full-book and audio captures remain unchanged. Exact edits are in Point_Trace.diff; before and after chapters are retained beside this page.

Next close reading: another resolution, another gesture. Start from the existing comparison of enlargement, repeated corners and what a particular drawing needs from its recorder. The later stick and whiteboard passages are already concrete; do not force equivalent changes into each encounter.
"""
OUT.joinpath('SUMMARY.md').write_text(summary,encoding='utf-8')
print(json.dumps(checks,indent=2))
