from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path.cwd()
sys.path.insert(0, str(ROOT))
from tools.book_registers import parse_blocks

OUT = ROOT / 'doc/book/iterations/2026-09-22-point-one-arrival'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-22-point-one-body-and-address'
REPORT = ROOT / 'doc/reports/primitives-purpose-2026-09-21'
MANUSCRIPT = ROOT / 'commons/maps/Point_One/final.md'
BUILDER = ROOT / 'tools/primitives_purpose_view.py'
CORE = ROOT / 'commons/data/museum_core_encounters.json'
OLD_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-one-body.json'
NEW_SNAPSHOT = REPORT / 'annotations-2026-09-22-point-one-arrival.json'
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
assert sha(original) == '723e11c17268219f8b5249344ecdec3ac2fd66978315e0574d4c7f13badf0a0b', 'Manuscript changed; reread before applying'
before = original.decode('utf-8').replace('\r\n','\n')
after = before
edits = load(OUT/'changes.json')['edits']
for e in edits:
    assert after.count(e['old']) == 1, e['title']
    after = after.replace(e['old'],e['new'],1)
start = '<!-- @drag_point_target -->'
end = '<!-- @ -->'
fence = chr(96)*3
checks = {
    'all_four_edits_applied': all(after.count(e['new']) == 1 for e in edits),
    'all_earlier_passages_unchanged': before.split(start)[0] == after.split(start)[0],
    'closing_and_footnotes_unchanged': before.split(end)[1] == after.split(end)[1],
    'artifact_markers_unchanged': re.findall(r'<!--\s*@.*?-->',before) == re.findall(r'<!--\s*@.*?-->',after),
    'all_code_blocks_unchanged': re.findall(fence+r'.*?'+fence,before,re.S) == re.findall(fence+r'.*?'+fence,after,re.S),
    'all_footnote_definitions_unchanged': re.findall(r'^\[\^.+',before,re.M) == re.findall(r'^\[\^.+',after,re.M),
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
snapshot['note'] = 'Current ten-hall reading snapshot. Four Point One arrival paragraphs revised locally; unchanged annotations retained by block identity. No remote classification. Frozen book and audio captures remain unchanged.'

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
 evidence('arrival-repeat','commons/artifacts/drag_point_target/drag_point_target.gd','if near and not _inside:',9,'artifact','The inside flag separates staying from entering. The accepted entry calls _drop; leaving clears _inside.'),
 evidence('arrival-rearm-default','commons/artifacts/drag_point_target/drag_point_target.gd','@export var rearm: bool = true',1,'artifact','Repeated entries are enabled by default; the Point One placement supplies no override.'),
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
style += 'html{scroll-behavior:smooth}.encounters{max-width:760px;margin:20px auto;font:14px/1.6 system-ui,sans-serif}.reading a[id]{scroll-margin-top:24px}.reading-notes{max-width:760px;margin:40px auto}.reading-notes li{margin-bottom:14px}'
toc=[('frame_counter_display','Counter'),('folding_past','Folding past'),('origin','Origin'),('the_invisible_point','Invisible point'),('code_evolution_screen','Code screen'),('interactive_point_origin_force','The held point'),('coordinate_readout','Readouts'),('CoordinateSystem3M','Reference frame'),('drag_point_target','Arrival')]
notes=[
 ('A beginning already underway','The running counter, borrowed work, fog and rabbit give the opening a pressure of time. The shift to origin offers a place to begin without pretending to recover a first beginning. That passage is preserved.'),
 ('The point keeps acquiring possibilities','The empty case and separate code example prepare the held body. A surface, a way to grasp it, and two reported addresses become distinct additions. The earlier revisions now read as one developing encounter.'),
 ('A precise report can remain partial','Rounding and named reference frames give the critical questions a specific operation. The giants and fog remain an opening association; no equivalence between LOCAL and confusion has been added.'),
 ('Arrival becomes available for play','The final rule admits a region and keeps a small memory of entry. Repeated arrivals can have a rhythm that the distance test does not describe. The paragraph retains the question of recording the journey.'),
 ('The next connection','The ending is unchanged. Point Lines begins with two positions and a connection; later, its endpoint calculation shows why that connection does not preserve a detour. This is a useful continuation of “how did it get there?”, rather than a promise that the next line will answer it completely.')
]
chunks=[
 '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Point One — a hand has room to arrive</title><style>'+style+'</style></head><body><main>',
 '<div class="eyebrow">Ada Research · Point One · completed close-edit pass · 22 September 2026</div>',
 '<h1>A hand has room to arrive.</h1>',
 '<p class="intro">The whole Point One chapter, with four small refinements to the arrival encounter. Read it continuously, or jump to the last encounter and its before-and-after comparison.</p>',
 '<p class="status">Applied to the current chapter. All earlier passages, code, footnotes and the closing bridge are preserved. This page gathers the complete chapter; the larger book export and audiobook remain earlier captures.</p>',
 '<nav><a href="#reading">Read all of Point One</a><a href="#reading-encounter-drag_point_target">Jump to arrival</a><a href="#changes">Compare four edits</a><a href="#read-through">Reading the chapter as a whole</a><a href="Point_One.diff">Exact diff</a><a href="/compose/sources?map=Point_One&amp;doc=final">Read and comment</a><a href="/research/possible-bodies/primitives-purpose.html?map=Point_One&amp;view=reading">Text + purpose</a></nav>',
 '<nav class="encounters" aria-label="Encounters in this chapter">'+''.join('<a href="#reading-encounter-'+token+'">'+label+'</a>' for token,label in toc)+'</nav>',
 '<section class="reading" id="reading">'+render(after,'reading-',True)+'</section>',
 '<section id="changes"><h2>What changed, and what prompted it</h2>'
]
for i,e in enumerate(edits,1):
    chunks.append('<section class="change" id="change-'+str(i)+'"><div class="eyebrow">Edit '+str(i)+'</div><h2>'+html.escape(e['title'])+'</h2><p class="reason">'+html.escape(e['incitement'])+'</p><div class="pair"><article><h3>Before</h3>'+render(e['old'],'before-'+str(i)+'-')+'</article><article><h3>Revised</h3>'+render(e['new'],'after-'+str(i)+'-')+'</article></div></section>')
chunks.extend([
 '</section><section class="reading-notes" id="read-through"><h2>Reading Point One as a whole</h2><p>The chapter has a continuous investigation: arriving, locating, holding, reporting, then using a location as a request. These are editorial judgments from reading the current manuscript alongside the next chapter, not observations of a new headset session.</p>',
 '<ul>'+''.join('<li><strong>'+html.escape(title)+'.</strong> '+html.escape(body)+'</li>' for title,body in notes)+'</ul>',
 '<p>The density worth listening for is the opening counter-and-history passage. It is deliberate, and no further shortening has been applied. The next close edit can start with <a href="/compose/sources?map=Point_Lines&amp;doc=final">Point Lines: the connection and the barrier</a>.</p></section>',
 '<details><summary>Read the earlier arrival passage</summary><div class="reading">'+render(segment(before),'previous-')+'</div></details>',
 '<footer><a href="SUMMARY.md">Decisions and source checks</a> · <a href="Point_One.before.md">Before this edit</a> · <a href="Point_One.after.md">Complete revised chapter</a> · <a href="../2026-09-22-point-one-body-and-address/index.html">Previous edit</a></footer></main></body></html>'
])
OUT.joinpath('index.html').write_text('\n'.join(chunks),encoding='utf-8')
checks.update(before_sha256=sha(original),after_sha256=new_sha,
              purpose_halls=len(audit['maps']),purpose_paragraphs=audit['total_paragraphs'],
              annotation_blocks=len(new_blocks),new_historical_claims=False,
              scene_or_behavior_changes=False,new_headset_test=False,
              audiobook_regenerated=False)
save(OUT/'checks.json',checks)
summary = """# Point One: arrival and continuous reading

Four local paragraph edits finish this close-edit pass of Point One. The full chapter is rendered continuously in index.html, with encounter links and the four original/revised pairs.

## Changes

1. Invite carrying the point to the target without requiring release. Repetition is developed later rather than prescribed twice in the opening.
2. Explain distance_to() and the inclusive comparison, then return to the bodily meaning: a hand has room to arrive.
3. Replace registry-group and rearming vocabulary with the small entry memory and its observable consequence. Intention remains outside the comparison.
4. Give the destination-as-instrument idea a concrete action: a direct return and a longer route change the pause between arrivals. Preserve the question of adding a record of the journey.

## Continuous reading

The chapter's movement holds: a visitor arrives in an already running room; an origin supplies a reference; an undrawn point can be located; another position gains a body; that body has several reports; a destination admits arrivals and can be used rhythmically.

Preserve the author's borrowing paragraph, the giants and fog, the rabbit, the invisible point and the questions around what draws a hand. WORLD and LOCAL remain named technical references, with room for the earlier image to resonate without being equated to clarity and confusion.

The opening is relatively dense because it introduces the clock, the code supporting its appearance and a historical room. That is a pacing question for the next reading/listening session, not a reason for another unsolicited shortening.

The close is unchanged. “How did it get there?” carries into Point Lines: a relation between endpoints can be calculated and made visible, while the detour still requires a further record. Point_Lines/final.md was read for this transition and was not edited.

## Source checks

drag_point_target.gd: catch_radius 0.45, catch_height 1.20, rearm true. The Point One token has no overrides for these values. _check reads the point's global position, accepts the distance, records _inside and calls _drop on entry; leaving clears the flag. Release and intention are not inputs. _drop creates falling rigid-body spheres.

The entry flag is a small memory of whether an eligible point is already inside. It is not a stored trajectory. The prose keeps those two meanings of memory distinct.

No new scene, map, interaction or runtime claim is introduced. No new headset session, listener test or audio generation was performed. Existing code and footnotes are unchanged.

## Reading records

Current Point One text hash and purpose notes are synchronized through a new derived ten-hall snapshot. Old annotations and earlier comparison captures remain intact. The canonical chapter and this page are current; the larger frozen full-book export and audiobook remain earlier captures.

See Point_One.diff for the exact prose changes, changes.json for the reason for each edit, and checks.json for preservation checks.
"""
OUT.joinpath('SUMMARY.md').write_text(summary,encoding='utf-8')
print(json.dumps(checks,indent=2))

