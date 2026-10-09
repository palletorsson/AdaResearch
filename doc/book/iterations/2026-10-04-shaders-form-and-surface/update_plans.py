"""Apply the authored Shader summary revision; preserve all other route content."""
from pathlib import Path
import copy
import difflib
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
ROUTE = ROOT / 'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'

def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def backup(path):
    saved = OUT / 'before' / path.relative_to(ROOT)
    if not saved.exists():
        saved.parent.mkdir(parents=True, exist_ok=True)
        saved.write_bytes(path.read_bytes())

def save(path, value):
    backup(path)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def ref(chapter, title, purpose):
    return dict(title='The Book of Shaders — ' + title,
                url=f'https://thebookofshaders.com/{chapter:02}/', purpose=purpose)

BOS = 'algorithms/shaders/book_of_shaders/'
ARC = ('PROPOSED. Familiar forms acquire new ways of appearing. Deepen the garment studio’s '
       'first shader use: construct a form from a coordinate rule, transform and repeat it, '
       'compare its material on different primitive bodies, then alter it with a layered field. '
       'Compose these choices before asking what an image must retain to evolve. Keep the '
       'existing images → bodies → rooms route. The learner carries a small form function and '
       'its settings; museum bindings and transport remain proposed until implemented.')

UPDATES = [
    dict(id='Shader_01_Shaping', title='Give a familiar form a surface rule', mode='make',
         storyboard='At the graph panels, the student returns to the point, distance and the boundary of a face. Bringing coordinates, functions, colour mapping and the garment studio’s first shader, they make one circular mark from distance to a chosen centre. A threshold turns that distance into an inside and an outside; a narrow transition softens the visible edge. The existing graphs explain the rule. The panel, material binding and coordinate display are supplied. The student changes centre and radius independently, then explains why the mark moved while the panel did not. They carry a small mask function and its parameters. A band or box is a later variation; the timed graph remains a comparison, not a second opening lesson.',
         storyboard_short='Use graph panels to explain a circular mark. Reuse point distance, functions, colour mapping and garment UVs. Teach coordinate → distance → mask; expose centre/radius and compare sharp/soft edge. Supply panel/material binding. Check: move centre without changing radius; explain unchanged mesh. Carry mask + settings. Optional band/box; defer clock analysis. Open: learner binding; softened edge needs valid bounds.',
         brings=['point, distance and face boundary', 'functions and colour mapping', 'Ribbon_Patterns_03: supplied UVs and sampled material'],
         learns=['distance-to-mask rule', 'uniforms for centre and radius', 'visible boundary versus mesh geometry'],
         carries='One small mask function, declared UV frame, centre, radius and edge width',
         supplied=['existing panel and graph display', 'named material binding and UV display'],
         prior_maps=['Point_One','Point_Coordinates','Point_Lines','Point_Triangle_Context','Primitives_Columns','Color_Grid_Pallet','Ribbon_Patterns_03'],
         independent_check='Choose another centre without changing the radius. Predict the mark’s position and explain why neither the panel mesh nor its collision moved.',
         critical_question='Which decision turns a difference in distance into an inside and an outside?',
         source_refs=[BOS+'shader_01_shaping.gd',BOS+'shaping_step.gdshader',BOS+'shapes_circle.gdshader',BOS+'shapes_rect.gdshader','commons/artifacts/fabric_shader_studio/fabric_recipe.gd'],
         tutorial_references=[ref(3,'Uniforms','Name the input shared by fragment evaluations.'),ref(5,'Shaping functions','Relate a threshold and transition to the boundary of a form.'),ref(7,'Shapes','Use distance and masks to construct a mark.')],
         review_note='The existing hall displays graphs. The learner mask and its host connection are proposed; the deferred Shapes sources provide the operation, not an installed new station. Keep one main form. Use step for a hard edge and ordered, distinct smoothstep bounds for softness. Verify the actual phase-speed control before expanding the clock comparison.'),
    dict(id='Shader_05_Patterns', title='Transform the form inside its address', mode='make',
         storyboard='The tiled squares return to the earlier floor and garment, where a pattern already depended on how it was sampled. The student brings the retained mask, transforms and array addresses. They first offset and turn a band or asymmetric version of the mark around a named centre, then repeat it in a four-by-four study. The integer tile address chooses a variation; the fractional coordinate evaluates the form inside that tile. One chosen tile turns while the rest keep their orientation. They carry the mask, coordinate transform and address rule as separate parts. The garden offers a further comparison: its supplied world projection lets a pattern cross several bodies. Moving the learner’s function there needs an explicit adapter that preserves that projection.',
         storyboard_short='Use tiled panels; return to floor/garment sampling. Reuse mask, transforms and array addresses. Offset/turn an asymmetric mark, then repeat 4×4. Teach floor = tile ID; fract = local coordinate. Check: turn one tile only. Carry mask + transform + address rule. Supply host; garden projection stays world-based. Open: binding/transfer adapter. Deferral: no new Shapes/Matrices halls.',
         brings=['retained mask function', 'translation, rotation and scale about a centre', 'array addresses and earlier floor/garment sampling'],
         learns=['coordinate transformation before evaluation', 'tile address versus local coordinate', 'variation selected by address'],
         carries='The retained form plus a transform and a tile-address rule',
         supplied=['existing pattern display and parameter host', 'garden’s world projection and blending'],
         prior_maps=['Trans_Translation','Trans_Rotation','Trans_Scale','Array','Tutorial_Tiling_Floor','Tutorial_Tiling_Walls','Ribbon_Patterns_03','Shader_01_Shaping'],
         independent_check='Choose one address in a four-by-four field and turn its asymmetric motif. Keep the other fifteen unchanged; explain which calculation selects the tile and which draws its mark.',
         critical_question='What can remain particular when every appearance is evaluated from a shared rule?',
         source_refs=[BOS+'shader_05_patterns.gd',BOS+'matrices_translate.gdshader',BOS+'matrices_rotate.gdshader',BOS+'matrices_scale.gdshader',BOS+'patterns_tile.gdshader',BOS+'patterns_truchet.gdshader','commons/artifacts/reference_studies/pattern.gdshader'],
         tutorial_references=[ref(8,'Matrices','Transform the sampling coordinate around an explicit centre.'),ref(9,'Patterns','Separate cell selection from the local form rule.')],
         review_note='A centred circle cannot reveal rotation: use a band or asymmetric mark for that comparison. Earlier tilings already use images and shaders. The current tile source draws a faint border; narrow the manuscript’s contrary claim in a later prose pass. The garden uses world triplanar mapping, not each object’s UVs. MODE/RESET rebuild materials; a future adapter must reconnect.'),
    dict(id='Shader_11_QueerRubber', title='Let one material meet different bodies', mode='make',
         storyboard='The black ring catches a rainbow rim while the larger primitive bodies answer the lamps. The student returns to the faceted sphere, the garment’s curved receiver and the distinction between moving an object and moving around it. They compare one proposed teaching material on a sphere and a cube before adding a rim from supplied normal and view vectors in the same frame. Dot products now become an appearance. Keeping the material fixed, they change the body or viewpoint and account for the difference. They carry a material whose receiver matters. The existing leather, plastic and oil-like appearances remain available for looking and interpretation; the lesson does not require rebuilding all of them.',
         storyboard_short='Use ring and staged primitives. Reuse faceted sphere, curved garment, transforms, dot product and retained material. Compare one material on sphere/cube; teach rim from unit normal/view vectors in one frame. Check: predict changed rim with body/viewpoint changed and material fixed. Carry receiver-aware material. Supply geometry/vectors/lamps. Open: shared-material and hold controls absent; emission is not a lamp.',
         brings=['primitive surfaces and garment receivers', 'object rotation versus viewer movement', 'dot products and a retained material'],
         learns=['surface normals and view vectors in a common frame', 'view-dependent rim response'],
         carries='The retained material with a rim rule and a declared receiver',
         supplied=['existing primitive bodies and lamps', 'surface/view vectors and material connection'],
         prior_maps=['Primitives_Ignorance','Primitives_Godot','Trans_Rotation','Color_Flashlight','Ribbon_Patterns_03','VFM_02_Operations','Shader_05_Patterns'],
         independent_check='Hold the material settings fixed. Predict which rim will change when the camera moves or the receiver changes from sphere to cube, and distinguish that change from the lamp highlight.',
         critical_question='What makes a computed surface read as softness, leather, display or desire?',
         source_refs=[BOS+'shader_11_queerrubber.gd','algorithms/shaders/queer_materials/pop_plastic.gdshader','commons/artifacts/fabric_shader_studio/fabric.gdshader'],
         tutorial_references=[dict(title='Godot 4.6 — Spatial shaders',url='https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html',purpose='Check the actual normal/view frame and material outputs in the Godot host.')],
         review_note='The hall already supports several primitive body types, but does not provide a shared learner material switch or rotation-hold controls. Those are proposed adapter work. Preserve material associations as interpretation; do not claim simulated fibres, physical optics or a light cast on other bodies by EMISSION alone.'),
    dict(id='Shader_09_FBM', title='Let a field enter the form', mode='make',
         storyboard='The student crosses the glass above the moving basin, then returns to the noise panels with the form function they have kept. Noise and weighted sums are familiar; here a finite shader loop combines a few scales with separate frequency and amplitude updates. A bounded contribution disturbs the mask’s boundary while the panel mesh stays fixed. Compare no disturbance with the chosen amount before adding time. The student changes the finest contribution while retaining the broad form and explains the difference. They carry a field function and its range. The basin’s vertex displacement and normal construction are supplied comparisons: its surface moves, but the glass is what carries the visitor.',
         storyboard_short='Use noise panels and glass-covered basin. Reuse mask, weighted sums and Noise. Teach bounded octave loop; keep frequency/amplitude separate. Perturb mask boundary; compare zero contribution before adding time. Check: change fine detail while retaining broad form. Carry field + range. Supply base noise/material host and basin displacement/normals. Glass supplies support. Defer vertex teaching; coordinate warp optional.',
         brings=['retained form and material', 'Noise fields and weighted sums', 'rendered surface versus physical support'],
         learns=['finite octave accumulation in the shader', 'bounded field contribution to a mask boundary'],
         carries='A finite layered field that can alter the retained form’s appearance',
         supplied=['base noise function and material host', 'basin mesh, displacement, normals and independent support'],
         prior_maps=['WaveFunctions_Synthesis_Lab','Noise_Space_10','Noise_Perlin_Simplex','Shader_01_Shaping','Shader_11_QueerRubber'],
         independent_check='Change the contribution of a fine noise scale while keeping the broad mark and its centre recognizable. Identify whether the edit changed colour, sampling coordinates or mesh vertices.',
         critical_question='Which construction makes the moving surface visible, and which makes the crossing possible?',
         source_refs=[BOS+'shader_09_fbm.gd',BOS+'fbm_basic.gdshader',BOS+'fbm_domain_warp.gdshader','commons/artifacts/basin_water'],
         tutorial_references=[ref(11,'Noise','Return to the field already studied; supply its generator.'),ref(13,'Fractal Brownian Motion','Accumulate finite scales; treat coordinate warping as an extension.')],
         review_note='The retained mask-to-field connection is proposed. The mask changes fragment colour, not mesh geometry; coordinate warping is optional. Keep water’s vertex displacement supplied. More octaves do not guarantee visible improvement and do add work; choose a bounded count suitable for the material.'),
    dict(id='Shader_12_PinkExtravaganza', title='Compose a body and its appearance', mode='reflect',
         storyboard='Among the pink water, sagging sphere and plural body, the student chooses an arrangement worth keeping. They bring the form, repetition, rim and layered field developed here, together with Melencolia’s earlier work of composition. Choosing a supplied body, they combine a limited set of those operations and record what each contributes. One alternate version keeps the geometry but changes its appearance. They distinguish whole-object transformation, supplied vertex deformation and fragment colour. The outcome is a material recipe with reasons for its choices, not a new compulsory technique. The room’s associations remain open: which setting is a default, and who gets to call its appearance excessive?',
         storyboard_short='Use pink water, sagging sphere and plural body. Reuse Melencolia composition + retained form, repetition, rim and field. Compose limited known effects on supplied body; record choices. Check: make an alternate appearance with geometry fixed; distinguish transform/vertex/fragment. Carry material recipe. Supply lamps/geometry/deformation. Open: composition binding absent. No new compulsory syntax; pink alone is not a theory of queerness.',
         brings=['Melencolia’s composition with available forms', 'retained mask, pattern, rim and field', 'transforms and supplied deformation'],
         learns=['deliberate composition and comparison with known operations'],
         carries='An editable material recipe, receiver choice and an alternate version',
         supplied=['existing bodies, assemblage and lamps', 'vertex deformation and material host'],
         prior_maps=['Primitives_Melencolia','Primitives_Profiles','Trans_Scale','Color_Context_Placed','Shader_05_Patterns','Shader_11_QueerRubber','Shader_09_FBM'],
         independent_check='Make two appearances for the same geometry. State the few changed inputs and the effect each was meant to produce; account for what the existing lighting still contributes.',
         critical_question='Who gets to call an appearance excessive, and how did the chosen defaults acquire that meaning?',
         source_refs=[BOS+'shader_12_pinkextravaganza.gd','commons/artifacts/reference_studies/plural_body.gd','commons/artifacts/reference_studies/skin.gdshader'],
         tutorial_references=[ref(7,'Shapes','Return to a form already owned by the learner.'),ref(9,'Patterns','Use variation as a compositional choice, not a fresh prerequisite.')],
         review_note='A material-composition adapter remains proposed. The existing unfolding controls do not implement that task. This room can build judgment with known tools; do not impose another algorithm or treat pink as sufficient queer content.'),
    dict(id='Shader_10_ReactionDiffusion', title='Ask what the form must remember', mode='reflect',
         storyboard='The green panel asks for a previous texture it does not receive. Beside it, branching frost looks grown without retaining that growth. The student brings the form recomputed from coordinates, Paint’s retained image and earlier old-state/new-state updates. They trace which inputs produce each picture, then sketch what would have to be stored for a changed mark to affect the next update. Restarting a clock and restoring a saved state become different operations. They carry this explicit state contract into Cellular Automata. The existing panels and texture-reading excerpts are supplied; this reflective threshold does not require repairing the exhibit or claim that its missing feedback already works.',
         storyboard_short='Use green panel and apparently grown frost. Reuse retained form, Paint history and old/new state. Trace inputs; name what a changed mark must leave for next update. Check: explain clock restart versus state restore. Carry old-state → rule → new-state contract into CA. Supply panels/texture-reading excerpts. Host lacks previous-frame feedback; no promise of evolving chemistry or implemented transport.',
         brings=['coordinate-driven form and time', 'Color_Paint retained image', 'separate previous and next state'],
         learns=['feedback requires a retained, connected input'],
         carries='An explicit old-state → rule → new-state contract for Cellular Automata',
         supplied=['existing panels', 'shader excerpts and texture-reading function'],
         prior_maps=['Point_Trace','Color_Paint','WaveFunctions_3D_Wave_Propagation','Shader_09_FBM'],
         independent_check='Explain why restarting TIME can reproduce a coordinate-driven image but does not restore the history of a stateful simulation. Name the missing input in the existing panel.',
         critical_question='What history can this appearance justify claiming?',
         source_refs=[BOS+'shader_10_reactiondiffusion.gd','commons/resourses/shaders/reaction_diffusion.gdshader',BOS+'dla_visual.gdshader'],
         tutorial_references=[],
         review_note='The host does not bind the previous-frame texture. Preserve this honest threshold. The Book of Shaders contents lists simulation topics, but the linked chapters used here do not supply a finished Godot reaction-diffusion lesson.'),
]

def replace_section(path, section):
    text = path.read_text(encoding='utf-8')
    pattern = r'^## 12\. Shaders:.*?(?=^## 13\.)'
    assert len(re.findall(pattern, text, flags=re.M | re.S)) == 1, path
    updated = re.sub(pattern, lambda _: section.rstrip() + '\n\n', text, flags=re.M | re.S)
    backup(path)
    path.write_text(updated, encoding='utf-8')
    assert re.sub(pattern, '', text, flags=re.M | re.S) == re.sub(pattern, '', updated, flags=re.M | re.S)

def main():
    plans_path = ROOT / 'doc/book/course/storyboards/growth.json'
    plans = load(plans_path)
    prior_plans = copy.deepcopy(plans)
    shader = next(s for s in plans if s['sequence'] == 'shaders')
    old_halls = copy.deepcopy(shader['halls'])
    assert [h['id'] for h in old_halls] == [h['id'] for h in UPDATES]
    shader['arc'] = ARC
    for hall, update in zip(shader['halls'], UPDATES):
        hall.update(update)
    shader['tutorial_guidance'] = 'doc/book/course/storyboards/SHADERS.md'
    shader['status'] = 'Revised teaching proposal; not expanded lessons or implemented learner adapters'
    assert [s for s in plans if s['sequence'] != 'shaders'] == [s for s in prior_plans if s['sequence'] != 'shaders']
    for h in UPDATES:
        for p in h['source_refs']:
            assert (ROOT / p).exists(), p
        for p in h['prior_maps']:
            assert (ROOT / 'commons/maps' / p).is_dir(), p
    save(plans_path, plans)

    sequence_path = ROOT / 'commons/maps/sequences/shaders.json'
    sequence = load(sequence_path)
    original = copy.deepcopy(sequence)
    meta = sequence['sequences']['shaders']
    meta['truth'] = 'A familiar form can be evaluated as a surface rule. Coordinates, material, light and viewpoint affect its appearance; mesh geometry, collision and retained state remain distinct constructions.'
    meta['qfep_connection'] = 'Earlier coordinates, forms, arrays and fields return as choices inside a material. The learner locates where each choice changes an appearance, a body or a record. Re-evaluating from coordinates and a clock differs from updating from retained state; the final hall makes that missing connection explicit before Cellular Automata.'
    meta['formula'] = 'surface sample → form rule → material response; retained state requires a connected input'
    meta['description'] = 'Six existing halls move from wall images to staged bodies and rooms: graph functions, coordinate patterns, material responses on primitives, layered fields and a glass-covered basin, pink compositions, then a panel whose previous-state input is missing. The proposed tutorial carries a small form rule through these encounters, drawing on earlier sequences and The Book of Shaders.'
    meta['learning_objectives_status'] = 'Proposed tutorial progression; learner adapters and cross-hall transfer are not yet verified.'
    meta['learning_objectives'] = [
        'Reuse point distance and colour mapping to construct a mask, keeping its visible boundary distinct from the panel mesh',
        'Transform a sampling coordinate and separate tile address from local position to vary one repeated form',
        'Compare one material on different primitive bodies and distinguish normal/view response from received light',
        'Use a finite layered field to change appearance while identifying the separate construction that supports the visitor',
        'Compose known material operations and explain an alternate appearance without adding a compulsory new technique',
        'Distinguish clock-driven re-evaluation from retained-state feedback and identify the missing previous input before Cellular Automata',
    ]
    meta['content'] = [
        'Shader_01_Shaping: existing graph panels; proposed return to point, distance and boundary as a small surface mask',
        'Shader_05_Patterns: existing coordinate tilings and world-projected garden; proposed transforms and address-selected variation of the retained form',
        'Shader_11_QueerRubber: existing staged primitive bodies; proposed comparison of a shared material and its view-dependent rim',
        'Shader_09_FBM: existing layered fields and basin under glass; proposed finite field applied to the retained form',
        'Shader_12_PinkExtravaganza: existing pink materials and plural body; proposed composition with known operations and a declared receiver',
        'Shader_10_ReactionDiffusion: previous-state texture is unbound and frost retains no growth; reflective handoff to Cellular Automata',
    ]
    meta['deferred_reason']['Shader_03_Shapes'] = 'Reuse selected mask functions inside Shaping; keep the full gallery deferred.'
    meta['deferred_reason']['Shader_04_Matrices'] = 'Return to earlier transforms through sampling coordinates inside Patterns; keep the full gallery deferred.'
    meta.setdefault('local_review_history', []).append({
        'date': '2026-10-04',
        'scope': 'Form-based tutorial summaries and references',
        'decision': 'Keep six halls and images → bodies → rooms. Carry a familiar form through masks, transforms, repetition, materials and fields. Read The Book of Shaders as a reference, adapting explicitly to Godot.',
        'guide': 'doc/book/course/storyboards/SHADERS.md',
        'status': 'Teaching proposal updated; museum logic, map order and full manuscripts unchanged.',
    })
    assert meta['maps'] == original['sequences']['shaders']['maps']
    save(sequence_path, sequence)

    route_path = ROUTE / 'route.json'
    route = load(route_path)
    old_route = copy.deepcopy(route)
    updates = {h['id']: h for h in shader['halls']}
    for h in route['halls']:
        if h['sequence'] == 'shaders':
            h.update(updates[h['id']])
    next(s for s in route['sequences'] if s['id'] == 'shaders')['arc'] = ARC
    assert [h for h in route['halls'] if h['sequence'] != 'shaders'] == [h for h in old_route['halls'] if h['sequence'] != 'shaders']
    assert [h['id'] for h in route['halls']] == [h['id'] for h in old_route['halls']]
    save(route_path, route)
    page_path = ROUTE / 'index.html'
    page = page_path.read_text(encoding='utf-8')
    payload = json.dumps(route, ensure_ascii=False).replace('</', '<\\/')
    pattern = r'(<script id="route-data" type="application/json">).*?(</script>)'
    assert len(re.findall(pattern, page, re.S)) == 1
    backup(page_path)
    page_path.write_text(re.sub(pattern, lambda m: m[1]+payload+m[2], page, count=1, flags=re.S), encoding='utf-8')

    heading = '## 12. Shaders: What a Surface Answers To'
    full = [heading, ARC, '']
    short = [heading, '']
    for h in shader['halls']:
        full += [f'### {h["id"]} — {h["title"]}', h['storyboard'], '', '**Short AI alternative**', h['storyboard_short'], '', f'*For correction:* {h["review_note"]}', '']
        short += [f'### {h["id"]}', h['storyboard_short'], '']
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS.md', ROUTE/'storyboards.md']:
        replace_section(p, '\n'.join(full))
    for p in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS_SHORT.md', ROUTE/'storyboards-short.md']:
        replace_section(p, '\n'.join(short))
    for p in [ROOT/'doc/book/course/storyboards/SEQUENCES.md', ROUTE/'sequences.md']:
        text = p.read_text(encoding='utf-8')
        start = text.index(heading)
        end = text.index('## 13.', start)
        section = text[start:end].splitlines()
        section[1] = ARC
        replace_section(p, '\n'.join(section))

    diff = []
    for old, new in zip(old_halls, shader['halls']):
        for field in ['title','storyboard','storyboard_short']:
            diff.extend(difflib.unified_diff([old[field]+'\n'], [new[field]+'\n'], fromfile=new['id']+'/'+field+'/before', tofile=new['id']+'/'+field+'/after'))
    (OUT/'summaries.diff').write_text(''.join(diff), encoding='utf-8')
    (OUT/'checks.json').write_text(json.dumps({
        'date':'2026-10-04', 'shader_halls':len(UPDATES), 'route_halls':len(route['halls']),
        'other_authored_sequences_unchanged':True, 'other_route_halls_unchanged':True,
        'route_order_unchanged':True, 'other_markdown_sections_unchanged':True,
        'referenced_local_sources_exist':True, 'previous_map_folders_exist':True,
        'runtime_checked':False, 'learner_adapters_implemented':False,
        'sources':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [plans_path,sequence_path,route_path]},
    },ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Updated six Shader plans and metadata; preserved 201 other route halls and all route order.')

if __name__ == '__main__':
    main()
