"""Guarded proposals only; root owns their integration."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[4];PASS=HERE.parent
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
proposals=[]
def propose(path,keys,new):
    cursor=read(PASS/'before'/path)
    for key in keys:cursor=cursor[key]
    if cursor!=new:proposals.append(dict(path=path,keys=keys,old=cursor,new=new))
def registry(key,text,path='commons/artifacts/registry/randomness.json'):
    propose(path,['artifacts',key,'description'],text)
registry('seed_replay_demo','Two seeded colour grids can replay the same draw procedure or compare it with one discarded draw before RGB assignment. The same seed is not sufficient when the procedure changes. A slider selects an integer seed; REPLAY rebuilds, RANDOM chooses a seed, and optional draw strips expose the stream offset.')
registry('shannon_entropy_meter','Measures the empirical categorical Shannon entropy of a seeded sample from its symbol counts. The optional ledger retains the ordered tiles, compares a second weighted sample and sorts a display copy without changing counts or H. Disclosure reveals or withholds the measurement; it does not measure spatial disorder or thermodynamic entropy.')
registry('entropy_axiom','A field of points whose random displacement grows along the grid’s z direction. It contrasts lattice alignment with positional variation; this artifact does not calculate Shannon entropy.','commons/artifacts/registry/algorithms_misc.json')
registry('ten_print_maze_3d','A standing field of binary diagonal marks, with a separate ant search on a finer raster. The shipped stroke scene changes one diagonal every 0.08 seconds; its stored orientation and navigation update together. A visual contour is not a guarantee of a bodily passage. Character, wall and tile impressions are additional representations; the tile variant needs a separate orientation review.')
registry('dice_throw','A physical simulated die on a felt table, with face frequencies and a running mean read from settled orientation. Equal face probabilities and mean 3.5 are comparison hypotheses, not guarantees about a user’s throwing procedure. Rewards default to 16 balls per pip: 96 for a six and 16 for a one.')
propose('commons/maps/Randomness_10_PRINT_Algorithm/map_data.json',['map_info','description'],'Independent diagonal marks form contours that can look like a maze. Compare those contours with the ant’s separately computed navigation; the linked screen/floor print and exact-count diagonal board remain companion investigations.')
propose('commons/maps/Randomness_10_PRINT_Algorithm/map_data.json',['map_info','metadata','learning_objectives'],[
 'Identify the two local diagonal choices and follow how their endpoints meet',
 'Distinguish a drawn contour from an open passage and a computed route',
 'Follow a local replacement through the ant’s refreshed navigation model',
 'Compare independent choices with a prepared count of changed marks in retained companion works'])
propose('commons/maps/Random_Cubes/map_data.json',['map_info','description'],'A user-thrown simulated die connects a physical outcome to a retained statistical record and an authored reward. Compare one result, a face frequency and the running mean while keeping the throwing procedure in view.')
propose('commons/maps/Random_Cubes/map_data.json',['map_info','metadata','learning_objectives'],[
 'Compare the upward physical face with the reported result after settlement',
 'Track one face’s frequency separately from the running numerical mean',
 'Use the equal-face mean of 3.5 as a distribution hypothesis rather than a possible face',
 'Keep the throwing method and reward rule distinct from a claim of fairness'])
(HERE/'metadata-proposals.json').write_text(json.dumps(proposals,ensure_ascii=False,indent=2),encoding='utf-8')
(HERE/'manuscript-proposals.json').write_text('[]\n',encoding='utf-8')
print(len(proposals),'metadata proposals; no manuscript rewrites. Root owns Remove exit.')
