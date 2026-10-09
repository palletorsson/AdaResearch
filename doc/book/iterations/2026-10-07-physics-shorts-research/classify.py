"""Reproducible title-cue index, not video understanding or retention analysis."""
from collections import Counter
from pathlib import Path
import csv
import json
import re

HERE=Path(__file__).resolve().parent
TOPICS={
 'Throw, flight, bounce':r'\b(throw\w*|launch\w*|catapult\w*|mortar\w*|bounc\w*|jump\w*|fly|flying|flight|rocket\w*|drop\w*|catch\w*|frisbee\w*|ballistic\w*)\b',
 'Mechanisms and automation':r'\b(mechan\w*|machine\w*|contraption\w*|robot\w*|automat\w*|motor\w*|gear\w*|conveyor\w*|dispenser\w*|sorter\w*|gripper\w*|servo\w*|crank\w*|hinge\w*|piston\w*|clock\w*|pump\w*)\b',
 'Chain reactions and repetition':r'(domino|chain.?reaction|repeat|reset|loop\w*|toppl\w*|falldown)',
 'Sports, trick shots and vehicles':r'\b(trick.?shot\w*|basketball\w*|golf\w*|bowling\w*|football\w*|soccer\w*|baseball\w*|sport\w*|skateboard\w*|bike\w*|biking|motorcycle\w*|car\w*|vehicle\w*|truck\w*|frisbee\w*|jugg\w*|ping.?pong|pool|tennis|billiard\w*)\b',
 'Balance, fit and constraint':r'\b(balanc\w*|fit|fits|fitting|stack\w*|tower\w*|support\w*|puzzle\w*|stuck|knot\w*|interlock\w*|bolt\w*|friction\w*|slid\w*|roll\w*|spring\w*|pendulum\w*|tug|torque|weight\w*)\b',
 'Collision, breakage and load':r'(collisi\w*|collid\w*|crash\w*|smash\w*|shred\w*|crush\w*|break\w*|broken|destruct\w*|knock\w*|impact\w*|heavy|heaviest|force\w*|momentum|inertia|recoil)',
 'Gravity, magnets and orbits':r'\b(gravit\w*|magnet\w*|orbit\w*|levitat\w*|attract\w*|vortex\w*|centrifug\w*)\b',
 'Fluids, air and pressure':r'\b(water\w*|fluid\w*|liquid\w*|air|wind\w*|vacuum\w*|pressure\w*|siphon\w*|bubble\w*|balloon\w*|float\w*|buoyan\w*|pour\w*|snorkel\w*|fountain\w*)\b',
 'Light, colour and perception':r'\b(light\w*|optic\w*|mirror\w*|color\w*|colour\w*|rainbow\w*|laser\w*|illusion\w*|hologram\w*|invisib\w*|image\w*|microscope\w*|screen\w*|glass|see.through)\b',
 'Sound, rhythm and synchronization':r'(music\w*|rhythm\w*|sync\w*|melody|sound\w*|asmr|piano|sing\w*|song\w*|chime\w*|bell\w*|noise\w*)',
 'Materials, heat and chemistry':r'\b(heat\w*|hot|cold|freez\w*|melt\w*|fire\w*|flame\w*|lava|nitrogen|oxygen|chem\w*|metal\w*|steel|diamond|crystal\w*|wax|polymer\w*|sodium|ice|aerogel)\b',
 'VR and game cues':r'\b(vr|metaquest\w*|quest\d*|gamedev\w*|gaming|gmod|garry\w*|ragdoll\w*|sandbox|people.playground|boneworks|bonelab|unstable.dynamics|marrow)\b',
}
HOOKS={
 'Question or prediction':r'(\?|\b(why|how|what happens|which|guess|predict|will it|can you|can we|can he|can i)\b)',
 'Comparison':r'(\b(vs\.?|versus|compar\w*|different|same|faster than|slower than|bigger than)\b)',
 'Precision or satisfaction':r'\b(perfect\w*|satisf\w*|smooth\w*|accur\w*|precision|synchron\w*|sync\w*)\b',
 'Failure or mishap':r'(fail\w*|gone.wrong|not.the.plan|regret|bloop\w*|crash\w*|accident\w*|stuck|flaw|break\w*|broken|didn.t.go.well|did.not.survive|not.the.results)',
 'Surprise or apparent impossibility':r'(impossib\w*|weird\w*|strange\w*|surpris\w*|unexpected|paradox\w*|secret\w*|magic\w*|mind.bend\w*|mind.blow\w*|reverse\w*|defy\w*|actually)',
 'Scale, speed or escalation':r'(\b(biggest|largest|longest|fastest|smallest|tiny|giant|huge|ultimate|world.record|faster|increasing\w*|level.\d+|high.speed)\b|\d[\d,]*\s*(domino|ball|marble|gram|second|hour|foot|feet))',
 'Reveal or anticipation':r'(reveal\w*|wait.*(end|drop)|watch.*happen|before.it.happens|see.what|what.will.happen)',
 'Build or useful task':r'\b(build\w*|mak\w*|creat\w*|design\w*|clean\w*|wash\w*|tidy\w*|carry\w*|deliver\w*|retriev\w*|open\w*|pack\w*|draw\w*)\b',
}

rows=json.loads((HERE/'sample.json').read_text(encoding='utf-8'))
for r in rows:
 text=r['title'].lower()
 r['topic_cues']=[label for label,pattern in TOPICS.items() if re.search(pattern,text)]
 r['hook_cues']=[label for label,pattern in HOOKS.items() if re.search(pattern,text)]
 r['title_topic_unresolved']=not r['topic_cues']
 r['annotation_method']='automatic lexical cues in title including hashtags; overlapping, not verified video content'
(HERE/'classified.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
stats={'n':len(rows),'channel_counts':dict(Counter(r['channel'] for r in rows)),
 'topic_cue_counts':dict(Counter(x for r in rows for x in r['topic_cues']).most_common()),
 'hook_cue_counts':dict(Counter(x for r in rows for x in r['hook_cues']).most_common()),
 'no_topic_cue':sum(r['title_topic_unresolved'] for r in rows),
 'no_hook_cue':sum(not r['hook_cues'] for r in rows),
 'method':'Lexical title cues, including hashtags; categories overlap. Counts describe this purposive sample only. They are not counts of confirmed physical processes, successful videos or audience preferences.',
 'topic_regex':TOPICS,'hook_regex':HOOKS}
(HERE/'analysis.json').write_text(json.dumps(stats,ensure_ascii=False,indent=2),encoding='utf-8')
with (HERE/'classified.csv').open('w',encoding='utf-8-sig',newline='') as f:
 fields=['id','title','channel','url','topic_cues','hook_cues','title_topic_unresolved']
 w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
 for r in rows:
  row={k:r[k] for k in fields}
  row['topic_cues']='; '.join(row['topic_cues']);row['hook_cues']='; '.join(row['hook_cues'])
  w.writerow(row)
print(json.dumps({k:v for k,v in stats.items() if 'regex' not in k},ensure_ascii=True,indent=2))
