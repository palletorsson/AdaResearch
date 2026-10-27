from pathlib import Path
import importlib.util

HERE = Path(__file__).resolve().parent
source = HERE.parent / '2026-10-21-batch-25/build_review_page.py'
spec = importlib.util.spec_from_file_location('review_gallery', source)
gallery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gallery)
gallery.HERE = HERE
gallery.OUT = gallery.ROOT / 'doc/book/iterations/2026-10-21-void-transfer-batch-26'
if __name__ == '__main__':
    gallery.main()
