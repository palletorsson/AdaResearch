"""One-off spatial revision; preserve the preceding museum evidence first."""
from pathlib import Path
import json, shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-08-sine-space-colour-rain'
MAP = ROOT / 'commons/maps/WaveFunctions_Sine_Space'

def main():
    current=json.loads((MAP/'map_data.json').read_text(encoding='utf8'))
    if current['map_info'].get('museum',{}).get('basin',{}).get('ramps'):
        print('This earlier layout is superseded by the authored walk-down pool in map_data.json.')
        return
    before = OUT / 'before'
    before.mkdir(parents=True, exist_ok=True)
    for source in [MAP/'map_data.json', MAP/'final.md', ROOT/'algorithms/color/colorballs/colorballs.gd']:
        target = before/source.name
        if not target.exists(): shutil.copy2(source, target)
    old = ROOT/'doc/book/iterations/2026-10-08-sine-space-walk-the-waves/after'
    for name in ['crossing.png','walls-above.png','report.json','source_manifest.json']:
        if not (before/name).exists(): shutil.copy2(old/name, before/name)
    data = json.loads((before/'map_data.json').read_text(encoding='utf8'))
    data['map_info']['dimensions']['width'] = 20
    data['map_info']['museum']['sculpture_clear_rects'] = [[1,1,18,38]]
    data['map_info']['description'] = 'A contact tray and visible wave corridor lead into a broad silver sine floor. Coloured balls fall, bounce and roll across the same relief the player crosses between solid side walls.'
    for name, rows in data['layers'].items():
        if name == 'structure':
            for z in range(40):
                if z in [0,39]: rows[z] = ['w']*8+['1']*3+['w']*9
                elif 17 <= z <= 34: rows[z] = ['w']*2+['0']*14+['w']*4
                else: rows[z] = ['w']+['1']*18+['w']
        else:
            data['layers'][name] = [['']*3+row+['']*3 for row in rows]
    data['layers']['interactables'][26][9] = 'sine_space#floor:walk#width:14#depth:18#pos_x:-0.5#pos_z:-0.5#fit:exact'
    data['layers']['interactables'][25][9] = 'colorballs#case:sine_rain'
    data['documentation']['layout'] = '20x40. Widened forecourt, north-south wave corridor, then a 14x18-metre sine floor between solid side walls. Coloured physics balls drop from overhead; no level bypass. Arrival and exit landings meet zero-height ends.'
    data['documentation']['key_elements'] = [
        'All five earlier artifacts retained and shifted 3m right: tray (6,4), explanation (6,9), corridor (9,12), wave floor centred (9,26), dark sphere (13,36).',
        'Colorballs (9,25), sine_rain case: 48 coloured spheres, radius 0.22m, continuous staggered recycling above the wave floor.',
        'Walls occupy x1 and x16-18 over z17-34, joined to the outer shell. Wave floor spans x2..16, z17..35.',
        'Spawn (11,2), exit (14,37). No lift or flat side bypass.',
        'Student surface bay remains hall-local (10.5,0,8.5).'
    ]
    (MAP/'map_data.json').write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf8')

if __name__ == '__main__': main()
