"""Publish the locally rendered audiobook tracks without changing manuscripts."""
from pathlib import Path
import html
import json

base = Path(__file__).resolve().parent
edition = json.loads((base / 'narration.json').read_text(encoding='utf-8'))
audio_dir = base / 'google/gemini-3.1-flash-tts-preview-Sulafat'
render_file = audio_dir / 'render.json'
render = json.loads(render_file.read_text(encoding='utf-8')) if render_file.exists() else {'tracks': [], 'complete': False}
tracks = render['tracks']

def url(path):
    return html.escape(path.relative_to(base).as_posix(), quote=True)

def player(path, label):
    src = url(path)
    return f'<audio controls preload="metadata" aria-label="{html.escape(label, quote=True)}" src="{src}"></audio><a class="download" href="{src}" download>Download MP3</a>'

def duration(seconds):
    total = round(seconds)
    return f'{total // 60}:{total % 60:02d}'

state = 'The complete Primitives capture is ready.' if render.get('complete') else f'{len(tracks)} of 11 tracks ready. More tracks are rendering; refresh this page to see them.'
blocks = []
complete = audio_dir / 'primitives-complete.mp3'
if render.get('complete') and complete.exists():
    blocks.append('<section class="complete"><h2>The whole walk</h2><p>' + duration(render['seconds']) + ' · ten halls and closing notes</p>' + player(complete, 'Complete Primitives audiobook') + '</section>')
else:
    sample = audio_dir / 'sample.mp3'
    if sample.exists():
        blocks.append('<section><h2>Opening voice sample</h2><p>Point One · 57 seconds</p>' + player(sample, 'Point One opening sample') + '</section>')
for i, track in enumerate(tracks):
    title = html.escape(track['title'])
    transcript = edition['chapters'][i]['stem']
    blocks.append(f'<section><p class="eyebrow">TRACK {i + 1:02d} · {duration(track["seconds"])}</p><h2>{title}</h2>' + player(audio_dir / track['mp3'], title) + f'<a class="transcript" href="transcripts/{transcript}.txt">Read this track</a></section>')
remaining = ''.join('<li>' + html.escape(c['title']) + '</li>' for c in edition['chapters'][len(tracks):])
if remaining:
    blocks.append('<section><h2>Still rendering</h2><ol start="' + str(len(tracks) + 1) + '">' + remaining + '</ol></section>')
page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitives — Ada Research audiobook</title><style>
*{box-sizing:border-box}body{max-width:840px;margin:6vh auto;padding:24px;background:#f5f0e6;color:#27251f;font:19px/1.65 Georgia,serif}h1{font-size:clamp(42px,8vw,78px);line-height:1.02;letter-spacing:-.035em}h2{font-weight:normal;margin:0 0 10px;font-size:30px}a{color:#80431e}section{border-top:1px solid #cabcaa;padding:24px 0}.state{border-left:4px solid #80431e;padding:12px 18px;background:#eae0cf}.eyebrow,small,.download,.transcript{font:13px/1.6 system-ui;letter-spacing:.04em}audio{display:block;width:100%;margin:12px 0}.transcript{margin-left:22px}.complete{background:#eae0cf;padding:24px;border:0;border-radius:10px}footer{margin-top:36px}li{margin:8px 0}
</style></head><body><small>ADA RESEARCH · AUDIO EDITION · 21 SEPTEMBER 2026</small><h1>Primitives.<br>A walk to listen to.</h1>'''
page += '<p class="state">' + state + '</p><p>From the point to Melencolia. Narrated in English with Google’s synthetic Sulafat voice. Code is spoken in words; the 37 footnotes are gathered in the closing track.</p>'
page += ''.join(blocks)
page += '<footer><a href="transcript.txt">Complete narration text</a> · <a href="STATUS.md">Edition notes</a><p><small>This audio edition uses frozen copies of the ten current manuscripts. The audio process did not edit the manuscripts. One later Grid control note is listed in the edition notes. Spoken code is an adaptation; synthesis and file checks do not replace a listening review.</small></p></footer></body></html>'
(base / 'index.html').write_text(page, encoding='utf-8')
print(f'Published {len(tracks)} tracks; complete={render.get("complete", False)}')
