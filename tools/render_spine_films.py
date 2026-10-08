"""Render native Godot stages, test them and encode their actual viewport frames."""
from pathlib import Path
import argparse, hashlib, json, os, subprocess
import imageio_ffmpeg
import build_spine_films as build

ROOT=build.ROOT; OUT=build.OUT; RUN=build.RUN

def run(ids,film=False,headless=False):
    films=[f for f in build.manifests() if not ids or f['id'] in ids]
    assert films,ids
    RUN.mkdir(parents=True,exist_ok=True)
    label='-'.join(ids) if ids else 'all'
    if len(label)>120:label=label[:70]+'-'+hashlib.sha256(label.encode()).hexdigest()[:12]
    spec_path=RUN/(label+'-spec.json')
    prefix=lambda p:'res://'+p.relative_to(ROOT).as_posix()
    spec={'films':films,'output':prefix(OUT)+'/', 'frames':prefix(RUN/'frames')+'/', 'report':prefix(RUN/(label+'-report.json')),'film':film,'fps':12}
    build.write(spec_path,spec)
    sources=set(p.removeprefix('res://') for f in films for p in f.get('source_paths',[]) if isinstance(p,str))
    sources={p for p in sources if (ROOT/p).is_file() and not p.startswith('commons/artifacts/spine_films/')}
    hashes=lambda:{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sorted(sources)}
    before=hashes()
    log_path=RUN/(label+'-render.log')
    command=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--path',str(ROOT),'--xr-mode','off','--headless' if headless else '--no-window','--rendering-method','gl_compatibility','--script','res://tools/probes/spine_films_capture.gd','--',prefix(spec_path)]
    with log_path.open('w',encoding='utf-8') as log:
        result=subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=max(180,len(films)*160),creationflags=subprocess.CREATE_NO_WINDOW)
    text=log_path.read_text(encoding='utf-8',errors='replace')
    after=hashes()
    build.write(RUN/(label+'-protected.json'),{'unchanged':before==after,'before':before,'after':after})
    errors=[line for line in text.splitlines() if any(s in line for s in ('SCRIPT ERROR','Parse Error','FAIL ','FILM BEGIN','FILM END'))]
    print('\n'.join(errors).encode('ascii',errors='backslashreplace').decode('ascii'))
    print('Engine:',result.returncode,'Sources unchanged:',before==after)
    if result.returncode or 'SCRIPT ERROR' in text or before!=after:raise SystemExit(1)
    if film and not headless:
        encode(films)

def encode(films):
    ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
    for f in films:
        movie=OUT/f['id']/'film.mp4'
        frames=RUN/'frames'/f['id']
        subprocess.run([ffmpeg,'-y','-v','error','-framerate','12','-i',str(frames/'frame-%04d.png'),'-c:v','libx264','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(movie)],check=True,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
        decode=subprocess.run([ffmpeg,'-v','error','-i',str(movie),'-f','null','-'],capture_output=True,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
        assert decode.returncode==0,decode.stderr
        count=len(list(frames.glob('frame-*.png')))
        stage=build.read(OUT/f['id']/'report.json')
        assert stage['passed'] and count==round(stage['duration']*12),(f['id'],count)
        build.write(OUT/f['id']/'film-report.json',{'frames':count,'fps':12,'bytes':movie.stat().st_size,'decode_exit':decode.returncode})
        # These are only this renderer's intermediate frames, kept under its run directory.
        assert frames.resolve().is_relative_to((RUN/'frames').resolve())
        for frame in frames.glob('frame-*.png'):frame.unlink()
        print('Encoded',f['id'],movie.stat().st_size)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--only',nargs='+');p.add_argument('--film',action='store_true');p.add_argument('--headless',action='store_true');p.add_argument('--encode-existing',action='store_true')
    a=p.parse_args();run(a.only,a.film,a.headless)
    if a.encode_existing:encode([f for f in build.manifests() if not a.only or f["id"] in a.only])
