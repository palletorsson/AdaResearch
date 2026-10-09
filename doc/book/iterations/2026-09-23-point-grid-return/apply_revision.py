from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-23-point-grid-return'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-22-point-trace-grain'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_Line_Grid/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-trace-grain.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-23-point-grid-return.json'
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
assert sha(original) == '62d8af2fd38cc732f93497354525bd903ddcdfeb587c6154ad8b6e3305b2847f', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @grab_sphere_point_snap -->'
end = '## Give the interval a rhythm'
fence = chr(96)*3
checks = {
    'all_three_edits_applied': all(after.count(e['new']) == 1 for e in edits),
    'opening_unchanged': before.split(start)[0] == after.split(start)[0],
    'walking_replay_plan_close_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
    'artifact_markers_unchanged': re.findall(r'<!--\s*@.*?-->',before) == re.findall(r'<!--\s*@.*?-->',after),
    'all_code_blocks_unchanged': re.findall(fence+r'.*?'+fence,before,re.S) == re.findall(fence+r'.*?'+fence,after,re.S),
    'all_footnote_definitions_unchanged': re.findall(r'^\[\^.+',before,re.M) == re.findall(r'^\[\^.+',after,re.M),
}
checks['point_one_unchanged'] = sha((ROOT/'commons/maps/Point_One/final.md').read_bytes()) == 'f95cd4dc84616a0eb8a826d3f1b23268aa1c8bf0a20f07471e9a6419d80ff273'
checks['point_lines_unchanged'] = sha((ROOT/'commons/maps/Point_Lines/final.md').read_bytes()) == '813522cc9fbb898583c37dbeb7c6d5fb969fd52019c15e975ff94a64cb3c7933'
checks['point_trace_unchanged'] = sha((ROOT/'commons/maps/Point_Trace/final.md').read_bytes()) == 'd3a048cc9e3830ef5ad467bfdbd521a31f6c00ff9646dbd92350327d14b36c75'
assert all(checks.values()), checks
for p in [MANUSCRIPT,BUILDER,CORE,OLD_SNAPSHOT,REPORT/'middle.json',REPORT/'audit.json',PURPOSE]:
    backup(p)
OUT.joinpath('Point_Line_Grid.before.md').write_bytes(original)
new_bytes = after.replace('\n','\r\n' if b'\r\n' in original else '\n').encode('utf-8')
new_sha = sha(new_bytes)

snapshot = load(OLD_SNAPSHOT)
source = next(s for s in snapshot['sources'] if s['map']=='Point_Line_Grid')
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
snapshot['note'] = 'Current ten-hall reading snapshot. Three Point Line Grid paragraphs revised locally: index as a count, a return with room for variation, and a marker/record comparison. Unchanged annotations retained by identity. No remote classification; frozen book/audio captures unchanged.'

early = load(REPORT/'middle.json')
hall = next(h for h in early['maps'] if h['map']=='Point_Line_Grid')
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
hall['evidence'].extend([
    evidence('snap-release','commons/primitives/point/grab_sphere_point_snap.gd',
             'var tip_position: Vector3 = _draw_sphere.global_position',4,'artifact',
             'Release shifts the handle so the sampled visible tip reaches its rounded world position.'),
    evidence('snap-recording','commons/primitives/point/grab_sphere_point_snap.gd',
             'var snapped_global = snap_position_to_grid(current_global)',7,'artifact',
             'Held recording rounds the marker position before the distance check; the visible marker is not moved by this recording step.')
])
for ev in hall['evidence']:
    if ev['path']=='commons/maps/Point_Line_Grid/final.md':
        assert after.count(ev['excerpt'])==1, ev['id']
        ev['start_line'] = after[:after.index(ev['excerpt'])].count('\n')+1
        ev['end_line'] = ev['start_line']+ev['excerpt'].count('\n')

core_raw = CORE.read_bytes()
core = json.loads(core_raw)
old_core_sha = core['rooms']['Point_Line_Grid']['text_sha256']
assert old_core_sha == 'b134318a11247b149f31dbe9581f58c83dc9dbd1e85dc80ad6b60f4b932c8b74'
assert core_raw.count(old_core_sha.encode())==1
core_after = core_raw.replace(old_core_sha.encode(),new_sha.encode())
checks['previous_core_text_sha256'] = old_core_sha
checks['preexisting_core_hash_synchronized'] = old_core_sha != sha(original)

builder_raw = BUILDER.read_bytes()
builder = builder_raw.decode('utf-8').replace('\r\n','\n')
old_snapshot_literal = OLD_SNAPSHOT.relative_to(ROOT).as_posix()
assert builder.count(old_snapshot_literal)==1
builder = builder.replace(old_snapshot_literal,NEW_SNAPSHOT.relative_to(ROOT).as_posix(),1)
assert MANUSCRIPT.read_bytes()==original
MANUSCRIPT.write_bytes(new_bytes)
CORE.write_bytes(core_after)
save(NEW_SNAPSHOT,snapshot)
save(REPORT/'middle.json',early)
write_like(BUILDER,builder,builder_raw)
from tools import primitives_purpose_view as purpose
audit = purpose.build_audit()
save(REPORT/'audit.json',audit)
purpose.render_report(audit)

OUT.joinpath('Point_Line_Grid.after.md').write_bytes(new_bytes)
diff = ''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),
                                  fromfile='Point_Line_Grid.before.md',tofile='Point_Line_Grid.after.md'))
OUT.joinpath('Point_Line_Grid.diff').write_text(diff,encoding='utf-8')


def render(text,prefix,encounters=False):
    if encounters:
        text = re.sub(r'<!--\s*@([^>]*?)\s*-->\s*',
            lambda m: '<a id="encounter-'+(m[1].strip() or 'closing')+'"></a>'+chr(10)*2,text)
    else:
        text = re.sub(r'<!--\s*@.*?-->\s*','',text)
    rendered = markdown.markdown(text,extensions=['fenced_code','footnotes'])
    rendered = re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',rendered)
    rendered = re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',rendered)
    if not encounters:
        names = re.findall(r'^\[\^([^\]]+)\]:',after,re.M)
        rendered = re.sub(r'\[\^([^\]]+)\]',lambda m: '<sup><a href="#reading-fn:'+m[1]+'">'+str(names.index(m[1])+1)+'</a></sup>',rendered)
    return rendered

style = re.search(r'<style>(.*?)</style>',PREVIOUS.joinpath('index.html').read_text(encoding='utf-8'),re.S)[1]
toc=[('grab_sphere_point_snap','An address to return to'),('player_trace','A rhythm to walk'),('grid_lines','A drawing becomes a score'),('plan_vitrine','An address underfoot'),('closing','Carry it onward')]
chunks=[
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point Line Grid — somewhere to return</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point Line Grid · 23 September 2026</div>',
 '<h1>Somewhere to return.</h1>',
 '<p class="intro">Your hand has room to vary while the point finds its place again. Three small revisions follow the snapping sphere from a number in the table to the possibility of returning.</p>',
 '<p class="status">Applied to the current chapter. The opening, later encounters, code and footnotes are preserved. Source correspondence checked; no new headset test. Full-book and audio captures remain earlier versions.</p>',
 '<nav><a href="#reading">Read the chapter</a><a href="#changes">Compare three edits</a><a href="Point_Line_Grid.diff">Exact diff</a><a href="/compose/sources?map=Point_Line_Grid&amp;doc=final">Read and comment</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_Line_Grid&amp;view=reading">Text + purpose</a></nav>',
 '<nav class="encounters" aria-label="Encounters in this chapter">'+''.join('<a href="#reading-encounter-'+token+'">'+label+'</a>' for token,label in toc)+'</nav>',
 '<section class="reading" id="reading">'+render(after,'reading-',True)+'</section>',
 '<section id="changes"><h2>Three edits, beside their originals</h2>'
]
for i,e in enumerate(edits,1):
    chunks.append('<section class="change" id="change-'+str(i)+'"><div class="eyebrow">Edit '+str(i)+'</div><h2>'+html.escape(e['title'])+'</h2><p class="reason">'+html.escape(e['incitement'])+'</p><div class="pair"><article><h3>Before</h3>'+render(e['old'],'before-'+str(i)+'-')+'</article><article><h3>Revised</h3>'+render(e['new'],'after-'+str(i)+'-')+'</article></div></section>')
chunks.extend([
 '</section><section class="reading-notes"><h2>What carries the encounter</h2>',
 '<p>Trace already showed how a recording chooses positions. Here those positions acquire addresses. Counting the spacing gives the reader a way into the index; moving away and returning gives the calculation a use.</p>',
 '<p>The same operation can omit a small difference and help two placements agree. That relation stays in the visitor’s hand. No general claim that grids liberate or confine follows from the calculation alone.</p>',
 '<p>The later encounters remain intact: walking across an interval, recognising a wrist-sized bend at another scale, and finding an address underfoot. “An address lets us recognise a return. It does not tell us why we came back.”</p>',
 '<p>Next, continue the close reading with <a href="/compose/sources?map=Point_Triangle_Context&amp;doc=final">Point Triangle Context</a>: when three points close a boundary, what makes the inside a face?</p></section>',
 '<footer><a href="SUMMARY.md">Decisions and source checks</a> · <a href="Point_Line_Grid.before.md">Before this edit</a> · <a href="Point_Line_Grid.after.md">Complete revised chapter</a> · <a href="../2026-09-22-point-trace-grain/index.html#reading">Previous: Trace</a></footer></main></body></html>'
])
OUT.joinpath('index.html').write_text(chr(10).join(chunks),encoding='utf-8')
checks.update(before_sha256=sha(original),after_sha256=new_sha,
              purpose_halls=len(audit['maps']),purpose_paragraphs=audit['total_paragraphs'],
              annotation_blocks=len(new_blocks),new_historical_claims=False,
              scene_or_behavior_changes=False,new_headset_test=False,audiobook_regenerated=False)
save(OUT/'checks.json',checks)
OUT.joinpath('SUMMARY.md').write_text('''# Point Line Grid: somewhere to return

Three small edits sharpen the snapping-sphere encounter. The rest of this mature chapter is preserved after reading it against the current Trace chapter and Grid companions.

## Decisions

1. Introduce the index through whole-number steps from the origin. Keep the five-centimetre example and “The same place has two names.” The two table columns describe the same retained position in metres and lattice indices.
2. Make the return actionable: release, move away, try the placement again. Several nearby inputs round to the same result. The hand can vary while the address agrees, which gives rounding a constructive use in making pieces meet.
3. Replace the table disclaimer with a visible comparison. Try moving the marker while keeping the recorded endpoint still. Both table columns name retained positions; the visible marker supplies the comparison with what the program keeps.

The critical question remains in the encounter: when do we want different positions to count as one, and what can we do with that agreement? No new philosophical or historical claim is added.

## Preserved

The opening bend from Trace, numerical boundary example, two code blocks, artifact anchors, all four footnotes, and every passage from “Give the interval a rhythm” onward. The rhythm of crossing, returning for different reasons, a gesture becoming a score, and addresses reaching upward from the plan already carry particular investigations. They do not need matching rewrites to satisfy a format. Point One, Lines and Trace remain unchanged.

## Source correspondence

The snap scene sets grid_size to 0.05 m. The recorder rounds each marker coordinate before its distance gate; the recording step does not force the visible marker onto that lattice. On release, it shifts the handle by the correction needed to bring the sampled tip onto its rounded position. The table derives both metres and integer indices from retained positions. Checked in grab_sphere_point_snap.gd and its scene, together with the chapter’s technical companion.

No map, artifact, scene, role or runtime behaviour was changed. Source correspondence is not a new headset or learner test. Existing plans to observe paired pens in assembled VR remain open.

## Records and next

Updated the Grid paragraph-purpose records, derived annotation snapshot, purpose view and core manuscript hash. The core record carried a stale hash before this pass; only its Grid manuscript hash was synchronized, with encounter tokens and curation preserved. Preserved unchanged paragraph notes and open actions. Before/after files, the exact diff and preservation checks accompany this page. Frozen full-book and audio captures were not regenerated.

The current close reading can continue to Point_Triangle_Context. Carry the distinction between naming a place and giving a body somewhere to stand into the distinction between a closed boundary and a face.
''',encoding='utf-8')
print(json.dumps(checks,indent=2))
