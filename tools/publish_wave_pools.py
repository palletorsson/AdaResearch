from pathlib import Path
import hashlib, html, json
from publish_wavefunctions_opening import STYLE, render
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-wave-pools-walk-down'
ROOMS=[('WaveFunctions_Sine_Space','Sine Space','sine-space-colour-rain','rain-above.png'),('WaveFunctions_3D_Wave_Propagation','Wave Propagation','wave-propagation-between-points','gallery.png')]
def page(title,body):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><style>'+STYLE+'</style><header><div class="tag">Endless Museum · 8 October 2026</div><h1>'+title+'</h1><nav><a href="index.html">Rooms and walking tests</a><a href="WaveFunctions_Sine_Space.html">Sine Space readings</a><a href="WaveFunctions_3D_Wave_Propagation.html">Propagation readings</a></nav></header><main>'+body+'</main></html>'
def main():
    body='<p>The museum floor now leads down into the wave surfaces. Both rooms have open basins, broad ramps at both ends and level exit landings. The pools have no glass lids or fire.</p>'
    manifest={'scope':'Native Godot/Jolt museum walking tests with controlled input; physical headset comfort and Quest performance remain untested.','rooms':{},'sources':{}}
    for key,title,previous,before in ROOMS:
        data=json.loads((OUT/'after'/key/'report.json').read_text(encoding='utf8'));assert data['passed']
        count=len(data['checks']);assert all(x['passed'] for x in data['checks'])
        log=(OUT/'after'/key/'engine.log').read_text(encoding='utf8',errors='replace')
        assert 'SCRIPT ERROR' not in log and 'blocked t exit' not in log and 'no clear supported entrance' not in log
        manifest['rooms'][key]={'checks':count,'passed':True,'walks':{k:v for k,v in data['observations'].items() if k.startswith('walk_')}}
        detail=('The silver relief stays still. You descend one metre, walk its folds among the falling coloured balls, then climb back out. Both solid side walls remain. The ramp toes extend beneath the relief so an exposed edge cannot catch the player. The room is now 20 × 48 metres, with clear space after the corridor and beyond the exit ramp.' if 'Sine' in key else 'The moving tiles now sit in a 13 × 19-metre pool. Their outer row stays at the ramp landing; the original wave calculation continues inside, with its amplitude easing towards the quiet rim. The tiles use moving physics bodies and update on the physics clock. Narrower gaps help the crossing. The room is 24 × 40 metres, with dry side aisles and a clear exit landing.')
        body+=f'<section id="{key}"><h2>{title}</h2><p>{detail}</p><figure><img src="after/{key}/pool-eye.png" alt="Walk down into {title}"><figcaption>Native museum capture from the approach.</figcaption></figure><div class="pictures"><figure><img src="before/{key}/{before}"><figcaption>Before.</figcaption></figure><figure><img src="after/{key}/pool-above.png"><figcaption>After: an open pool with a descent and return.</figcaption></figure></div><p><strong>{count}/{count} checks passed.</strong> The actual museum walker crossed and returned without jumping, reaching level floor at both ends. <a href="after/{key}/report.json">Walking samples and assertions</a> · <a href="{key}.html">Tutorial left / reflection right</a></p></section>'
        m=ROOT/'commons/maps'/key
        tutorial=(m/'tutorial.md').read_text(encoding='utf8');final=(m/'final.md').read_text(encoding='utf8')
        (OUT/(key+'.html')).write_text(page(title+' — two readings','<p>The tutorial program is unchanged. The reflection now follows the descent and return in the actual museum.</p><div class="parallel"><article><div class="tag">tutorial.md</div>'+render(tutorial)+'</article><article><div class="tag">final.md</div>'+render(final)+'</article></div>'),encoding='utf8')
        for name in ['map_data.json','tutorial.md','final.md']:
            src=m/name;manifest['sources'][src.relative_to(ROOT).as_posix()]=hashlib.sha256(src.read_bytes()).hexdigest()
        prior=OUT.parent/('2026-10-08-'+previous)/'index.html'
        text=prior.read_text(encoding='utf8');banner='<p class="status" id="walk-down-pool">New room revision: walk down into the wave pool and climb out at the other end. <a href="../2026-10-08-wave-pools-walk-down/index.html#'+key+'">Current images and walking tests</a>. The captures below record the earlier layout.</p>'
        if 'id="walk-down-pool"' not in text:prior.write_text(text.replace('<main>','<main>'+banner,1),encoding='utf8')
    body+='<h2>What remains to try in VR</h2><p>These are desktop-engine checks using the real museum collision world and player capsule. The controlled Sine Space walk excludes impacts from loose balls; a separate drop verifies rain contact with the lowered terrain. Headset comfort, controller locomotion and Quest performance still need a headset trial. All earlier authored exhibits remain. The tutorial programs and their learning focus are unchanged.</p><p><a href="verification.json">Source hashes and results</a></p>'
    (OUT/'index.html').write_text(page('Walk down into the waves',body),encoding='utf8')
    for p in ['commons/scenes/endless_museum.gd','commons/scenes/em/basin_access.gd','algorithms/wavefunctions/wave_propagation_3d/WavePropagation3D.gd','tools/probes/wave_pool_access.gd']:
        manifest['sources'][p]=hashlib.sha256((ROOT/p).read_bytes()).hexdigest()
    (OUT/'verification.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    print('Published both rooms, current paired readings and 41 native checks.')
if __name__=='__main__':main()
