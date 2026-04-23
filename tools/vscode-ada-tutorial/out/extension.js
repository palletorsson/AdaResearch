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
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const path = __importStar(require("path"));
const registryLoader_1 = require("./registryLoader");
const webviewProvider_1 = require("./webviewProvider");
const artifactTreeProvider_1 = require("./artifactTreeProvider");
let statusBarItem;
function getRepoPath() {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders)
        return null;
    for (const folder of folders) {
        const p = folder.uri.fsPath;
        // Check if this is Ada Research repo
        const registryDir = path.join(p, "commons", "artifacts", "registry");
        try {
            const fs = require("fs");
            if (fs.existsSync(registryDir))
                return p;
        }
        catch {
            continue;
        }
    }
    return null;
}
function activate(context) {
    const repoPath = getRepoPath();
    if (!repoPath) {
        // Not an Ada Research workspace — silently skip activation
        return;
    }
    // Status bar item
    statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
    statusBarItem.command = "ada.showArtifactTutorial";
    context.subscriptions.push(statusBarItem);
    // Tree view
    const treeProvider = new artifactTreeProvider_1.ArtifactTreeProvider(repoPath);
    vscode.window.registerTreeDataProvider("adaArtifactTree", treeProvider);
    // Command: show artifact tutorial
    context.subscriptions.push(vscode.commands.registerCommand("ada.showArtifactTutorial", async (tokenArg) => {
        let token = tokenArg;
        if (!token) {
            // Try to detect from active editor
            const editor = vscode.window.activeTextEditor;
            if (editor && editor.document.fileName.endsWith(".gd")) {
                token = (0, registryLoader_1.findArtifactByFilePath)(editor.document.fileName, repoPath) ?? undefined;
            }
            if (!token) {
                // Show quick pick
                const input = await vscode.window.showInputBox({
                    prompt: "Enter artifact lookup name (e.g., turing_pattern_generator)",
                    placeHolder: "artifact_token",
                });
                if (!input)
                    return;
                token = input;
            }
        }
        await (0, webviewProvider_1.showTutorial)(token, repoPath, context);
    }));
    // Command: refresh tree
    context.subscriptions.push(vscode.commands.registerCommand("ada.refreshArtifactTree", () => {
        (0, registryLoader_1.clearCache)();
        treeProvider.refresh();
    }));
    // Track active editor to update status bar
    context.subscriptions.push(vscode.window.onDidChangeActiveTextEditor((editor) => {
        if (editor && editor.document.fileName.endsWith(".gd")) {
            const token = (0, registryLoader_1.findArtifactByFilePath)(editor.document.fileName, repoPath);
            if (token) {
                statusBarItem.text = `$(book) ${token}`;
                statusBarItem.tooltip = "Click to open artifact tutorial";
                statusBarItem.show();
            }
            else {
                statusBarItem.hide();
            }
        }
        else {
            statusBarItem.hide();
        }
    }));
    // Check current editor on activation
    const activeEditor = vscode.window.activeTextEditor;
    if (activeEditor && activeEditor.document.fileName.endsWith(".gd")) {
        const token = (0, registryLoader_1.findArtifactByFilePath)(activeEditor.document.fileName, repoPath);
        if (token) {
            statusBarItem.text = `$(book) ${token}`;
            statusBarItem.tooltip = "Click to open artifact tutorial";
            statusBarItem.show();
        }
    }
}
function deactivate() {
    // Cleanup handled by disposables
}
//# sourceMappingURL=extension.js.map