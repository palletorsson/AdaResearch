from pathlib import Path
import json

BASE = Path('doc/book/iterations/2026-09-19-wavefunctions-review/ending')

def replace(path, old, new):
    p = Path(path)
    data = p.read_bytes()
    a, b = old.encode(), new.encode()
    assert data.count(a) == 1, (path, old)
    p.write_bytes(data.replace(a, b))

replacements = {
 'algorithms/wavefunctions/resonance/ResonatingMetallophone.gd': [
  ('# emerges: music from physics — the pentatonic scale emerges from choosing bar lengths', '# emerges: chosen note frequencies become synthesized tones and determine visible bar lengths'),
  ('# relationships: depends on ResonatingBar physics;', '# relationships: depends on ResonatingBar strike detection and synthesized audio;'),
  ('# truth: Every object has frequencies at which it wants to vibrate — striking reveals its voice.', '# truth: This instrument chooses its notes first; a strike restarts the chosen decaying sine voice.')],
 'algorithms/wavefunctions/resonance/ResonatingBar.gd': [
  ('@export var decay_time: float = 3.0  # How long the sound lasts in seconds', '@export var decay_time: float = 3.0  # Exponential time constant; stored duration is 2.5 times this'),
  ('const SOUND_DURATION = 5.0  # the shipped buffer length; see _sound_seconds()', 'const SOUND_DURATION = 5.0  # Legacy constant; current buffer duration comes from _sound_seconds()')],
 'algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd': [
  ('# desire: drag two frequencies close together and hear/see the slow pulse emerge from their interference', '# desire: drag two frequencies close together and see the slow pulse emerge from their interference'),
  ('# truth: When two nearly identical things interfere, their tiny difference becomes the loudest signal.', '# truth: The frequency difference appears as a slow visual envelope; this artifact produces no audio.')],
 'algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.gd': [
  ('# essence: r(theta) = base_radius + sine_mod * sin(mod_freq * theta), y = step_rise * i', '# essence: r(theta) = BASE_RADIUS + WALKWAY_OFFSET + WAVE_AMPLITUDE * sin(WAVE_FREQUENCY * theta); tread top y = STEP_RISE * i'),
  ('# critical_parameter: SINE_MODULATION — amplitude of the radial sine wave that makes the staircase breathe', '# critical_parameter: WAVE_AMPLITUDE — amplitude of the radial sine wave that makes the staircase breathe'),
  ('# emerges: a walkable sine function wrapped into architecture — your body traces the wave by climbing', '# emerges: sampled positions become treads with optional provisions; continuous ascent still requires a walking check'),
  ('# needs: VR locomotion and collision [has], staircase physics [has]', '# needs: tread and membrane collision [has], full ascent/headroom/headset comfort [unverified]')],
 'algorithms/wavefunctions/oscillation_driver/TrigWalkingPath.gd': [
  ('# essence: x_sin(z) = A*sin(omega*z), x_cos(z) = A*cos(omega*z) — dual walkable trig paths', '# essence: fixed lane X, shared sloping base plus A*sin(phase) or A*cos(phase) in Y — two finite rows of collidable steps'),
  ('# triggers: player Z-position generates new steps ahead; escalator-like phase scroll', '# triggers: startup creates path_length step pairs; optional escalator mode circulates the existing rows in opposite directions')],
}
for path, changes in replacements.items():
    for old, new in changes: replace(path, old, new)

# Change only quoted metadata values, keeping every authored layer and formatting byte.
p = 'commons/maps/WaveFunctions_TrigWalkingPath/map_data.json'
replace(p, '"title": "Walk the Trig Function"', '"title": "A Slow Pulse from Fast Motions"')
replace(p, '"description": "Trig Walking Path"', '"description": "Compare two adjustable visual oscillations with their half-scaled sum. Nearby frequencies produce a slow envelope; equal frequencies remove that beating. The finite TrigWalkingPath remains a secondary spatial comparison alongside sine oscillation, Lissajous curves and wave interference."')
replace(p, '"learning_objectives": [ "Wavefunctions" ]', '"learning_objectives": [ "Compare two frequencies with their visual sum", "Relate the slow envelope to absolute frequency difference", "Distinguish half-scaled display height from the raw sum", "Keep visual beats distinct from audible demonstrations" ]')
p = 'commons/maps/Wavefunctions_Sky_Stairs/map_data.json'
m = json.loads(Path(p).read_text(encoding='utf-8'))
replace(p, json.dumps(m['map_info']['description'],ensure_ascii=False), json.dumps('Inspect a single helical staircase whose tread radius varies sinusoidally while height rises uniformly. Compare sampled centres, tread edges and the membranes joining them from the surrounding floor. Mathematical objects, a cube and the dark sphere remain secondary references. Full ascent, headroom and headset comfort are not established by the visible outline.',ensure_ascii=False))
replace(p, '"learning_objectives": [ "Sine-modulated geometry as architecture", "Vertical oscillation and spatial sampling", "Embodied waveform tracing through climbing", "Phase relationships in 3D space" ]', '"learning_objectives": [ "Distinguish angular progression, radial sine modulation and uniform rise", "Compare sampled centres with tread edges and connections", "Recognize that collision geometry does not establish a usable full ascent", "Inspect provisions for different bodies from accessible viewpoints" ]')

# Preserve the earlier designs verbatim, with a current source-grounded entry above them.
prefixes = {
 'WaveFunctions_TrigWalkingPath': '''# Current hall: a slow pulse from fast motions

`beat_frequency_demo` is the primary. Its two controls set frequencies from 1 to 10 Hz. The three rows show A, B and half of their raw sum. Close frequencies give a slow envelope; equal frequencies remove the beating in this fixed-phase demonstration. The display is visual only. See [the chapter](final.md) for the encounter and `algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd` for the implementation.

The secondary `TrigWalkingPath` remains in the room. Its shipped scene creates forty pairs of collidable steps once, adds end platforms, then circulates the two rows in opposite directions. Their heights combine a shared sloping base with sine or cosine. There is no visitor-triggered generation, cross-bridge or linked chart in that source. The other secondary works are `sine_oscillation`, `lissajous_curves` and `wave_interference`; `dark_sphere` remains the reference object. The next hall compares five fixed harmonic frequencies in the Synthesis Lab.

## Archived design proposal

The text below is preserved from an earlier design. Its endless generation, cross-bridge, entrance controls and linked chart are proposals, not descriptions of the current hall. Its code is illustrative, not an extract from the shipped artifact. The current chapter and the source named above take precedence.

---

''',
 'Wavefunctions_Sky_Stairs': '''# Current hall: what a curve needs from a stair

The primary `sine_cylinder_staircase` builds one helix of eighty treads. With the shipped scene parameters, the tread top rises by 0.11 per sample while the radius is `2.5 + 0.45 * sin(2 * angle)`. The angle completes two turns. This is radial modulation with uniform rise, not three parallel staircases or a sine-shaped height profile.

The default `membrane` provision joins neighbouring tread edges with visible quads and matching colliders, lifted by the configured 0.3 offset. Other source options are `none`, `rail` and `posts`; they change the provision around the same sampled path. The chapter begins with three visible treads inspected from the surrounding floor. Treads and colliders alone do not establish a complete ascent, suitable headroom or headset comfort. `math_objects`, `cube_scene` and `dark_sphere` remain in the hall; their presence does not implement the floating wave-density field described in the earlier proposal. See [the chapter](final.md) and `algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.gd`.

## Archived design proposal

The text below is preserved from an earlier design. Its three staircases, variable-rise climb, altitude chart and wave-density cube fields are proposals, not descriptions of the current hall. Its code is illustrative, not an extract from the shipped artifact. Full walking and headset claims remain unverified.

---

'''
}
for hall, prefix in prefixes.items():
    for name in ['intent.md','summary.md','technical.md','tutorial.md','critical.md']:
        p=Path('commons/maps')/hall/name
        old=p.read_bytes()
        p.write_bytes(prefix.replace('\n','\r\n').encode()+old)

replace('commons/maps/WaveFunctions_TrigWalkingPath/artifacts.md', '> Sine and cosine become architecture. Two lanes of steps rise and fall according to trigonometric functions — one traces sin, the other cos — and the learner walks the wave. Each footfall lands on a computed position. The path generates itself ahead, an escalator of pure math, lit from below.', '> Primary: Beat Frequency Demo. Compare the two visual oscillations with their half-scaled sum, then change their frequency difference. The finite TrigWalkingPath and the other oscillation studies remain secondary comparisons.')
replace('commons/maps/WaveFunctions_TrigWalkingPath/artifacts.md', 'Walkable path generated by trig functions', 'Secondary: two finite rows of collidable steps, with sine/cosine height modulation and opposite-direction escalator motion. Full traversal is not verified by this review.')
replace('commons/maps/Wavefunctions_Sky_Stairs/artifacts.md', '> Ascent through oscillation. Stairs that climb along sine curves — each step a moment in a wave cycle. Rising through space by following frequency, the spiral staircase as helix, vertical progress as rotational persistence.', '> Inspect one helix with radial sine modulation and uniform rise. Compare tread centres, edges and connecting membranes from the surrounding floor; a full ascent still needs testing.')

blurbs={
 'WaveFunctions_TrigWalkingPath':'Two fast motions make a slow pulse. Compare A, B and their half-scaled sum, then bring the two frequencies together. The beat display is visual only; the finite sine/cosine escalator remains nearby as a different way to place oscillation in space.\n',
 'Wavefunctions_Sky_Stairs':'The outline breathes inward and outward as the treads climb at a steady rise. Follow three neighbouring steps with your eyes, then compare their edges and the membranes joining them. A sampled curve supplies positions; a route for a body needs more.\n'
}
for hall,text in blurbs.items(): (Path('commons/maps')/hall/'blurb.md').write_text(text,encoding='utf-8')
