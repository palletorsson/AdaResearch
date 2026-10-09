from pathlib import Path
import html
import json
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STUDY = ROOT / 'doc/book/studies/ada-xr-starter'
checks = json.loads((OUT / 'verification.json').read_text())
assert checks['passed'] and all(c['passed'] for c in checks['checks'])
count = len(checks['checks'])
code = html.escape((STUDY / 'studies/hello_world.gd').read_text())
readme = markdown.markdown((STUDY / 'README.md').read_text(encoding='utf-8'), extensions=['tables', 'fenced_code'])
verified = markdown.markdown((STUDY / 'VERIFICATION.md').read_text(encoding='utf-8'))
style = '''
*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#28272a;font:19px/1.65 Georgia,serif}
main{max-width:1160px;margin:auto;padding:32px 28px 70px}header{font:14px/1.6 system-ui,sans-serif;border-bottom:1px solid #ccc5bb;padding-bottom:22px}
nav{display:flex;gap:24px;flex-wrap:wrap}a{color:#85445e;text-underline-offset:4px}h1{font-size:clamp(36px,5vw,64px);line-height:1.12;font-weight:normal;margin:42px 0 20px}h2{font-size:28px;font-weight:normal;margin-top:42px}
.intro{max-width:760px}figure{margin:36px 0}img{width:100%;height:auto;display:block}figcaption,.small{font:14px/1.6 system-ui,sans-serif;margin-top:12px;color:#5c5559}
.roles{display:grid;grid-template-columns:repeat(3,1fr);gap:30px;border-top:1px solid #ccc5bb;border-bottom:1px solid #ccc5bb;padding:22px 0;margin:36px 0}.roles h2{margin:0 0 12px;font-size:25px}.roles p{margin:0;font-size:17px}
.download{display:inline-block;background:#713c52;color:#fff;padding:12px 24px;text-decoration:none;font:16px/1.5 system-ui,sans-serif;border-radius:3px}details{margin-top:24px;border-top:1px solid #ccc5bb;padding-top:20px}summary{font:17px/1.6 system-ui,sans-serif;cursor:pointer}details>div{max-width:820px}pre{overflow:auto;background:#e5dfd6;padding:22px;font:15px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.86em}pre code{font:inherit}table{border-collapse:collapse;width:100%;font-size:16px}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #ccc5bb}
a:focus-visible,summary:focus-visible{outline:3px solid #bb6a8b;outline-offset:4px}@media(max-width:720px){.roles{grid-template-columns:1fr}main{padding:24px 18px}body{font-size:18px}}@media print{header,.download{display:none}body{background:white}main{padding:0}}
'''
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ada — a place to begin</title><style>{style}</style></head>
<body><main><header><p>ADA / DAY ZERO · 3 October 2026</p><nav><a href="#room">The room</a><a href="#study">The student's part</a><a href="#guide">Open the project</a><a href="#verification">What was checked</a><a href="../2026-10-03-point-zero-one-lesson/index.html#reading">Point Zero tutorial</a></nav></header>
<section class="intro"><h1>A place to begin.</h1><p>One prepared room. A player who can move and hold something. A small piece of code that is yours to change.</p><p>The same counter can run here or in a separate desktop study. The room gives it a place; its script creates the display and keeps the count.</p><a class="download" href="ada-xr-starter.zip" download>Download the student starter · Godot 4.6</a><p class="small">XR Tools 4.5.1 included. Desktop checked; physical headset and Quest export checks pending.</p></section>
<figure id="room"><a href="room.png"><img src="room.png" alt="The Godot starter room with an off-white plinth, pink pickup cube, dark floor and running counter on a charcoal panel"></a><figcaption>Inside the running starter · actual Godot desktop render. The pink cube checks the supplied pickup. The counter is the student’s first study.</figcaption></figure>
<p class="small"><a href="../2026-10-03-day-zero-light-and-material/index.html">See the new Day Zero lighting setup — before / after and one light experiment.</a></p>
<p class="small"><a href="../2026-10-03-point-one-a-body/index.html#reading">Continue with Point One — a position, a surface and a boundary in this same room.</a></p>
<p class="small"><a href="../2026-10-03-point-lines-two-ends/index.html#reading">Preview Point Lines — two held positions and the relation between them.</a></p>
<p class="small"><a href="../2026-10-03-point-trace-positions-kept/index.html#reading">Continue with Point Trace — keep positions and follow their order.</a></p>
<p class="small"><a href="../2026-10-03-point-grid-an-address/index.html#reading">Continue with Point Grid — give a position an address, then place it again.</a></p>
<p class="small"><a href="../2026-10-03-trace-return-to-grid/index.html#reading">Current Trace → Grid handoff: bring your own released gesture into the next lesson.</a></p>
<section class="roles"><div><h2>Borrow the room.</h2><p>Day Zero supplies the view, light, floor, movement and input. Establish them once, then begin.</p></div><div><h2>Make the study.</h2><p>The lesson creates its own object in code. It names any supplied component it needs.</p></div><div><h2>Return to Ada.</h2><p>Keep the work small enough to move. Its scale, neighbours and place in the hall give it another situation.</p></div></section>
<section class="intro" id="study"><h2>The student's part stays small.</h2><p>This is the unchanged Point Zero counter. It is attached to <code>Study</code> in <code>main.tscn</code>. There is no prepared label to fetch.</p><pre><code>{code}</code></pre><p>The player code lives separately. Understanding the frame counter does not require rebuilding the player.</p></section>
<details id="guide"><summary>Open the project and try it</summary><div>{readme}</div></details>
<details id="verification"><summary>{count} checks passed · see their scope</summary><div>{verified}<p><a href="verification.json">Individual check results</a></p></div></details>
</main><script>function reveal(){{let el=document.querySelector(location.hash||'#room');if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print('Review page rebuilt.')
