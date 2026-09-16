from pathlib import Path
import json,shutil,sys
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
page=ROOT/'doc/research/possible-bodies'
images=page/'entropy-ruin'; images.mkdir(exist_ok=True)
unit=json.loads((OUT/'unit.json').read_text(encoding='utf-8'))
museum=json.loads((OUT/'Random_Entropy-runtime.json').read_text(encoding='utf-8'))
assert not unit['failures'] and not museum['failures']
assert 'SCRIPT ERROR' not in (OUT/'Random_Entropy-process.log').read_text(encoding='utf-8')
for state in ['intact','weathered']:
    shutil.copy2(OUT/f'Random_Entropy-ruin-{state}.png',images/f'{state}.png')
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What still holds? · Ada Research</title>
<style>body{margin:0;background:#171a19;color:#e7dfcc;font:18px/1.65 system-ui}main{max-width:1100px;margin:auto;padding:42px 24px}h1{font:clamp(36px,6vw,68px)/1.05 Georgia,serif;max-width:800px}p{max-width:760px}figure{margin:36px 0}img{display:block;width:100%;border:1px solid #545448}figcaption{font-size:15px;color:#bebbac;margin-top:8px}a{color:#e7ba78}.kicker{color:#afbdaf;font-size:14px;letter-spacing:.1em}nav{display:flex;flex-wrap:wrap;gap:24px}strong{color:#fff2d4}</style>
<main><div class="kicker">RANDOM_ENTROPY / A SPATIAL EXPERIMENT</div><h1>What still holds?</h1><p>Four pale columns, a lintel and a brick wall. Wait by a joint. A stone leaves its place; the view through the structure changes. The stone is still here.</p>
<figure><img src="entropy-ruin/intact.png" alt="Four fluted stone columns and a brick wall in the Entropy museum hall"><figcaption>Intact: 116 pieces carry a familiar architectural outline.</figcaption></figure>
<figure><img src="entropy-ruin/weathered.png" alt="The same columns partly dismantled, with brick and stone rubble retained below"><figcaption>After 46 selections: gaps, surviving columns and the same pieces gathered below. Actual Godot museum capture.</figcaption></figure>
<p><strong>RUN / PAUSE</strong> holds selection and descent. <strong>ONE STONE</strong> places one selected piece among the rubble. <strong>RESTORE</strong> rebuilds the structure and resets its seed, ready to replay.</p>
<p>The rule selects exposed top pieces and keeps the bottom two courses. Its falls and landing places are staged. This is a comparison with the hall’s account of arrangement and counting; it does not measure thermodynamic entropy or simulate centuries of weather.</p>
<p>The hall extends to 17 × 31 metres. The ruin stands after the glass field, with open space around it and the earlier exhibits retained. Automated behavior and museum checks pass; headset comfort remains to be tested.</p>
<nav><a href="http://localhost:3003/book?map=Random_Entropy&section=final">Read the hall</a><a href="http://localhost:3003/necklace/thread?map=Random_Entropy&role=primary">Primary artifacts</a><a href="http://localhost:3003/research/possible-bodies/randomness-spatial.html#Random_Entropy">Earlier staging</a></nav></main></html>'''
(page/'entropy-ruin.html').write_text(html,encoding='utf-8')
if '--publish' in sys.argv:
    dest=ROOT.parent/'ada_encyclopedia/public/research/possible-bodies'
    (dest/'entropy-ruin').mkdir(exist_ok=True)
    shutil.copy2(page/'entropy-ruin.html',dest/'entropy-ruin.html')
    for state in ['intact','weathered']: shutil.copy2(images/f'{state}.png',dest/'entropy-ruin'/f'{state}.png')
print('Review ready;',unit['checks'],'behavior checks;',len(museum['checks']),'museum checks')
