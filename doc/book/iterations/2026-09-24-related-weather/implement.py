from pathlib import Path
import json,hashlib
R=Path.cwd();H=R/'doc/book/iterations/2026-09-24-related-weather'
def read(p):return p.read_text(encoding='utf-8-sig')
def load(p):return json.loads(read(p))
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/'commons/maps/Random_Noise_Types/map_data.json';d=load(p);assert len(d['layers']['structure'])==10
for name,rows in d['layers'].items():rows[9:9]=[(['w']+['1']*11+['w']) if name=='structure' else [' ']*13 for _ in range(18)]
d['layers']['interactables'][18][6]='related_weather'
assert d['layers']['utilities'][7][6]=='t'
d['layers']['utilities'][7][6]=' ';d['layers']['utilities'][27][6]='t'
d['map_info']['dimensions']['depth']=28;d['map_info']['museum']['sculpture_clear_rects'].append([1,9,11,26])
d['map_info']['title']='Which rules keep acting?';d['map_info']['metadata']['learning_objectives'].append('Distinguish raw temporal relationships from aperture limits, display history and smoothing')
save(p,d)
p=R/'commons/artifacts/registry/noise.json';d=load(p);d['artifacts']['related_weather']={'lookup_name':'related_weather','name':'Related weather','scene':'res://commons/artifacts/related_weather/related_weather.tscn','category':'noise','sequence':'noise','map_sequences':['noise'],'map_ready':True,'include_in_map_data':True,'parameters':{'footprint':[10,4,12],'size_group':'environment'},'description':'Three glazed viewing walls expose the latest eight samples as sight slits. Shared uniform innovations drive a fresh signal, accumulated steps and an approximate pink filter. Identical travel and aperture limits; fixed glass retains body collision. Local run/hold, single step, replay and fresh-seed controls. Raw signal verification and limits documented separately.','interactions':['Start the shared clock','Walk alongside the eight retained moments','Look through the aligned or separated slits','Hold during motion and finish a step','Replay the seeded record or choose a new seed'],'qfep_connection':'Memory can be written into a process and into its display. A smooth-looking wall may owe its agreement to filtering, to the shared motor, or to clipping at a limit. Different relations admit different views.','tags':['temporal_correlation','white_noise','random_walk','pink_noise','display_bounds','sight','history']};save(p,d)
passage='''<!-- @related_weather -->

Three walls wait beyond the listening benches. Their faces are closed. A narrow gold line stands on the far side. Start the clock and the walls acquire slits. A fragment of the line appears, disappears, returns somewhere else. Walk alongside it. Can you find a place from which the openings agree?

Each wall keeps eight moments. The newest arrives at the near end; earlier values move back through the display until the oldest leaves it. Your walk can run along a history that the machine no longer shows all at once.

The pale wall takes a fresh draw. The brown wall adds a little of that same draw to its previous value:

```gdscript
sum += 0.10 * white
```

Here the last place helps make the next one. Follow a run of openings along the brown wall, then return to the pale one. What does each let you anticipate? An independent sequence can also make a run. A few agreeable neighbours do not prove a rule.

The pink wall filters the shared draws. It carries several earlier inputs and outputs into each new value. It already had a past before you pressed RUN: the filter received 4,096 preparation samples. Those samples are not among the eight moments in front of you. We prepared this beginning; we did not remove its history.[^weather-filter]

All three walls travel with the same easing and the same clock. Watch a single opening in the pale wall move. Even independent targets can glide smoothly between their addresses. The motor can make continuity without giving the next draw any memory. Hold the motion, then finish one step with NEXT. Compare where the slit was going with how it got there.

An orange edge sometimes lights beneath an opening. The value wanted a place beyond the display's range. The raw calculation continues; the slit stays within its frame. Two different numbers can meet the same limit and appear to agree. A tidy row is not always a shared tendency. Sometimes it is a ceiling.

Lean toward the gold line again. The slits admit a view; fixed glass keeps them from becoming passages. These walls alter what your position lets you see while keeping another boundary in place. The same rule could have been given doors, sound, ground. Here it is given sight.

REPLAY empties the record and restores the local seed. It repeats the targets and the filter's preparation, but you are now standing somewhere else. Stay there for another run. Which relation belongs to the numbers, which to the machine that presents them, and which only becomes possible from here?

'''
p=R/'commons/maps/Random_Noise_Types/final.md';s=read(p);anchor='We can leave this hall with more than one discovery.';assert '<!-- @related_weather -->' not in s
s=s.replace(anchor,passage+anchor)
s+='\n[^weather-filter]: This is a finite filter approximating pink noise, following [Julius O. Smith’s synthesis example](https://www.dsprelated.com/freebooks/sasp/Example_Synthesis_1_F_Noise.html). The signal is checked separately from the moving, bounded display; the measured frequency range and preparation are recorded in the tutorial companion. A pink colour does not establish a pink spectrum.\n';p.write_text(s,encoding='utf-8');(H/'new-passage.md').write_text(passage,encoding='utf-8')
p=R/'commons/maps/Random_Noise_Types/intent.md';s=read(p);s=s.replace('are primary, in that order.','remain primary, followed by related_weather.');s+='''

24 September — Related weather extends the existing encounters into three full-size viewing walls. Shared innovations, accumulated steps and a finite pink approximation move eight sight slits per wall. The visitor walks alongside recorded time and looks for alignment through the walls. Separate signal memory, display memory, matched motor smoothing, fixed gains and clipped aperture bounds. Glass collision stays fixed; an opening for sight is not a passage for the body. Preserve the listening studies and their distinction between illustrated curves and actual sound. Hall extends 13×10 to 13×28 without changing previous artifacts or structure rows; the exit moves from (6,7) to (6,27). New artifact at (6,18). Headset experience remains open.
''';p.write_text(s,encoding='utf-8')
p=R/'commons/maps/Random_Noise_Types/technical.md';s=read(p);s+='''

## Related weather — 24 September 2026

`related_weather` at (6,18) adds three fixed glazed walls to the extended 13×28 hall. Their eight slits each show the newest eight accepted targets; the oldest visible slot is seven samples behind the newest. Opaque panels move but the glass collision stays fixed. Side and end aisles allow the body to move around the walls. Existing four artifacts, their configurations and all prior structure rows remain. Eighteen rows are inserted before former row 9; the teleporter moves from (6,7) to the final doorway (6,27).

`weather_signals.gd` supplies a seeded uniform innovation u in [-1,1] to all three channels. White returns u. The walk adds 0.10u to its unbounded sum. Pink uses the third-order IIR coefficients in [Julius O. Smith, Example: Synthesis of 1/F Noise](https://www.dsprelated.com/freebooks/sasp/Example_Synthesis_1_F_Noise.html). It receives 4096 preparation samples; the visible walk starts at zero afterward. Uniform rather than Gaussian innovations change the marginal distribution, not the filter transfer function. Neither the raw walk nor the raw pink output is clamped in the model.

The display uses fixed gains [1,1,11.6], then y = 1.70 + 0.75 * clamp(value,-1,1), with a 0.64 m sight slit. Orange slot markers identify target clipping. The gain is fixed for every seed, not recalculated to fit each run. Values on the console are before this clamp, with the pink display gain applied. No claim that these three marginal distributions are equal. Raw values, bounds and visible motor motion are distinct layers.

All channels share a one-second cubic smoothstep movement and a one-second dwell. RUN starts or resumes, HOLD pauses both pending travel and clock. NEXT starts one sample or finishes the currently paused stroke without drawing again. REPLAY cancels pending motion, clears the record and repeats filter preparation and visible targets from the same seed. NEW SEED clears with a different seed, which does not guarantee a different-looking short run. The record stops explicitly at 128 samples; the display retains eight and does not silently loop. Glass collision does not move during these controls.

The spectral check exports actual production-model samples, before gain, clipping or motor motion. It uses a stated Welch estimate and frequency band; the report accompanies this review. No spectral claim is made about eight visible targets, eased shutter trajectories or the older unmeasured audio filters. The new record is an architectural time-series display, not an acoustic measurement or a new proof of blue-noise spacing.
''';p.write_text(s,encoding='utf-8')
primaries=['randompoint','randompoints','WhiteNoiseGallery','NoiseColors3D','related_weather']
p=R/'commons/maps/sequences/noise.json';d=load(p)
for group in d['sequences']['noise']['artifact_groups']:
 if group['map']=='Random_Noise_Types':
  group['artifacts']=primaries;group['size_budget']='environment';group['rationale']='From enforced coordinates and initial spacing to independent image/audio constructions, then temporal relationships embodied as moving views.'
save(p,d)
p=R/'commons/data/museum_core_encounters.json';d=load(p);room=d['rooms']['Random_Noise_Types'];room['primary_tokens']=primaries;room['reason']='Constraint can act on position, admission, temporal state or the view. Preserve all four established studies and add the embodied temporal comparison.'
for key,f in [('text','final.md'),('map','map_data.json')]:room[key+'_sha256']=hashlib.sha256((R/'commons/maps/Random_Noise_Types'/f).read_bytes()).hexdigest()
room['local_review']='doc/book/iterations/2026-09-24-related-weather/DECISIONS.md';save(p,d)
print('Viewing walls placed; earlier artifacts and structure retained; exit moved to new end.')
