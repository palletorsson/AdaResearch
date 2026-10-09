"""Present the comic, accessible synopsis, research note and generation provenance."""
from pathlib import Path
from html import escape
from hashlib import sha256
import json
import markdown

HERE = Path(__file__).resolve().parent


def main():
    image = HERE/'comic-v2.png'
    if not image.is_file():
        raise SystemExit('Save the generated comic before building its page.')
    synopsis = (HERE/'SYNOPSIS.md').read_text(encoding='utf-8')
    research = (HERE/'RESEARCH-NOTE.md').read_text(encoding='utf-8')
    synopsis_html = markdown.markdown(synopsis, extensions=['tables','fenced_code'])
    research_html = markdown.markdown(research, extensions=['tables','fenced_code'])
    provenance = dict(
        title="The student who hasn't arrived",
        date='2026-10-05',
        method='Built-in image_gen tool; original generation, museum-reference edit, then targeted podium-count correction. No image-editing postprocessing.',
        prompt='PROMPT.txt',
        edit_prompts=['EDIT-PROMPT-v2.txt','EDIT-PROMPT-v2-podiums.txt'],
        asset='comic-v2.png',
        previous_asset='comic.png',
        architectural_references=['../2026-10-03-point-one-existing-points/corridor.png','../2026-10-03-point-one-existing-points/solid.png'],
        sha256=sha256(image.read_bytes()).hexdigest(),
        status='Fictional comic synopsis based on an actual bounded code-continuation experiment. Not a museum screenshot or record of participants.',
        provenance_note='Museum revision: three entrance podiums, straight gallery architecture, repeated title and always another room, large polished black future sphere. The authored transcript is SYNOPSIS.md.',
        actual_code_reference='../2026-10-05-lesson-state-chain/assembled.gd',
        evidence_reference='../2026-10-05-lesson-state-chain/report-runtime.json')
    (HERE/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n',encoding='utf-8')
    page = '''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>The student who hasn't arrived · Endless Museum</title>
<style>
:root{color-scheme:light;--paper:#f3f0e9;--ink:#272727;--rose:#815063}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.7 system-ui,sans-serif}header,main,footer{max-width:1160px;margin:auto;padding:2rem}header{padding-top:3rem}h1{font:clamp(2.2rem,5vw,4rem)/1.08 Georgia,serif;letter-spacing:-.035em;margin:.7rem 0 1rem}h2{font:1.7rem/1.3 Georgia,serif}p{max-width:74ch}.eyebrow{font-size:12px;letter-spacing:.16em;text-transform:uppercase;color:var(--rose)}a{color:var(--rose);text-underline-offset:3px}nav{display:flex;gap:1.2rem;flex-wrap:wrap;margin-top:1.2rem;font-size:.9rem}figure{margin:0}figure img{display:block;width:100%;height:auto;box-shadow:0 10px 38px #30291e1a}figcaption{font-size:.85rem;color:#68625b;margin:1rem auto 3rem;max-width:80ch}.text{max-width:840px;margin:3.5rem auto}.text h1{font-size:2.2rem}details{margin:2rem 0;border-top:1px solid #c9c2b6;padding-top:1rem}summary{cursor:pointer;font-size:1.1rem}table{width:100%;border-collapse:collapse;margin:2rem 0;font-size:.86rem}th,td{padding:.7rem;border-bottom:1px solid #d2cbbe;vertical-align:top;text-align:left}code{font-family:Consolas,monospace;font-size:.92em}footer{font-size:.8rem;color:#68625b;border-top:1px solid #c9c2b6}#comic,#synopsis,#research{scroll-margin-top:1rem}.line{font:1.5rem/1.4 Georgia,serif;margin:2rem auto;max-width:65ch}
@media(max-width:700px){header,main,footer{padding:1rem}header{padding-top:2rem}td,th{padding:.4rem}table{font-size:.8rem}}
@media print{header,footer,nav,.text,figcaption{display:none}body{background:white}main{padding:0;max-width:none}figure img{box-shadow:none;max-height:98vh;width:auto;max-width:100%;margin:auto}@page{size:A3 portrait;margin:8mm}}
</style></head><body><header><div class="eyebrow">Endless Museum · Comic synopsis · 5 October 2026</div>
<h1>The student who hasn't arrived</h1><p>The student is imagined. The code can already run. A point passes from one lesson to the next while the encounter being prepared for keeps changing.</p>
<nav><a href="#comic">Comic</a><a href="#synopsis">Panel transcript</a><a href="#research">Research note</a><a href="comic-v2.png" download>Download image</a><a href="../2026-10-05-lesson-state-chain/index.html">The real continuation test</a></nav></header>
<main><figure id="comic"><a href="comic-v2.png"><img src="comic-v2.png" alt="Eight-panel comic in the museum's white rectangular rooms: the student enters past three podiums, continues with a small white sphere, tests its pickup, then approaches a large glossy black sphere, the object of the future. Walls read ENDLESS MUSEUM, always another room. Full panel transcript follows." aria-describedby="comic-caption"></a><figcaption id="comic-caption">Museum revision: three entrance podiums, familiar gallery architecture and wall lettering, with the large black sphere awaiting the student. Generated illustration; fictional participants. The small white point, code line and test result refer to the actual continuation pilot. Click the page for the full image.</figcaption></figure>
<p class="line">The intended recipient is moving while you are constructing the address.</p>
<section class="text" id="synopsis"><details><summary>Read the eight panels as text</summary>'''+synopsis_html+'''</details></section>
<section class="text" id="research">'''+research_html+'''<nav><a href="EDIT-PROMPT-v2.txt">Museum revision prompt</a><a href="EDIT-PROMPT-v2-podiums.txt">Podium correction prompt</a><a href="PROMPT.txt">Original prompt</a><a href="comic.png">First image</a><a href="provenance.json">Image provenance</a><a href="SYNOPSIS.md">Editable synopsis</a></nav></section>
</main><footer>Built-in image generation · Research sources checked 5 October 2026 · Museum code and canonical tutorial text unchanged by this comic.</footer></body></html>'''
    (HERE/'index.html').write_text(page,encoding='utf-8')
    print('Saved comic page, synopsis, research note and image provenance.')


if __name__ == '__main__':
    main()
