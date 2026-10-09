from pathlib import Path
import json
root=Path.cwd()
base=root/'doc/book/iterations/2026-09-19-wavefunctions-review/middle'
prose=[]
def replace(mapname,old,new):
    path=f'commons/maps/{mapname}/final.md'
    assert old in (root/path).read_text(encoding='utf8'),path
    prose.append({'path':path,'old':old,'new':new})
replace('WaveFunctions_3D_Wave_Propagation',
"Choose one sphere near the centre of the lattice. Follow that sphere alone for several movements. Then widen your attention to its neighbours. Compare when they rise together and when their displacements differ, without abandoning your first sphere as a reference.",
"Choose one sphere near the centre of the lattice. Follow that sphere alone for several movements. Then widen your attention to its neighbours. Their movement can be much smaller. Compare when they rise together and when their displacements differ, without abandoning your first sphere as a reference. The panel begins with COUPLED and SINE. RESET returns the same still lattice and starts its drive again.")
replace('WaveFunctions_3D_Wave_Propagation',
"Each oscillator has its own restoring influence towards an equilibrium and a damping term that resists its velocity. Coupling adds another influence: a neighbour displaced differently contributes a force. The program gathers those forces and then updates the oscillators' velocities and displacements. The centre receives a continuing excitation in this version, so the surrounding motion has a source.",
"Now select PULSE on the panel. After a short wait, the centre receives one push. Follow what happens beyond it. Change COUPLED to INDEPENDENT and watch the same push from the same still beginning. What has stopped travelling? Return to COUPLED before explaining the difference. Every button restarts the comparison; it does not cut a moving wave midway.\n\nEach oscillator has its own restoring influence towards an equilibrium and a damping term that resists its velocity. Coupling adds another influence: a neighbour displaced differently contributes a force. The program gathers those forces and then updates the oscillators' velocities and displacements. SINE keeps driving the centre; PULSE adds a single initial velocity after half a second. The same source can now be tried with and without the links.\n\nThe readout reports the largest displacement reached by one immediate neighbour since the reset, in millimetres. Under SINE it may be easy to miss that small response among the larger centre movements. PULSE makes a different comparison visible without changing the spring, mass or damping settings. A measurement can help you notice a motion; it does not replace watching which sphere moves next.")
replace('WaveFunctions_3D_Wave_Propagation',
"Changing the coupling or disconnecting selected neighbours would extend this investigation; those are proposed variations rather than controls available here.",
"The switch disconnects all the links at once. Removing only selected neighbours remains a further experiment: a different boundary inside the same lattice.")
replace('WaveFunctions_Effect_Sound',
"The room calls this FM synthesis. This expression implements phase modulation, which also changes instantaneous frequency.",
"The instrument names this phase modulation: an FM-style synthesis method that also changes instantaneous frequency.")
(base/'manuscript-proposals.json').write_text(json.dumps(prose,ensure_ascii=False,indent=2),encoding='utf8')
metadata=[]
def meta(mapname,keys,new):
    path=f'commons/maps/{mapname}/map_data.json';d=json.loads((root/path).read_text(encoding='utf8'))
    old=d
    for k in keys: old=old[k]
    metadata.append({'path':path,'keys':keys,'old':old,'new':new})
changes={
'WaveFunctions_3D_Wave_Propagation':(
 'Follow a disturbance through a finite lattice of coupled oscillators. Compare the same sine drive or one pulse with links present and absent. A nearby tiled wave display offers a contrasting analytic distance-field construction; its default attenuation is exponential.',
 ['Follow one sphere before reading a travelling pattern across the lattice','Compare identical starting states and forcing with coupling on or off','Distinguish a continuing sine drive from a single velocity pulse','Relate boundary behaviour to the number of neighbours','Compare local force integration with the secondary display’s analytic distance field; do not infer physical inverse-square energy transport from either display']),
'WaveFunctions_Effect_Sound':(
 'Two movable balls map six parameters of a phase-modulation/FM-style instrument. Establish a baseline, hold a reference and compare a changed note. A four-lane scope shows the modulation term, carrier, rule and output while the ear follows the full envelope.',
 ['Use BASELINE, HOLD, PLAY and COMPARE to hear one changed parameter','Map ball position to carrier frequency and envelope, and to modulation ratio, index and decay','Read modulation inside the carrier phase rather than as an added output voice','Separate the carrier envelope from the modulator envelope','Notice the scope’s normalization and short time window; preserve listening as evidence']),
'Wavefunctions_Bernini':(
 'Repeated spiral columns distinguish periodic change through height from rotation through time. A CPU-generated ring mesh combines sine/cosine centre offsets, radius variation and a changing angular phase, with procedural audio accompaniment.',
 ['Follow a shaft profile through height, then observe the shaft rotate through time','Relate circular sine/cosine coordinates to a helical centre path and radial variation','Distinguish generated mesh construction from a vertex-shader or noise deformation','Read the repetition of columns as intervals and sight lines','Treat architectural inspiration and generated accompaniment as situated choices, not a full historical account or a touch instrument']),
'WaveFunctions_John_Cage':(
 'Chance schedules playback within a prepared vocabulary of synthesized clips over drone and city-ambience layers. Luminous forms respond to sound activity. The Cage reference opens a question about authorship and listening; this artifact does not perform a particular Cage score.',
 ['Separate continuous layers from intermittent events by listening over time','Distinguish uncertain ordering from an open-ended sound vocabulary','Compare the envelope and texture of recurring prepared variations','Recognize that the luminous forms do not expose every scheduling choice or spatialize the audio','Ask what the composer has already decided before leaving event order to chance'])}
for name,(description,objectives) in changes.items():
    meta(name,['map_info','description'],description)
    meta(name,['map_info','metadata','learning_objectives'],objectives)
(base/'metadata-proposals.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf8')
print('proposed',len(prose),'manuscript replacements and',len(metadata),'metadata fields')
