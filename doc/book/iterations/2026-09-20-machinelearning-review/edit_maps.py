from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[4]
def load(p): return json.loads((ROOT/p).read_text(encoding='utf-8'))
def save(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def museum(w,d):
    return {'wall_height':4,'open_roof':True,'gate':False,'gate_depth_rows':0,'piers':False,
            'plinths':False,'artifact_placement':'map','sculpture_clear_rects':[[1,1,w-2,d-2]]}

for room,w,d,placements,description in [
 ('ML_Sequence_Memory',19,23,[(9,7,'lstms_vr:0:0:1'),(9,17,'transformers_vr:0:0:0.4')],
  'Walk around an LSTM gate diagram first, then a smaller transformer diagram. Trace different ways of relating present input to earlier information.'),
 ('ML_Generative',19,21,[(9,11,'generative_adversarial_networks_gans_vr:0:0:0.65')],
  'An animated generator/discriminator exchange with visible candidate and reference particles. Metrics are scripted; the hall illustrates roles without training models.')]:
    path=f'commons/maps/{room}/map_data.json'; data=load(path)
    data['map_info']['dimensions']={'width':w,'depth':d,'max_height':4}
    data['map_info']['description']=description
    data['map_info']['metadata']['design_notes']=description
    data['map_info']['museum']=museum(w,d)
    structure=[['4' if x in (0,w-1) or z in (0,d-1) else '1' for x in range(w)] for z in range(d)]
    for z in (0,d-1):
        for x in range(w//2-1,w//2+2): structure[z][x]='1'
    utilities=[[' ']*w for _ in range(d)]; utilities[1][w//2]='s'; utilities[d-2][w//2]='t'
    interactables=[[' ']*w for _ in range(d)]
    for x,z,token in placements: interactables[z][x]=token
    data['layers']={'structure':structure,'utilities':utilities,'interactables':interactables}
    save(path,data)

for room,token,new in [
 ('ML_Classification','enhanced_kmeans','enhanced_kmeans:0:0.15:0.2#natural_cluster_count:3#lesson_controls:on'),
 ('ML_Gradient_Landscape','loss_function_comparator','loss_function_comparator:0:0:1.2#plinth:1.0')]:
    path=f'commons/maps/{room}/map_data.json'
    # Always derive this bay from the frozen original, so reruns do not extend it again.
    data=load('doc/book/iterations/2026-09-20-machinelearning-review/before/'+path)
    for row in data['layers']['interactables']:
        for i,cell in enumerate(row):
            if str(cell).split(':')[0]==token: row[i]=new
    if room=='ML_Classification':
        w=data['map_info']['dimensions']['width']
        for row in data['layers']['interactables']:
            for i,cell in enumerate(row):
                if str(cell).startswith('enhanced_kmeans:'): row[i]=' '
        for row in data['layers']['utilities']:
            for i,cell in enumerate(row):
                if cell=='s': row[i]=' '
        front=[['4' if x in (0,w-1) or (z==0 and x not in (6,7,8)) else '1' for x in range(w)] for z in range(7)]
        data['layers']['structure']=front+data['layers']['structure']
        for layer in ('utilities','interactables'):
            data['layers'][layer]=[[' ']*w for _ in range(7)]+data['layers'][layer]
        data['layers']['utilities'][1][7]='s'
        data['layers']['interactables'][4][7]=new
        data['map_info']['dimensions']['depth']+=7
        data['map_info']['metadata']['design_notes']='An entrance bay for the controlled k-means comparison; the existing classification rooms and supporting works continue behind it.'
    for row in data['layers']['interactables']:
        for i,cell in enumerate(row):
            if str(cell).split(':')[0] in ('svm_visualization','pca_visualization','random_forest_visualization'):
                row[i]=str(cell)+'#desktop_ui:off'
    size=data['map_info']['dimensions']; data['map_info']['museum']=museum(size['width'],size['depth'])
    save(path,data)

path='commons/maps/sequences/machinelearning.json'; data=load(path); seq=data['sequences']['machinelearning']
seq['name']='Machine Learning: What Changes, and Why?'
seq['truth']='A change in appearance is not yet evidence of learning. Follow what changes, what measures it and what stays fixed.'
seq['qfep_connection']='Within Ada Research, learning opens questions about what a model preserves and excludes. These are project interpretations; learning is not universally gradient descent, and data variability is not identical to thermodynamic entropy.'
seq['description']='Eight encounters distinguish environmental selection, loss, clustering, learned weights, image filtering, diagrams of memory and adversarial learning, and anomaly rules. Follow each operation before interpreting what its result means.'
seq['learning_objectives']=[
 'Identify selection conditions without requiring an explicit leaderboard',
 'Compare three loss rules on controlled observations and repeatable starts',
 'Compare four cluster centres on three blobs, rings and an unclustered sample',
 'Distinguish transient activation, learned parameters and evidence of generalisation',
 'Separate computed edge evidence from supplied recognition labels',
 'Read memory and adversarial-learning diagrams without mistaking animation for trained state',
 'Relate anomaly scores to a threshold and reference population']
roles=load('commons/data/artifact_roles.json')['roles']
for groups in [seq.get('artifact_groups',[]),data.get('artifact_groups',[])]:
 for group in groups:
    room=group.get('map')
    if room not in seq['maps']: continue
    group['artifacts']=[t for t,role in roles.get(room,{}).items() if role=='primary']
    group['rationale']='Begin with the current primary encounter; retain supporting comparisons. Follow what changes and what evidence supports the claim.'
save(path,data)
print('Four maps updated; eight-hall order retained')
