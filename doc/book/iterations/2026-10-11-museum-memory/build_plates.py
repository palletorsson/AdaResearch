"""Render a semantic atlas and an unsummarized source leaf for a future OCR trial.

This renders data; it does not run or benchmark an OCR model. Does not refresh
capsule source receipts. Rerendering a stale capsule retains the stale status.
"""
from pathlib import Path
import hashlib
import json
import sys
import textwrap
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tools"))
import museum_memory

def font(size, serif=False, mono=False):
    return ImageFont.truetype("C:/Windows/Fonts/" + ("consola.ttf" if mono else "georgia.ttf" if serif else "arial.ttf"), size)

def wrap(draw, text, width, face):
    result = []
    for paragraph in text.splitlines():
        line = ""
        for word in paragraph.split(" "):
            candidate = f"{line} {word}" if line else word
            if draw.textlength(candidate, font=face) > width and line:
                result.append(line); line = word
            else:
                line = candidate
        result.append(line)
    return result

def main():
    model = museum_memory.model(ROOT)
    halls = [h for h in model["halls"] if h["capsule"]]
    paper, ink, green = "#f4f2eb", "#242823", "#435441"
    plate = Image.new("RGB", (2000, 2720), paper)
    draw = ImageDraw.Draw(plate)
    draw.text((70, 45), "ENDLESS MUSEUM  /  MEMORY ATLAS  /  11 OCTOBER 2026", font=font(22), fill=green)
    draw.text((70, 87), "What the next room keeps", font=font(62, serif=True), fill=ink)
    draw.text((70, 172), "A semantic route. Originals remain on the shelf. Photographs are dated retrieval cues.", font=font(25), fill=ink)
    source_receipts = []
    for i, h in enumerate(halls):
        x, y = 70 + (i % 2)*970, 242 + (i//2)*782
        draw.rectangle((x, y, x+920, y+747), outline="#bac0ae", width=2)
        c=h["capsule"]
        draw.text((x+22,y+18), f"{i:02} / {h['map']}", font=font(27), fill=ink)
        if h["image"]:
            p=ROOT/h["image"]["path"]
            plate.paste(ImageOps.fit(Image.open(p).convert("RGB"),(876,184)),(x+22,y+65))
            draw.text((x+22,y+256), f"Museum capture {h['image']['date']}  |  capsule {h['status']}",font=font(17),fill=green)
        cy=y+290
        for key in ("object", "change", "keep", "carry", "question"):
            text=key.upper()+": "+c[key]
            for line in wrap(draw,text,874,font(22)):
                draw.text((x+22,cy),line,font=font(22),fill=ink);cy+=28
            cy+=10
        assert cy < y+747, (h["map"],cy-y)
        source_receipts.extend(h["evidence"])
    draw.text((70, 2627), "Not a full packet: load rules, omissions, status and SHA-256 receipts before acting.", font=font(24), fill=ink)
    draw.text((70, 2666), "localhost:3003/museum-memory  |  No OCR or token-saving result is claimed.", font=font(22), fill=green)
    plate.save(OUT/"plate.png")

    # The comparison leaf encodes the entire source, including fences and comments.
    # Wrap without dropping whitespace or words; keep the exact source bytes too.
    source_path="commons/maps/Point_Zero/tutorial.md"
    raw=(ROOT/source_path).read_bytes()
    text=raw.decode("utf-8-sig")
    lines=[]
    for line in text.splitlines():
        lines.extend(textwrap.wrap(line.expandtabs(4),width=110,replace_whitespace=False,drop_whitespace=False) or [""])
    leaf=Image.new("RGB",(1800,170+len(lines)*25+75),paper)
    ld=ImageDraw.Draw(leaf)
    ld.text((55,30),"SOURCE LEAF / POINT ZERO / NO SUMMARY",font=font(27),fill=ink)
    ld.text((55,80),source_path,font=font(20),fill=ink)
    ld.text((55,115),"SHA-256 "+hashlib.sha256(raw).hexdigest(),font=font(18,mono=True),fill=green)
    for i,line in enumerate(lines):ld.text((55,170+i*25),line,font=font(23,mono=True),fill=ink)
    leaf.save(OUT/"source-leaf.png")
    (OUT/"source-leaf.md").write_bytes(raw)
    packets={scope:museum_memory.packet(model,scope) for scope in ["project","sequence:primitives","map:Point_Trace","map:Point_Line_Grid"]}
    for scope,p in packets.items():(OUT/(scope.replace(":","-")+".md")).write_text(p["text"],encoding="utf-8")
    receipt={"date":"2026-10-11", "memory_revision":model["revision"],"stats":model["stats"],
             "sources":source_receipts,"source_leaf":{"path":source_path,"sha256":hashlib.sha256(raw).hexdigest(),"words":len(text.split()),"dimensions":leaf.size},
             "packets":{k:{"words":v["words"],"selected_source_words":v["source_words"]} for k,v in packets.items()},
             "interpretation":"Whitespace counts only. Packets and originals contain different information. No optical token or comprehension benchmark."}
    (OUT/"manifest.json").write_text(json.dumps(receipt,indent=2,ensure_ascii=False),encoding="utf-8")
    print(json.dumps({"plate":plate.size,"source_leaf":leaf.size,"packets":receipt["packets"]}))

if __name__=="__main__":main()
