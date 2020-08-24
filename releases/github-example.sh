#!/usr/bin/env bash

git notes --ref features add -m "Actually none"
git notes --ref fixes add -m "Spelling corrected"
git notes --ref improve add -m "Better wording"
git notes --ref changes add -m "Second words"

github-tags.sh
git tag v1.0.2 -m "New Text Files" # required
git tag -l -n
git push --tags # required
github-tags.sh

github-notes.sh > NOTES.md # required
macdown NOTES.md

github-release.sh
github-release.sh -c create -F NOTES.md # required
github-release.sh

github-assets.sh -c create -f bootstrap-macos.sh # required
github-assets.sh -c create -f bootstrap-unix.sh # required
github-assets.sh

github-release.sh -s -c read
github-release.sh -s -c read -v
