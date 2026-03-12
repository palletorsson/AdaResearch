extends Resource
class_name TutorialGitTimeline

const TEXT = """
# 🐙 Music as Version Control
### The Git Timeline Graph

This work visualizes music composition as a series of **commits** in a version control system.

1.  **Master Branch (Blue)**: The main trunk of the timeline. It represents the stable, canonical melody that loops indefinitely.
2.  **Feature Branches (Green/Orange)**: Experimental divergences.
    *   At specific 'fork points', the playback cursor may choose to branch off.
    *   **Feature A (Green)**: A melodic variation that eventually **merges** back into Master.
    *   **Feature B (Orange)**: A bass-heavy infinite loop (a 'dev branch' that never merges).

### Graph Theory & Chance
Unlike a static timeline, this graph is traversed probabilistically.
*   **Forks**: High intensity increases the likelihood of entering a Feature Branch.
*   **Merges**: Rejoining the main trunk resolves the musical tension.

This structure mirrors decision trees in narrative design and branching logic in software development.
"""

