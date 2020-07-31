#!/bin/bash
set -e

WORKDIR="$(pwd)"

# get absolute paths
cd "$(dirname $0)/.."
PROJDIR="$(pwd)"
OUTDIR="$PROJDIR/lib"

cd "../Infrastructure/tool/codegen"
CODEGEN="$(pwd)"

cd "$CODEGEN"

# generate the file(s)
dart bin/generate_firebase_model.dart "$OUTDIR/model.yaml"

# assert that the generated file is valid Dart
dartanalyzer --packages "$PROJDIR/.packages" "$OUTDIR/model.g.dart"
