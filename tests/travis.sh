#!/bin/bash
set -o nounset
set -o errexit

npm install -g cordova
npm install

# lint
npm run lint

# run tests appropriate for platform
if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    sudo gem install cocoapods
    npm install -g ios-sim ios-deploy
    npm run test:ios
fi
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    android list targets
    echo no | android create avd --force -n test -t android-21 --abi armeabi-v7a
    emulator -avd test -no-audio -no-window &
    android-wait-for-emulator
    npm run test:android
fi