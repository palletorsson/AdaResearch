from pathlib import Path
import importlib.util
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('gallery',HERE.parent/'2026-10-21-batch-25/build_review_page.py')
gallery=importlib.util.module_from_spec(spec);spec.loader.exec_module(gallery)
gallery.HERE=HERE;gallery.OUT=gallery.ROOT/'doc/book/iterations/2026-10-21-void-transfer-batch-28'
if __name__=='__main__':
    gallery.main()
    p=gallery.OUT/'index.html';s=p.read_text(encoding='utf8')
    s=s.replace('independent transfer review','placement-first transfer review').replace('Independent review','Placement review')
    s=s.replace('Native checks use desktop and synthetic tracked XR.','Only basic loading is checked in desktop and synthetic tracked XR. Artifact buttons and interaction mechanics are deliberately untested.')
    p.write_text(s,encoding='utf8')
