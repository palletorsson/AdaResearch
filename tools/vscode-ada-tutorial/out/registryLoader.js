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
exports.loadRegistries = loadRegistries;
exports.buildLookupIndex = buildLookupIndex;
exports.buildDirIndex = buildDirIndex;
exports.findArtifactByFilePath = findArtifactByFilePath;
exports.clearCache = clearCache;
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
let cachedRegistries = null;
let byLookupName = null;
let byDirName = null;
function loadRegistries(repoPath) {
    if (cachedRegistries)
        return cachedRegistries;
    const registryDir = path.join(repoPath, "commons", "artifacts", "registry");
    if (!fs.existsSync(registryDir))
        return [];
    const registries = [];
    for (const file of fs.readdirSync(registryDir)) {
        if (!file.endsWith(".json"))
            continue;
        try {
            const raw = fs.readFileSync(path.join(registryDir, file), "utf-8");
            const data = JSON.parse(raw);
            const id = path.basename(file, ".json");
            const artifacts = {};
            for (const [key, val] of Object.entries(data.artifacts || {})) {
                const a = val;
                artifacts[key] = {
                    lookupName: a.lookup_name || key,
                    name: a.name || key,
                    description: a.description || "",
                    scene: a.scene || "",
                    category: a.category || "",
                    complexity: a.complexity || "",
                    tags: a.tags || [],
                    sequence: a.sequence || "",
                    mapSequences: a.map_sequences || [],
                    mapReady: a.map_ready || false,
                };
            }
            registries.push({
                id,
                name: data.name || id,
                artifacts,
            });
        }
        catch {
            /* skip malformed */
        }
    }
    cachedRegistries = registries;
    return registries;
}
function buildLookupIndex(repoPath) {
    if (byLookupName)
        return byLookupName;
    byLookupName = new Map();
    for (const reg of loadRegistries(repoPath)) {
        for (const [key, artifact] of Object.entries(reg.artifacts)) {
            const token = artifact.lookupName || key;
            byLookupName.set(token, artifact);
        }
    }
    return byLookupName;
}
function buildDirIndex(repoPath) {
    if (byDirName)
        return byDirName;
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
function findArtifactByFilePath(filePath, repoPath) {
    const dirIndex = buildDirIndex(repoPath);
    // Try parent directory name
    const dirName = path.basename(path.dirname(filePath));
    if (dirIndex.has(dirName)) {
        return dirIndex.get(dirName);
    }
    // Try filename without extension
    const baseName = path.basename(filePath, ".gd");
    if (dirIndex.has(baseName)) {
        return dirIndex.get(baseName);
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
function clearCache() {
    cachedRegistries = null;
    byLookupName = null;
    byDirName = null;
}
//# sourceMappingURL=registryLoader.js.map