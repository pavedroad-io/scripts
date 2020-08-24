#!/usr/bin/env bash

source github-api.sh

echo; echo read_tags:
read_tags

echo; echo read_latest:
read_latest

echo; echo read_rel_id:
read_rel_id

echo; echo read_rel_tag:
read_rel_tag

echo; echo read_releases:
read_releases

echo; echo read_releases_id:
read_releases_id

echo; echo read_drafts:
read_drafts

echo; echo read_prerels:
read_prerels

echo; echo read_latest_id:
read_latest_id

echo; echo read_rel_tag_id:
read_rel_tag_id

echo; echo read_assets:
read_assets

echo; echo read_assets_id:
read_assets_id

if [ ! -z $command ]; then
    echo; echo command $command:
    if [ "$asset" == "true" ]; then
        case ${command} in
            create) create_asset;;
            read) read_asset;;
            update) update_asset;;
            delete) delete_asset;;
        esac
    else
        case ${command} in
            create) create_release;;
            read) read_release;;
            update) update_release;;
            delete) delete_release;;
        esac
    fi
fi

