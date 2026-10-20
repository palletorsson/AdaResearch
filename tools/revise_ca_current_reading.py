"""Apply a bounded prose pass, preserving all printed programs and route IDs."""
from pathlib import Path
import hashlib, json, re, shutil, difflib

R = Path(__file__).resolve().parents[1]
O = R/'doc/book/iterations/2026-10-10-ca-current-pass'
SEQ = R/'commons/maps/sequences/cellularautomata.json'
order = json.loads(SEQ.read_text(encoding='utf-8-sig'))['sequences']['cellularautomata']['maps']

def read(p): return p.read_text(encoding='utf-8-sig')
def write(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(s,encoding='utf-8',newline='\n')
def blocks(s): return re.findall(r'```gdscript\n(.*?)\n```',s,re.S)
def replace(s,a,b):
    assert s.count(a)==1,a[:150]
    return s.replace(a,b)

assert not (O/'before').exists(), 'One-shot revision: preserve its first baseline.'
for h in order:
    for t in ['tutorial','final']:
        p=R/'commons/maps'/h/(t+'.md'); d=O/'before'/h/p.name
        d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,d)
shutil.copy2(SEQ,O/'before/cellularautomata.json')

focus = [
    ('Read `answer`, `evolve` and `remember`: one local answer, one simultaneous update, one copied record.', 'Choose another pair of seed addresses, away from the pair already tried. Predict their first combined row and test it. Keep the boundary and rule fixed.'),
    ('Read `next_state` before `active_neighbours` and `evolve`. The new idea is a state that remains visible but no longer contributes to the active count.', 'Choose a different small seed wholly inside the outer shell. Follow one nominated address for two steps. Record its state and active-neighbour count separately.'),
    ('Read `step`, `select_row`, `deck_position` and `screen_position`. The update is carried; the new work is keeping a record and giving it two receivers.', 'Choose another screen mapping while keeping the deck and saved rows unchanged. Check both an occupied and an empty recorded site, then append a row to confirm the calculation still agrees.'),
    ('Read `neighbours`, `next_state` and `receive`. First understand the two-dimensional rule; then follow the separate connection from one address to the lamp.', 'Choose a different seed and a different lamp address. Predict a short sequence of lamp states, then compare it with the stored cells while LINK is on and off.'),
    ('First read `input_position` and the proximity branch of `evolve`. Make one patch lose and regain support. Then return to the same function for the SYNC/SCAN comparison.', 'Choose a different held-point path with at least one pause and one withdrawal. Predict one address that will lose health and another that will remain supported; compare their values after equal numbers of steps.'),
    ('Read `Field.laplacian` and `next_pair`, then `plant` in the host. The new question is what exchange contributes when the local reaction is held fixed.', 'Choose an untouched address beside a seed of your own. Calculate its first U/V pair with exchange on and off before stepping. Keep both beginnings identical.'),
    ('Read `next_row`, then inspect the inputs to supplied `copy_positions`. Change the cellular seed before changing either display; deriving the recursive recipe belongs to Fractals.', 'Choose another seed and nominate a feature to compare with the fixed sculpture. Verify that the cube transforms stay fixed, even if the visual resemblance no longer persuades you.'),
    ('Read `reset`, `step` and `report` in the paired model. Follow one changed value through storage and measurement before interpreting its displayed brightness.', 'Choose a different valid intervention address or pull value. Keep the two update procedures and their drive matched. Predict the first difference count and peak, then test those values rather than judging the image alone.'),
]
names=[['row.gd','point_body.gd'],['volume.gd','point_body.gd'],['history.gd','point_body.gd'],['life.gd','point_body.gd'],['presence.gd','point_body.gd'],['field.gd','exchange.gd','point_body.gd'],['procedures.gd','comparison.gd','point_body.gd'],['paired.gd','difference.gd','point_body.gd']]

for i,h in enumerate(order):
    p=R/'commons/maps'/h/'tutorial.md'; old=read(p); s=old
    heading=re.search(r'\n## (?!Learning elements)[^\n]+\n',s).group()
    s=replace(s,heading,'\n## Reading route\n\n'+focus[i][0]+' The complete files also include the display and controls; keep those working while investigating the named functions.\n'+heading)
    s=s.replace('Make one independent edit:', 'Make this guided edit:').replace('## Make an independent change','## A guided boundary change')
    if h=='CA_Introduction':
        s=replace(s,'Trace gave us an array of positions;', 'The Shader sequence ended with a field that kept its previous state. We keep that old-to-next agreement and open a smaller rule: three Boolean inputs choose one answer. No shader machinery is needed for this row.\n\nTrace gave us an array of positions;')
        s=replace(s,'No authored mesh, label or scene-child reference is required.', 'If the node is not present in your working scene, add an empty Node3D named `PointStudy` under the hall you are editing. Attach only the current lesson host to it. Save each lesson in its own folder before replacing the host; all relative helper paths resolve inside that folder. No authored mesh, label or scene-child reference is required.')
        s=replace(s,'The same eight-answer list can later receive a different interface.', 'The same eight-answer list can later receive a different interface.\n\nBuild and compare on desktop, then return to the installed exhibit for its full VR controls. Later compact studies name keyboard-only comparison controls explicitly. Reusing PointBody means retaining its construction and behaviour in your code; these listings do not transfer a live object or saved field automatically between halls.')
    if h=='CA_ElementaryRules':
        s=replace(s,'They share the three-state rule and empty outer shell, but their beginnings and resulting shapes differ.', 'They share the three-state rule and empty outer shell, but their beginnings and resulting shapes differ. In the printed twelve-cell seed, the central active-neighbour counts are **11 → 14 → 5**. At the installed gold address they are **11 → 7 → 5**. Both follow active → fading → empty. Compare the transition rule, not the two specimens as identical fields.')
        s=replace(s,'This is your own seed, not a change to the museum installation.', 'This is a prescribed seed comparison in your copy, not a change to the museum installation.')
    if h=='CA_SoftRules':
        s=replace(s,'## A field stores two values', '## Return to the Shader field\n\nShaders already introduced a retained U/V field. Here we expose neighbour exchange by switching it off in one matched copy. This CPU model uses four axial neighbours, a 32 × 32 grid, Du = 0.16, Dv = 0.08, F = 0.037 and K = 0.060. The Shader study used a weighted eight-neighbour stencil, a 96 × 96 grid and different rates. We carry the distinction between state and image, not its texture or exact trajectory. Compare A and B within this lesson; do not expect their pictures to reproduce the Shader wall.\n\n## A field stores two values')
    if h=='CA_EdgeOfChaos':
        s=replace(s,'## Make three predictions','## Predict, then check')
        s=replace(s,'**First, keep INTEGER, UNIFORM, PULL 0.25 and DRIVE 0.**', 'Before reading the worked outcomes below, write what you expect integer storage, fractional storage and zero pull to retain after one update. These are guided comparisons; your independent choice follows them.\n\n**First, keep INTEGER, UNIFORM, PULL 0.25 and DRIVE 0.**')
    insert='\n## Your own test\n\n'+focus[i][1]+' Keep your prediction, the observed values and a runnable assertion in a separate test script. If they disagree, identify whether the prediction, test or study needs changing.\n'
    if h=='CA_EdgeOfChaos': s=replace(s,'\n## Optional composition',insert+'\n## Optional composition')
    else:
        # Place a choice at the exit, leaving the worked explanation intact.
        s=s.rstrip()+ '\n'+insert+'\n'
    assert blocks(s)==blocks(old),h
    # Explicit extraction labels are comments, never learner-code edits.
    count=[0]
    def mark(m):
        n=names[i][count[0]];count[0]+=1
        return '<!-- student-code:'+n+' -->\n'+m.group()
    s=re.sub(r'```gdscript\n.*?\n```',mark,s,flags=re.S)
    assert count[0]==len(names[i]);write(p,s)

edits={
 'CA_Introduction': [('Keep the pleasure of the blob. Bring an unfinished question with it.', 'The Shader wall kept a changing field behind its surface. This board offers fewer states and a clock you can stop after each answer. Bring the question of what is kept; here we can follow it one neighbourhood at a time.')],
 'CA_ElementaryRules': [('Every answer is written into a second array. The old volume supplies all the questions before the arrays exchange places. There is no privileged first cell whose new answer reaches its neighbours early. STEP gives this local agreement one generation; the rest of the museum keeps running.', 'STEP lets all the cells answer the same previous world. A changed cell cannot rush its new answer to a neighbour within that step. The rest of the museum keeps running.')],
 'CA_GameOfLife': [('The rule reads left, centre and right, as the board in the first hall did. Their ordered states select one of Rule 30\'s eight answers. Each answer enters a new row while the old row remains available to its other neighbours. The study keeps the new row and adds it to the record.', 'The opening board\'s row has returned, using Rule 30. Its next answer becomes another part of the record. We have changed what can remain available to us after the calculation moves on.')],
 'CA_BeyondBinary': [('A zero does not contain an instruction to make a hole.', 'A zero does not contain an instruction to make a hole. The route is asking us to compare uses of an answer as well as ways of obtaining it.')],
 'CA_ExpandingSpace': [('Three of the four choices moved in this hall: a cell holds a fraction, the visitor\'s position is among what it consults, and the order of the loop decides when an answer counts.', 'Our position has entered the conditions. What the surface permits can change that position in return.')],
 'CA_SoftRules': [('Two small squares wait on the tables.', 'The Shader wall has a relative here. Its colours also came from a field with a past. These tables offer a different comparison: let one field receive from its neighbours while withholding that relation from the other.\n\nTwo small squares wait on the tables.')],
 'CA_AgentsCircuits': [('The resemblance is useful because it gives you a question to test.', 'We are returning to a familiar row for a new reason: to compare its making with another procedure. The resemblance is useful because it gives you a question to test.')],
 'CA_EdgeOfChaos': [('More places carry it. Less of it remains at any one place.', 'More places carry it. The largest local difference is smaller. A widening patch and a growing disturbance would be different findings.')],
}
for h in order:
    p=R/'commons/maps'/h/'final.md';s=read(p)
    for a,b in edits[h]:s=replace(s,a,b)
    write(p,s)

d=json.loads(read(SEQ)); q=d['sequences']['cellularautomata']; old_maps=q['maps'][:]
q['name']='Cellular Automata: What a Neighbour Can Change'
q['truth']='A field keeps states at addresses. Its neighbourhood, update schedule, boundary and input determine how those states can change.'
q['description']='Eight museum comparisons: local answers, lingering states, retained history, moving patterns, bodily input, neighbour exchange, different procedures and matched differences.'
q['demonstration']='Step a row, follow a fading cell, walk beside a saved history, connect Life to a lamp, withdraw support by proximity, isolate exchange and measure one changed beginning.'
q['qfep_connection']='The reflective track asks who or what can contribute, what a stored state retains, and how a receiver turns a value into a consequence. These are situated questions; this sequence does not measure Langton’s lambda or demonstrate a universal edge-of-chaos condition.'
q['estimated_time']='Self-paced; no measured completion time for the eight build-and-investigate lessons.'
titles=['A row with neighbours','A state that lingers','Keep a generation','A pattern visits an address','The surface includes you','What a neighbour offers','Two ways to make','What a difference keeps']
q['content']=[h+': '+t for h,t in zip(order,titles)]
q['learning_objectives']=[
 'Read ordered Boolean neighbours and update from an unchanged previous row.',
 'Separate cell state, active participation and visible surface in a three-state volume.',
 'Keep independent history and distinguish site, generation, display and physical support.',
 'Implement Life and connect a fixed address to an output without feedback.',
 'Transform external positions into rule inputs; compare synchronous and scan updates.',
 'Isolate neighbour exchange from a shared local reaction using matched fields.',
 'Distinguish local state updates from a supplied recursive placement recipe.',
 'Measure matched differences and separate storage, threshold and display gain.'
]
q['learning_objectives_status']='Current lesson subjects aligned on 10 October. Historical map IDs retained. Fresh museum and independent ghost-student review in progress.'
assert q['maps']==old_maps
write(SEQ,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
changes=[]
for h in order:
    for t in ['tutorial','final']:
        p=R/'commons/maps'/h/(t+'.md');before=read(O/'before'/h/p.name)
        write(O/'diffs'/h/(t+'.diff'), ''.join(difflib.unified_diff(before.splitlines(True),read(p).splitlines(True),fromfile='before/'+h+'/'+p.name,tofile='current/'+h+'/'+p.name)))
        changes.append({'hall':h,'track':t,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'printed_code_unchanged':blocks(before)==blocks(read(p))})
write(O/'editorial-checks.json',json.dumps(changes,indent=2)+'\n')
print(json.dumps({'manuscripts':len(changes),'printed_code_unchanged':True,'route_unchanged':True}))
