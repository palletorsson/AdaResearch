"""Publish the local review, using actual tested Godot museum captures."""
from pathlib import Path
import json
import shutil
import sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
GALLERY = ROOT / 'doc/space/random-gallery-2026-09-16'
PAGE = ROOT / 'doc/research/possible-bodies'
SLUG = 'entropy-wall-and-random-gallery'

assert not json.loads((OUT / 'probe.json').read_text(encoding='utf-8'))['failures']
assert 'SCRIPT ERROR' not in (OUT / 'process.log').read_text(encoding='utf-8')
assert not json.loads((GALLERY / 'museum-runtime.json').read_text(encoding='utf-8'))['failures']
assert 'SCRIPT ERROR' not in (GALLERY / 'museum-process.log').read_text(encoding='utf-8')
assets = {
    'wall-intact.png': OUT / 'wall-intact.png',
    'wall-partial.png': OUT / 'wall-partial.png',
    'wall-weathered.png': OUT / 'wall-weathered.png',
    'museum-painting.png': GALLERY / 'museum-painting.png',
    'museum-gallery.png': GALLERY / 'museum-arrival.png',
}
target = PAGE / SLUG
target.mkdir(exist_ok=True)
for name, source in assets.items():
    assert source.is_file(), source
    shutil.copy2(source, target / name)

html = '''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The wall is in the experiment · Ada Research</title>
<style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#171b1d;color:#e9e4d9;font:18px/1.7 system-ui,sans-serif}
main{max-width:1120px;margin:auto;padding:48px 24px 80px}h1{font:clamp(40px,7vw,78px)/1.08 Georgia,serif;max-width:900px;margin:18px 0 26px}
h2{font:34px/1.2 Georgia,serif;margin:56px 0 18px}p{max-width:800px}.eyebrow{font-size:13px;letter-spacing:.14em;text-transform:uppercase;color:#b4c8c5}
a{color:#f0c887;text-underline-offset:.2em}figure{margin:30px 0}img{width:100%;height:auto;display:block;border:1px solid #515b5c;border-radius:4px}figcaption{font-size:14px;line-height:1.5;color:#b8c3c1;margin-top:10px}
.choices{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}.choices button{font:inherit;background:#242e31;color:#f4ecdf;border:1px solid #617372;padding:9px 17px;border-radius:4px;cursor:pointer}.choices button[aria-pressed=true]{background:#e2c896;color:#172122}.choices button:focus-visible{outline:3px solid #a6e3da;outline-offset:4px}
.works{display:grid;grid-template-columns:1fr 1fr;gap:16px}.work{padding:20px;border-top:1px solid #60716c;background:#1c2527}.work h3{font-size:20px;margin:0 0 8px}.work p{font-size:16px;margin:0}.links{display:flex;flex-wrap:wrap;gap:14px 28px;margin-top:30px}footer{font-size:14px;color:#b8c3c1;border-top:1px solid #4c5d58;margin-top:44px;padding-top:22px}@media(max-width:650px){.works{grid-template-columns:1fr}main{padding:30px 18px}}
</style><main>
<div class="eyebrow">Randomness / restored works and a changing museum / 16 September 2026</div>
<h1>The wall is in the experiment.</h1>
<p>The colonnade began as a work inside the Entropy hall. Now a six-metre section of the museum’s west wall follows the same rule. Choose a stone, watch its place become a gap, and look beyond the room.</p>
<div class="choices" role="group" aria-label="Compare wall states"><button aria-pressed="false" data-state="intact">Intact</button><button aria-pressed="true" data-state="partial">60 stones moved</button><button aria-pressed="false" data-state="weathered">120 stones moved</button></div>
<figure><img id="wall" src="entropy-wall-and-random-gallery/wall-partial.png" alt="A partly dismantled museum wall with uneven courses and fallen stones"><figcaption id="wall-caption" aria-live="polite">Sixty of 144 stones have moved. The broken outline exposes the sky beyond the museum. Actual Godot capture.</figcaption></figure>
<p><strong>RUN / PAUSE</strong> starts or holds the process. <strong>ONE STONE</strong> moves the next selected top piece. <strong>RESTORE</strong> rebuilds the wall and resets its seed. The wall starts paused so it can be encountered intact.</p>
<p>The pieces carry their collision with them: openings really open, and restoration closes them again. The floor remains supported, and the lower courses and footing remain. Rubble settles inside a shallow apron beside the wall.</p>
<p>The program has selected what can give way. Its falls and landing places are authored. This continues the hall’s question about arrangement, counting and bodily passage; it does not measure thermodynamic entropy or model structural collapse.</p>
<div class="links"><a href="/book?map=Random_Entropy&amp;section=final">Read Entropy</a><a href="entropy-ruin.html">The earlier colonnade</a></div>

<h2>Four works return.</h2>
<p>The old <em>Examples of Randomness</em> map held a Pollock-inspired painting, Monte Carlo darts, growing pipes and a cycling particle study. Their original artifacts now occupy a 15 × 25 metre gallery immediately before Random Game. Existing halls remain in the route.</p>
<figure><img src="entropy-wall-and-random-gallery/museum-painting.png" alt="The restored generative floor painting inside the museum"><figcaption>The floor painting is the first encounter. Its canvas display has been repaired, so the generated marks reach the visible surface again.</figcaption></figure>
<div class="works">
<article class="work"><h3>Paint</h3><p>Walk around sampled marks on a floor canvas. A palette, stroke rule and boundary give chance its particular reach.</p></article>
<article class="work"><h3>Estimate</h3><p>Use THROW, AUTO and RESET to compare counted points with the displayed estimate of pi. More samples do not make every next estimate better.</p></article>
<article class="work"><h3>Grow a path</h3><p>Follow the pipe’s permitted axis turns. Its bounded run can cross itself; it does not promise to visit every part of its enclosure.</p></article>
<article class="work"><h3>Change the rule</h3><p>The particle study cycles through random kicks, trigonometric flow, spirals, swarming and selection. These are different procedures, each with its own restrictions.</p></article>
</div>
<figure><img src="entropy-wall-and-random-gallery/museum-gallery.png" alt="Separate observing bays for the recovered gallery works"><figcaption>The recovered works occupy distinct bays with a continuous floor and room to approach. Actual museum capture.</figcaption></figure>
<p><strong>What is a random choice permitted to change?</strong> The revised hall text follows that question through all four works. Each is present in the primary-artifact thread as well as the book.</p>
<div class="links"><a href="/book?map=Randomness_Examples_of_Randomness&amp;section=final">Read the recovered gallery</a><a href="/necklace/thread?map=Randomness_Examples_of_Randomness&amp;role=primary">See its primary artifacts</a><a href="/museum-progress?sequence=randomness">Follow Randomness</a></div>
<footer>Verified in the desktop Godot museum: wall openings and restoration, floor support, deterministic wall replay, painting output, artifact placement and controls. The wall passed 56 automated checks; the repaired painting and particle scenes passed 22 focused checks. Headset comfort remains to be tested.</footer>
</main><script>
const descriptions={intact:'The intact wall: 144 stones above a continuous footing. Actual Godot capture.',partial:'Sixty of 144 stones have moved. The broken outline exposes the sky beyond the museum. Actual Godot capture.',weathered:'The finite run has moved 120 stones. Twenty-four lower stones remain above the footing; every displaced stone is retained below.'};
document.querySelectorAll('[data-state]').forEach(b=>b.addEventListener('click',()=>{const s=b.dataset.state;document.getElementById('wall').src='entropy-wall-and-random-gallery/wall-'+s+'.png';document.getElementById('wall').alt=descriptions[s];document.getElementById('wall-caption').textContent=descriptions[s];document.querySelectorAll('[data-state]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));}));
</script></html>'''
(PAGE / (SLUG + '.html')).write_text(html, encoding='utf-8')
# Leave a link in the review the user was already reading.
old = PAGE / 'entropy-ruin.html'
prior = old.read_text(encoding='utf-8')
link = '<p><a href="entropy-wall-and-random-gallery.html">Continue: the museum wall and the recovered Randomness gallery →</a></p>'
if SLUG not in prior:
    old.write_text(prior.replace('<nav>', link+'<nav>'), encoding='utf-8')
if '--publish' in sys.argv:
    dest = ROOT.parent / 'ada_encyclopedia/public/research/possible-bodies'
    (dest / SLUG).mkdir(exist_ok=True)
    for name in assets:
        shutil.copy2(target / name, dest / SLUG / name)
    shutil.copy2(PAGE / (SLUG+'.html'), dest / (SLUG+'.html'))
    shutil.copy2(old, dest / old.name)
print('Review ready:', SLUG)
