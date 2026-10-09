from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-22-point-one-origin-and-absence'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-22-point-one-borrowed-time'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_One/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-one.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-one-origin.json'
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
assert sha(original) == 'd5d9831185278db89bdaa90edb7c94742b14fd4d61bc8d2f22ebed2f7c3b1376', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @origin -->'
end = '<!-- @interactive_point_origin_force -->'
fence = chr(96)*3
checks = {
    'all_seven_edits_applied': all(e['new'] in after and e['old'] not in after for e in edits),
    'counter_folding_borrowing_unchanged': before.split(start)[0] == after.split(start)[0],
    'hands_readouts_arrival_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
    'artifact_markers_unchanged': re.findall(r'<!--\s*@.*?-->',before) == re.findall(r'<!--\s*@.*?-->',after),
    'all_code_blocks_unchanged': re.findall(fence+r'.*?'+fence,before,re.S) == re.findall(fence+r'.*?'+fence,after,re.S),
    'all_footnote_definitions_unchanged': re.findall(r'^\[\^.+',before,re.M) == re.findall(r'^\[\^.+',after,re.M),
    'invisible_point_has_no_reveal': 'What they locate is never drawn. There is no hidden mesh waiting to appear.' in after,
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
snapshot['note'] = 'Current ten-hall reading snapshot. Seven Point One paragraphs revised locally; unchanged annotations retained by block identity. No remote classification. Frozen book and audio captures remain unchanged.'

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
 evidence('origin-appearance','commons/primitives/origin/origin.gd','const DEFAULT_BODY :=',2,'artifact','Default body and glow colours; the Point One placement supplies no colour override.'),
 evidence('origin-placement','commons/maps/Point_One/map_data.json','origin:0:0#plinth',1,'placement','Installed origin token and configuration.'),
 evidence('marker-stages','commons/maps/Point_One/evolution.json','"title": "Something to find"',5,'artifact','Displayed illustrative code adds a SphereMesh at point_position.'),
 evidence('visibility-example','commons/maps/Point_One/evolution.json','"title": "Hide the surface"',5,'artifact','The excerpt accumulates elapsed time and switches marker visibility on alternating two-second intervals. It is displayed rather than executed.'),
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
# Preserve the authored crossed-out 'you' in the live purpose reader.
old_pattern = r'|\*([^*\n]+)\*/g'
new_pattern = r'|\*([^*\n]+)\*|~~([^~\n]+)~~/g'
assert builder.count(old_pattern)==1
builder = builder.replace(old_pattern,new_pattern,1)
old_node = "const n=el(hit[5]!==undefined||hit[6]!==undefined?'strong':'em');inline(n,hit[5]??hit[6]??hit[7],m,depth+1)"
new_node = "const n=el(hit[8]!==undefined?'del':hit[5]!==undefined||hit[6]!==undefined?'strong':'em');inline(n,hit[8]??hit[5]??hit[6]??hit[7],m,depth+1)"
assert builder.count(old_node)==1
builder = builder.replace(old_node,new_node,1)

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
    return rendered
style = re.search(r'<style>(.*?)</style>',PREVIOUS.joinpath('index.html').read_text(encoding='utf-8'),re.S)[1]
chunks = [
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point One — origin and absence</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point One · close edit · 22 September 2026</div>',
 '<h1>A place without a body.</h1>',
 '<p class="intro">Origin, invisible point and code screen. The next part of Point One, revised through what each artifact lets us find, read and question.</p>',
 '<p class="status">Applied to the current chapter. Seven paragraph edits. The opening, borrowing passage, rabbit, code and footnotes are preserved. From the grabbable point onward, the text is unchanged. These are source checks and editorial readings; no new headset observation is claimed.</p>',
 '<nav><a href="#reading">Read the revised passage</a><a href="#changes">Compare seven edits</a><a href="Point_One.diff">Exact diff</a><a href="/compose/sources?map=Point_One&amp;doc=final">Read and comment on the chapter</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_One&amp;view=reading">Text + purpose</a><a href="../2026-09-22-point-one-borrowed-time/index.html#reading">Previous passage</a></nav>',
 '<section class="reading" id="reading">'+render(segment(after)+'\n\n'+relevant_notes(segment(after)),'reading-')+'</section>',
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
summary = """# Point One: origin, invisible point, code screen

Seven local paragraph edits are applied to commons/maps/Point_One/final.md.

The origin now has a findable appearance, and Vector3.ZERO is read as three zero components. Choosing a reference becomes a question the numbers alone cannot settle. The struck-through visitor remains as written.

The invisible point keeps the existing locating exercise and its pause. The source gives us another direction of reading: the position comes first, then the arrows are arranged around it. Nothing is revealed at the centre.

The code screen presents a separate marker. Its prose now distinguishes displaying code from executing it before following the additions. The previously unused delta returns in a specific two-second visibility example, without movement of the marker's centre.

## Material checks

- Origin script: near-black body, pink glow; scene includes CubeLines. The map token contains no colour override.
- Invisible-point script: FOCUS is declared before the geometry is constructed; arrows aim at it, two thin cylinders cross there; no marker is created.
- evolution.json: separate illustrative sphere, material and label; elapsed time selects alternating two-second visibility intervals.
- Code-screen script: stage presentation and PLAY advance excerpts.
- These establish source correspondence, not a new observation of VR comfort, readability or runtime appearance.

## Preserved

The entire earlier opening, including the author's borrowing paragraph, rabbit and Sutherland reference. All code blocks, artifact markers and footnotes. The text from interactive_point_origin_force onward. All scenes, maps and interactions.

## Reading infrastructure

The current manuscript hash, Point One purpose notes and derived ten-hall snapshot are synchronized. Unchanged annotations are carried by identity. The purpose reader now renders the authored struck-through 'you' as a deletion instead of literal Markdown. Original frozen annotations, earlier review captures, full-book export and audiobook are unchanged.

Point_One.diff is the exact prose diff. changes.json records the reason and purpose for every edit.
"""
OUT.joinpath('SUMMARY.md').write_text(summary,encoding='utf-8')
print(json.dumps(checks,indent=2))

