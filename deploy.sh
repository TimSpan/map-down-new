#!/usr/bin/env sh
set -e
npm run build
cd dist
git init
git add -A
git commit -m 'deploy'
# git push -f git@github.com:TimSpan/myx.git main:pages
git push -f https://github.com/TimSpan/map-down-new.git master:pages


cd -
