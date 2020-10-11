#!/usr/bin/env bash

asset="false"

source github-api.sh

if [ "$quiet" != "true" ]; then
    echo; echo Release tags:
    latest=false read_tags

    echo; echo Published releases:
    lastest=false read_releases

    if [ "$latest" == "true" ]; then
        echo; echo Latest release:
        read_latest
    fi

    if [ "$draft" == "true" ]; then
        echo; echo Draft releases:
        latest=false read_drafts
    fi

    if [ "$prerel" == "true" ]; then
        echo; echo Prerelease releases:
        latest=false read_prerels
    fi
fi

if [ ! -z $command ]; then
    message; message ${command^} release:
    case ${command} in
        create) create_release;;
        read) read_release;;
        update) update_release;;
        delete) delete_release;;
    esac
fi

