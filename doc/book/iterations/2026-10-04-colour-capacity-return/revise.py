"""Colour proposal revision. Preserves runtime, manuscripts and other sequences."""
from pathlib import Path
import copy, difflib, hashlib, json, re

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
ROUTE = ROOT / 'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p, d): p.write_text(json.dumps(d, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

ARC = ('PROPOSED. Colour returns to the forms, transforms and addressed assignments already available. '
       'Keep geometry while changing its palette; keep a surface while moving its light. Nails introduces '
       'one bounded position-to-colour function and an explained receiver. Pillar changes that function’s '
       'coordinate convention; Grid keeps a returned value at an address. Paint returns to an existing timed '
       'path on an evolving image. Walls carries palette and arrangement onward into Tiling. Rainbow remains '
       'a generous pause with optional palette-making. Equal values need not look alike; these proposed '
       'learner connections do not imply automatic transport between exhibits.')

UPDATES = [
dict(id='Color_Context_Placed',
 storyboard='The first columns keep the same five forms while their colour assignments change. Bringing primitives, transforms and array lookup, the student selects colours for a small supplied part list while keeping its geometry fixed. Begin with list position; supplied numeric shape categories offer a second grouping once that assignment is clear. Each part has an explained material reference, so choosing a palette entry and assigning it are visible operations. The student regroups two separated parts by colour without moving either. They carry a palette and a selection rule independent of placement. The larger stacks, historical associations and cone landscape remain available for looking and composition without becoming additional required builds.',
 storyboard_short='Use fixed-geometry columns. Reuse primitives/transforms/lookup. Teach palette selection separately from material assignment and placement. Supply part/material references; numeric categories optional after index selection. Check: regroup separated parts without moving them. Carry palette + selection rule. Rich stacks remain encounters. Open: reduced host binding; no dictionary lesson assumed.',
 brings=['primitive forms and transforms','array lookup and cyclic selection'],
 learns=['palette selection separate from placement','a colour value assigned to a named material'],
 carries='A palette and a selection rule, with a declared material receiver.',
 supplied=['existing part geometry with direct material references','optional numeric category list'],
 prior_maps=['Array','Tutorial_Tiling_Floor','Trans_Translation'],
 independent_check='Give two separated parts the same colour without changing their positions; explain which selection changed.',
 review_note='Use a small explicit part/category list before requiring dictionaries. The museum’s richer stack records remain supplied; choose the reduced editing entry before writing a full lesson.',
 source_refs=['commons/artifacts/chroma_stack/chroma_stack.gd'],
 before='Palette assignment was useful, but the plan also required building a new stack and left category data unsettled.',
 after='Use the existing forms; change their palette rule. Begin with list position and make shape categories a small optional return.',
 reason='Keep the opening focused on how colour regroups familiar parts.'),
dict(id='Color_Flashlight',
 storyboard='The student moves a coloured lamp across the pale board and faceted sphere, then follows the source edit already offered by this hall. They bring material colour and transforms and keep a direct reference to one existing supplied light. Change its colour while leaving the receiving surface alone; then keep the colour and change the lamp’s direction. Predict which condition changed before comparing the result. The fixed lamp in the side room offers a later return to time-varying colour. Grabbing, room geometry and the renderer remain supplied. The student carries a controllable light and the distinction between a value assigned to a material and light reaching it; no new room or lamp assembly is required.',
 storyboard_short='Use existing lamp/board/faceted sphere. Reuse colour assignment and transforms. Follow current bounded light-colour edit; retain named light reference. Vary colour with receiver fixed, then aim with colour fixed. Supply grabbing/room/renderer. Carry illumination versus albedo distinction. Timed lamp optional. No new room; no spectral-optics claim.',
 brings=['material colour','position and orientation'], learns=['light colour and aim as different inputs to appearance'],
 carries='An explained existing light reference and a controlled comparison of receiving conditions.',
 supplied=['existing light, room and grabbing','renderer and timed side-room comparison'],
 prior_maps=['Color_Context_Placed','Trans_Rotation'],
 independent_check='Choose another light colour, predict its effect on an unchanged surface, then vary aim alone.',
 review_note='The existing tutorial already provides a small light-colour edit. Retain that entry; do not replace it with a new host or require lighting equations.',
 source_refs=['algorithms/postprocessing/flashlight_demo/flashlight_color.gd','commons/artifacts/colour_light_rooms/colour_light_rooms.gd'],
 before='The plan asked the student to create another light in a supplied receiving room.',
 after='Use the museum lamp and the small source edit already taught here. Change colour and aim separately.',
 reason='The existing encounter already provides the necessary experiment.'),
dict(id='Color_Nails',
 storyboard='The held point recolours nails on the giant and petite hands and, in the standard VR setup, the choosing hand. Reuse a position in a named local frame and bounded mapping. The student writes one function taking that local position and positive box dimensions, clamping each component to the box and dividing by its dimension: X becomes red, Y green, Z blue. It returns a Color; one named preview material receives it through albedo_color. The grab connection, hand meshes and application signals are supplied. Predict the colour at a different point and revisit it, then keep nail colour fixed while changing rendered skin. Carry the function and a recorded colour. Preserve the critical distinction between these equally easy assignments and their unequal lived meanings.',
 storyboard_short='Use RGB point and salon hands. Reuse local position/bounded mapping. Teach positive box sizes; clamp/divide X→R, Y→G, Z→B; return Color → named preview albedo. Supply grabbing/hands/signals. Predict another point, revisit it; keep nails fixed while changing skin. Carry function + recorded colour. Preserve Lorde/embodied difference. Open: reduced preview binding; no automatic Rainbow transfer.',
 brings=['held position in a declared local frame','bounded mapping and function returns'],
 learns=['local box coordinates normalised to RGB','returned colour value versus receiving material'],
 carries='A bounded RGB function and a recorded result that can be reused deliberately.',
 supplied=['grab connection and positive box dimensions','preview material, hand meshes and application signal route'],
 prior_maps=['Point_Coordinates','Trans_Scale','Color_Flashlight'],
 independent_check='Predict the RGB result at a new local point, revisit it, then apply that value to the declared preview without changing the hand geometry.',
 review_note='The current companion offers observation/source tracing, not this complete authored function. Bind the reduced function to one named preview before expanding the lesson. GameManager already retains hand/nail choices, but that does not feed Rainbow or Grid automatically. Preserve the main text’s Lorde passage.',
 source_refs=['commons/interfaces/value_mapper_3d.gd','commons/interfaces/nail_color_controller.gd'],
 before='Position-to-RGB was promised, but its input, output and first receiver were left broad.',
 after='Specify one small local-position → RGB function and one preview material. Keep the hand system supplied and preserve the critical skin/polish passage.',
 reason='Give the student a reusable operation without making the salon a wiring lesson.'),
dict(id='Color_Rainbow', mode='deepen',
 storyboard='RE-DIVIDE changes the bands while the opening and celebration remain available. Bring the palette list and a colour recorded at Nails; there is no automatic transfer. An optional making step substitutes that value in a hand-picked palette, then compares different nonempty palette lengths with the same total band width. The curved-strip builder is supplied with radius, width and colour inputs and a returned strip reference; the learner can inspect the fixed-width division without rebuilding the arch. Predict which boundaries move while the opening stays. The forty-eight-band version introduces the difference between many samples and continuity. Carry palette choice and partitioning onward. Staying, looking and celebrating can complete this hall without another coding assignment.',
 storyboard_short='Use RE-DIVIDE; celebration stays unconditional. Reuse palette; manually record/reuse Nails colour. Optional: replace palette entry, compare nonempty lengths at fixed total width. Supply curved-strip builder and route. Predict seams versus opening. Carry palette/partition distinction. Many bands remain discrete; HSV sampler optional before Pillar. No automatic transfer or optics claim.',
 brings=['palette list','a deliberately recorded colour'], learns=['optional fixed-span partition by nonempty palette length'],
 carries='A chosen palette and an understanding of what its partition preserves.',
 supplied=['existing arch, celebration and accessible route','curved-strip builder; optional supplied HSV palette'],
 prior_maps=['Color_Nails','Color_Context_Placed'],
 independent_check='If taking the making route, choose another nonempty palette and predict which band boundaries move while the total span stays fixed.',
 review_note='Keep making optional. The installed options are six, seven, forty-eight and two bands. A hand-picked palette avoids making HSV a prerequisite here. Celebration does not require completing a task.',
 source_refs=['algorithms/primitives/rainbow/rainbow.gd'],
 before='A new partition generator was a required output of the hall.',
 after='Make palette substitution and fixed-width partitioning optional. A chosen Nails colour can return through a recorded value; celebration needs no task.',
 reason='Preserve the room’s generosity and avoid treating every artwork as homework.'),
dict(id='Color_Pillar',
 storyboard='A moving card samples the field between the pillars; leaving it in place keeps its latest sample. Bring Nails’ position-to-colour function and change the rule explicitly: X now chooses hue, Z saturation and represented Y value, converted with Color.from_hsv. The supplied height adapter maps the card’s local 0.65–1.85 metre range into the field’s 0.46–4.60 metre height; it is not the same position passed unchanged. Predict a sample between columns, then vary height while keeping the other coordinates. At value zero, different addresses yield the same black. Carry the field function and one recorded result toward Grid. The matching ceiling and named swatches remain encounters with appearance, classification and the gaps between visible samples.',
 storyboard_short='Use moving sampler and constant swatch. Reuse Nails function pattern, change convention: field X→H, Z→S, Y→V; convert HSV→Color. Supply explicit hand-height adapter (.65–1.85 → .46–4.60 m), card/readouts. Predict between columns; vary V alone. Movement resamples; stationary card keeps latest. Carry function + recorded result. Black has many source addresses; HSV is not perceptually uniform. No automatic Grid handoff.',
 brings=['position-to-colour function','declared reference frame and bounded ranges'], learns=['HSV mapping and conversion','input adaptation versus field evaluation','rule versus displayed samples'],
 carries='A stated colour-field function and one recorded sample for an addressed write.',
 supplied=['sampler, readouts and material receiver','explicit hand-to-field height conversion'],
 prior_maps=['Color_Nails','Color_Rainbow'],
 independent_check='Predict a sample between columns; raise represented height alone, then explain why black cannot reveal its unique source address.',
 review_note='The sampler checks position each frame, not whether it is held. A released stationary card keeps the last sample because its position stops changing. Use actual ranges from hsv_at; value is not perceived lightness. A recorded result or copied function can connect Grid, but the installed exhibits have no such transfer.',
 source_refs=['algorithms/color/pillarcolorcollection/pillarcolorcollection.gd','algorithms/color/pillarcolorcollection/field_sampler.gd'],
 before='The field function was sound, but its coordinate change and hand-height conversion were only generally described.',
 after='Return to Nails’ function with explicit HSV coordinates and height conversion. Keep one sample for the next hall; preserve the fog-like ceiling encounter.',
 reason='Make the change of representation teachable without claiming one formula serves both rooms unchanged.'),
dict(id='Color_Grid_Pallet', title='Let one address keep a colour',
 storyboard='The outline leaves an edited square and returns to find its colour. Bring array addressing and a recorded result from Nails or Pillar. In the proposed reduced study, write that colour to one chosen address through an explained address-to-instance receiver; selecting another address must not write to either. The installed console instead cycles four inks, so using the learner’s own value is a proposed binding. Revisit the address, then apply the whole-grid rule and predict the replacement. Carry stored assignment separately from live field evaluation. Preserving one exception is an optional later policy, not current behaviour. The wider reach of RULE, the twenty-five selectable sites and the unbroken floor retain their critical force.',
 storyboard_short='Use edited floor square. Reuse address/lookup and recorded Nails/Pillar Color. Propose write through named address→instance receiver; selection only reads. Check leave/return, then predict RULE overwrite. Current COLOUR cycles four inks; custom input needs binding. Carry stored assignment versus live evaluation. Optional protected exception; no history/current protection. Keep 25-site control versus wider rule and unchanged support.',
 brings=['addressed read/write','colour returned by an earlier function'], learns=['selection versus assignment','stored sample versus live evaluation','explicit overwrite policy'],
 carries='A colour value stored at an address and a known rule for replacing it.',
 supplied=['selection interface','explained address-to-MultiMesh-instance receiver'],
 prior_maps=['Array','Tutorial_Tiling_Floor','Color_Nails','Color_Pillar'],
 independent_check='Write a recorded colour to one address, leave and return without modifying it, then predict what RULE will replace. The custom-colour binding remains to be supplied.',
 review_note='Vector2i.y denotes room Z here. The actual colour is a MultiMesh instance value, not one separate material per cell. Current COLOUR cycles INKS; custom function input is proposed. RULE overwrites mapped floor colours; protected exceptions/history are not implemented.',
 source_refs=['algorithms/color/gridcolorizer/address_lesson.gd','algorithms/color/gridcolorizer/gridcolorizer.gd'],
 before='The plan introduced a separate material grid and made exception protection its main output.',
 after='Keep a colour from Nails or Pillar at one address using the existing instance model. Teach leaving, returning and overwriting; protection becomes optional.',
 reason='Make the strongest sequence handoff concrete while distinguishing the proposed input from the installed four inks.'),
dict(id='Color_Paint',
 storyboard='The automatic can is painting before the student takes a manual one. Bring elapsed time, sine and the distinction between an address and the value kept there. Read the existing two-coordinate automatic path, then change one rate or amplitude while keeping the other coordinate unchanged. Predict whether the path becomes narrower or turns at another pace. The supplied host converts surface coordinates into a hit and sends deposits to the same draw_spray operation used by the manual cans. Compare a quick pass with staying in one place. Carry the path rule and the distinction between replacing a grid entry and contributing to an image that spreads and fades. The shader and spray apparatus remain supplied; no second brush is required.',
 storyboard_short='Use existing automatic path/manual cans. Reuse time/sine/address distinctions. Edit one UV rate or amplitude; predict path width or pace with other coordinate fixed. Supply UV→hit mapping and shared draw_spray surface. Compare quick versus repeated deposits. Carry path rule and evolving-image distinction, not recoverable gesture history. No second brush; defer spray/feedback shader. Albers remains an encounter.',
 brings=['elapsed time and sine','coordinate mapping and retained traces'], learns=['bounded two-coordinate surface path','deposit versus replacement','evolving image versus stored gesture list'],
 carries='An editable path and an explicit account of what the canvas keeps and changes.',
 supplied=['existing automatic caller and surface-coordinate conversion','shared spray operation, ray hits and evolving-image renderer'],
 prior_maps=['Trans_Pre','Point_Trace','Color_Grid_Pallet'],
 independent_check='Change one amplitude without changing either rate; predict the path’s extent, then compare a faster pass with repeated deposits at a place.',
 review_note='Both automatic and manual callers already reach draw_spray. Keep that shared operation rather than proposing another brush system. Its retained image spreads and fades; it is not permanent storage or a lossless list of strokes. UVs are introduced as two bounded surface coordinates; shader implementation comes later.',
 source_refs=['commons/context/drawingboard/ball_painting_automation.gd','commons/context/drawingboard/paper_draw_surface.gd','commons/context/drawingboard/spray_can.gd'],
 before='The plan required a second teaching brush and left the shared canvas connection unresolved.',
 after='Edit the existing automatic path. Both painters already use the same spray operation; distinguish accumulating, fading paint from a saved trace.',
 reason='Use the implemented encounter to teach one meaningful change, with less machinery.'),
dict(id='Color_Walls',
 storyboard='Walk the same route between panes in FILTER and OPAQUE modes: a chair disappears while the gaps stay. Bring colour assignment, surface geometry and transformed arrangements. Use the companion’s existing pane or palette edit to change one condition, keeping the other fixed. Alpha controls the contribution of the view behind a supplied transparent surface; the transparency mode, backing light and collision remain explicit support. Predict what can change in the view without changing passage, then walk around it. The RGB/HSV models and interpolation bench offer optional returns to coordinate choices. Carry palette separately from arrangement into Pattern_Disco. The office and assembly’s questions of privacy and who may rearrange a room need no further coding exercise.',
 storyboard_short='Use switchable panes and existing companion edit. Reuse materials/transforms/palette. Vary one pane angle or palette while other condition stays. Explain alpha; supply transparency/light/collision. Predict view versus passage. Carry palette separate from arrangement into Pattern_Disco. RGB/HSV models/interpolation optional; preserve privacy/authority questions. No new composition required. Open: companion spacing prose/code mismatch.',
 brings=['surface materials','spatial arrangement and colour assignment'], learns=['alpha as a contribution to appearance','appearance versus physical passage'],
 carries='A palette and arrangement that can be varied independently in the returning disco floor.',
 supplied=['transparency mode, light and collision','existing pane construction and optional gradient models'],
 prior_maps=['Color_Flashlight','Color_Pillar','Color_Paint','Tutorial_Tiling_Walls'],
 independent_check='Predict what changing one pane’s angle or palette does to the view, and which collision boundaries remain.',
 review_note='Preserve existing bounded edits and keep interpolation optional. Companion prose says try 0.18 while its spacing example uses 0.21; reconcile at the full-lesson pass. This summary revision does not alter that companion or the mature main text.',
 source_refs=['algorithms/color/color_mixing/color_constellation_office.gd','commons/artifacts/colour_wall_studies/study.gd'],
 before='The plan required composing two new panes despite useful edits already present in the companion.',
 after='Use an existing pane or palette edit. Keep view versus passage central and carry palette-versus-arrangement into Tiling.',
 reason='Preserve an accomplished ending without adding another required construction.')
]

def section_replace(path, section):
    txt=path.read_text(encoding='utf-8')
    pat=r'^## 4\. Color and Composition.*?(?=^## 5\.)'
    assert len(re.findall(pat,txt,re.M|re.S))==1,path
    new=re.sub(pat,lambda _:section.rstrip()+'\n\n',txt,flags=re.M|re.S)
    assert re.sub(pat,'',txt,flags=re.M|re.S)==re.sub(pat,'',new,flags=re.M|re.S)
    path.write_text(new,encoding='utf-8')

def main():
    p=ROOT/'doc/book/course/storyboards/early.json';data=load(p);old=copy.deepcopy(data)
    seq=next(s for s in data if s['sequence']=='color');before=copy.deepcopy(seq)
    assert [h['id'] for h in seq['halls']]==[h['id'] for h in UPDATES]
    changes=[]
    for h,u in zip(seq['halls'],UPDATES):
        for f in u['source_refs']:assert (ROOT/f).is_file(),f
        for mid in u['prior_maps']:assert (ROOT/'commons/maps'/mid).is_dir(),mid
        change={k:u[k] for k in ['id','before','after','reason']}
        h.update({k:v for k,v in u.items() if k not in ['before','after','reason']})
        h['change_reason']=u['reason'];change['title']=h['title'];changes.append(change)
    seq.update(arc=ARC,status='Revised teaching proposals; review each map before full lessons',tutorial_guidance='doc/book/course/storyboards/COLOUR.md')
    assert [s for s in old if s['sequence']!='color']==[s for s in data if s['sequence']!='color']
    save(p,data);save(OUT/'changes.json',changes)

    p=ROOT/'commons/maps/sequences/color.json';meta=load(p);meta_before=copy.deepcopy(meta);s=meta['sequences']['color']
    s['teaching_prerequisites']=['primitives','transformation','array_tutorial']
    s['teaching_prerequisites_note']='Tutorial continuity only. Runtime prerequisites and unlock requirements stay unchanged.'
    s['formula']='RGB = (r, g, b), each channel in [0, 1]; Godot HSV = (h, s, v), normalized to [0, 1], with hue 0 and 1 meeting around the circle. Individual exhibits may use narrower ranges.'
    s['learning_objectives_status']='Revised summary proposals; learner bindings and full companion revisions remain pending.'
    s['learning_objectives']=[
      'Assign palettes to familiar forms independently of placement; use an explained material receiver',
      'Vary an existing light while keeping its receiving surface fixed',
      'Write a bounded local-position-to-RGB function and distinguish its value from its appearance',
      'Optionally repartition a fixed span with a chosen nonempty palette; keep celebration available without a task',
      'Change the coordinate rule to HSV with an explicit hand-height adapter; separate field from samples',
      'Propose storing an earlier colour result at an addressed instance; distinguish selection, write and overwrite',
      'Alter the existing timed paint path and distinguish an evolving image from a lossless trace',
      'Use alpha and arrangement to compare visibility with physical passage; carry palette choices into Tiling']
    s.setdefault('local_review_history',[]).append(dict(date='2026-10-04',report='doc/book/iterations/2026-10-04-colour-capacity-return/index.html',decision='Concentrate on position-to-colour and storing its result; reuse existing lamps and automatic brush; Rainbow making optional. Eight separately reviewable summary proposals.',status='Proposed; no runtime, full tutorial or final text edits'))
    for key in ['maps','prerequisites','unlock_requirements','unlocks']:assert s[key]==meta_before['sequences']['color'][key]
    assert meta.get('artifact_groups')==meta_before.get('artifact_groups');save(p,meta)

    p=ROUTE/'route.json';route=load(p);oldroute=copy.deepcopy(route);by_id={h['id']:h for h in seq['halls']}
    for h in route['halls']:
        if h['sequence']=='color':h.update(by_id[h['id']])
    next(s for s in route['sequences'] if s['id']=='color')['arc']=ARC
    assert [h for h in route['halls'] if h['sequence']!='color']==[h for h in oldroute['halls'] if h['sequence']!='color']
    assert [h['id'] for h in route['halls']]==[h['id'] for h in oldroute['halls']];save(p,route)
    p=ROUTE/'index.html';page=p.read_text(encoding='utf-8');pat=r'(<script id="route-data" type="application/json">).*?(</script>)'
    assert len(re.findall(pat,page,re.S))==1
    p.write_text(re.sub(pat,lambda m:m[1]+json.dumps(route,ensure_ascii=False).replace('</','<\\/')+m[2],page,count=1,flags=re.S),encoding='utf-8')

    heading='## 4. Color and Composition';full=[heading,ARC,''];short=[heading,'']
    for h in seq['halls']:
        full += [f'### {h["id"]} — {h["title"]}',h['storyboard'],'','**Short AI alternative**',h['storyboard_short'],'',f'*For correction:* {h["review_note"]}','']
        short += [f'### {h["id"]}',h['storyboard_short'],'']
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS.md',ROUTE/'storyboards.md']:section_replace(p,'\n'.join(full))
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS_SHORT.md',ROUTE/'storyboards-short.md']:section_replace(p,'\n'.join(short))
    for p in [ROOT/'doc/book/course/storyboards/SEQUENCES.md',ROUTE/'sequences.md']:
        t=p.read_text(encoding='utf-8');a=t.index(heading);b=t.index('## 5.',a);lines=t[a:b].splitlines();lines[1]=ARC;section_replace(p,'\n'.join(lines))
    diff=[]
    for a,b in zip(before['halls'],seq['halls']):
        for key in ['title','mode','storyboard','storyboard_short','review_note']:
            diff.extend(difflib.unified_diff([a[key]+'\n'],[b[key]+'\n'],fromfile=b['id']+'/'+key+'/before',tofile=b['id']+'/'+key+'/after'))
    (OUT/'summaries.diff').write_text(''.join(diff),encoding='utf-8')
    for x in load(OUT/'unchanged-evidence-before.json'):
        assert hashlib.sha256((ROOT/x['path']).read_bytes()).hexdigest()==x['sha256'],x['path']
    save(OUT/'checks.json',dict(sequence='color',maps=8,other_route_halls_unchanged=len(route['halls'])-8,order_unchanged=True,other_authored_sequences_unchanged=True,other_markdown_sections_unchanged=True,runtime_gates_unchanged=True,finals_tutorials_map_data_unchanged=True,runtime_checked=False,learner_transfer_implemented=False))
    print('Updated eight Colour proposals; all other halls/order and 24 protected map documents unchanged.')

if __name__=='__main__':main()
