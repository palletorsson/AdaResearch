import { NextResponse } from "next/server";
import { readFile, readdir } from "fs/promises";
import { join } from "path";

function getResearchPath(): string {
  return (
    process.env.ADA_RESEARCH_PATH ||
    "C:/Users/palle/Documents/GitHub/AdaResearch_46"
  );
}

async function readJsonSafe(filePath: string): Promise<unknown> {
  try {
    const content = await readFile(filePath, "utf-8");
    return JSON.parse(content);
  } catch {
    return null;
  }
}

// Form process taxonomy — mirrors MORPHOLOGY_ENGINE.md
const FORM_TAXONOMY = [
  { id: "grown", label: "Grown", range: [0.0, 0.15], f: "High", e: "Low", phi: "Low",
    bio: "Trees, coral, blood vessels", math: "Fractals, L-systems", color: "#22d3ee" },
  { id: "extruded", label: "Extruded", range: [0.15, 0.45], f: "Medium", e: "Low", phi: "Low",
    bio: "Worms, spines, tubes", math: "Sweeps, profiles", color: "#a78bfa" },
  { id: "carved", label: "Carved", range: [0.45, 0.6], f: "High", e: "Medium", phi: "Medium",
    bio: "Shells, caves", math: "Boolean ops, SDFs", color: "#f59e0b" },
  { id: "folded", label: "Folded", range: [0.6, 0.8], f: "Variable", e: "Variable", phi: "High",
    bio: "Insects, proteins, leaves", math: "Origami, springs", color: "#ec4899" },
  { id: "crystallized", label: "Crystallized", range: [0.8, 1.0], f: "Very High", e: "Very Low", phi: "Very Low",
    bio: "Minerals, diatoms, snowflakes", math: "Polyhedra, lattices", color: "#06b6d4" },
  { id: "dissolved", label: "Dissolved", range: [-1, -1], f: "Low", e: "High", phi: "Medium",
    bio: "Slime mold, lichen, clouds", math: "Reaction-diffusion", color: "#84cc16" },
  { id: "assembled", label: "Assembled", range: [-1, -1], f: "Medium", e: "Medium", phi: "Medium",
    bio: "Colonial organisms", math: "Graph composition", color: "#f97316" },
  { id: "instanced", label: "Instanced", range: [-1, -1], f: "High", e: "Medium", phi: "Low",
    bio: "Forests, swarms, colonies", math: "Arrays, scatter", color: "#14b8a6" },
];

// Curriculum progression
const CURRICULUM = [
  { stage: 1, algorithm: "Foundations", form: "Box, Sphere, Cylinder" },
  { stage: 2, algorithm: "Recursion", form: "L-system branching" },
  { stage: 3, algorithm: "Graphs", form: "Node-edge sweep" },
  { stage: 4, algorithm: "Cellular Automata", form: "Voxel grids" },
  { stage: 5, algorithm: "Noise & Fields", form: "Displacement, terrain" },
  { stage: 6, algorithm: "Physics", form: "Fold, spring deployment" },
  { stage: 7, algorithm: "Optimization", form: "Evolution of form" },
  { stage: 8, algorithm: "Topology", form: "Isosurface, SDF carving" },
  { stage: 9, algorithm: "Emergence", form: "Swarm instancing, Turing patterns" },
  { stage: 10, algorithm: "Synthesis", form: "Full pipeline — anything" },
];

// GET /api/morphology — returns taxonomy + stages + snapshots
export async function GET() {
  const root = getResearchPath();

  // Load soft stages
  const softStages = await readJsonSafe(join(root, "commons", "maps", "soft_stages.json"));

  // Load creature snapshots (if any)
  let snapshots: unknown[] = [];
  const snapshotDir = join(root, "doc", "reports", "creature_snapshots");
  try {
    const files = await readdir(snapshotDir);
    const jsonFiles = files.filter((f) => f.endsWith(".json")).slice(-20); // Last 20
    for (const f of jsonFiles) {
      const data = await readJsonSafe(join(snapshotDir, f));
      if (data) snapshots.push(data);
    }
  } catch {
    // No snapshots yet
  }

  return NextResponse.json({
    taxonomy: FORM_TAXONOMY,
    curriculum: CURRICULUM,
    softStages,
    snapshots,
  });
}
