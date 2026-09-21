"""Build the Synthesis Lab review from the independent hall run and current book."""
from pathlib import Path
import hashlib
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/research/possible-bodies'
REC = ROOT / 'doc/space/synthesis-lab-review-2026-09-12'
RUN = ROOT / 'ada_run/synthesis-lab-review-2026-09-12'
MAP = 'WaveFunctions_Synthesis_Lab'
HALL = RUN / MAP
run = json.loads((RUN / 'run.json').read_text(encoding='utf-8'))
assert run['exit'] == 0 and run['checks'] == 110 and not run['failures']
assert run['sources_unchanged'] and run['original_hand_unchanged']
manifest = []


def copy(src, name):
    shutil.copyfile(src, OUT / name)
    manifest.append(name)


def save(name, text):
    (OUT / name).write_bytes(text.encode('utf-8'))
    manifest.append(name)


for src, name in [
    ('probe_synthesis_lab_desktop_front_live.png', 'synthesis-lab-bench.png'),
    ('probe_synthesis_lab_h1_alone.png', 'synthesis-lab-one.png'),
    ('probe_synthesis_lab_readout_live.png', 'synthesis-lab-readout.png'),
    ('probe_synthesis_lab_live.json', 'synthesis-lab-check.json'),
]:
    copy(HALL / src, name)
copy(RUN / 'run.json', 'synthesis-lab-run.json')
for name in ['final', 'tutorial', 'technical', 'critical']:
    copy(ROOT / f'commons/maps/{MAP}/{name}.md', f'synthesis-lab-{name}.md')

text = '''# The curve continues after its name ends

[AirMusic](air-music.html) → **Synthesis Lab** → [Random Definition](random-definition.html)

[The primary and its book passage](/necklace/thread?map=WaveFunctions_Synthesis_Lab&role=primary) · [Wavefunctions work plan](/research/waves-chance-noise/index.html#WaveFunctions_Synthesis_Lab)

At the bench, the sum is already waiting. A pale curve climbs and falls above five colored rows. None of those rows has the shape of the whole. **Which part would you remove first?**

Claude's five-slider bench, housed readout, clear approaches and miniature hallway remain. This review repairs the names the instrument gives its constructions and brings the book closer to what a visitor can actually do. All 25 placed artifacts remain; `additive_wave_demo` is the one primary the book follows.

![The bench from the desktop operating position, with the sum, five components, controls and readout](synthesis-lab-bench.png)

## Take away, predict, return

Press HOLD and lower the four sliders below H1. The extra rows disappear; a sine remains. H1 ALONE performs that removal together. BASELINE restores the five arrival amounts. Hold a phase and make the same comparison more than once.

![H1 alone: the pale total and the first component remain, drawn at different scales](synthesis-lab-one.png)

Bring H2 back. At the amber mark, predict whether it will raise or lower the total before reading the plate. The slider is a positive amount, but its sine can be negative at that position. Adding a term can lower the result.

The sum uses the same operation across the board:

```gdscript
var value = 0.0
for h in range(harmonic_amplitudes.size()):
    value += harmonic_amplitudes[h] * sin(phase * (h + 1))
return value
```

This bench is visual. It does not play its curves as audio. The continuity with AirMusic is the operation of adding contributions; the constraints have changed. Separate strikes could have separate ages. Here the five rows share one phase, multiplied by the integers one through five.

## The moment a name lets go

Restore BASELINE. Its fifth amount is 0.20. Raise it to 0.22: the sawtooth name remains. Raise it to 0.24: the label becomes Custom Waveform. The construction changed continuously. The name crossed a threshold.

| Setting | Revised label |
|---|---|
| One nonzero harmonic, including a quiet H1 | Pure Sine Wave |
| The arrival five, or all five scaled together | Approximately Sawtooth Wave |
| H4 or H5 moved well away from that recipe | Custom Waveform |
| Positive odd 1/n² terms | Odd 1/n² mix (positive terms) |
| All five zero | Zero waveform |

The old detector sometimes ignored the upper sliders and could misname a quieter lone sine as a triangle. The repaired detector checks every coefficient relative to H1, with a tolerance of 0.025. It names a neighborhood of recipes; it does not turn a finite sum into an ideal discontinuous wave.

The old source preset called `triangle` also reveals a limit: its odd terms are all positive. A triangle in this orientation needs alternating signs. Those coefficients remain available under the existing source configuration, with a more accurate label. A negative amount would require a control beyond the five supplied here.

## Something can leave the picture and remain in the sum

A component below 0.01 disappears from the ladder while the total still includes it. The formula rounds coefficients to one decimal place; the plate uses two. At some marks the sum of visible rows can disagree with the complete total. These are different decisions about what to show, rather than a single disappearance.

![The tilted readout compares the contributions at the mark, their drawn sum, and the full total](synthesis-lab-readout.png)

The ladder also uses a smaller drawing scale than the total and separates the components vertically. Add their values, not their literal heights on the board. The sampled baseline has a rounded rise of about 8.6 cm within a 50 cm cycle. Five smooth terms can suggest a corner without making an exact one. Other amounts can produce larger peaks; 1.58 is this baseline's peak, not a ceiling imposed on every sum.

This gives the question “what bodies are possible?” a specific set of tools: five nonnegative coefficients, integer harmonics and one shared phase. There is room for many unfamiliar shapes inside those constraints. There are also forms that would require another operation. Custom Waveform is a place to begin looking.

## Review and next visit

**110 independent desktop checks passed, with zero failures and engine exit 0.** They include real slider paths, a desktop pointer drag, panel presses, sum-versus-component geometry, readout values, approaches, cleanup and rebuilding. Ten coefficient settings also check the revised names and compare all 256 drawn sum samples with independent arithmetic; the largest error was below 9 × 10⁻⁸.

The book hero now agrees with the existing primary, `additive_wave_demo`. Thirteen production-code excerpts were checked across the revised final and tutorial. A stale `coloredlines` entry was removed from the book and role list; Claude had already removed its placement in the earlier visual pass.

Headset reach and label legibility remain for a later visit. Higher sums extend beyond the dark backing and can approach the upper lettering; that staging limit remains visible in this review. The nearby radio is independent of the bench. No human listening observation is claimed.

[Desktop report](synthesis-lab-check.json) · [Run receipt](synthesis-lab-run.json) · [Tutorial](synthesis-lab-tutorial.md) · [Technical notes](synthesis-lab-technical.md) · [Critical text](synthesis-lab-critical.md)

**Next: [Random Definition](random-definition.html).** BASELINE returns the five amounts without rewinding the clock. Repeating a recipe and repeating an exact instant require different state. The next hall asks what else must be kept for an unfamiliar result to return.
'''
final = (ROOT / f'commons/maps/{MAP}/final.md').read_text(encoding='utf-8')
save('synthesis-lab.md', text + '\n## Book passage\n\n' + final)
style = (OUT / 'air-music.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
body = markdown.markdown(text, extensions=['tables', 'fenced_code'])
body += '<details><summary>Read the book passage</summary>' + markdown.markdown(final, extensions=['fenced_code']) + '</details>'
save('synthesis-lab.html', '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The sum on the bench · Ada Research</title><style>' + style + '</style></head><body><main>' + body + '</main></body></html>\n')
(REC / 'publication-manifest.json').write_bytes((json.dumps(manifest, indent=2) + '\n').encode('utf-8'))
(REC / 'publication-hashes.json').write_bytes((json.dumps({n: hashlib.sha256((OUT / n).read_bytes()).hexdigest() for n in manifest}, indent=2) + '\n').encode('utf-8'))
print(json.dumps({'files': len(manifest), 'checks': run['checks']}))
