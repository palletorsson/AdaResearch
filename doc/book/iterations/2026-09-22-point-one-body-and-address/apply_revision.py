from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-22-point-one-body-and-address'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-22-point-one-origin-and-absence'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_One/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-one-origin.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-one-body.json'
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
assert sha(original) == '38408e9e26793aba7a40579d74376c233704a966c57f09b5c31fbec5784af162', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @interactive_point_origin_force -->'
end = '<!-- @drag_point_target -->'
fence = chr(96)*3
checks = {
    'all_five_edits_applied': all(after.count(e['new']) == 1 for e in edits),
    'earlier_passages_unchanged_except_requested_fog': before.split(start)[0].replace(edits[0]['old'],edits[0]['new']) == after.split(start)[0],
    'arrival_close_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
    'artifact_markers_unchanged': re.findall(r'<!--\s*@.*?-->',before) == re.findall(r'<!--\s*@.*?-->',after),
    'all_code_blocks_unchanged': re.findall(fence+r'.*?'+fence,before,re.S) == re.findall(fence+r'.*?'+fence,after,re.S),
    'all_footnote_definitions_unchanged': re.findall(r'^\[\^.+',before,re.M) == re.findall(r'^\[\^.+',after,re.M),
    'fog_is_explicitly_a_comparison': 'It is like standing on the shoulders of giants in fog:' in after,
}
assert all(checks.values()), checks
for p in [MANUSCRIPT,BUILDER,CORE,OLD_SNAPSHOT,REPORT/'early.json',REPORT/'audit.json',PURPOSE]:
    backup(p)
OUT.joinpath('Point_One.before.md').write_bytes(original)
new_bytes = after.replace('\n','\r\n' if b'\r\n' in original else '\n').encode('utf-8')
new_sha = sha(new_bytes)

snapshot = load(OLD_SNAPSHOT)
source = next(s for s in snapshot['sources'] if s['map']=='Point_One')
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
snapshot['note'] = 'Current ten-hall reading snapshot. Five Point One paragraphs revised locally; unchanged annotations retained by block identity. No remote classification. Frozen book and audio captures remain unchanged.'

early = load(REPORT/'early.json')
hall = next(h for h in early['maps'] if h['map']=='Point_One')
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
 evidence('pickup-labels','commons/primitives/point/interactive_point_origin.gd','match _display_format_index:',12,'artifact','Four formats; the fourth hides the coordinate label. The pickup handler advances this index.'),
 evidence('pickup-morph','commons/primitives/point/interactive_point_origin_force.gd','_morph_target = 1.0 if _is_held else 0.0',5,'artifact','Held state changes the shader morph value, using delta.'),
 evidence('pickable-body','commons/primitives/point/interactive_point_origin_force.tscn','[gd_scene load_steps=6 format=3]',53,'artifact','The installed scene inherits XRTools pickable behavior and contains a sphere collision shape and visual mesh.'),
 evidence('reference-pair','algorithms/vectors/00_coordinates/CoordinateSystem3M.gd','var world_p: Vector3 = pt.global_position',21,'artifact','The shared point is reported in world or frame-local coordinates according to the receiving card.'),
])
for ev in hall['evidence']:
    if ev['path']=='commons/maps/Point_One/final.md':
        assert after.count(ev['excerpt'])==1, ev['id']
        ev['start_line'] = after[:after.index(ev['excerpt'])].count('\n')+1
        ev['end_line'] = ev['start_line']+ev['excerpt'].count('\n')

core_raw = CORE.read_bytes()
core = json.loads(core_raw)
assert core['rooms']['Point_One']['text_sha256']==sha(original)
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

OUT.joinpath('Point_One.after.md').write_bytes(new_bytes)
diff = ''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),
                                  fromfile='Point_One.before.md',tofile='Point_One.after.md'))
OUT.joinpath('Point_One.diff').write_text(diff,encoding='utf-8')

def segment(text):
    return text[text.index(start):text.index(end)].strip()
def relevant_notes(text):
    refs = set(re.findall(r'\[\^([^\]]+)\]',text))
    return '\n\n'.join(line for line in after.splitlines()
                       if any(line.startswith('[^'+r+']:') for r in refs))
def render(text,prefix):
    text = re.sub(r'<!--\s*@.*?-->\s*','',text)
    text = text.replace('~~you~~','<del>you</del>')
    rendered = markdown.markdown(text,extensions=['fenced_code','footnotes'])
    rendered = re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',rendered)
    rendered = re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',rendered)
    footnote_numbers = {'point-one-euclid':'1','point-one-haraway':'2'}
    rendered = re.sub(r'\[\^([^\]]+)\]', lambda m: '<sup><a href="#reading-fn:'+m[1]+'">'+footnote_numbers.get(m[1],m[1])+'</a></sup>', rendered)
    return rendered
style = re.search(r'<style>(.*?)</style>',PREVIOUS.joinpath('index.html').read_text(encoding='utf-8'),re.S)[1]
chunks = [
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point One — a body and an address</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point One · close edit · 22 September 2026</div>',
 '<h1>A body and an address.</h1>',
 '<p class="intro">A hand can carry more than an address reports. This pass follows the grabbable point into its two coordinate readouts, and adds Palle’s image of shoulders and fog to the earlier encounter with the counter.</p>',
 '<p class="status">Applied to the current chapter. Five paragraph edits. The author’s borrowing paragraph, the rabbit, all code and footnotes are preserved. The arrival target and ending are unchanged. These are source checks and editorial readings; no new headset observation is claimed.</p>',
 '<nav><a href="#reading">Read the revised passages</a><a href="#changes">Compare five edits</a><a href="Point_One.diff">Exact diff</a><a href="/compose/sources?map=Point_One&amp;doc=final">Read and comment on the chapter</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_One&amp;view=reading">Text + purpose</a><a href="../2026-09-22-point-one-origin-and-absence/index.html#reading">Previous passage</a></nav>',
 '<section class="reading" id="reading"><h2>After reading the counter</h2>'+render(edits[0]['new'],'fog-')+'<h2>Continue with the point in your hand</h2>'+render(segment(after)+'\n\n'+relevant_notes(segment(after)),'reading-')+'</section>',
 '<section id="changes"><h2>What changed, and what prompted it</h2>'
]
for i,e in enumerate(edits,1):
    chunks.append('<section class="change" id="change-'+str(i)+'"><div class="eyebrow">Edit '+str(i)+'</div><h2>'+html.escape(e['title'])+'</h2><p class="reason">'+html.escape(e['incitement'])+'</p><div class="pair"><article><h3>Before</h3>'+render(e['old'],'before-'+str(i)+'-')+'</article><article><h3>Revised</h3>'+render(e['new'],'after-'+str(i)+'-')+'</article></div></section>')
chunks.extend([
 '</section><details><summary>Read the complete earlier passage</summary><div class="reading">'+render(segment(before)+'\n\n'+relevant_notes(segment(before)),'previous-')+'</div></details>',
 '<footer>The comparison is a frozen record of this edit. The full-book export and audiobook retain their earlier captures. <a href="SUMMARY.md">Decisions and source checks</a> · <a href="Point_One.before.md">Before</a> · <a href="Point_One.after.md">After</a></footer></main></body></html>'
])
OUT.joinpath('index.html').write_text('\n'.join(chunks),encoding='utf-8')
checks.update(before_sha256=sha(original),after_sha256=new_sha,
              purpose_halls=len(audit['maps']),purpose_paragraphs=audit['total_paragraphs'],
              annotation_blocks=len(new_blocks),new_historical_claims=False,
              scene_or_behavior_changes=False,new_headset_test=False,
              audiobook_regenerated=False)
save(OUT/'checks.json',checks)
summary = """# Point One: a body and an address

Five local paragraph edits are applied to commons/maps/Point_One/final.md.

## The opening image

Palle described borrowing as standing on the shoulders of giants in fog. The image now follows the counter's code example, where one operation has become readable while much of its supporting machinery remains unopened. It describes inherited support without a clear view; it does not describe literal fog in the scene or promise eventual total transparency. No historical attribution is asserted.

The author's preferred borrowing paragraph remains exact.

## The next encounters

The pickup invites a repeat, so the label's changing format can be noticed through action. The distinction between a visible sphere and a grabbable artifact is explained through their different requirements.

The rounding paragraph now gives a numerical example: 1.231 and 1.234 both print as 1.23. The stored position is not changed by formatting. This explains how a moving point can share a printed address with its previous position, without treating lower display precision as inherently bad.

WORLD is explicitly tied to the scene's coordinate system before comparison with the coloured frame's LOCAL reference. The existing questions about desire, what three numbers cannot contain, an unnamed reference and the finite drawn axes remain intact.

## Material checks

- Pickup base: each pickup advances the four label formats; the fourth hides the label.
- Force variant: held state changes the morph target and shader parameter.
- Scene: XRTools pickable, visual mesh and sphere collision shape.
- Readout: %.2f formats each component; formatting does not assign a new position.
- Coordinate frame: to_local converts the shared point's global position; each card receives its configured WORLD or LOCAL reading.
- These are source correspondences, not new observations of headset legibility or comfort.

## Preserved and synchronized

All code, artifact anchors and footnotes. Previous prose except the explicitly requested fog addition. Arrival target and chapter ending. All maps, scenes and behavior.

The manuscript hash and current purpose notes are synchronized through a new derived ten-hall snapshot. Original frozen annotations, previous comparison captures, full-book export and audiobook are unchanged.

Point_One.diff is the exact prose diff. changes.json records the reason and purpose for every edit.
"""
OUT.joinpath('SUMMARY.md').write_text(summary,encoding='utf-8')
print(json.dumps(checks,indent=2))

