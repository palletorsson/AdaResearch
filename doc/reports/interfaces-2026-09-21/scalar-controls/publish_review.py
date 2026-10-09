from pathlib import Path
import hashlib, json, re, shutil, urllib.request

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
SLUG='2026-09-21-interface-scalar-review'
dest=ROOT/'doc/book/iterations'/SLUG
dest.mkdir(parents=True,exist_ok=True)
checks=json.loads((HERE/'after/checks.json').read_text(encoding='utf-8'))
assert not checks['failures']
assert 'SCRIPT ERROR' not in (HERE/'after/run.log').read_text(encoding='utf-8')
assert 'SCRIPT ERROR' not in (HERE/'after/endpoint-capture.log').read_text(encoding='utf-8')
library_source=HERE.parent/'console-placement/after/checks.json'
library=json.loads(library_source.read_text(encoding='utf-8'))
assert not library['failures']
for p in (HERE/'after').glob('stops-*.png'):shutil.copy2(p,dest/p.name)
for name in ['page-0','page-8']:shutil.copy2(HERE/'before'/(name+'.png'),dest/('before-'+name+'.png'))
shutil.copy2(HERE/'after/checks.json',dest/'control-checks.json')
shutil.copy2(library_source,dest/'library-checks.json')
shutil.copy2(HERE/'after/mixer-regression.log',dest/'mixer-regression.log')
shutil.copy2(HERE/'after/library/report.json',dest/'gallery-placement-finding.json')
shutil.copy2(HERE/'README.md',dest/'implementation.md')
sources=[str(p.relative_to(HERE/'before/sources')).replace('\\','/') for p in (HERE/'before/sources').rglob('*') if p.is_file() and p.name!='.gdignore']
sources += ['commons/interactables/'+name+'.gd' for name in ['linear_driver','scalar_pointer','axis_slider_control']]
sources += ['commons/ui/demo/vr_component_demo.gd','commons/testing/test_scalar_library.gd','commons/testing/capture_scalar_endpoints.gd','commons/testing/probe_library_hall.gd']
(dest/'source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
prior=ROOT/'doc/book/iterations/2026-09-21-interface-library-review/index.html'
style=re.search(r'<style>(.*?)</style>',prior.read_text(encoding='utf-8'),re.S).group(1)
def picture(name,caption):
    return f'<figure><a href="{name}.png"><img src="{name}.png" alt="{caption}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'
html=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>The slot and the hand agree · Ada Research</title><style>{style}</style></head><body><main>
<div class="eyebrow">Ada Research · Interface workshop · 21 September 2026</div>
<h1>The slot and<br>the hand agree.</h1>
<p class="lead">A vertical fader travels up and down. Its minimum and maximum fit inside the plate. Turning the console preserves that relationship.</p>
<span class="badge">{len(checks['checks'])} control checks pass</span><span class="badge">173 library checks · 12 mixer checks</span><span class="badge pending">Headset testing remains</span>
<h2>From minimum to maximum</h2>
<div class="pair">{picture('stops-8-0','Minimum: the horizontal fader is left; the vertical fader is down.')}{picture('stops-8-1','Maximum: right and up. Both grips stay inside their backing plates.')}</div>
<p>The vertical audio fader previously used a horizontal driver and an unsupported axis setting. Its track now supplies the rotation. The horizontal audio fader also had an extra offset that put its travel to one side of the slot.</p>
<h2>Keep the differences</h2>
<div class="pair">{picture('stops-0-0','Four slider behaviors at their lower stops. The automatic slider is paused for this comparison.')}{picture('stops-0-1','The upper stops remain within the plates. The returning control returns to centre when released after interaction.')}</div>
<p>Smooth, automatic/manual, stepped, and return-to-centre controls stay distinct. The automatic slider yields while you operate it, then resumes. Small pointer movements accumulate across a detent. A second pointer cannot take over a held control.</p>
<h2>Turn the knob, keep the plane</h2>
<div class="pair">{picture('stops-2-1','The shared dials at maximum. The separately tested wheel retains its degree readout.')}{picture('stops-7-1','Audio dials use the same grab and pointer behavior, retaining their audio-facing API.')}</div>
<p>The knobs rotate in their face plane and their pickup regions sit on the visible grips. The same local-coordinate approach works when the whole console is inclined or turned in the hall.</p>
<details><summary>Original library captures</summary><div class="pair">{picture('before-page-0','Original vertical-slider page before this interaction repair.')}{picture('before-page-8','Original audio-fader page before correcting the axes and travel offsets.')}</div></details>
<p>These are actual Godot renders. Automated checks use native pickup, collision rays, and the production control scripts. The control tests cover reversals, limits, visible grip containment, axis direction, readouts, page guards and release behavior. The existing mounted-mixer test also passes.</p>
<div class="note">The furniture-gallery map is outside the current endless-museum route. The placement probe fell back to Point_One, so it is recorded as an unresolved placement finding. These screenshots show the production library scene, not a verified museum-hall installation. Headset reach, hand feel, listening and Quest performance remain to be tested.</div>
<p><a href="control-checks.json">Control checks</a> · <a href="library-checks.json">All-page checks</a> · <a href="mixer-regression.log">Mixer regression</a> · <a href="gallery-placement-finding.json">Placement finding</a> · <a href="implementation.md">Implementation and reproduction</a> · <a href="source-hashes.json">Source hashes</a></p>
<footer><a href="../2026-09-21-interface-library-review/index.html">Previous: one place to try every control</a><p>Next: a reachable test-room entry, then the mixed-control racks.</p></footer>
</main></body></html>'''
(dest/'index.html').write_text(html,encoding='utf-8')
url='http://localhost:3003/book-review/doc/book/iterations/'+SLUG+'/index.html'
for name in ['index.html']+re.findall(r'<img src="([^"]+)"',html):
    with urllib.request.urlopen(url.rsplit('/',1)[0]+'/'+name,timeout=20) as response:assert response.status==200
print(url)
print('Review and all displayed images return HTTP 200.')
