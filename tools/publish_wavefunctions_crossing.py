from pathlib import Path
import json, hashlib
from publish_wavefunctions_opening import STYLE, render
from publish_wavefunctions_surface import page as old_page

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-sine-space-walk-the-waves'
OLD=ROOT/'doc/book/iterations/2026-10-08-sine-space-a-surface'
MAP=ROOT/'commons/maps/WaveFunctions_Sine_Space'

def main():
    report=json.loads((OUT/'after/report.json').read_text(encoding='utf8'))
    assert report['passed']
    count=len(report['checks'])
    walk=report['observations']['walk']
    final=(MAP/'final.md').read_text(encoding='utf8')
    (OUT/'final.md').write_text(final,encoding='utf8')
    (OLD/'final.md').write_text(final,encoding='utf8')
    (OLD/'final.html').write_text(old_page('What a wave can hold','<article>'+render(final)+'</article>'),encoding='utf8')
    tutorial=(MAP/'tutorial.md').read_text(encoding='utf8')
    (OLD/'parallel.html').write_text(old_page('A surface and what it permits','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    body=f'''<p>The sine floor is now the walking route to the next room. Solid walls run along both sides and fill the former flat bypasses. The floor's height rule and collision mesh are unchanged.</p><div class="pictures"><figure><img src="after/crossing.png"><figcaption>Inside the real museum: follow the folds to the level landing beyond.</figcaption></figure><figure><img src="after/walls-above.png"><figcaption>Both side routes are closed. The eight-by-eighteen-metre sine surface connects the two landings.</figcaption></figure></div><h2>Before and after</h2><div class="pictures"><figure><img src="before/floor.png"><figcaption>Before: a flat path let the player pass the surface without walking it.</figcaption></figure><figure><img src="after/floor.png"><figcaption>After: the onward route crosses the wave floor between solid walls.</figcaption></figure></div><p>The dark sphere has moved to the far landing. All five authored exhibits remain. The unused automatic lift beside the entrance to the floor was removed because it offered a route above the crossing.</p><h2>Native walking test</h2><p>{count}/{count} checks passed. The actual museum CharacterBody crossed the eighteen-metre surface, reached the far landing and was blocked when attempting each former side bypass. Its measured height ranged from {walk['lowest']:.2f} to {walk['highest']:.2f} metres: {walk['highest']-walk['lowest']:.2f} metres of vertical travel range.</p><p><a href="after/report.json">Assertions and recorded walk</a> · <a href="after/source_manifest.json">Source manifest</a></p><p class="note">Controlled forward movement through the actual collision geometry, with museum input paused. This verifies physical support and obstruction; headset comfort remains to be tested. The tutorial program is unchanged.</p><h2>The revised passage</h2><blockquote>Beyond the corridor, the silver floor waits in its basin. This surface has collision. Walk onto it: a fold that the eye follows now changes where the foot can stand. The terrain stays still while your height changes. Solid walls close both sides. To reach the next room you cross these folds; level ground waits at the far end. The wave has become a condition of continuing.</blockquote><p><a href="final.md">Full current reflection</a> · <a href="../2026-10-08-sine-space-a-surface/parallel.html">Tutorial and reflection together</a></p>'''
    html=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Walk the waves</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Sine Space · spatial correction</div><h1>Walk the waves</h1><p>Two solid sides. The way onward is across the surface.</p></header><main>{body}</main></html>'''
    (OUT/'index.html').write_text(html,encoding='utf8')
    index=OLD/'index.html';text=index.read_text(encoding='utf8')
    banner='<p class="status" id="required-crossing">Updated at the author’s request: both flat side paths are now closed by solid walls. <a href="../2026-10-08-sine-space-walk-the-waves/index.html">See the new required crossing, museum images and walking test.</a> The room images and counts below document the earlier layout.</p>'
    if 'id="required-crossing"' not in text:text=text.replace('<main>','<main>'+banner,1)
    index.write_text(text,encoding='utf8')
    paths=['commons/maps/WaveFunctions_Sine_Space/map_data.json','commons/maps/WaveFunctions_Sine_Space/final.md','tools/probes/wavefunctions_surface_museum.gd','tools/probes/wavefunctions_surface_crossing.gd']
    (OUT/'verification.json').write_text(json.dumps({'passed':True,'checks':count,'height_range_m':walk['highest']-walk['lowest'],'sources':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}},indent=2),encoding='utf8')
    print('Published required sine-floor crossing, evidence and revised reflection.')

if __name__=='__main__':main()
