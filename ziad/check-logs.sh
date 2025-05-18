#!/bin/bash

# This script helps check logs for troubleshooting

# Function to check logs of a specific pod
check_pod_logs() {
  POD_NAME=$1
  echo "=== Logs for $POD_NAME ==="
  kubectl logs -n frappe-men $POD_NAME
  echo "=========================="
}

# Function to describe a specific pod
describe_pod() {
  POD_NAME=$1
  echo "=== Details for $POD_NAME ==="
  kubectl describe pod -n frappe-men $POD_NAME
  echo "============================="
}

# Get all pod names
PODS=$(kubectl get pods -n frappe-men -o jsonpath="{.items[*].metadata.name}")

# Check status of all pods
echo "Current pod status:"
kubectl get pods -n frappe-men

# Menu for selecting which pod to check
echo ""
echo "Select a pod to check logs:"
select POD_NAME in $PODS "All Pods" "Exit"; do
  case $POD_NAME in
    "All Pods")
      for POD in $PODS; do
        check_pod_logs $POD
      done
      break
      ;;
    "Exit")
      exit 0
      ;;
    *)
      if [ -n "$POD_NAME" ]; then
        echo "1. View logs"
        echo "2. Describe pod"
        echo "3. Both"
        read -p "Select option: " OPTION
        case $OPTION in
          1)
            check_pod_logs $POD_NAME
            ;;
          2)
            describe_pod $POD_NAME
            ;;
          3)
            check_pod_logs $POD_NAME
            describe_pod $POD_NAME
            ;;
          *)
            echo "Invalid option"
            ;;
        esac
      else
        echo "Invalid selection"
      fi
      break
      ;;
  esac
done
