"""Render Codex's independent batch-25 reviews without changing worker status."""
from pathlib import Path
import html
import json
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / 'doc/book/iterations/2026-10-21-void-transfer-batch-25'

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    esc = html.escape
    jobs = json.loads((HERE / 'batch.json').read_text())['jobs']
    total_maps = sum(len(job['maps']) for job in jobs)
    total_objects = sum(job['source_placements'] for job in jobs)
    batch_number = HERE.name.rsplit('-', 1)[-1]
    accepted = 0
    sections = []
    for job in jobs:
        trial = job['sequence']
        review_file = HERE / (trial + '-review.json')
        review = json.loads(review_file.read_text()) if review_file.exists() else {}
        passed = review.get('status') == 'accepted_as_uncurated_transfer'
        if passed:
            accepted += len(job['maps'])
        folder = ROOT / job['folder']
        evidence = folder / 'evidence'
        target = OUT / trial
        target.mkdir(exist_ok=True)
        rows = []
        for level, name in enumerate(job['maps'], 1):
            url = f'http://localhost:3003/lab-editor?mode=void&trial={trial}&floor={level}'
            rows.append(f'<li><a href="{esc(url, quote=True)}">{esc(name)}</a> · floor {level}</li>')
        gallery = []
        for photo in sorted(evidence.glob('*.png')):
            shutil.copy2(photo, target / photo.name)
            gallery.append(f'<figure><a href="{trial}/{photo.name}"><img loading="lazy" src="{trial}/{photo.name}" alt="{esc(photo.stem)}"></a><figcaption>{esc(photo.stem.replace("-", " "))}</figcaption></figure>')
        if review_file.exists():
            shutil.copy2(review_file, target / 'review.json')
        receipts = []
        for name in ['source-checks.json', 'checks.json', 'editor-checks.json']:
            p = evidence / name
            if not p.exists(): continue
            report = json.loads(p.read_text(encoding='utf-8-sig'))
            shutil.copy2(p, target / name)
            receipts.append(f'<a href="{trial}/{name}">{esc(name)}: {len(report.get("checks", []))} checks, {"passed" if report.get("passed") else "pending"}</a>')
        limits = ''.join('<li>' + esc(x) + '</li>' for x in review.get('limitations', []))
        sections.append(f'<section id="{trial}"><h2>{esc(trial)}</h2><p>{"Accepted as an uncurated transfer" if passed else "Review in progress"} · {job["source_placements"]} original objects</p><ul>{"".join(rows)}</ul><p class="receipts">{" · ".join(receipts)} · <a href="{trial}/review.json">Independent review</a></p><div class="gallery">{"".join(gallery)}</div><details><summary>Recorded limits and remaining curation</summary><ul>{limits}</ul></details></section>')
    page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Void transfer batch {batch_number}</title>
<style>body{{margin:0;background:#19171f;color:#eee5ef;font:17px/1.5 system-ui}}main{{max-width:1200px;margin:auto;padding:40px 24px}}h1{{font-size:48px;line-height:1.1}}h2{{font-size:30px}}a{{color:#e7bcec}}section{{border-top:1px solid #5a4c61;padding:28px 0;margin-top:32px}}.gallery{{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}}figure{{margin:0}}img{{width:100%}}figcaption,.receipts{{font-size:13px}}details{{padding:16px;background:#25212e;margin-top:20px}}@media(max-width:750px){{.gallery{{grid-template-columns:1fr}}}}</style>
<main><p>21 October 2026 · batch {batch_number} · independent transfer review</p><h1>{accepted} of {total_maps} maps reviewed and accepted.</h1><p>{total_objects} original artifact occurrences from the museum. These trials preserve the source works for arrangement in the lab editor. Curation and chapter texts follow later.</p><p>Native checks use desktop and synthetic tracked XR. Physical-headset testing remains outstanding. Exported models are arrangement snapshots; Godot runs the interactions.</p>{''.join(sections)}</main></html>'''
    (OUT / 'index.html').write_text(page, encoding='utf-8')
    print(OUT / 'index.html')

if __name__ == '__main__':
    main()
