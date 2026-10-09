from pathlib import Path
import json
root=Path.cwd();base=root/'doc/book/iterations/2026-09-19-randomness-review/middle'
out=base/'proposed';out.mkdir(exist_ok=True)
texts=[];metadata=[]
def prose(m,old,new):
    path=f'commons/maps/{m}/final.md'
    assert (root/path).read_text(encoding='utf-8').count(old)==1,old
    texts.append(dict(path=path,old=old,new=new))
def meta(m,keys,new):
    path=f'commons/maps/{m}/map_data.json';data=json.loads((root/path).read_text(encoding='utf-8'))
    old=data
    for key in keys:old=old[key]
    metadata.append(dict(path=path,keys=keys,old=old,new=new))
prose('Random_Walk','The keypad offers 2D, 3D, LEVY and RESET.','The keypad offers 2D, 3D, LONG STEP and RESET.')
prose('Random_Walk','The previous room let a draw choose a cube from a set. Here the draw proposes a movement from the position already reached.','Earlier, a draw chose a cube from an eligible set. The last room let perturbations accumulate in a stack. Here the draw proposes a movement from the position already reached.')
prose('Random_Walk','In 3D two draws choose a direction on a sphere; the proposed length stays the same. LEVY draws a length too.','In 3D two draws choose a direction on a sphere; the proposed length stays the same. LONG STEP draws a length too.')
prose('Random_Mushrooms','At the smaller arrival stage, wait for a silhouette.','<!-- @silhouette_arrivals -->\n\nAt the smaller arrival stage, wait for a silhouette.')
prose('Random_Mushrooms','Beyond the garden, three couture bodies stand together.','<!-- @couture_comparison -->\n\nBeyond the garden, three couture bodies stand together.')
prose('Random_Mushrooms','Carry that question into the recovered gallery: what can the same act of drawing a value become when it meets a brush, a tally or a growing path? After that, Random Game asks your body to answer in time.','Carry that question through the cage interlude. Then, in Random Space Geometry, compare values chosen independently with values related across neighbouring positions. What changes when difference acquires a neighbourhood?')
meta('Random_Rotate_Random_XYZ',['map_info','title'],'What remains in a changing stack')
meta('Random_Rotate_Random_XYZ',['map_info','description'],'Two complete MultiMesh stacks fit a shared ten-metre display. Pause accumulated drift, rotation and darkening; compare fixed specimen size with unequal configured rates, then restore the initial arrangement.')
meta('Random_Rotate_Random_XYZ',['map_info','metadata','learning_objectives'],[
    'Separate changes in position, orientation and appearance while specimen size remains fixed',
    'Pause and resume accumulated perturbation without restarting the onset delay',
    'Distinguish restoring an initial arrangement from replaying an identical stochastic future',
    'Recognise unequal configured rates as a limit on attributing differences to shape alone'])
meta('Random_Walk',['map_info','metadata','learning_objectives'],[
    'Compare a proposed step, its reflected endpoint and the stored trail',
    'Distinguish 2D, 3D and bounded inverse-square-root LONG STEP rules',
    'Replay positions at equal step counts and separate visual emphasis from population',
    'Inspect omitted wall contacts, discarded history and capped simulation time'])
meta('Random_Walk',['map_info','description'],'A seeded glass walk exposes step proposals, reflected endpoints, retained trails and two clocks. A raised-cell terrain and a held drawing point show what happens when the same family of rules meets ground or hand.')
meta('Random_Mushrooms',['map_info','description'],'Three encounters compare population recipes, sampled wardrobes and changed constructions: a six-template mushroom bed, six authored arrival slots with DRESS/FORMS, and a three-seed couture comparison.')
meta('Random_Mushrooms',['map_info','metadata','learning_objectives'],[
    'Follow template copies and distinguish scattering, rings, clusters and rejected candidates',
    'Remove per-instance scale variation while retaining the draws that place the population',
    'Compare resampling a wardrobe with changing its available forms without changing arrivals',
    'Hold three seeds while changing garment construction, then ask which capabilities remain absent'])
(out/'root-text.json').write_text(json.dumps(texts,ensure_ascii=False,indent=2),encoding='utf-8')
(out/'root-metadata.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
registry=[]
for file,id,description in [
    ('commons_artifacts','random_walk_terrarium','Five random walkers in a reflecting glass tank: fixed-length 2D/3D proposals or bounded inverse-square-root LONG STEP proposals. The legacy LEVY_FLIGHT enum remains compatible. A 200-position tail and optional logbook expose the named seed, two clocks and ONE/ALL emphasis.'),
    ('randomness','random_decay_multimesh','Two MultiMesh stacks accumulate bounded drift, rotation, sinking and darkening at different configured rates. Both use fixed one-metre specimen units by default. Optional stack_fit fits both complete displays to a given width with a common geometry scale, a 0.6m gap and floor-aligned initial faces; controls retain full size. TOGGLE preserves the ramp clock; RESET restarts it.'),
    ('randomness','silhouette_arrivals','Seeded sampling without replacement fills six authored places. DRESS resamples the wardrobe; FORMS switches branching instructions while retaining its dress seed. Both leave arrival order unchanged; REPLAY restores that order. Flat billboard figures gain different outlines, not locomotion.')]:
    path=f'commons/artifacts/registry/{file}.json';keys=['artifacts',id,'description']
    old=json.loads((root/path).read_text(encoding='utf-8'))['artifacts'][id]['description']
    registry.append(dict(path=path,keys=keys,old=old,new=description))
(out/'root-registry.json').write_text(json.dumps(registry,ensure_ascii=False,indent=2),encoding='utf-8')
print(len(texts),'text changes;',len(metadata),'metadata changes; no Gaussian changes')
