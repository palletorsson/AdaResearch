"""Visual companion to the source survey. No museum/content mutations."""
from pathlib import Path
from collections import defaultdict
import hashlib
import html
import json
import shutil

from PIL import Image
from shader_pattern_principles import entries as principle_entries

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-10-shader-pattern-survey'
PUBLIC = ROOT.parent / 'ada_encyclopedia/public'
E = html.escape


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def main():
    inventory = read(OUT / 'inventory.json')['reviewed']
    maps = defaultdict(list)
    scenes = {}
    for row in inventory:
        for token, definitions in row['artifacts'].items():
            maps[token].append(row['map'])
            if definitions:
                scenes[token] = definitions[0]['scene']
    registry = {}
    for f in (ROOT / 'commons/artifacts/registry').glob('*.json'):
        registry.update(read(f).get('artifacts', {}))
    entries = []

    def add(token, title, section, fit, caption, caution='', image=None, source_maps=None, scene=None, config=None):
        fresh = image is None
        original = OUT / f'gallery-images/{token}.png' if fresh else PUBLIC / image
        assert original.is_file(), original
        if not fresh:
            shutil.copy2(original, OUT / f'gallery-images/{token}-archive.png')
        raw = original if fresh else OUT / f'gallery-images/{token}-archive.png'
        thumbnail = OUT / f'gallery-images/{token}.webp'
        with Image.open(raw) as im:
            size = im.size
            im.thumbnail((1000, 750))
            im.convert('RGB').save(thumbnail, 'WEBP', quality=88)
        scene = scene or scenes.get(token) or registry.get(token, {}).get('scene', '')
        if scene:
            source = ROOT / scene.removeprefix('res://')
            assert source.is_file(), source
            target = OUT / 'sources' / source.relative_to(ROOT)
            if target.suffix == '.gdshader':
                target = target.with_suffix('.gdshader.txt')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            source_link = target.relative_to(OUT).as_posix()
        else:
            source_link = ''
        entries.append(dict(id=token, title=title, section=section, fit=fit, caption=caption,
                            caution=caution, maps=source_maps if source_maps is not None else maps[token],
                            scene=scene, source_link=source_link, config=config,
                            image=thumbnail.relative_to(OUT).as_posix(), original=raw.relative_to(OUT).as_posix(),
                            provenance='Fresh Godot specimen · 10 October 2026' if fresh else 'Existing Godot capture · reused for comparison',
                            fresh=fresh, original_source=str(original), dimensions=size,
                            sha256=hashlib.sha256(raw.read_bytes()).hexdigest()))

    shader_data = [
        ('01_shaping', 'Shaping functions', 'Shaders · current hall', 'Five panels turn numerical functions into boundaries and curves.', 'Some outputs occupy only part of the display. Check the receiver UVs before using this as the first teaching example.'),
        ('02_colors', 'Colour by function', 'Shaders · reference', 'Gradients, hue and mixtures on four panels. A return to the earlier Colour sequence.'),
        ('03_shapes', 'A shape from distance', 'Shaders · borrow first', 'Circle, rectangle, combined shapes and polygon masks: the familiar form becomes a surface calculation.', 'The current display visibly clips several masks; the circle is not visible in this default view. The scene uses BoxMesh receivers. This needs a UV/display check, not a claim that the shapes already read clearly.'),
        ('04_matrices', 'Transform the coordinates', 'Shaders · borrow first', 'Translation, rotation, scale and their combination applied to sampling coordinates.', 'The shapes are very small or outside the visible panel in this default capture. The teaching idea needs a clearer displayed domain.'),
        ('05_patterns', 'One tile, many relations', 'Tiling ↔ Shaders', 'Circles, curved Truchet lines, offsets and brick arrangements. These are the default classic modes; the artifact has other modes.'),
        ('06_random', 'Random at an address', 'Shaders · reference', 'A coordinate hash, a random grid and changing static. Recall Randomness through a surface.'),
        ('07_noise', 'Neighbouring values', 'Shaders · reference', 'Four noise displays offer fields with different local relationships. Use one controlled comparison.'),
        ('08_cellularnoise', 'Nearest points', 'Shaders · optional', 'Coloured cells, distance to a point and cracks between cells. A possible move from regular tiles to irregular regions.'),
        ('09_fbm', 'Layers of a field', 'Shaders · current hall', 'Layered noise, turbulence and terrain-like images. The earlier field returns as a material input.'),
        ('10_reactiondiffusion', 'A missing previous state', 'Shaders · repair needed', 'The present green panel and an analytic frost image. A useful question about what a surface remembers.', 'The reaction-diffusion panel is not supplied with a previous-state texture. This capture is not evidence of simulated growth; the frost image is not a DLA simulation.'),
        ('11_queerrubber', 'Material changes the body we see', 'Shaders · current hall', 'Rims, surface response and contrasting materials on familiar primitive bodies.'),
        ('12_pinkextravaganza', 'A material composition', 'Shaders · current hall', 'The sphere, torus, capsule and floor become a deliberately excessive arrangement of familiar effects.'),
    ]
    for suffix, title, fit, caption, *caution in shader_data:
        add('shader_' + suffix, title, 'shaders', fit, caption, caution[0] if caution else '')

    add('tiles_explained', 'UV → repeat → turn → pattern', 'patterns', 'Shaders · borrow first', 'Five existing stages make the coordinate operation visible before it becomes an image.')
    add('gridscheckers', 'Stripes and checks on bodies', 'patterns', 'Tiling ↔ Shaders', 'The same small family of rules wraps cubes and spheres. Compare the receiver with the rule on its surface.')
    add('truchettiles', 'A diagonal can organise a floor', 'patterns', 'Tiling · small addition', 'Diagonal splits, small marks and zigzags produce different fields. A good source for the 4×4 orientation comparison.', 'The file called quarterarcs makes a diagonal split. The curved Truchet example is in the shader pattern rack above.')
    add('fabrics', 'Colour, bump and displacement', 'patterns', 'Shaders · borrow first', 'The older Fabrics collection puts animated patterns, normal response and displacement on floors and primitive bodies.', 'These are material studies. They do not simulate interlaced yarn.')
    add('animalpatterns', 'A skin made from rules', 'patterns', 'Shaders · composition', 'Spots, stripes and other patterned surfaces on familiar receivers. Change palette and mask separately.', 'Designed resemblances, not models of biological pattern formation.')
    add('glassdivider', 'A pattern seen through glass', 'patterns', 'Shaders · optional', 'Transparent dividers stand across a patterned surface. Potential for comparing the surface with its appearance through another material.', 'Screen- and depth-dependent effects need checking in the actual museum and headset.')
    add('waves', 'Four water surfaces', 'patterns', 'Shaders · reference', 'Animated water materials share a simple floor arrangement. Compare with the earlier wave work before adding another lesson.')
    add('Shader_Gallery', 'Six skins, one sphere', 'patterns', 'Shaders · comparison', 'Leather, velvet, plastic, green emission, fungus-like marks and rust sit on the same underlying form.')
    add('color_pattern_mate_texture_for_3d', 'A family of mirrored marks', 'patterns', 'Tiling · optional', 'A grid of procedural line motifs. Useful as a catalogue of source marks and mirroring choices.', 'This clearer archived view is used instead of the sparse early frame from the fresh render. Animation state differs.', image='artifact-gallery/captures/color_pattern_mate_texture_for_3d/top.png')

    add('pattern_maker_station', 'Make a source; see it repeat', 'machines', 'Tiling · already represented', 'A small editable source and a large receiving surface. A familiar operation with another physical arrangement.')
    machine_notes = {
        'thread_loom': ('Follow the Thread', 'Tiling · existing loom', 'A shuttle, warp threads and a continuous weft. This is the explicit crossing-by-crossing connection to handwork.', 'The geometry models crossings; it does not simulate yarn tension or friction.'),
        'pm_loom': ('Jacquard-inspired image loom', 'Tiling · alternative carrier', 'A loom-shaped image machine turns a motif into wallpaper-patterned output.', 'It produces patterned images. Its mechanism is different from the thread loom above.'),
        'pm_mill': ('Kaleidoscope mill', 'Tiling · alternative carrier', 'A machine frame places a repeating image beside the controls that produce it.', 'Choose for the encounter it offers; a new machine shape does not by itself introduce a new algorithm.'),
        'pm_press': ('Tile-stamp press', 'Tiling · alternative carrier', 'A press, control panel and patterned sheet suggest a make-and-print encounter.'),
        'pm_hologram': ('Holographic printer', 'Tiling · alternative carrier', 'A floating motif workspace and the resulting sheet make source and output spatially distinct.'),
        'pm_studio': ('Pattern studio', 'Tiling · alternative carrier', 'A compact paint/control surface overlooks a large carpet: a workspace for the same source-to-field relation.'),
        'pm_tile': ('Pattern tile plate', 'Tiling · compact interface', 'A small wall plate controls a repeated floor image. A simpler alternative to a large machine.'),
        'pm_tunnel': ('Pattern tunnel', 'Tiling · architectural return', 'A control console faces a tiled enclosure. The receiving surface becomes a place you can enter.'),
    }
    for token, (title, fit, caption, *caution) in machine_notes.items():
        spec = read(PUBLIC / f'pattern-machines-gallery/{token}.json')
        add(token, title, 'machines', fit, caption, caution[0] if caution else '',
            image=f'pattern-machines-gallery/{token}.png', scene=spec['scene'], config=spec.get('dna'),
            source_maps=['Symmetry_Seventeen'] if token == 'thread_loom' else ['Adjacent pattern-machine collection'])
    add('pattern_compositor', 'Field, border, medallion', 'machines', 'Tiling · optional composition', 'Different pattern rules occupy different zones. A useful way to distinguish composing an object from repeating a tile.', image='artifact-gallery/captures/pattern_compositor/top.png', source_maps=['Gallery_Shaders'])
    add('array_carpet', 'The source covers a floor', 'machines', 'Tiling · familiar receiver', 'A carpet makes the return from an editable small source to a large repeated field visible.', image='artifact-gallery/captures/array_carpet/front.png')
    add('wfc_tile_mosaic', 'Neighbours constrain the result', 'later', 'Later · constraints', 'A mosaic gives neighbouring tiles rules about what may touch. This is a different lesson from simple copying.', image='artifact-gallery/captures/wfc_tile_mosaic/front.png')
    add('basin_water', 'A field under glass', 'patterns', 'Shaders · existing comparison', 'A water surface from the FBM hall. The appearance, glass support and collision should be discussed separately.', image='artifact-gallery/captures/basin_water/front.png')

    add('shader_arch_gallery', 'A patchwork tunnel of cubes', 'spaces', 'Tiling · optional destination', 'Each cube carries a different combination of domain, palette and pattern settings. A spatial composition after a controlled comparison.')
    for token, title, caption, caution in [
        ('Wallpaper_Groups_Gallery', 'Wallpaper bays', 'Named bays and decorative floors organised as a spatial catalogue.', 'The current plan does not enumerate all seventeen group names; labels do not prove the symmetry of a floor preset.'),
        ('Tile_Shapes_Gallery', 'Different floor arrangements', 'Fifteen rooms, including an entrance, collect diagonal, radial, hexagonal and other named floor arrangements.', 'These are room/floor-plan previews, not fifteen independently validated teaching examples.'),
        ('Pixel_Art_Gallery', 'Small marks, large rooms', 'Pixel, neon, glitch and Memphis presets appear across an eight-room floor plan.', 'Useful atmosphere and display references; not a missing compulsory chapter.'),
    ]:
        add(token, title, 'spaces', 'Tiling · spatial reference', caption, caution, source_maps=[token],
            scene='res://commons/artifacts/floor_plan_space/floor_plan_space.tscn', config={'plan_path':f'res://commons/maps/{token}/floor_plan.json'})

    add('WFCSculptureGenerator', 'A generated sculptural cluster', 'later', 'Later · generative construction', 'A large sphere meets a cluster of smaller bodies. Another visual direction from Pattern Generation Two.', 'A still image does not establish how constraint propagation works here; inspect the generator before teaching it.')
    add('WFC3DGenerator', 'A field of constructed cells', 'later', 'Later · constraints', 'A dense arrangement of coloured solids from Pattern Generation Three. Better considered after the learner can distinguish copying from neighbour rules.')
    add('self_organizing_patterns', 'Local rules, collective pattern', 'later', 'Later · emergent systems', 'This is the self-organising artifact actually placed in the hall labelled DLA.', 'The map title alone does not make this a verified diffusion-limited aggregation example.')
    add('markov_chains', 'A state and its possible next states', 'later', 'Later · probability and narrative', 'Connected states and changing bodies from the narrative-generation hall. A different subject from a surface shader.')
    add('env_one', 'A generated environment', 'later', 'Reference · naming mismatch', 'This same environment generator is placed in both the Typography and Wang maps.', 'Neither map currently demonstrates what its title promises. Do not import those titles as lesson claims.')
    add('degrading_shader_demo', 'A surface that could keep a touch', 'later', 'Shaders · repair candidate', 'The existing sphere demo gives a possible receiver for retained marks.', 'The scene does not attach its degradation manager. This image shows the material, not working touch memory.')

    additions = principle_entries()
    # Keep the teaching comparison together; the washed-out installation follows it.
    additions.sort(key=lambda row: (row['section'] == 'principles' and row['token'] == 'tartan_demo'))
    for row in additions:
        add(**row)
        entry = entries[-1]
        entry['capture_kind'] = 'Existing artifact scene'
        token = entry['id']
        if entry['scene'].endswith('.gdshader'):
            entry['capture_kind'] = 'Existing shader on a plain review quad'
            entry['provenance'] = 'Fresh Godot shader view · review receiver · 10 October 2026'
        elif token.startswith(('atlas', 'mm_')):
            entry['capture_kind'] = 'One existing gallery plate isolated for inspection'
            entry['provenance'] = 'Fresh Godot capture · existing plate isolated · 10 October 2026'
            folder = 'mamma_monster_gallery' if token.startswith('mm_') else 'pattern_atlas_gallery'
            source = ROOT / f'commons/artifacts/{folder}/shaders/{token}.gdshader'
            target = OUT / 'sources' / source.relative_to(ROOT).with_suffix('.gdshader.txt')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            entry['shader_source_link'] = target.relative_to(OUT).as_posix()

    sections = [
        ('shaders', '01', 'Shader studies', 'The twelve existing study artifacts. Six already belong to the current shader sequence.'),
        ('patterns', '02', 'Older pattern experiments', 'The seven numbered Pattern Generation rooms hold a useful reserve of surface and coordinate studies.'),
        ('machines', '03', 'Making the source', 'Compare the actual thread loom with machines that generate images, then choose the most useful interface.'),
        ('spaces', '04', 'Pattern becomes a room', 'Architectural alternatives. The three floor-plan previews use their own map JSON, not a generic room.'),
        ('later', '05', 'Other subjects and repair candidates', 'Potential material for later sequences, plus examples whose current implementation needs attention.'),
        ('principles', '06', 'Tartan, twill and the small rule', 'Crossed bands, a counted diagonal and a stored 4×4 motif. Compare the source pattern with the rule that arranges it.'),
        ('atlas', '07', 'Pattern Atlas · nineteen studies', 'Individual plates from the existing atlas, with their maker labels retained. Captions describe the implemented rule. These shader interpretations do not reconstruct a craft’s material process or establish its history.'),
        ('mamma', '08', 'Mamma Mönster · six studies', 'The project’s existing studies around Kristina Torsson, Mah-Jong and Mothers Dream. A personal lineage of motifs, repetitions and transformations, shown one plate at a time.'),
    ]
    section_order = {s[0]: i for i, s in enumerate(sections)}
    entries.sort(key=lambda e: section_order[e['section']])
    style = '''*{box-sizing:border-box}html{scroll-padding-top:90px}body{margin:0;background:#eeeae3;color:#202326;font:16px/1.55 system-ui,sans-serif}a{color:inherit;text-underline-offset:4px}main{max-width:1400px;margin:auto;padding:40px 28px 80px}.eyebrow{text-transform:uppercase;letter-spacing:.15em;font-size:12px;font-weight:750;color:#665663}h1{font:clamp(42px,7vw,88px)/1.02 Georgia,serif;max-width:980px;margin:20px 0}h2{font:36px/1.1 Georgia,serif;margin:0}h3{font:26px/1.15 Georgia,serif;margin:8px 0 10px}.intro{max-width:740px;font-size:19px}nav{display:flex;flex-wrap:wrap;gap:10px 20px;margin:24px 0}nav a{font-size:14px}.jump{position:sticky;top:0;z-index:5;background:#eeeae3f5;border-top:1px solid #c5bfb9;border-bottom:1px solid #c5bfb9;padding:12px 0;}section{padding-top:50px}.section-head{display:flex;gap:20px;align-items:baseline}.section-head span{color:#ab526e;font-size:16px}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:28px 24px;margin-top:24px}article{background:#fffdf8;border:1px solid #d5d0c9;min-width:0;scroll-margin-top:80px}article .image{display:block;background:#262c34;overflow:hidden}article img{width:100%;aspect-ratio:16/9;object-fit:contain;display:block;}.copy{padding:20px 24px 24px}.meta{display:flex;gap:12px;align-items:center;font-size:12px}.num{font-weight:750;font-size:15px}.fit{background:#f7e5eb;color:#793b52;padding:4px 8px;border-radius:3px;font-size:12px}.maps{font-size:12px;color:#64646a;overflow-wrap:anywhere}.copy p{margin:10px 0}.provenance{font-size:11px;color:#767078}.caution{border-left:3px solid #b97941;padding-left:12px;color:#68482e;font-size:14px}.open{display:inline-block;font-size:13px;font-weight:700;margin-top:10px}.note{font-size:14px;color:#64646a;max-width:850px}details{border-top:1px solid #ddd;padding-top:16px;margin-top:20px}summary{cursor:pointer;font-weight:600}.hero{width:100%;max-height:72vh;object-fit:contain;background:#262c34;display:block}.detail{max-width:1400px}.detail-text{max-width:850px}.detail h1{font-size:clamp(36px,5vw,62px)}code{font-size:12px;overflow-wrap:anywhere}.pager{justify-content:space-between}footer{margin-top:70px;border-top:1px solid #bbb;padding-top:20px;font-size:13px}.missing{background:#e4dfd7;padding:24px;margin-top:36px} @media(max-width:750px){main{padding:25px 16px 50px}.grid{grid-template-columns:1fr}.copy{padding:18px}.jump{gap:7px 13px}h2{font-size:29px}.section-head{gap:12px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}article img{transition:none}}'''

    def document(title, content):
        compact = '.overview .grid{grid-template-columns:repeat(4,minmax(0,1fr));gap:16px}.overview .copy{padding:14px}.overview h3{font-size:21px}.overview .copy>p:not(.maps){display:none}.overview .maps{font-size:11px}.overview .meta{align-items:flex-start}.overview h1{font-size:60px}.overview header .note{font-size:13px}.overview .open{margin-top:0}@media(max-width:1100px){.overview .grid{grid-template-columns:repeat(3,minmax(0,1fr))}}@media(max-width:750px){.overview .grid{grid-template-columns:repeat(2,minmax(0,1fr))}.overview h1{font-size:42px}.overview .fit{font-size:10px}.overview h3{font-size:20px}}@media(max-width:430px){.overview .grid{grid-template-columns:1fr}}'
        return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{E(title)} · Endless Museum</title><style>{style}{compact}</style></head><body>{content}</body></html>'

    fresh_count = sum(x['fresh'] for x in entries)
    header = f'''<main><header><p class="eyebrow">Endless Museum · artifact shelf · 10 October 2026</p><h1>See the rule.<br>Choose the encounter.</h1><p class="intro">{len(entries)} visual cards from the shader and pattern survey, with related making machines. Open an image for a large view and use <b>Previous / Next</b> to compare.</p><p class="note">{fresh_count} fresh Godot specimen views and {len(entries)-fresh_count} existing captures. Fresh views stage existing scenes or isolate their plates; two shader-library studies use plain review quads. These views do not show current hall placement. Room previews use the named map’s floor plan. No headset interaction test was performed.</p><nav><a href="index.html">Read the source survey</a><a href="#coverage">Coverage and limits</a><a href="gallery-manifest.json">Image and source index</a></nav><p>You can refer to the card numbers when choosing what to keep, borrow or develop.</p></header><nav class="jump" aria-label="Gallery sections">'''
    header = header.replace('<nav><a href="index.html">', '<nav><a href="gallery-principles.html">New: tartan and pattern rules</a><a href="gallery-atlas.html">Pattern Atlas</a><a href="gallery-mamma.html">Mamma Mönster</a><a href="index.html">', 1)
    header = header.replace('</header>', '<p><a href="../2026-10-10-jacquard-cards-and-layers/index.html"><b>New working artifact: punch-card loom and 3D thread layers →</b></a></p></header>', 1)
    header += ''.join(f'<a href="#{key}">{no} {E(title)}</a>' for key, no, title, _ in sections) + '</nav>'
    cards = {}
    (OUT / 'gallery').mkdir(exist_ok=True)
    for i, entry in enumerate(entries):
        entry['number'] = i+1
        title, token = E(entry['title']), entry['id']
        badge = f'<div class="meta"><span class="num">{i+1:02d}</span><span class="fit">{E(entry["fit"])}</span></div>'
        map_text = ' · '.join(entry['maps'])
        warning = f'<p class="caution">{E(entry["caution"])}</p>' if entry['caution'] else ''
        detail_path = f'gallery/{token}.html'
        cards[token] = f'''<article id="{token}"><a class="image" href="{detail_path}" aria-label="Open {title}"><img loading="lazy" src="{entry['image']}" alt="Godot capture: {title}"></a><div class="copy">{badge}<h3>{title}</h3><p>{E(entry['caption'])}</p>{warning}<p class="maps">{E(map_text)}</p><p class="provenance">{E(entry['provenance'])}</p><a class="open" href="{detail_path}">Enlarge / compare →</a></div></article>'''
        prev = entries[(i-1) % len(entries)]
        nxt = entries[(i+1) % len(entries)]
        pager = f'<nav class="pager"><a href="{prev["id"]}.html">← Previous · {E(prev["title"])}</a><a href="../gallery.html#{token}">All {len(entries)} cards</a><a href="../gallery-{entry["section"]}.html#{token}">This category</a><a href="{nxt["id"]}.html">Next · {E(nxt["title"])} →</a></nav>'
        info = f'<p><code>{E(entry["scene"])}</code></p><p><a href="../{entry["source_link"]}">Source snapshot</a> · <a href="../{entry["original"]}">Full PNG</a></p>'
        if entry.get('shader_source_link'):
            info += f'<p><a href="../{entry["shader_source_link"]}">Read this plate’s shader</a></p>'
        if entry['config']:
            info += f'<p>Capture configuration: <code>{E(json.dumps(entry["config"]))}</code></p>'
        detail = f'<main class="detail">{pager}{badge}<h1>{title}</h1><a href="../{entry["original"]}"><img class="hero" src="../{entry["original"]}" alt="Godot capture: {title}"></a><div class="detail-text"><p class="intro">{E(entry["caption"])}</p>{warning}<p class="maps">Source: {E(map_text)}</p><p class="provenance">{E(entry["provenance"])}</p><details><summary>Artifact source and capture</summary>{info}<p>A still shows one visual state. It does not validate the controls or the tutorial.</p></details></div>{pager}</main>'
        (OUT/detail_path).write_text(document(entry['title'], detail), encoding='utf-8')

    body = header.replace('<main>', '<main class="overview">', 1)
    for key, no, title, subtitle in sections:
        section_cards = ''.join(cards[e['id']] for e in entries if e['section']==key)
        body += f'<section id="{key}"><div class="section-head"><span>{no}</span><h2>{E(title)}</h2></div><p>{E(subtitle)} <a href="gallery-{key}.html">Open large category view →</a></p><div class="grid">'
        body += section_cards + '</div></section>'
        category_nav = f'<nav><a href="gallery.html">All {len(entries)} cards</a>' + ''.join(f'<a href="gallery-{k}.html">{E(t)}</a>' for k,_,t,_ in sections) + '</nav>'
        category = f'<main>{category_nav}<p class="eyebrow">Endless Museum · visual artifact comparison</p><h1>{E(title)}</h1><p class="intro">{E(subtitle)}</p><p class="note">Open any image for its full view. Fresh captures use isolated review lighting; existing captures are labelled. These are visual comparisons, not headset tests.</p><div class="grid">{section_cards}</div>{category_nav}</main>'
        (OUT/f'gallery-{key}.html').write_text(document(title,category),encoding='utf-8')
    body += '''<section id="coverage"><h2>What this shelf includes</h2><p>The principal shader and pattern artifacts from the 31-map survey, plus the related loom, mill, press and compositor. Repeated placements and shared tile-puzzle variants are grouped rather than presented as new algorithms. Generic library racks, screens and dark spheres are omitted.</p><div class="missing"><b>Still needs a useful capture</b><p><code>koch_curve</code>, placed in the map named <code>PatternGeneration_Penrose_Tilings</code>, produced no visible curve in this capture. It is not represented by an invented Penrose image.</p><p><code>wall_pattern_gallery</code> needs the surrounding grid walls to build its overlays. A standalone blank preview would not show its work. The separate patchwork tunnel above is identified as its own artifact.</p></div><p class="note">The older tile puzzle and VR editor have mostly blank default previews. The added rule cards configure the existing tile editor with twill or houndstooth; they show usable source patterns without changing the museum placements. The image-machine collection is adjacent material, not a claim that every machine is installed in the reviewed halls.</p></section><footer><a href="index.html">Back to the 31-map survey</a> · <a href="gallery-manifest.json">Capture provenance</a><p>Gallery only. No map order, artifact logic, tutorial.md or final.md was changed.</p></footer></main>'''
    body = body.replace('Repeated placements and shared tile-puzzle variants are grouped rather than presented as new algorithms.', 'The expanded shelf also includes the tartan family, four configured tile-editor comparisons, nineteen Pattern Atlas plates and six Mamma Mönster plates. A shared scene is identified explicitly; a new arrangement is not presented as a new artifact implementation.')
    (OUT/'gallery.html').write_text(document('Shader and pattern artifact gallery',body),encoding='utf-8')
    manifest = dict(date='2026-10-10',count=len(entries),fresh_count=fresh_count,existing_count=len(entries)-fresh_count,
                    scope='Visual artifact selection. Fresh captures use isolated review lighting; interaction and headset behaviour untested.',
                    entries=entries, capture_jobs=['gallery-work/jobs.json','gallery-work/rooms.json','gallery-work/principles-jobs.json'],
                    logs=['gallery-work/render.log','gallery-work/rooms.log','gallery-work/principles-render.log','gallery-work/pink-render.log'])
    (OUT/'gallery-manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
    index=OUT/'index.html';text=index.read_text(encoding='utf-8')
    if 'href="gallery.html"' not in text:
        text=text.replace('<nav>','<nav><a href="gallery.html">Visual artifact gallery</a>',1)
        index.write_text(text,encoding='utf-8')
    print(json.dumps({k:manifest[k] for k in ['count','fresh_count','existing_count']}))


if __name__ == '__main__':
    main()
