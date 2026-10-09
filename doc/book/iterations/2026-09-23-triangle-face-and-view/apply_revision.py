from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-23-triangle-face-and-view'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-23-point-grid-return'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_Triangle_Context/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-23-point-grid-return.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-23-triangle-face-and-view.json'
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
assert sha(original) == 'aaf2030cc962a6468684cd41f8774724200f1e5faed9ba4de3da3dd3b98b0ce2', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @triangle_line_puzzle -->'
end = 'Follow their edges across the notch.'
fence = chr(96)*3
checks = {
    'all_five_edits_applied': all(after.count(e['new']) == 1 for e in edits),
    'opening_unchanged': before.split(start)[0] == after.split(start)[0],
    'fan_limits_choices_close_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
    'artifact_markers_unchanged': re.findall(r'<!--\s*@.*?-->',before) == re.findall(r'<!--\s*@.*?-->',after),
    'all_code_blocks_unchanged': re.findall(fence+r'.*?'+fence,before,re.S) == re.findall(fence+r'.*?'+fence,after,re.S),
    'all_footnote_definitions_unchanged': re.findall(r'^\[\^.+',before,re.M) == re.findall(r'^\[\^.+',after,re.M),
}
checks['point_one_unchanged'] = sha((ROOT/'commons/maps/Point_One/final.md').read_bytes()) == 'f95cd4dc84616a0eb8a826d3f1b23268aa1c8bf0a20f07471e9a6419d80ff273'
checks['point_lines_unchanged'] = sha((ROOT/'commons/maps/Point_Lines/final.md').read_bytes()) == '813522cc9fbb898583c37dbeb7c6d5fb969fd52019c15e975ff94a64cb3c7933'
checks['point_trace_unchanged'] = sha((ROOT/'commons/maps/Point_Trace/final.md').read_bytes()) == 'd3a048cc9e3830ef5ad467bfdbd521a31f6c00ff9646dbd92350327d14b36c75'
checks['point_grid_unchanged'] = sha((ROOT/'commons/maps/Point_Line_Grid/final.md').read_bytes()) == '4b555b97d34557bb830e03a8c69b073a791e81ae734fbba7cb31a48152d6c5d1'
assert all(checks.values()), checks
for p in [MANUSCRIPT,BUILDER,CORE,OLD_SNAPSHOT,REPORT/'middle.json',REPORT/'audit.json',PURPOSE]:
    backup(p)
OUT.joinpath('Point_Triangle_Context.before.md').write_bytes(original)
new_bytes = after.replace('\n','\r\n' if b'\r\n' in original else '\n').encode('utf-8')
new_sha = sha(new_bytes)

snapshot = load(OLD_SNAPSHOT)
source = next(s for s in snapshot['sources'] if s['map']=='Point_Triangle_Context')
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
snapshot['note'] = 'Current ten-hall reading snapshot. Five Triangle paragraphs refined locally: appearance, viewpoint, corner timing and release, and the shared fan vertex. Unchanged annotations retained. No remote classification; frozen book/audio captures unchanged.'

early = load(REPORT/'middle.json')
hall = next(h for h in early['maps'] if h['map']=='Point_Triangle_Context')
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
    if e['title'] == 'Release commits the corner edit':
        note['opportunity'] = ''
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
hall['actions'] = [a for a in hall['actions'] if a['title'] != 'Specify release when editing a filled corner']
hall['evidence'].extend([
    evidence('fill-material','commons/primitives/line/puzzles/triangle_line_puzzle.gd',
             'material.albedo_color = Color(1,0.3,0.6,0.45)',3,'artifact',
             'The puzzle face is translucent and visible from both sides.'),
    evidence('corner-release','commons/primitives/point/draw_triangle_faces.gd',
             'func _on_edit_point_dropped(',14,'artifact',
             'Release stores the snapped corner position and rebuilds lines and faces.')
])
for ev in hall['evidence']:
    if ev['id'] == 'edit':
        ev['note'] = 'The revised final explicitly asks for release before the face rebuilds.'
for ev in hall['evidence']:
    if ev['path']=='commons/maps/Point_Triangle_Context/final.md':
        assert after.count(ev['excerpt'])==1, ev['id']
        ev['start_line'] = after[:after.index(ev['excerpt'])].count('\n')+1
        ev['end_line'] = ev['start_line']+ev['excerpt'].count('\n')

core_raw = CORE.read_bytes()
core = json.loads(core_raw)
assert core['rooms']['Point_Triangle_Context']['text_sha256']==sha(original)
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
save(REPORT/'middle.json',early)
write_like(BUILDER,builder,builder_raw)
from tools import primitives_purpose_view as purpose
audit = purpose.build_audit()
save(REPORT/'audit.json',audit)
purpose.render_report(audit)

OUT.joinpath('Point_Triangle_Context.after.md').write_bytes(new_bytes)
diff = ''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),
                                  fromfile='Point_Triangle_Context.before.md',tofile='Point_Triangle_Context.after.md'))
OUT.joinpath('Point_Triangle_Context.diff').write_text(diff,encoding='utf-8')


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
toc=[('triangle_line_puzzle','Boundary and visible face'),('draw_triangle_faces','Draw and question the fill')]
chunks=[
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point Triangle Context — a face and a viewpoint</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point Triangle Context · 23 September 2026</div>',
 '<h1>A face and a viewpoint.</h1>',
 '<p class="intro">A patch hangs between three corners. As you walk around it, the patch narrows almost to a line. Later, a fill reaches into a place you left open. Five small revisions bring these investigations closer to the reader.</p>',
 '<p class="status">Applied to final.md. The chapter’s structure, L-shaped experiment, code, footnotes and critical ending remain. Checked against current source; no new headset test. Full-book and audio captures remain earlier versions.</p>',
 '<nav><a href="#reading">Read the chapter</a><a href="#changes">Compare five edits</a><a href="Point_Triangle_Context.diff">Exact diff</a><a href="/compose/sources?map=Point_Triangle_Context&amp;doc=final">Read and comment</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_Triangle_Context&amp;view=reading">Text + purpose</a></nav>',
 '<nav class="encounters" aria-label="Encounters in this chapter">'+''.join('<a href="#reading-encounter-'+token+'">'+label+'</a>' for token,label in toc)+'</nav>',
 '<section class="reading" id="reading">'+render(after,'reading-',True)+'</section>',
 '<section id="changes"><h2>Five edits, beside their originals</h2>'
]
for i,e in enumerate(edits,1):
    chunks.append('<section class="change" id="change-'+str(i)+'"><div class="eyebrow">Edit '+str(i)+'</div><h2>'+html.escape(e['title'])+'</h2><p class="reason">'+html.escape(e['incitement'])+'</p><div class="pair"><article><h3>Before</h3>'+render(e['old'],'before-'+str(i)+'-')+'</article><article><h3>Revised</h3>'+render(e['new'],'after-'+str(i)+'-')+'</article></div></section>')
chunks.extend([
 '</section><section class="reading-notes"><h2>What carries the encounter</h2>',
 '<p>The first surface becomes something to look at. The material is translucent; showing and hiding it leaves the same closed boundary. Walking around it then changes the view while the geometry stays fixed.</p>',
 '<p>The drawing instructions now lead with moving to a corner and waiting for its number. Releasing an edited corner is explicitly what commits its new position and rebuilds the faces. In the fan explanation, the first corner is shared by every triangle; it is not the centre of the polygon.</p>',
 '<p>The exact L-shaped comparison stays intact, including its awkward result and possible reuse as a wing or pleat. “A convenient method need not require everyone to want a convenient shape.” The critical question grows from what the construction does.</p>',
 '<p>Headset reach and the ease of drawing the six-corner L remain open observations. The tutorial companion still leads with the older manual two-fill route; aligning that companion is recorded separately. This page and final.md use the installed SHIFT START route.</p>',
 '<p>Next: <a href="/compose/sources?map=Primitives_Polythedra&amp;doc=final">Primitives Polythedra</a>. What can faces enclose, and how does the same form become a slope or a barrier?</p></section>',
 '<footer><a href="SUMMARY.md">Decisions and source checks</a> · <a href="Point_Triangle_Context.before.md">Before this edit</a> · <a href="Point_Triangle_Context.after.md">Complete revised chapter</a> · <a href="../2026-09-23-point-grid-return/index.html#reading">Previous: Grid</a></footer></main></body></html>'
])
OUT.joinpath('index.html').write_text(chr(10).join(chunks),encoding='utf-8')
checks.update(before_sha256=sha(original),after_sha256=new_sha,
              purpose_halls=len(audit['maps']),purpose_paragraphs=audit['total_paragraphs'],
              annotation_blocks=len(new_blocks),new_historical_claims=False,
              scene_or_behavior_changes=False,new_headset_test=False,audiobook_regenerated=False)
save(OUT/'checks.json',checks)
OUT.joinpath('SUMMARY.md').write_text('''# Point Triangle Context: a face and a viewpoint

Five local revisions, applied directly to final.md. The chapter already has an effective investigation: close a boundary, make its face visible, and compare different first-corner fills of one L-shaped outline. That structure and its critical consequences are preserved.

## Decisions

1. Let the face appear before reporting instrument state. The completed boundary stays empty until SHOW / HIDE FILL introduces a translucent patch. Toggling it leaves the edges intact.
2. Describe projection through the visitor's movement: the patch narrows almost to a line while its corners stay fixed, then opens in view when the visitor moves back. Existing footnote retains winding, culling and thickness distinctions. This does not claim that the geometric surface changes dimension.
3. Put movement to a corner and waiting for its number before the sampling explanation. Retain the one-second interval, distance condition and ten-centimetre grid, in the context of held drawing.
4. Correct the corner-edit timing: move, then release the corner to rebuild the faces. The prior wording could imply a continuously following mesh. Resolve that specific text action in the purpose records; mark the revised paragraph grounded and remove its now-satisfied opportunity.
5. Explain the fan through its shared first corner. Avoid suggesting that this boundary vertex is the geometric centre. Preserve the submitted triples and the entire subsequent discussion of overspill, counts, applicability and alternatives.

## Preserved

The opening question, prior-learning connection, delay before the third edge, two separate operations, actual mesh code, non-collinearity, the six-corner L recipe, SHIFT START comparison, triangle list, all three footnotes, secondary artifact availability and the ending. The possibility of reusing an unwanted patch as a wing or pleat remains. Point One, Lines, Trace and Grid remain unchanged.

The important critical sentence is already earned by the experiment: “A convenient method need not require everyone to want a convenient shape.” No theory name or generic political conclusion was added.

## Source correspondence

triangle_line_puzzle.gd creates its fill only after completion. Its pink material has alpha 0.45, alpha transparency and disabled culling. The subsequent toggle changes visibility. The corner coordinates stay fixed during viewing.

draw_triangle_faces.gd commits edited corners in _on_edit_point_dropped: snap the position, store it, rebuild lines and all triangles. Its first-vertex fan uses placed_points[loop_points[0]] with successive pairs. The technical companion records the held timer, distance gate and world-grid pitch; none was changed by this prose edit.

These are source checks. Existing supplied-input runtime evidence for the L is retained; no new runtime, headset, ease-of-use or learner-comprehension test is claimed.

## Records and next

The purpose snapshot, five paragraph notes, resolved release action, source evidence, core text hash and served purpose view are synchronized. All other open actions remain: observing drawing/reach in the assembled hall and aligning the tutorial companion with the current SHIFT START route. The older manual route remains valid but has different totals.

Exact diff, before/after manuscripts and preservation checks accompany the reading page. No scene, map, role or artifact implementation changes. Frozen full-book and audio captures remain unchanged.

Continue with Primitives_Polythedra: faces enclosing volume, and a form whose orientation can make a ramp or barrier. Keep its own particular actions and questions rather than copying this chapter's paragraph structure.
''',encoding='utf-8')
print(json.dumps(checks,indent=2))
