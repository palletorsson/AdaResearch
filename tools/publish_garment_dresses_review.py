"""Publish real museum photographs and validation for the dress extension."""
from pathlib import Path
import hashlib, html, json, re, shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-10-dresses-from-the-loom'


def main():
    tests = [json.loads((OUT / p).read_text(encoding='utf-8')) for p in ('tests.json', 'museum-tests.json')]
    assert all(d['passed'] for d in tests)
    count = sum(len(d['checks']) for d in tests)
    files = [
        'commons/artifacts/garment_cutting_table/suit_panels.gd',
        'commons/artifacts/garment_cutting_table/cloth_record.gd',
        'commons/artifacts/garment_cutting_table/garment_cutting_table.gd',
        'commons/artifacts/garment_cutting_table/README.md',
        'commons/player/tailored_suit.gd', 'commons/player/costume_wardrobe.gd',
        'commons/player/queer_costume.gd',
        'commons/artifacts/registry/garment_cutting_table.json',
        'commons/maps/Ribbon_Patterns_03/tutorial.md',
        'commons/maps/Ribbon_Patterns_03/final.md',
        'tools/probes/garment_dresses_test.gd', 'tools/probes/garment_dresses_museum.gd',
        'tools/run_garment_dresses_review.py',
    ]
    hashes = {}
    for f in files:
        dst = OUT / 'source' / f
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / f, dst)
        hashes[f] = hashlib.sha256(dst.read_bytes()).hexdigest()
    (OUT / 'source-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Ribbon_Patterns_03/tutorial.md').read_text(encoding='utf-8')
    prior = (ROOT / 'doc/book/iterations/2026-10-10-cutting-a-suit/before/commons/maps/Ribbon_Patterns_03/tutorial.md').read_text(encoding='utf-8')
    assert re.findall(r'```.*?```', tutorial, re.S) == re.findall(r'```.*?```', prior, re.S)
    guide = tutorial.split('## Optional: cut the cloth you kept')[1].split('## What travels')[0]
    def para(s):
        return ''.join('<p>' + re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html.escape(p)) + '</p>' for p in s.strip().split('\n\n'))
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Dresses from the loom · Endless Museum</title>
<style>
:root{color-scheme:light;--ink:#292a2b;--paper:#f4efe4;--line:#cfc6b7;--accent:#754631}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}main{max-width:1320px;margin:auto;padding:50px 28px}header{max-width:930px;margin-bottom:38px}.eyebrow{font-size:12px;letter-spacing:.17em;text-transform:uppercase}h1{font:clamp(38px,5vw,74px)/1.06 Georgia,serif;max-width:850px;margin:20px 0}h2{font:32px/1.2 Georgia,serif;margin:0 0 12px}h3{font-size:20px}a{color:var(--accent)}.lead{font-size:21px;max-width:760px}button{font:inherit;cursor:pointer;background:transparent;border:1px solid var(--line);border-radius:24px;padding:9px 20px;color:var(--ink)}button[aria-pressed=true]{background:var(--ink);color:var(--paper);border-color:var(--ink)}button:focus-visible{outline:3px solid #ab6c48;outline-offset:3px}.choices{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}.views{display:grid;grid-template-columns:1fr 1fr;gap:18px}img{width:100%;display:block;border-radius:3px}figure{margin:0}figcaption{font-size:14px;margin-top:9px;opacity:.8}.selection{padding:28px 0;border-top:1px solid var(--line)}.steps{display:grid;grid-template-columns:repeat(4,1fr);gap:22px;margin:40px 0}.step{border-top:2px solid var(--ink);padding-top:12px}.step p{margin:7px 0}.read{max-width:850px;margin:50px 0}.evidence{background:#e5e1d5;padding:28px;margin:40px 0}.nav{display:flex;flex-wrap:wrap;gap:20px;font-size:14px}details{border-top:1px solid var(--line);padding:18px 0}summary{cursor:pointer;font-weight:600}footer{font-size:13px;opacity:.8;margin-top:40px}@media(max-width:760px){main{padding:28px 18px}.views,.steps{grid-template-columns:1fr}.steps{gap:12px}}
</style><main><header><div class="eyebrow">Endless Museum / Tiling / Ribbon Patterns 03 / 10 October 2026</div>
<h1>One cloth.<br>Choose what it becomes.</h1><p class="lead">Three dresses join the suit at the cutting table. Change the silhouette, watch the robot assemble it, then wear it on your museum avatar.</p>
<nav class="nav"><a href="#wardrobe">Compare the shapes</a><a href="#controls">Use the table</a><a href="#evidence">Native test results</a><a href="../2026-10-10-cutting-a-suit/index.html">Earlier suit station</a></nav></header>
<section id="wardrobe" class="selection"><h2 id="shape-title">A-line dress</h2><p id="shape-note">A short flared skirt and short sleeves.</p>
<div class="choices" aria-label="Compare museum photographs"><button data-shape="aline" aria-pressed="true">A-line</button><button data-shape="gown" aria-pressed="false">Long gown</button><button data-shape="pleated" aria-pressed="false">Pleated</button><button data-shape="suit" aria-pressed="false">Suit</button></div>
<div class="views"><figure><a id="fit-link" href="fitted-aline.png"><img id="fit" src="fitted-aline.png" alt="A-line dress on the fitting figure inside the museum"></a><figcaption>On the fitting figure. Same houndstooth cloth in every comparison.</figcaption></figure>
<figure><a id="wear-link" href="worn-aline.png"><img id="wear" src="worn-aline.png" alt="The actual museum avatar wearing the A-line dress"></a><figcaption>On the actual museum walker, seen by an external camera. The first-person avatar does not supply a visible head.</figcaption></figure></div></section>
<section id="controls"><div class="steps"><div class="step"><strong>01 / Choose cloth</strong><p>LOAD LOOM reads your saved weave. CLOTH cycles tartan, houndstooth and optical checks.</p></div><div class="step"><strong>02 / Choose shape</strong><p>SUIT, A-LINE, GOWN or PLEATED. The figure previews it immediately. Your cloth stays loaded.</p></div><div class="step"><strong>03 / Make it</strong><p>CUT, then ASSEMBLE. The robot traces and transfers ten pieces. PAUSE and RESET stay nearby.</p></div><div class="step"><strong>04 / Wear it</strong><p>WEAR applies the completed garment. Look down or use the mirror. TAKE OFF restores the previous look.</p></div></div>
<figure><a href="dress-controls.png"><img src="dress-controls.png" alt="Four labelled shape buttons on the front of the cutting table" loading="lazy"></a><figcaption>The new shape row sits immediately in front of the making controls. Selecting another shape resets the table layout; it does not change the outfit you already wear.</figcaption></figure></section>
<section class="read"><h2>The cut changes. The record stays.</h2><p>A-line, gown and pleated dress have different lengths, sleeve lengths and skirt geometry. Each uses four bodice pieces, two sleeves and four skirt pieces. The suit retains its jacket and trouser panels.</p><p>The selected shape and complete weave record are saved with your wardrobe. Returning to the museum restores both. Trying another cloth at the table leaves the worn snapshot intact.</p><p>These are prescribed geometric silhouettes. The panels retain their cloth addresses as they stretch into shape; this does not simulate sewing, drape or bespoke body measurements. The existing inferred torso and tracked-hand sleeves carry the garment.</p></section>
<section id="evidence" class="evidence"><h2>__COUNT__ Godot checks passed.</h2><p>66 native checks cover the loom handoff, all dress buttons, retained cloth, cutting and assembly, panel UVs, avatar application, fresh save restore, undo to a previous dress, invalid shapes and old suit saves. Another 15 checks run in the installed museum hall, including clear standing approaches and each dress on the actual walker.</p><p>These photographs are Godot renders of the installed hall. Automated button-receiver and wardrobe tests passed; physical-headset reach and comfort still need a hands-on pass.</p><div class="nav"><a href="tests.json">Behaviour checks</a><a href="museum-tests.json">Museum checks</a><a href="source-hashes.json">Source snapshot</a><a href="source/commons/artifacts/garment_cutting_table/README.md">Station guide</a></div></section>
<details><summary>Updated optional tutorial passage</summary><div class="read">__PASSAGE__</div></details>
<footer>The existing shader coding lesson and all its printed listings remain unchanged. Making a garment does not grant curriculum completion.</footer></main>
<script>
const styles={aline:['A-line dress','A short flared skirt and short sleeves.'],gown:['Long gown','An ankle-length skirt with longer sleeves.'],pleated:['Pleated dress','A wider skirt with sixteen geometric pleats.'],suit:['Suit','The original jacket, long sleeves and trousers.']};
function choose(key){if(!styles[key])key='aline';document.querySelector('#shape-title').textContent=styles[key][0];document.querySelector('#shape-note').textContent=styles[key][1];for(const [id,prefix] of [['fit','fitted'],['wear','worn']]){const path=prefix+'-'+key+'.png';document.getElementById(id).src=path;document.getElementById(id).alt=styles[key][0]+(id==='fit'?' on the fitting figure':' worn by the museum avatar');document.getElementById(id+'-link').href=path;}document.querySelectorAll('[data-shape]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.shape===key)));}
document.querySelectorAll('[data-shape]').forEach(b=>b.addEventListener('click',()=>{choose(b.dataset.shape);history.replaceState(null,'','#'+b.dataset.shape);}));choose(location.hash.slice(1));
</script></html>'''
    page = page.replace('<nav class="nav">', '<p><strong>VR player:</strong> WEAR dresses the headset wearer. <a href="../2026-10-10-dresses-on-the-vr-player/index.html">VR rig tests and turn/mirror fixes</a>.</p><nav class="nav">', 1)
    (OUT / 'index.html').write_text(page.replace('__COUNT__', str(count)).replace('__PASSAGE__', para(guide)), encoding='utf-8')
    print(f'Published {count} checks and four photographed garments.')


if __name__ == '__main__':
    main()
