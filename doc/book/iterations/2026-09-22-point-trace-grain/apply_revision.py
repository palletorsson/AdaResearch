from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-22-point-trace-grain'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-22-point-trace-kept-positions'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_Trace/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-trace-kept-positions.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-trace-grain.json'
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
assert sha(original) == '19bb00349df0faf61a11c7238e57e601ea6189afa6225b019dcbaf5aea592e58', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @draw_dot -->'
end = '## Move the place that draws'
fence = chr(96)*3
checks = {
    'all_four_edits_applied': all(after.count(e['new']) == 1 for e in edits),
    'opening_unchanged': before.split(start)[0] == after.split(start)[0],
    'stick_board_close_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
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
snapshot['note'] = 'Current ten-hall reading snapshot. Four Point Trace threshold, resolution and retention paragraphs revised locally; unchanged annotations retained by block identity. No remote classification. Frozen book and audio captures remain unchanged.'

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
        incitement=e['incitement'])
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
    if encounters:
        text = text.replace('## Another resolution, another gesture', '<a id="resolution"></a>'+chr(10)*2+'## Another resolution, another gesture')
    text = text.replace('~~you~~','<del>you</del>')
    rendered = markdown.markdown(text,extensions=['fenced_code','footnotes'])
    rendered = re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',rendered)
    rendered = re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',rendered)
    if not encounters:
        names = re.findall(r'^\[\^([^\]]+)\]:',after,re.M)
        rendered = re.sub(r'\[\^([^\]]+)\]',lambda m: '<sup><a href="#reading-fn:'+m[1]+'">'+str(names.index(m[1])+1)+'</a></sup>',rendered)
    return rendered
style = re.search(r'<style>(.*?)</style>',PREVIOUS.joinpath('index.html').read_text(encoding='utf-8'),re.S)[1]
toc=[('reading-encounter-draw_dot','Drawing point'),('reading-resolution','Resolution'),('reading-encounter-draw_stick','Drawing stick'),('reading-encounter-whiteboard','Whiteboard'),('reading-encounter-closing','Carry it onward')]
chunks=[
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point Trace — a grain to draw with</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point Trace · resolution and retention · 22 September 2026</div>',
 '<h1>A grain to draw with.</h1>',
 '<p class="intro">A numerical example for the blue dot, a diagonal through the grid, and permission to take time looking. Four local edits finish this close reading of Point Trace, including a simpler movement-threshold sentence.</p>',
 '<p class="status">Applied to the current chapter. The invitation to repeat a corner, the stick, whiteboard, code and footnotes are preserved. Source correspondence was checked; no new headset test was performed. Full-book and audio captures remain earlier versions.</p>',
 '<nav><a href="#reading-resolution">Read the resolution encounter</a><a href="#reading">Read the whole chapter</a><a href="#changes">Compare four edits</a><a href="Point_Trace.diff">Exact diff</a><a href="/compose/sources?map=Point_Trace&amp;doc=final">Read and comment</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_Trace&amp;view=reading">Text + purpose</a></nav>',
 '<nav class="encounters" aria-label="Encounters in this chapter">'+''.join('<a href="#'+token+'">'+label+'</a>' for token,label in toc)+'</nav>',
 '<section class="reading" id="reading">'+render(after,'reading-',True)+'</section>',
 '<section id="changes"><h2>Four edits, beside their originals</h2>'
]
for i,e in enumerate(edits,1):
    chunks.append('<section class="change" id="change-'+str(i)+'"><div class="eyebrow">Edit '+str(i)+'</div><h2>'+html.escape(e['title'])+'</h2><p class="reason">'+html.escape(e['incitement'])+'</p><div class="pair"><article><h3>Before</h3>'+render(e['old'],'before-'+str(i)+'-')+'</article><article><h3>Revised</h3>'+render(e['new'],'after-'+str(i)+'-')+'</article></div></section>')
chunks.extend([
 '</section><section class="reading-notes"><h2>What stays open</h2>',
 '<p>The blue dot gives rounding a scale the reader can follow: 0.05 metres becomes 0.08 along one axis. Movement and a new stored position remain different events. The joining line still has diagonal directions available.</p>',
 '<p>The paragraph about making a repeatable corner is preserved. A small flourish can disappear, while the same spacing can help the hand find a position again. What matters is the drawing the reader wants to make.</p>',
 '<p>The capacity paragraph recovers one sentence from the earlier draft: “Looking at the line need not spend another place in it.” The reader can understand the limit without having to exhaust it.</p>',
 '<p>The stick and whiteboard encounters already carry clear investigations: moving the observed point to a tip, and using a lift to separate marks. They stay intact. Next is <a href="/compose/sources?map=Point_Line_Grid&amp;doc=final">Point Line Grid</a>, where the drawing returns at another scale and positions acquire integer addresses.</p></section>',
 '<footer><a href="SUMMARY.md">Decisions and source checks</a> · <a href="Point_Trace.before.md">Before this edit</a> · <a href="Point_Trace.after.md">Complete revised chapter</a> · <a href="../2026-09-22-point-trace-kept-positions/index.html#reading">Previous edit</a></footer></main></body></html>'
])
OUT.joinpath('index.html').write_text(chr(10).join(chunks),encoding='utf-8')
checks.update(before_sha256=sha(original),after_sha256=new_sha,
              purpose_halls=len(audit['maps']),purpose_paragraphs=audit['total_paragraphs'],
              annotation_blocks=len(new_blocks),new_historical_claims=False,
              scene_or_behavior_changes=False,new_headset_test=False,audiobook_regenerated=False)
save(OUT/'checks.json',checks)
summary="""# Point Trace: a grain to draw with

Four local edits complete this close reading of Point Trace. The chapter's structure and its strongest actions remain intact.

## Decisions

1. Repair the cumbersome sentence introduced in the preceding pass. Use a plain account of waiting for at least five millimetres of movement before considering another position. Keep the relation between a still drawing, continuing time and the absence of pause duration from the position list. The exact comparison-reference update remains in technical.md; the text does not claim that path length accumulates or that the reference is always the last saved point.
2. Give the rounding code one coordinate to act on. For blue, 80 mm is 0.08 m; an X reading of 0.05 rounds to 0.08. Y and Z follow the same operation. Explain duplicate rejection as why passing the movement test need not add a corner.
3. Stay with the possibilities of the gridded drawing. Stored positions lie on the grid while joining segments can run diagonally. Replace the repeated reminder that all sampling is partial with a distinction a visitor can look for in the shape.
4. Recover “Looking at the line need not spend another place in it” from the earlier draft. Keep finite retention explicit, without making filling a 4096-position list a required task. This also reflects the author's request to preserve pleasure and usefulness alongside limits.

## Kept

The opening loop, pause and release; the list explanation and eleven-point display example from the prior pass; the four resolution settings; the wrist negotiating with spacing; the invitation to make a corner one can return to; the drawing stick and whiteboard; the transfer into Grid; all code, footnotes and artifact markers. Point One and Point Lines are unchanged.

The existing stick and board passages already contain particular bodily investigations and do not need equivalent edits merely for consistency. A final reading of the complete chapter supports continuing to Grid.

## Source correspondence

Current Point_Trace placements set dot resolutions to none, 10, 40 and 80 mm. The shared recorder converts millimetres to metres, applies snappedf independently to X/Y/Z in free space, rejects a shaped position that approximately matches the last retained one, and draws a LINE_STRIP between retained points. Spatial rounding does not require axis-aligned segments.

The five-millimetre comparison is against the last movement-gate-passing position. Passing advances that reference before shaping. The source and technical companion retain this precise account; the main prose names the operation at the pace of the encounter.

The scene capacity is 4096. Appending beyond capacity removes the oldest entry. Fading is disabled. Looking at a released drawing adds no points to it. The retained development opportunity for a short capacity experiment is preserved in the purpose notes; no new control is promised here.

## Checks and next step

Text, purpose snapshot and core manuscript hash synchronized. Existing code and footnotes preserved. No script, map, scene or role changes; no new Godot, headset or learner run. Full-book and audiobook captures remain frozen.

Next: Point_Line_Grid. Its opening already receives the released drawing and explains a metre coordinate and an integer index as two names for a place. Follow that encounter rather than repeating Trace's explanation of rounding.

See changes.json, Point_Trace.diff and checks.json for paragraph purposes, exact edits and preservation checks.
"""
OUT.joinpath('SUMMARY.md').write_text(summary,encoding='utf-8')
print(json.dumps(checks,indent=2))
