"""
Auto Ctrl+Enter: Sends Ctrl+Enter every 60 seconds.
Useful for auto-submitting/running commands.

Usage:
    python tools/auto_ctrl_enter.py              # every 60s
    python tools/auto_ctrl_enter.py --interval 30  # every 30s
    python tools/auto_ctrl_enter.py --count 5      # only 5 times

Press Ctrl+C to stop.
"""

import sys
import time
import argparse

try:
    import pyautogui
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyautogui"])
    import pyautogui


def main():
    parser = argparse.ArgumentParser(description="Auto Ctrl+Enter every N seconds")
    parser.add_argument("--interval", type=int, default=60, help="Seconds between presses (default: 60)")
    parser.add_argument("--count", type=int, default=0, help="Number of times (0 = infinite)")
    args = parser.parse_args()

    print(f"Sending Ctrl+Enter every {args.interval}s")
    print("Press Ctrl+C to stop.\n")

    i = 0
    try:
        while True:
            i += 1
            if args.count > 0 and i > args.count:
                break
            pyautogui.hotkey("ctrl", "Return")
            print(f"[{i}] Ctrl+Enter sent at {time.strftime('%H:%M:%S')}")
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
