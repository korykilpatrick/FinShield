#!/bin/bash
# get_tree.sh – generate a project tree excluding config files/folders and docs

# Change to the project root (assumes this script lives in the scripts/ directory)
cd "$(dirname "$0")/.."

# Run tree while ignoring common config files and docs; output to project_tree.txt
tree -I "firebase.json|firestore.indexes.json|firestore.rules|storage.rules|GoogleService-Info.plist|docs|config" > project_tree.txt

echo "Project tree generated in project_tree.txt"