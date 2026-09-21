"""Encode native frames and record the evidence for the opt-in bridge."""
from pathlib import Path
import hashlib, json, subprocess
import imageio_ffmpeg

root=Path(__file__).resolve().parents[1]
out=root/'ada_run/biome_inheritance'
assert len(list((out/'frames').glob('*.png')))==144
movie=out/'inheritance-cycle.mp4'
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-loglevel','error','-y',
    '-framerate','12','-i',str(out/'frames/%04d.png'),'-frames:v','144','-c:v','libx264',
    '-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(movie)],
    check=True,creationflags=subprocess.CREATE_NO_WINDOW)
reader=imageio_ffmpeg.read_frames(str(movie)); media=next(reader); reader.close()
assert media['duration']==12 and media['size']==(1280,800)
probe=json.loads((out/'probe.json').read_text(encoding='utf-8'))
capture=json.loads((out/'capture.json').read_text(encoding='utf-8'))
assert probe['failures']==0
for pose in ['narrow','wide']:
    assert probe[pose]['accepted_ids']==capture[pose]['accepted_ids']
    assert probe[pose]['excluded_cover']==capture[pose]['excluded_cover']
files=[root/'commons/artifacts/biome_inheritance/biome_inheritance.gd',
       root/'commons/biome_layers/inherited_form_clearance.gd',
       root/'commons/testing/probe_biome_inheritance.gd',
       root/'commons/testing/capture_biome_inheritance.gd']
data={'date':'2026-09-19','godot_checks':probe['checks'],'failures':0,
      'native_render_matches_headless_probe':True,'generation':capture['wide']['habitat_generation'],
      'candidate_cover':capture['wide']['candidate_cover'],
      'standing_narrow':capture['narrow']['standing_cover'],'standing_wide':capture['wide']['standing_cover'],
      'movie':{'width':1280,'height':800,'fps':12,'seconds':12},
      'scope':'Opt-in composition; production BiomeObject code and RSI baseline unchanged. Cover occupancy only.',
      'limitations':['No growth or shade feedback','Larger residents do not yet read inherited forms',
                     'No whole-spine persistence','No headset validation'],
      'source_hashes':{str(p.relative_to(root)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
(out/'verification.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(json.dumps(data,indent=2))
