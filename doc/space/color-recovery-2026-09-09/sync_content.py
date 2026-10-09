from pathlib import Path
import json,hashlib,collections,sys
sys.path.insert(0,str(Path.cwd()))
R=Path('commons/maps');O=Path('doc/space/color-recovery-2026-09-09')
def load(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def save(p,d):Path(p).write_text(json.dumps(d,indent=1,ensure_ascii=False)+'\n',encoding='utf-8')
texts={
'Color_Context_Placed':'''# A colour with company

<!-- @dna_modern_art_albers_homage_warm -->

Find the warm Albers study among the recovered compositions. Stay with a small area of colour long enough to notice what surrounds it. Then let your gaze include the neighbouring work. Has the colour changed, or has the comparison?

The arrangement holds several ways of giving colour company: a stack, a frame, furniture, repeated forms. Some make relationships easy to name. Others put more into the view than a name can hold. Begin with one work, then widen the view.

The warm study is a made configuration. Its proportions, colours and neighbours have been chosen. The room does not offer a neutral sample against which every other arrangement must be measured. It offers something specific that another arrangement can contest.

<!-- @ -->
''',
'Color_Pillar':'''# The colour between the pillars

<!-- @pillarcolorcollection -->

Stand where the colours are pale. Follow one line of pillars farther into the field. The hue stays recognisable while its saturation increases. Now walk across that line. The hue changes too. Two directions, two different ways to change a colour.

There are thirty-five pillars, but the floor does not stop at thirty-five colours. Look between the columns. The smooth field continues where no pillar stands. Each pillar is a sample of that field at a particular position.

```gdscript
var u := clampf(p.x / 12.8, 0.0, 1.0)
var v := clampf(p.z / 19.2, 0.0, 1.0)
return Color.from_hsv(u * 0.85, lerpf(0.25,1.0,v),0.95)
```

The address is doing work. One coordinate chooses a place along the hue range; another chooses saturation. Value stays at 0.95. The gaps between columns contain possibilities that the collection has not put into a body.

The field is larger than its former arrangement: five columns by seven rows, with 3.2 metres between samples. Each pillar rises 4.6 metres. Walk close enough to read a sample's address and colour code, then step back until several pillars overlap. The computed values remain fixed. What their company makes visible keeps changing.

<!-- @color_sets_overview -->

Beyond the field, twelve collections hang on a framed wall. Their colours have names, and their groups have names too. These sets were assembled. The field was evaluated. Both are ways of deciding which colours belong together.

Take a swatch if you want to carry that decision into another view. Its label makes it identifiable. It cannot carry every relationship the colour will enter. Compare it with a pillar, with another swatch, with the space around your hand.

The wall does not finish the gradient. It gives you another method of collecting it, with another set of omissions.

<!-- @ -->
''',
'Color_Paint':'''# Before the hand

<!-- @ball_painting_demo -->

A coloured ball is already moving across the canvas. Wait before taking anything. The line changes direction, and the pigment changes colour as it travels. A painting is underway without your hand.

The machine's path comes from two oscillations with different rates. Neither one describes the whole curve alone.

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
```

The surface receives the line between successive samples. At most thirty updates arrive each second. The moving ball makes the sampling visible; wet paint continues to change the image after a mark is made.

The other pigment balls remain available to take. Try adding a gesture while the automatic painter continues. Your mark and the machine's mark reach the same drawing surface. They arrive by different paths, but neither owns a separate canvas.

<!-- @albers_wall_gallery -->

Turn from that accumulating surface to the Albers studies. Let one coloured area hold your attention, then include its surround. The comparison changes again. Here the arrangement offers a condition to look into; at the canvas, marks keep changing that condition while you look.

Return to the painting. Some of what happened while you looked away is still visible. Some has already flowed into something else.

<!-- @ -->
''',
'Color_Walls':'''# The view has partitions

<!-- @color_constellation_office -->

The glass makes an office before anyone sits down. Eight desks wait inside eight cubicles. Every partition follows one of two perpendicular directions. From the central aisle, the entrances are easy to find. Looking through the panes is less straightforward.

Choose one cubicle and enter it. Look across its coloured glass toward the next. Move until another pane enters the same view. You have changed no colour parameter, yet the layers through which you see have changed.

The panes are full height: 2.6 metres, with 1.2-metre entrances opening onto the aisle. Their angles stay at zero or ninety degrees. The room uses familiar office geometry to make colour into an architectural condition. A partition can divide movement while letting a view continue.

These are tinted transparent materials in a renderer. Their overlap is alpha compositing, not a complete physical simulation of light passing through coloured glass. The office gives that rule walls, desks and distances. Which views does it make possible, and which does it quietly organise for you?

<!-- @color_space_navigator -->

Return to the colour-space navigator. Here a colour can be treated as a position in a coordinate system. In the office, your position changed the colours in your view. Keep those operations distinct, then put them into conversation.

<!-- @gradient_interpolator -->

At the interpolator, follow the passage between colours. Compare a calculated transition with a view through several panes. Both can produce an intermediate appearance. The operations that produced it differ.

The room lets a similar appearance have more than one explanation. Look again before deciding which one applies.

<!-- @ -->
'''}
for m,t in texts.items():(R/m/'final.md').write_text(t,encoding='utf-8')
primary={'Color_Context_Placed':['dna_modern_art_albers_homage_warm'],'Color_Nails':['nail_color_controller','hand_color_controller'],'Color_Grid_Pallet':['gridcolorizer'],'Color_Rainbow':['rainbow'],'Color_Pillar':['pillarcolorcollection','color_sets_overview'],'Chamber_Color':['becoming_catalyst'],'Color_Paint':['ball_painting_demo','albers_wall_gallery'],'Color_Walls':['color_constellation_office','color_space_navigator','gradient_interpolator'],'Color_Flashlight':['flashlight_demo']}
roles=load('commons/data/artifact_roles.json');core=load('commons/data/museum_core_encounters.json');report=load(O/'recovery.json')
for rec in report['rooms']:
 m=rec['map'];d=load(R/m/'map_data.json');placed=list(dict.fromkeys(str(t).split(':')[0].split('#')[0].strip() for row in d['layers']['interactables'] for t in row if str(t).strip() and str(t).strip()!='0'))
 if m in primary:
  oldroles=roles['roles'].get(m,{})
  roles['roles'][m]={t:('primary' if t in primary[m] else 'decoration' if oldroles.get(t)=='decoration' or t=='dark_sphere' else 'secondary') for t in placed}
  roles['order'][m]={role:primary[m] if role=='primary' else [t for t in placed if roles['roles'][m][t]==role] for role in ['primary','secondary','decoration']};roles['groups'][m]=[]
  p=R/m/'final.md';row=core['rooms'].setdefault(m,{});row.update(primary_tokens=primary[m],sequence='color',status='draft' if p.exists() else 'text_pending',reason='Historical configuration recovered with perimeter walls; selected colour encounters restored as the primary thread.',map_sha256=hashlib.sha256((R/m/'map_data.json').read_bytes()).hexdigest(),learner_verified=False)
  if p.exists(): row.update(text_path=p.as_posix(),text_sha256=hashlib.sha256(p.read_bytes()).hexdigest())
  else: row.pop('text_sha256',None)
 note='\n\n## 2026-09-09 — configuration recovered and enclosed\n\nSource: '+rec['source']+'. Original size '+str(rec['original_size'])+'; enclosure '+str(rec['museum_size'])+'; every original structure and utility cell preserved at offset (4,4). The real GridSystem retains grid-dependent colour behavior, inside perimeter walls, with no staged glass arena or fire. Full layouts and prior manuscripts are preserved in doc/space/color-recovery-2026-09-09.\n'
 if rec['changes']:note+='\nAuthored exceptions: '+json.dumps(rec['changes'],ensure_ascii=False)+'.\n'
 note+='\nRuntime grid/placement checks pass. Learner and headset walkthrough remain unverified. '+('The restored room does not yet have a final manuscript.\n' if not (R/m/'final.md').exists() else 'The book remains a draft.\n')
 if '2026-09-09 — configuration recovered and enclosed' not in (R/m/'field_notes.md').read_text(encoding='utf-8-sig'):
  with (R/m/'field_notes.md').open('a',encoding='utf-8') as f:f.write(note)
 # All structure restoration metadata lives outside the book voice.
 (R/m/'museum_recovery.md').write_text(note.lstrip(),encoding='utf-8')
save('commons/data/artifact_roles.json',roles);save('commons/data/museum_core_encounters.json',core)
# Book navigation follows current sequence membership; preserve existing secondary lines only when placed.
p='commons/data/book/color.json';book=load(p);old={r['map']:r for r in book['pearls']};pattern_pearl=old.get('Pattern_Foundry');book['pearls']=[]
for m in report['color_maps']:
 row=old.get(m,{'pearl':m.replace('_',' ').lower(),'map':m,'join':True});row['hero']=primary[m][0];row['lines']=[{'token':t,'text':t.replace('_',' '),'by':'astra'} for t in primary[m]];row.pop('simulations',None);book['pearls'].append(row)
save(p,book)
pt=Path('commons/data/book/tiling.json');tilebook=load(pt) if pt.exists() else {'chapter':'tiling','title':'Tiling and Symmetry','pearls':[]};prior={r['map']:r for r in tilebook['pearls']}
if pattern_pearl:prior.setdefault('Pattern_Foundry',pattern_pearl)
tilebook['pearls']=[prior.get(m,{'pearl':m.replace('_',' ').lower(),'map':m,'lines':[],'join':True}) for m in report['pattern_maps']];save(pt,tilebook)
# Refresh only the two changed chapter slices, keeping every other chapter's rows.
from tools import build_spine_artifact_order as builder
builder.ROLES=roles
p='commons/data/spine_artifact_order.json';d=load(p);oldrows=d['order'];first=next(i for i,r in enumerate(oldrows) if r['sequence'] in ['color','tiling']);remaining=[r for r in oldrows if r['sequence'] not in ['color','tiling']];seen={r['lookup'] for r in remaining};rows=[]
for seq,maps in [('color',report['color_maps']),('tiling',report['pattern_maps'])]:
 for m in maps:
  for t,role,by in builder.thread(m):
   if t in seen:continue
   seen.add(t);rows.append({'lookup':t,'sequence':seq,'map':m,'role':role,'by':by})
d['order']=remaining[:first]+rows+remaining[first:];d['_meta']['artifacts']=len(d['order']);d['_meta']['primary']=sum(r.get('role')=='primary' for r in d['order']);d['_meta']['ordered_by']=dict(collections.Counter(r.get('by') for r in d['order']));d['_meta']['maps_read']=sum(len(builder.maps_for(s)) for s in builder.spine_sequences());save(p,d)
from tools import artifact_roles,final_tags
for m in texts:
 tags=final_tags.tokens_of(final_tags.parse((R/m/'final.md').read_text(encoding='utf-8-sig')));assert tags==primary[m]
print('Book navigation and primary roles synchronized; untouched chapter manifest rows retained.')
