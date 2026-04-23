import * as fs from "fs";
import * as path from "path";

export interface RegistryArtifact {
  lookupName: string;
  name: string;
  description: string;
  scene: string;
  category: string;
  complexity: string;
  tags: string[];
  sequence: string;
  mapSequences: string[];
  mapReady: boolean;
}

export interface Registry {
  id: string;
  name: string;
  artifacts: Record<string, RegistryArtifact>;
}

let cachedRegistries: Registry[] | null = null;
let byLookupName: Map<string, RegistryArtifact> | null = null;
let byDirName: Map<string, string> | null = null;

export function loadRegistries(repoPath: string): Registry[] {
  if (cachedRegistries) return cachedRegistries;

  const registryDir = path.join(repoPath, "commons", "artifacts", "registry");
  if (!fs.existsSync(registryDir)) return [];

  const registries: Registry[] = [];

  for (const file of fs.readdirSync(registryDir)) {
    if (!file.endsWith(".json")) continue;
    try {
      const raw = fs.readFileSync(path.join(registryDir, file), "utf-8");
      const data = JSON.parse(raw);
      const id = path.basename(file, ".json");
      const artifacts: Record<string, RegistryArtifact> = {};

      for (const [key, val] of Object.entries(data.artifacts || {})) {
        const a = val as Record<string, unknown>;
        artifacts[key] = {
          lookupName: (a.lookup_name as string) || key,
          name: (a.name as string) || key,
          description: (a.description as string) || "",
          scene: (a.scene as string) || "",
          category: (a.category as string) || "",
          complexity: (a.complexity as string) || "",
          tags: (a.tags as string[]) || [],
          sequence: (a.sequence as string) || "",
          mapSequences: (a.map_sequences as string[]) || [],
          mapReady: (a.map_ready as boolean) || false,
        };
      }

      registries.push({
        id,
        name: (data.name as string) || id,
        artifacts,
      });
    } catch {
      /* skip malformed */
    }
  }

  cachedRegistries = registries;
  return registries;
}

export function buildLookupIndex(repoPath: string): Map<string, RegistryArtifact> {
  if (byLookupName) return byLookupName;

  byLookupName = new Map();
  for (const reg of loadRegistries(repoPath)) {
    for (const [key, artifact] of Object.entries(reg.artifacts)) {
      const token = artifact.lookupName || key;
      byLookupName.set(token, artifact);
    }
  }
  return byLookupName;
}

export function buildDirIndex(repoPath: string): Map<string, string> {
  if (byDirName) return byDirName;

  byDirName = new Map();
  const lookup = buildLookupIndex(repoPath);
  for (const [token, artifact] of lookup) {
    // Extract directory name from scene path: res://commons/artifacts/foo/Foo.tscn -> foo
    const match = artifact.scene.match(/\/([^/]+)\/[^/]+\.tscn$/);
    if (match) {
      byDirName.set(match[1], token);
    }
    // Also map by token itself (most common case)
    byDirName.set(token, token);
  }
  return byDirName;
}

export function findArtifactByFilePath(
  filePath: string,
  repoPath: string
): string | null {
  const dirIndex = buildDirIndex(repoPath);

  // Try parent directory name
  const dirName = path.basename(path.dirname(filePath));
  if (dirIndex.has(dirName)) {
    return dirIndex.get(dirName)!;
  }

  // Try filename without extension
  const baseName = path.basename(filePath, ".gd");
  if (dirIndex.has(baseName)) {
    return dirIndex.get(baseName)!;
  }

  // Try building res:// path and matching
  const rel = path.relative(repoPath, filePath).replace(/\\/g, "/");
  const resPath = `res://${rel}`;
  const lookup = buildLookupIndex(repoPath);
  for (const [token, artifact] of lookup) {
    if (artifact.scene.replace(".tscn", ".gd") === resPath) {
      return token;
    }
  }

  return null;
}

export function clearCache(): void {
  cachedRegistries = null;
  byLookupName = null;
  byDirName = null;
}
