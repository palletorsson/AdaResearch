"""Publish the hand-loom review from existing native captures and test receipts."""
from pathlib import Path
import html
import json
import shutil
import hashlib
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-thread-loom'
REVIEW = ROOT / 'doc/book/iterations/2026-10-09-tiling-thread-and-hand'
MAP = ROOT / 'commons/maps/Symmetry_Seventeen'

STYLE = '''
:root{color-scheme:light;--ink:#272922;--muted:#62665c;--line:#cecfc1;--pink:#a63863}
*{box-sizing:border-box}body{margin:0;background:#f3f1e8;color:var(--ink);font:18px/1.6 Georgia,serif}
main{max-width:1120px;margin:auto;padding:42px 28px 90px}nav,.eyebrow,figcaption,.small{font:14px/1.55 system-ui,sans-serif;color:var(--muted)}
nav{display:flex;gap:12px 26px;flex-wrap:wrap;border-bottom:1px solid var(--line);padding:0 0 18px;margin-bottom:36px}
a{color:var(--pink);text-underline-offset:3px}h1{font-size:clamp(40px,6vw,76px);line-height:1.06;font-weight:400;margin:12px 0 25px;letter-spacing:-.035em}h2{font-weight:400;font-size:30px;margin-top:44px;line-height:1.2}h3{font-size:22px}p,li{max-width:77ch}figure{margin:28px 0}img{display:block;width:100%;height:auto;background:#21262a}figcaption{margin-top:9px}article{max-width:860px;margin:auto}article img{margin-top:20px}blockquote{border-left:3px solid var(--pink);margin-left:0;padding-left:24px}table{border-collapse:collapse;font-size:16px;width:100%;display:block;overflow:auto}td,th{text-align:left;vertical-align:top;border-bottom:1px solid var(--line);padding:13px 12px}code{font:14px/1.5 monospace}pre{overflow:auto;background:#e8e6dc;padding:20px}.status{padding:20px 24px;background:#e5eadf;border-left:3px solid #536c46}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.pair figure{margin:0}details{border-top:1px solid var(--line);padding:15px 0}summary{cursor:pointer;font-family:system-ui,sans-serif}li{margin:6px 0}.lead{font-size:24px;line-height:1.4}.table-wrap{overflow-x:auto}@media(max-width:700px){main{padding:25px 18px 50px}.pair{grid-template-columns:1fr}body{font-size:17px}}
'''


def page(title, body, nav):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{STYLE}</style></head><body><main><nav>{nav}</nav>{body}</main></body></html>'


def md_page(src, dest, nav, replacements=None):
    text = src.read_text(encoding='utf-8-sig')
    for old, new in (replacements or {}).items():
        text = text.replace(old, new)
    body = markdown.markdown(text, extensions=['tables', 'fenced_code'])
    title = text.splitlines()[0].lstrip('# ')
    dest.write_text(page(title, '<article>'+body+'</article>', nav), encoding='utf-8')


def main():
    runtime = json.loads((OUT/'tests.json').read_text())
    museum = json.loads((OUT/'museum-tests.json').read_text())
    assert runtime['passed'] and museum['passed'], 'Do not publish a passing report over failing evidence'
    assert all(c['passed'] for r in [runtime, museum] for c in r['checks'])
    n, m = len(runtime['checks']), len(museum['checks'])
    source_dir = OUT / 'source'
    source_dir.mkdir(exist_ok=True)
    for name in ['README.md', 'thread_loom.gd', 'shuttle.gd', 'thread_loom.tscn']:
        shutil.copy2(ROOT/'commons/artifacts/thread_loom'/name, source_dir/name)
    for name in ['thread_loom_test.gd', 'thread_loom_museum.gd']:
        shutil.copy2(ROOT/'tools/probes'/name, source_dir/name)
    for name in ['capture', 'museum']:
        shutil.copy2(OUT/(name+'.log'), OUT/(name+'-log.txt'))
    hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(source_dir.iterdir()) if p.is_file()}
    (OUT/'source-hashes.json').write_text(json.dumps(hashes, indent=2)+'\n', encoding='utf-8')
    nav = '<a href="index.html">The working loom</a><a href="final.html">Hall reflection</a><a href="textile-note.html">The thread and the work</a><a href="http://localhost:3003/pattern-machines-gallery">Machine gallery</a>'
    if (OUT.parent/'2026-10-09-tiling-making-and-wearing/final.html').exists():
        nav += '<a href="../2026-10-09-tiling-making-and-wearing/final.html">Read the revised Tiling sequence</a>'
    body = f'''
<div class="eyebrow">TILING / SYMMETRY SEVENTEEN · 9 OCTOBER 2026 · BUILT IN GODOT</div>
<h1>Follow the thread.</h1>
<p class="lead">Take the shuttle. Carry a thread through the opening. Beat it into place. The cloth keeps the choices you made.</p>
<p>A working hand loom now stands beside the pattern atlas displays in the real museum. Twelve cream warp threads meet one continuous pink weft. A four-by-four draft chooses which threads lift.</p>
<figure><a href="museum.png"><img src="museum.png" alt="The wooden hand loom installed beside pattern displays in the Symmetry Seventeen museum hall"></a><figcaption>Inside the actual Symmetry Seventeen hall. Native Godot capture; the image shows twelve woven passes after testing.</figcaption></figure>
<h2>Use your hands</h2>
<ol><li>Choose <strong>PLAIN</strong>, <strong>TWILL</strong>, or edit the sixteen draft buttons on the left. A lit cell means warp over weft.</li><li>Pick up the brass shuttle from the lit side. Move it horizontally through the gap between the raised and lowered threads, all the way to the other side.</li><li>Press the held shuttle's <strong>trigger</strong>, or <strong>BEAT</strong> beside the loom. The reed beats in one pass.</li><li>Return through the opening in the opposite direction. Change the draft between passes and find where the new rule begins in the cloth.</li></ol>
<p class="small">Four passes are supplied on arrival. RESET leaves bare warp. UNDO removes the pending or last committed pass. PASS supplies a guided traversal for desktop use; BEAT still commits it. The finite sample holds 24 passes.</p>
<div class="pair"><figure><a href="player-view.png"><img loading="lazy" src="player-view.png" alt="A standing view of the shuttle, raised warp and controls within reach"></a><figcaption>Working position in the museum. The draft and beat controls sit beside the hands.</figcaption></figure><figure><a href="crossings.png"><img loading="lazy" src="crossings.png" alt="Close view of continuous pink weft crossing over and under cream warp threads"></a><figcaption>Separate yarn surfaces at each crossing. The cloth travels over the front beam.</figcaption></figure></div>
<h2>A change leaves a place in the cloth</h2>
<p>Each completed pass records the draft that made it. Editing the next row leaves the earlier work intact. This gives the sequence a material operation to compare with changing the image on a surface.</p>
<p>The loom builds thread geometry. Its yarn paths and take-up are prescribed; tension, friction and cloth deformation are not simulated. Weaving and knitting remain different constructions. This artifact models weaving.</p>
<p>It is an additional museum encounter. The agreed symmetry tutorials and their code are unchanged. The hall reflection now follows the thread, with a note placing Sadie Plant's <em>Zeros + Ones</em> beside <em>Mamma Mönster</em>.</p>
<h2>Checked in the running project</h2>
<div class="status"><strong>{n} runtime checks + {m} museum checks passed.</strong><p>Tests cover crossing order and clearance, retained draft history, invalid passes, beating, undo/reset, bounded geometry, simulated XR pickup and trigger use, and placement in the actual hall. Physical headset reach and comfort still need your playthrough.</p></div>
<p class="small"><a href="tests.json">Runtime assertions</a> · <a href="museum-tests.json">Museum assertions</a> · <a href="capture.log">Runtime log</a> · <a href="museum.log">Museum log</a></p>
<details><summary>Build and placement</summary><p>Tiling → Symmetry Seventeen, cell [16,21], beside the atlas plates. Token <code>thread_loom</code>. Existing machines remain in place.</p><p><a href="../../../../../../commons/artifacts/thread_loom/README.md">Artifact instructions</a> · <a href="../../../../../../commons/artifacts/thread_loom/thread_loom.gd">Loom source</a> · <a href="../../../../../../commons/artifacts/thread_loom/shuttle.gd">Shuttle source</a></p></details>
<h2>Read it with the sequence</h2>
<p><a href="final.html">Updated hall reflection</a> · <a href="textile-note.html">Plant, Mamma Mönster and textile construction</a> · <a href="../2026-10-09-tiling-thread-and-hand/index.html">How the sequence can become tighter</a></p>
<p><a href="http://localhost:3003/pattern-atlas">Pattern atlas</a> · <a href="http://localhost:3003/pattern-mill-gallery">Pattern mill</a> · <a href="http://localhost:3003/pattern-machines-gallery">Pattern machines, including the new loom</a></p>
'''
    body = body.replace('../../../../../../commons/artifacts/thread_loom/', 'source/')
    body = body.replace('href="capture.log"', 'href="capture-log.txt"').replace('href="museum.log"', 'href="museum-log.txt"')
    (OUT/'index.html').write_text(page('Follow the thread', body, nav), encoding='utf-8')
    md_page(MAP/'final.md', OUT/'final.html', nav, {'(textile-note.md)':'(textile-note.html)'})
    md_page(MAP/'textile-note.md', OUT/'textile-note.html', nav)
    shutil.copy2(MAP/'final.md', OUT/'final.md')
    shutil.copy2(MAP/'textile-note.md', OUT/'textile-note.md')
    md_page(REVIEW/'REVIEW.md', REVIEW/'index.html', '<a href="../2026-10-09-thread-loom/index.html">The working loom</a><a href="../2026-10-09-tiling-different-jobs/index.html">The nine-hall route</a>')
    print(f'Published loom review, reflective reading and editorial proposal; {n}+{m} passing checks.')


if __name__ == '__main__':
    main()
