#!/bin/sh

# If a command fails then the deploy stops
set -e
cd docs && rm -rf *
cd ..
cp CNAME docs
cd _hugo
hugo -t reveal-hugo
mv public/* ../docs