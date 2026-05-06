"""Create 17 catalyst chamber maps across the spine."""
import json, os

chambers = [
    {"seq": "primitives", "name": "Chamber_Primitives", "mode": "primitives", "creature": None, "screen": "point",
     "blurb": "The first mark. You pick up the crystal and it absorbs into your hand. Fire bouncing spheres at targets. The system acknowledges you.",
     "concept": "First catalyst interaction — absorption, first projectile, targeting practice."},
    {"seq": "transformation", "name": "Chamber_Transformation", "mode": "transformation", "creature": "miura_crawler", "screen": "scatter",
     "blurb": "The crawler folds flat when your shrink ray hits it. It does not die. It compresses. You have changed something without destroying it.",
     "concept": "First creature encounter — transformation as non-destructive change."},
    {"seq": "color", "name": "Chamber_Color", "mode": "chromatic", "creature": "kaleidocycle_enemy", "screen": "scatter",
     "blurb": "Rainbow bursts shift the kaleidocycle through its four color-attack modes. The miura watches from the corner, no longer hostile.",
     "concept": "Color as communication — each hue triggers a different creature response."},
    {"seq": "forces", "name": "Chamber_Forces", "mode": "forces", "creature": "kresling_spire", "screen": "scatter",
     "blurb": "The calming mortar slows the kresling. Amber warmth. Physics as gentleness.",
     "concept": "Force as calming influence — Newton applied to creature relationships."},
    {"seq": "array_tutorial", "name": "Chamber_Arrays", "mode": None, "creature": "gridagent:copy", "screen": "grid",
     "blurb": "No new weapon. Instead you watch the grid agent traverse, copy, pattern. You place obstacles. The agent adapts.",
     "concept": "No catalyst mode — the lesson is observation and arrangement, not projection."},
    {"seq": "wavefunctions", "name": "Chamber_Waves", "mode": "waveform", "creature": "waterbomb_enemy", "screen": "wave",
     "blurb": "Your helix shots spiral through the air. The waterbomb bounces in rhythm. When your wave matches its frequency, something synchronizes.",
     "concept": "Resonance — wave-particle duality as creature interaction."},
    {"seq": "randomness", "name": "Chamber_Random", "mode": "chaos", "creature": "octapod_crawler", "screen": "scatter",
     "blurb": "Chaos shots scatter unpredictably. The octapod cannot predict you. Randomness levels the field.",
     "concept": "Unpredictability as equality — neither player nor creature controls the outcome."},
    {"seq": "noise", "name": "Chamber_Noise", "mode": None, "creature": None, "screen": "field",
     "blurb": "No weapon, no creature. You sculpt the terrain with Perlin noise. The landscape rises and falls. You are making a world.",
     "concept": "World-building — the player becomes environment designer, not combatant."},
    {"seq": "cellularautomata", "name": "Chamber_CA", "mode": "cellular", "creature": "lifeform_walker", "screen": "grid",
     "blurb": "Your CA burst hits the walker. Its armor is a Game of Life grid. Your cells interact with its cells. Conway meets Conway.",
     "concept": "Rule systems meeting — two cellular automata interacting across the player-creature boundary."},
    {"seq": "fractals", "name": "Chamber_Fractals", "mode": "fractal", "creature": "fractal_hydra", "screen": "scatter",
     "blurb": "You split. It splits. Your projectiles branch into four. The hydra branches into two. Neither of you can finish this.",
     "concept": "Self-similarity across the player-creature boundary — both express the same recursion."},
    {"seq": "lsystems", "name": "Chamber_LSystems", "mode": "branching", "creature": "branching_vine", "screen": "trace",
     "blurb": "Your branching tendrils grow alongside the vine. Two grammars producing structure. The miura approaches, curious now.",
     "concept": "Grammar as shared language — L-system projectiles and L-system creatures growing together."},
    {"seq": "proceduralgeneration", "name": "Chamber_ProcGen", "mode": None, "creature": "bricoleur_golem", "screen": "grid",
     "blurb": "The golem rebuilds from whatever is nearby. You cannot destroy it. Every piece you knock off becomes material for the next version.",
     "concept": "Bricolage — destruction feeds reconstruction."},
    {"seq": "softbodies", "name": "Chamber_SoftBodies", "mode": None, "creature": "spring_hopper", "screen": "field",
     "blurb": "The hopper bounces softly. Spring physics. Deformable matter in deformable space. Everything gives when you push it.",
     "concept": "Soft interaction — no rigid boundaries between player force and creature response."},
    {"seq": "swarmintelligence", "name": "Chamber_Swarm", "mode": "swarm", "creature": "swarm_hive", "screen": "scatter",
     "blurb": "Your eight boids meet their swarm. Two flocks in one space. The same rules on both sides. The miura dances with you.",
     "concept": "Collective intelligence — the catalyst becomes a flock, mirroring the creature."},
    {"seq": "machinelearning", "name": "Chamber_ML", "mode": None, "creature": "gradient_hunter", "screen": "scatter",
     "blurb": "The hunter learns your patterns. Move predictably and it finds you. Move randomly and it loses the gradient.",
     "concept": "Adversarial learning — the creature improves by studying you."},
    {"seq": "foundationscrisis", "name": "Chamber_Foundations", "mode": None, "creature": "paradox_stalker", "screen": "scatter",
     "blurb": "Two overlapping ghosts. One is real, one is not. You cannot defeat what you cannot distinguish. Incompleteness.",
     "concept": "Goedel embodied — a creature that proves the limits of your formal system."},
    {"seq": "qfeplaboratory", "name": "Chamber_QFEP", "mode": None, "creature": "qfep_calibrator", "screen": "wave",
     "blurb": "Every creature you befriended is here. The miura, the kaleidocycle, the hydra, the vine, the swarm. All friends now. The formula is complete.",
     "concept": "Culmination — all catalyst modes, all befriended creatures, the full QFEP formula embodied."},
]

for ch in chambers:
    map_dir = f"commons/maps/{ch['name']}"
    os.makedirs(map_dir, exist_ok=True)

    catalyst_str = f"becoming_catalyst#start_mode:{ch['mode']}" if ch["mode"] else " "
    creature_str = f"proximity_spawner#type:{ch['creature']}" if ch["creature"] else " "
    screen_str = f"science_screen:180:1.5#mode:{ch['screen']}"

    map_data = {
        "map_info": {
            "name": ch["name"].replace("_", " "),
            "lookup_name": ch["name"],
            "description": ch["blurb"],
            "dimensions": {"width": 11, "depth": 7, "max_height": 2}
        },
        "settings": {
            "cube_size": 1.0, "gutter": 0.0, "show_grid": True,
            "enable_physics": True, "enter_type": "I"
        },
        "utility_definitions": {
            "t": {"type": "teleporter", "name": "Return to Lab",
                   "description": "Sequence complete",
                   "properties": {"action": "next_in_sequence"}}
        },
        "layers": {
            "structure": [["1"]*11 for _ in range(7)],
            "utilities": [
                ["sp"]+[" "]*10,
                *[[" "]*11 for _ in range(5)],
                [" "]*10 + ["t"],
            ],
            "interactables": [
                [" ", " ", catalyst_str, " ", " ", " ", " ", " ", screen_str, " ", " "],
                [" "]*11,
                [" ", "catalyst_target", " ", "catalyst_target", " ", " ", " ", "catalyst_target", " ", "catalyst_target", " "],
                [" ", " ", " ", " ", " ", creature_str, " ", " ", " ", " ", " "],
                [" "]*11,
                [" "]*11,
                [" "]*11,
            ]
        }
    }

    with open(f"{map_dir}/map_data.json", "w", encoding="utf-8") as f:
        json.dump(map_data, f, indent=2, ensure_ascii=False)

    with open(f"{map_dir}/blurb.md", "w", encoding="utf-8") as f:
        f.write(ch["blurb"] + "\n")

    with open(f"{map_dir}/intent.md", "w", encoding="utf-8") as f:
        f.write(f"Concept: {ch['concept']}\n")
        f.write(f"Sequence role: Catalyst chamber for {ch['seq']}. Last map before returning to Lab.\n")
        f.write(f"Technical angle: Catalyst mode {ch['mode'] or 'none'}, creature {ch['creature'] or 'none'}, Science Screen {ch['screen']}.\n")
        f.write(f"Critical angle: The chamber is where mathematics becomes relationship. The catalyst transforms the player-creature boundary.\n")

    mode_str = ch["mode"] or "none"
    creature_name = ch["creature"] or "none"
    print(f"{ch['name']:30s}  mode:{mode_str:15s}  creature:{creature_name:20s}  screen:{ch['screen']}")

print(f"\nCreated {len(chambers)} chambers")
