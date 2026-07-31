# Care Reports test portal

This local, dependency-free website is a target for the Robot Framework suites in `tasks/`.

## Install dependencies

```sh
python3 -m pip install -r requirements.txt
```

## Run the Robot suites directly

```sh
bash run_robot.sh
```

The script installs the required packages, starts the local portal automatically via the Robot tasks, and writes the reports under timestamped folders in the `logs/` tree.

The default selected quarter is configured in `variables/task_variables.resource` and is now `Q2`. The portal accepts any non-empty credentials.
