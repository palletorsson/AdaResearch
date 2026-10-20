from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
MAP=ROOT/'commons/maps/Random_Entropy'
route='ledger → four mixing jars → shakeable jar → four-cube sorting table → two compartments → displaced points → ruin → signal room'
def edit(name, pairs):
    p=MAP/name;s=p.read_text(encoding='utf8')
    for old,new in pairs:
        assert old in s,(name,old)
        s=s.replace(old,new)
    p.write_text(s,encoding='utf8')

p=MAP/'final.md';s=p.read_text(encoding='utf8')
start=s.index('<!-- @entropy_jar -->');end=s.index('<!-- @entropy_sorting_table -->')
section=s[start:end]
big=section[section.index('Four broad glass jars'):section.index('The gauge is not measuring')]
big=big.replace('Four broad glass jars rise','Beyond the desk, four broad glass jars rise')
big=big.replace('For eight seconds they hold.', 'For eight seconds they hold. One reading asks about colour given a height band, H(C|Y); the vertical bar means “given.” The other asks about colour given core or rim. Each records where in a different way.')
small=section[section.index('A few steps to the side'):section.index('Four broad glass jars')]
small=small.replace('A few steps to the side','Beside the plinth').replace('Its label now names a different quantity: H(C|Y), colour uncertainty given a height band. The vertical bar means “given.” Six horizontal bands divide the jar for the calculation.','Its reading uses six horizontal bands. Here we can change the motion ourselves.')
last=section[section.index('The gauge is not measuring'):]
last='This reading does not measure the heat of shaking. RESET restores the specimen. That intervention, too, belongs to the apparatus. We have changed the positions inside a partition. How many arrangements could its record describe?\n\n'
s=s[:start]+'<!-- @entropy_jar_states -->\n\n'+big+'<!-- @entropy_jar -->\n\n'+small+last+s[end:]
s=s.replace('The count returns as a room.', 'Through the doorway after the ruin, the count returns as a room.')
p.write_text(s,encoding='utf8')

edit('tutorial.md', [('ledger → jar → four-cube sorting table → two compartments → displaced points → ruin → signal room',route)])
edit('artifacts.md',[
('| `entropy_sorting_table` | Four kept cubes; count pictured colour arrangements, then add a divider without changing the batch | (13, 9), yaw 180° |\n| `prefab_disorder` | optional tutorial comparison: originals → parts → hybrids, and back; 16 butterflies confined to the tables | (8, 12), current curated position |\n| `shannon_entropy_meter` | primary | (8, 5) |\n| `entropy_jar` | secondary | (3, 5) |\n| `entropy_compartments` | primary; tutorial and final | (8, 9) |\n| `hardware_entropy_decay` | secondary | (3, 9) |\n| `entropy_axiom` | primary | (8, 15) |\n| `entropy_ruin` | primary | (8, 26) |',
'| 1. `shannon_entropy_meter` | Sort a record while its colour reading stays | (8, 5), yaw 180° |\n| 2. `entropy_jar_states` | Four slow mixtures; height and radial observations | (5, 8), yaw 180° |\n| 3. `entropy_jar` | Shake the retained population directly | (12, 8), yaw 180° |\n| 4. `entropy_sorting_table` | Four kept cubes; inspect every compatible pattern | (5, 14), yaw 180° |\n| 5. `entropy_compartments` | Sixteen sites, two measures, save and replay | (11, 14), yaw 180° |\n| 6. `entropy_axiom` | Walk through positional displacement | (17, 21), yaw 0° |\n| 7. `entropy_ruin` | Remove a support; observe physical consequences | (8, 29), yaw 0° |\n| 8. `signal_room` | Counts and neighbours at room scale | (12, 48), yaw 180° |\n| A. `prefab_disorder` | Optional hybrids, gallery, rehearsal and local butterflies | (19, 10), yaw 180° |\n| B. `hardware_entropy_decay` | Optional input-driven surface wear | (3, 19), yaw 180° |'),
('ledger → jar → four-cube sorting table → two compartments → displacement enclosure → ruin → signal room',route),
('The entrance chamber remains narrower.','Both bays now share the full width. The museum arrives at (8,2), ahead of the ledger; the grid entrance remains at (8,0). A three-metre doorway at row 33 separates the bays. The ten-metre enclosure has its own eastern floor area, with an open central passage and a western bypass.'),
('Near the entrance, `prefab_disorder`','On the eastern side stop, `prefab_disorder`'),
('The west wall at z23–28','The west wall at z26–31'),
('`entropy_jar_states` at (4,2)','`entropy_jar_states` at (5,8)'),
('left of the entrance.','beyond and to the left of the ledger.')])
edit('intent.md',[
('Random_Definition → Random_Entropy → Random_Remove','Random_Definition → Random_Entropies (Types) → Random_Entropy (Workshop) → Random_Remove'),
('**Shared room/final route:** ledger at (8,5) → jar at (3,5) → two-compartment bench at (8,9) → displacement enclosure at (8,15) → ruin at (8,26) → signal room at (12,48). Listed positions are authored grid cells; these instruments face the entrance at 180°. Butterflies and hardware decay remain optional encounters. The full grid is 25 × 66 m, with a narrower entrance chamber and adjoining signal bay.',
'**Shared room/final route:** '+route+'. The [artifact inventory](artifacts.md) gives every position and orientation. Both bays are 25 m wide within the 25 × 66 m grid; a three-metre doorway at row 33 leads to the signal room. Museum arrival is (8,2), before the ledger. Hybrid investigation with its local butterflies and hardware wear occupy optional side stops. The weathering wall sits beside the physical ruin for a direct comparison.'),
('Headset comfort, human understanding and full traversal remain open.','The [new layout review](../../../doc/book/iterations/2026-10-16-entropy-hall-order/index.html) checks actual collision geometry and entry-to-exit routes. Headset comfort and human understanding remain open.')])
edit('summary.md',[
('The current review improves local panel contrast and removes an inaccurate ×4 caption. All artifact placements and museum geometry remain.',
'The current layout gives every artifact a separate footprint. '+route.capitalize()+'. Both bays are 25 m wide, joined by a three-metre doorway. Prefab hybrids and hardware wear remain accessible side stops; the weathering wall accompanies the ruin.'),
('at (4,2)','at (5,8)'),('at (3,5)','at (12,8)')])
edit('plan.md',[
('installed at (13,9)','installed at (5,14)'),
('Installed at (4,2) on a shared plinth; original live jar retained at (3,5)','Installed at (5,8) on a shared plinth; live jar beside it at (12,8)'),
('Current curated bench position (8,12) retained; no hybrid recipe or record changes','Moved to the eastern side stop at (19,10); recipe, gallery, butterflies and rehearsal retained'),
('Points, signal room, butterflies and hardware decay need not all enter the final essay | Curation roles recorded; no untested relocations','Hybrids and hardware wear are optional; butterflies stay with the hybrid tables. Points and signal room remain in the adopted final | All ten placements recorded; main route and side approaches checked in the actual museum'),
('Use the [plinth and physical ruin review](../../../doc/book/iterations/2026-10-16-plinth-and-physical-ruin/index.html) for current native views.','Use the [hall-order review](../../../doc/book/iterations/2026-10-16-entropy-hall-order/index.html) for current placement and native views; the [plinth and physical ruin review](../../../doc/book/iterations/2026-10-16-plinth-and-physical-ruin/index.html) retains the mechanism tests.')])
p=MAP/'plan.md';s=p.read_text(encoding='utf8');s+='''
## Hall-order trial · 16 October

The adopted order is '''+route+'''. The first room is widened to match the signal bay. The point enclosure, ruin, wall and optional benches have separate footprints; every current artifact is retained. A museum-specific arrival marker sits before the ledger, clear of the former threshold collision.

| Next check | Evidence and decision |
| --- | --- |
| Native layout | Measure installed visible envelopes; check supported standing positions with a 0.6 m wide, 1.8 m tall capsule; test route segments every 0.1 m, doorway, exit and the hybrid rehearsal's handoff. Receipts in the hall-order review. |
| Walk and read | Follow the eight main encounters once. Note any missed object, backtracking, obscured control, tiring gap or transition that feels arbitrary. Test in a headset separately. |
| Test the middle | Does observing four mixtures create a reason to shake one jar? Do four visible possibilities prepare the sixteen-site count? Record the first place the next encounter is no longer needed. |
| Revise one placement | Move the weakest transition, repeat from the same entrance, and keep the previous plan and observation. A collision-free route is not evidence that the sequence is compelling. |

No apparatus is removed. The 48-value seed bench remains the first research pilot.
''';p.write_text(s,encoding='utf8')
edit('relationship.md',[
('| Two compartments |','| Four cubes / sorting table | Workshop: inspect all compatible pictures, then change a divider before accepting a formula. |\n| Two compartments |'),
('Optional visual-order study. Keep its lack of an entropy measurement explicit.','Adopted final route: visual-order study after the counting benches. Keep its lack of an entropy measurement explicit.'),
('Authored dismantling, not a heat calculation.','Contact-driven collapse beside a separately authored weathering wall; neither is a heat calculation.'),
('Optional transfer: unchanged colour counts','Final return: unchanged colour counts'),
('| Butterflies and hardware-decay display | Optional collection encounters.','| Butterflies and hardware-decay display | Butterflies belong to the optional prefab tables; hardware wear is a separate side stop.')])
p=MAP/'writing_wall.json';d=json.loads(p.read_text(encoding='utf8'));placement=json.loads((HERE/'placement.json').read_text())
d['order']=placement['main_order']+placement['optional']
for m in d['magnets']:
    key=m['id'];x,z,yaw=placement['placements'][key]
    main=key in placement['main_order'];i=d['order'].index(key)
    m['x']=55+300*(i%2) if main else 955;m['y']=65+240*(i//2) if main else 65+240*(i-8)
    prefix=f"{'Main encounter '+str(i+1) if main else 'Optional side stop'} at ({x},{z}), yaw {yaw}°. "
    m['proposal']=prefix+m.get('proposal','').replace('keep the six-encounter final route','keep the adopted main final route')
    if key=='hardware_entropy_decay':m['brief']='Controller movement and grip change surface scratches, grime and weathering. An input-driven visual study; no thermodynamic entropy calculation.'
    if key=='entropy_jar':m['final']='After watching four slow mixtures, shake a smaller jar. Then ask how many configurations fit a description.'
d['hall_role']='Observe what a reading leaves out, change one condition, then follow the consequence at increasing spatial scales.'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
p=ROOT/'doc/book/course/text-plans/Random_Entropy/research-brief.md';s=p.read_text(encoding='utf8')
s=s.replace('ledger → jar → two compartments → displaced points → ruin → signal room',route).replace('installed at grid (8,9)','installed at grid (11,14)').replace('the six-stop text','the adopted final text')
s=s.replace('The approximately 1,250-word final','The current final')
s=s.replace('the ledger, jar, new two-compartment bench, hardware decay study, displacement enclosure, ruin and signal room','the ledger, four mixing jars, live jar, four-cube sorting table, two-compartment bench, prefab hybrids with local butterflies, hardware decay study, displacement enclosure, ruin and signal room')
s+='\n\n## All-artifact layout · 16 October\n\nThe [hall-order review](../../../iterations/2026-10-16-entropy-hall-order/index.html) records the current positions, eight-encounter main route and optional side stops. Both bays are 25 m wide, joined at row 33. Museum arrival is before the ledger at (8,2). Geometry checks and a collision-tested path are technical evidence; the next human trial asks where the sequence loses its reason to continue. The first 48-value pilot remains unchanged.\n'
p.write_text(s,encoding='utf8')
print('Updated current room/final order, writing wall, tutorial and task plan; historical editions retained.')
