#!/usr/bin/env bash
# Type-checks plugins/with-gradle-properties.ts, a config plugin that hands withGradleProperties and
# AndroidConfig.Properties.propertiesListToString a readonly PropertiesItem[], with strict. Exits 1 while either refuses
# the readonly list, 0 once the plugin type-checks, and 2 when a step fails or another error shows.
set -uo pipefail

cd "$(dirname "$0")" || exit 2

package_version() {
  node -p "require('./node_modules/$1/package.json').version" 2>/dev/null || printf 'not installed'
}

if [ ! -d node_modules ]; then
  if ! npm ci --no-audit --no-fund >install.log 2>&1; then
    tail -n 20 install.log
    echo "SUMMARY: step failed: npm ci (install.log)"
    exit 2
  fi
fi

system_name=$(uname -s) || exit 2
node_version=$(node --version) || exit 2
npm_version=$(npm --version) || exit 2
package_versions=""
for package in expo @expo/config-plugins typescript; do
  version=$(package_version "$package") || exit 2
  package_versions+=", $package $version"
done
echo "System: $system_name, node $node_version, npm $npm_version$package_versions"

npx --no-install tsc -p tsconfig.plugins.json --pretty false --listFiles >compiler-output.txt 2>&1
compiler_status=$?
if [ "$compiler_status" -gt 2 ] || ! grep -q -E '/lib\.es5\.d\.ts$' compiler-output.txt; then
  tail -n 20 compiler-output.txt
  echo "SUMMARY: step failed: tsc exited $compiler_status without listing its files (compiler-output.txt)"
  exit 2
fi

errors=$(grep -E '^[^ ]+\([0-9]+,[0-9]+\): error TS[0-9]+:' compiler-output.txt)
if [ -z "$errors" ]; then
  echo "SUMMARY: fixed: the plugin hands both a readonly PropertiesItem[] and type-checks"
  exit 0
fi
# Each error with the lines that explain it, one per line, so an error is judged with its explanation.
blocks=$(awk '/^[^ ].*\([0-9]+,[0-9]+\): error TS[0-9]+:/ { if (block != "") print block; block = $0; next }
  /^ / { if (block != "") block = block " |" $0; next }
  { if (block != "") print block; block = "" }
  END { if (block != "") print block }' compiler-output.txt)
readonly_refusal="is 'readonly' and cannot be assigned to the mutable type 'PropertiesItem\[\]'"
refusals=$(grep -E "^plugins/with-gradle-properties\.ts\(" <<<"$blocks" | grep -E "$readonly_refusal")
others=$(grep -v -E "$readonly_refusal" <<<"$blocks")
if [ -n "$others" ]; then
  echo "$others"
  echo "SUMMARY: step failed: errors other than a refused readonly PropertiesItem[]"
  exit 2
fi
echo "$errors"
count=$(grep -c '' <<<"$refusals")
echo "SUMMARY: defect: $count call(s) refuse a readonly PropertiesItem[], taking only the mutable PropertiesItem[]"
exit 1
