#!/usr/bin/env python3
"""Test if Python ARM64 can spawn x64 Rscript subprocess.

This determines if the issue is Deno-specific or general Windows ARM limitation.
"""

import subprocess
import sys
import platform

def main():
    if len(sys.argv) < 3:
        print("Usage: python test-python-rscript.py <rscript_path> <script_path>")
        sys.exit(1)

    rscript_path = sys.argv[1]
    script_path = sys.argv[2]

    print("Testing Python subprocess spawning of x64 Rscript...")
    print(f"Python version: {sys.version}")
    print(f"Python arch: {platform.machine()}")
    print(f"Rscript: {rscript_path}")
    print(f"Script: {script_path}")
    print()

    try:
        result = subprocess.run(
            [rscript_path, script_path],
            capture_output=True,
            text=True,
            timeout=30
        )

        print(f"Exit code: {result.returncode}")
        print("Stdout:")
        print(result.stdout)

        if result.stderr:
            print("Stderr:")
            print(result.stderr)

        if result.returncode == 0:
            print("\n✅ Python subprocess spawn SUCCEEDED")
            print("This means the issue is Deno-specific, not a general Windows ARM limitation")
            sys.exit(0)
        else:
            print(f"\n❌ Python subprocess spawn FAILED with exit code {result.returncode}")
            print("This means the issue affects multiple runtimes, not just Deno")
            sys.exit(1)

    except Exception as error:
        print(f"\n❌ Python subprocess spawn threw exception:")
        print(error)
        sys.exit(1)

if __name__ == "__main__":
    main()
