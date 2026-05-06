import * as vscode from "vscode";
import * as fs from "fs";
import * as path from "path";
import { loadRegistries, type RegistryArtifact } from "./registryLoader";

interface SequenceInfo {
  id: string;
  name: string;
  maps: string[];
  isSpine: boolean;
  spineOrder: number;
}

type TreeItemData =
  | { type: "sequence"; sequence: SequenceInfo }
  | { type: "map"; mapName: string; sequenceId: string }
  | { type: "artifact"; token: string; artifact: RegistryArtifact };

export class ArtifactTreeProvider implements vscode.TreeDataProvider<TreeItemData> {
  private _onDidChangeTreeData = new vscode.EventEmitter<TreeItemData | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  private sequences: SequenceInfo[] = [];
  private mapArtifacts = new Map<string, string[]>(); // mapName -> artifact tokens

  constructor(private repoPath: string) {
    this.loadData();
  }

  refresh(): void {
    this.loadData();
    this._onDidChangeTreeData.fire(undefined);
  }

  private loadData(): void {
    // Load sequences
    const seqDir = path.join(this.repoPath, "commons", "maps", "sequences");
    const spinePath = path.join(this.repoPath, "commons", "maps", "curriculum_spine.json");

    let spineMap = new Map<string, { order: number; phase: string }>();
    if (fs.existsSync(spinePath)) {
      try {
        const spineData = JSON.parse(fs.readFileSync(spinePath, "utf-8"));
        const seqs = spineData.spine?.sequences || [];
        spineMap = new Map(
          seqs.map((s: { name: string; order: number; phase: string }) => [
            s.name,
            { order: s.order, phase: s.phase },
          ])
        );
      } catch { /* skip */ }
    }

    this.sequences = [];
    if (fs.existsSync(seqDir)) {
      for (const file of fs.readdirSync(seqDir).sort()) {
        if (!file.endsWith(".json") || file === "sequence_index.json") continue;
        try {
          const data = JSON.parse(fs.readFileSync(path.join(seqDir, file), "utf-8"));
          if (data.sequences && typeof data.sequences === "object" && !Array.isArray(data.sequences)) {
            for (const [seqId, seqData] of Object.entries(data.sequences as Record<string, Record<string, unknown>>)) {
              const spine = spineMap.get(seqId);
              this.sequences.push({
                id: seqId,
                name: (seqData.name as string) || seqId,
                maps: (seqData.maps as string[]) || [],
                isSpine: !!spine,
                spineOrder: spine?.order ?? 999,
              });
            }
          } else if (Array.isArray(data.maps)) {
            const seqId = path.basename(file, ".json");
            const spine = spineMap.get(seqId);
            this.sequences.push({
              id: seqId,
              name: (data.name as string) || seqId,
              maps: data.maps as string[],
              isSpine: !!spine,
              spineOrder: spine?.order ?? 999,
            });
          }
        } catch { /* skip */ }
      }
    }

    // Sort: spine first by order, then non-spine alphabetically
    this.sequences.sort((a, b) => {
      if (a.isSpine && !b.isSpine) return -1;
      if (!a.isSpine && b.isSpine) return 1;
      if (a.isSpine && b.isSpine) return a.spineOrder - b.spineOrder;
      return a.id.localeCompare(b.id);
    });

    // Build map -> artifacts lookup from map_data.json files
    this.mapArtifacts.clear();
    const mapsDir = path.join(this.repoPath, "commons", "maps");
    const allMapNames = new Set<string>();
    for (const seq of this.sequences) {
      for (const m of seq.maps) allMapNames.add(m);
    }

    for (const mapName of allMapNames) {
      const mapDataPath = path.join(mapsDir, mapName, "map_data.json");
      if (!fs.existsSync(mapDataPath)) continue;
      try {
        const data = JSON.parse(fs.readFileSync(mapDataPath, "utf-8"));
        const inter: string[][] = data.layers?.interactables || [];
        const tokens = new Set<string>();
        for (const row of inter) {
          for (const cell of row) {
            const c = (cell || "").trim();
            if (c && c !== " ") {
              tokens.add(c.split(":")[0]);
            }
          }
        }
        this.mapArtifacts.set(mapName, Array.from(tokens));
      } catch { /* skip */ }
    }
  }

  getTreeItem(element: TreeItemData): vscode.TreeItem {
    switch (element.type) {
      case "sequence": {
        const item = new vscode.TreeItem(
          element.sequence.name,
          vscode.TreeItemCollapsibleState.Collapsed
        );
        item.description = `${element.sequence.maps.length} maps`;
        item.iconPath = new vscode.ThemeIcon(
          element.sequence.isSpine ? "milestone" : "list-ordered"
        );
        item.tooltip = `Sequence: ${element.sequence.id}\n${element.sequence.maps.length} maps${
          element.sequence.isSpine ? " (spine)" : ""
        }`;
        return item;
      }
      case "map": {
        const artifacts = this.mapArtifacts.get(element.mapName) || [];
        const item = new vscode.TreeItem(
          element.mapName,
          artifacts.length > 0
            ? vscode.TreeItemCollapsibleState.Collapsed
            : vscode.TreeItemCollapsibleState.None
        );
        item.description = artifacts.length > 0 ? `${artifacts.length} artifacts` : "";
        item.iconPath = new vscode.ThemeIcon("map");
        return item;
      }
      case "artifact": {
        const item = new vscode.TreeItem(
          element.artifact.name || element.token,
          vscode.TreeItemCollapsibleState.None
        );
        item.description = element.artifact.complexity || "";
        item.iconPath = new vscode.ThemeIcon("symbol-class");
        item.command = {
          command: "ada.showArtifactTutorial",
          title: "Show Tutorial",
          arguments: [element.token],
        };
        item.tooltip = `${element.artifact.description}\n\nClick to view tutorial`;
        return item;
      }
    }
  }

  getChildren(element?: TreeItemData): TreeItemData[] {
    if (!element) {
      // Root: show sequences
      return this.sequences.map((seq) => ({
        type: "sequence" as const,
        sequence: seq,
      }));
    }

    if (element.type === "sequence") {
      return element.sequence.maps.map((mapName) => ({
        type: "map" as const,
        mapName,
        sequenceId: element.sequence.id,
      }));
    }

    if (element.type === "map") {
      const tokens = this.mapArtifacts.get(element.mapName) || [];
      const registries = loadRegistries(this.repoPath);
      const lookup = new Map<string, RegistryArtifact>();
      for (const reg of registries) {
        for (const [key, art] of Object.entries(reg.artifacts)) {
          lookup.set(art.lookupName || key, art);
        }
      }

      return tokens.map((token) => ({
        type: "artifact" as const,
        token,
        artifact: lookup.get(token) || {
          lookupName: token,
          name: token,
          description: "",
          scene: "",
          category: "",
          complexity: "",
          tags: [],
          sequence: "",
          mapSequences: [],
          mapReady: false,
        },
      }));
    }

    return [];
  }
}
