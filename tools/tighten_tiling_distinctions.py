"""Edit Tiling's teaching emphasis; preserve every executable student file and hall."""
from pathlib import Path
import re, json, hashlib, difflib, shutil
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-tiling-different-jobs'
OLD = R / 'doc/book/iterations/2026-10-09-tiling-revision'

ROWS = [
 dict(id='Pattern_Disco', title='Return to the floor', mode='reuse', verb='Separate',
  focus='Change the palette without changing the pattern values.',
  keep='Addresses and cube positions', change='Palette, then phase in a separate comparison',
  test='Make both palette entries grey; advance the rule, then reveal it with another palette.',
  role='A brief return to Arrays and Colour. Follow one square through a palette change and a phase change. Reuse the existing grid and point; the carried classes need no new explanation.',
  elements=['A pattern value and its assigned colour.','Palette change versus phase change.','A changed value hidden by equal colours.'],
  image='palette-navy-pink.png',
  spatial='Let the walkable floor carry this return. The sequencer is a wider encounter, not another prerequisite in this lesson.'),
 dict(id='Pattern_Foundry', title='Make the source', mode='build', verb='Author',
  focus='One stored mark changes every occurrence that reads it.',
  keep='The receiver and its reading rule', change='One source entry',
  test='Predict all six visible occurrences of an edited entry before painting.',
  role='Build the editable source. Stay with one mark and its repeated appearances. Copying recipes, dressing architecture and saving fabric are later questions; the larger machines remain available for a return visit.',
  elements=['An editable source of palette indices.','Wrapped addresses into that source.','One edit reaching its repeated occurrences.'],
  image='small-source.png',
  spatial='Make the small source and its repeated preview the first encounter. Keep the loom, studio, mirror and runway as later visits so this room does not announce the entire sequence at once.'),
 dict(id='Tutorial_Pattern', title='Change the reader', mode='build', verb='Reflect',
  focus='Change the address operation while the stored mark stays fixed.',
  keep='Source entries and receiver', change='Forward or reflected lookup; separately reverse the stored rows',
  test='Tell a reflected reading from a flipped source by inspecting the stored entries.',
  role='Change how a copy reads the source. This room separates a reflected lookup from a mutation of the stored mark. Keep the source small and asymmetric; classification and glide will come later.',
  elements=['Forward and reflected source lookup.','Changing a reader versus mutating its data.','Painting back through a reflected occurrence.'],
  image='two-fixed-fields.png',
  spatial='Keep this as a quiet two-field comparison. A source view must remain visible beside the result; its unchanged or changed cells are the evidence.'),
 dict(id='Array_Patterns', title='Give the address a place', mode='build', verb='Place',
  focus='Recover the same address after the receiver turns and changes size.',
  keep='Source and lookup', change='Receiver frame and physical cell spacing',
  test='Find the same source entry with the held point on both table and wall.',
  role='Return to Transformation with a purpose: place the pattern in a physical frame, then recover an address from your hand. Hold the pattern rule fixed. The tunnel makes this a passage to walk through as well as a display to inspect.',
  elements=['A receiver frame and its local axes.','World position converted to a surface address.','Cell spacing and finite extent in metres.'],
  image='installed-tunnel.png',
  spatial='Let the tunnel dominate. Older tile machines are secondary returns; another mirror comparison should not become the main encounter.'),
 dict(id='Symmetry_Seventeen', title='Combine operations', mode='build', verb='Compose a rule',
  focus='Add a half-height shift to a reflection already understood.',
  keep='Source and placed receiver', change='A composed source-address operation',
  test='Predict a glide lookup after changing source height from two rows to four.',
  role='A short extension of the existing reader: add a half-height shift to reflection. Use P1 and PM as known comparisons. The new question is what composing operations permits; the wider gallery introduces classification without asking you to rebuild seventeen systems.',
  elements=['Reflection composed with a half-height shift.','Source height as a condition of the discrete rule.','A construction rule versus a classification claim.'],
  image='installed-p1-pg.png',
  spatial='The current two-panel console resembles Tutorial Pattern too closely. A next spatial pass should make the glide displacement and a full return visible, with the classification gallery beyond the comparison.'),
 dict(id='Pattern_Temple', title='Let one wall differ', mode='compose', verb='Distribute',
  focus='Choose which receivers should agree, and which should become independent.',
  keep='Known source, rules and receiver construction', change='Ownership and the scope of a copied recipe',
  test='Copy table to wall, edit the wall, and show that the table keeps its record.',
  role='Compose with the source, rules and frames you already have. Foundry made every occurrence consult one source. Here separate receivers own separate recipes: copying makes them agree once, while a later edit can stay local. The temple gives that choice room to matter.',
  elements=['Selecting the receiver of an edit.','A recipe copied once versus a continuing shared reference.','Composing agreement and difference across a room.'],
  image='court-one-different.png',
  spatial='Keep the whole court as the artifact. Begin with agreement, then leave one wall different. Avoid adding another catalogue of pattern machines around this strong room-scale action.'),
 dict(id='Ribbon_Patterns_01', title='Look inside the pattern', mode='build', verb='Layer',
  focus='Use height in the source lookup and inspect what a slice leaves hidden.',
  keep='The source and the existing grid renderer', change='A third storage index and height-dependent reading',
  test='Predict one value at an unequal-index address, then hide other layers without deleting them.',
  role='Take a branch from the surface into a volume. The extra index is the subject. This prepares later work with spatial data; the next colour comparison and fabric shader do not require a volume. Keep that distinction instead of pretending every room is a prerequisite for the next.',
  elements=['Layers of rows stored as values[y][z][x].','Height used as an input to the source lookup.','A hidden layer versus deleted data.'],
  image='installed-slice.png',
  spatial='Lead with the source/volume pair and a visible slice. Shelves and sorting races are other encounters, not extra required array lessons here.'),
 dict(id='Ribbon_Patterns_02', title='Pause and compare', mode='reflect', verb='Observe',
  focus='Separate a fixed numerical value from its appearance in context.',
  keep='Target values or source pixels', change='Surround, viewpoint or supplied shading, one at a time',
  test='Record changed condition, fixed values and observed appearance without a prescribed perceptual answer.',
  role='An investigation between builds. Use the installed comparisons, predict what stays fixed and record what you see. The complete reconstruction remains below as an optional return to shared materials; building another selector is not required before the fabric lesson.',
  elements=['A fixed value under changing viewing conditions.','Surface distance versus projected appearance.','Prediction and observation kept distinct.'],
  image='installed-context.png',
  spatial='Give the equal targets and the plane/curve pair a quieter visual surround. Hue carousels, prisms and scanners can remain optional encounters; they need not restart the Colour curriculum.'),
 dict(id='Ribbon_Patterns_03', title='Carry the mark onto a body', mode='build', verb='Sample and wear',
  focus='Write the known reading operation as a shader, then inspect what the saved recipe carries.',
  keep='Supplied studio, source editor and garment geometry', change='The fragment sampling expression',
  test='Change vertical repeats to three and explain why the worn saved recipe still uses two.',
  role='The address calculation returns in a new place: the fragment shader. Keep the studio as the supplied host. A garment and procession make the result available to wear and compare; saved settings and the program interpreting them remain separate.',
  elements=['UV repeat and offset in a fragment shader.','Texture sampling onto differently mapped surfaces.','A saved recipe versus its shader interpreter.'],
  image='installed-studio.png',
  spatial='Let studio, mirror and procession close the route. Lasers, strobes and glitch displays are part of the wider museum; the primary path should not make them competing tutorial destinations.'),
]

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def codes(t): return dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl|ini)\n(.*?)\n```', t, re.S))
def write(p,t): p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t,encoding='utf-8')

def main():
 O.mkdir(parents=True,exist_ok=True)
 assert not (O/'audit.json').exists(), 'This is a one-time prose pass; do not overwrite later edits.'
 sequence=R/'commons/maps/sequences/tiling.json'
 protected={str(sequence.relative_to(R)):sha(sequence)}
 originals={};audit=[]
 for r in ROWS:
  h=r['id'];m=R/'commons/maps'/h
  protected[str((m/'map_data.json').relative_to(R))]=sha(m/'map_data.json')
  for track in ['tutorial','final']:
   p=m/(track+'.md');t=p.read_text(encoding='utf-8');originals[h,track]=t
   write(O/'before'/h/(track+'.md'),t)
  t=originals[h,'tutorial']
  end=t.index('\n## ',t.index('## Learning elements')+3)
  t=t[:t.index('## Learning elements')]+'## Learning elements\n\n'+'\n'.join('- '+e for e in r['elements'])+'\n\n'+r['role']+'\n'+t[end:]
  # Put explanations/predictions before unchanged companion listings.
  ranges={
   'Pattern_Disco':('### The Palette class, carried unchanged','## Make the distinction disappear'),
   'Pattern_Foundry':('### The carried files','## Predict a shared change'),
   'Tutorial_Pattern':('### The carried files','## Predict before pressing'),
   'Array_Patterns':('### The carried files','## Predict, then inspect')}
  if h in ranges:
   a,b=ranges[h];i=t.index(a);j=t.index(b);carried=t[i:j].strip();t=t[:i]+t[j:]
   t=t.rstrip()+'\n\n## Complete carried files\n\n'+carried+'\n'
  if h=='Pattern_Temple':
   t=t.replace('Carry the source and the distinction between a record, its copies and its receivers into Ribbon Patterns. The next question is how a source gains another index and how a surface reads through it.',
    'Before leaving, choose your own arrangement of agreement and difference. Make the two receivers agree, change one, then explain why the other stays as it was. In the installed court, choose a reason to keep one wall different. The next hall takes a branch into layers: it uses the source to fill a volume, rather than requiring this room to become a larger surface catalogue.')
  if h=='Ribbon_Patterns_02':
   a=t.index('## One material, two targets');b=t.index('## Carry the method to the curved display');c=t.index('## Complete carried files')
   construction=t[a:b].replace('## One material, two targets','## Optional reconstruction — one material, two targets',1)
   viewing=t[b:c]
   t=t[:a]+viewing+construction+t[c:]
   t=t.replace('Use the familiar five-by-five grid as a selector.', 'In the optional reconstruction, use the familiar five-by-five grid as a selector.',1)
  if h=='Ribbon_Patterns_03':
   t=t.replace('Tiling has followed a value into a source, a repeated reading, a surface, a volume and a garment. Keep those distinctions when the picture changes.',
    'Across Tiling we have reused classes and reading operations, with declared sources for each study. We have not automatically saved one edited motif through every hall. The volume was a branch; the garment returns to surface sampling. Keep those distinctions when the picture changes.')
  assert codes(t)==codes(originals[h,'tutorial']),h+' code changed'
  write(m/'tutorial.md',t)
  f=originals[h,'final']
  if h=='Pattern_Foundry':
   begin=f[:f.index('<!-- @pattern_tile_mirror -->')]
   further=f[f.index('<!-- @pattern_tile_mirror -->'):f.index('<!-- @ -->')]
   notes='# Foundry — further encounters\n\nThese encounters remain in the museum. They are a return visit to the loom, studio and architectural controls, after the first reading has followed one source edit into its copies.\n\n'+further
   write(m/'further-encounters.md',notes)
   f=begin+'''Now try to make the mark appear only once while the rest of the field stays unchanged. Editing the shared source makes it recur. The instrument makes it easier to change every appearance than to keep just one different. A single stored cell holds all these places together.

<!-- @ -->

A repeated field can be economical, recognisable and pleasurable. It can also make a wanted exception difficult to express. Choose a reason for keeping one copy different: a direction marker, a mistake you want to retain, or a place that should resist the general pattern.

For now, this source cannot grant that exception. The mark you change will return wherever the rule reads it. You have made a small decision whose reach exceeds your hand. What would you want to keep shared, and where would you want another decision to begin?

Leave the larger machines running. In Tutorial Pattern, keep the painted cells as they are and change the way a copy reads them. That is a different action from painting another mark.

[On a return visit: the loom, held images and architectural surfaces](further-encounters.md).
'''
  if h=='Pattern_Temple':
   needle='At the desk, a gold point names the surface you are about to change.'
   f=f.replace(needle,'In Foundry, one edited source reached every occurrence that read it. Here each part of the court keeps a recipe of its own. You can make them agree without making every later choice travel between them.\n\n'+needle,1)
  if h=='Symmetry_Seventeen':
   f=f.replace('Here the surface stays flat, and a small mark returns in ways that do not quite agree.',
    'Here the surface stays flat. You already know a reflection can leave the source unchanged. Follow what happens when that reflection is also shifted: an operation we know becomes one part of another.')
  write(m/'final.md',f)
  previous=OLD/h
  for name,body in codes(t).items():
   p=previous/'learner/printed'/name
   assert p.read_text(encoding='utf-8')==body+'\n',f'{h}/{name}: printed evidence mismatch'
  audit.append({'hall':h,'code_files_unchanged':len(codes(t)),
   'tutorial_before_sha256':hashlib.sha256(originals[h,'tutorial'].encode()).hexdigest(),
   'tutorial_after_sha256':sha(m/'tutorial.md'),
   'tutorial_prose_words_before':len(re.sub(r'```.*?```','',originals[h,'tutorial'],flags=re.S).split()),
   'final_words_before':len(originals[h,'final'].split()),'final_words_after':len(f.split()),
   'existing_test_report':(previous/'tests.json').relative_to(R).as_posix(),
   'existing_tests_passed':json.loads((previous/'tests.json').read_text())['all_passed']})
  for track in ['tutorial','final']:
   now=(m/(track+'.md')).read_text(encoding='utf-8')
   write(O/'changes'/f'{h}-{track}.diff',''.join(difflib.unified_diff(originals[h,track].splitlines(True),now.splitlines(True),fromfile='before/'+h+'/'+track+'.md',tofile='after/'+h+'/'+track+'.md')))
 # Update only existing Tiling summaries/modes, preserving all unrelated plan data.
 p=R/'doc/book/course/execution-plan/plan.json';raw=p.read_text(encoding='utf-8');plan=json.loads(raw)
 write(O/'before/tiling-plan-entries.json',json.dumps([x for x in plan['lessons'] if x['id'] in {r['id'] for r in ROWS}],ensure_ascii=False,indent=2)+'\n')
 original_other=[x for x in plan['lessons'] if x['id'] not in {r['id'] for r in ROWS}]
 fmt=lambda x:'    '+json.dumps(x,ensure_ascii=False,indent=2).replace('\n','\n    ')
 for r in ROWS:
  row=next(x for x in plan['lessons'] if x['id']==r['id']);old=fmt(row);assert raw.count(old)==1
  row['mode']=r['mode']
  row['summary']=r['role']+' '+r['focus']+' Demonstrate it: '+r['test']
  row['sequenceRole']={'verb':r['verb'],'heldFixed':r['keep'],'changed':r['change'],'revision':'2026-10-09-tiling-different-jobs','spatialProposal':r['spatial']}
  raw=raw.replace(old,fmt(row),1)
 assert [x for x in json.loads(raw)['lessons'] if x['id'] not in {r['id'] for r in ROWS}]==original_other
 write(p,raw)
 assert all(sha(R/k)==v for k,v in protected.items()),'Protected hall/order changed concurrently'
 write(O/'audit.json',json.dumps({'scope':'Prose and teaching emphasis; no new runtime claims','halls':audit,'protected_sha256':protected,'all_printed_code_matches_prior_tests':True,'other_plan_rows_unchanged':True},indent=2)+'\n')
 write(O/'route.json',json.dumps(ROWS,ensure_ascii=False,indent=2)+'\n')
 print('Revised nine lesson emphases; all printed files unchanged; hall maps and sequence unchanged.')

if __name__=='__main__': main()
