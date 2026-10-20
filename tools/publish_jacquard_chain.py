"""Publish the native hanging-card-chain checks, captures and animated cycle."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import subprocess
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-10-jacquard-hanging-chain'

def main():
    receipts = [json.loads((OUT/name).read_text()) for name in ['tests.json','museum-tests.json']]
    assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in receipts)
    assert len(receipts[0]['checks']) >= 90
    source=OUT/'source'; source.mkdir(exist_ok=True)
    for p in (ROOT/'commons/artifacts/jacquard_weaver').iterdir():
        if p.suffix in {'.gd','.gdshader','.tscn','.md'}: shutil.copyfile(p,source/p.name)
    for name in ['jacquard_weaver_test.gd','jacquard_museum_test.gd']:
        shutil.copyfile(ROOT/'tools/probes'/name,source/name)
    shutil.copyfile(ROOT/'commons/artifacts/registry/jacquard_weaver.json',source/'registry.json')
    hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in source.iterdir() if p.is_file()}
    (OUT/'source-hashes.json').write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8')
    frames=list(OUT.glob('motion-*.png'))
    assert len(frames)==60
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-v','error','-framerate','50/7','-i',str(OUT/'motion-%03d.png'),'-vf','scale=1200:800','-r','30','-c:v','libx264','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(OUT/'card-chain.mp4')],check=True,timeout=90,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    def image(name,caption):
        assert (OUT/name).exists()
        return f'<figure><a href="{name}"><img src="{name}" width="1800" height="1200" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'
    style='''*{box-sizing:border-box}body{margin:0;background:#eee9df;color:#302920;font:19px/1.6 Georgia,serif}main{max-width:1300px;margin:auto;padding:30px 25px 80px}nav,figcaption,.meta{font:14px/1.5 system-ui}nav{display:flex;gap:24px;flex-wrap:wrap;border-bottom:1px solid #bcb0a1;padding-bottom:20px}a{color:#785326;text-underline-offset:4px}h1{font:clamp(42px,7vw,84px)/1.05 Georgia,serif;max-width:900px;margin:26px 0}h2{font-size:31px;margin:40px 0 12px}.lead{font-size:26px;max-width:820px}.copy{max-width:810px}figure{margin:26px 0}img,video{display:block;width:100%;height:auto;background:#192127}figcaption{margin:10px 0;color:#665b4e}.grid{display:grid;grid-template-columns:1fr 1fr;gap:25px}.grid figure{margin:0}.receipt{padding:22px;background:#dfe5d6;margin:30px 0}li{margin:12px 0}code{font-size:14px}.meta{margin-top:32px}@media(max-width:760px){.grid{grid-template-columns:1fr}main{padding:22px 16px 60px}}'''
    body='''<nav><a href="#cycle">Watch the cycle</a><a href="#experiment">Change one hole</a><a href="#museum">In the museum</a><a href="#use">Use the chain</a><a href="../2026-10-10-jacquard-cards-and-layers/index.html">Earlier loom / tartan</a></nav>
<p class="meta">Endless Museum · Tiling / Symmetry Seventeen · 10 October 2026</p>
<h1>One card.<br>One woven row.</h1><p class="lead">The cards now hang in a laced loop. A card moves into the reader, the chain stops, the threads lift and the shuttle draws a new pass into the cloth.</p>'''
    body+=image('hanging-chain.png','Actual Godot capture. The moving chain replaces the fixed card sockets; spare cards wait on the front tray. Colour controls have moved beside the bed to reveal the cloth.')
    body+='''<h2 id="cycle">Watch three cycles</h2><video controls loop muted playsinline preload="metadata" poster="04-cloth.png" src="card-chain.mp4"></video><p class="meta">Native Godot frames advanced at 0.14 seconds per frame, replayed at the same timing. This shows the real artifact and its real card program.</p><div class="grid">'''
    for n,c in [('01-advance.png','1 · Advance. The next physical card moves toward the fixed brass reading window.'),('02-read-lift.png','2 · Read and lift. The card seats; the enlarged read mask identifies the choice passed to the hooks.'),('03-shuttle.png','3 · Pass. The chain stays still while the shuttle carries the visible weft across the shed.'),('04-cloth.png','4 · Keep. The pass enters the recorded cloth. Only then can the next cycle begin.')]:body+=image(n,c)
    body+='''</div><div class="copy"><h2 id="use">Use the chain</h2><ol><li>Press <b>TARTAN + CLEAR</b> for the coloured sample, or keep the cream-and-pink warp and weft.</li><li><b>ONE PICK</b> completes one cycle. <b>RUN / STOP</b> repeats the chain; stopping finishes the current pass.</li><li>Grab a card to remove it. Automatic weaving stops after the current pass. Release the card into an empty numbered frame to put it back. The return side of the loop also carries real cards.</li><li>The twelve punch buttons edit the selected card. The current pass retains the choice it already took; the next use of that card reads its edited holes. Finished cloth keeps earlier choices.</li><li>The eight-card loop repeats. Empty frames are passed over; with only one card installed, the belt makes a full revolution before using it again.</li></ol><p><b>WEAVE 96 PICKS</b> remains the fast-sample control on the companion table. It records real passes without showing every animation and leaves the chain at its last used card. ONE PICK or RUN then continues in the correct order. The layer slider still opens the same recorded cloth.</p></div>'''
    body+='''<div class="copy"><p><b>NORMAL / SLOW</b>, beside RUN / STOP, switches between a 2.8-second and an 8-second pass. You can change speed while watching: the card, shuttle and current choice keep their place. A finished pass now reads <b>PICK … WOVEN</b>.</p><h2 id="experiment">Change one hole. Follow its return.</h2><p>Weave eight plain picks. On card 01, patch hook 1. Weave sixteen more. The change appears on picks <b>9 and 17</b>, when that card returns. Each has eight changed crossings because the twelve-hook unit repeats eight times across the cloth. The first eight rows stay intact.</p><p>This visitor experiment runs through the real punch button and animated passes. Assertions check the entire history and the generated warp paths. <a href="one-hole-record.json">Read the before/after record.</a></p></div><div class="grid">'''
    body+=image('one-hole-cloth.png','Actual 24-pick sample after patching card 01, hook 1. The interruption repeats across the width on picks 9 and 17.')
    body+=image('one-hole-layers.png','The same sample opened into layers. The inspection changes its spacing; the recorded crossings remain the same.')
    body+='</div><h2 id="museum">Installed in Symmetry Seventeen</h2>'
    body+=image('tartan-museum.png','The updated loom and layer table inside the current Endless Museum hall. The existing hand loom remains nearby.')
    body+=image('player-view.png','Standing view of the working loom. The colour controls sit to the right; the central shed and growing cloth are open to view.')
    body+='<details><summary>Before: fixed sockets</summary>'+image('before/loom.png','Before this change: eight cards stayed on the front panel; only the enlarged reading copy changed.')+'</details>'
    body+=f'''<div class="copy receipt"><b>{len(receipts[0]['checks'])} runtime assertions and {len(receipts[1]['checks'])} museum checks passed.</b><p>The checks cover card arrival before lift, stationary cards during the pass, one row per cycle, wrapping, sparse chains, pickup interruption, coloured history and the batch-to-animation handoff. XR pickup and release are exercised with simulated controllers; headset reach still needs a physical playthrough.</p></div><div class="copy"><p>The card belt follows a prescribed path. Laces and a turning drum show its connection, but card gravity and cord tension are not physics simulations. Yarn crossings retain their existing geometric model. The photographs inspired the hanging arrangement; this is a small teaching loom, not a reconstruction of every historical linkage.</p></div><p class="meta"><a href="tests.json">Runtime checks</a> · <a href="museum-tests.json">Museum checks</a> · <a href="source/README.md">Artifact guide</a> · <a href="source/card_chain.gd">Moving chain</a> · <a href="source/jacquard_weaver.gd">Loom cycle</a> · <a href="source-hashes.json">Source snapshot hashes</a></p>'''
    (OUT/'index.html').write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>One card, one woven row · Endless Museum</title><style>{style}</style></head><body><main>{body}</main></body></html>',encoding='utf-8')
    print(f'Published {OUT}/index.html · {len(receipts[0]["checks"])} + {len(receipts[1]["checks"])} checks')

if __name__=='__main__': main()
