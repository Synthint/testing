#!/bin/bash


if [ -z "$1" ]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

NAMESPACE="$1"


for resource in $(kubectl api-resources --verbs=list --namespaced -o name); do
  if [[ "$resource" == "events" || "$resource" == "events.events.k8s.io" ]]; then
    continue
  fi
  for name in $(kubectl get "$resource" -n "$NAMESPACE" -o name 2>/dev/null); do
    echo "Patching $name in $resource..."
    kubectl patch "$name" -n "$NAMESPACE" --type=merge -p '{"metadata":{"finalizers":null}}' || echo "Failed to patch $name"
  done
done
