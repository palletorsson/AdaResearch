"""A prose-only whole-sequence pass; retain all printed programs verbatim."""
from pathlib import Path
import json,re,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-shaders-complete-readings'
NAMES=['Shader_01_Shaping','Shader_05_Patterns','Shader_11_QueerRubber','Shader_09_FBM','Shader_12_PinkExtravaganza','Shader_10_ReactionDiffusion']
def main():
    for name in NAMES:
        for track in ['tutorial.md','final.md','map_data.json']:
            p=ROOT/'commons/maps'/name/track;before=OUT/'before'/name/track
            before.parent.mkdir(parents=True,exist_ok=True)
            if not before.exists():shutil.copy2(p,before)
    seq=ROOT/'commons/maps/sequences/shaders.json'
    if not (OUT/'before/shaders.json').exists():shutil.copy2(seq,OUT/'before/shaders.json')
    edits=[
      ('Shader_01_Shaping','final',
       'The wave leaps sideways, by an amount you could not have predicted, and continues.',
       'The wave leaps sideways and continues. The amount depends on when you moved the slider.'),
      ('Shader_01_Shaping','final',
       'The graphs keep nothing; they are functions of TIME.',
       'The graphs retain their control values but no previous image; the animated graph also reads TIME.'),
      ('Shader_05_Patterns','tutorial',
       'The existing flower garden and saved-record instrument are optional returns below.',
       'The existing flower garden and saved-record instrument are optional returns below. Complete the repeated-circle study before choosing either. The saved-record exercise is a separate data-reading lesson; Materials does not depend on it.'),
      ('Shader_09_FBM','tutorial',
       'Next, Pink Extravaganza combines operations you can now distinguish: colour, sampling coordinates, light response and visible displacement. Keep asking which body receives a rule and which construction supports the player.',
       'Next, Pink Extravaganza returns to the rigid cube and point. Its required study combines repeated colour, a view-dependent rim and emission while keeping geometry fixed. The displaced water remains a supporting encounter in the room. Keep asking which body receives a rule and which construction supports the player.'),
      ('Shader_12_PinkExtravaganza','final',
       'None yet keeps the whole field that the next field will need.',
       'None of these keeps an evolving field to supply to its own next update.'),
      ('Shader_10_ReactionDiffusion','tutorial',
       '## Read the rule first',
       '''## Two passes through the same study

First run the complete program and compare CLEAR, a planted mark, STEP, RUN/HOLD and INK. Explain which actions change the stored values. Trace `previous_state` through the update and the completed texture back into the next input. That is the central new capability.

Then open the numerical rule: predict one cell, change FEED and compare equal step counts. The chemistry coefficients are a supplied model to investigate. The render-target scheduling and byte packing below keep it executable; understanding every transport detail is not an additional entry requirement. Both passes use the same program and field.

## Read the update rule'''),
    ]
    changes=[]
    for name,track,old,new in edits:
        p=ROOT/'commons/maps'/name/(track+'.md');s=p.read_text(encoding='utf8')
        if old in s:
            assert s.count(old)==1,(name,old)
            before=re.findall(r'```[^\n]*\n.*?\n```',s,re.S)
            s=s.replace(old,new)
            assert re.findall(r'```[^\n]*\n.*?\n```',s,re.S)==before
            p.write_text(s,encoding='utf8')
        else:assert new in s,(name,old)
        changes.append({'map':name,'track':track,'before':old,'after':new})
    data=json.loads(seq.read_text(encoding='utf8'));s=data['sequences']['shaders'];assert s['maps']==NAMES
    s['description']='Six halls carry a familiar point and cube through a colour mask, coordinate repetition, bump and normal maps, vertex displacement, a composed material, and a field that retains its previous state. Each required reconstruction sits beside a larger museum encounter. Optional returns remain available without becoming prerequisites.'
    s['qfep_connection']='Earlier coordinates, forms, arrays and fields return as choices inside a material. The learner locates where each choice changes an appearance, a body or a record. Re-evaluating from current inputs differs from updating retained state; the final hall supplies that connection before Cellular Automata.'
    s['estimated_time']='Not measured: museum visit and code reconstruction are separate activities.'
    s['learning_objectives']=[
      'Construct a shared UV distance mask; compare hard and soft visible boundaries with fixed geometry and collision',
      'Repeat and shift sampling coordinates; distinguish tile address, local coordinates and physical size',
      'Compare flat shading, height-derived normals and an encoded normal map under light without changing silhouette',
      'Use bounded layered noise to compare colour, vertex normals and displacement; explain subdivision and separate physical support',
      'Compose repeated pigment, a view-dependent rim and emission on fixed bodies; distinguish visible brightness from illumination',
      'Plant and retain field data; read old state, write next separately; distinguish model update, palette and receiver'
    ]
    s['content']=[
      'Shader_01_Shaping: one circle rule on two square receivers; same point controls radius and edge',
      'Shader_05_Patterns: same circle and point; repeat and shift the lookup; optional garden and saved-record returns',
      'Shader_11_QueerRubber: same receivers, point and circle; compare flat, height and normal-map shading under light',
      'Shader_09_FBM: same point and rigid cube; replace squares with a subdivided plane and keep collision separate',
      'Shader_12_PinkExtravaganza: return to rigid point and cube; compose dots, rim and emission; investigate the surrounding room',
      'Shader_10_ReactionDiffusion: point plants in retained field; GPU updates previous state; old unbound panel and frost remain comparisons'
    ]
    s['learning_objectives_status']='Six focused tutorial drafts reconstructed and tested individually; whole-sequence prose pass complete. Printed examples unchanged in this pass. Teacher-authored GPU/synthetic-XR evidence; independent student, human-learning, headset and automatic cross-hall persistence are not established.'
    if not any(e.get('scope')=='Whole shader sequence reading' for e in s['local_review_history']):
        s['local_review_history'].append({'date':'2026-10-10','scope':'Whole shader sequence reading','decision':'Keep six-hall order. Preserve optional encounters, separate them in collected reading, clarify Water-to-Pink handoff and two passes through retained state. Update descriptive metadata to the completed drafts.','guide':'doc/book/iterations/2026-10-10-shaders-complete-readings/index.html','status':'Prose and metadata only; map order, museum runtime and printed code unchanged.'})
    seq.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    (OUT/'prose-changes.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    # Protect the entire listings, including optional code and maps, not just marked blocks.
    for name in NAMES:
        for track in ['tutorial.md','final.md']:
            old=(OUT/'before'/name/track).read_text(encoding='utf8');new=(ROOT/'commons/maps'/name/track).read_text(encoding='utf8')
            assert re.findall(r'```[^\n]*\n.*?\n```',old,re.S)==re.findall(r'```[^\n]*\n.*?\n```',new,re.S)
        assert (OUT/'before'/name/'map_data.json').read_bytes()==(ROOT/'commons/maps'/name/'map_data.json').read_bytes()
    original=json.loads((OUT/'before/shaders.json').read_text(encoding='utf8'))['sequences']['shaders']
    for key in ['maps','deferred_maps','prerequisites','unlocks','artifact_groups','algorithm_paths']:assert original[key]==s[key],key
    print('Six text clarifications; current sequence descriptions. All code fences, maps and route arrays preserved.')
if __name__=='__main__':main()
