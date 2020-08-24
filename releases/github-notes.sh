#!/usr/bin/env bash

# list of notes-refs used for release notes
notes_refs=(features fixes improve changes)
declare -A notes_titles=(
    [features]="New Features"
    [fixes]="Bug Fixes"
    [improve]="Improvements"
    [changes]="Other Changes"
)

release_notes() {
    title=$(git tag -l --format='%(subject)' $latest)
    echo "# Release Notes for $latest - $title"
    # get all notes for each note ref type
    for ref in "${notes_refs[@]}"; do
        echo; echo "## ${notes_titles[${ref}]}"
        # get all commits between tags
        for rev in $(git rev-list $latest...$previous); do
            if git notes --ref $ref list $rev &> /dev/null; then
                note=$(git notes --ref $ref show $rev)
                echo "- $note"
            fi
        done
    done
}

if [ "$#" -eq 0 ]; then
    previous=$(git describe --abbrev=0 --tags $(git rev-list --tags --skip=1 --max-count=1))
    latest=$(git describe --abbrev=0 --tags)
elif [ "$#" -eq 2 ]; then
    previous=$1
    latest=$2
else
    echo "Usage:    $(basename $0) [<from-tag> <to-tag>]" >&2
    echo "Includes: notes after <from-tag> up to and incuding <to-tag>" >&2
    echo "Defaults: <from-tag> is previous tag, <to-tag> is latest tag" >&2
    echo "Output:   writes notes in markdown format to stdout" >&2
    exit
fi

echo "<from-tag>: $previous <to-tag>: $latest" >&2

release_notes
