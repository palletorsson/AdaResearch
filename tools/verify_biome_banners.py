"""Encode actual Godot frames and compare the renderer with the headless probe."""
from pathlib import Path
import hashlib, json, subprocess
import imageio_ffmpeg

root=Path(__file__).resolve().parents[1]
out=root/'ada_run/biome_inheritance/banners'
capture=json.loads((out/'capture.json').read_text(encoding='utf-8'))
probe=json.loads((out/'probe.json').read_text(encoding='utf-8'))
legacy=json.loads((out.parent/'probe.json').read_text(encoding='utf-8'))
assert probe['failures']==legacy['failures']==0
assert len(list((out/'frames').glob('*.png')))==capture['frames']==240
for pose in ['lowered','raised']:
    assert probe[pose]['accepted_ids']==capture[pose]['accepted_ids']
    assert probe[pose]['excluded_cover']==capture[pose]['excluded_cover']
    assert probe[pose]['banners']==capture[pose]['banners']
movie=out/'banner-cycle.mp4'
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-loglevel','error','-y',
    '-framerate','12','-i',str(out/'frames/%04d.png'),'-frames:v','240','-c:v','libx264',
    '-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',str(movie)],
    check=True,creationflags=subprocess.CREATE_NO_WINDOW)
reader=imageio_ffmpeg.read_frames(str(movie)); media=next(reader); reader.close()
assert media['duration']==20 and media['size']==(1440,900)
paths=['commons/artifacts/biome_inheritance/biome_inheritance.gd',
       'commons/artifacts/biome_inheritance/rising_banners.gd',
       'commons/artifacts/biome_inheritance/banner_pattern.gdshader',
       'commons/biome_layers/inherited_form_clearance.gd',
       'commons/testing/probe_biome_banners.gd','commons/testing/capture_biome_banners.gd']
data={'date':'2026-09-19','godot_checks':probe['checks'],'regression_checks':legacy['checks'],'failures':0,
      'native_render_matches_headless_probe':True,
      'standing_lowered':capture['lowered']['standing_cover'],'standing_raised':capture['raised']['standing_cover'],
      'candidate_cover':capture['raised']['candidate_cover'],
      'movie':{'width':1440,'height':900,'fps':12,'seconds':20},
      'limits':['Rigid panels; no cloth physics','Geometric cover occupancy; no growth or shade',
                'Larger residents still use their own placement','No headset validation'],
      'source_hashes':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in paths}}
(out/'verification.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in data.items() if k!='source_hashes'},indent=2))
