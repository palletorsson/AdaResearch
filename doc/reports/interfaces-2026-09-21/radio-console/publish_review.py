from pathlib import Path
import hashlib
import json
import re
import shutil
import urllib.request

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SLUG = '2026-09-21-interface-radio-review'
dest = ROOT / 'doc/book/iterations' / SLUG
dest.mkdir(parents=True, exist_ok=True)
checks = json.loads((HERE / 'after/checks.json').read_text(encoding='utf-8'))
assert not checks['failures']
assert 'SCRIPT ERROR' not in (HERE / 'after/run.log').read_text(encoding='utf-8')
count = len(checks['checks'])
for stage, names in [('before', ['console', 'scale', 'presets', 'list', 'void']), ('after', ['console', 'scale', 'presets', 'list', 'void', 'operating', 'reference'])]:
    for name in names:
        shutil.copy2(HERE / stage / (name + '.png'), dest / (stage + '-' + name + '.png'))
    shutil.copy2(HERE / stage / 'checks.json', dest / (stage + '-checks.json'))
shutil.copy2(HERE / 'README.md', dest / 'implementation.md')
sources = [
    'commons/audio/rack_configs/SoundscapeRadioRack.gd',
    'commons/audio/rack_configs/SoundscapeRadioRack.tscn',
    'commons/audio/systems/SciFiLoFiSoundscape.gd',
    'commons/audio/SoundBankSingleton.gd',
    'commons/interactables/physical_angular_control.gd',
    'commons/interactables/wheel_smooth.tscn',
    'commons/interactables/InteractableDemo.gd',
    'commons/interactables/interactable_radio_demo.tscn',
    'commons/ui/interface_radio_reference.gd',
    'commons/testing/test_radio_console.gd',
    'commons/artifacts/registry/wavefunctions.json',
]
(dest / 'source-hashes.json').write_text(json.dumps({p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}, indent=2), encoding='utf-8')
previous = ROOT / 'doc/book/iterations/2026-09-21-interface-angular-review/index.html'
old = previous.read_text(encoding='utf-8')
style = re.search(r'<style>(.*?)</style>', old, re.S).group(1)
html = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Turn until you hear it · Ada Research</title><style>STYLE</style></head><body><main>
<div class="eyebrow">Ada Research · Interface workshop · 21 September 2026</div>
<h1>Turn until<br>you hear it.</h1>
<p class="lead">The soundscape radio now gives the hand enough room, and its readings agree with its controls.</p>
<span class="badge">COUNT desktop checks pass</span><span class="badge pending">Headset and listening review pending</span>
<figure><a href="after-scale.png"><img src="after-scale.png" alt="Rebuilt radio with full-size tuning and level wheels below a readable degree band and selected station name"></a><figcaption>Actual Godot render of the existing SoundscapeRadioRack. The selected third station is at 80°; the level wheel reads −6 dB.</figcaption></figure>
<h2>The hand, the number and the sound</h2>
<p>The old radio shrank its two controls, printed fictional FM values and let station shortcuts leave the physical wheel behind. The volume wheel had a dead negative range, and changing its value did not change layers already playing.</p>
<div class="pair"><figure><a href="before-console.png"><img src="before-console.png" alt="Original small radio assembly with reduced wheels and an 88 MHz label" loading="lazy"></a><figcaption>Before: the shared wheel repair had reached the radio, but its assembly still used the old sizes and labels.</figcaption></figure><figure><a href="after-console.png"><img src="after-console.png" alt="Larger supported radio panel with full-size wheels and a flat between-stations display" loading="lazy"></a><figcaption>After, from the same camera: full-size controls at 29 cm centres, with their readings seated on the backing.</figcaption></figure></div>
<p>Tuning now starts between stations at 20°. Turning the wheel moves the degree needle; choosing a station through code moves the wheel too. The level control covers −40 to 0 dB across its full travel and changes sounds already playing. The quiet end is attenuation, not a mute switch.</p>
<h2>Four ways to describe the same selection</h2>
<p>The existing variants are part of the encounter. Changing the panel changes which clues it gives you while preserving the selected sound.</p>
<div class="pair">
<figure><a href="after-scale.png"><img src="after-scale.png" alt="Scale face with continuous degree band, needle and station name" loading="lazy"></a><figcaption><strong>Scale:</strong> a position along a band. The gaps can be read.</figcaption></figure>
<figure><a href="after-presets.png"><img src="after-presets.png" alt="Preset face with nine station lamps and one selected lamp" loading="lazy"></a><figcaption><strong>Presets:</strong> nine discrete lamps. Between them, every lamp goes dark.</figcaption></figure>
<figure><a href="after-list.png"><img src="after-list.png" alt="List face showing nine names with the third highlighted" loading="lazy"></a><figcaption><strong>List:</strong> a named collection. The selected entry lights up.</figcaption></figure>
<figure><a href="after-void.png"><img src="after-void.png" alt="Listening-only face with dark screen and no numeric wheel readings" loading="lazy"></a><figcaption><strong>Void:</strong> two wheels, no station map and no numeric readings. Find the sound by listening.</figcaption></figure>
</div>
<h2>The interface reached into playback</h2>
<p>The player now resolves the sound IDs used by the shipped presets through the existing sound bank. Random-event sounds are prepared in the background. If you tune again while preparation is underway, the radio keeps the latest request; it does not wait for a worker to finish inside the wheel callback. Informative panels show when the selected sound is still being prepared.</p>
<p>This remains a threshold between preset centres and the existing drone used in the gaps. It does not simulate an FM receiver or continuously blend signal clarity.</p>
<h2>A reference, ready for the next placement check</h2>
<figure><a href="after-reference.png"><img src="after-reference.png" alt="The production radio inclined on an upright plinth in its focused InteractableDemo reference" loading="lazy"></a><figcaption>The actual radio in <code>interactable_radio_demo.tscn</code>. Audio startup is paused in this capture, so the preparation request remains visible.</figcaption></figure>
<p>COUNT checks cover the four face restrictions, actual XR Tools grabs and ray hits, station shortcuts, degree and dB agreement, queued selections, live audio gain and full-length mono loops. Separate checks exercise the real threaded player with short diagnostic streams and generate small production sounds. The visual radio fixture uses silent playback logging; screenshots are not evidence of perceived sound quality.</p>
<div class="note"><strong>Still open:</strong> headset reach and legibility, Quest performance and a full listening pass. Two legacy Nostromo sounds—<code>SciFi.space_ambience</code> and <code>SciFi.dystopian_alarm</code>—have no implementation found in the project. They remain explicit missing layers, with an incomplete-sound message on informative faces.</div>
<p>The shared radio scene is updated, including its existing museum uses. The larger case still needs checking in those halls; this page shows the assembled artifact and reference placement.</p>
<p><a href="after-checks.json">All checks</a> · <a href="before-checks.json">Baseline findings</a> · <a href="implementation.md">Implementation and reproduction notes</a> · <a href="source-hashes.json">Captured source hashes</a></p>
<footer><a href="../2026-09-21-interface-angular-review/index.html">Previous: place / keep moving</a><p>Next interface family: the stepped and returning levers, followed by their assembled placements. The unresolved radio sounds remain a separate, concrete audio task.</p></footer>
</main></body></html>'''.replace('STYLE', style).replace('COUNT', str(count))
(dest / 'index.html').write_text(html, encoding='utf-8')
if SLUG not in old:
    old = old.replace('</footer>', '<p><a href="../' + SLUG + '/index.html">Continue: the soundscape radio</a></p></footer>')
    previous.write_text(old, encoding='utf-8')
url = 'http://localhost:3003/book-review/doc/book/iterations/' + SLUG + '/index.html'
with urllib.request.urlopen(url, timeout=20) as response:
    assert response.status == 200
for name in re.findall(r'<img src="([^"]+)"', html):
    with urllib.request.urlopen(url.rsplit('/', 1)[0] + '/' + name, timeout=20) as response:
        assert response.status == 200
print(url)
print(count, 'passing checks; review and all displayed images served successfully')
