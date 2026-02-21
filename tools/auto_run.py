"""
Auto-run: Find the window with 'Antigravity' in the title and click the Run button.
Uses pyautogui + pygetwindow for Windows GUI automation.

Usage:
    python tools/auto_run.py
    python tools/auto_run.py --key f5       # Send F5 instead of clicking
    python tools/auto_run.py --find-only    # Just find and list matching windows
"""

import sys
import time

try:
    import pyautogui
    import pygetwindow as gw
except ImportError:
    print("Installing required packages...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyautogui", "pygetwindow"])
    import pyautogui
    import pygetwindow as gw


def find_antigravity_window():
    """Find window with 'Antigravity' in the title."""
    all_windows = gw.getAllWindows()
    matches = []
    for w in all_windows:
        if w.title and "antigravity" in w.title.lower():
            matches.append(w)
    return matches


def list_all_windows(filter_text=None):
    """List all visible windows, optionally filtered."""
    all_windows = gw.getAllWindows()
    for w in all_windows:
        if not w.title.strip():
            continue
        if filter_text and filter_text.lower() not in w.title.lower():
            continue
        print(f"  [{w.width}x{w.height}] {w.title}")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Find Antigravity window and send Run command")
    parser.add_argument("--key", default="f5", help="Key to send (default: f5)")
    parser.add_argument("--find-only", action="store_true", help="Just list matching windows")
    parser.add_argument("--list-all", action="store_true", help="List all windows")
    parser.add_argument("--search", default="antigravity", help="Window title search term (default: antigravity)")
    args = parser.parse_args()

    if args.list_all:
        print("All visible windows:")
        list_all_windows()
        return

    search = args.search
    print(f"Searching for windows with '{search}' in title...")
    
    matches = []
    all_windows = gw.getAllWindows()
    for w in all_windows:
        if w.title and search.lower() in w.title.lower():
            matches.append(w)

    if not matches:
        print(f"No window found with '{search}' in title.")
        print("\nAll visible windows:")
        list_all_windows()
        return

    print(f"Found {len(matches)} matching window(s):")
    for i, w in enumerate(matches):
        print(f"  [{i}] {w.title}  ({w.width}x{w.height} at {w.left},{w.top})")

    if args.find_only:
        return

    # Use the first match
    target = matches[0]
    print(f"\nActivating: {target.title}")
    
    try:
        target.activate()
        time.sleep(0.3)  # Wait for focus
    except Exception as e:
        print(f"Warning: activate failed ({e}), trying minimize/restore...")
        try:
            target.minimize()
            time.sleep(0.2)
            target.restore()
            time.sleep(0.3)
        except Exception as e2:
            print(f"Could not activate window: {e2}")
            return

    print(f"Sending key: {args.key}")
    pyautogui.press(args.key)
    print("Done!")


if __name__ == "__main__":
    main()
