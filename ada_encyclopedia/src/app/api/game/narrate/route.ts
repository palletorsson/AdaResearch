import { NextRequest, NextResponse } from "next/server";
import { spawn } from "child_process";
import { join } from "path";
import { existsSync } from "fs";

function getResearchPath(): string | null {
  return process.env.ADA_RESEARCH_PATH || null;
}

function findGodotExe(): string | null {
  const candidates = [
    process.env.GODOT_PATH,
    "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
    "godot",
  ];
  for (const candidate of candidates) {
    if (candidate && existsSync(candidate)) return candidate;
  }
  return candidates[candidates.length - 1] || null; // fallback to PATH
}

// Track running processes
const runningProcesses = new Map<
  string,
  { process: ReturnType<typeof spawn>; output: string[]; startedAt: number }
>();

// POST /api/game/narrate
// body: { target: "all" | "sequence" | "map", sequence?: string, map?: string }
export async function POST(request: NextRequest) {
  const researchPath = getResearchPath();
  if (!researchPath) {
    return NextResponse.json(
      { error: "ADA_RESEARCH_PATH not configured" },
      { status: 500 }
    );
  }

  const godotExe = findGodotExe();
  if (!godotExe) {
    return NextResponse.json(
      { error: "Godot executable not found" },
      { status: 500 }
    );
  }

  let body: { target?: string; sequence?: string; map?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { target = "all", sequence, map } = body;

  // Build Godot command args
  const args = [
    "--path",
    researchPath,
    "--xr-mode",
    "off",
    "--no-window",
    "--script",
    "res://commons/testing/narrate_all.gd",
    "--",
    "--outdir=res://ada_run/narrations",
  ];

  if (target === "sequence" && sequence) {
    args.push(`--sequence=${sequence}`);
  }
  // For single map, still filter by sequence (narrate_all handles finding the map)
  if (target === "map" && sequence) {
    args.push(`--sequence=${sequence}`);
  }

  const id = `narrate-${Date.now()}`;

  try {
    const child = spawn(godotExe, args, {
      cwd: researchPath,
      stdio: ["ignore", "pipe", "pipe"],
    });

    const entry = { process: child, output: [] as string[], startedAt: Date.now() };
    runningProcesses.set(id, entry);

    child.stdout?.on("data", (data: Buffer) => {
      const lines = data.toString().split("\n").filter(Boolean);
      entry.output.push(...lines);
      // Keep only last 200 lines
      if (entry.output.length > 200) {
        entry.output = entry.output.slice(-200);
      }
    });

    child.stderr?.on("data", (data: Buffer) => {
      entry.output.push(`[stderr] ${data.toString().trim()}`);
    });

    child.on("close", (code) => {
      entry.output.push(`[done] Process exited with code ${code}`);
      // Clean up after 5 minutes
      setTimeout(() => runningProcesses.delete(id), 300000);
    });

    return NextResponse.json({
      status: "started",
      id,
      target,
      sequence: sequence || null,
      map: map || null,
    });
  } catch (err) {
    return NextResponse.json(
      { error: `Failed to start Godot: ${err}` },
      { status: 500 }
    );
  }
}

// GET /api/game/narrate?id=<run-id>
// Check status of a running narration
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const id = searchParams.get("id");

  if (!id) {
    // List all running/recent processes
    const list = Array.from(runningProcesses.entries()).map(([key, entry]) => ({
      id: key,
      running: !entry.output.some((l) => l.startsWith("[done]")),
      lines: entry.output.length,
      startedAt: entry.startedAt,
    }));
    return NextResponse.json({ processes: list });
  }

  const entry = runningProcesses.get(id);
  if (!entry) {
    return NextResponse.json({ error: "Process not found" }, { status: 404 });
  }

  const done = entry.output.some((l) => l.startsWith("[done]"));
  const lastLines = entry.output.slice(-50);

  return NextResponse.json({
    id,
    running: !done,
    output: lastLines,
    elapsed: Date.now() - entry.startedAt,
  });
}
