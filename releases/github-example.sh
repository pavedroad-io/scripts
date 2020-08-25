#!/usr/bin/env bash

git notes --ref features append -m "Some new feature"
git notes --ref fixes append -m "Spelling corrected"
git notes --ref improve append -m "Better wording"
git notes --ref changes append -m "Capitalize titles"

github-tags.sh
git tag v1.0.2 -m "New Text Files" # required
git tag -l -n
git push --tags # required
github-tags.sh

github-notes.sh > NOTES.md # required

github-release.sh
github-release.sh -c create -F NOTES.md # required
github-release.sh

github-assets.sh -c create -f bootstrap-macos.sh
github-assets.sh -c create -f bootstrap-unix.sh
github-assets.sh

github-release.sh -s -c read
github-release.sh -s -c read -v
