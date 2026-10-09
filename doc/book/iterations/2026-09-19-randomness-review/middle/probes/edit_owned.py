from pathlib import Path
import hashlib, json, difflib
root = Path.cwd()
base = root/'doc/book/iterations/2026-09-19-randomness-review/middle'
paths = ['commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd','algorithms/randomness/randomdecay/scripts/random_decay_multimesh.gd']
for p in paths:
    assert hashlib.sha256((root/p).read_bytes()).hexdigest() == json.loads((base/'before-sha256.json').read_text())[p], p
p=root/paths[0]; s=p.read_text(encoding='utf-8')
start=s.index('# Algorithm:'); end=s.index('\nextends Node3D')
s=s[:start]+'''# Algorithm: Uniform headings in 2D or 3D, plus a bounded long-step mode.
# Each walker retains its current position and RNG state. The displayed trail
# is recorded but is not consulted by the next step; glass reflects endpoints.
# MSD reports the five walkers' squared displacement inside this finite box.
#
# @identity
# essence: next_position = reflect(position + sampled_step)
# desire: follow one walk, then compare its current position with its partial record
# critical_parameter: walk_mode — planar, volumetric, or capped inverse-square-root step lengths
# triggers: mode buttons change the generator; RESET replays a named seed with the same settings
# emerges: changing a direction or length rule changes the retained tangle within the same glass
# needs: VR mode buttons [has], reset button [has], trail rendering via ImmediateMesh [has]
# relationships: contrasts with random_walk_leash (observed vs felt); feeds random_walk_collection and pixel_cloud
# truth: A visible history is not yet a history the next step can use.
''' + s[end:]
replacements={
'"label": "LEVY"':'"label": "LONG\\nSTEP"',
'# Mode buttons: 2D (Btn_0), 3D (Btn_1), LEVY (Btn_2)':'# Mode buttons: 2D (Btn_0), 3D (Btn_1), LONG STEP (Btn_2)',
'# Lévy flight: occasional large jumps':'# Bounded long-step sampler; the legacy enum name is retained for saved configurations.',
'["2D", "3D", "Lévy"]':'["2D", "3D", "Long step"]',
'"LEVY · 3D · step':'"LONG STEP · 3D · step',
'"glass folds a step back · LEVY cap':'"glass folds a step back · length cap',
'["2D", "3D", "LEVY"]':'["2D", "3D", "LONG STEP"]',
}
for old,new in replacements.items():
    assert old in s,old
    s=s.replace(old,new)
p.write_text(s,encoding='utf-8',newline='\n')
p=root/paths[1];s=p.read_text(encoding='utf-8')
s=s.replace('# desire: watch two pristine stacks slowly crumble — drift, darken, sink — and feel entropy win','# desire: watch two arranged stacks drift, darken and sink under different configured rates')
s=s.replace('# emerges: each instance decays at its own rate — the grid becomes a ruin uniquely every time','# emerges: bounded stochastic perturbations accumulate; the fixed sizes and unequal rates constrain the comparison')
s=s.replace('# truth: Decay is not failure — it is matter remembering that arrangement is improbable.','# truth: This authored decay process is not a measurement of thermodynamic entropy.')
s=s.replace('# - 1dm prisms with smaller spacing','# - prisms with smaller spacing; force_uniform_item_size makes these 1m too')
old='\t\tdecay_active = not decay_active\n\t\tif decay_active:\n\t\t\t_decay_elapsed = 0.0'
assert s.count(old)==1;s=s.replace(old,'\t\t_toggle_decay()')
old='\t\t\t\tdecay_active = not decay_active\n\t\t\t\tif decay_active:\n\t\t\t\t\t_decay_elapsed = 0.0'
assert s.count(old)==1;s=s.replace(old,'\t\t\t\t_toggle_decay()')
anchor='func _create_vr_controls() -> void:'
s=s.replace(anchor,'# Pause preserves the accumulated startup/ramp time; only RESET starts it over.\nfunc _toggle_decay() -> void:\n\tdecay_active = not decay_active\n\n'+anchor)
p.write_text(s,encoding='utf-8',newline='\n')
diff=[]
for path in paths:
    diff.extend(difflib.unified_diff((base/'before-source'/path).read_text(encoding='utf-8').splitlines(True),(root/path).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+path,tofile='after/'+path))
(base/'owned-source.diff').write_text(''.join(diff),encoding='utf-8')
print('Updated bounded labels and pause clock; sampler/export names unchanged.')
