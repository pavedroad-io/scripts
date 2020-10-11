#!/usr/bin/env bash

asset="true"

source github-api.sh

# Download source tarball or zipball with option -s tgz or -s zip
if [ ! -z $source_type ]; then
    source_url=$(read_source_url)
    if [ $? -ne 0 ]; then
        echo $source_url
        exit 1
    fi

    if [ "$url_only" == "true" ]; then
        # Just print URL if option -u is set
        echo $source_url
    else
        file_name=$(basename $repo)-$tag.$source_type
        echo Downloading $file_name
        curl -sLo $file_name $source_url
    fi
    exit
fi

# Otherwise download file based on asset name or asset ID
asset_url=$(read_asset_url)
if [ $? -ne 0 ]; then
    echo $asset_url
    exit 1
fi

if [ "$url_only" == "true" ]; then
    # Just print URL if option -u is set
    echo $asset_url
else
    if [ -z $asset_file ]; then
        asset_file=$(verbose=false identify=false read_asset)
    fi
    file_name=${asset_file%.*}-$tag
    extension=${asset_file##*.}
    if [ $extension != "" ]; then
        file_name=${file_name}.${extension}
    fi
    echo Downloading $file_name
    curl -sLo $file_name $asset_url
fi
