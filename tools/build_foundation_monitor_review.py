"""Static, script-free review of the six native foundation monitors."""
from pathlib import Path
import html, json, os
import build_spine_films as build

OUT = build.ROOT/'doc/book/iterations/2026-10-04-foundation-monitors'
CONTROL_TEXT = {
    'foundation_point': 'LOWER / RAISE changes Y by 0.1 m. FRAME compares the extra one-metre offset. RESET returns to 1.2 m.',
    'foundation_trace': 'READ NEXT tests the next candidate against the last kept position. JOIN PAIR connects the next retained neighbours. RESET clears the study.',
    'foundation_state': 'FRAME advances the teaching clock by 0.5 seconds. APPROACH / AWAY compares a current response with a remembered visit. RESET clears both.',
    'foundation_function': 'SIDES cycles 4, 6, 8, 12 and 16. LOWER / RAISE changes height. The other column remains four-sided and two metres tall.',
    'foundation_array': 'NEXT SLOT reads another address. WRITE toggles its value. RULE assigns a checker pattern. RESET restores the occupied grid.',
    'foundation_class': 'ADVANCE A / B changes the referenced palette. LINK / UNLINK compares shared and separate state. RESET keeps the link setting and resets both indices.',
}


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    esc = html.escape
    rel = lambda p: os.path.relpath(p,OUT).replace(os.sep,'/')
    entries = [e for e in build.read(build.BASE/'catalog.json') if e.get('collection')=='foundation']
    cards = []
    for e in entries:
        folder = build.OUT/e['id']
        museum = folder/'museum.png'
        video = folder/'film.mp4'
        poster = folder/'poster.png'
        media = f'<video controls playsinline preload="none" poster="{rel(poster)}" src="{rel(video)}"></video>' if video.exists() else f'<img src="{rel(poster)}" alt="{esc(e["title"])}">'
        photo = f'<a href="{rel(museum)}"><img src="{rel(museum)}" alt="Monitor inside {esc(e["map"])}"></a>' if museum.exists() else '<p>Museum capture is being prepared.</p>'
        cards.append(f'<section id="{e["id"]}"><p class="eyebrow">{esc(e["map"])}</p><h2>{esc(e["title"])}</h2><p class="intro">{esc(e["description"])}</p><div class="pair"><figure>{media}<figcaption>The native Godot demonstration. Use the lower controls in the museum to try it yourself.</figcaption></figure><figure>{photo}<figcaption>Inside the Endless Museum. Open the image for the full view.</figcaption></figure></div><p class="controls">{esc(CONTROL_TEXT[e["id"]])}</p><details><summary>What the study represents</summary><p>{esc(e["limitation"])}</p><a href="{rel(build.ROOT/e["scene"].removeprefix("res://"))}">Godot scene</a></details></section>')
    menu = ''.join(f'<a href="#{e["id"]}">{esc(e["title"])}</a>' for e in entries)
    page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Six comparisons, inside the museum · Ada</title><style>
:root{--paper:#f3f0e8;--ink:#23382f;--line:#cdd3c8;--rose:#a44973}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.65 system-ui,sans-serif}main{max-width:1380px;margin:auto;padding:38px}header{max-width:970px;margin:20px 0 42px}h1,h2{font:400 58px/1.1 Georgia,serif;letter-spacing:-.025em}h2{font-size:36px}a{color:inherit;text-underline-offset:3px}.eyebrow{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;color:var(--rose)}.lead{font-size:22px}nav{display:flex;flex-wrap:wrap;gap:10px 20px;font-size:13px;padding:18px 0;border-block:1px solid var(--line)}section{padding:35px 0;border-bottom:1px solid var(--line)}.intro{max-width:930px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px;align-items:start}figure{margin:10px 0;background:#e3e4de}video,img{display:block;width:100%;height:auto}figcaption{padding:12px;font-size:12px}.controls{background:#fffdf7;padding:16px 20px;border-left:3px solid var(--rose)}details{font-size:13px;max-width:920px}summary{cursor:pointer}footer{font-size:12px;padding:28px 0}a:focus-visible,summary:focus-visible{outline:3px solid var(--rose);outline-offset:4px}@media(max-width:780px){main{padding:20px}.pair{grid-template-columns:1fr}h1{font-size:40px}h2{font-size:30px}}</style></head><body><main><header><p class="eyebrow">Ada · Foundation studies · 4 October 2026</p><h1>Six comparisons,<br>inside the museum.</h1><p class="lead">Watch the operation, pause it, then change something yourself.</p><p>The six working sketches have become native 3D scenes with their own cameras. Each monitor plays when you look at it. Its lower controls hold the demonstration and let you try the model; your choices remain when you look away. <b>DEMO</b> starts the demonstration again.</p><p><a href="http://localhost:3003/research/foundation-visuals/index.html">The original foundation visuals</a> · <a href="../2026-10-04-spine-films/index.html#collection=foundation">Browse the film collection</a></p></header><nav>MENU</nav>CARDS<footer>Native desktop rendering, controls and museum placements checked. Physical Quest testing remains. The teaching controls act on these private studies; the surrounding exhibits keep their own behaviour. <a href="../2026-10-04-spine-films/foundation-verification.json">Verification record</a></footer></main></body></html>'''.replace('MENU',menu).replace('CARDS',''.join(cards))
    (OUT/'index.html').write_text(page,encoding='utf-8')
    print('Built',OUT/'index.html','with',len(entries),'studies')


if __name__ == '__main__':
    main()
