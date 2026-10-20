"""Small prose-only corrections after reading the complete Swarm sequence."""
from pathlib import Path
import json, re, hashlib

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-10-swarm-sequence-review'
edits = [
 ('PhysarumColony', 'final', 'physarum',
  'The previous hall cut one hollow for one body and asked whether it could be entered; here nothing is cut, and many agents rewrite the ground they move on.',
  'The previous hall rebuilt a surface when you changed its description. Here moving points change the field themselves, and later movements read what remains.'),
 ('Boids_Algorithm', 'tutorial', 'boids',
  'Keep the neighbour selector, velocity, weighted requests and shared snapshot. In Agent-Based Modeling, give the carried body an explicit internal state and ask when the same surroundings lead it to act differently.',
  'Keep PointBody, velocity, bounded steering and the shared snapshot. The neighbour selector and three flocking requests remain available tools, but the next study sets them aside. Agent-Based Modeling brings back the shared trace and gives the carried body an internal state: searching or returning with food.'),
 ('Ant_Colony_Optimization', 'tutorial', 'aco',
  'In Particle Swarm Optimization, each point will also remember a best position of its own.',
  'Particle Swarm Optimization replaces the trails and carrying flag with personal and shared records of scored positions. The PointBody class stays; the colony behaviour does not.'),
 ('Particle_Swarm_Optimization', 'tutorial', 'pso',
  'The last Swarm hall will let us compare what a body reads and what it leaves. Carry this distinction: a common destination here comes from a shared score and record. It is not the same relationship as a neighbour\'s heading or a trail underfoot.',
  'The last Swarm hall keeps PointBody and the habit of inspecting a record. It sets this optimizer aside and supplies the museum\'s existing ecosystem. We will write an account of births, losses and bodies added from outside, then compare it with the population we can see. A scored destination and a population account answer different questions.'),
 ('Particle_Swarm_Optimization', 'final', 'pso',
  'In the next room we can place these supports beside one another.',
  'In the next room, watch for bodies arriving with gold rings. A population can continue because an operation outside its individual encounters supplies more of them.'),
 ('Swarm_Intelligence_Algorithms', 'final', 'account',
  'Let the sphere go. Movement resumes.',
  'Let the sphere go. If the model was running before you held it, movement resumes.'),
]
changes = []
for suffix, kind, writer, old, new in edits:
    p = R / 'commons/maps' / ('SwarmIntelligence_' + suffix) / (kind + '.md')
    text = p.read_text(encoding='utf8')
    if new in text:
        continue
    assert text.count(old) == 1, (p, old)
    backup = O / 'before' / p.relative_to(R)
    backup.parent.mkdir(parents=True, exist_ok=True)
    if not backup.exists():
        backup.write_bytes(p.read_bytes())
    updated = text.replace(old, new)
    assert re.findall(r'```.*?```', text, re.S) == re.findall(r'```.*?```', updated, re.S)
    p.write_bytes(updated.encode('utf8'))
    w = R / 'tools' / ('write_swarm_' + writer + '.py')
    source = w.read_text(encoding='utf8')
    if old in source:
        assert source.count(old) == 1
        w.write_bytes(source.replace(old, new).encode('utf8'))
    else:
        # Physarum keeps its inherited reflection rather than printing a new one.
        assert writer == 'physarum' and kind == 'final'
    changes.append({'path': str(p.relative_to(R)), 'before': old, 'after': new,
                    'sha256': hashlib.sha256(updated.encode()).hexdigest()})

plan_path = R / 'doc/book/course/execution-plan/plan.json'
plan = json.loads(plan_path.read_text(encoding='utf8'))
backup = O / 'before/plan.json'
if not backup.exists():
    backup.parent.mkdir(parents=True, exist_ok=True)
    backup.write_bytes(plan_path.read_bytes())
next_steps = {
 'SwarmIntelligence_Boids_Algorithm': 'ABM keeps PointBody, velocity, bounded steering and the old/next snapshot. Set aside flocking requests; return to the shared trace and add searching/carrying state.',
 'SwarmIntelligence_Ant_Colony_Optimization': 'PSO keeps PointBody but replaces trails and carrying state with personal and shared scored-position records. Continue at full room scale.',
 'SwarmIntelligence_Particle_Swarm_Optimization': 'Population Support keeps PointBody and record inspection, replaces optimization with the supplied ecosystem, and adds a birth/loss/supply account checked against the visible population.',
}
for row in plan['lessons']:
    if row['id'] in next_steps:
        old = row['next']
        row['next'] = next_steps[row['id']]
        publisher = R / 'tools' / ('publish_swarm_' + {
            'SwarmIntelligence_Boids_Algorithm': 'boids',
            'SwarmIntelligence_Ant_Colony_Optimization': 'aco',
            'SwarmIntelligence_Particle_Swarm_Optimization': 'pso'}[row['id']] + '.py')
        source = publisher.read_text(encoding='utf8')
        if old in source:
            publisher.write_bytes(source.replace(old, row['next']).encode('utf8'))
plan_path.write_bytes((json.dumps(plan, ensure_ascii=False, indent=2) + '\n').encode('utf8'))
before = json.loads(backup.read_text(encoding='utf8'))
for a, b in zip(before['lessons'], plan['lessons']):
    assert a['id'] == b['id']
    assert {k:v for k,v in a.items() if k != 'next'} == {k:v for k,v in b.items() if k != 'next'}
    if a['id'] not in next_steps:
        assert a == b
if changes:
    (O/'changes.json').write_bytes((json.dumps(changes, ensure_ascii=False, indent=2)+'\n').encode())
print(f'{len(changes)} prose handoffs tightened. Printed code unchanged; plan decisions and baselines preserved.')
