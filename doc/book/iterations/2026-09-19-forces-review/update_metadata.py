"""Scoped source-aware metadata repair; registry objects remain independently reviewable."""
import copy
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def replace_entry(relative, key, update):
    path = ROOT / relative
    text = path.read_text(encoding='utf-8')
    match = re.search(r'(?m)^([ \t]*)' + re.escape(json.dumps(key)) + r'\s*:\s*', text)
    assert match, (relative, key)
    value, length = json.JSONDecoder().raw_decode(text[match.end():])
    update(value)
    indent = match.group(1)
    rendered = json.dumps(value, ensure_ascii=False, indent=2).replace('\n', '\n' + indent)
    path.write_text(text[:match.end()] + rendered + text[match.end()+length:], encoding='utf-8', newline='\n')


def patch(relative, key, **changes):
    replace_entry(relative, key, lambda value: value.update(changes))


if '--recover-arena' in sys.argv:
    for token in ['parlour_orbits', 'paused_fountain', 'prop_mobile', 'prop_spigot',
                  'revolving_door', 'three_gravities', 'umbrella_field']:
        patch('commons/artifacts/registry/vectors_demos.json', token, lookup_name=token, map_ready=True, include_in_map_data=True)
elif '--recover-kinetic' in sys.argv:
    for token in ['sisyphus_mower', 'prop_carousel']:
        patch('commons/artifacts/registry/vectors_demos.json', token, lookup_name=token, map_ready=True, include_in_map_data=True)
else:
    patch('commons/artifacts/registry/vectors_demos.json', 'torque_crank', description=
          'A LEVERAGE slider varies the angle between illustrated arm and push directions. Their normalized cross-product magnitude sin(theta) sets a static wheel pose from 0 to 48 degrees; no angular velocity or physical torque dynamics are integrated. The readout names the angular factor, input angle and wheel pose. Cyan arm, orange push and gold axis retain the cross-product construction. Seed changes the arm bearing; purchase variants exchange drawn arm/push lengths while preserving their product.')
    patch('commons/artifacts/registry/vectors.json', 'vector_normalize_demo',
          description='Compare a vector with its normalized direction. The implemented threshold uses the measured magnitude: greater than 0.001 returns a unit vector; at or below it returns zero. Direction is preserved when normalization is admitted, while magnitude is discarded.',
          qfep_connection='An example of chosen reduction: magnitude is discarded, and the numerical threshold decides which measured vectors retain a direction. This association is not a computed QFEP quantity.')
    patch('commons/artifacts/registry/hazards.json', 'four_leg_critter',
          description='Four-legged procedural walker. A prescribed body drift stretches the planted feet; the gait code selects the most stretched eligible leg and moves one leg at a time. In VFM_09_Legs this visible walking is compared with physical support, which this walker does not solve.',
          qfep_connection='The comparison exposes a choice hidden by a convincing gait: a branch selects one foot, and a commanded body does not negotiate support forces. The form is an opportunity to inspect that rule, not evidence that a diagonal trot or stable gait emerged from physics.')
    patch('commons/artifacts/registry/vectors_demos.json', 'vector_machine',
          description='A console composes a world-coordinate acceleration vector from pitch, yaw and magnitude and posts it to force_field receivers. The configured Force-as-Place lesson labels magnitude ACCEL, exposes an idle yaw at a vertical pole and begins at downward 9.8 m/s². Cube and visitor receivers retain and update motion differently; a drawn arrow alone does not guarantee passage.')
    patch('commons/artifacts/registry/vectors_demos.json', 'force_field_zone',
          description='A local acceleration volume with a wireframe boundary and field arrows. Unfrozen rigid bodies inside have ordinary gravity disabled and receive velocity += field_vector * delta, without division by mass; their contacts and damping remain. The museum visitor uses a separate velocity-carrying locomotion receiver, retaining incoming motion while inside and returning control on exit. The configured five-metre crossing keeps a solid plank for comparison. Legacy force naming identifies the artifact; the applied quantity is acceleration.')
    def ring(value):
        value['description'] = 'A body-scale prescribed circular path. The moving pod displays tangential velocity and the inward acceleration v²/r required by that path. The configured comparison changes speed between 2, 4 and 6 m/s while its radius stays at 3.4 metres; radius is separately configurable in source or map data. It does not integrate a force to obtain the orbit or automatically carry the visitor. The distinction between a drawn acceleration and a dynamic cause is part of the encounter.'
        value['parameters']['speed'] = '0..1 parameter mapped to prescribed linear speed 2..9 m/s'
    replace_entry('commons/artifacts/registry/vectors_demos.json', 'centrifuge_ring', ring)

    def sequence(value):
        keys = ['truth', 'description', 'demonstration', 'qfep_connection', 'learning_objectives', 'content']
        if not value.get('curation_history'):
            value['curation_history'] = [dict(date='2026-09-19', reason='Preserve the earlier overview while aligning current descriptions with the thirteen authored halls.', **{k: copy.deepcopy(value[k]) for k in keys})]
        value['truth'] = 'An arrow does not decide what happens. Its quantity, frame, receiver and retained state give it a consequence.'
        value['description'] = 'Thirteen halls follow vectors from portable displacement through operations, trajectories and carried velocity to contact, attraction, support and local acceleration. Compare what similar arrows ask different bodies to do. Bench diagrams, room-scale models and the museum visitor are deliberately different receivers.'
        value['demonstration'] = 'Move two endpoints together; compare routes with the same sum; retain the perpendicular remainder of a projection. Launch a prescribed trajectory, then let a rigid body retain motion after a push. Give two receivers the same field, compare drag, signed work and circular motion, release a spring, change timing, allow a source to respond, test support and targeting, then enter an acceleration field beside a loose cube.'
        value['qfep_connection'] = 'The sequence gives the research a set of inspectable choices: what a model retains, what its update changes, and which bodies can respond. Those choices support questions about possible bodies and exclusions. These exhibits do not collectively measure entropy or calculate a QFEP threshold.'
        value['learning_objectives'] = [
            'Distinguish endpoint coordinates, displacement, magnitude and normalized direction, including the chosen small-vector threshold.',
            'Compare addition, route length and cancellation; use subtraction, dot and projection to retain a relation and its remainder.',
            'Separate a normalized cross-product diagram from physical torque and angular dynamics.',
            'Distinguish a time-parameterized launch trajectory from velocity accumulated by a rigid body under force.',
            'Compare the same field sample used to set velocity or add acceleration.',
            'Distinguish physical drag, a locomotion adapter, signed nominal work and prescribed circular motion.',
            'Compare restoring force and damping, then phase offsets, frequency drift and a retained conveyor backlog.',
            'Compare a held source with mutual softened attraction and measure sensitivity under specified initial conditions.',
            'Compare physical support with commanded gait, target selection with collision, and local acceleration with receiver-specific movement.',
            'Inspect retained state and entry/exit boundaries; relate velocity and acceleration to the rates introduced in Change.'
        ]
        lines = [
            'portable displacement and a chosen normalization threshold', 'composition, destination and travelled route',
            'gap, classification, projection remainder and turning relation', 'analytic launch and complementary trajectories',
            'finite force, retained velocity, damping and a separate friction threshold', 'one field, two receiver rules',
            'drag, signed nominal work and a prescribed circle', 'restoring force, carried velocity and damping',
            'phase, frequency and accumulated backlog', 'held source, mutual response and initial difference',
            'physical support beside a commanded gait', 'sensing and feeding state beside collision constraints',
            'a local acceleration field received by cube and visitor'
        ]
        value['content'] = [name + ': ' + line for name, line in zip(value['maps'], lines)]
    replace_entry('commons/maps/sequences/forces.json', 'forces', sequence)

    objectives = {
        'VFM_03_Motion': ['Compare a finite push with coasting and braking', 'Observe how mass and damping change the response of a rigid body', 'Distinguish requested force from measured acceleration and contact response', 'Compare that dynamic body with the separate friction-ramp threshold model'],
        'Vectors_Act3_FieldsAndMotion': ['Sample the same vector field with two receivers', 'Compare setting velocity with accumulating acceleration', 'Test how retained state changes the response to reversal and gain', 'Reveal the receiver rules after observing trajectories'],
        'Vectors_Act5_ForceAsPlace': ['Compose a local acceleration vector, including the idle yaw at a vertical pole', 'Compare loose-cube and visitor receivers and their retained motion', 'Distinguish zero acceleration from zero velocity', 'Compare the field crossing with the retained plank and inspect the locomotion boundary']
    }
    for name, lines in objectives.items():
        patch(f'commons/maps/{name}/map_data.json', 'metadata', learning_objectives=lines)
print('Scoped Forces metadata updated', ' '.join(sys.argv[1:]))
