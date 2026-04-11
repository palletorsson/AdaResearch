import { NextRequest, NextResponse } from "next/server";
import { readFile, writeFile, mkdir } from "fs/promises";
import { join } from "path";
import { spawn } from "child_process";

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

// GET /api/breathe — returns all BREATHE data for the dashboard
export async function GET() {
  const root = getResearchPath();

  const [breathLog, trajectory, proposals, heatMap, focusVector] =
    await Promise.all([
      readJsonSafe(join(root, "doc", "reports", "breath_log.json")),
      readJsonSafe(join(root, "doc", "reports", "improvement_trajectory.json")),
      readJsonSafe(
        join(root, "doc", "reports", "skill_evolution_proposals.json")
      ),
      readJsonSafe(join(root, "doc", "HEAT_MAP.json")),
      readJsonSafe(join(root, "doc", "FOCUS_VECTOR.json")),
    ]);

  return NextResponse.json({
    breathLog,
    trajectory,
    proposals,
    heatMap,
    focusVector,
  });
}

function runPythonTool(
  script: string,
  args: string[],
  cwd: string
): Promise<{ stdout: string; stderr: string; code: number | null }> {
  return new Promise((resolve) => {
    const child = spawn("python", [script, ...args], {
      cwd,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (d: Buffer) => {
      stdout += d.toString();
    });
    child.stderr.on("data", (d: Buffer) => {
      stderr += d.toString();
    });

    child.on("close", (code) => {
      resolve({ stdout, stderr, code });
    });

    // Safety timeout — 60 seconds
    setTimeout(() => {
      child.kill();
      resolve({ stdout, stderr, code: -1 });
    }, 60_000);
  });
}

// POST /api/breathe — trigger tools
// Body: { action: "score" | "heatmap" | "garden" | "gates" }
export async function POST(request: NextRequest) {
  const root = getResearchPath();

  let body: { action: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { action } = body;

  const toolMap: Record<string, { script: string; args: string[] }> = {
    score: {
      script: join(root, "tools", "sequence_pipeline_scorer.py"),
      args: [],
    },
    heatmap: {
      script: join(root, "tools", "heat_map_generator.py"),
      args: [],
    },
    garden: {
      script: join(root, "tools", "garden_listener.py"),
      args: ["--diagnosis"],
    },
    gates: {
      script: join(root, "tools", "run_release_gates.py"),
      args: [
        "--gate-toggles",
        join(root, "doc", "reports", "RELEASE_GATES_TOGGLES.json"),
      ],
    },
  };

  const tool = toolMap[action];
  if (!tool) {
    return NextResponse.json(
      { error: `Unknown action: ${action}. Valid: ${Object.keys(toolMap).join(", ")}` },
      { status: 400 }
    );
  }

  const result = await runPythonTool(tool.script, tool.args, root);

  // After running heatmap or score, re-read the output file
  let updatedData: unknown = null;
  if (action === "heatmap") {
    updatedData = await readJsonSafe(join(root, "doc", "HEAT_MAP.json"));
  }

  return NextResponse.json({
    action,
    code: result.code,
    stdout: result.stdout,
    stderr: result.stderr,
    updatedData,
  });
}
