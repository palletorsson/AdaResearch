"""Publish the opt-in bridge review; keep the recorded RSI baseline intact."""
from pathlib import Path
import json, shutil, html as html_tools

root=Path(__file__).resolve().parents[1]
run=root/'ada_run/biome_inheritance'
target=root.parent/'ada_encyclopedia/public/biome-primitives'
assets=target/'inheritance'
assert target.parent.parent.name=='ada_encyclopedia'
record=json.loads((run/'capture.json').read_text(encoding='utf-8'))
probe=json.loads((run/'probe.json').read_text(encoding='utf-8'))
assert probe['failures']==0
banner_record=json.loads((run/'banners/capture.json').read_text(encoding='utf-8'))
banner_checks=json.loads((run/'banners/verification.json').read_text(encoding='utf-8'))
assert banner_checks['failures']==0
html=(root/'commons/artifacts/biome_inheritance/web/inheritance.html').read_text(encoding='utf-8')
evolution=json.loads((root/'commons/artifacts/biome_inheritance/evolution-review.json').read_text(encoding='utf-8'))
evolution_checks=json.loads((run/'evolution/verification.json').read_text(encoding='utf-8'))
assert evolution_checks['failures']==0
cards=[]
for row in evolution['stages']:
    hall=html_tools.escape(row['map'],quote=True)
    cards.append(f'<article class="map-card" id="{hall}"><small>{hall}</small>'
                 f'<h3>{html_tools.escape(row["title"])}</h3>'
                 f'<a href="inheritance/evolution/{hall}.png"><img src="inheritance/evolution/{hall}.png" alt="Godot biome at {hall}"></a>'
                 f'<p>{html_tools.escape(row["text"])}</p></article>')
html=html.replace('{{EVOLUTION_CARDS}}','\n'.join(cards))
for key,value in {'NARROW':record['narrow']['standing_cover'],'WIDE':record['wide']['standing_cover'],
                  'CANDIDATES':record['wide']['candidate_cover'],'GENERATION':record['wide']['habitat_generation'],
                  'BANNER_LOW':banner_record['lowered']['standing_cover'],
                  'BANNER_HIGH':banner_record['raised']['standing_cover']}.items():
    html=html.replace('{{'+key+'}}',str(value))
assets.mkdir(parents=True,exist_ok=True)
(target/'inheritance.html').write_text(html,encoding='utf-8')
for name in ['earlier.png','first_cover.png','later_narrow.png','later_wide.png','inside.png','inheritance-cycle.mp4','verification.json']:
    shutil.copyfile(run/name,assets/name)
shutil.copyfile(run/'capture.json',assets/'record.json')
(assets/'banners').mkdir(exist_ok=True)
for name in ['doors.png','banners.png','inside.png','patterns.png','banner-cycle.mp4','verification.json']:
    shutil.copyfile(run/'banners'/name,assets/'banners'/name)
shutil.copyfile(run/'banners/capture.json',assets/'banners/record.json')
(assets/'evolution').mkdir(exist_ok=True)
for row in evolution['stages']:
    shutil.copyfile(run/'evolution'/(row['map']+'.png'),assets/'evolution'/(row['map']+'.png'))
shutil.copyfile(run/'evolution/capture.json',assets/'evolution/record.json')
shutil.copyfile(run/'evolution/verification.json',assets/'evolution/verification.json')
shutil.copyfile(root/'commons/artifacts/biome_primitives/web/index.html',target/'index.html')
print('http://127.0.0.1:3003/biome-primitives/inheritance.html')
