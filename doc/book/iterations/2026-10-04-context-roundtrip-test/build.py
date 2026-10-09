"""Build a portable report from the saved test documents."""
from pathlib import Path
from html import escape
import markdown

HERE = Path(__file__).resolve().parent
STYLE = '''
:root{color-scheme:light;--paper:#f5f3ed;--ink:#24382f;--muted:#657068;--line:#d4dbd1;--accent:#91385d}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink);font:19px/1.75 Georgia,serif}
header,footer{padding:22px 5vw;font:13px/1.6 system-ui,sans-serif;border-bottom:1px solid var(--line)}header,nav{display:flex;gap:22px;flex-wrap:wrap}header{justify-content:space-between}
main{max-width:1000px;margin:60px auto 80px;padding:0 28px}h1{font-size:clamp(40px,6vw,76px);font-weight:400;line-height:1.08;letter-spacing:-.035em;max-width:850px;margin:0 0 24px}
h2{font-size:30px;line-height:1.25;font-weight:400;margin-top:55px}h3{font-size:22px}p{margin:24px 0}a{color:var(--accent);text-underline-offset:4px}code{font:0.83em/1.5 Consolas,monospace;overflow-wrap:anywhere}
table{border-collapse:collapse;width:100%;font:14px/1.6 system-ui,sans-serif;margin:28px 0}th,td{text-align:left;vertical-align:top;padding:13px;border-bottom:1px solid var(--line)}th{font-weight:650;background:#e7ece4}
blockquote{border-left:3px solid var(--accent);margin:28px 0;padding:1px 24px;background:#e9ece5}li{margin:8px 0}.route{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin:30px 0;font:14px/1.6 system-ui,sans-serif}.route details{padding:15px;border:1px solid var(--line);background:#fffdf7}.route summary{cursor:pointer;font-weight:650;color:var(--accent)}.route p{margin:12px 0 0}.overline{font:12px/1.5 system-ui,sans-serif;text-transform:uppercase;letter-spacing:.12em;color:var(--muted)}a:focus-visible,summary:focus-visible{outline:2px solid var(--accent);outline-offset:4px}footer{border-top:1px solid var(--line);border-bottom:0;color:var(--muted)}.return{font:14px/1.6 system-ui,sans-serif;color:var(--muted)}
@media(max-width:760px){body{font-size:17px}main{margin:35px auto;padding:0 18px}.route{grid-template-columns:1fr 1fr}th,td{padding:9px;font-size:12px}header{padding:18px}}
@media print{body{background:white;font-size:11pt}header,footer,.route,.return{display:none}main{margin:0;max-width:none;padding:0}h1{font-size:32pt}h2{font-size:19pt;break-after:avoid}tr{break-inside:avoid}a{color:inherit}p{orphans:3;widows:3}}
'''
route = '''<p class="overline">Inspect the levels · open a card</p><div class="route" aria-label="The local to global return">
<details open><summary>Whole project</summary><p>Existing museum. Supplied, encountered and learned are different. Preserve artistic inquiry.</p></details>
<details open><summary>Sequence</summary><p>Segment → recorded list → lattice address. Arrays returns to that material with another operation.</p></details>
<details open><summary>Map</summary><p>Grid fits the accepted record before rounding. Keep source and display address distinct.</p></details>
<details open><summary>Evidence</summary><p>Frozen code supports that order. It does not establish headset transfer or beginner understanding.</p></details>
</div><p class="return">Return outward: the local distinction changes the Array handoff and the shared teaching agreement. It does not automatically change the museum order.</p>'''

def make_page(source, output, title, navigation, add_route=False):
    body = markdown.markdown((HERE / source).read_text(encoding='utf-8'), extensions=['tables', 'fenced_code', 'toc'])
    if add_route:
        marker = '<h2 id="moving-back-to-the-whole">'
        body = body.replace(marker, route + marker, 1)
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{escape(title)} | Ada</title><style>{STYLE}</style></head><body><header><span>ADA / MEMORY EXPERIMENT</span><nav>{navigation}</nav></header><main>{body}</main><footer>4 October 2026 · Selected source inspection and a fresh-context handoff. No museum runtime or learner trial.</footer></body></html>'''
    (HERE / output).write_text(page, encoding='utf-8')

make_page('REPORT.md', 'index.html', 'Can the local finding survive the return?', '<a href="#moving-back-to-the-whole">The return</a><a href="precedents.html">Related systems</a><a href="PACKET.md">402-word packet</a><a href="REPORT.md">Editable report</a>', True)
make_page('PRECEDENTS.md', 'precedents.html', 'Systems to learn from', '<a href="index.html">Test results</a><a href="PRECEDENTS.md">Editable notes</a>')
print('Built index.html and precedents.html')
