"""Apply approved narrow proposals against captured originals; preserve unrelated work."""
from pathlib import Path
import hashlib, json, runpy

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def write(p, d): p.write_text(json.dumps(d, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

# Prepare targets before writing: a concurrent edit cannot be silently replaced.
targets = {}
for proposed in (HERE/'proposed').glob('*.md'):
    rel = f'commons/maps/{proposed.stem}/final.md'
    path = ROOT/rel
    original = (HERE/'before'/rel).read_text(encoding='utf-8')
    target = proposed.read_text(encoding='utf-8')
    assert path.read_text(encoding='utf-8') in (original, target), rel
    targets[path] = target
proposals = read(HERE/'opening/metadata-proposals.json') + read(HERE/'middle/metadata-proposals.json') + read(HERE/'middle/registry-proposals.json')
for p in read(HERE/'ending/root-proposals.json')['registry']:
    proposals.append(dict(path=p['path'], keys=['artifacts',p['key'],p['field']], old=p['old'], new=p['new']))
documents = {}
for p in proposals:
    path = ROOT/p['path']
    d = documents.setdefault(path, read(path))
    cursor = d
    for key in p['keys'][:-1]: cursor=cursor[key]
    key = p['keys'][-1]
    assert cursor[key] in (p['old'], p['new']), (p['path'],p['keys'])
    cursor[key] = p['new']
for p, text in targets.items():
    if p.read_text(encoding='utf-8') != text: p.write_text(text, encoding='utf-8')
for p, d in documents.items(): write(p,d)
runpy.run_path(str(HERE/'sequence_update.py'))

roles = read(ROOT/'commons/data/artifact_roles.json')
assert roles == read(HERE/'before/commons/data/artifact_roles.json'), 'Roles changed externally; reconcile explicitly.'
core_path = ROOT/'commons/data/museum_core_encounters.json'
core = read(core_path)
reasons = {
 'WaveFunctions_Intro':'Compare two returns to one position by their velocity; retain the prescribed and driven-motion companions.',
 'WaveFunctions_Pendulum':'Compare a movement with the finite, timestamped history that its sampler keeps.',
 'WaveFunctions_Sine_Space':'Try body size and relief, then distinguish moving visual walls from collision support.',
 'WaveFunctions_Unit_Circle':'Predict a turning point’s coordinate graph after meeting sine-shaped space; keep its rods attached under placement.',
 'WaveFunctions_3D_Wave_Propagation':'Compare the same reset and forcing with links present and absent; follow a neighbour before explaining transmission.',
 'WaveFunctions_Effect_Sound':'Keep a listening reference while moving the two parameter bodies; read the implemented phase modulation.',
 'Wavefunctions_Bernini':'Compare variation through height with rotation through time and with your own movement around a shaft.',
 'WaveFunctions_John_Cage':'Listen for what chance changes within the prepared vocabulary and what remains authored.',
 'WaveFunctions_AirMusic':'Strike, wait and restrike; compare a decaying voice with the sampled sum of independent bars.',
 'Wavefunctions_Sky_Stairs':'Inspect what a sampled curve needs to host a body; distinguish treads, membranes and a tested ascent.',
 'WaveFunctions_TrigWalkingPath':'Follow either input before reading their slower beat envelope; retain the finite moving path as a different construction.',
 'WaveFunctions_Synthesis_Lab':'Compare one harmonic with the arrival sum before receiving its recipe name; keep all coefficients visible.'
}
scopes = {
 'WaveFunctions_Intro':'Current source and historical 58-check desktop evidence; no full historical source fingerprint or new headset run.',
 'WaveFunctions_Pendulum':'Current source and historical 81-check desktop evidence; no full historical source fingerprint or new headset run.',
 'WaveFunctions_Sine_Space':'Current source; dated tray source/scene/probe/registry match earlier evidence, but whole-room configuration does not. Corridor evidence is historical.',
 'WaveFunctions_Unit_Circle':'Fresh isolated local/world transform regression: 102 checks; saved original fails 51. No complete museum walkthrough.',
 'WaveFunctions_3D_Wave_Propagation':'Fresh isolated comparison controls and bounded actual-museum placement/capture checks; see middle/AUDIT.md for reach limits.',
 'WaveFunctions_Effect_Sound':'Current DSP source and bounded actual-museum label capture; no new complete listening or headset session.',
 'Wavefunctions_Bernini':'Current mesh/audio source and restored route contract; no new runtime or headset validation of this encounter.',
 'WaveFunctions_John_Cage':'Current scheduling/audio source and restored route contract; no new listening or headset validation.',
 'WaveFunctions_AirMusic':'Fresh isolated PCM, per-bar retrigger and sample-sum checks; no full museum listening or headset session.',
 'Wavefunctions_Sky_Stairs':'Fresh isolated geometry/collider checks and restored route contract; complete ascent and headset comfort remain untested.',
 'WaveFunctions_TrigWalkingPath':'Fresh isolated beat algebra and finite path/collider checks; no complete physical traversal or headset session.',
 'WaveFunctions_Synthesis_Lab':'Fresh focused controls and actual-museum pointer/reveal/capture checks at standing eye height; no headset or learner validation.'
}
for name, reason in reasons.items():
    item=core['rooms'][name]
    item.update(reason=reason, primary_tokens=roles['order'][name]['primary'], learner_verified=False,
        map_sha256=sha(ROOT/f'commons/maps/{name}/map_data.json'),
        text_sha256=sha(ROOT/f'commons/maps/{name}/final.md'),
        local_review='doc/book/iterations/2026-09-19-wavefunctions-review/SUMMARY.md',
        verification_scope=scopes[name],
        status='source_checked_draft' if name in ['WaveFunctions_Intro','WaveFunctions_Pendulum','WaveFunctions_Sine_Space','Wavefunctions_Bernini','WaveFunctions_John_Cage'] else 'desktop_checked_headset_pending')
write(core_path,core)
write(HERE/'applied-metadata.json',proposals)
print(f'Applied {len(targets)} chapter revisions and {len(proposals)} metadata fields; all roles preserved.')
