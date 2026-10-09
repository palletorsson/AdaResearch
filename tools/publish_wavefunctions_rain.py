from pathlib import Path
import hashlib, json
from publish_wavefunctions_opening import STYLE, render
from publish_wavefunctions_surface import page as reading_page

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-sine-space-colour-rain'
OLD=ROOT/'doc/book/iterations/2026-10-08-sine-space-a-surface'
PREVIOUS=ROOT/'doc/book/iterations/2026-10-08-sine-space-walk-the-waves'
MAP=ROOT/'commons/maps/WaveFunctions_Sine_Space'

def main():
    report=json.loads((OUT/'after/report.json').read_text(encoding='utf8'))
    assert report['passed']
    count=len(report['checks'])
    walk=report['observations']['walk']
    old='The terrain stays still while your height changes. Solid walls close both sides.'
    new='The room opens wider. Coloured balls fall from above, bounce against a crest and gather in the hollows. Walk among them: the same relief redirects their movement and changes your footing. The terrain stays still while your height changes. Solid walls close both sides.'
    for path in [MAP/'final.md',ROOT/'doc/book/studies/wavefunctions-lineage/sine-space-final.md']:
        text=path.read_text(encoding='utf8')
        if 'The room opens wider.' not in text:
            assert old in text,path
            path.write_text(text.replace(old,new,1),encoding='utf8')
    final=(MAP/'final.md').read_text(encoding='utf8')
    tutorial=(MAP/'tutorial.md').read_text(encoding='utf8')
    (OUT/'final.md').write_text(final,encoding='utf8')
    (OLD/'final.md').write_text(final,encoding='utf8')
    (OLD/'final.html').write_text(reading_page('What a wave can hold','<article>'+render(final)+'</article>'),encoding='utf8')
    (OLD/'parallel.html').write_text(reading_page('A surface and what it permits','<div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
    body=f'''<p>The room is now 20 metres wide. Its silver wave floor expands from 8 to 14 metres across, with the same 18-metre crossing. Solid side walls still lead the visitor over the folds.</p>
    <figure><img src="after/rain-eye.png" alt="Coloured physics balls falling and collecting between silver crests in the wider museum room"><figcaption>Inside the actual Endless Museum. Balls fall into the surface you walk across.</figcaption></figure>
    <div class="pictures"><figure><img src="before/crossing.png"><figcaption>Before: eight metres across; no coloured rain.</figcaption></figure><figure><img src="after/crossing.png"><figcaption>After: fourteen metres across, with falling and rolling spheres.</figcaption></figure></div>
    <figure><img src="after/rain-above.png"><figcaption>From above: the hollows collect the balls. Both side walls remain closed; the far landing leads onward.</figcaption></figure>
    <h2>What changed</h2><p>All five previous exhibits remain. Colour’s existing ball artifact supplies 48 spheres, each 44 cm in diameter. One returns overhead every 0.4 seconds; the fixed pool keeps the rain going without accumulating more physics bodies. Their collisions, bounce and rolling are simulated by Jolt.</p>
    <h2>Checked in Godot</h2><p>{count}/{count} native checks passed. The actual museum walker reached the far landing with {walk['highest']-walk['lowest']:.2f} metres of vertical range, and both side bypasses remained blocked. A controlled ball drop hit the sine collider, rebounded and moved sideways. Recycling preserves the bodies and places them over this hall.</p>
    <p><a href="after/report.json">Assertions and measurements</a> · <a href="verification.json">Source hashes</a></p><p class="note">Real engine captures and collision tests. Headset comfort and Quest performance still need an in-headset check.</p>
    <h2>The reading</h2><blockquote>{new}</blockquote><p>The tutorial program remains unchanged. The reflection now includes the balls meeting the same surface as the visitor.</p><p><a href="../2026-10-08-sine-space-a-surface/parallel.html">Tutorial and reflection</a> · <a href="final.md">Current reflection</a></p>'''
    (OUT/'index.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Colour over the waves</title><style>{STYLE}</style><header><div class="tag">Endless Museum · Sine Space · 8 October 2026</div><h1>Colour over the waves</h1><p>A wider floor, falling bodies, hollows that gather them.</p></header><main>{body}</main></html>',encoding='utf8')
    banner='<p class="status" id="colour-rain">Current room: a wider 14-metre wave floor with falling coloured balls. <a href="../2026-10-08-sine-space-colour-rain/index.html">See the latest museum images and tests.</a> The layout images below record an earlier version.</p>'
    for folder in [OLD,PREVIOUS]:
        path=folder/'index.html';text=path.read_text(encoding='utf8')
        if 'id="colour-rain"' not in text:text=text.replace('<main>','<main>'+banner,1)
        path.write_text(text,encoding='utf8')
    paths=['commons/maps/WaveFunctions_Sine_Space/map_data.json','commons/maps/WaveFunctions_Sine_Space/final.md','commons/maps/WaveFunctions_Sine_Space/tutorial.md','algorithms/color/colorballs/colorballs.gd','tools/probes/wavefunctions_surface_museum.gd','tools/probes/wavefunctions_surface_crossing.gd','tools/probes/wavefunctions_colour_rain.gd']
    (OUT/'verification.json').write_text(json.dumps({'passed':True,'checks':count,'height_range_m':walk['highest']-walk['lowest'],'sources':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}},indent=2),encoding='utf8')
    planpath=ROOT/'doc/book/course/execution-plan/plan.json'
    text=planpath.read_text(encoding='utf8')
    start=text.index('"id": "WaveFunctions_Sine_Space"')
    index=text.index('"notes": ',start)+len('"notes": ')
    notes, consumed=json.JSONDecoder().raw_decode(text[index:])
    if '2026-10-08-sine-space-colour-rain' not in notes:
        notes+=' Later spatial update: room widened to 20x40m and sine crossing to 14x18m; existing colorballs supplies bounded rain. All prior exhibits retained; 111/111 native checks. See doc/book/iterations/2026-10-08-sine-space-colour-rain/index.html.'
        text=text[:index]+json.dumps(notes,ensure_ascii=False)+text[index+consumed:]
        planpath.write_text(text,encoding='utf8')
    print(f'Published colour rain: {count}/{count} checks.')

if __name__=='__main__':main()
