#!/usr/bin/env python3
"""
Intent-driven development starter packs for AdaResearch.

This complements tools/lod_query.py:
  - lod_query.py works best when you already know the entity name
  - dev_start.py works when you know the development intention

Examples:
  python tools/dev_start.py grid
  python tools/dev_start.py "interactive button"
  python tools/dev_start.py flowers --json
  python tools/dev_start.py --list
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parent.parent
DOC_DIR = ROOT / "doc"
DOCS_DIR = ROOT / "docs"
STARTPACKS_DIR = DOC_DIR / "startpacks"
ENCY_ROOT = ROOT.parent / "ada_encyclopedia"
GWE_DB = ROOT.parent / "grounded_wiki_engine" / "backend" / "data" / "cache.db"
DEEPWIKI_URL = "https://deepwiki.com/palletorsson/AdaResearch"

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

SKIP_DIR_NAMES = {
    ".git",
    ".godot",
    ".next",
    ".claude",
    "node_modules",
    "__pycache__",
    "android",
    "build",
    "temp",
}


@dataclass
class PackItem:
    path: str
    reason: str


@dataclass
class EncyclopediaItem:
    label: str
    route: str = ""
    source: str = ""
    reason: str = ""


@dataclass
class TopicProfile:
    key: str
    title: str
    overview: str
    category: str = "general"
    aliases: list[str] = field(default_factory=list)
    keywords: list[str] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)
    read_first: list[PackItem] = field(default_factory=list)
    principles: list[str] = field(default_factory=list)
    constraints: list[str] = field(default_factory=list)
    first_moves: list[str] = field(default_factory=list)
    deepwiki_topics: list[str] = field(default_factory=list)
    encyclopedia: list[EncyclopediaItem] = field(default_factory=list)
    history_keywords: list[str] = field(default_factory=list)


TOPIC_PROFILES: dict[str, TopicProfile] = {
    "grid": TopicProfile(
        key="grid",
        title="Grid System",
        category="systems",
        overview=(
            "The grid is the stage system for AdaResearch. It turns JSON map data "
            "into structure, utilities, and interactables, and it is the right "
            "starting point for changes to layout, colors, utilities, spawning, or "
            "map-level affordances."
        ),
        aliases=[
            "grid",
            "lab grid",
            "grid color",
            "update the grid",
            "grid system",
            "map grid",
        ],
        keywords=[
            "grid",
            "lab",
            "utility",
            "interactable",
            "map_data",
            "spatial fit",
            "apply_grid_config",
        ],
        tags=["grid", "maps", "layout", "rendering", "utilities"],
        read_first=[
            PackItem("commons/grid/GridSystem.gd", "Master orchestrator for map rendering."),
            PackItem(
                "commons/grid/GridInteractablesComponent.gd",
                "Artifact placement and token resolution from the interactables layer.",
            ),
            PackItem(
                "commons/grid/UtilityRegistry.gd",
                "Single source of truth for utility token meanings.",
            ),
            PackItem(
                "doc/LAB_GRID_GUID.md",
                "Concrete lab-specific grid styling, progression, and the current cube colors.",
            ),
            PackItem(
                "docs/GRID_MODIFIER_AND_SPATIAL_FIT_PLAN.md",
                "Current extension plan for grid modifiers and artifact placement logic.",
            ),
            PackItem(
                "doc/MAP_EDITING_PIPELINE.md",
                "Operational map editing flow if the change touches authored map data.",
            ),
        ],
        constraints=[
            "Maps use a 3-layer contract: structure, utilities, interactables.",
            "The lab grid currently uses off-white cubes: Color(0.95, 0.95, 0.98, 1.0).",
            "Lab ambient light is documented as Color(0.9, 0.9, 1.0, 0.4).",
            "The current plan keeps the 2.5D map format and adds complexity through modifiers, not format replacement.",
        ],
        first_moves=[
            "Decide whether the change is structural, utility-level, or interactable-level before touching code.",
            "Check whether the request belongs in generic GridSystem or only in lab-specific styling.",
            "If the change affects authored maps, inspect one representative map_data.json first.",
        ],
        deepwiki_topics=[
            "Grid System",
            "Grid System Architecture",
            "Map Data Format",
            "Artifact Registry System",
        ],
        encyclopedia=[
            EncyclopediaItem(
                label="Grid Editor",
                route="/grid-editor",
                source="src/components/grid-editor/GridCanvas.tsx",
                reason="2D editing surface for tile/grid changes.",
            ),
            EncyclopediaItem(
                label="Map Builder",
                route="/map-builder",
                source="src/components/map-builder/MapBuilderPage.tsx",
                reason="Higher-level map composition and analysis flow.",
            ),
            EncyclopediaItem(
                label="Project context store",
                source="src/app/api/context/route.ts",
                reason="Reusable place to persist derived clauses, formulas, and patterns.",
            ),
        ],
        history_keywords=["grid", "lab", "map", "utility", "spatial fit", "color"],
    ),
    "nature_system": TopicProfile(
        key="nature_system",
        title="Nature System",
        category="nature",
        overview=(
            "The nature system is a critter-based Q-FEP simulation layer spanning "
            "DNA, morphology, evolution, transmutation, and map-level nature painting."
        ),
        aliases=[
            "nature",
            "nature system",
            "improve the nature system",
            "critter",
            "q-fep critter",
        ],
        keywords=[
            "nature",
            "critter",
            "dna",
            "flower",
            "fungus",
            "tree",
            "transmutation",
            "evolution",
        ],
        tags=["nature", "critters", "dna", "morphology", "simulation"],
        read_first=[
            PackItem("doc/NATURE_SYSTEM_PLAN.md", "Main design contract for the system."),
            PackItem(
                "algorithms/nature_system/README.md",
                "Code-level entry point for the implemented nature system folder.",
            ),
            PackItem(
                "algorithms/nature_system/demo/nature_system_demo.gd",
                "Runnable demo surface tying the subsystems together.",
            ),
            PackItem(
                "algorithms/nature_system/dna/critter_dna.gd",
                "Core data structure for critter morphology and behavior.",
            ),
            PackItem(
                "algorithms/nature_system/morphology/flower_morphology.gd",
                "Starting point for flower shape generation.",
            ),
            PackItem(
                "algorithms/nature_system/systems/transmutation_manager.gd",
                "Relationship and state transformation logic.",
            ),
            PackItem(
                "commons/artifacts/registry/nature_system.json",
                "Registry truth for the demo artifact and current map-readiness state.",
            ),
        ],
        constraints=[
            "The design principle is transmutation across a spectrum, not fixed friend/enemy categories.",
            "The demo artifact is registered but currently marked map_ready=false.",
            "The system spans all four kingdoms: tree, creature, flower, fungus.",
        ],
        first_moves=[
            "Choose whether the work is DNA-level, morphology-level, or map authoring before editing.",
            "If the goal is a new system behavior, start in algorithms/nature_system/systems/.",
            "If the goal is a new visible organism, start in morphology plus registry/demo wiring.",
        ],
        deepwiki_topics=[
            "Overview",
            "Artifact Registry System",
            "Map & Content Definition",
        ],
        encyclopedia=[
            EncyclopediaItem(
                label="Nature layer persistence API",
                source="src/app/api/game/save-nature-layer/route.ts",
                reason="Writes and reads nature_layer.json per map.",
            ),
            EncyclopediaItem(
                label="Project context store",
                source="src/app/api/context/route.ts",
                reason="Good place to persist derived patterns and nature formulas.",
            ),
        ],
        history_keywords=["nature", "garden", "critter", "dna", "transmutation", "flower"],
    ),
    "flowers": TopicProfile(
        key="flowers",
        title="Flowers",
        category="nature",
        overview=(
            "Flowers sit between the broader nature-system DNA route and standalone "
            "artifact route. Use this pack when you want to build new flowers or "
            "extend flower behavior specifically. The stable core is: flowers are "
            "parameterized signal organisms whose morphology, symmetry, and perception "
            "effects should remain legible to the learner."
        ),
        aliases=[
            "flower",
            "flowers",
            "new flowers",
            "build new flowers",
            "improve flowers",
        ],
        keywords=["flower", "flowers", "botanical", "water flowers", "pollen"],
        tags=["flowers", "botanical", "signals", "morphology", "artifacts"],
        read_first=[
            PackItem(
                "algorithms/nature_system/morphology/flower_morphology.gd",
                "System-level flower morphology generator.",
            ),
            PackItem(
                "commons/artifacts/botanical_flower/botanical_flower.gd",
                "Standalone flower artifact implementation.",
            ),
            PackItem(
                "commons/artifacts/flower_lab/flower_lab.gd",
                "Flower-specific experiment surface.",
            ),
            PackItem(
                "commons/artifacts/water_flowers/water_flowers.gd",
                "Existing water flower artifact implementation.",
            ),
            PackItem(
                "commons/flora/botanical_flower.gd",
                "Core procedural flower generator with botanical taxonomy and presets.",
            ),
            PackItem(
                "doc/NATURE_SYSTEM_PLAN.md",
                "Design contract for flower meaning, toxicity, and transmutation.",
            ),
        ],
        principles=[
            "Flowers are signal critters: they are meant to convey information, medicine, toxicity, attraction, or perception shifts, not just act as decoration.",
            "Morphology should stay parameter-legible: petal count, symmetry, curvature, stem height, color, and inflorescence should produce visible conceptual differences a learner can read.",
            "The core generator is anatomically structured: stem, leaves, sepals, petals, stamens, pistil, and inflorescence order matter more than arbitrary mesh styling.",
            "Use real botanical patterns when possible: radial vs bilateral symmetry, phyllotaxis, inflorescence type, and species-like presets are part of the teaching value.",
            "Standalone flower artifacts should stay thin wrappers over the core generator or morphology system, forwarding meaningful parameters rather than duplicating flower-building logic.",
            "Perception changes are part of the flower contract: pollen, color, and morphology can change what the player sees or understands, not only what the player looks at.",
        ],
        constraints=[
            "Flowers are signal critters in the nature-system design, not just decoration.",
            "Flower changes can be either standalone artifacts or nature-system morphology work; decide which route you are taking.",
            "BotanicalFlower already exposes taxonomy-level controls such as flower form, symmetry, leaf placement, and inflorescence presets; prefer extending that model over inventing parallel parameter vocabularies.",
            "Flower Lab is already teaching the most impactful parameters through VR sliders, so new principles should remain teachable through a small set of high-leverage controls.",
        ],
        first_moves=[
            "Decide whether this flower belongs in commons/artifacts as a standalone scene or in algorithms/nature_system as generated morphology.",
            "If the flower should affect player perception or medicine/toxicity, align it with the transmutation model first.",
            "Check whether the desired change belongs in the core BotanicalFlower generator, the DNA-driven FlowerMorphology path, or only in a wrapper artifact.",
        ],
        deepwiki_topics=["Artifacts & Interactables", "Map & Content Definition"],
        encyclopedia=[
            EncyclopediaItem(
                label="Nature layer persistence API",
                source="src/app/api/game/save-nature-layer/route.ts",
                reason="Relevant if flower placement becomes part of painted map nature.",
            ),
        ],
        history_keywords=["flower", "flowers", "garden", "pollen", "botanical"],
    ),
    "folding": TopicProfile(
        key="folding",
        title="Folding",
        category="experimental",
        overview=(
            "Folding is currently strongest as a design/runtime specification. It already "
            "has a detailed contract, but the runtime is still more design-heavy than grid "
            "or nature-system work. Start by separating authored specification from actually "
            "implemented fold code."
        ),
        aliases=[
            "folding",
            "explore folding",
            "fold creature",
            "folded creature",
            "miura",
        ],
        keywords=["fold", "folding", "miura", "fold_amount", "foldrig", "foldcritter"],
        tags=["folding", "runtime", "spec", "morphology", "prototype"],
        read_first=[
            PackItem(
                "doc/FOLDING_CREATURE_SYSTEM.md",
                "High-level folding design and authoring model.",
            ),
            PackItem(
                "doc/FOLD_RUNTIME_SPEC_V1.md",
                "Runtime class contracts and update order.",
            ),
            PackItem(
                "doc/NATURE_SYSTEM_PLAN.md",
                "Nature-system overlap if folding is being attached to critters rather than isolated artifacts.",
            ),
            PackItem(
                "commons/primitives/foldedpaper/foldedpaper.gd",
                "Closest concrete folded primitive currently present in the repo.",
            ),
        ],
        constraints=[
            "Folding is specified across morphology, function, structure, and symbolic meaning.",
            "The runtime spec centers on fold_amount and explicit FoldRig/FoldSolver abstractions.",
            "Treat this as partially implemented: design truth is stronger than code truth here.",
        ],
        first_moves=[
            "Decide whether the next step is spec consolidation, a folded primitive prototype, or critter integration.",
            "Avoid assuming FoldRig/FoldSolver runtime classes already exist unless you verify them locally.",
        ],
        deepwiki_topics=["Overview", "Interactive Components", "Artifacts & Interactables"],
        encyclopedia=[],
        history_keywords=["fold", "folding", "miura", "creature"],
    ),
    "interaction_controls": TopicProfile(
        key="interaction_controls",
        title="Interactive Buttons and Sliders",
        category="interaction",
        overview=(
            "Use this pack for VR control surfaces: buttons, sliders, preset panels, and "
            "other parameter controls embedded in artifacts."
        ),
        aliases=[
            "button",
            "interactive button",
            "push button",
            "slider",
            "vr controls",
            "control panel",
        ],
        keywords=["button", "slider", "press", "push_button", "slider_horizontal", "panel"],
        tags=["interaction", "vr-controls", "buttons", "sliders", "panels"],
        read_first=[
            PackItem(
                "commons/interactables/push_button.tscn",
                "Current push-button scene used by artifacts.",
            ),
            PackItem(
                "commons/interactables/slider_horizontal.tscn",
                "Current slider scene used by artifacts.",
            ),
            PackItem(
                "doc/ARTIFACT_VR_REVIEW.md",
                "Current implementation pattern and ergonomics for VR control panels.",
            ),
            PackItem(
                "doc/ARTIFACT_IMPLEMENTATION_NOTES.md",
                "Examples of reset buttons, sliders, and control surfaces embedded in artifacts.",
            ),
            PackItem(
                "commons/artifacts/curvature_slider/curvature_slider.gd",
                "Concrete artifact-level slider example.",
            ),
        ],
        constraints=[
            "Current standard is slider_horizontal.tscn for continuous parameters and push_button.tscn for discrete actions.",
            "Control panels are documented as slightly in front of and below the artifact, tilted ~30 degrees toward the viewer.",
            "Desktop keyboard controls are often preserved alongside VR controls.",
        ],
        first_moves=[
            "Copy the existing VR review panel pattern before inventing a new control panel layout.",
            "Decide whether you are adding a reusable interactable or a one-off artifact control.",
            "Check hand reach, spacing, and label readability as part of the starting contract.",
        ],
        deepwiki_topics=["Interactive Components", "Artifacts & Interactables"],
        encyclopedia=[],
        history_keywords=["button", "slider", "vr controls", "control panel", "panel"],
    ),
    "science_screen": TopicProfile(
        key="science_screen",
        title="Science Screen",
        category="visualization",
        overview=(
            "Science Screen is the 2D mirror for 3D VR interactions. It is the right "
            "starting point when the task touches visual parity between VR and web, "
            "on-screen coordinate feedback, mode-specific visualizers, or the 2D-to-3D bridge."
        ),
        aliases=[
            "science screen",
            "science-screen",
            "screen",
            "xy screen",
            "visualization screen",
        ],
        keywords=[
            "science screen",
            "science_screen",
            "xy",
            "viewport",
            "point",
            "line",
            "triangle",
            "draw dot",
        ],
        tags=["science-screen", "visualization", "vr-web-bridge", "2d", "primitives"],
        read_first=[
            PackItem(
                "doc/SCIENCE_SCREEN_SYSTEM.md",
                "System contract for the VR/web bridge, rendering modes, and style parity.",
            ),
            PackItem(
                "commons/artifacts/science_screen/science_screen.gd",
                "Main Godot artifact with scanning and mode dispatch logic.",
            ),
            PackItem(
                "commons/artifacts/science_screen/screen_overlay.gd",
                "Overlay and presentation logic around the rendered screen surface.",
            ),
            PackItem(
                "commons/artifacts/registry/primitives.json",
                "Registry truth for primitive artifacts the screen mirrors.",
            ),
            PackItem(
                "doc/PRIMITIVE_ONTOLOGY.md",
                "Conceptual frame for the primitives the screen is teaching.",
            ),
        ],
        principles=[
            "The 2D screen is not secondary UI; it is the explicit mirror of embodied 3D interaction.",
            "VR and web should preserve the same visual language: grid, colors, readout, and mode logic.",
            "The screen should auto-adapt to nearby artifacts instead of requiring bespoke map configuration.",
        ],
        constraints=[
            "VR truth is the science_screen artifact and its mode scanners; web parity should follow that contract, not drift independently.",
            "The screen style is intentionally scientific and shared across platforms.",
            "If you add a new mode, you need both a Godot renderer path and a web renderer path.",
        ],
        first_moves=[
            "Decide whether the change is a new mode, a visual-style adjustment, or a scanner/detection change.",
            "Check the current Science Screen system doc before editing the artifact or the web mirror.",
            "Verify whether the web mirror needs updating in parallel with the Godot artifact.",
        ],
        deepwiki_topics=["Artifacts & Interactables", "Interactive Components", "Map & Content Definition"],
        encyclopedia=[
            EncyclopediaItem(
                label="Science Screen XY",
                route="/primitives/science-screen",
                source="src/components/shared/ScienceScreenXY.tsx",
                reason="Web mirror component for the VR Science Screen modes.",
            ),
            EncyclopediaItem(
                label="Timeline Editor",
                route="/timeline-editor",
                source="src/app/timeline-editor/page.tsx",
                reason="Relevant when the Science Screen is revealed or sequenced in scripted map flow.",
            ),
        ],
        history_keywords=["science screen", "xy", "point", "line", "triangle", "draw"],
    ),
    "artifact_registry": TopicProfile(
        key="artifact_registry",
        title="Artifact Registry",
        category="content",
        overview=(
            "The artifact registry is the lookup and metadata layer between maps and scenes. "
            "Use this pack when the task is about adding artifacts, changing lookup_name metadata, "
            "understanding registry structure, or improving how artifacts are categorized and discovered."
        ),
        aliases=[
            "artifact registry",
            "registry",
            "artifacts",
            "artifact metadata",
            "lookup name",
        ],
        keywords=[
            "artifact",
            "registry",
            "lookup_name",
            "scene",
            "grid_artifacts",
            "dev_themes",
            "tags",
        ],
        tags=["registry", "artifacts", "lookup", "metadata", "spawning"],
        read_first=[
            PackItem(
                "commons/managers/GridArtifactRegistry.gd",
                "Authoritative runtime loader for registry/*.json files.",
            ),
            PackItem(
                "doc/ARCHITECTURE.md",
                "System-level description of artifact lookup and registry structure.",
            ),
            PackItem(
                "doc/ARTIFACT_THEME_GUIDE.md",
                "Metadata and categorization guide for registry entries.",
            ),
            PackItem(
                "doc/ARTIFACT_ORGANIZATION_PROPOSAL.md",
                "Design rationale behind modular category registries.",
            ),
            PackItem(
                "commons/artifacts/registry/primitives.json",
                "Representative modular registry file with live artifact entries.",
            ),
            PackItem(
                "commons/artifacts/registry/lab.json",
                "Registry example for lab- and tool-oriented artifacts.",
            ),
        ],
        principles=[
            "registry/*.json is the authoritative source; the legacy grid_artifacts.json file is deprecated.",
            "lookup_name is the stable bridge between map tokens, registry metadata, and scene loading.",
            "Theme/category metadata should improve discovery without changing runtime identity.",
        ],
        constraints=[
            "GridArtifactRegistry loads all registry/*.json files and may overwrite duplicate keys by last-loaded file.",
            "New metadata should stay additive and backward compatible unless you are deliberately changing loader behavior.",
            "Maps and sequences should refer to stable lookup_name values, not folder structure.",
        ],
        first_moves=[
            "Decide whether the work is loader behavior, registry schema, or authoring metadata.",
            "Check for duplicate or overlapping lookup_name entries before adding a new artifact.",
            "If the change is discovery-oriented, update metadata first and runtime code second.",
        ],
        deepwiki_topics=["Artifact Registry System", "Artifacts & Interactables", "Map & Content Definition"],
        encyclopedia=[
            EncyclopediaItem(
                label="AI tool inventory",
                route="/ai",
                source="src/lib/ai/tool-inventory.ts",
                reason="Useful when you want to connect artifact metadata to encyclopedia tooling surfaces.",
            ),
            EncyclopediaItem(
                label="Map Builder",
                route="/map-builder",
                source="src/components/map-builder/MapBuilderPage.tsx",
                reason="Relevant because map authoring consumes lookup_name artifacts from the registry layer.",
            ),
        ],
        history_keywords=["artifact", "registry", "lookup_name", "metadata", "dev_themes"],
    ),
    "sequence_map_pipeline": TopicProfile(
        key="sequence_map_pipeline",
        title="Sequence and Map Pipeline",
        category="curriculum",
        overview=(
            "This is the curriculum path from sequence definition to map flow to lab progression. "
            "Use this pack when the task is about building a new sequence, editing map progression, "
            "changing unlock order, or understanding how authored maps become playable curriculum."
        ),
        aliases=[
            "sequence pipeline",
            "map pipeline",
            "sequence and map pipeline",
            "map sequence",
            "progression system",
        ],
        keywords=[
            "sequence",
            "map",
            "pipeline",
            "progression",
            "lab_post",
            "curriculum_spine",
            "map_data",
        ],
        tags=["sequences", "maps", "progression", "pipeline", "lab"],
        read_first=[
            PackItem(
                "doc/HOW_TO_ADD_MAP_SEQUENCE.md",
                "Practical sequence authoring guide and lab-chain rules.",
            ),
            PackItem(
                "doc/MAP_EDITING_PIPELINE.md",
                "End-to-end workflow from discovery through validation and VR review.",
            ),
            PackItem(
                "doc/PROGRESSION_SYSTEM.md",
                "Architecture-level explanation of lab progression and sequence rewards.",
            ),
            PackItem(
                "commons/managers/AdaSceneManager.gd",
                "Sequence loading and transition manager.",
            ),
            PackItem(
                "commons/managers/MapProgressionManager.gd",
                "Sequence-first progression state and unlock tracking.",
            ),
            PackItem(
                "commons/maps/curriculum_spine.json",
                "Explicit recommended sequence order and lab progression chain.",
            ),
        ],
        principles=[
            "Sequence ownership comes from sequence JSON and registry metadata, not from folder names alone.",
            "The Lab progression chain should grow monotonically across post maps.",
            "Map authoring and curriculum progression are linked: a sequence is not just a list of maps, but a learning path with unlock logic.",
        ],
        constraints=[
            "AdaSceneManager loads and merges sequences from commons/maps/sequences/*.json.",
            "MapProgressionManager now treats sequence files as canonical progression input.",
            "Lab post maps should preserve prior state while adding new rewards and routes.",
        ],
        first_moves=[
            "Decide whether the task belongs to sequence JSON, map_data.json authoring, scene-loading code, or lab progression.",
            "If the task changes unlock flow, inspect curriculum_spine.json before editing manager code.",
            "If the task creates a new sequence, validate both authoring docs and the runtime managers before testing.",
        ],
        deepwiki_topics=["Map & Content Definition", "Overview", "Artifact Registry System"],
        encyclopedia=[
            EncyclopediaItem(
                label="Map Builder",
                route="/map-builder",
                source="src/components/map-builder/MapBuilderPage.tsx",
                reason="Primary web surface for composing and exporting map_data.json.",
            ),
            EncyclopediaItem(
                label="Map Pipeline",
                route="/map-pipeline",
                source="src/app/features/page.tsx",
                reason="Feature-level reference for the guided map workflow surfaces.",
            ),
            EncyclopediaItem(
                label="Workflow",
                route="/workflow",
                source="src/app/workflow/page.tsx",
                reason="Operational flow for orient-assess-build-verify-track work.",
            ),
        ],
        history_keywords=["sequence", "map", "progression", "lab", "curriculum", "unlock"],
    ),
}


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip().lower())


def file_exists(relative_path: str) -> bool:
    if relative_path.startswith("src/"):
        return (ENCY_ROOT / relative_path).exists()
    return (ROOT / relative_path).exists()


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "startpack"


def iter_text_files(base_dirs: Iterable[Path], suffixes: tuple[str, ...]) -> Iterable[Path]:
    for base in base_dirs:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix.lower() not in suffixes:
                continue
            if any(part in SKIP_DIR_NAMES for part in path.parts):
                continue
            yield path


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""


def score_profile(query: str, profile: TopicProfile) -> int:
    score = 0
    q = normalize_text(query)
    for alias in profile.aliases:
        alias_norm = normalize_text(alias)
        if q == alias_norm:
            score += 12
        elif alias_norm in q or q in alias_norm:
            score += 8
    for keyword in profile.keywords:
        if keyword.lower() in q:
            score += 3
    return score


def choose_profile(query: str) -> TopicProfile | None:
    ranked = sorted(
        TOPIC_PROFILES.values(),
        key=lambda profile: score_profile(query, profile),
        reverse=True,
    )
    if not ranked:
        return None
    best = ranked[0]
    return best if score_profile(query, best) > 0 else None


def score_text_match(text: str, keywords: Iterable[str]) -> int:
    content = normalize_text(text)
    return sum(1 for keyword in keywords if keyword.lower() in content)


def find_history_hits(keywords: list[str], limit: int = 5) -> list[dict[str, str]]:
    history_roots = [DOC_DIR / "sessions"]
    candidates = list(iter_text_files(history_roots, (".md",)))
    handoffs = sorted(DOC_DIR.glob("SESSION_HANDOFF*.md"))
    candidates.extend(handoffs)

    hits: list[dict[str, str]] = []
    seen_paths: set[Path] = set()
    for path in candidates:
        text = read_text(path)
        score = score_text_match(text, keywords)
        if score <= 0:
            continue
        snippet = ""
        for line in text.splitlines():
            if score_text_match(line, keywords) > 0:
                snippet = line.strip()
                break
        if path in seen_paths:
            continue
        seen_paths.add(path)
        hits.append(
            {
                "path": str(path.relative_to(ROOT)).replace("\\", "/"),
                "snippet": snippet[:220],
                "score": str(score),
            }
        )
    hits.sort(key=lambda item: int(item["score"]), reverse=True)
    return hits[:limit]


def find_doc_hits(keywords: list[str], limit: int = 6) -> list[dict[str, str]]:
    hits: list[dict[str, str]] = []
    for path in iter_text_files([DOC_DIR, DOCS_DIR], (".md", ".json")):
        if STARTPACKS_DIR in path.parents:
            continue
        text = read_text(path)
        score = score_text_match(text, keywords)
        if score <= 0:
            continue
        snippet = ""
        for line in text.splitlines():
            if score_text_match(line, keywords) > 0:
                snippet = line.strip()
                break
        hits.append(
            {
                "path": str(path.relative_to(ROOT)).replace("\\", "/"),
                "snippet": snippet[:220],
                "score": str(score),
            }
        )
    hits.sort(key=lambda item: int(item["score"]), reverse=True)
    unique: list[dict[str, str]] = []
    seen = set()
    for item in hits:
        if item["path"] in seen:
            continue
        seen.add(item["path"])
        unique.append(item)
    return unique[:limit]


def find_repo_hits(keywords: list[str], limit: int = 8) -> list[str]:
    roots = [ROOT / "commons", ROOT / "algorithms", ROOT / "spatial_ui"]
    results: list[tuple[int, str]] = []
    for base in roots:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            if any(part in SKIP_DIR_NAMES for part in path.parts):
                continue
            relative = str(path.relative_to(ROOT)).replace("\\", "/")
            score = score_text_match(relative, keywords)
            if score > 0:
                results.append((score, relative))
    results.sort(key=lambda item: (-item[0], item[1]))
    deduped: list[str] = []
    seen = set()
    for _, path in results:
        if path in seen:
            continue
        seen.add(path)
        deduped.append(path)
    return deduped[:limit]


def get_gwe_project_slug() -> str | None:
    if not GWE_DB.exists():
        return None
    try:
        conn = sqlite3.connect(str(GWE_DB))
        repo_root = str(ROOT)
        row = conn.execute(
            "SELECT slug FROM projects WHERE repo_root = ? LIMIT 1",
            (repo_root,),
        ).fetchone()
        conn.close()
        return row[0] if row else None
    except Exception:
        return None


def _keyword_score(text: str, keywords: list[str]) -> int:
    lowered = normalize_text(text)
    score = 0
    for keyword in keywords:
        if not keyword:
            continue
        keyword_norm = normalize_text(keyword)
        if " " in keyword_norm:
            if keyword_norm in lowered:
                score += 2
            continue
        pattern = re.compile(rf"(?<![a-z0-9_]){re.escape(keyword_norm)}(?![a-z0-9_])")
        if pattern.search(lowered):
            score += 1
    return score


def _keyword_position(text: str, keywords: list[str]) -> int:
    lowered = normalize_text(text)
    positions: list[int] = []
    for keyword in keywords:
        if not keyword:
            continue
        keyword_norm = normalize_text(keyword)
        if " " in keyword_norm:
            pos = lowered.find(keyword_norm)
            if pos >= 0:
                positions.append(pos)
            continue
        pattern = re.compile(rf"(?<![a-z0-9_]){re.escape(keyword_norm)}(?![a-z0-9_])")
        match = pattern.search(lowered)
        if match:
            positions.append(match.start())
    return min(positions) if positions else -1


def _excerpt_around_keyword(text: str, keywords: list[str], max_len: int = 320) -> str:
    cleaned = re.sub(r"\s+", " ", text).strip()
    if len(cleaned) <= max_len:
        return cleaned
    pos = _keyword_position(cleaned, keywords)
    if pos < 0:
        return cleaned[:max_len]
    start = max(0, pos - max_len // 3)
    end = min(len(cleaned), start + max_len)
    excerpt = cleaned[start:end]
    if start > 0:
        excerpt = "..." + excerpt
    if end < len(cleaned):
        excerpt = excerpt + "..."
    return excerpt


def _is_low_signal_turn(text: str) -> bool:
    lowered = normalize_text(text)
    if not lowered:
        return True
    bad_prefixes = (
        "i'll ",
        "let me ",
        "now let me ",
        "good! now",
        "good, now",
        "<task-notification>",
        "this is a design question",
    )
    if lowered.startswith(bad_prefixes):
        return True
    if "tool-use-id" in lowered or "output-file>" in lowered:
        return True
    if "continued from a previous conversation" in lowered:
        return True
    if "summary below covers the earlier portion" in lowered:
        return True
    return False


def find_grounded_wiki_hits(keywords: list[str], limit_points: int = 4, limit_claims: int = 4, limit_turns: int = 4) -> dict:
    project_slug = get_gwe_project_slug()
    if not project_slug:
        return {"project_slug": None, "points": [], "claims": [], "turns": []}

    try:
        conn = sqlite3.connect(str(GWE_DB))
        conn.row_factory = sqlite3.Row

        point_rows = conn.execute(
            """
            SELECT point_type, title, statement, support_count, confidence
            FROM knowledge_points
            WHERE project_slug = ? AND status != 'stale'
            """,
            (project_slug,),
        ).fetchall()
        claim_rows = conn.execute(
            """
            SELECT claim_type, statement, support_count, confidence, status
            FROM claims
            WHERE project_slug = ?
            """,
            (project_slug,),
        ).fetchall()
        turn_rows = conn.execute(
            """
            SELECT session_id, turn_index, role, text
            FROM chat_turns
            WHERE project_slug = ?
            """,
            (project_slug,),
        ).fetchall()
        conn.close()
    except Exception:
        return {"project_slug": project_slug, "points": [], "claims": [], "turns": []}

    scored_points = []
    for row in point_rows:
        joined = f"{row['title']} {row['statement']}"
        score = _keyword_score(joined, keywords)
        if score <= 0:
            continue
        scored_points.append(
            (
                score,
                row["support_count"],
                row["confidence"],
                {
                    "point_type": row["point_type"],
                    "title": row["title"],
                    "statement": _excerpt_around_keyword(row["statement"], keywords),
                    "support_count": row["support_count"],
                    "confidence": row["confidence"],
                },
            )
        )
    scored_points.sort(key=lambda item: (-item[0], -item[1], -item[2], item[3]["title"]))

    scored_claims = []
    for row in claim_rows:
        score = _keyword_score(row["statement"], keywords)
        if score <= 0:
            continue
        scored_claims.append(
            (
                score,
                row["support_count"],
                row["confidence"],
                {
                    "claim_type": row["claim_type"],
                    "statement": _excerpt_around_keyword(row["statement"], keywords),
                    "support_count": row["support_count"],
                    "confidence": row["confidence"],
                    "status": row["status"],
                },
            )
        )
    scored_claims.sort(key=lambda item: (-item[0], -item[1], -item[2]))

    scored_turns = []
    for row in turn_rows:
        text = row["text"] or ""
        if _is_low_signal_turn(text):
            continue
        score = _keyword_score(text, keywords)
        if score <= 0:
            continue
        role_bonus = 2 if row["role"] == "user" else 1
        scored_turns.append(
            (
                score + role_bonus,
                {
                    "session_id": row["session_id"],
                    "turn_index": row["turn_index"],
                    "role": row["role"],
                    "text": _excerpt_around_keyword(text, keywords),
                },
            )
        )
    scored_turns.sort(key=lambda item: -item[0])

    return {
        "project_slug": project_slug,
        "points": [item[3] for item in scored_points[:limit_points]],
        "claims": [item[3] for item in scored_claims[:limit_claims]],
        "turns": [item[1] for item in scored_turns[:limit_turns]],
    }


def build_generic_pack(query: str) -> dict:
    keywords = [part for part in re.split(r"[\s/_-]+", query.lower()) if part]
    grounded = find_grounded_wiki_hits(keywords)
    return {
        "query": query,
        "matched_topic": "generic",
        "pack_slug": slugify(query),
        "title": f"Generic development start for: {query}",
        "category": "exploration",
        "tags": keywords[:8],
        "overview": (
            "No curated starter pack matched exactly. This pack is assembled from "
            "document hits and repo path matches, so it is useful for discovery but "
            "less trustworthy than a curated topic profile."
        ),
        "read_first": [],
        "principles": [],
        "constraints": [],
        "first_moves": [
            "Refine the intent into a system noun if possible, then rerun this tool.",
            "Use tools/lod_query.py when you know the sequence, map, or artifact name.",
        ],
        "deepwiki_url": DEEPWIKI_URL,
        "deepwiki_topics": ["Overview"],
        "encyclopedia": [],
        "history_hits": find_history_hits(keywords),
        "doc_hits": find_doc_hits(keywords),
        "repo_hits": find_repo_hits(keywords),
        "grounded_wiki": grounded,
        "trust_order": [
            "repo files",
            "doc/ and docs/ contracts",
            "session handoffs and session summaries",
            "grounded wiki chat points and turns",
            "encyclopedia routes and source files",
            "DeepWiki overview",
        ],
    }


def build_profile_pack(query: str, profile: TopicProfile) -> dict:
    keywords = sorted(set(profile.keywords + profile.history_keywords + query.lower().split()))
    grounded_keywords = sorted(set(profile.keywords + profile.history_keywords))
    grounded = find_grounded_wiki_hits(grounded_keywords)
    return {
        "query": query,
        "matched_topic": profile.key,
        "pack_slug": slugify(profile.key),
        "title": profile.title,
        "category": profile.category,
        "tags": profile.tags,
        "overview": profile.overview,
        "read_first": [
            {
                "path": item.path,
                "reason": item.reason,
                "exists": file_exists(item.path),
            }
            for item in profile.read_first
        ],
        "principles": profile.principles,
        "constraints": profile.constraints,
        "first_moves": profile.first_moves,
        "deepwiki_url": DEEPWIKI_URL,
        "deepwiki_topics": profile.deepwiki_topics,
        "encyclopedia": [
            {
                "label": item.label,
                "route": item.route,
                "source": item.source,
                "reason": item.reason,
                "exists": file_exists(item.source) if item.source else False,
            }
            for item in profile.encyclopedia
        ],
        "history_hits": find_history_hits(keywords),
        "doc_hits": find_doc_hits(keywords),
        "repo_hits": find_repo_hits(keywords),
        "grounded_wiki": grounded,
        "trust_order": [
            "repo files",
            "doc/ and docs/ contracts",
            "session handoffs and session summaries",
            "grounded wiki chat points and turns",
            "encyclopedia routes and source files",
            "DeepWiki overview",
        ],
    }


def render_markdown(pack: dict) -> str:
    lines = [
        f"# Development Start: {pack['title']}",
        "",
        f"**Intent:** `{pack['query']}`",
        f"**Matched topic:** `{pack['matched_topic']}`",
        f"**Pack slug:** `{pack['pack_slug']}`",
        f"**Category:** `{pack.get('category', 'general')}`",
        f"**Tags:** `{', '.join(pack.get('tags', []))}`" if pack.get("tags") else "**Tags:** `none`",
        f"**Generated:** `{pack.get('generated_at', '')}`",
        "",
        pack["overview"],
        "",
        "## Trust Order",
    ]
    for item in pack["trust_order"]:
        lines.append(f"- {item}")

    if pack["read_first"]:
        lines.extend(["", "## Read First"])
        for item in pack["read_first"]:
            status = "" if item["exists"] else " [missing]"
            lines.append(f"- `{item['path']}`{status} — {item['reason']}")

    if pack.get("principles"):
        lines.extend(["", "## Core Principles"])
        for item in pack["principles"]:
            lines.append(f"- {item}")

    if pack["constraints"]:
        lines.extend(["", "## Key Constraints"])
        for item in pack["constraints"]:
            lines.append(f"- {item}")

    if pack["first_moves"]:
        lines.extend(["", "## Suggested First Moves"])
        for item in pack["first_moves"]:
            lines.append(f"- {item}")

    if pack["history_hits"]:
        lines.extend(["", "## Relevant History"])
        for item in pack["history_hits"]:
            snippet = f" — {item['snippet']}" if item["snippet"] else ""
            lines.append(f"- `{item['path']}`{snippet}")

    if pack["doc_hits"]:
        lines.extend(["", "## Related Docs"])
        for item in pack["doc_hits"]:
            if item["path"] in {hit["path"] for hit in pack["history_hits"]}:
                continue
            snippet = f" — {item['snippet']}" if item["snippet"] else ""
            lines.append(f"- `{item['path']}`{snippet}")

    if pack["repo_hits"]:
        lines.extend(["", "## Related Repo Paths"])
        for item in pack["repo_hits"]:
            lines.append(f"- `{item}`")

    grounded = pack.get("grounded_wiki") or {}
    if grounded.get("project_slug"):
        lines.extend(["", "## Grounded Wiki Chat Knowledge"])
        lines.append(f"- source project slug: `{grounded['project_slug']}`")
        for item in grounded.get("points", []):
            lines.append(
                f"- point [{item['point_type']}] support={item['support_count']}: {item['statement']}"
            )
        for item in grounded.get("claims", []):
            lines.append(
                f"- claim [{item['claim_type']}] support={item['support_count']}: {item['statement']}"
            )
        for item in grounded.get("turns", []):
            lines.append(
                f"- turn `{item['session_id']}#{item['turn_index']}` ({item['role']}): {item['text']}"
            )

    if pack["encyclopedia"]:
        lines.extend(["", "## Encyclopedia Surfaces"])
        for item in pack["encyclopedia"]:
            bits = [item["label"]]
            if item["route"]:
                bits.append(f"route `{item['route']}`")
            if item["source"]:
                missing = "" if item["exists"] else " [missing]"
                bits.append(f"source `{item['source']}`{missing}")
            if item["reason"]:
                bits.append(item["reason"])
            lines.append(f"- {' — '.join(bits)}")

    lines.extend(["", "## DeepWiki"])
    lines.append(f"- Base: {pack['deepwiki_url']}")
    for item in pack["deepwiki_topics"]:
        lines.append(f"- Suggested topic: {item}")

    return "\n".join(lines)


def ensure_pack_metadata(pack: dict) -> dict:
    if "generated_at" not in pack:
        pack["generated_at"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    pack.setdefault("category", "general")
    pack.setdefault("tags", [])
    return pack


def load_pack_index(output_dir: Path) -> dict[str, dict]:
    index_path = output_dir / "index.json"
    if not index_path.exists():
        return {}
    try:
        data = json.loads(index_path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def write_pack(pack: dict, output_dir: Path) -> dict:
    ensure_pack_metadata(pack)
    output_dir.mkdir(parents=True, exist_ok=True)
    slug = pack["pack_slug"]
    md_path = output_dir / f"{slug}.md"
    json_path = output_dir / f"{slug}.json"
    md_path.write_text(render_markdown(pack), encoding="utf-8")
    json_path.write_text(json.dumps(pack, indent=2, ensure_ascii=False), encoding="utf-8")

    index_path = output_dir / "index.json"
    index_entries = load_pack_index(output_dir)

    index_entries[slug] = {
        "title": pack["title"],
        "matched_topic": pack["matched_topic"],
        "category": pack.get("category", "general"),
        "tags": pack.get("tags", []),
        "query": pack["query"],
        "generated_at": pack["generated_at"],
        "markdown": md_path.name,
        "json": json_path.name,
    }
    ordered = dict(sorted(index_entries.items(), key=lambda item: item[0]))
    index_path.write_text(json.dumps(ordered, indent=2, ensure_ascii=False), encoding="utf-8")

    return {
        "slug": slug,
        "markdown_path": str(md_path),
        "json_path": str(json_path),
        "index_path": str(index_path),
    }


def build_pack_from_query(query: str, slug_override: str = "") -> dict:
    profile = choose_profile(query)
    pack = build_profile_pack(query, profile) if profile else build_generic_pack(query)
    ensure_pack_metadata(pack)
    if slug_override:
        pack["pack_slug"] = slugify(slug_override)
    return pack


def refresh_saved_pack(slug: str, output_dir: Path) -> dict:
    index_entries = load_pack_index(output_dir)
    entry = index_entries.get(slug)
    if not entry:
        raise KeyError(f"Unknown saved pack slug: {slug}")
    query = entry.get("query") or slug.replace("-", " ")
    pack = build_pack_from_query(query, slug_override=slug)
    return write_pack(pack, output_dir)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build an AdaResearch development starter pack.")
    parser.add_argument("query", nargs="*", help="Intent or topic, e.g. grid, nature system, interactive button.")
    parser.add_argument("--json", action="store_true", dest="json_output", help="Emit JSON instead of Markdown.")
    parser.add_argument("--list", action="store_true", help="List curated starter topics.")
    parser.add_argument("--saved", action="store_true", help="List saved packs from doc/startpacks/index.json.")
    parser.add_argument("--write", action="store_true", help="Write the pack to doc/startpacks as Markdown and JSON.")
    parser.add_argument("--slug", default="", help="Custom slug to use when writing a pack.")
    parser.add_argument("--refresh-saved", metavar="SLUG", help="Refresh one saved pack using its stored query.")
    parser.add_argument(
        "--refresh-all-saved",
        action="store_true",
        help="Refresh every saved pack from doc/startpacks/index.json.",
    )
    parser.add_argument(
        "--refresh-curated",
        action="store_true",
        help="Regenerate all curated starter packs into doc/startpacks.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if args.list:
        for key, profile in sorted(TOPIC_PROFILES.items()):
            print(f"{key} [{profile.category}]: {profile.title}")
        return 0

    if args.saved:
        print(json.dumps(load_pack_index(STARTPACKS_DIR), indent=2, ensure_ascii=False))
        return 0

    if args.refresh_saved:
        written = refresh_saved_pack(slugify(args.refresh_saved), STARTPACKS_DIR)
        print(json.dumps([written], indent=2, ensure_ascii=False))
        return 0

    if args.refresh_all_saved:
        written = []
        for slug in sorted(load_pack_index(STARTPACKS_DIR)):
            written.append(refresh_saved_pack(slug, STARTPACKS_DIR))
        print(json.dumps(written, indent=2, ensure_ascii=False))
        return 0

    if args.refresh_curated:
        written = []
        for key, profile in sorted(TOPIC_PROFILES.items()):
            pack = build_profile_pack(profile.title, profile)
            ensure_pack_metadata(pack)
            written.append(write_pack(pack, STARTPACKS_DIR))
        print(json.dumps(written, indent=2, ensure_ascii=False))
        return 0

    query = " ".join(args.query).strip()
    if not query:
        print("Usage: python tools/dev_start.py <intent>")
        print("Example: python tools/dev_start.py grid")
        print("Use --list to see curated topics.")
        return 1

    pack = build_pack_from_query(query, slug_override=args.slug)

    if args.json_output:
        print(json.dumps(pack, indent=2, ensure_ascii=False))
    else:
        print(render_markdown(pack))

    if args.write:
        written = write_pack(pack, STARTPACKS_DIR)
        print(
            json.dumps(
                {"written": written},
                indent=2,
                ensure_ascii=False,
            )
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
