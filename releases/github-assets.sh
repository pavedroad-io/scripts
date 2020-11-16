#!/usr/bin/env bash

asset="true"

source github-api.sh

if [ "$quiet" != "true" ]; then
    echo; echo Uploaded assets:
    read_assets

    echo; echo Uploaded asset-ids:
    read_assets_id
fi

if [ ! -z $command ]; then
    message; message ${command^} asset:
    case ${command} in
        create) create_asset;;
        read) read_asset;;
        update) update_asset;;
        delete) delete_asset;;
    esac
fi

