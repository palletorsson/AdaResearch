"""Reconstruct revised inputs and freeze a labelled same-agent revision rerun."""
from pathlib import Path
from datetime import datetime, timezone
import difflib
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
INITIAL = HERE.parent
GHOST = INITIAL.parent
INPUT = GHOST / 'final-input'
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def read(path): return path.read_text(encoding='utf-8')
text = read(INPUT / 'tutorial.md')
listings = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\s*\n(.*?)\n```', text, re.S)
assert {name for name, _ in listings} == {'triangle_record.gd', 'euclid_study.gd', 'point_body.gd', 'line_skin.gd'}
for name, source in listings:
    (HERE / name).write_text(source + '\n', encoding='utf-8', newline='\n')

intermediate_diff = ''.join(difflib.unified_diff(read(INITIAL / 'v2' / 'euclid_study.gd').splitlines(True), read(HERE / 'euclid_study.gd').splitlines(True), fromfile='v2/euclid_study.gd', tofile='v3/euclid_study.gd'))
(HERE / 'final_vs_intermediate.diff').write_text(intermediate_diff, encoding='utf-8')
print('Final versus intermediate source:')
print(intermediate_diff)

source_diffs = ''.join(''.join(difflib.unified_diff(read(INITIAL / name).splitlines(True), read(HERE / name).splitlines(True), fromfile='initial/' + name, tofile='v3/' + name)) for name, _ in listings)
(HERE / 'source.diff').write_text(source_diffs, encoding='utf-8')
packet_diffs = ''.join(''.join(difflib.unified_diff(read(GHOST / 'input' / name).splitlines(True), read(INPUT / name).splitlines(True), fromfile='initial/' + name, tofile='v3/' + name)) for name in ('tutorial.md', 'final.md'))
(HERE / 'packet.diff').write_text(packet_diffs, encoding='utf-8')
source_comparison = {name: {'initial_sha256': sha(INITIAL / name), 'revised_sha256': sha(HERE / name), 'identical': sha(INITIAL / name) == sha(HERE / name)} for name, _ in listings}
assert all(source_comparison[n]['identical'] for n in ('triangle_record.gd', 'point_body.gd', 'line_skin.gd'))
assert not source_comparison['euclid_study.gd']['identical']
assert read(GHOST / 'input' / 'final.md') == read(INPUT / 'final.md')
old_base = 'res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/student'
new_base = old_base + '/v3'
(HERE / 'minimal.tscn').write_text(read(INITIAL / 'minimal.tscn').replace(old_base, new_base), encoding='utf-8')

probe = read(INITIAL / 'primary_probe.gd').replace(old_base, new_base)
driver = '''
class SyntheticHand extends Node3D:
    var body: Node3D
    var target_pose: Vector3
    var driving: bool = false

    func _process(_delta: float) -> void:
        if driving: body.global_position = target_pose

    func _physics_process(_delta: float) -> void:
        if driving: body.global_position = target_pose

'''
probe = probe.replace('var checks: Array = []', driver + 'var checks: Array = []', 1)
probe = probe.replace('var pointer: Node3D', 'var pointer')
probe = probe.replace('    pointer = Node3D.new()\n    pointer.name = "SyntheticHand"\n    stage.add_child(pointer)\n', '')
probe = probe.replace('    current_scene = stage\n', '    current_scene = stage\n    pointer = SyntheticHand.new()\n    pointer.name = "ContinuousSyntheticHand"\n    stage.add_child(pointer)\n', 1)
probe = probe.replace('    point.global_position = hand_world\n', '    pointer.body = point\n    pointer.target_pose = hand_world\n    pointer.driving = true\n    point.global_position = hand_world\n', 1)
probe = probe.replace('    await frames()\n    vector_near("grab.after_frames_sphere_stays_with_hand"', '    for cycle in range(8):\n        await physics_frame\n        await process_frame\n    vector_near("grab.after_frames_sphere_stays_with_hand"', 1)
probe = probe.replace('    point.on_desktop_drop(pointer)\n', '    pointer.driving = false\n    point.on_desktop_drop(pointer)\n', 1)

presentation_helpers = '''func lowest_host_y(mesh_node: MeshInstance3D) -> float:
    var box = mesh_node.get_aabb()
    var lowest = INF
    for i in range(8):
        var local = box.position + Vector3(box.size.x if i & 1 else 0.0, box.size.y if i & 2 else 0.0, box.size.z if i & 4 else 0.0)
        lowest = minf(lowest, host.to_local(mesh_node.to_global(local)).y)
    return lowest

func presentation_checks() -> void:
    var top = host.get_child(0)
    var table_top = top.position.y + top.mesh.size.y * 0.5
    near("v3.table_top_y", table_top, 1.0)
    var text_count = 0
    var outlines_removed = true
    var zero_outline_count = 0
    for child in host.get_children():
        if child is Label3D:
            text_count += 1
            if child == host.readout:
                outlines_removed = outlines_removed and child.outline_size == 6 and child.outline_modulate == Color.WHITE
            else:
                outlines_removed = outlines_removed and child.outline_size == 0
                if child.outline_size == 0: zero_outline_count += 1
    check("v3.six_labels", text_count == 6, text_count, 6)
    check("v3.final_label_outline_policy", outlines_removed)
    check("v3.five_labels_without_outline", zero_outline_count == 5, zero_outline_count, 5)
    near("v3.readout_outline_size", host.readout.outline_size, 6.0)
    check("v3.readout_white_outline", host.readout.outline_modulate == Color.WHITE, str(host.readout.outline_modulate), "WHITE")
    for name in ["Guide", "Reset"]:
        var button = host.get_node(name)
        var cap = button.get_node("Button/ButtonMesh")
        var area = button.get_node("InteractableAreaButton")
        var local_up = host.global_basis.inverse() * cap.global_basis.y
        vector_near("v3." + name + ".cap_axis_faces_table_up", local_up.normalized(), Vector3.UP)
        near("v3." + name + ".root_height", button.position.y, 1.03)
        var rest_low = lowest_host_y(cap)
        near("v3." + name + ".rest_cap_bottom", rest_low, 1.035)
        check("v3." + name + ".rest_cap_above_table", rest_low > table_top, rest_low, table_top)
        area._on_button_entered(pointer)
        await create_timer(0.15).timeout
        var pressed_low = lowest_host_y(cap)
        near("v3." + name + ".pressed_cap_bottom", pressed_low, 1.015)
        check("v3." + name + ".pressed_cap_above_table", pressed_low > table_top, pressed_low, table_top)
        check("v3." + name + ".press_moved_down", pressed_low < rest_low - 0.019, pressed_low - rest_low, -0.02)
        area._on_button_exited(pointer)
        await create_timer(0.15).timeout
        near("v3." + name + ".released_cap_returns", lowest_host_y(cap), rest_low)

'''
probe = probe.replace('func run() -> void:\n', presentation_helpers + 'func run() -> void:\n', 1)
probe = probe.replace('    var failures = checks.filter', '    await presentation_checks()\n    var failures = checks.filter', 1)
probe = probe.replace('"probe": "primary"', '"probe": "v3_revision_primary_same_agent"')
probe = probe.replace('Headless full host, numerical geometry, synthetic area-button callbacks, desktop grab/drop and keyboard method dispatch. No physical XR/render claim.', 'Same-agent revision rerun. Headless full host, geometry, continuous synthetic hand pose, supplied area-button callbacks, keyboard method dispatch, numerical cap clearance/up-facing and outline checks. No physical XR/render claim.')
(HERE / 'primary_probe.gd').write_text(probe, encoding='utf-8')
(HERE / 'shear_probe.gd').write_text(read(INITIAL / 'shear_probe.gd').replace(old_base, new_base).replace('"probe": "independent_shear_variation"', '"probe": "v3_repeat_of_previously_predicted_shear"'), encoding='utf-8')
(HERE / 'probe.diff').write_text(''.join(difflib.unified_diff(read(INITIAL / 'primary_probe.gd').splitlines(True), probe.splitlines(True), fromfile='initial/primary_probe.gd', tofile='v3/primary_probe.gd')), encoding='utf-8')

predictions = {
    'frozen_at_utc': datetime.now(timezone.utc).isoformat(),
    'identity': 'Revision rerun by the same experienced coding AI; not a fresh ghost student.',
    'v3_engine_executed_yet': False,
    'prior_predictions_sha256': sha(INITIAL / 'predictions.json'),
    'geometry_and_shear_predictions': 'Unchanged from initial frozen predictions.json; both numerical source and variation are unchanged.',
    'grab_prediction': 'Continuous hand driver supplies world pose each process/physics frame. Rotated/translated host records A=(1,-1), keeps sphere at hand while held, and projects sphere on release to local (1,1.12,-1).',
    'presentation_predictions': {
        'table_top_local_y': 1.0,
        'button_root_local_y': 1.03,
        'cap_rest_min_local_y': 1.035,
        'cap_fully_pressed_min_local_y': 1.015,
        'cap_displacement': -.02,
        'cap_axis': 'Host-local +Y, including when host is rotated in world space.',
        'direct_label3d_count': 6,
        'outline_sizes': {'five_corner_and_button_labels': 0, 'readout': 6, 'readout_outline_color': 'WHITE'},
        'method': 'Transform actual cap mesh AABB corners into host local coordinates before and after the real button tween; headless geometry property check, not visual inspection.',
    },
    'verified_source_comparison': source_comparison,
    'verified_source_changes': ['euclid_study.gd adds outline_size=0 for three corner and two button labels; readout has outline_size=6 and outline_modulate=Color.WHITE.', 'Guide and Reset root heights change from 0.94 to 1.03.', 'make_button sets rotation=Vector3.ZERO, cancelling the supplied scene root rotation.', 'triangle_record.gd, point_body.gd and line_skin.gd identical.', 'final.md identical.'],
    'assistance': ['Parent supplied final visually checked packet and stated intended presentation changes; intermediate v2 was frozen but superseded before engine execution. I independently read both texts and generated packet/source diffs. No author probe/results or canonical source was inspected.', 'Initial grab failure and continuous-input follow-up inform this same-agent rerun; this is not independent fresh-reader evidence.'],
    'previous_intermediate_packet': 'student/v2 retained, no engine execution',
    'new_reads': [{'path': str(INPUT / name), 'sha256': sha(INPUT / name), 'scope': 'Complete revised lesson text'} for name in ('tutorial.md', 'final.md')],
    'reused_reads': 'Initial reading_assistance_log.json and followup_predictions.json; no new external source read.',
}
(HERE / 'predictions.json').write_text(json.dumps(predictions, indent=2), encoding='utf-8')
manifest = {'frozen_at_utc': datetime.now(timezone.utc).isoformat(), 'v3_engine_executed_yet': False,
            'sha256': {p.name: sha(p) for p in sorted(HERE.iterdir()) if p.is_file() and p.name != 'pre_run_manifest.json'},
            'input_sha256': {name: sha(INPUT / name) for name in ('tutorial.md', 'final.md')},
            'initial_evidence_sha256': {p.name: sha(p) for p in sorted(INITIAL.iterdir()) if p.is_file()}}
(HERE / 'pre_run_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(source_diffs)
print(json.dumps({'input_sha256': manifest['input_sha256'], 'source_comparison': source_comparison, 'frozen_files': len(manifest['sha256'])}, indent=2))
