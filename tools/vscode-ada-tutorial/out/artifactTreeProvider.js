"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ArtifactTreeProvider = void 0;
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const registryLoader_1 = require("./registryLoader");
class ArtifactTreeProvider {
    constructor(repoPath) {
        this.repoPath = repoPath;
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
        this.sequences = [];
        this.mapArtifacts = new Map(); // mapName -> artifact tokens
        this.loadData();
    }
    refresh() {
        this.loadData();
        this._onDidChangeTreeData.fire(undefined);
    }
    loadData() {
        // Load sequences
        const seqDir = path.join(this.repoPath, "commons", "maps", "sequences");
        const spinePath = path.join(this.repoPath, "commons", "maps", "curriculum_spine.json");
        let spineMap = new Map();
        if (fs.existsSync(spinePath)) {
            try {
                const spineData = JSON.parse(fs.readFileSync(spinePath, "utf-8"));
                const seqs = spineData.spine?.sequences || [];
                spineMap = new Map(seqs.map((s) => [
                    s.name,
                    { order: s.order, phase: s.phase },
                ]));
            }
            catch { /* skip */ }
        }
        this.sequences = [];
        if (fs.existsSync(seqDir)) {
            for (const file of fs.readdirSync(seqDir).sort()) {
                if (!file.endsWith(".json") || file === "sequence_index.json")
                    continue;
                try {
                    const data = JSON.parse(fs.readFileSync(path.join(seqDir, file), "utf-8"));
                    if (data.sequences && typeof data.sequences === "object" && !Array.isArray(data.sequences)) {
                        for (const [seqId, seqData] of Object.entries(data.sequences)) {
                            const spine = spineMap.get(seqId);
                            this.sequences.push({
                                id: seqId,
                                name: seqData.name || seqId,
                                maps: seqData.maps || [],
                                isSpine: !!spine,
                                spineOrder: spine?.order ?? 999,
                            });
                        }
                    }
                    else if (Array.isArray(data.maps)) {
                        const seqId = path.basename(file, ".json");
                        const spine = spineMap.get(seqId);
                        this.sequences.push({
                            id: seqId,
                            name: data.name || seqId,
                            maps: data.maps,
                            isSpine: !!spine,
                            spineOrder: spine?.order ?? 999,
                        });
                    }
                }
                catch { /* skip */ }
            }
        }
        // Sort: spine first by order, then non-spine alphabetically
        this.sequences.sort((a, b) => {
            if (a.isSpine && !b.isSpine)
                return -1;
            if (!a.isSpine && b.isSpine)
                return 1;
            if (a.isSpine && b.isSpine)
                return a.spineOrder - b.spineOrder;
            return a.id.localeCompare(b.id);
        });
        // Build map -> artifacts lookup from map_data.json files
        this.mapArtifacts.clear();
        const mapsDir = path.join(this.repoPath, "commons", "maps");
        const allMapNames = new Set();
        for (const seq of this.sequences) {
            for (const m of seq.maps)
                allMapNames.add(m);
        }
        for (const mapName of allMapNames) {
            const mapDataPath = path.join(mapsDir, mapName, "map_data.json");
            if (!fs.existsSync(mapDataPath))
                continue;
            try {
                const data = JSON.parse(fs.readFileSync(mapDataPath, "utf-8"));
                const inter = data.layers?.interactables || [];
                const tokens = new Set();
                for (const row of inter) {
                    for (const cell of row) {
                        const c = (cell || "").trim();
                        if (c && c !== " ") {
                            tokens.add(c.split(":")[0]);
                        }
                    }
                }
                this.mapArtifacts.set(mapName, Array.from(tokens));
            }
            catch { /* skip */ }
        }
    }
    getTreeItem(element) {
        switch (element.type) {
            case "sequence": {
                const item = new vscode.TreeItem(element.sequence.name, vscode.TreeItemCollapsibleState.Collapsed);
                item.description = `${element.sequence.maps.length} maps`;
                item.iconPath = new vscode.ThemeIcon(element.sequence.isSpine ? "milestone" : "list-ordered");
                item.tooltip = `Sequence: ${element.sequence.id}\n${element.sequence.maps.length} maps${element.sequence.isSpine ? " (spine)" : ""}`;
                return item;
            }
            case "map": {
                const artifacts = this.mapArtifacts.get(element.mapName) || [];
                const item = new vscode.TreeItem(element.mapName, artifacts.length > 0
                    ? vscode.TreeItemCollapsibleState.Collapsed
                    : vscode.TreeItemCollapsibleState.None);
                item.description = artifacts.length > 0 ? `${artifacts.length} artifacts` : "";
                item.iconPath = new vscode.ThemeIcon("map");
                return item;
            }
            case "artifact": {
                const item = new vscode.TreeItem(element.artifact.name || element.token, vscode.TreeItemCollapsibleState.None);
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
    getChildren(element) {
        if (!element) {
            // Root: show sequences
            return this.sequences.map((seq) => ({
                type: "sequence",
                sequence: seq,
            }));
        }
        if (element.type === "sequence") {
            return element.sequence.maps.map((mapName) => ({
                type: "map",
                mapName,
                sequenceId: element.sequence.id,
            }));
        }
        if (element.type === "map") {
            const tokens = this.mapArtifacts.get(element.mapName) || [];
            const registries = (0, registryLoader_1.loadRegistries)(this.repoPath);
            const lookup = new Map();
            for (const reg of registries) {
                for (const [key, art] of Object.entries(reg.artifacts)) {
                    lookup.set(art.lookupName || key, art);
                }
            }
            return tokens.map((token) => ({
                type: "artifact",
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
exports.ArtifactTreeProvider = ArtifactTreeProvider;
//# sourceMappingURL=artifactTreeProvider.js.map