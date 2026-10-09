"""Public Shorts-list metadata only: no login, video download or watch claims."""
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import csv
import json
import time
import yt_dlp

HERE = Path(__file__).resolve().parent
SOURCES = [
 ('TheActionLab','science demonstrations'),
 ('ActionLabShorts','science demonstrations'),
 ('SteveMould','science demonstrations'),
 ('SteveSpangler','science demonstrations'),
 ('physicsfun','physical toys and demonstrations'),
 ('Engineezy','mechanisms and making'),
 ('JosephsMachines','mechanisms and chain reactions'),
 ('BrickExperimentChannel','mechanisms and making'),
 ('Hevesh5','dominoes and chain reactions'),
 ('MarbleRunJapan','marble runs'),
 ('HowRidiculous','throws, drops and targets'),
 ('DudePerfect','trick shots and challenges'),
 ('JoshHorton','balance, juggling and trick shots'),
 ('THATLLWORK','trick shots and challenges'),
 ('MDMXGames','VR physics sandbox developer'),
 ('BrandonJLa','VR physics sandbox developer'),
 ('Ctop','VR and sandbox gameplay'),
 ('Fudgy','VR and sandbox gameplay'),
 ('SpyCakes','sandbox gameplay'),
 ('DoodleChaos','simulated physics, rhythm and chain reactions'),
 ('SickScience','science demonstrations'),
 ('FailArmy','physical mishaps and fail compilations'),
]

class Logger:
 def __init__(self): self.messages=[]
 def debug(self, message): pass
 def warning(self, message): self.messages.append(str(message))
 def error(self, message): self.messages.append(str(message))

def collect(source):
 handle, purpose=source
 url=f'https://www.youtube.com/@{handle}/shorts'
 logger=Logger()
 opts={'extract_flat':True,'playlistend':100,'skip_download':True,
       'quiet':True,'no_warnings':True,'socket_timeout':15,'retries':1,
       'extractor_retries':1,'logger':logger}
 rows=[]
 info={'requested_handle':handle,'source_url':url,'selection_purpose':purpose}
 try:
  with yt_dlp.YoutubeDL(opts) as y:
   result=y.extract_info(url,download=False)
   info.update(channel=result.get('channel'),channel_id=result.get('channel_id') or result.get('id'),list_title=result.get('title'))
   for rank,v in enumerate(result.get('entries',[]),1):
    if not v or not v.get('id') or not v.get('title'): continue
    entry_url=v.get('url','')
    if '/shorts/' not in entry_url: continue
    rows.append({'id':v['id'],'title':v['title'],'url':entry_url,
                 'channel':result.get('channel') or handle,'channel_id':info['channel_id'],
                 'requested_handle':handle,'list_position':rank,
                 'approx_view_count':v.get('view_count'),'source_url':url,
                 'channel_selection_purpose':purpose})
  info['status']='ok';info['count']=len(rows)
 except Exception as ex:
  info['status']='error';info['error']=str(ex);info['count']=0
 info['warnings']=logger.messages
 (HERE/'raw').mkdir(exist_ok=True)
 (HERE/'raw'/f'{handle}.json').write_text(json.dumps({'source':info,'entries':rows},ensure_ascii=False,indent=2),encoding='utf-8')
 print(f'{handle}: {info["status"]}, {len(rows)} titles',flush=True)
 return handle,info,rows

def main():
 results={}
 pending=[]
 for source in SOURCES:
  cache=HERE/'raw'/f'{source[0]}.json'
  if cache.exists():
   cached=json.loads(cache.read_text(encoding='utf-8'))
   results[source[0]]=(cached['source'],cached['entries'])
  else: pending.append(source)
 with ThreadPoolExecutor(max_workers=3) as pool:
  for f in as_completed([pool.submit(collect,s) for s in pending]):
   handle,info,rows=f.result();results[handle]=(info,rows)
 # Fixed source order, round-robin through list positions, deduplicate video IDs.
 sample=[];seen=set()
 for rank in range(100):
  for handle,purpose in SOURCES:
   rows=results[handle][1]
   if rank<len(rows) and rows[rank]['id'] not in seen:
    sample.append(rows[rank]);seen.add(rows[rank]['id'])
   if len(sample)==1000: break
  if len(sample)==1000: break
 manifest={'collection_date':'2026-10-07','yt_dlp_version':yt_dlp.version.__version__,
  'target':1000,'selected_unique_titles':len(sample),
  'method':'Purposive channel sample; up to first 100 entries supplied by each public /shorts list; fixed-order round-robin selection of 1000 unique video IDs. Default list order recorded as list_position; not a random sample.',
  'limits':['Titles and list metadata only; no videos watched by this script.',
            'Not the user personalized feed; no claim of platform-wide representativeness.',
            'View counts are approximate list-display values; not used to infer retention or causation.',
            'Dates of individual uploads are unavailable in these flat lists.'],
  'sources':[results[h][0] for h,p in SOURCES]}
 (HERE/'sample.json').write_text(json.dumps(sample,ensure_ascii=False,indent=2),encoding='utf-8')
 (HERE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 with (HERE/'sample.csv').open('w',encoding='utf-8-sig',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(sample[0]) if sample else ['id','title','url']);w.writeheader();w.writerows(sample)
 print(f'SELECTED {len(sample)} unique Shorts titles',flush=True)

if __name__=='__main__': main()
