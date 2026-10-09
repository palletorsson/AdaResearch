from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-22-point-lines-walk-and-trace'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-22-point-lines-connection'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_Lines/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-lines-connection.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-lines-walk.json'
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
assert sha(original) == '1a433f62bcee11556cd4ece40731e067377feee70233ce8adbf7750e8e9553f2', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @walk_this_line_marking -->'
end = '<!-- @ -->'
fence = chr(96)*3
checks = {
    'all_four_edits_applied': all(after.count(e['new']) == 1 for e in edits),
    'connection_barrier_measurement_unchanged': before.split(start)[0] == after.split(start)[0],
    'closing_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
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
snapshot['note'] = 'Current ten-hall reading snapshot. Four Point Lines walk-and-trace paragraphs revised locally; unchanged annotations retained by block identity. No remote classification. Frozen book and audio captures remain unchanged.'

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
hall['evidence'].append(evidence('trace-drawing','commons/primitives/point/player_trace.gd','func _rebuild_trail() -> void:',28,'artifact','Stored positions become a line strip: each pair of neighbouring samples is joined by a straight segment.'))
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
    if not encounters:
        names = re.findall(r'^\[\^([^\]]+)\]:',after,re.M)
        rendered = re.sub(r'\[\^([^\]]+)\]',lambda m: '<sup><a href="#reading-fn:'+m[1]+'">'+str(names.index(m[1])+1)+'</a></sup>',rendered)
    return rendered
style = re.search(r'<style>(.*?)</style>',PREVIOUS.joinpath('index.html').read_text(encoding='utf-8'),re.S)[1]
toc=[('line_demo','Connection'),('do_not_cross_barrier','Barrier'),('line','Measurement'),('walk_this_line_marking','Walk this line'),('player_trace','Trace')]
chunks=[
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point Lines — a line to move with</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point Lines · walk and trace · 22 September 2026</div>',
 '<h1>A line to move with.</h1>',
 '<p class="intro">A straight marking waits for a walk. Another line takes shape as the visitor moves. Four small edits make this encounter more concrete while leaving its meaning open.</p>',
 '<p class="status">Applied to the current chapter. The earlier connection and measurement passages, all code, footnotes and the closing remain intact. Source correspondence was checked; no new headset test was performed. The full-book export and audiobook remain earlier captures.</p>',
 '<nav><a href="#reading-encounter-walk_this_line_marking">Read the revised encounter</a><a href="#reading">Read the whole chapter</a><a href="#changes">Compare four edits</a><a href="Point_Lines.diff">Exact diff</a><a href="/compose/sources?map=Point_Lines&amp;doc=final">Read and comment</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_Lines&amp;view=reading">Text + purpose</a></nav>',
 '<nav class="encounters" aria-label="Encounters in this chapter">'+''.join('<a href="#reading-encounter-'+token+'">'+label+'</a>' for token,label in toc)+'</nav>',
 '<section class="reading" id="reading">'+render(after,'reading-',True)+'</section>',
 '<section id="changes"><h2>Four edits, beside their originals</h2>'
]
for i,e in enumerate(edits,1):
    chunks.append('<section class="change" id="change-'+str(i)+'"><div class="eyebrow">Edit '+str(i)+'</div><h2>'+html.escape(e['title'])+'</h2><p class="reason">'+html.escape(e['incitement'])+'</p><div class="pair"><article><h3>Before</h3>'+render(e['old'],'before-'+str(i)+'-')+'</article><article><h3>Revised</h3>'+render(e['new'],'after-'+str(i)+'-')+'</article></div></section>')
chunks.extend([
 '</section><section class="reading-notes"><h2>What this encounter can carry</h2>',
 '<p>The stripe offers a direction, and its words can prompt a correction without a score being calculated. Its steadiness can also become useful for dancing. The text asks the reader to notice how the instruction was taken up.</p>',
 '<p>The trace makes movement available to compare with that instruction. Following the headset has a bodily consequence: leaning may change the line while the feet stay still. The reader has something specific to investigate about what the drawing records.</p>',
 '<p>The endpoint calculation and the final invitation to bring the detour are preserved. They lead into <a href="/compose/sources?map=Point_Trace&amp;doc=final">Point Trace</a>, where the reader can hold a drawing point, watch the count, and discover how a journey becomes an ordered set of positions.</p></section>',
 '<footer><a href="SUMMARY.md">Decisions and source checks</a> · <a href="Point_Lines.before.md">Before this edit</a> · <a href="Point_Lines.after.md">Complete revised chapter</a> · <a href="../2026-09-22-point-lines-connection/index.html#reading">Previous edit</a></footer></main></body></html>'
])
OUT.joinpath('index.html').write_text(chr(10).join(chunks),encoding='utf-8')
checks.update(before_sha256=sha(original),after_sha256=new_sha,
              purpose_halls=len(audit['maps']),purpose_paragraphs=audit['total_paragraphs'],
              annotation_blocks=len(new_blocks),new_historical_claims=False,
              scene_or_behavior_changes=False,new_headset_test=False,audiobook_regenerated=False)
save(OUT/'checks.json',checks)
summary="""# Point Lines: a line to move with

Four local paragraph edits continue the close reading from connection and measurement into Walk this line and the player trace.

## Decisions

1. Replace an abstract phrase about varying a relation with a visible comparison: the stripe stays straight through different journeys.
2. Locate the effect of the instruction in a possible correction of a step. The artifact draws words and geometry; it does not score compliance. Keep the possibility of dancing available to this reader.
3. Invite inspection of where stripe and trace part company. Remove the guarantee that a particular sideways step was recorded. The authored stripe and the trace have different histories: one waits, the other takes shape during movement.
4. Give the tracking mechanism a bodily consequence. In VR the recorder takes horizontal coordinates from the headset and retains the rig's floor-level height (plus a small drawing offset). A lean can therefore affect the line while the feet stay still. The script samples positions and connects accepted points with straight segments.

The source supports these possible actions; no new headset experience is claimed. Movement below the recording threshold need not add a point. The new wording does not promise a visible record of every footstep, lean or small motion.

## Kept

The preceding connection, barrier and measurement edits; the glass-supported basin; the question of what following means to a body; the comparison between journeys sharing endpoints; all code and footnote definitions; the closing question and “Bring the detour.” Point One and Point Trace are unchanged.

The earlier critical.md describes a different grid-focused route and makes stronger general claims about straightness. Those claims were not imported. The present hall can invite pleasure, guidance, correction and deviation without assigning one moral meaning to each shape. Existing Ahmed references stay in the footnotes; no new historical attribution was added.

## Source checks

- walk_this_line_marking.gd constructs the stripe and lettering. It contains no walk-scoring loop. The current map supplies the black paint and glass basin.
- player_trace.gd: _tracked_position uses the headset's X and Z in VR and the walker position on desktop. Accepted positions pass a movement gate, enter the retained list and are drawn as a line strip by _rebuild_trail.
- player_trace.tscn sets the movement threshold to 0.01 m and retains up to 1024 points without time fading. This pass does not explain every setting; Point Trace takes up the question of what is kept.

No scene, map, script behavior or artifact role changes. No new Godot or headset run. The current manuscript hash and purpose notes are synchronized. Full-book and audio captures remain frozen.

## Next

Point Trace: stay with the held drawing point, its count and its sampled curve. Read the existing opening before changing it; it already gives the reader a concrete pause-and-move comparison. Do not introduce another generic account of loss where the artifact offers a particular choice of resolution.

See changes.json for each paragraph's incitement, Point_Lines.diff for the exact changes, and checks.json for preservation checks.
"""
OUT.joinpath('SUMMARY.md').write_text(summary,encoding='utf-8')
print(json.dumps(checks,indent=2))
