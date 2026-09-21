from pathlib import Path
import hashlib, json, shutil
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/research/possible-bodies'
REC=ROOT/'doc/space/sine-flow-hall-2026-09-12'
MAP='WaveFunctions_Sine_Space'
report=json.loads((ROOT/'ada_run/sine-flow-hall/report.json').read_text(encoding='utf-8'))
corridor=json.loads((ROOT/'ada_run/waves_chance_noise/WaveFunctions_Sine_Space/probe_sine_space_live.json').read_text(encoding='utf-8'))
assert not report['failures'] and not corridor['failures']
assert report['checks']>=41 and corridor['checks']>=64
final=(ROOT/f'commons/maps/{MAP}/final.md').read_text(encoding='utf-8')
roles=json.loads((ROOT/'commons/data/artifact_roles.json').read_text(encoding='utf-8'))
assert roles['order'][MAP]['primary']==['sine_flow_tray','sine_wall_corridor']
assert all(f'<!-- @{t} -->' in final for t in roles['order'][MAP]['primary'])
for src,dst in [('tray-contact.png','sine-contact-tray.png'),('forecourt-and-corridor.png','sine-contact-hall.png'),('report.json','sine-contact-check.json')]:
    shutil.copyfile(ROOT/'ada_run/sine-flow-hall'/src,OUT/dst)
shutil.copyfile(ROOT/'ada_run/waves_chance_noise/WaveFunctions_Sine_Space/probe_sine_space_live.json',OUT/'sine-contact-corridor-check.json')
(OUT/'sine-contact-final.md').write_text(final,encoding='utf-8')
text=f'''# What a wave can hold

[Two primary artifacts and their book passages](/necklace/thread?map=WaveFunctions_Sine_Space&role=primary) · [Landscape research thread](landscape-thread.html) · [Article](landscape-article.html)

The landscape experiment now has a place in Sine Space. A six-row forecourt holds a physical sine tray. Beyond it, the original corridor, bridge and basin keep their arrangement. The room's book follows two encounters: a stationary surface that redirects moving spheres, then moving walls that suggest a passage without colliding with the visitor.

![The sine contact tray with transparent side guards and a low tilted display](sine-contact-tray.png)

**Try the tray.** Choose a hollow and predict whether a sphere will leave. Press RELEASE, follow one body, then read the three counts at twelve seconds. Change SIZE alone and repeat. RESET before trying RELIEF. RULE reveals the sampled sine and the construction of collision geometry after you have watched it work.

| Control | What it changes |
|---|---|
| RELEASE | A new batch of 32 spheres; replaces the old batch. |
| RELIEF | Peak-to-trough height: 0.12 / 0.30 / 0.55 m. Clears the batch. |
| SIZE | Radius: 45 / 75 / 105 mm. Mass remains 0.1 kg. Clears the batch. |
| RESET | Restores 0.30 m relief, 75 mm radius, an empty tray and hidden RULE. |
| RULE | Reveals the sine expression, sampling and collision assumptions. |

Every trial runs to a twelve-second counter. Tilt stays twenty degrees. Each sphere is counted as outlet, still in, or other exit. Departed spheres move to the collection display and stop participating in collisions. The others freeze at the deadline. STILL IN does not decide their permanent fate. This is a new one-tray encounter; the article's recorded four-tray apparatus and raw series remain unchanged.

![Forecourt, side controls and the preserved red corridor beyond](sine-contact-hall.png)

**Continue to the walls.** The existing seven-metre corridor is still primary. AMP, PHASE, FREEZE and RESET retain their meanings. At half-turn offset the walls bend together with a two-metre local-X gap. Walk through a visible crest: these wall meshes have no collision, while their thin floor slab supports the visitor. Bring the contact tray's question with you: what does this particular surface let a particular body do?

| Book order | Artifact | Placement |
|---|---|---|
| 1 | `sine_flow_tray` — primary | Forecourt (3,4), rotated 180°, side console towards the central approach. |
| 2 | `sine_wall_corridor` — primary | (6,10), rotated 90°, with its west and east approaches preserved. |
| Further exploration | `sine_wall_explanation`, `sine_space` | Case in the west nook; older floor-wave field in the basin. |

The `dark_sphere` also remains as a reference in the basin. The hall is 14 by 36 map cells. All original placements shift six rows together, so the relationship between corridor, bridge and basin stays intact. The new forecourt and the corridor approach exclude generated statues; controls are at standing hand height. The transparent guards retain collision while letting visitors inspect contact from the side.

**Verified on desktop.** {report['checks']} contact-tray checks and {corridor['checks']} corridor checks pass with zero failures. These include actual museum placement, capsule route casts, button clicks through the project's desktop interaction rig, radius/relief separation, fixed terrain samples during size comparisons, three complete batches and deadline accounting. The corridor rig also walks its passage and toggles FREEZE with mouse input. The captures above come from the running museum. Synthetic input through that rig is distinct from the museum walker's controls and from tracked hands. Headset reach, readability and comfort remain for the later visit.

[Contact-tray evidence](sine-contact-check.json) · [Corridor evidence](sine-contact-corridor-check.json) · [Room text](sine-contact-final.md)

The next hall on the current effective museum route is [**Effect Sound**](effect-sound.html). There the relation between oscillations becomes audible. We can carry forward the same question: what can a new combination do that its parts did not do alone?

<details><summary>Read the updated book passage</summary>

BOOK_PASSAGE

</details>
'''
(OUT/'sine-contact.md').write_text(text.replace('BOOK_PASSAGE',final),encoding='utf-8')
body=markdown.markdown(text.replace('BOOK_PASSAGE',markdown.markdown(final,extensions=['fenced_code'])),extensions=['tables','fenced_code'])
style=(OUT/'landscape-thread.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+=' details{margin:35px 0;padding:20px;border:1px solid #c2bbaa}summary{cursor:pointer;font-weight:600}details h1{font-size:32px} table{overflow-wrap:anywhere}'
(OUT/'sine-contact.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What a wave can hold · Ada Research</title><style>'+style+'</style></head><body><main>'+body+'</main></body></html>\n',encoding='utf-8')

update='[The sine encounter is now in the museum](sine-contact.html): a dedicated forecourt, contact tray and two primary book sections. The four-tray article apparatus remains the recorded research setup.'
for filename in ['landscape-thread.md','landscape-thread.html']:
    p=OUT/filename; s=p.read_text(encoding='utf-8')
    if 'sine-contact.html' not in s:
        if filename.endswith('.md'):
            title,rest=s.split('\n',1); s=title+'\n\n'+update+'\n'+rest
        else: s=s.replace('</h1>','</h1>'+markdown.markdown(update),1)
    if filename.endswith('.md'):
        s=s.replace('**Next actionable step:** fit a sine-only physical tray beside the existing Sine Space encounter, inspect the real approach and controls, and test a sphere crossing before adding it to the book\'s primary story. Develop the full-size walkable receiver as a separate comparison; do not scale a tabletop physics result into a claim about player access.', '**Next actionable step:** continue the halls from the completed sine contact encounter; keep headset review pending. A full-size walking or concealment receiver needs its own body, task and observation protocol.')
    else:
        s=s.replace('<strong>Next actionable step:</strong> fit a sine-only physical tray beside the existing Sine Space encounter, inspect the real approach and controls, and test a sphere crossing before adding it to the book\'s primary story. Develop the full-size walkable receiver as a separate comparison; do not scale a tabletop physics result into a claim about player access.', '<strong>Next actionable step:</strong> continue the halls from the completed sine contact encounter; keep headset review pending. A full-size walking or concealment receiver needs its own body, task and observation protocol.')
    p.write_text(s,encoding='utf-8')
p=ROOT/'tools/build_possible_bodies_guide.py'; s=p.read_text(encoding='utf-8')
if 'href="sine-contact.html"' not in s:
    s=s.replace('<div class="next">','<div class="next"><p><a href="sine-contact.html"><b>What a wave can hold.</b></a> Sine Space now has a physical contact tray, a clear forecourt and two book encounters: tray, then corridor.</p>')
    p.write_text(s,encoding='utf-8')
files=['sine-contact.html','sine-contact.md','sine-contact-final.md','sine-contact-check.json','sine-contact-corridor-check.json','sine-contact-tray.png','sine-contact-hall.png','landscape-thread.html','landscape-thread.md','index.html','working-guide.md','audit.json']
REC.mkdir(parents=True,exist_ok=True)
(REC/'publication-manifest.json').write_text(json.dumps(files,indent=2)+'\n',encoding='utf-8')
sources=[f'commons/maps/{MAP}/{f}' for f in ['map_data.json','final.md','tutorial.md','technical.md','critical.md']]+['commons/artifacts/sine_flow_tray/sine_flow_tray.gd','commons/artifacts/sine_flow_tray/sine_flow_tray.tscn','commons/artifacts/registry/sine_flow_tray.json','commons/testing/probe_sine_flow_hall.gd','commons/testing/probe_wcn_sine_space.gd']
(REC/'source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'contact_checks':report['checks'],'corridor_checks':corridor['checks'],'primary_order':roles['order'][MAP]['primary'],'publication_files':len(files)}))
