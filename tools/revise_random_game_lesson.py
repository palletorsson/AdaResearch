"""Keep one timing construction in the tutorial; preserve the room's reflection."""
from pathlib import Path
import hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[1]
HERE=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Game'
STUDY=ROOT/'doc/book/studies/randomness-lineage'

def main():
    HERE.mkdir(parents=True,exist_ok=True)
    protected=[f'commons/maps/Random_Game/{n}' for n in ['tutorial.md','final.md','map_data.json']]
    protected+=['commons/primitives/cubes/random_cycle_cube.gd','commons/primitives/cubes/random_cycle_cube.tscn','commons/maps/sequences/randomness.json','doc/book/studies/randomness-lineage/point_body.gd']
    if not (HERE/'before-manifest.json').exists():
        hashes={}
        for name in protected:
            dest=HERE/'before'/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/name,dest)
            hashes[name]=hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
        (HERE/'before-manifest.json').write_text(json.dumps(hashes,indent=2),encoding='utf8')
    text='''# A wait kept

**Learning elements**

- A fixed order of states with sampled waits
- Drawing once and retaining a deadline
- Updating a clock without redrawing the decision
- Separating a warning, a movement and collision support
- Replaying local state

At the crossing, watch one stone. It stands, leaves, stays below, then returns. The order repeats; the pauses vary. Look at the tablet: the current wait has already been drawn. The next wait is not yet stored. Turn CUE off. The ring disappears, but the stone keeps its appointment.

Random Space separated a value from the picture that disclosed it. Here we separate a scheduled event from its warning. Bring the cube's translation from Transformation, the clock from Point Zero, seeded draws and the carried PointBody. We rebuild one stone beside the existing crossing. The doors, removal floor and falling cubes remain other encounters in the hall.

## Keep a clock and a stone

In your local copy of the prepared museum, add a Node3D at hall-local **(3.5, 0, 10.5), Y rotation 90 degrees**, with unit scale. Place the three printed files together; attach `14_a_wait_kept.gd`. The museum already supplies its player, XR Tools, light and floor. The script makes its own stone, collider, display and PointBody. This is a small working model beside the crossing: stand on the museum floor to inspect it. The displayed cube and its travel are 60% of the installed stone's size. The backdrop and base are visual, without collision.

Hold the point over a label and press the trigger. REPLAY restores the current seed, clock, first wait, height and support, and pauses. RUN / STOP advances or holds the lesson's clock. CUE changes the advance ring. While paused, +0.25 s advances the clock by a quarter-second. Moving or dropping the point does not choose an action. The tablet stays readable when the ring is off.

There are two small programs. `wait_cycle.gd` stores the schedule without drawing geometry. The Node3D script gives that schedule a body. Keeping the clock separate lets us inspect an exact instant without waiting for it in a headset.

## The schedule: wait_cycle.gd

`replay()` initializes the generator and enters STANDS. `enter()` draws only when the stone begins a standing or hidden wait. It stores the phase's end in `until_ms`. `advance_to()` reads the time and crosses any boundaries already reached. It never draws merely because another frame arrived.

<!-- student-code:wait_cycle.gd -->
```gdscript
__MODEL__
```

## The complete body: 14_a_wait_kept.gd

`_physics_process()` supplies elapsed time. `redraw()` asks the schedule for height, support and warning; it does not make another decision. Notice that the cube's collider is explicitly created alongside its BoxMesh. A visible body does not supply collision by itself.

<!-- student-code:14_a_wait_kept.gd -->
```gdscript
__HOST__
```

## The same point: point_body.gd

This is the unchanged control from the earlier rooms. Its code is included so the example has every script it needs; the existing XR Tools installation supplies `XRToolsPickable`.

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

## Follow one cycle

`State` names four integers. Adding one and taking `% 4` moves through their fixed order. A random draw chooses a duration within the standing band, 2.4–4.6 seconds, or the hidden band, 1.1–2.2 seconds. These are endpoints, not a minimum plus a width. With equal endpoints the duration is fixed and no random number is consumed. The readout's draw count counts assigned waits, including fixed ones.

The deadline is **phase start + duration**. It is stored once. During a wait, subtracting the current clock gives time left. LEAVES and RETURNS use fixed durations; the tablet keeps the preceding drawn wait and shows zero wait remaining. The phase-end value still tells you when the movement phase finishes.

| State | Height | Collision support | Duration |
|---|---|---|---|
| STANDS | At the top | On | One sampled wait |
| LEAVES | Sinks for 0.5 s, then stays down for 0.2 s | On throughout | 0.7 s |
| GONE | Down | Off | One sampled wait |
| RETURNS | Stays down for 0.2 s, then rises for 0.2 s | Off for the first 0.2 s, then on | 0.4 s |

The cosine expressions reproduce the installed stone's smooth sine easing. They control travel, not the wait distribution. The colour marks the state; the white beacon marks either movement phase. The gold ring appears only during the last 1.2 seconds of STANDS, while the stone can still support a body. At the exact deadline the state becomes LEAVES and that ring is off.

The museum crossing uses asynchronous timers and tweens, with a ticket that invalidates an old loop on replay. This reconstruction uses one explicit clock instead. Replay replaces that clock and state, so no old timer or tween survives to move the stone later. Waits are rounded to milliseconds, matching the installed deadline display; production timers use the original fractional seconds. We are reproducing the draw rule and phase structure, not claiming frame-identical synchronization with the live crossing. The lesson's pause is local too: the museum around it keeps running.

`advance_to()` handles a frame that crosses more than one boundary. The next phase begins at the previous deadline, rather than at the late frame's arrival. Splitting the same elapsed time into smaller updates therefore keeps the same schedule. A long stall can skip displaying intermediate poses; physics cannot retroactively reproduce contacts that were never simulated. Replay is the only operation here that moves the clock backward.

## Change the notice, keep the event

Replay, then use +0.25 s until the ring appears. Record the deadline. Toggle CUE twice. The deadline, drawn duration and generator state stay the same. The number on the tablet still gives notice even when the stone does not.

Now change `notice_ms := 1200` to `notice_ms := 300` in the schedule and replay the same seed. Predict which will change: the first drawn duration, the moment of sinking, or the warning's duration. The ring now offers only 0.3 seconds of notice. The scheduled states remain identical. Explain where the player would have to look to compensate.

For a second variation, change `stand_band` to `Vector2(3.0, 3.0)`. Every standing wait becomes three seconds. The hidden waits still vary, so the whole cycle is not yet periodic. Because the fixed standing wait consumes no random value, the next hidden wait reads an earlier value from the seeded stream. Fixed and variable waits cannot be swapped while assuming every later duration will stay unchanged.

Finally change `run_seed` from 42 to 43. The order of states stays; the waits change. That number seeds this one learner stone. The full crossing has a separate seed that supplies different seeds to its three stones.

## What this room adds

You can now point to the moment when a decision enters the world, the state that keeps it, the view that reveals it, and the consequence attached to it. A random future can contain an already determined next event. A warning can change what a visitor knows without changing that event.

This closes the fourteen teaching halls of Randomness. Noise now returns to the relation between neighbouring samples. Keep this question available: which part is sampled, which part is retained, and which part is only being shown?
'''
    for token,name in [('__MODEL__','wait_cycle.gd'),('__HOST__','14_a_wait_kept.gd'),('__POINT__','point_body.gd')]:text=text.replace(token,(STUDY/name).read_text(encoding='utf8').rstrip())
    (ROOT/'commons/maps/Random_Game/tutorial.md').write_text(text,encoding='utf8')
    final=(HERE/'before/commons/maps/Random_Game/final.md').read_text(encoding='utf8')
    final=final.replace('Carry that question through the biome ladder, where successive compositions gather the rules we have met. In Noise Types we will then take it between neighbouring places.', 'Carry that question into Noise Types, between neighbouring places.')
    final=final.replace('A draw supplies the standing wait:','A draw supplies the standing wait. The interval becomes one number, held until the wait ends.')
    final=re.sub(r'\n```gdscript\n.*?\n```\n','\n',final,flags=re.S)
    final=final.replace('\nInside the function, the interval becomes a number:\n','')
    final=final.replace('There is another separation under your feet:','There is another separation under your feet.')
    final=final.replace('One door is assigned passage at the beginning of the round:','One door is assigned passage at the beginning of the round.')
    final=final.replace('The irregularity begins elsewhere:','The irregularity begins elsewhere.')
    final=final.replace('The counter reads the stored deadline.', 'Beside the crossing, the small reconstruction lets you pause a stone and shorten its notice. Its wait stays the same while the time offered to you contracts. The counter reads the stored deadline.')
    final=re.sub(r'\n{3,}','\n\n',final)
    (ROOT/'commons/maps/Random_Game/final.md').write_text(final,encoding='utf8')

if __name__=='__main__':main()
