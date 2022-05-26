#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Please enter a git commit message"
  exit
fi

bundle exec jekyll build
mv _site /tmp/_site
git checkout -f master
rm -rf .
cp -r /tmp/_site .
rm -rf /tmp/_site
git add .
git commit -am "$1"
git push origin master
cd ..
echo "Successfully built and pushed to GitHub."
