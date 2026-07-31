#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

python3 -m pip install -r requirements.txt

python3 -m robot --outputdir "$ROOT_DIR/logs" --logtitle "Robot Bot Log" --reporttitle "Robot Bot Report" "$ROOT_DIR/tasks/annual_well_visit_task.robot" "$ROOT_DIR/tasks/er_visits_task.robot" "$ROOT_DIR/tasks/ip_admissions_task.robot"
