from pathlib import Path
import json, hashlib, difflib

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def revise(name, changes):
    p = ROOT / 'commons/maps' / name / 'final.md'
    paragraphs = p.read_text(encoding='utf-8').split('\n\n')
    for start, new in changes:
        i = next(i for i, text in enumerate(paragraphs) if text.startswith(start))
        paragraphs[i] = new
    p.write_text('\n\n'.join(paragraphs), encoding='utf-8')

revise('SwarmIntelligence_Agent_Based_Modeling_ABM', [
    ('Watch the colony long enough', 'Watch the colony long enough to recognise a trail. Use RESET and watch the beginning again. The food returns to the same places, with the same qualities; the ants begin with the same headings. Now raise EVAPORATE, reset, and compare. Keep ANTS steady at first. You are changing how quickly the ground forgets, while giving the next colony the same beginning.'),
    ('Next vary ANTS.', 'Next vary ANTS. The control replaces the population but leaves its field behind. The new ants arrive in a world marked by ants that are no longer there. Watch whether they pick up an old route. Then RESET: this time the marks disappear too. Replacing the travellers and erasing their history are two different acts. Compare fewer agents leaving more persistent marks with more agents leaving shorter-lived marks; similar pictures can have different histories.'),
])
revise('SwarmIntelligence_Particle_Swarm_Optimization', [
    ('Watch the population under CONVERGE', 'Watch the population under CONVERGE, then choose SPREAD. The button changes the score while the particles keep their positions and motion. Keep INERTIA steady and watch the turn. For a comparison from the same beginning, use RESET after selecting each objective: it restores the same scatter and velocities. Next try NOVELTY. Before reading these as success and failure, describe what each setting seems to reward.'),
    ('CONVERGE rewards movement', 'CONVERGE rewards movement towards the centre. SPREAD rewards distance from it; two particles can score equally well while crowding the same edge. NOVELTY rewards distance from positions retained in an archive. These are three different questions put to the same moving bodies. The labels Corporate, Ecological and Artistic are invitations to argue about those questions, not properties proved by the equations.'),
    ('Spend longer with NOVELTY.', 'Spend longer with NOVELTY. At its beginning the archive remembers the current positions. Its count grows as more visits are kept, and the bright regions on the plate change with that record. Follow a place that was bright. Does it remain promising once the swarm has been there?\n\nA remembered position must be scored again when the archive changes. Yesterday\'s high score cannot simply win against today\'s distances: the question has changed under it. The particle retains a place, but its claim to be best has to be renewed. Here forgetting and revaluation are part of the mechanism that lets movement continue.\n\nThe archive holds at most two hundred positions, sampled one at a time rather than recording every visit. When it fills, new entries replace the oldest. An apparently unexplored place can be unfamiliar to this record without being unfamiliar to the world. New relative to whom, and to how much of their past?'),
])
revise('SwarmIntelligence_Swarm_Intelligence_Algorithms', [
    ('Watch for a population recovery', 'Watch for a population recovery. Beside the living box, the POPULATION SUPPORT record counts prey and predators supplied from outside. Food has its own count; predator pressure reports when a population-level rule is reducing predator health. These marks come from the interventions themselves. A rise in prey accompanied by five supplied bodies tells a different story from a rise with no addition recorded. Neither view alone gives the whole history.\n\nLook back at the organisms after reading the record. Does the same recovery look different now? The intervention has not become more visible in their movements; you have gained another way to account for them. A future comparison could let you turn population care off while keeping the starting conditions fixed. For now the record exposes support without withdrawing it.'),
])

p = ROOT / 'commons/maps/sequences/swarmintelligence.json'
d = json.loads(p.read_text(encoding='utf-8')); s = d['sequences']['swarmintelligence']
s['name'] = 'Swarm Intelligence: Where Coordination Lives'
s['truth'] = 'Collective movement does not identify its cause. Look for the field, neighbour, memory, objective and support that make it possible.'
s['description'] = 'Seven encounters trace coordination through environmental memory, supplied direction, peer relations, agent state, two-channel trails, evaluated memory and population-level care. Decentralised movement invites questions about power; it does not by itself establish equality or autonomy.'
s['qfep_term'] = 'λ'
s['qfep_connection'] = 'Ask which rules and supports sustain a collective pattern, whose differences the shared medium can register, and what changing those conditions makes possible. This is a research question, not a claim that every swarm sits at an edge of chaos.'
s['demonstration'] = 'Compare agents writing trails, following supplied arrows, steering relative to neighbours and pursuing remembered scores. Finish by observing local ecology alongside a visible account of population support.'
s['learning_objectives'] = [
 'Distinguish agent-written traces from externally supplied guidance',
 'Compare separation, alignment, cohesion and perception radius',
 'Change evaporation from a repeatable starting state; distinguish new agents from a cleared field',
 'Follow the home/food channels of a foraging simulation without assuming proven optimality',
 'Distinguish remembered positions from their scores, especially as a novelty archive changes',
 'Compare local population events with interventions at population scale',
]
s['content'] = [x for x in s['content'] if not x.startswith('Chamber_Swarm:')]
replacements = {
 'SwarmIntelligence_PhysarumColony': 'Environmental memory: agents and fixed anchors contribute to a changing trail field',
 'SwarmIntelligence_Ant_Colony_Optimization': 'Two channels: outward and returning travellers seek and leave different traces',
 'SwarmIntelligence_Swarm_Intelligence_Algorithms': 'Local ecology and a visible record of population support',
}
for i, line in enumerate(s['content']):
    m = line.split(':', 1)[0]
    if m in replacements: s['content'][i] = m + ': ' + replacements[m]
for group in s.get('artifact_groups', []):
    if group['map'] in replacements: group['rationale'] = replacements[group['map']]
    if group['map'].endswith('Particle_Swarm_Optimization'): group['artifacts'] = ['fitness_landscape_politics', 'self_organizing_patterns']
    if group['map'].endswith('Boids_Algorithm') and 'flocking_controls' not in group['artifacts']: group['artifacts'].insert(0,'flocking_controls')
for group in d.get('artifact_groups', []):
    if group['map'] in replacements: group['rationale'] = replacements[group['map']]
    if group['map'].endswith('Ant_Colony_Optimization'): group['artifacts'] = ['AntColonyV2']
    if group['map'].endswith('PhysarumColony'): group['artifacts'] = ['PhysarumColony']
    if group['map'].endswith('FlowFields'): group['artifacts'] = ['FlowFieldMain']; group['rationale'] = 'Existing supplied-field encounter; its arrows expose local guidance.'
    if group['map'].endswith('Particle_Swarm_Optimization'): group['artifacts'] = ['fitness_landscape_politics','self_organizing_patterns']
    if group['map'].endswith('Boids_Algorithm') and 'flocking_controls' not in group['artifacts']: group['artifacts'].insert(0,'flocking_controls')
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

p = ROOT / 'commons/data/book/swarmintelligence.json'; d = json.loads(p.read_text(encoding='utf-8'))
for pearl in d['pearls']:
    m = pearl.get('map','')
    if m.endswith('Boids_Algorithm'):
        pearl['hero']='flocking_controls'
        if not any(l.get('token')=='flocking_controls' for l in pearl['lines']): pearl['lines'].insert(0,{'token':'flocking_controls','text':'Change one relation; watch a local arrow and the flock together.','by':'draft'})
    if m.endswith('Particle_Swarm_Optimization'):
        pearl['hero']='fitness_landscape_politics'
        for line in pearl['lines']:
            if line['token']=='fitness_landscape_politics': line['text']='A remembered position remains; its claim to be best must be scored again.'
    if m.endswith('Swarm_Intelligence_Algorithms'):
        line=pearl['lines'][0];line['note']='Local events and population-scale interventions coexist. The live care record identifies restocking, predator pressure and supplied food; it does not claim what removing them would cause.'
        line.pop('note_src',None)
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def patch_registry(path, changes):
    p=ROOT/path; d=json.loads(p.read_text(encoding='utf-8'))
    def walk(x):
        if isinstance(x,dict):
            if x.get('lookup_name') in changes: x.update(changes[x['lookup_name']])
            for v in x.values(): walk(v)
        elif isinstance(x,list):
            for v in x: walk(v)
    walk(d);p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
patch_registry('commons/artifacts/registry/algorithms_misc.json', {'ecosystem_simulation': {
    'qfep_connection':'Local predator-prey encounters coexist with population-scale restocking, predator pressure and outside food. Making this support visible changes what a claim of autonomy can mean.'}})
patch_registry('commons/artifacts/registry/swarmintelligence.json', {
    'fitness_landscape_politics': {'description':'PSO particles compare convergence, distance from centre and distance from an evolving archive. RESET repeats the starting scatter; novelty rescoring keeps remembered positions comparable under the current archive. A ridge mandate is also available by configuration.'},
    'ant_colony_optimization': {'qfep_connection':'A field holds traces longer than individual visits. Repeatable beginnings let the visitor compare how decay and population change what remains available to the next traveller.'},
})

p=ROOT/'commons/data/museum_core_encounters.json';d=json.loads(p.read_text(encoding='utf-8'))
def update_core(x):
    if isinstance(x,dict):
        for m in s['maps']:
            if m in x and isinstance(x[m],dict):
                r=x[m]
                for kind,file in [('text','final.md'),('map','map_data.json')]:
                    for key in [kind+'_sha256',kind+'_hash']:
                        if key in r: r[key]=hashlib.sha256((ROOT/'commons/maps'/m/file).read_bytes()).hexdigest()
        for v in x.values(): update_core(v)
    elif isinstance(x,list):
        for v in x: update_core(v)
update_core(d);p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

patch=[]
for m in s['maps']:
    f='commons/maps/'+m+'/final.md'
    a=(HERE/'before'/f).read_text(encoding='utf-8');b=(ROOT/f).read_text(encoding='utf-8')
    patch.extend(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+f,tofile=f))
(HERE/'final.diff').write_text(''.join(patch),encoding='utf-8')
print('Three chapters revised; four chapters preserved. Sequence framing and encounter index aligned.')
