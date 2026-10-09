from pathlib import Path
import difflib, hashlib, html, json, re
import markdown

H = Path(__file__).resolve().parent
R = H.parents[3]
NAMES = ['Color_Context_Placed','Color_Flashlight','Color_Nails','Color_Rainbow','Color_Pillar','Color_Grid_Pallet','Color_Paint','Color_Walls','Chamber_Color']
NOTES = [
'Two literal corrections only: eight pieces need not be eight different shape types, and 6.2 metres is the height of the whole capped column. The richer stacks, artist references and opening voice stay.',
'The RGB tuple now has a readable zero-to-one range. Alpha is named and set aside for the later transparency encounter.',
'The chapter now invites you to raise your own virtual hand in the controller-based VR setup. Choosing a colour includes the body making the choice. Desktop keeps the giant/petite comparison. The chosen colours can travel with the virtual hands during the visit.',
'HSV is introduced before its first formula. The reader can see what stays fixed and what part of the hue circle the sweep visits. The celebration and its generous opening remain.',
'A walk along one line of samples now becomes a worked comparison: hue and value stay fixed while saturation changes. The normalized coordinates and two functions become readable. An unseen older room arrangement is no longer the reference.',
'One pair of available addresses makes the diagonal relation inspectable: (8, 9) and (9, 8) both sum to seventeen. The overwrite, exception and memory passages stay.',
'Canvas coordinates are introduced before the first expression, and Trace is recalled through its actual sampling encounter. The image memory and two clocks remain; a controlled clock comparison is a future artifact task.',
'Preserved without manuscript edits. Preparing HSV earlier lets the models and interpolation work as a return. The distinction between where a view can travel and where a body can go remains central.',
'A sentence responding to an absent bracelet design is replaced by an invitation to look back at what stays. The ending asks the reader to choose a receiver and one condition to change before entering Tiling.'
]
PROTECTED = {
'Color_Context_Placed':['The turns are already over. The movement is yours.','An array has an order. The builder makes that order climb.'],
'Color_Flashlight':['You cannot pick it up separately from the meeting that produces it.'],
'Color_Nails':['Name one choice the box gives you and another it does not.'],
'Color_Rainbow':['Stay a moment with the possibility that the room is pleased you arrived.'],
'Color_Grid_Pallet':['The white outline has travelled. Your exception has not followed it.'],
'Color_Paint':['White enters the work again. It is the direction of forgetting in this particular simulation.'],
'Color_Walls':['Your view took a route your body could not.','The agreement about where to begin and end did not decide how to travel.'],
'Chamber_Color':['A return can reset one part of an encounter while leaving another part altered.']
}
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()

def render(text, prefix):
    text = re.sub(r'<!--\s*@[^>]*-->', '', text)
    out = markdown.markdown(text, extensions=['fenced_code','footnotes','tables'])
    out = re.sub(r'id="([^"]+)"', lambda m: 'id="'+prefix+m[1]+'"', out)
    return re.sub(r'href="#([^"]+)"', lambda m: 'href="#'+prefix+m[1]+'"', out)

def diff(rel):
    old = (H/'before'/rel).read_text(encoding='utf-8')
    now = (R/rel).read_text(encoding='utf-8')
    name = rel.replace('/','__')+'.diff'
    text = ''.join(difflib.unified_diff(old.splitlines(True),now.splitlines(True),fromfile='before/'+rel,tofile='current/'+rel))
    (H/name).write_text(text, encoding='utf-8')
    return old, now, name

baseline = read(H/'baseline.json')
preserved = {rel:digest for rel,digest in baseline.items() if rel.endswith('map_data.json') or rel in ['commons/maps/sequences/color.json','commons/data/artifact_roles.json']}
for source in [H/'late-source-hashes.json', H/'nails/source_hashes.json']:
    preserved.update({rel:digest for rel,digest in read(source).items() if not rel.endswith('/final.md')})
prior = read(R/'doc/book/iterations/2026-09-21-arrays-return/preserved.json')
frozen = 'doc/book/iterations/2026-09-21-full-book/ada-research-full-book.md'
preserved[frozen] = prior[frozen]
preserved['commons/maps/Color_Walls/final.md'] = baseline['commons/maps/Color_Walls/final.md']
for rel,digest in preserved.items():
    assert sha(R/rel) == digest, 'Changed preserved input: '+rel
(H/'preserved.json').write_text(json.dumps(preserved,indent=2)+'\n',encoding='utf-8')
core = read(R/'commons/data/museum_core_encounters.json')
expected = read(H/'before/commons/data/museum_core_encounters.json')
roles = read(R/'commons/data/artifact_roles.json')
probe = read(H/'nails/probe_results.json')
assert len(probe['checks']) == 35 and all(x['pass'] for x in probe['checks']) and not probe['failures']
parts = []; counts = []; changed = []
for name, note in zip(NAMES,NOTES):
    rel = 'commons/maps/'+name+'/final.md'
    old, now, delta = diff(rel)
    assert sha(H/'before'/rel) == baseline[rel], 'Baseline changed'
    markers = lambda t: re.findall(r'<!-- @([A-Za-z_0-9]+) -->', t)
    assert markers(old) == markers(now) == roles['order'][name]['primary'] == core['rooms'][name]['primary_tokens'], 'Encounter order mismatch: '+name
    assert all(q in now for q in PROTECTED.get(name,[])), 'Protected quote missing: '+name
    obj = expected['rooms'][name]
    obj['text_path'] = rel; obj['text_sha256'] = sha(R/rel)
    obj['map_sha256'] = sha(R/'commons/maps'/name/'map_data.json')
    if obj['status'] == 'text_pending': obj['status'] = 'draft'
    is_changed = old != now
    if is_changed: changed.append(name)
    counts.append({'map':name,'before_words':len(old.split()),'after_words':len(now.split()),'changed':is_changed})
    links = '<a href="/compose/sources?map='+name+'&amp;doc=final">Read and comment</a><a href="/long-museum/encounters?map='+name+'">Encounter map</a>'
    if is_changed: links += '<a href="'+delta+'">Exact diff</a>'
    body = '<details><summary>Read the current chapter</summary><div class="reading">'+render(now,name+'-read-')+'</div></details>'
    if is_changed:
        body += '<details><summary>Compare original and current</summary><div class="compare"><article><h3>Original</h3>'+render(old,name+'-old-')+'</article><article><h3>Current</h3>'+render(now,name+'-new-')+'</article></div></details>'
    parts.append('<section id="'+name+'"><h2>'+html.escape(name.replace('_',' '))+'</h2><p>'+html.escape(note)+'</p><nav>'+links+'</nav>'+body+'</section>')
assert core == expected, 'Unexpected core changes outside nine derived Colour records'
assert len(changed) == 8
old_technical,new_technical,technical_diff = diff('commons/maps/Color_Nails/technical.md')
verification = {'scope':'Independent reading of all nine chapters; source checks; isolated Godot player-hand receiver probe. No live museum or headset run.','preserved_files':len(preserved),'protected_passages':sum(map(len,PROTECTED.values())),'encounter_order_preserved':True,'changed_chapters':changed,'supporting_nails_documentation_updated':True,'core_changes':'Nine current manuscript/map references; three stale text_pending records become draft; no role or learner-verified changes','player_hand_checks':len(probe['checks']),'player_hand_failures':probe['failures'],'chapter_counts':counts}
(H/'verification.json').write_text(json.dumps(verification,indent=2)+'\n',encoding='utf-8')
style = (R/'doc/book/iterations/2026-09-21-point-one-return/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style += 'section{margin:48px 0;border-top:1px solid var(--line);padding-top:24px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.pair figure{margin:16px 0}.compare{align-items:start}td,th{text-align:left;vertical-align:top;padding:10px;border-bottom:1px solid var(--line)}table{border-collapse:collapse;width:100%}@media(max-width:760px){.pair{grid-template-columns:1fr}}'
nav = ''.join('<a href="#'+n+'">'+n.replace('Color_Context_Placed','Stacks').replace('Color_','').replace('Chamber_Color','Chamber').replace('_',' ')+'</a>' for n in NAMES)
summary = '''# Colour: the colour reaches your hand

21 September 2026. A proportionate return to a mature nine-hall sequence.

## Method

One fresh reader received only the sequence order and the nine current manuscripts, without author notes, earlier reviews or implementation. A separate verifier checked Context, Flashlight, Rainbow and Pillar. A dedicated verifier traced Nails into the actual player rig and ran a bounded isolated probe. The lead checked the four later halls against their placed implementations and made the editorial decisions. The independent report is retained unchanged; its recommendations are evidence for judgment, not an automatic edit list.

## The important finding: Nails

Both standard VR controller-hand meshes already receive nail and skin colours through their own GameManager subscribers. The station's shallow direct-hand lookup can fail without breaking that path. Thirty-five isolated Godot assertions pass, including selection before hands appear, subsequent independent material changes and replacement hand scenes. No production repair is required for that path.

The chapter now asks the reader to raise their own virtual hand, compare it with the two display scales, and change skin while keeping the nail choice. It keeps the question of which bodily choices the box permits and which it leaves fixed. Desktop retains the giant/petite comparison. Colour survives scene changes in memory; no new promise of automatic persistence after quitting is made.

The probe uses real embedded hand meshes, unchanged receiver/station scripts and a literal colour-method slice from GameManager. XR animation is omitted and mapper input is a signal fixture. It proves wiring and material values, not headset rendering, physical dragging, finger tracking or comfort. Bare-hand skeletal tracking was not established. Read [the full report](nails/verification.md) and [the saved results](nails/probe_results.json).

## Editorial decisions

- Preserve the sequence order and every currently placed artifact. The progression already changes the reader's agency: compare authored choices, move light, dress a body, divide a rainbow, sample a field, write an exception, join a painter, alter visibility, then change a receiver.
- Give RGB its zero-to-one range. Introduce HSV before the first formula; let Pillar supply one worked crossing between walking and code. This is the largest useful beginner repair.
- Give Grid an equal-sum pair that its console can actually select: (8, 9) and (9, 8). Introduce canvas UV addresses before Paint's expression and recall what the reader did in Trace.
- Remove the unseen former-room comparison and the absent bracelet reference. Let Chamber end with the reader's proposed experiment rather than a status report.
- Preserve Walls completely and all ten quoted passages protected by the fresh reader. Keep model-specific scientific limits where they prevent a mistaken inference. Do not mechanically remove every repeated critical return.
- Defer the proposed larger cuts to the opening inventory and Paint's parameter density. The opening's richer stacks were deliberately developed with the author; the concrete examples have value. Paint's two clocks are a real limit with a potential experiment. A later read-aloud or learner pass can decide whether compression helps. This pass adds access to the code without erasing that material.

## What changed

Eight final.md chapters received local edits; Color_Walls is byte-for-byte preserved. Color_Nails/technical.md now records the actual player receiver path, current control cells and the limits of the new test. Nine derived core records now point to their current map and text hashes; Flashlight, Rainbow and Grid no longer incorrectly say text_pending. Primary choices, reasons and learner_verified values are unchanged.

The comparison page contains the baseline and current chapters, exact diffs and links to the commenting view. Baselines were captured before this pass. Prior salon screenshots are dated 19 September; they show the display hands before/after selection, not a new view from a headset or the result of this editorial pass.

## Evidence and next encounter

See [fresh reading](fresh-reader.md), [early source verification](early-source-check.md), [later source verification](late-source-check.md), [Nails verification](nails/verification.md) and [content/preservation checks](verification.json). Existing runtime observations were reused where appropriate and remain dated. No live game, museum bake, visitor save or frozen whole-book export was changed.

The next sequence is Tiling's return after colour: preserve its connection to the monochrome floor, wall and rhythm studies in Arrays, then ask what colour, material and control allow the architecture and the dressed body to do. For Nails, the remaining physical check is short: change each station in the headset, raise both hands, and carry the colour into the next hall. That is still an unperformed wearer check.
'''
(H/'SUMMARY.md').write_text(summary,encoding='utf-8')
page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Colour — the colour reaches your hand</title><style>'''+style+'''</style></head><body><main><div class="eyebrow">Ada Research · Colour reading return · 21 September 2026</div><h1>The colour reaches<br>your hand.</h1><p class="intro">The lamps changed what reached a surface. In the salon, colour can reach the hand you use to choose it.</p><p>An independent fresh reading of all nine chapters, two separate source verifiers and a focused player-hand test. The sequence holds together; this pass gives the beginner a few more ways into its code and makes the body encounter explicit.</p><nav>'''+nav+'''</nav><section id="hand-evidence"><h2>Can you wear the colour?</h2><p><strong>Yes, on the standard VR controller-hand meshes.</strong> Both hands receive the selected nail and skin values. The colour also reaches hands created after the choice and replacement hand scenes. The existing receivers already do this, so no new receiver was needed.</p><blockquote>In VR, raise the hand moving with your controller and turn its nails toward you. Compare them with the petite hand, the giant nails and the swatch. The colour has reached the hand you use to choose it. What seemed like dressing an object now includes the body doing the dressing.</blockquote><table><thead><tr><th>Evidence</th><th>What it establishes</th></tr></thead><tbody><tr><td>Current source and 35 passing Godot checks</td><td>Nail and skin values reach both real hand meshes independently, including late appearance and scene replacement.</td></tr><tr><td>Desktop comparison</td><td>The giant and petite salon hands remain the visible receivers; the desktop pointer is not a nail-bearing player hand.</td></tr><tr><td>Still to experience</td><td>Physical headset interaction, visibility, reach and comfort. The isolated probe supplied a signal fixture, not human controller movement. Bare-hand skeletal tracking was not established.</td></tr></tbody></table><nav><a href="nails/verification.md">Player-hand report</a><a href="nails/probe_results.json">35 probe results</a><a href="SUMMARY.md">Decisions and scope</a></nav><div class="pair"><figure><a href="../2026-09-19-color-review/opening/runtime/nails-before-choice.png"><img src="../2026-09-19-color-review/opening/runtime/nails-before-choice.png" alt="Dated Godot salon view with giant display hand, petite hand and two colour controls"><figcaption>Display hands before the selected colour change.</figcaption></a></figure><figure><a href="../2026-09-19-color-review/opening/runtime/nails-after-choice.png"><img src="../2026-09-19-color-review/opening/runtime/nails-after-choice.png" alt="Dated Godot salon view with the display hand receiving teal skin and magenta nails"><figcaption>Display hands after the selected colour change.</figcaption></a></figure></div><p class="note">Actual Godot captures from 19 September. These are the salon display hands, not the player hands tested today. They show two earlier runtime states, not a spatial change from this manuscript pass.</p></section><section><h2>A value needs somewhere to arrive.</h2><p>The fresh reader found a growing investigation: colour meets light, a bodily surface, a position, an image with memory, and a receiver. The main beginner gap was smaller and specific: HSV appeared in code before the reader knew how to read it. Rainbow now introduces it; Pillar works through one crossing. The scientific and associative directions remain together.</p><nav><a href="fresh-reader.md">Independent reading</a><a href="early-source-check.md">Early source checks</a><a href="late-source-check.md">Later source checks</a><a href="verification.json">Preservation record</a></nav><p>Eight chapters receive local changes. Walls stays intact. The more substantial suggested cuts to the opening and Paint are deferred for an author reading: their particular examples and clocks still do useful work.</p></section>'''+''.join(parts)+'''<section><h2>Next: the patterned room.</h2><p>Arrays supplied monochrome floors, walls and rhythm. Tiling can now return to those operations with colour, material and control: what can a surface let a body do, and what can the body change in the room?</p><nav><a href="/museum-progress?sequence=tiling">Tiling progression</a><a href="../2026-09-21-arrays-return/index.html">Previous Arrays pass</a><a href="'''+technical_diff+'''">Nails supporting-document diff</a></nav></section><p class="note">All nine map files, curated roles, sequence order, tested hand code and the frozen whole-book export are preserved. No new headset or learner validation is claimed. The complete reports distinguish fresh controlled evidence from earlier runtime observations.</p></main></body></html>'''
(H/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'published':str(H/'index.html'),'changed_chapters':len(changed),'preserved_files':len(preserved),'protected_passages':10,'hand_probe_checks':len(probe['checks'])}))
