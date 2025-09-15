import yaml
import json
import sys

with open("pass_creator_job.yaml") as f:
    data = yaml.safe_load(f)

print(json.dumps(data, indent=2))
