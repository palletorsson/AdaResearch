"""Revise Tiling summaries only; preserve the museum and full written tracks."""
from pathlib import Path
import copy, difflib, hashlib, json, re

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
ROUTE=ROOT/'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
ARC=('PROPOSED. Return to Arrays’ addressed values and Colour’s palette/receiver distinction. '
     'Choose a small source, then separate editing it from changing how another address reads it. '
     'Give repetition a physical scale, test a symmetry with a revealing mark, and let height enter '
     'the lookup. A reflective comparison keeps source equality separate from viewed appearance. '
     'Close with a tiny UV repeat-and-offset shader using the existing studio host. Keep source, '
     'palette, sampling rule, receiver and saved version distinct. Reusing a known motif is not '
     'automatic cross-hall transfer; full lessons and learner bindings remain proposed.')

UPDATES=[
dict(id='Pattern_Disco',
 storyboard='The familiar floor returns after Colour with two replaceable colours. Bring the earlier address rule and palette lookup; use the existing value_at result rather than making another floor or clock. With the floor held and sequencer stopped, change the pair that displays zero and one, then keep the pair while advancing one phase. Predict what stays related in each comparison. The floor receiver, controls and independent score remain supplied. The student carries the separation between a computed value and its displayed colour. The optional triangle comparison uses a different shader drawing, not one whole-cell zero or one; it can retain the palette question without becoming the opening shader lesson.',
 storyboard_short='Reuse existing value_at and Colour palette lookup. Hold floor/stop score; change colour pair, then phase alone. Predict unchanged relationships. Supply floor/controls/separate score clock. Carry value versus appearance. Triangle drawing optional and distinct from whole-cell values. No new floor/clock; reduced palette-edit entry still to be chosen.',
 learns=['a computed pattern value and its display palette can change independently'],
 carries='A known address rule with an independently chosen two-colour palette.',
 independent_check='Keep phase fixed and predict which cells change when one palette entry changes; then advance phase with that palette unchanged.',
 prior_maps=['Tutorial_Disco','Color_Context_Placed','Color_Walls'],
 source_refs=['commons/artifacts/regularity/disco_controls.gd','commons/context/discofloor/StandaloneDiscoFloor.gd'],
 review_note='Revisit the current two-colour lookup instead of requiring a new floor or timer. The production console chooses four prepared pairs; a learner-authored pair needs a named source-edit entry. Super Triangle is separately drawn by a shader.',
 before='The checker rule and palette were separated, but the plan could read as another construction exercise.',
 after='Reuse the existing floor rule. Change palette and phase separately; keep the triangle shader an optional comparison.',
 reason='Let Colour return through an operation the student already knows.'),
dict(id='Pattern_Foundry',
 storyboard='Begin with one off-centre pair in the small four-by-four tile and find its repeated appearances. Bring addressed writes and palette selection; let a source entry hold a palette index and let a wrapping lookup select that entry before its colour is assigned. The student predicts another copy from its address, then changes one source cell. Input controls and the image preview are supplied. Carry a small motif and its reader. On a return visit, copy the nested source explicitly and compare it with a live reference. The loom and architectural receivers remain further encounters: the loom has its own five-by-five card, HOLD retains a receiver image, and each SAVE acts on a stated source. These are not one shared learner record.',
 storyboard_short='Use one 4×4 tile. Reuse addressed writes/palette lookup. Teach source[row][column] palette indices, wrap address then choose colour. Predict a repeated pair after one edit. Supply input/image preview. Carry motif + reader. Optional return: independent nested copy versus live reference. Loom has separate 5×5 source; HOLD image differs from SAVE. Later teaching stations use fixed seeds.',
 learns=['palette-index source with wrapping lookup','optional independent copy versus live reference'],
 carries='A small indexed motif and its reader; an optional separately retained source copy.',
 supplied=['existing tile editor input and image preview','loom and architectural receiver controls for comparison'],
 independent_check='Choose an unseen preview address, predict its source entry and colour, then explain why editing that entry changes more than one appearance.',
 prior_maps=['Array','Color_Grid_Pallet','Pattern_Disco'],
 source_refs=['commons/primitives/arrays/pattern_tile_puzzle.gd','commons/artifacts/pattern_machine_a/recipe_study.gd'],
 review_note='One core source-and-reader study first; copy/history on a return visit. Use explicit row/column storage in the reduced example and show how it connects to the selected station. The small tile, five-by-five loom and fabric studio are distinct sources. Do not present a copied source array as the implementation of a held texture.',
 before='A four-by-four source, copying and the loom’s curved receivers were bundled into one lesson.',
 after='Start with one small motif and wrapping lookup. Move copying to a return visit; distinguish the tile, loom and held images.',
 reason='Reduce first-visit load without losing the richer questions of sharing and keeping.'),
dict(id='Tutorial_Pattern',
 storyboard='Follow the asymmetric bend through PM, then watch the source cells during FLIP X. Bring the motif and wrapping reader. First change only the read address: on alternate tile columns, reverse the source column while keeping the row. Then make a separate mirrored source by reversing entries inside each row; do not reverse the order of the rows. Displays, editor input and shader rendering are supplied. The student predicts where the coloured neighbour will appear and checks that only the second operation changes the stored source. A symmetric mark can conceal either reversal; altering one cell reveals it again. Carry two named operations, source editing and transformed reading, before considering any wider symmetry classification.',
 storyboard_short='Use PM versus FLIP X. Reuse motif/wrapping. Teach alternate-column reflected read without source mutation; separately reverse entries within each source row, not row order. Predict asymmetric neighbour; inspect unchanged versus changed source. Supply editor/displays/shader. Carry read transform versus data transform. Symmetric motif may hide the operation; shader authorship waits.',
 learns=['horizontal reflected lookup versus horizontal source reversal'],
 carries='Separate read-address and source-edit functions with a revealing test motif.',
 independent_check='Predict the blue neighbour’s position after each operation, then use a symmetric source to hide the reversal and one changed cell to reveal it.',
 prior_maps=['Pattern_Foundry','Trans_Rotation'],
 source_refs=['commons/artifacts/pattern_maker_station/fixed_motif_lesson.gd','commons/maps/Tutorial_Pattern/tutorial.md'],
 review_note='Keep the first reduced address operation in GDScript. “Reverse source rows” must mean reversing entries within every row, not swapping top and bottom rows. P1/PM displays are supplied; matching appearance alone cannot tell whether the source was mutated.',
 before='“Reversed source rows” left the direction of the source edit ambiguous.',
 after='Make horizontal reversal explicit: read columns backwards, or reverse entries within each row. Check which operation actually changes the source.',
 reason='Keep a visually similar result from concealing two different operations.'),
dict(id='Array_Patterns',
 storyboard='Enter the tunnel with its stated fixed four-by-four source; earlier edits have not travelled here. Bring wrapped lookup and named frames. Follow one marked floor address to its source, then derive the address from a position using a declared origin, surface axes and cell width in metres. On the right wall, columns run along the passage and rows descend; they are not the floor’s directions. The tunnel, collision, shader and face selector remain supplied. Predict that changing a cell from forty to sixty centimetres changes a four-cell motif from 1.6 to 2.4 metres, without enlarging the passage. Inspect the corner where counts restart. Carry the conversion and its units; importing a learner motif remains optional future work.',
 storyboard_short='Use fixed-source tunnel; no preceding-edit transfer. Reuse wrapped read/reference frames. Teach position→surface row/column with named origin/axes and metre cell width. Predict .4→.6 m cells means 1.6→2.4 m motif. Wall directions differ; corners restart. Supply tunnel/collision/shader/selector. Carry explicit surface conversion. Distinguish cell width from whole-repeat width; optional import remains unbuilt.',
 learns=['physical position to surface address','cell width versus whole motif width'],
 carries='A position-to-address conversion with explicit origin, axes and metre units.',
 independent_check='Predict the motif width for another cell width, then explain how one right-wall address maps to the source without using the floor axes.',
 prior_maps=['Point_Coordinates','Tutorial_Pattern','Tutorial_Tiling_Walls'],
 source_refs=['commons/artifacts/pattern_tunnel/tunnel_address_lesson.gd','commons/artifacts/pattern_tunnel/pattern_tunnel.gdshader'],
 review_note='The tunnel intentionally uses a fixed comparison source. Teach it as such rather than requiring an import to justify the hall. Other stations quote whole-repeat width; this control quotes one source cell. Check the selected face’s actual origin and axes before expanding code.',
 before='Physical cell size was included, but transfer and surface conventions stayed open.',
 after='Use the installed fixed motif and name each face’s directions. Distinguish one cell’s width from the width of the complete repeat.',
 reason='Give the same number an unambiguous unit and meaning.'),
dict(id='Symmetry_Seventeen',
 storyboard='Use the live and held panels to follow the same asymmetric mark through P1, PM and PG. Bring the reflected reader; on reflected alternate columns, add half the four-row source height and wrap to produce the installed glide comparison. The panels, source editor, image hold and wallpaper cage remain supplied. Predict two neighbouring source blocks before changing a mark. A generic reflected or glided arrangement needs two source blocks across its horizontal translation period, while a specially symmetric source can hide the operation or add further symmetries. Carry a motif that reveals a rule and a tested repeating unit. The seventeen-group classification and makers’ histories remain questions beyond what three buttons certify.',
 storyboard_short='Use P1/PM/PG live-held comparison. Reuse reflected reader; on alternate reflected blocks shift source row by two and wrap four. Predict adjacent blocks and generic two-block X period. Supply editor/panels/image hold/cage. Alter asymmetric mark to hide/reveal operation. Carry diagnostic motif + tested period. Keep classification/cultural history distinct; no proof of seventeen renderers.',
 learns=['glide lookup and its translation period','source symmetry can conceal a construction rule'],
 carries='A diagnostic motif and a repeating unit checked against more than one source block.',
 independent_check='Predict the mark in two adjacent blocks, locate a horizontal translation that repeats the result, then see what changes when the source becomes symmetric.',
 prior_maps=['Tutorial_Pattern','Array_Patterns'],
 source_refs=['commons/primitives/arrays/wallpaper_groups.gd','commons/primitives/arrays/symmetry_compare_lesson.gd'],
 review_note='For the current even-height four-row source the glide shifts by two rows; do not silently generalise that discrete recipe to odd heights. A source block is not necessarily the whole field’s translation unit. The selected renderer name is not a proof of the resulting pattern’s complete symmetry group.',
 before='The glide was described, but a source block could still be mistaken for its full repeating unit.',
 after='Inspect two neighbouring blocks and test the translation period. Keep the seventeen-group claim separate from this bounded comparison.',
 reason='Make the limit of the demonstrated rule as clear as its visible effect.'),
dict(id='Ribbon_Patterns_01',
 storyboard='The marked source and selected volume cube let the student follow one lookup through height. Bring the earlier volume convention, values[y][z][x], and explicitly name the source plane SOURCE[z][x]. Repeat the source through four layers, then let the layer index shift its source column: SOURCE[z][(x+y)%4]. Predict a selected address before using its marker. Cube creation, selection and slicing are supplied. Turning SLICE on hides forty-eight of the sixty-four stored values; the comparison changes visibility without deleting entries. Zero now selects a pale colour, not vacancy. Carry the layer-dependent reader and these declared meanings. The familiar starting motif returns as installed data, not a claim that a previous edit was imported.',
 storyboard_short='Reuse volume[y][z][x]; source plane is SOURCE[z][x]. Repeat then shift lookup SOURCE[z][(x+y)%4]. Predict unequal indices before marker check. Supply cubes/selection/slicing. SLICE:16 visible,64 stored; zero=pale colour, not absence. Carry layer reader and value meaning. Fixed familiar motif, no previous-edit import. Missing full companion remains to write.',
 learns=['layer-dependent source lookup in an explicit storage convention','visibility distinct from stored values'],
 carries='A volume reader with declared palette-index values and nondestructive slice views.',
 independent_check='For x=3,y=2,z=1, predict source [1][1]; change only the displayed slice and explain why no stored entry should change.',
 prior_maps=['Tutorial_3D','Pattern_Foundry','Symmetry_Seventeen'],
 source_refs=['algorithms/arrays/layer_pattern_lesson.gd'],
 review_note='Preserve the YZX storage convention from the flight volume while explicitly changing values from occupancy to palette indices. The source uses ZX. Supplied rendering and selectors are not new learning prerequisites. tutorial.md is absent; this remains a plan.',
 before='The height shift and slicing were clear, but the storage convention was implicit.',
 after='Name source [z][x] and volume [y][z][x], then predict one shifted lookup. Keep zero-as-colour distinct from earlier occupancy.',
 reason='Reuse the earlier volume knowledge without silently changing what its values mean.'),
dict(id='Ribbon_Patterns_02',
 storyboard='Keep the grey targets numerically equal while their surrounds change; there is no required perceptual answer. Bring colour values and surface addresses, then compare the same motif on a flat sheet and a curve of equal surface width. Hold the source and repeat size fixed while changing one surround, carrier or supplied shading condition. Record the equality the code guarantees separately from what appears equal from the current viewpoint. Arc length need not equal projected width. The dot-product lighting model and controls stay supplied, with the operation taught later in Forces. This hall carries a method of comparison into the studio, not a new shader assignment. Its artifact name does not establish a spectral metamerism experiment.',
 storyboard_short='Keep reflective comparison. Equal target values, changed surrounds; same source and surface spacing, flat/curved carriers. Separate numerical equality, arc length and projected appearance. Supply controls and dot-product shading; teach operation later. No required perceptual result or new code. Carry controlled comparison to studio; no spectral-metamerism claim.',
 learns=['state exactly which equality a controlled comparison preserves'],
 carries='A comparison that separates stored equality, surface distance and viewed appearance.',
 independent_check='Optional reflection: name one condition held fixed and one changed, then distinguish the program’s equality from your observation.',
 prior_maps=['Color_Flashlight','Color_Pillar','Ribbon_Patterns_01'],
 source_refs=['algorithms/color/carrier_comparison.gd'],
 review_note='Retain the reflective mode. Equal physical repeat spacing here differs from equal UV repeat counts on differently sized studio receivers. No new code or dot-product prerequisite is added. Equal arc length is not equal projected width; the shader’s direction control is not a moved museum sun. tutorial.md is absent, but a short comparison companion is enough.',
 before='The reflective comparison already worked well.',
 after='Keep it. Clarify equal surface distance versus apparent width; leave the lighting calculation supplied and require no perceptual answer.',
 reason='Allow the sequence to deepen attention without adding more programming.'),
dict(id='Ribbon_Patterns_03',
 storyboard='Begin with the existing studio wall and preview skirt sharing a motif. Bring wrapping lookup and surface addresses into a small first shader: multiply mesh UV by repeat counts, add an offset, then sample the supplied texture into ALBEDO. The declared host turns four-by-four palette indices into a nearest-filtered, repeating texture and assigns materials; garment meshes and wardrobe remain supplied. Write and explain the reduced fragment calculation before comparing repeat and offset separately. UV repeats are counts per mesh, not metre spacing. Use the existing SAVE and WEAR SAVED flow to compare live edits with a stored recipe. That file saves bounded cells and settings, not arbitrary shader code. Carry this small sampling vocabulary to Shaders; cut-out, finish and deformation remain optional encounters.',
 storyboard_short='Use existing studio wall/skirt host. Teach tiny fragment: UV×repeat+offset → repeating nearest texture → ALBEDO. Supply palette-index→texture conversion, material assignment, meshes/wardrobe. Predict repeat versus offset; UV counts are not metres. SAVE stores bounded cells/settings; WEAR explicitly applies snapshot to Skirt. No shader-code export or general garment transfer. Cut-out/finish/deformation optional; full companion absent.',
 learns=['first shader sampling with an explained texture/material host','mesh UV repeat counts versus physical spacing','saved recipe data versus shader implementation'],
 carries='A small repeat-and-offset sampling operation plus a clearly bounded saved appearance recipe.',
 supplied=['Recipe.material: palette indices to texture and shader uniforms','existing wall and preview skirt material assignment','wardrobe, saving and supported Skirt receiver'],
 independent_check='Predict what doubling horizontal repeats does while offset stays fixed, then shift offset without changing the count. Save a supported recipe, edit the live source and predict which skirt changes.',
 prior_maps=['Pattern_Foundry','Array_Patterns','Ribbon_Patterns_02'],
 source_refs=['commons/artifacts/fabric_shader_studio/fabric.gdshader','commons/artifacts/fabric_shader_studio/fabric_recipe.gd','commons/artifacts/fabric_shader_studio/fabric_shader_studio.gd'],
 review_note='Use existing Recipe.material and studio.refresh as the explained host. Current SAVE accepts repeats 4/8 and offset 0/.125 plus supported cells/settings; it excludes palette, shader code, meshes and LOOK. The current preview silhouette is chosen separately on wear. Select the reduced fragment excerpt and exact learner edit location before the full lesson; no new host is needed. All three Ribbon tutorial.md files are absent. Do not require finish or vertex deformation before the later Shaders sequence.',
 before='A tiny shader was proposed, but its host and what SAVE could carry were left open.',
 after='Name the existing texture/material host. Teach repeat, offset and sampling only; distinguish saved recipe data from shader code and metre spacing.',
 reason='Give the sequence a small, usable shader ending without implying the whole studio must be rebuilt.')
]

def replace_section(path,section):
    t=path.read_text(encoding='utf-8');pattern=r'^## 5\. Patterns: Dress the Architecture.*?(?=^## 6\.)'
    assert len(re.findall(pattern,t,re.M|re.S))==1,path
    after=re.sub(pattern,lambda _:section.rstrip()+'\n\n',t,flags=re.M|re.S)
    assert re.sub(pattern,'',t,flags=re.M|re.S)==re.sub(pattern,'',after,flags=re.M|re.S)
    path.write_text(after,encoding='utf-8')

def main():
    p=ROOT/'doc/book/course/storyboards/early.json';data=load(p);old=copy.deepcopy(data)
    seq=next(s for s in data if s['sequence']=='tiling')
    before=next(s for s in load(OUT/'before/doc/book/course/storyboards/early.json') if s['sequence']=='tiling')
    assert [h['id'] for h in seq['halls']]==[h['id'] for h in UPDATES]
    changes=[]
    for h,u in zip(seq['halls'],UPDATES):
        for path in u['source_refs']:assert (ROOT/path).is_file(),path
        for mid in u['prior_maps']:assert (ROOT/'commons/maps'/mid).is_dir(),mid
        h.update({k:v for k,v in u.items() if k not in ['before','after','reason']});h['change_reason']=u['reason']
        changes.append(dict(id=h['id'],title=h['title'],**{k:u[k] for k in ['before','after','reason']}))
    seq.update(arc=ARC,status='Revised teaching proposals; review each map before full lessons',tutorial_guidance='doc/book/course/storyboards/TILING.md')
    assert [s for s in data if s['sequence']!='tiling']==[s for s in old if s['sequence']!='tiling']
    save(p,data);save(OUT/'changes.json',changes)
    p=ROOT/'commons/maps/sequences/tiling.json';meta=load(p);bmeta=copy.deepcopy(meta);s=meta['sequences']['tiling']
    s['learning_objectives_status']='Revised summary proposals; full Ribbon companions and reduced learner bindings remain pending.'
    s['learning_objectives']=[
      'Reuse addressed pattern values with a replaceable palette and independent clocks',
      'Read a small palette-index source through wrapped addresses; distinguish source copies, held images and saved recipes',
      'Separate a reflected read from reversing entries within each stored row',
      'Explain face axes, cell width and full motif width; distinguish physical metres from normalized UV counts',
      'Test reflection and glide across their repeating unit without claiming a full wallpaper-group proof',
      'Use a layer index in a palette lookup while separating stored data from slice visibility',
      'Compare fixed values across carriers and viewing conditions without prescribing perception',
      'Write a tiny repeat-and-offset texture sample in a supplied studio host; state exactly what its saved recipe can transfer']
    report='doc/book/iterations/2026-10-04-tiling-capacity-return/index.html'
    s['local_review_history']=[h for h in s.get('local_review_history',[]) if h.get('report')!=report]
    s['local_review_history'].append(dict(date='2026-10-04',report=report,decision='Separate sources and storage scopes; preserve reflective comparisons; close with a bounded UV sampling lesson in the existing studio.',status='Proposed summaries only; no runtime or full companion changes'))
    for k in ['maps','prerequisites','artifact_groups']:assert s[k]==bmeta['sequences']['tiling'][k]
    save(p,meta)
    p=ROUTE/'route.json';route=load(p);broute=copy.deepcopy(route);byid={h['id']:h for h in seq['halls']}
    for h in route['halls']:
        if h['sequence']=='tiling':h.update(byid[h['id']])
    next(s for s in route['sequences'] if s['id']=='tiling')['arc']=ARC
    assert [h for h in route['halls'] if h['sequence']!='tiling']==[h for h in broute['halls'] if h['sequence']!='tiling']
    assert [h['id'] for h in route['halls']]==[h['id'] for h in broute['halls']];save(p,route)
    p=ROUTE/'index.html';t=p.read_text(encoding='utf-8');pat=r'(<script id="route-data" type="application/json">).*?(</script>)'
    assert len(re.findall(pat,t,re.S))==1
    p.write_text(re.sub(pat,lambda m:m[1]+json.dumps(route,ensure_ascii=False).replace('</','<\\/')+m[2],t,count=1,flags=re.S),encoding='utf-8')
    heading='## 5. Patterns: Dress the Architecture';full=[heading,ARC,''];short=[heading,'']
    for h in seq['halls']:
        full += [f'### {h["id"]} — {h["title"]}',h['storyboard'],'','**Short AI alternative**',h['storyboard_short'],'',f'*For correction:* {h["review_note"]}','']
        short += [f'### {h["id"]}',h['storyboard_short'],'']
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS.md',ROUTE/'storyboards.md']:replace_section(p,'\n'.join(full))
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS_SHORT.md',ROUTE/'storyboards-short.md']:replace_section(p,'\n'.join(short))
    for p in [ROOT/'doc/book/course/storyboards/SEQUENCES.md',ROUTE/'sequences.md']:
        t=p.read_text(encoding='utf-8');a=t.index(heading);b=t.index('## 6.',a);lines=t[a:b].splitlines();lines[1]=ARC;replace_section(p,'\n'.join(lines))
    diff=[]
    for a,b in zip(before['halls'],seq['halls']):
        for key in ['title','storyboard','storyboard_short','review_note']:
            diff.extend(difflib.unified_diff([a[key]+'\n'],[b[key]+'\n'],fromfile=b['id']+'/'+key+'/before',tofile=b['id']+'/'+key+'/after'))
    (OUT/'summaries.diff').write_text(''.join(diff),encoding='utf-8')
    for x in load(OUT/'unchanged-evidence-before.json'):assert hashlib.sha256((ROOT/x['path']).read_bytes()).hexdigest()==x['sha256'],x['path']
    save(OUT/'checks.json',dict(sequence='tiling',maps=8,other_route_halls_unchanged=len(route['halls'])-8,order_unchanged=True,other_authored_sequences_unchanged=True,other_markdown_sections_unchanged=True,finals_tutorials_map_data_unchanged=True,runtime_checked=False))
    print('Eight Tiling proposals updated; other sequences, order and full map documents preserved.')

if __name__=='__main__':main()
