"""A comparison of existing costumes on the production XR costume components."""
from pathlib import Path
import hashlib, html, json, shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-10-player-costume-gallery'
LOOKS = [
    ('suit', 'Woven suit', 'Jacket, long sleeves and trousers.'),
    ('aline', 'A-line dress', 'Short sleeves and a short, flared skirt.'),
    ('gown', 'Long gown', 'A long skirt with a wider hem and longer sleeves.'),
    ('pleated', 'Pleated dress', 'Sixteen geometric pleats open the skirt silhouette.'),
    ('latex_cathedral', 'Latex Cathedral', 'Pink latex, a dark spiked collar and a gold crown.'),
    ('chrome_orchid', 'Chrome Orchid', 'Reflective petals spread from the shoulders and crown.'),
    ('holo_fan', 'Holographic Fan', 'An iridescent fan behind the shoulders and a tall crest.'),
    ('pearl_rococo', 'Pearl Rococo', 'Rounded sleeves, pearl trim and a small pearl crown.'),
]


def main():
    results = json.loads((OUT / 'checks.json').read_text(encoding='utf-8'))
    assert results['passed']
    for key, _, _ in LOOKS:
        for view in ('front', 'side', 'down'):
            assert (OUT / f'{key}-{view}.png').exists()
    cards = ''.join(f'''<button class="card" data-look="{key}" aria-label="Compare {title}">
<img src="{key}-front.png" alt="{title} on the VR player rig inside the museum"><span>{title}</span></button>''' for key, title, _ in LOOKS)
    choices = ''.join(f'<option value="{key}">{title}</option>' for key, title, _ in LOOKS)
    data = {key: {'title': title, 'note': note} for key, title, note in LOOKS}
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Your player, eight costumes · Endless Museum</title><style>
:root{color-scheme:light;--paper:#f3eee5;--ink:#28252a;--line:#cfc5b9}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}main{max-width:1460px;padding:44px 28px;margin:auto}header{max-width:860px}.eyebrow{font-size:12px;letter-spacing:.16em;text-transform:uppercase}h1{font:clamp(40px,5.6vw,76px)/1.07 Georgia,serif;margin:20px 0}h2{font:32px/1.2 Georgia,serif}p{max-width:840px}a{color:#754834}.lineup{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:20px;margin:35px 0 50px}.card{padding:0;border:0;background:transparent;font:inherit;text-align:left;cursor:pointer;color:inherit}.card img{width:100%;aspect-ratio:4/5;object-fit:cover;display:block;background:#ccc}.card span{display:block;padding:10px 0;font-size:17px}.card:hover img{outline:3px solid #bd8a73}.card:focus-visible{outline:3px solid #795447;outline-offset:5px}.toolbar{display:flex;justify-content:space-between;align-items:center;gap:20px;border-top:1px solid var(--line);padding-top:30px}.toolbar h2{margin:0}select{font:inherit;padding:10px 16px;border:1px solid #9a8e80;border-radius:4px;background:var(--paper);color:inherit}.detail{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0}figure img{width:100%;display:block}figcaption{font-size:14px;margin:7px 0 22px;opacity:.82}.down{max-width:900px;margin:22px auto}.observations{border-top:1px solid var(--line);padding-top:25px;margin-top:45px;max-width:900px}.small{font-size:14px}details{margin:25px 0}summary{cursor:pointer}footer{border-top:1px solid var(--line);padding-top:20px;margin-top:40px;font-size:13px}@media(max-width:800px){.lineup{grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}.detail{grid-template-columns:1fr}.toolbar{align-items:flex-start;flex-direction:column}main{padding:25px 18px}}
</style><main><header><p class="eyebrow">Endless Museum / Your VR body / 10 October 2026</p><h1>Your player,<br>eight costumes.</h1><p>The same headset-and-controller pose, photographed inside Ribbon Patterns 03. The four woven garments use the same houndstooth cloth; the four sculptural looks retain their own finishes.</p><p class="small">Native Godot renders with simulated tracking poses. These are the current wearable components, including the production IK arms and hand models. No physical headset was used for the captures.</p></header>
<div class="lineup">__CARDS__</div>
<section id="compare"><div class="toolbar"><h2 id="title">Woven suit</h2><label>Compare <select id="look">__CHOICES__</select></label></div><p id="note"></p><div class="detail"><figure><a id="front-link" href="suit-front.png"><img id="front" src="suit-front.png" alt="Woven suit, front view"></a><figcaption>Outside view · same camera position for every costume.</figcaption></figure><figure><a id="side-link" href="suit-side.png"><img id="side" src="suit-side.png" alt="Woven suit, side view"></a><figcaption>Three-quarter view · the same body and hand pose.</figcaption></figure></div><figure class="down"><a id="down-link" href="suit-down.png"><img id="down" src="suit-down.png" alt="Looking down at the woven suit"></a><figcaption>Looking down through the XRCamera. A single flat render, not a stereoscopic headset capture.</figcaption></figure></section>
<section class="observations"><h2>What the views show</h2><p>The woven dresses keep attention on the textile and the changing hem. Chrome Orchid and Holographic Fan make the shoulders much wider. Latex Cathedral adds spikes; Pearl Rococo uses rounder volumes.</p><p>The tailored garments currently have no head or mask geometry. Their open neckline exposes the inside of the garment when looking down. Some sculptural looks also leave a gap between the hem and boots. These are visible limits of the current avatar construction.</p><p>The comparison uses a fresh wardrobe with no earned tiers or trophies. The sculptural skirts can grow with progress, so a player farther through the museum may see a different length. Your worn shape and fabric remain separate from progression.</p><details><summary>Where to choose them in VR</summary><p>At the cutting table: choose SUIT, A-LINE, GOWN or PLEATED; then CUT → ASSEMBLE → WEAR. At the mirror: PREVIOUS and NEXT cycle the four sculptural looks. Both dress the headset wearer.</p></details></section>
<footer>__COUNT__ capture checks passed, including connection to the XR camera and controllers, IK arms and all eight outfit applications. <a href="checks.json">Results</a> · <a href="source-hashes.json">Source snapshot</a> · <a href="../2026-10-10-dresses-on-the-vr-player/index.html">VR turn and mirror checks</a></footer></main>
<script>const looks=__DATA__;function show(key,scroll=false){if(!looks[key])key='suit';const look=looks[key];document.getElementById('look').value=key;document.getElementById('title').textContent=look.title;document.getElementById('note').textContent=look.note;for(const view of ['front','side','down']){const path=key+'-'+view+'.png';const img=document.getElementById(view);img.src=path;img.alt=look.title+' / '+view;document.getElementById(view+'-link').href=path;}history.replaceState(null,'','#'+key);if(scroll)document.getElementById('compare').scrollIntoView({behavior:'smooth'});}document.querySelectorAll('[data-look]').forEach(b=>b.onclick=()=>show(b.dataset.look,true));document.getElementById('look').onchange=e=>show(e.target.value);show(location.hash.slice(1));</script></html>'''
    page = page.replace('__CARDS__', cards).replace('__CHOICES__', choices).replace('__DATA__', json.dumps(data)).replace('__COUNT__', str(len(results['checks'])))
    (OUT / 'index.html').write_text(page, encoding='utf-8')
    hashes = {}
    for f in ['commons/player/queer_costume.gd', 'commons/player/tailored_suit.gd', 'commons/player/super_drag_outfit.gd', 'commons/player/costume_wardrobe.gd', 'commons/player/PlayerCustomization.gd', 'tools/probes/player_costume_gallery.gd', 'tools/run_player_costume_gallery.py']:
        target = OUT / 'source' / f
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / f, target)
        hashes[f] = hashlib.sha256(target.read_bytes()).hexdigest()
    (OUT / 'source-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    print('Published 8 costumes, 24 native renders.')


if __name__ == '__main__':
    main()
