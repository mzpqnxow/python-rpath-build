#!/bin/bash
# Use for recreating pyboot3 packages directory
# Nobody needs this except me :>
PATHS=('3.10.7' '3.11.4' '3.7.17' '3.8.17' '3.9.17')
for path in ${PATHS[@]}; do
  export PATH="/opt/Python-$path/bin:$PATH"
done
REQS="pyboot3-dev-reqs.txt"
cat > "$REQS" << 'EOF'
appdirs
distlib
filelock
importlib-metadata
importlib-resources
packaging
pyparsing
PySocks
setuptools-scm
six
virtualenv
zipp
toml
pip
EOF
for v in 3.6 3.7 3.8 3.9 3.10 3.11; do
  python="python$v"
  if ! command -v "$python" 2>&- >&-; then
    echo Python v$v not found, skipping ...
    continue
  fi
  echo Building for $python ...
  "$python" -mpip install --use-feature=no-binary-enable-wheel-cache  -I --root "$(realpath py$v)" --upgrade --no-binary :all: -r "$REQS" --no-warn-script-location
done
