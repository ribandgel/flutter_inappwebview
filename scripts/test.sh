#!/bin/bash

readonly SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
readonly PROJECT_DIR="$(dirname $SCRIPT_PATH)"

function error() {
  echo "$@" 1>&2
}

# on macOS local IP can be found using something like $(ipconfig getifaddr en0)
# on linux local IP can be found using something like $(ifconfig en0 | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}') or $(ip route get 1 | awk '{print $NF;exit}')
export NODE_SERVER_IP=$1
PLATFORM=$2
FAILED=0

if [ $PLATFORM = "web" ]; then
  $PROJECT_DIR/tool/chromedriver --port=4444 &
fi

dart $PROJECT_DIR/tool/env.dart

cd $PROJECT_DIR/nodejs_server_test_auth_basic_and_ssl
node index.js &

flutter --version
flutter clean
cd $PROJECT_DIR/example
flutter clean
if [ $PLATFORM = "web" ]; then
  flutter driver --driver=test_driver/integration_test.dart --target=integration_test/webview_flutter_test.dart  --device-id=chrome
else
  flutter driver --driver=test_driver/integration_test.dart --target=integration_test/webview_flutter_test.dart
fi

if [ $? -eq 0 ]; then
  echo "Integration tests passed successfully."
else
  error "Some integration tests failed."
  FAILED=1
fi

jobs -p | xargs kill

exit $FAILED