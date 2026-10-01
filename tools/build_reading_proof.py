"""Freeze the current reading manuscript and build an A4 print proof.

Run with Python plus markdown, bs4, Pillow, PyMuPDF, pypdf and reportlab.
Uses installed Chrome/Edge; no network or museum execution is required.
"""
from pathlib import Path
from datetime import datetime
from urllib.parse import unquote, urlsplit
import argparse
import hashlib
import html
import io
import json
import re
import subprocess
import sys
import time

import fitz
import markdown
from bs4 import BeautifulSoup
from PIL import Image
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parents[1]
sys.stdout.reconfigure(encoding="utf-8")
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--date", default="2026-09-30", help="Printed edition date (YYYY-MM-DD)")
args = parser.parse_args()
EDITION = datetime.strptime(args.date, "%Y-%m-%d").strftime("%d %B %Y").lstrip("0")
OUT = ROOT / "output/pdf"
WORK = ROOT / "tmp/pdfs" / ("reading-proof-" + args.date)
for p in [OUT, WORK / "images", WORK / "sources"]:
    p.mkdir(parents=True, exist_ok=True)
FINAL = OUT / f"AdaResearch_Reading_Proof_{args.date}.pdf"
CHROME = next((p for p in [Path("C:/Program Files/Google/Chrome/Application/chrome.exe"),
    Path("C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe")] if p.exists()), None)
if not CHROME:
    raise RuntimeError("Chrome or Edge is required for paged HTML printing")

sources = {}
transforms = []
local_links = set()
image_cache = {}
spacing_adjustments = {}


def read(path):
    path = path.resolve()
    raw = path.read_bytes()
    rel = path.relative_to(ROOT).as_posix()
    sources[rel] = hashlib.sha256(raw).hexdigest()
    dest = WORK / "sources" / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(raw)
    return raw.decode("utf-8-sig").replace("\r\n", "\n")


def load_document(path, key, label):
    text = read(path)
    if not text.strip():
        raise ValueError(f"Empty manuscript: {path}")
    if path.name == "afterword-qfep.md":
        text = re.split(r"\n---\s*\n\s*## Editorial development slots", text, maxsplit=1)[0]
        transforms.append("Afterword: internal Editorial development slots excluded; essay and footnotes retained.")
    # Remove authoring annotations, never reader-facing prose or code.
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S).strip()
    if text.startswith("# "):
        title, body = text[2:].split("\n", 1)
    else:
        title, body = label, text
    body = re.sub(r"^\s*\*(?:Preface · working draft[^\n]*|Afterword · Working draft[^\n]*|Part of the preface[^\n]*)\*\s*\n", "", body)
    return dict(path=path.resolve(), key=key, label=label, title=title.strip(), body=body.strip())


spine_path = ROOT / "commons/maps/curriculum_spine.json"
spine = sorted(json.loads(read(spine_path))["spine"]["sequences"], key=lambda s: s["order"])
front = [load_document(ROOT / "doc/book/preface.md", "FR00", "Preface"),
         load_document(ROOT / "doc/book/day-zero.md", "FR01", "Day Zero")]
back = [load_document(ROOT / "doc/book/afterword-qfep.md", "BK00", "Afterword")]
parts = []
chapters = []
for index, seq in enumerate(spine):
    raw = json.loads(read(ROOT / "commons/maps/sequences" / (seq["name"] + ".json")))
    data = raw["sequences"][seq["name"]]
    part = dict(key=f"PT{index:02d}", title=data.get("name", seq["name"]), order=index + 1, chapters=[])
    for hall in data["maps"]:
        doc = load_document(ROOT / "commons/maps" / hall / "final.md", f"CH{len(chapters):03d}", hall.replace("_", " "))
        doc["hall"] = hall
        chapters.append(doc)
        part["chapters"].append(doc)
    parts.append(part)
if len({d["hall"] for d in chapters}) != len(chapters):
    raise ValueError("A hall occurs more than once in the spine")
documents = front + chapters + back
doc_by_path = {d["path"]: d for d in documents}
print(f"Reading proof: {len(parts)} sequences, {len(chapters)} halls, {len(front) + len(back)} framing chapters", flush=True)


def resolve_local(target, origin):
    target = unquote(urlsplit(target).path)
    if target.startswith("/book-review/"):
        return (ROOT / target[len("/book-review/"):]).resolve()
    if target.startswith("/"):
        return (ROOT / target.lstrip("/")).resolve()
    return (origin.parent / target).resolve()


def print_image(target, origin):
    path = resolve_local(target, origin)
    if path in image_cache:
        return image_cache[path]
    raw = path.read_bytes()  # Missing figures fail the build.
    rel = path.relative_to(ROOT).as_posix()
    sources[rel] = hashlib.sha256(raw).hexdigest()
    with Image.open(path) as im:
        im.load()
        if "A" in im.getbands():
            bg = Image.new("RGB", im.size, "white")
            bg.paste(im.convert("RGBA"), mask=im.convert("RGBA").getchannel("A"))
            im = bg
        im = im.convert("RGB")
        im.thumbnail((2400, 2400), Image.Resampling.LANCZOS)
        dest = WORK / "images" / (hashlib.sha256(raw).hexdigest()[:16] + ".jpg")
        im.save(dest, quality=94, subsampling=0, optimize=True)
    image_cache[path] = dest.as_uri()
    return image_cache[path]


def inline(text):
    # A numbered sequence label is inline text, not a Markdown ordered list.
    text = re.sub(r"^(\d+)\. ", r"\1\\. ", text)
    return re.sub(r"^<p>|</p>$", "", markdown.markdown(text).strip())


def plain(text):
    return BeautifulSoup(inline(text), "html.parser").get_text()


def document_html(doc):
    # Add strikethrough without changing code spans or code fences.
    blocks = re.split(r"(```[\s\S]*?```|`[^`\n]+`)", doc["body"])
    for i in range(0, len(blocks), 2):
        blocks[i] = re.sub(r"~~(.+?)~~", r"<del>\1</del>", blocks[i])
    body = "".join(blocks)
    rendered = markdown.markdown(body, extensions=["footnotes", "fenced_code", "tables", "attr_list", "sane_lists"])
    soup = BeautifulSoup(rendered, "html.parser")
    for node in soup.find_all(id=True):
        node["id"] = doc["key"] + "-" + node["id"]
    for image in soup.find_all("img"):
        image["src"] = print_image(image["src"], doc["path"])
    for a in soup.find_all("a", href=True):
        target = a["href"]
        if target.startswith("#"):
            a["href"] = "#" + doc["key"] + "-" + target[1:]
        elif not target.startswith(("https://", "http://", "mailto:")):
            path = resolve_local(target, doc["path"])
            if path in doc_by_path:
                a["href"] = "#" + doc_by_path[path]["key"]
            else:
                try:
                    label = path.relative_to(ROOT).as_posix()
                except ValueError:
                    label = target
                local_links.add(label)
                # Local companion references remain readable on paper.
                a.attrs.pop("href", None)
                ref = soup.new_tag("span", attrs={"class": "path"})
                ref.string = f" ({label})"
                a.insert_after(ref)
    # Keep one figure and its following italic caption together.
    for image in list(soup.find_all("img")):
        parent = image.parent
        if parent.name == "p" and len(parent.find_all("img")) == 1:
            figure = soup.new_tag("figure")
            parent.insert_before(figure)
            sibling = parent.find_next_sibling()
            figure.append(parent.extract())
            if sibling and sibling.name == "p" and sibling.find("em") and not sibling.get_text().strip().replace(sibling.find("em").get_text().strip(), ""):
                sibling.name = "figcaption"
                figure.append(sibling.extract())
    return (f'<article class="chapter" id="{doc["key"]}"><div class="eyebrow">{html.escape(doc["label"])}</div>'
            f'<h1>{inline(doc["title"])}</h1><span class="mark">[[{doc["key"]}]]</span>{soup}</article>')


for doc in documents:
    doc["html"] = document_html(doc)
print(f"Prepared {len(image_cache)} distinct figures", flush=True)

CSS = """
@page {size:A4; margin:22mm 28mm 24mm 28mm}
html {-webkit-print-color-adjust:exact; print-color-adjust:exact}
body {font:11pt/1.48 Cambria,Georgia,serif;color:#181818;margin:0}
h1,h2,h3,h4 {break-after:avoid-page;line-height:1.2}
h1 {font-size:23pt;font-weight:normal;margin:0 0 17pt}
h2 {font-size:14pt;margin:18pt 0 8pt} h3 {font-size:12pt;margin:14pt 0 6pt}
p {margin:0 0 8pt;orphans:3;widows:3}
a {color:inherit;text-decoration:none}
.title-page {text-align:center;padding-top:54mm;break-after:page}
.title-page h1 {font-size:42pt;margin:0 0 12pt}
.subtitle {font-size:17pt}.edition {margin-top:46mm;font:11pt/1.6 Arial,sans-serif}
.proof-note,.chapter,.toc,.part-page {break-before:page}
.proof-note {padding-top:20mm;max-width:130mm}
.proof-note p {margin-bottom:14pt}
.chapter.compact p {margin-bottom:6pt}
.chapter.compact pre {margin-top:7pt;margin-bottom:9pt}
.chapter.compact2 {line-height:1.43}
.chapter.compact2 p {margin-bottom:5pt}
.chapter.compact2 pre {margin-top:6pt;margin-bottom:8pt}
.eyebrow {font:8.5pt/1.4 Arial,sans-serif;letter-spacing:1pt;color:#606060;margin:0 0 8pt}
.part-page {text-align:center;padding-top:60mm;break-after:page}
.part-page h1 {font-size:28pt}.part-page .eyebrow {margin-bottom:18pt}
.toc h1 {font-size:25pt;margin:0 0 18pt}
.toc .row {display:flex;line-height:1.42;break-inside:avoid;font-size:9.3pt}
.toc .row .text {flex:1}.toc .page {flex:0 0 24pt;text-align:right}
.toc .part {font-weight:bold;margin-top:9pt;break-after:avoid-page}
.toc .child {margin-left:12pt}.toc .framing {font-weight:bold;margin:5pt 0}
.mark {position:absolute;font:1pt/1 Arial;color:white}
pre {font:8.8pt/1.4 Consolas,"Courier New",monospace;background:#f5f4f1;border-left:2pt solid #d4d0c8;
padding:8pt 10pt;white-space:pre-wrap;overflow-wrap:anywhere;tab-size:4;break-inside:avoid; margin:10pt 0 13pt}
pre.long {break-inside:auto} code {font-family:Consolas,"Courier New",monospace;font-size:.9em}
pre code {font-size:1em} p code,li code {overflow-wrap:anywhere}
blockquote {margin:9pt 16pt;color:#393939} blockquote p {margin-bottom:6pt}
figure {margin:13pt 0;break-inside:avoid} figure p {margin:0}
img {display:block;max-width:100%;max-height:118mm;width:auto;height:auto;margin:auto}
figcaption {font:9pt/1.4 Cambria,serif;color:#444;margin-top:6pt}
table {border-collapse:collapse;font-size:9pt;width:100%;margin:10pt 0;overflow-wrap:anywhere}
thead {display:table-header-group} tr {break-inside:avoid} td,th {border-bottom:.5pt solid #bbb;padding:5pt;text-align:left;vertical-align:top}
th {background:#eee} ul,ol {padding-left:20pt} li {margin-bottom:4pt;orphans:2;widows:2}
.footnote {font-size:8.5pt;line-height:1.4;margin-top:18pt}
.footnote hr {border:0;border-top:.5pt solid #999;width:28%;margin:0 0 8pt}
.footnote li {margin-bottom:6pt;overflow-wrap:anywhere}.footnote-backref {display:none}
.path {font:7.8pt/1.4 Consolas,monospace;color:#666;overflow-wrap:anywhere}
sup {line-height:0} del {text-decoration:line-through}
"""
# Permit natural page breaks in the few programs too tall for a page.
for doc in documents:
    soup = BeautifulSoup(doc["html"], "html.parser")
    for pre in soup.find_all("pre"):
        if len(pre.get_text().splitlines()) > 42:
            pre["class"] = ["long"]
    doc["html"] = str(soup)


def build_html(page_of):
    def body(doc):
        level = spacing_adjustments.get(doc['key'], 0)
        return doc['html'].replace('class="chapter"', 'class="chapter ' + ('compact2' if level == 2 else 'compact') + '"', 1) if level else doc['html']
    def row(key, title, cls):
        return (f'<div class="row {cls}"><span class="text"><a href="#{key}">{inline(title)}</a></span>'
                f'<span class="page">{page_of.get(key, "")}</span></div>')
    output = ['<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Ada Research - First reading proof</title>',
              f'<style>{CSS}</style></head><body>',
              '<section class="title-page"><h1>Ada Research</h1><p class="subtitle">The book of the museum</p>',
              '<p>Palle Torsson</p>',
              f'<div class="edition">First reading proof<br>{EDITION}<br>{len(parts)} sequences · {len(chapters)} halls</div></section>',
              '<section class="proof-note"><h1>About this copy</h1>',
              '<p>This is a reading proof of a book being developed alongside its museum. The writing, objects and rooms continue to change together.</p>',
              '<p>Read the encounters as a continuous journey. The code already present in the manuscript is retained. Separate tutorial files are not added to this edition; the complete sequence of making lessons is still being developed.</p>',
              '<p>The preface and Day Zero prepare the arrival. The afterword returns to the questions of the book with the journey behind it. Footnotes remain with their chapters.</p>',
              '<p>Companion files are identified by their repository paths. They belong to the AdaResearch project and are not embedded in these printed pages.</p>',
              '<p>Use the margins for questions, corrections and connections. This copy fixes one moment of the work so that we can read it together.</p></section>',
              '<nav class="toc"><h1>Contents</h1>']
    for doc in front:
        output.append(row(doc["key"], doc["label"] + ' — ' + doc["title"] if doc["label"] == "Preface" else doc["title"], "framing"))
    for part in parts:
        output.append(row(part["key"], f'{part["order"]}. {part["title"]}', "part"))
        for doc in part["chapters"]:
            output.append(row(doc["key"], doc["title"], "child"))
    for doc in back:
        output.append(row(doc["key"], "Afterword — " + doc["title"], "framing"))
    output.append('</nav>')
    output.extend(body(d) for d in front)
    for part in parts:
        output.append(f'<section class="part-page" id="{part["key"]}"><p class="eyebrow">Sequence {part["order"]} of {len(parts)} <span class="mark">[[{part["key"]}]]</span></p><h1>{html.escape(part["title"])}</h1></section>')
        output.extend(body(d) for d in part["chapters"])
    output.extend(body(d) for d in back)
    output.append('</body></html>')
    return '\n'.join(output)


def render(source, destination):
    cmd = [str(CHROME), '--headless=new', '--disable-gpu', '--disable-extensions', '--disable-background-networking',
           f'--user-data-dir={WORK / "chrome-profile"}', '--no-pdf-header-footer',
           '--run-all-compositor-stages-before-draw', '--virtual-time-budget=12000',
           f'--print-to-pdf={destination}', source.as_uri()]
    start = time.monotonic()
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
    if result.returncode or not destination.exists():
        raise RuntimeError(result.stderr[-2500:])
    print(f'Rendered {destination.name} in {time.monotonic() - start:.0f}s', flush=True)


def locate(path):
    found = {}
    with fitz.open(path) as pdf:
        for i, page in enumerate(pdf):
            for key in re.findall(r'\[\[((?:PT|FR|BK)\d{2}|CH\d{3})\]\]', re.sub(r'\s+', '', page.get_text())):
                if key in found:
                    raise ValueError(f'Duplicate section marker {key}')
                found[key] = i + 1
        return found, len(pdf)


expected = {d['key'] for d in documents} | {p['key'] for p in parts}
page_of = {}
for attempt in range(1, 7):
    source = WORK / f'pass-{attempt}.html'
    pdf = WORK / f'pass-{attempt}.pdf'
    source.write_text(build_html(page_of), encoding='utf-8')
    render(source, pdf)
    found, page_count = locate(pdf)
    if set(found) != expected:
        raise ValueError(f'Missing printed chapters: {expected - set(found)}')
    # Tighten spacing slightly when a chapter leaves fewer than 65 words alone
    # on its final page. Keep body type at 11pt and never remove text.
    adjusted = []
    starts = {found[d['key']]: d['key'] for d in documents}
    with fitz.open(pdf) as proof:
        for n, page in enumerate(proof, 1):
            if n in found.values() or not any(s <= n for s in starts):
                continue
            if len(page.get_text().split()) < 65 and not page.get_images():
                key = starts[max(s for s in starts if s <= n)]
                if spacing_adjustments.get(key, 0) < 2:
                    spacing_adjustments[key] = spacing_adjustments.get(key, 0) + 1
                    adjusted.append(key)
    print(f'Pass {attempt}: {page_count} pages, {len(found)} sections; contents stable: {found == page_of}; spacing adjustments: {len(adjusted)}', flush=True)
    if found == page_of and not adjusted:
        break
    page_of = found
else:
    raise RuntimeError('Contents pagination did not stabilize')

# Pagination markers are only measuring tools; exclude them from the reading PDF.
clean_html = re.sub(r'<span class="mark">.*?</span>', '', build_html(found))
clean_source = WORK / 'print.html'
clean_source.write_text(clean_html, encoding='utf-8')
pdf = WORK / 'print.pdf'
render(clean_source, pdf)
with fitz.open(pdf) as clean_pdf:
    if len(clean_pdf) != page_count:
        raise RuntimeError('Removing measurement markers changed pagination')

# Keep named destinations and internal links while adding page numbers.
reader = PdfReader(pdf)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
buf = io.BytesIO()
overlay = canvas.Canvas(buf, pagesize=(595.2756, 841.8898))
for i in range(page_count):
    if i:
        overlay.setFont('Helvetica', 8)
        overlay.setFillGray(.4)
        overlay.drawCentredString(595.2756 / 2, 31, str(i + 1))
    overlay.showPage()
overlay.save()
buf.seek(0)
footer = PdfReader(buf)
for i, page in enumerate(writer.pages):
    page.merge_page(footer.pages[i])
    page.compress_content_streams()
writer.add_outline_item('Contents', 2)
for d in front:
    writer.add_outline_item(d['label'], found[d['key']] - 1)
for part in parts:
    parent = writer.add_outline_item(f'{part["order"]}. {part["title"]}', found[part['key']] - 1)
    for d in part['chapters']:
        writer.add_outline_item(plain(d['title']), found[d['key']] - 1, parent=parent)
for d in back:
    writer.add_outline_item('Afterword', found[d['key']] - 1)
writer.add_metadata({'/Title': 'Ada Research - First reading proof', '/Author': 'Palle Torsson',
    '/Subject': f'{EDITION}; {len(parts)} sequences; {len(chapters)} halls',
    '/Creator': 'Ada Research reading-proof builder'})
with FINAL.open('wb') as stream:
    writer.write(stream)
with fitz.open(FINAL) as to_compact:
    compact = WORK / 'compacted.pdf'
    to_compact.save(compact, garbage=4, deflate=True)
compact.replace(FINAL)

# Fail if any manuscript source changed during the build.
changed = [p for p, sha in sources.items() if hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != sha]
if changed:
    raise RuntimeError('Sources changed during build; rebuild: ' + ', '.join(changed))
manifest = dict(edition_date=args.date, built_at=datetime.now().astimezone().isoformat(),
    head=subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True, text=True).stdout.strip(),
    source_basis='Current working tree, including uncommitted files; hashes below are authoritative.',
    pdf=FINAL.relative_to(ROOT).as_posix(), pdf_sha256=hashlib.sha256(FINAL.read_bytes()).hexdigest(),
    sequences=len(parts), halls=len(chapters), pages=page_count, images=len(image_cache),
    sources=sources, print_only_transforms=transforms, spacing_adjustments=spacing_adjustments,
    sections=[dict(key=d['key'], title=plain(d['title']), page=found[d['key']], source=d['path'].relative_to(ROOT).as_posix()) for d in documents],
    sequence_starts=[dict(title=p['title'], page=found[p['key']]) for p in parts],
    local_companion_references=sorted(local_links))
(OUT / f'reading-proof-{args.date}-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'FINAL {FINAL}: {page_count} pages, {FINAL.stat().st_size / 1024**2:.1f} MB', flush=True)
