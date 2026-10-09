from pathlib import Path
import hashlib, json, re, shutil, urllib.request

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
SLUG='2026-09-21-interface-library-review'
dest=ROOT/'doc/book/iterations'/SLUG
dest.mkdir(parents=True,exist_ok=True)
library=json.loads((HERE/'after/checks.json').read_text(encoding='utf-8'))
radio=json.loads((HERE/'after/radio/report.json').read_text(encoding='utf-8'))
assert not library['failures'] and not radio['failures']
for folder in [HERE/'after',HERE/'after/radio']:
    assert 'SCRIPT ERROR' not in (folder/'run.log').read_text(encoding='utf-8',errors='replace')
for stage,names in [('before',['library']),('after',['library','levers','page-3','page-6','page-8','page-10'])]:
    for name in names:shutil.copy2(HERE/stage/(name+'.png'),dest/(stage+'-'+name+'.png'))
    shutil.copy2(HERE/stage/'checks.json',dest/(stage+'-checks.json'))
for stage in ['before','after']:
    for name in ['radio-operating','radio-approach']:
        shutil.copy2(HERE/stage/'radio'/(name+'.png'),dest/(stage+'-'+name+'.png'))
    shutil.copy2(HERE/stage/'radio/report.json',dest/(stage+'-radio-checks.json'))
shutil.copy2(HERE/'README.md',dest/'implementation.md')
sources=[
 'commons/audio/rack_configs/SoundscapeRadioRack.gd','commons/maps/Point_One/map_data.json',
 'commons/maps/Point_One/artifacts.md','commons/ui/demo/vr_component_demo.gd',
 'commons/ui/demo/vr_component_demo.tscn','commons/maps/Gallery_Furniture/map_data.json',
 'commons/artifacts/registry/furniture.json','commons/artifacts/registry/wavefunctions.json',
 'commons/audio/interfaces/SimpleWaveformDisplay.gd','commons/audio/systems/spectrum_analyzer_lease.gd',
 'algorithms/wavefunctions/spectralanalysis/GameSoundMeter.gd',
 'commons/testing/test_component_library.gd','commons/testing/probe_radio_readouts.gd',
 'commons/testing/probe_point_one_radio.gd',
]
(dest/'source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
prior=ROOT/'doc/book/iterations/2026-09-21-interface-lever-review/index.html'
style=re.search(r'<style>(.*?)</style>',prior.read_text(encoding='utf-8'),re.S).group(1)
count=len(library['checks'])+len(radio['checks'])
html='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>One place to try every control · Ada Research</title><style>STYLE</style></head><body><main>
<div class="eyebrow">Ada Research · Interface workshop · 21 September 2026</div>
<h1>One place to try<br>every control.</h1>
<p class="lead">The radio leans toward the reader. The component library brings each family to the same operating position.</p>
<span class="badge">COUNT focused checks pass</span><span class="badge pending">Headset testing remains</span>
<h2>Look past the grips</h2>
<div class="pair"><figure><a href="before-radio-operating.png"><img src="before-radio-operating.png" alt="Upright radio in Point One with grips partly covering the lower numerical readings"></a><figcaption>Before: from standing height, the physical grips cover part of the wheel readings.</figcaption></figure><figure><a href="after-radio-operating.png"><img src="after-radio-operating.png" alt="Inclined Point One radio with both numerical windows exposed beneath the wheels"></a><figcaption>After: a supported 32° incline presents the face toward the reader.</figcaption></figure></div>
<p>The same radio remains a secondary encounter in Point_One, at source cell (3,4), on its 0.85 m plinth. Its optional <code>orientation:inclined</code> setting preserves tuning, gain and the four face modes. Other placements retain their upright default.</p>
<figure><a href="after-radio-approach.png"><img src="after-radio-approach.png" alt="The inclined radio and support foot on their plinth in the actual Point One hall" loading="lazy"></a><figcaption>Actual museum geometry. Floor support, the final approach and grip reach pass the same checks as before. Both numeric windows now pass the sampled sight-line test.</figcaption></figure>
<h2>The controls come to the hand</h2>
<div class="pair"><figure><a href="before-library.png"><img src="before-library.png" alt="Old tall component library extending below the floor" loading="lazy"></a><figcaption>Before: a long vertical catalogue, with lower rows below floor level.</figcaption></figure><figure><a href="after-library.png"><img src="after-library.png" alt="A supported inclined component console with family selector and physical page buttons" loading="lazy"></a><figcaption>After: a floor-standing console, with every family brought to operating height.</figcaption></figure></div>
<p>All 28 specimen placements remain available across eleven pages. The physical Previous and Next buttons are grouped at 36 cm centres. Only the current page's controls are instantiated. A page loads fresh controls; paging waits for a held control or active drag to end.</p>
<figure><a href="after-levers.png"><img src="after-levers.png" alt="Continuous, stepped and returning levers on the new library console" loading="lazy"></a><figcaption>The lever family keeps its three behaviors. The same mount lets the hand compare them.</figcaption></figure>
<div class="pair"><figure><a href="after-page-3.png"><img src="after-page-3.png" alt="Three original button specimens on the shared library backing" loading="lazy"></a><figcaption>Buttons retain their physical caps and bases.</figcaption></figure><figure><a href="after-page-6.png"><img src="after-page-6.png" alt="The physical two-axis pad presented at operating height" loading="lazy"></a><figcaption>The XY pad gets room for both axes.</figcaption></figure><figure><a href="after-page-8.png"><img src="after-page-8.png" alt="Horizontal and vertical audio faders with backed flat value cards" loading="lazy"></a><figcaption>Legacy values stay connected to their controls and appear on flat cards.</figcaption></figure><figure><a href="after-page-10.png"><img src="after-page-10.png" alt="Signal monitors mounted as one library family" loading="lazy"></a><figcaption>Displays run while their page is present.</figcaption></figure></div>
<h2>Changing pages must also release resources</h2>
<p>The older audio displays left analysis effects on the audio bus after removal. Waveform views now share an owned analyser per bus; the last view releases it. Spectrum meters remove their own effect. Tests verify that repeated visits leave no extra effects and preserve unrelated audio work.</p>
<p>The library checks cover all pages, component counts, geometry, flat text, real pager targeting, held-control guards, value updates and audio resource lifetime. The Point_One checks exercise the production radio in the actual museum. The existing 78-check radio regression suite also passes.</p>
<div class="note">These images are Godot renders. Sight-line and input checks use measured desktop poses and synthetic events through the real control code. Seated reach, tracked hands, listening and standalone Quest performance still need testing. The library's older sliders and audio dials retain their existing input drivers; presentation checks do not establish that all their grabs are correct.</div>
<p><a href="after-checks.json">Library checks and dimensions</a> · <a href="after-radio-checks.json">Radio hall checks</a> · <a href="before-radio-checks.json">Original sight-line failures</a> · <a href="implementation.md">Implementation and reproduction</a> · <a href="source-hashes.json">Source hashes</a></p>
<footer><a href="../2026-09-21-interface-lever-review/index.html">Previous: what stays when you let go?</a><p>Next: audit the legacy slider and audio-dial grabs in this inclined setup, and test the library in its furniture hall.</p></footer>
</main></body></html>'''.replace('STYLE',style).replace('COUNT',str(count))
(dest/'index.html').write_text(html,encoding='utf-8')
url='http://localhost:3003/book-review/doc/book/iterations/'+SLUG+'/index.html'
for suffix in ['index.html']+re.findall(r'<img src="([^"]+)"',html):
    with urllib.request.urlopen(url.rsplit('/',1)[0]+'/'+suffix,timeout=20) as response:assert response.status==200
print(url)
print(count,'focused checks; review and all displayed images served successfully')
