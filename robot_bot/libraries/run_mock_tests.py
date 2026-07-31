"""Run every Robot report flow against the bundled local test portal.

Results are written to logs/<report-name>/ as output.xml, log.html, and
report.html, making each bot's execution easy to debug independently.
"""

from __future__ import annotations

import datetime
import functools
import http.server
import subprocess
import sys
import threading
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PORTAL_ROOT = ROOT / "tests"
SERVER_ADDRESS = ("127.0.0.1", 8000)
TASKS = {
    "annual_well_visit": "tasks/annual_well_visit_task.robot",
    "er_visits": "tasks/er_visits_task.robot",
    "ip_admissions": "tasks/ip_admissions_task.robot",
}


def build_output_dir(name: str, timestamp: str | None = None) -> Path:
    """Return the timestamped directory used for Robot output artifacts."""
    run_timestamp = timestamp or datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = ROOT / "logs" / name / run_timestamp
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def main() -> int:
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(PORTAL_ROOT))
    server = http.server.ThreadingHTTPServer(SERVER_ADDRESS, handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    print("Local test portal started at http://127.0.0.1:8000")

    failures = 0
    try:
        for name, task in TASKS.items():
            output_dir = build_output_dir(name)
            print(f"\nRunning {name} -> {output_dir}")
            result = subprocess.run(
                ["robot", "--outputdir", str(output_dir), str(ROOT / task)],
                cwd=ROOT,
                check=False,
            )
            failures += result.returncode != 0
    finally:
        server.shutdown()
        server.server_close()

    return int(failures > 0)


if __name__ == "__main__":
    raise SystemExit(main())
