from pathlib import Path
from html.parser import HTMLParser
import hashlib,json,re
import markdown
H=Path(__file__).resolve().parent;R=H.parents[3]
sources=json.loads((H/"sources.json").read_text(encoding="utf-8"))
spoken=json.loads((H/"spoken-code.json").read_text(encoding="utf-8"))
tick=chr(96)
inline={
"_process":"underscore process","_count":"underscore count","Engine.get_process_frames()":"Engine dot get process frames",
"Vector3":"Vector three","FOCUS":"focus","_process(delta)":"underscore process, with delta","%.2f":"percent dot two f","to_local()":"to local",
"trigger_explosion()":"trigger explosion","b - a":"b minus a","length()":"length","rec":"rec","s":"s",
"to_local(world_tip)":"to local, applied to world tip","snappedf":"snapped f",
"Geometry2D.triangulate_polygon":"Geometry two D dot triangulate polygon",
"v6":"vertex six","v4":"vertex four","v5":"vertex five","v7":"vertex seven","SurfaceTool":"Surface Tool",
"V - E + F = 8 - 12 + 6 = 2":"V minus E plus F equals eight minus twelve plus six equals two",
"8 - 18 + 12 = 2":"eight minus eighteen plus twelve equals two",
"1e-16":"one times ten to the power of minus sixteen","capsule.tscn":"capsule dot T S C N",
"combine_portals":"combine portals","ring_segments":"ring segments","(3 + i, 3 + 2i)":"three plus i, and three plus two i",
"2 * sin(PI/n)":"two times the sine of pi divided by n","2 * n * sin(PI/n)":"two times n times the sine of pi divided by n",
"TAU = 2 * PI":"tau equals two times pi","n ≥ 3":"n greater than or equal to three","TAU":"tau",
"A_n = L(1 − 2⁻ⁿ)":"A sub n equals L times one minus two to the power of minus n",
"T_n = L(1 − 2⁻⁽ⁿ⁺¹⁾)":"T sub n equals L times one minus two raised to the negative of the quantity n plus one",
"6/1024":"six divided by one thousand and twenty-four"}
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,data):self.parts.append(data)
 def handle_endtag(self,tag):
  if tag in ["p","h1","h2","h3","h4","li","blockquote","tr"]:self.parts.append("\n\n")
 def handle_starttag(self,tag,attrs):
  if tag=="br":self.parts.append("\n")
def clean(raw):
 raw=re.sub(r"<!--.*?-->","",raw,flags=re.S)
 raw=re.sub(r"\[\^[^\]]+\]","",raw)
 raw=re.sub(tick+r"([^"+tick+r"\n]+)"+tick,lambda m:inline.get(m[1],m[1].replace("_"," ")),raw)
 raw=re.sub(r"~~(.*?)~~",lambda m:m[1]+", crossed out,",raw)
 parser=Text();parser.feed(markdown.markdown(raw,extensions=["tables"]))
 text="".join(parser.parts)
 text=re.sub(r"(?<=\w)_(?=\w)"," ",text)
 for a,b in {"→":" to ","↔":" in both directions ","≤":" less than or equal to ","≥":" greater than or equal to ","×":" times ","²":" squared ","³":" cubed ","π":" pi ","τ":" tau ","§":"section "}.items():text=text.replace(a,b)
 text=re.sub(r"[ \t]+"," ",text)
 return [p.strip() for p in re.split(r"\n\s*\n",text) if p.strip()]
chapters=[];notes=[];code_total=0;note_total=0
for index,source in enumerate(sources,1):
 name=source["map"];raw=(H/"source"/(name+".md")).read_bytes()
 assert hashlib.sha256(raw).hexdigest()==source["sha256"]
 text=raw.decode("utf-8-sig")
 definitions=list(re.finditer(r"(?ms)^\[\^([^\]]+)\]:[ \t]*(.*?)(?=^\[\^[^\]]+\]:|\Z)",text))
 note_total+=len(definitions)
 if definitions:
  notes.append({"kind":"heading","text":"Notes for "+name.replace("_"," ")+".","pause_ms":1000})
  for n,m in enumerate(definitions,1):
   for j,p in enumerate(clean(m[2])):notes.append({"kind":"note","text":("Note "+str(n)+". " if j==0 else "")+p,"pause_ms":650})
  text=text[:definitions[0].start()].rstrip()
 blocks=list(re.finditer(tick*3+r"[^\n]*\n(.*?)"+tick*3,text,re.S))
 assert len(blocks)==len(spoken[name]),name
 segments=[{"kind":"heading","text":("Ada Research. Primitives. " if index==1 else "")+"Chapter "+str(index)+". "+name.replace("_"," ")+".","pause_ms":1300}]
 start=0
 for b,reading in zip(blocks,spoken[name]):
  segments += [{"kind":"prose","text":p,"pause_ms":550} for p in clean(text[start:b.start()])]
  segments.append({"kind":"code","text":reading,"pause_ms":850})
  start=b.end();code_total+=1
 segments += [{"kind":"prose","text":p,"pause_ms":550} for p in clean(text[start:])]
 joined="\n\n".join(s["text"] for s in segments)+"\n"
 assert not any(m in joined for m in ["<!--",tick*3,"https://","http://","[^"]),name
 stem=f"{index:02d}-{name.lower().replace('_','-')}"
 (H/"transcripts"/(stem+".txt")).write_text(joined,encoding="utf-8")
 chapters.append({"index":index,"map":name,"title":name.replace("_"," "),"stem":stem,"segments":segments,"words":len(joined.split()),"source_sha256":source["sha256"]})
notes.insert(0,{"kind":"heading","text":"Notes and references. These follow the order of the ten halls.","pause_ms":1300})
stem="11-notes-and-references";joined="\n\n".join(s["text"] for s in notes)+"\n"
(H/"transcripts"/(stem+".txt")).write_text(joined,encoding="utf-8")
chapters.append({"index":11,"map":None,"title":"Notes and references","stem":stem,"segments":notes,"words":len(joined.split())})
manifest={"title":"Ada Research — Primitives","edition":"Current working manuscripts captured 21 September 2026","status":"Narration prepared; awaiting Google speech authentication","requested_provider":"Google Text-to-Speech","source_files_unchanged":True,"spoken_code_blocks":code_total,"footnotes":note_total,"adaptation":"Prose retained; formatting and URLs are not spoken; code/data excerpts receive explicit spoken equivalents; footnotes are collected in the last track; strikethrough is spoken as crossed out.","sources":sources,"chapters":chapters}
(H/"narration.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
(H/"transcript.txt").write_text("\n\n".join((H/"transcripts"/(c["stem"]+".txt")).read_text(encoding="utf-8") for c in chapters),encoding="utf-8")
print(json.dumps({"tracks":len(chapters),"words":sum(c["words"] for c in chapters),"spoken_code_blocks":code_total,"footnotes":note_total}))
