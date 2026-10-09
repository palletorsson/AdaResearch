"""Revise only the Arrays teaching proposal and its generated reading copies."""
from pathlib import Path
import copy
import difflib
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
ROUTE=ROOT/'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'

def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def backup(p):
    b=OUT/'before'/p.relative_to(ROOT)
    if not b.exists(): b.parent.mkdir(parents=True,exist_ok=True);b.write_bytes(p.read_bytes())
def write(p,s): backup(p);p.write_text(s,encoding='utf-8')
def save(p,d): write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')

ARC=('PROPOSED. Keep an address while changing what its value asks a receiver to do. '
     'Return to Trace’s list and Transformation’s positioned body; extend a small occupancy '
     'record into a plane and a volume with explicit storage conventions. Then let an address '
     'choose a tile’s turn, give the same image another support, and let a clock read a score. '
     'Occupancy, orientation and musical events remain different kinds of data. Carry the '
     'read/write operation and declared readers into Colour and Tiling; automatic transport '
     'between museum exhibits is not assumed.')

UPDATES=[
dict(id='Array',title='Keep a place when its occupant leaves',mode='make',
     storyboard='The row loses a cube without closing its gap; the nearby grid lets the student locate another absence with two indices. Bringing Trace’s list and loop and Transformation’s positioned body, they begin with four slots, then extend the same read/write operation to a small grid. Follow the installed convention, grid_data[x][z], and keep occupancy values separate from visible-node references and spacing. A named display adapter and collection event are supplied. The student empties a chosen slot, changes the spacing and explains why the other addresses remain. They carry the occupancy record and its reader. Molnár’s retained departures offer an optional next experiment; the changing floor remains an encounter with the physical consequence of an empty place.',
     storyboard_short='Use row and indexed grid. Reuse Trace list/loop and positioned bodies. Teach retained slots, then grid_data[x][z]; separate occupancy, node reference and spacing. Supply display adapter/collection event. Check: empty one slot, vary spacing, preserve addresses. Carry record + reader. Optional: stored Molnár departures. Floor writer stays an encounter. Open: reduced learner binding; Array tutorial absent.',
     brings=['Trace’s list and traversal','created bodies and position values'],
     learns=['read/write a retained slot','two-index addressing in the installed x/z convention','occupancy value versus visible object reference'],
     carries='A small occupancy record and an explicit address-to-display reader',
     supplied=['named display adapter and collection event','existing floor writer and Molnár comparison'],
     prior_maps=['Point_Trace','Point_Line_Grid','Trans_Pre','Trans_Translation'],
     independent_check='Empty a chosen slot, then change the spacing. Predict which stored value changes and explain why neither operation renumbers the neighbours.',
     critical_question='The address survives an absence. What does the stored zero leave unexplained?',
     source_refs=['algorithms/arrays/row_3_x.gd','algorithms/arrays/grid_2d_4x4.gd','algorithms/arrays/binary_table/binary_table_display.gd','commons/artifacts/array_floor_writer/array_floor_writer.gd','commons/artifacts/molnar_cube_study/molnar_cube_study.gd'],
     change_reason='Make row-to-grid addressing the main lesson. Move stored random departures from a second required concept into an optional return; retain the floor writer’s bodily consequences without teaching a floor-editing system.',
     review_note='Array/tutorial.md is still absent. The reduced learner study and its display connection need choosing before a full lesson. The row uses array_data[0][i]; the grid uses grid_data[x][z]. Molnár’s current data is a different retained structure, not this occupancy table. Do not present Grid’s earlier lossy snapping as reversible.'),
dict(id='Tutorial_3D',title='Name the layer and keep the convention visible',mode='make',
     storyboard='In the flight enclosure, the student selects a cube above the ground and later reads zero where it stood. They bring the two-index occupancy record and extend the study to layers. The displayed address is [x, y, z], while the installed volume reads values[y][z][x]. Before changing a value, they show how the earlier [x][z] plane becomes one [z][x] layer: the conversion is part of the lesson. Flight, selection and collection are supplied. The student predicts an unequal-index address, changes its value and reads it back without shifting its neighbours. They carry an explicit storage-to-space mapping. Open structures and suspended fragments remain further uses of addressed places, not additional required data systems.',
     storyboard_short='Use flight enclosure. Reuse occupancy record. Teach displayed [x,y,z] → values[y][z][x]; explicitly convert earlier [x][z] plane into a [z][x] layer. Supply flight/selection/collection. Check unequal indices; write/read one slot without shifts. Carry storage-to-space mapping. Open structures/suspension remain comparisons. Open: reduced study binding; an added dimension grants no flight.',
     brings=['two-index occupancy and its reader','index-to-position placement'],
     learns=['three-index addressing','explicit conversion between storage conventions'],
     carries='An explainable mapping from displayed XYZ to stored layer/row/entry',
     supplied=['existing flight region','selection marker and collection event'],
     prior_maps=['Array','Point_Coordinates','Trans_Translation'],
     independent_check='Predict the place at [1, 2, 0], identify values[2][0][1], change that entry and retrieve it. Explain why spacing and flight permission are separate from the three indices.',
     critical_question='Which places can the record name, and which can a body actually reach?',
     source_refs=['commons/artifacts/regularity/array_flight_lab.gd','algorithms/arrays/grid_2d_4x4.gd'],
     change_reason='Replace the generic layer/row/column description with the actual XYZ-to-YZX relationship. Expose the change from the earlier grid instead of hiding a transpose inside supplied code.',
     review_note='Wrapping the earlier grid directly would yield values[y][x][z], not the installed values[y][z][x]. Explain the conversion or a named reader explicitly. The installed enclosure is four by four by four; the learner study may be smaller. Current tutorial’s open-form edits do not yet teach this storage conversion.'),
dict(id='Tutorial_Tiling_Floor',title='Let an address choose a turn',mode='make',
     storyboard='At the paired four-by-four samples, one extra turn at each address makes a larger figure cross the joints. The student brings addressing and rotation, but now gives the value another declared meaning: zero quarter-turns is an orientation, not an empty slot. With the asymmetric tile and image renderer supplied, they write one address-to-turn function using remainder by four. They predict a selected tile’s result, then add one exceptional address. Enlarging the field repeats the same calculation without adding instructions. They carry the motif choice, turn rule and exception separately. The other fields provide comparisons; the floor’s apparent ridges do not become steps underfoot.',
     storyboard_short='Use paired 4×4 samples. Reuse indices/rotation. Teach address → quarter-turn via remainder; zero means orientation, not vacancy. Supply motif/image renderer. Predict one result, add one exception, enlarge field with same rule. Carry motif + turn rule + exception. Other fields compare. Existing tiling rasterizes images; no per-tile body or stored occupancy implied. Open: learner-rule binding.',
     brings=['indexed lookup and traversal','rotation at a site'],
     learns=['address-to-orientation function','remainder and one exceptional address','new value meaning requires a declared reader'],
     carries='A motif and an address-to-turn rule with one explicit exception',
     supplied=['asymmetric tile','image renderer and existing rule-comparison controls'],
     prior_maps=['Array','Tutorial_3D','Trans_Rotation'],
     independent_check='Predict a turn at an address you have not inspected. Keep one exception, then enlarge the field and explain why the local rule needs no extra clauses.',
     critical_question='When a larger figure appears across the joints, where does the work of the small rule end?',
     source_refs=['commons/artifacts/regularity/tiling_principles.gd','commons/artifacts/regularity/tiling_pattern.gd','commons/artifacts/regularity/tiling_rule_study.gd'],
     change_reason='State the change from occupancy to orientation. Use the existing four-by-four study for a prediction, one exception and a larger field; make its image renderer an explicit supplied component.',
     review_note='The installed floor makes raster images from a rule; it is not a nested table of colliding triangle tiles. Do not require the learner to rebuild the renderer. The current tutorial redirects to final.md, so this remains a teaching selection rather than an implemented companion.'),
dict(id='Tutorial_Tiling_Walls',title='Keep the pattern, change what carries it',mode='reflect',
     storyboard='The same pattern now stands in front of the student. They bring the motif and turn rule from the floor and reuse its generated image on a supplied upright receiver. The eye chart and a walk toward and away from it let them compare what remains legible as its apparent size changes. No new syntax is needed. At the exception wall, they predict the difference between turning a mark inside the image and turning the sheet with its collision. One alters the picture; the other can open a passage. The hinge and finite landing stay supplied. They carry a comparison separating source, appearance and access, including the brief chance to look back at the outside of the museum’s enclosure.',
     storyboard_short='Use wall fields, eye chart and turning wall. Reuse floor motif/rule/image on supplied upright receiver. Compare distance and apparent scale; no new syntax. Predict image-turn versus carrier/collision-turn. Supply hinge/landing. Carry source–appearance–access distinction. Preserve the outside pause. Open: learner image assignment; no new tiling or wall-construction lesson.',
     brings=['motif and turn rule','generated image and a declared receiver','surface versus collision'],
     learns=['same image with a different receiver','image change versus physical passage'],
     carries='A reusable image and a comparison of source, appearance and access',
     supplied=['upright image receiver and eye chart','hinged wall, collision handling and finite landing'],
     prior_maps=['Tutorial_Tiling_Floor','Point_Triangle_Context','Trans_Pit'],
     independent_check='Before using either control, predict which turn could open a route and explain why changing the image alone cannot do so. Keep the same image while comparing floor and wall.',
     critical_question='What was the thin enclosure doing for our forward walk, before we saw its other side?',
     source_refs=['commons/artifacts/regularity/tiling_principles.gd','commons/artifacts/regularity/wall_exception.gd'],
     change_reason='Give the floor’s image a concrete return on another receiver. Preserve the eye chart and exterior landing as a reflective pause instead of adding another construction exercise.',
     review_note='Reuse of the learner’s own generated image needs an explicit assignment; the installed floor and walls already share a generator, not an automatically transported learner record. Preserve the mature main text and the wall’s collision/safety behavior.'),
dict(id='Tutorial_Disco',title='Let a clock read the choices you kept',mode='make',
     storyboard='The monochrome floor changes while a separate sequencer offers empty cells to fill. The student brings indexed lookup, remainder and elapsed time. They make a short score with explicitly named track and step indices, following the instrument’s [track][step] convention; false means no new sound trigger, not a missing floor tile. A supplied sound receiver handles the note. The student advances a playhead through the kept score, moves an event without changing tempo, then changes tempo without rewriting the entries. They stop the score and watch the floor continue. They carry a reusable timed reader. The sixteen-step score’s connection to twelve floor columns is a comparison of addresses, not a lesson in recording footsteps.',
     storyboard_short='Use separate sequencer and changing floor. Reuse lookup/remainder/time. Teach score[track][step] plus timed playhead; false = no new trigger. Supply sound receiver/display. Move event at fixed tempo; change tempo with score fixed; stop score and predict floor. Carry timed reader. 16 steps/12 columns can share a flash address. No footstep recording. Open: old tutorial contradicts current encounter.',
     brings=['indexed values and declared readers','elapsed time and cyclic counts'],
     learns=['stored events read by a separate clock','track/step addressing','inactive event versus absent geometry'],
     carries='A kept score and an independently controlled timed reader',
     supplied=['sound trigger interface','existing sequencer display and independently animated floor'],
     prior_maps=['Point_Zero','Tutorial_Tiling_Floor','Trans_Pre'],
     independent_check='Move an event while tempo stays fixed, then alter tempo without changing any entry. Stop the score and predict which floor behavior continues. As a further comparison, explain why step 0 and step 12 can flash the same floor column.',
     critical_question='What changes when you move with a rhythm but the system does not record your steps?',
     source_refs=['commons/audio/sequencer/step_sequencer.gd','commons/audio/sequencer/sequencer_ui.gd','commons/context/discofloor/StandaloneDiscoFloor.gd','commons/artifacts/regularity/disco_controls.gd','commons/context/discofloor/DiscoSequencerBridge.gd'],
     change_reason='Make the score’s value meaning and reader explicit, keep the independent clocks, and give the student an observable variation. Flag the old 17×17 footstep-recording tutorial as unresolved rather than silently treating its code as current.',
     review_note='The current instrument stores four tracks by sixteen boolean steps; the floor has twelve columns. The learner can start with one short track. The companion still describes a 17×17 footstep-recording floor, undefined supplied pieces and deferred Chamber_Arrays. This summary pass does not repair that full lesson: rewrite it from the present score before presenting it as reliable instructions.'),
]

def replace_section(path,section):
    text=path.read_text(encoding='utf-8')
    pattern=r'^## 3\. Arrays and Regularity.*?(?=^## 4\.)'
    assert len(re.findall(pattern,text,re.M|re.S))==1,path
    after=re.sub(pattern,lambda _:section.rstrip()+'\n\n',text,flags=re.M|re.S)
    assert re.sub(pattern,'',text,flags=re.M|re.S)==re.sub(pattern,'',after,flags=re.M|re.S)
    write(path,after)

def main():
    p=ROOT/'doc/book/course/storyboards/early.json';data=load(p);before=copy.deepcopy(data)
    seq=next(s for s in data if s['sequence']=='array_tutorial')
    assert [h['id'] for h in seq['halls']]==[h['id'] for h in UPDATES]
    for h in UPDATES:
        for r in h['source_refs']:assert (ROOT/r).exists(),r
        for r in h['prior_maps']:assert (ROOT/'commons/maps'/r).is_dir(),r
    seq['arc']=ARC
    seq['status']='Revised teaching proposal; full companion repairs and learner adapters remain pending'
    seq['tutorial_guidance']='doc/book/course/storyboards/ARRAYS.md'
    for old,new in zip(seq['halls'],UPDATES):old.update(new)
    assert [s for s in data if s['sequence']!='array_tutorial']==[s for s in before if s['sequence']!='array_tutorial']
    save(p,data)

    sp=ROOT/'commons/maps/sequences/array_tutorial.json';source=load(sp);source_before=copy.deepcopy(source)
    meta=source['sequences']['array_tutorial']
    meta['description']='Five existing halls follow a retained address through a row, a plane, an entered volume, a floor image, an upright receiver and a separately clocked score. The proposed teaching keeps occupancy, orientation and musical events distinct. Colour follows; its palette and later Tiling return to these address-and-reader operations.'
    meta['truth']='An address can remain when its occupant leaves. What a stored or computed value means depends on the reader: absence, a turn and a silent beat are different decisions.'
    meta['learning_objectives_status']='Revised summary proposal; reduced learner bindings and full tutorial repairs remain pending.'
    meta['learning_objectives']=[
        'Read and change a slot without removing its address; separate occupancy, visible references and spacing',
        'Explain the conversion from grid_data[x][z] to a volume stored as values[y][z][x]',
        'Use an address-to-turn rule and one exception, declaring that orientation zero is not absence',
        'Reuse a generated image on another receiver and distinguish its appearance from collision and passage',
        'Read a kept track/step score with a separate playhead; vary events and tempo independently of the floor animation',
    ]
    meta.setdefault('local_review_history',[]).append(dict(date='2026-10-04',scope='One-sequence capacity review',decision='Focus addressing first; optional Molnár variation; explicit XZ-to-YZX conversion; separate occupancy/orientation/event readers; retain the wall pause and independent Disco clocks.',report='doc/book/iterations/2026-10-04-arrays-capacity-return/REPORT.md',status='Summary and metadata changes only. Disco companion contradiction remains for full-lesson rewrite.'))
    assert meta['maps']==source_before['sequences']['array_tutorial']['maps']
    assert source['artifact_groups']==source_before['artifact_groups']
    save(sp,source)

    rp=ROUTE/'route.json';route=load(rp);oldroute=copy.deepcopy(route)
    by_id={h['id']:h for h in seq['halls']}
    for h in route['halls']:
        if h['sequence']=='array_tutorial':h.update(by_id[h['id']])
    next(s for s in route['sequences'] if s['id']=='array_tutorial')['arc']=ARC
    assert [h for h in route['halls'] if h['sequence']!='array_tutorial']==[h for h in oldroute['halls'] if h['sequence']!='array_tutorial']
    assert [h['id'] for h in route['halls']]==[h['id'] for h in oldroute['halls']]
    save(rp,route)
    pp=ROUTE/'index.html';page=pp.read_text(encoding='utf-8')
    pattern=r'(<script id="route-data" type="application/json">).*?(</script>)'
    assert len(re.findall(pattern,page,re.S))==1
    payload=json.dumps(route,ensure_ascii=False).replace('</','<\\/')
    write(pp,re.sub(pattern,lambda m:m[1]+payload+m[2],page,count=1,flags=re.S))

    heading='## 3. Arrays and Regularity';full=[heading,ARC,''];short=[heading,'']
    for h in seq['halls']:
        full += [f'### {h["id"]} — {h["title"]}',h['storyboard'],'','**Short AI alternative**',h['storyboard_short'],'',f'*For correction:* {h["review_note"]}','']
        short += [f'### {h["id"]}',h['storyboard_short'],'']
    for f in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS.md',ROUTE/'storyboards.md']:replace_section(f,'\n'.join(full))
    for f in [ROOT/'doc/book/course/TUTORIAL_STORYBOARDS_SHORT.md',ROUTE/'storyboards-short.md']:replace_section(f,'\n'.join(short))
    for f in [ROOT/'doc/book/course/storyboards/SEQUENCES.md',ROUTE/'sequences.md']:
        text=f.read_text(encoding='utf-8');a=text.index(heading);b=text.index('## 4.',a);section=text[a:b].splitlines();section[1]=ARC;replace_section(f,'\n'.join(section))

    old=next(s for s in before if s['sequence']=='array_tutorial')
    diff=[]
    for a,b in zip(old['halls'],seq['halls']):
        for key in ['title','storyboard','storyboard_short']:
            diff.extend(difflib.unified_diff([a[key]+'\n'],[b[key]+'\n'],fromfile=b['id']+'/'+key+'/before',tofile=b['id']+'/'+key+'/after'))
    (OUT/'summaries.diff').write_text(''.join(diff),encoding='utf-8')
    untouched=load(OUT/'unchanged-evidence-before.json')
    assert all(hashlib.sha256((ROOT/x['path']).read_bytes()).hexdigest()==x['sha256'] for x in untouched)
    checks=dict(sequence='array_tutorial',hall_count=5,other_202_route_halls_preserved=True,sequence_order_preserved=True,other_authored_sequences_preserved=True,other_markdown_sections_preserved=True,source_paths_exist=True,full_tutorials_finals_and_map_data_unchanged=True,disco_full_tutorial_repair_pending=True,runtime_checked=False)
    (OUT/'checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
    print('Arrays updated: five full/short summaries; 202 other route halls and all order preserved.')

if __name__=='__main__':main()
