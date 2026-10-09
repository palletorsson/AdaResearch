from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-22-point-lines-connection'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-22-point-one-arrival'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_Lines/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-one-arrival.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-lines-connection.json'
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
assert sha(original) == '709a6d2de2f2ed52eba0d8feca6bd5a927953907ceb1b0cc0f2c0d1aec5c363b', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @line_demo -->'
end = '<!-- @walk_this_line_marking -->'
fence = chr(96)*3
checks = {
    'all_five_edits_applied': all(after.count(e['new']) == 1 for e in edits),
    'chapter_opening_unchanged': before.split(start)[0] == after.split(start)[0],
    'walk_trace_close_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
    'artifact_markers_unchanged': re.findall(r'<!--\s*@.*?-->',before) == re.findall(r'<!--\s*@.*?-->',after),
    'all_code_blocks_unchanged': re.findall(fence+r'.*?'+fence,before,re.S) == re.findall(fence+r'.*?'+fence,after,re.S),
    'all_footnote_definitions_unchanged': re.findall(r'^\[\^.+',before,re.M) == re.findall(r'^\[\^.+',after,re.M),
}
checks['point_one_unchanged'] = sha((ROOT/'commons/maps/Point_One/final.md').read_bytes()) == 'f95cd4dc84616a0eb8a826d3f1b23268aa1c8bf0a20f07471e9a6419d80ff273'
assert all(checks.values()), checks
for p in [MANUSCRIPT,BUILDER,CORE,OLD_SNAPSHOT,REPORT/'early.json',REPORT/'audit.json',PURPOSE]:
    backup(p)
OUT.joinpath('Point_Lines.before.md').write_bytes(original)
new_bytes = after.replace('\n','\r\n' if b'\r\n' in original else '\n').encode('utf-8')
new_sha = sha(new_bytes)

snapshot = load(OLD_SNAPSHOT)
source = next(s for s in snapshot['sources'] if s['map']=='Point_Lines')
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
snapshot['note'] = 'Current ten-hall reading snapshot. Five Point Lines connection, barrier and measurement paragraphs revised locally; unchanged annotations retained by block identity. No remote classification. Frozen book and audio captures remain unchanged.'

early = load(REPORT/'early.json')
hall = next(h for h in early['maps'] if h['map']=='Point_Lines')
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
hall['evidence'].extend([
 evidence('snap-release','commons/primitives/snappoint/snap_point.gd','func _on_dropped(_pickable) -> void:',6,'artifact','Releasing samples the nearby endpoint and requests a connection when eligible.'),
 evidence('barrier-shape','commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.gd','body.name = "BarrierBody"',8,'artifact','The solid barrier box extends from floor to bar top, including the visually empty gap under the plank.'),
 evidence('previous-arrival-state','commons/artifacts/drag_point_target/drag_point_target.gd','if near and not _inside:',9,'artifact','Point One separates staying inside from entering; leaving clears the inside state so an arrival can repeat.'),
 evidence('line-update','commons/primitives/line/line.gd','func update_line_transform(start_pos: Vector3, end_pos: Vector3):',15,'artifact','The measuring line calculates endpoint distance, midpoint and the ordered direction while updating the visible segment.'),
])
for ev in hall['evidence']:
    if ev['path']=='commons/maps/Point_Lines/final.md':
        assert after.count(ev['excerpt'])==1, ev['id']
        ev['start_line'] = after[:after.index(ev['excerpt'])].count('\n')+1
        ev['end_line'] = ev['start_line']+ev['excerpt'].count('\n')

core_raw = CORE.read_bytes()
core = json.loads(core_raw)
assert core['rooms']['Point_Lines']['text_sha256']==sha(original)
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

OUT.joinpath('Point_Lines.after.md').write_bytes(new_bytes)
diff = ''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),
                                  fromfile='Point_Lines.before.md',tofile='Point_Lines.after.md'))
OUT.joinpath('Point_Lines.diff').write_text(diff,encoding='utf-8')

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
    return rendered
style = re.search(r'<style>(.*?)</style>',PREVIOUS.joinpath('index.html').read_text(encoding='utf-8'),re.S)[1]
toc=[('line_demo','Connection'),('do_not_cross_barrier','Barrier'),('line','Measurement'),('walk_this_line_marking','Walk this line'),('player_trace','Trace')]
chunks=[
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point Lines — a connection opens a passage</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point Lines · opening encounters · 22 September 2026</div>',
 '<h1>A connection opens a passage.</h1>',
 '<p class="intro">Five small edits to connection, barrier and measurement. The whole chapter is here for continuous reading, followed by the original and revised paragraphs.</p>',
 '<p class="status">Applied to the current chapter. Walk this line, the player trace, all code and footnotes remain unchanged. Source correspondence was checked; no new headset test was performed. The frozen full-book export and audiobook remain earlier captures.</p>',
 '<nav><a href="#reading">Read Point Lines</a><a href="#changes">Compare five edits</a><a href="#read-through">Decisions</a><a href="Point_Lines.diff">Exact diff</a><a href="/compose/sources?map=Point_Lines&amp;doc=final">Read and comment</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_Lines&amp;view=reading">Text + purpose</a></nav>',
 '<nav class="encounters" aria-label="Encounters in this chapter">'+''.join('<a href="#reading-encounter-'+token+'">'+label+'</a>' for token,label in toc)+'</nav>',
 '<section class="reading" id="reading">'+render(after,'reading-',True)+'</section>',
 '<section id="changes"><h2>What changed, and what prompted it</h2>'
]
for i,e in enumerate(edits,1):
    chunks.append('<section class="change" id="change-'+str(i)+'"><div class="eyebrow">Edit '+str(i)+'</div><h2>'+html.escape(e['title'])+'</h2><p class="reason">'+html.escape(e['incitement'])+'</p><div class="pair"><article><h3>Before</h3>'+render(e['old'],'before-'+str(i)+'-')+'</article><article><h3>Revised</h3>'+render(e['new'],'after-'+str(i)+'-')+'</article></div></section>')
chunks.extend([
 '</section><section class="reading-notes" id="read-through"><h2>The thread through these encounters</h2>',
 '<p>The hand joins two points, a passage opens, and the code makes the connection between those events available to question. Measurement then asks what can change while something else stays the same.</p>',
 '<ul><li><strong>A gesture before an explanation.</strong> Bring the points close and let go. The explosion remains a surprise before its cause is explained.</li>',
 '<li><strong>A visible gap can still be impassable.</strong> The collision shape gives the critical question a precise material condition. The wording explains what enforced the prohibition.</li>',
 '<li><strong>The previous room returns with a difference.</strong> Point One admits repeated arrivals. Here the passage remains open after disconnection. The rooms preserve different consequences of a gesture.</li>',
 '<li><strong>One segment, two directions.</strong> Reverse the written subtraction while holding the positions fixed. The length remains one metre; the ordered displacement reverses. This is a calculation to try, not a claim about a new in-game control.</li></ul>',
 '<p>The next close reading can stay with <a href="#reading-encounter-walk_this_line_marking">Walk this line and the player trace</a>: what a straight instruction asks of a moving body, and what its recorded path can show.</p></section>',
 '<footer><a href="SUMMARY.md">Decisions and source checks</a> · <a href="Point_Lines.before.md">Before this edit</a> · <a href="Point_Lines.after.md">Complete revised chapter</a> · <a href="../2026-09-22-point-one-arrival/index.html#reading">Point One</a></footer></main></body></html>'
])
OUT.joinpath('index.html').write_text(chr(10).join(chunks),encoding='utf-8')
checks.update(before_sha256=sha(original),after_sha256=new_sha,
              purpose_halls=len(audit['maps']),purpose_paragraphs=audit['total_paragraphs'],
              annotation_blocks=len(new_blocks),new_historical_claims=False,
              scene_or_behavior_changes=False,new_headset_test=False,
              audiobook_regenerated=False)
save(OUT/'checks.json',checks)
summary = """# Point Lines: connection, barrier and measurement

Five paragraph edits sharpen the first three encounters. This is a prose pass; no artifact, scene, map or role changes were made.

## Decisions

- Give the hand a plain action before the barrier breaks: bring an endpoint close and let go.
- Explain the apparently empty gap beneath the plank through the actual floor-to-bar collision shape. The explosion removes that shape; disconnecting the points does not restore it.
- Replace a general transition with a specific return to Point One: repeated arrival there, a lasting open passage here. The final sentence interprets what these rules let the rooms keep from a gesture.
- Read the existing displacement example component by component.
- Reverse the subtraction with the endpoints fixed to distinguish direction from length. This acts on the written example; it does not invent a control in the hall.

Walk this line, the player trace, the closing invitation to bring the detour, all code blocks, artifact markers and footnotes are unchanged. Point One is unchanged.

## Source correspondence

snap_point.gd detects the nearby endpoint when released and attempts a connection. snap_connection_manager.gd creates the relation and emits connection_created. line_demo.gd opens the nearby Point Lines barrier on the first accepted connection; disconnection does not restore it.

do_not_cross_barrier.gd creates a box extending from floor to bar top and removes its physics body when broken. The visible gap beneath the plank belongs to that box.

drag_point_target.gd clears _inside after leaving, allowing a further entry. Point One enables repeated arrivals by default. This supports the comparison with the first-only barrier consequence.

line.gd derives its cylinder from the distance, midpoint and direction between the endpoints; its displayed length is rounded to two decimal places. The unchanged written example uses Vector3 subtraction and length().

These are source checks, not a new VR observation or a claim of verified tactile feedback.

## Scope and next encounter

The current technical.md and tutorial.md still describe older teaching routes. Existing purpose-view actions already record this. They were not used as evidence for the current interaction and were not rewritten in this narrow prose pass.

The measuring-line source also contains a near-integer visual jitter effect and conditional feedback. This is a possible later inquiry into how a measuring instrument draws attention to selected values; its runtime behavior needs checking before the manuscript describes it as an experienced effect.

Continue next with Walk this line and the player trace. Keep the distinction between a marking that invites a path and a record that samples actual movement.

## Reading records

The current manuscript hash, encounter metadata and purpose notes are synchronized in a new derived snapshot. Unchanged annotations are retained by block identity. This page includes continuous reading and five original/revised pairs. Frozen full-book and audiobook captures were not regenerated.

See Point_Lines.diff, changes.json and checks.json for exact edits, paragraph purposes and preservation checks.
"""
OUT.joinpath('SUMMARY.md').write_text(summary,encoding='utf-8')
print(json.dumps(checks,indent=2))
