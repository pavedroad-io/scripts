# github api common variable and functions
# sourced from other files
# Thus no #!/usr/bin/env bash
# In order to not spawn another shell

usage() {
cat << EOF
Usage: $(basename $0) [<option> ... <option value> ...]
Options that require an argument show <value> in brackets
Valid options:
-a asset set
-b <branch>
-c <command>
-d draft set
-f <asset_file>
-F <notes_file>
-h help
-i <release_id>
-I <asset_id>
-l latest set
-m <message>
-n dryrun set
-p prerelease set
-r <repo>
-s silent set
-t <tag>
-v verbose set
-w warning set
Valid command arguments:
-c create
-c read
-c update
-c delete
EOF
exit 1
}

validate_token() {
    response=$(curl -sH "$github_auth" $github_repo)
    local message=$(echo $response | jq '.message')
    if [ "$message" != "null" ]; then
        echo Error: $message
        echo Check value of environmant variable PR_GITHUB_RELEASE_TOKEN
        exit 1
    fi
}

set_body() {
body=$(cat <<EOF
{
  "tag_name": "$tag",
  "target_commitish": "$branch",
  "name": "$tag",
  "body": "$message",
  "draft": $draft,
  "prerelease": $prerel
}
EOF
)
}

show_item() {
    if [ "${verbose}" == "true" ] ; then
        echo $response | jq "."
    else
        echo $response | jq -r ".$field"
    fi
}

show_array() {
    if [ "${latest}" == "true" ] ; then
        if [ "${verbose}" == "true" ] ; then
            echo $response | jq ".[0]"
        else
            echo $response | jq -r ".[0].$field"
        fi
    else
        if [ "${verbose}" == "true" ] ; then
            echo $response | jq "."
        else
            echo $response | jq -r ".[].$field"
        fi
    fi
}

read_tags() {
    response=$(curl -sH "$github_auth" $github_tags)
    field=name show_array
}

read_latest() {
    response=$(curl -sH "$github_auth" $github_latest)
    field=name show_item
}

read_rel_id() {
    response=$(curl -sH "$github_auth" $github_release_id)
    field=name show_item
}

read_rel_tag() {
    response=$(curl -sH "$github_auth" $github_rel_tag)
    field=name show_item
}

read_releases() {
    response=$(curl -sH "$github_auth" $github_rels)
    field=name show_array
}

read_releases_id() {
    response=$(curl -sH "$github_auth" $github_rels)
    field=id show_array
}

read_drafts() {
    response=$(curl -sH "$github_auth" $github_rels)
    response=$(echo $response | jq ".[] | select(.draft == true)")
    response=$(echo $response | jq -s ".")
    field=name show_array
}

read_prerels() {
    response=$(curl -sH "$github_auth" $github_rels)
    response=$(echo $response | jq ".[] | select(.prerelease == true)")
    response=$(echo $response | jq -s ".")
    field=name show_array
}

read_latest_id() {
    response=$(curl -sH "$github_auth" $github_latest)
    field=id show_item
}

read_rel_tag_id() {
    response=$(curl -sH "$github_auth" $github_rel_tag)
    field=id show_item
}

create_release() {
    set_body
    response=$(curl -sH "$github_auth" -d "$body" $github_rels)
    field=name show_item
    field=id show_item
}

read_release() {
    if [ "$release_id" == "null" ]; then
        echo Error: read_release: release_id is null
        return 1
    fi
    response=$(curl -sH "$github_auth" -d "$body" $github_release_id)
    field=name show_item
}

update_release() {
    if [ "$release_id" == "null" ]; then
        echo Error: update_release: release_id is null
        return 1
    fi
    set_body
    response=$(curl -X "PATCH" -sH "$github_auth" -d "$body" $github_release_id)
    field=name show_item
}

delete_release() {
    if [ "$release_id" == "null" ]; then
        echo Error: delete_release: release_id is null
        return 1
    fi
    response=$(curl -X "DELETE" -sH "$github_auth" $github_release_id)
}

read_assets() {
    response=$(curl -sH "$github_auth" $github_assets)
    field=name show_array
}

read_assets_id() {
    response=$(curl -sH "$github_auth" $github_assets)
    field=id show_array
}

read_asset_file_id() {
    if [ -z "$file" ]; then
        echo Error: read_asset_file_id: File must be specified
        return 1
    fi
    response=$(curl -sH "$github_auth" $github_assets)
    response=$(echo $response | jq --arg f "$file" '.[] | select(.name == $f)')
    field=id show_item
}

identify_asset() {
    [ "$identify" == "false" ] && return 0
    if [ -z "$file" ] && [ -z "$asset_id" ]; then
        echo Error: identify_asset: File or asset_id must be specified
        return 1
    fi

    if [ -z "$asset_id" ]; then
        local my_asset_id=$(verbose=false read_asset_file_id)
        if [ -z $my_asset_id ] || [ "$my_asset_id" == "null" ]; then
            echo Error: identify_asset: File is not an asset: $file
            return 1
        fi
        asset_id=$my_asset_id
    fi

    local my_file=$(verbose=false identify=false read_asset)
    if [ "$my_file" == "null" ]; then
        echo Error: identify_asset: asset_id is not valid
        return 1
    fi
    if [ -z "$file" ]; then
        file=$my_file
    fi
    asset_file=$my_file
}

create_asset() {
    if [ -z "$file" ]; then
        echo Error: create_asset: File must be specified
        return 1
    fi
    if [ ! -f "$file" ]; then
        echo Error: create_asset: Asset file does not exist: $file
        return 1
    fi
    local my_asset_id=$(verbose=false read_asset_file_id)
    if [ ! -z "$my_asset_id" ] ; then
        echo Error: create_asset: Asset file already exists: $file
        return 1
    fi
    local type="Content-Type: application/octet-stream"
    response=$(curl --data-binary @"$file" -sH "$github_auth" -H "$type" $github_asset)
    field=name show_item
    field=id show_item
}

read_asset() {
    identify_asset
    [ $? -ne 0 ] && return 1
    if [ "$identify" == "true" ] && [ "$asset_file" != "$file" ]; then
        echo Error: read_asset: $asset_file does not match option file: $file
        return 1
    fi

    github_asset_id="$github_rels/assets/$asset_id"
    response=$(curl -sH "$github_auth" $github_asset_id)
    field=name show_item
}

update_asset() {
    identify_asset
    [ $? -ne 0 ] && return 1
    if [ ! -f "$file" ]; then
        echo Error: update_asset: File does not exist: $file
        return 1
    fi
    if [ "$asset_file" == "$file" ]; then
        echo Updating file: $file
    else
        local my_asset_id=$(verbose=false read_asset_file_id)
        if [ -z "$my_asset_id" ] ; then
            echo Replacing file: $asset_file with: $file
        else
            echo Error: update_asset: Asset file already exists: $file
            return 1
        fi
    fi

    github_asset_id="$github_rels/assets/$asset_id"
    identify=false asset_file="$file" delete_asset

    github_asset="$github_upl_rels/$release_id/assets?name=$file"
    identify=false create_asset
}

delete_asset() {
    identify_asset
    [ $? -ne 0 ] && return 1
    if [ "$identify" == "true" ] && [ "$asset_file" != "$file" ]; then
        echo Error: delete_asset: $asset_file does not match option file: $file
        return 1
    fi

    github_asset_id="$github_rels/assets/$asset_id"
    response=$(curl -X "DELETE" -sH "$github_auth" $github_asset_id)
}

message() {
    [ "$silent" == "true" ] && return
    echo $*
}

err_message() {
    if [ "$warning" == "true" ]; then
        if [ "$silent" != "true" ]; then
            echo Warning: $*
        fi
    else
        echo Error: $*
        exit 1
    fi
}

branch="master"
draft=false
prerel=false
github_url="https://github.com/"
github_api="https://api.github.com"
github_upl="https://uploads.github.com"

# get options
while getopts ab:c:df:F:hi:I:lm:npr:st:vw opt; do
	case ${opt} in
		a) asset="true";;
		b) branch="$OPTARG";;
		c) command="$OPTARG";;
		d) draft=true;;
		f) file="$OPTARG";;
		F) notes_file="$OPTARG";;
		i) release_id="$OPTARG";;
		h) usage;;
		I) asset_id="$OPTARG";;
		l) latest="true";;
		m) message="$OPTARG";;
		n) dryrun="true";;
		p) prerel=true;;
		r) repo="$OPTARG";;
		s) silent="true";;
		t) tag="$OPTARG";;
		v) verbose="true";;
		w) warning=true;;
        :) usage;;
        \?) usage;;
	esac
done

if [ ! -z $notes_file ]; then
    if [ ! -f "$notes_file" ]; then
        echo Error: Notes file does not exist: $notes_file
        exit 1
    fi
    message=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\r\\n/g' $notes_file)
fi

if [ ! -z $command ]; then
	case ${command} in
        create|read|update|delete)
            if [ "$asset" == "true" ]; then
                message command = $command asset
            else
                message command = $command release
            fi
            ;;
        *)
            echo Error: Command $command is invalid
            echo command option must be create, read, update, or delete
            exit 1 ;;
	esac
fi

if [ ! -z $asset_id ]; then
    message asset_id = $asset_id
fi

if [ ! -z $file ]; then
    message file = $file
fi

if [ -z $repo ]; then
    # check remote repo url
    remote_url=$(git config --get remote.origin.url)
    if [ -z $remote_url ]; then
        echo "Must supply repo if not in a git repository"
        exit 1
    fi
    repo=$(echo "$remote_url" | sed -E -e "s#$github_url##" | sed -E -e 's/.git//')
    message current repo = $repo
else
    message option repo = $repo
fi

if [ "$branch" == "master" ]; then
    message default branch = $branch
else
    message option branch = $branch
fi

github_repo="$github_api/repos/$repo"
github_rels="$github_repo/releases"
github_latest="$github_repo/releases/latest"
github_tags="$github_repo/tags"
github_asset_id="$github_rels/assets/$asset_id"
github_auth="Authorization: token $PR_GITHUB_RELEASE_TOKEN"
github_upl_rels="$github_upl/repos/$repo/releases"
# github_upload="$github_upl_rels/$asset_id/assets?name=$file"

validate_token

if [ -z $tag ]; then
    tag=$(latest=true verbose=false read_tags)
    message latest tag = $tag
else
    message option tag = $tag
fi

github_rel_tag="$github_repo/releases/tags/$tag"

if [ -z $release_id ]; then
    release_id=$(verbose=false read_rel_tag_id)
    if [ "$release_id" == "null" ]; then
        err_message Tag has no associated release: $tag
        release_id=$(latest=true verbose=false read_releases_id)
        if [ "$release_id" == "null" ]; then
            err_message Latest release not found
        else
            message latest release_id = $release_id
        fi
    else
        message tagged release_id = $release_id
    fi
else
    message option release_id = $release_id
fi

github_release_id="$github_repo/releases/$release_id"
github_assets="$github_repo/releases/$release_id/assets"
github_asset="$github_upl_rels/$release_id/assets?name=$file"

release=$(verbose=false read_rel_id)
if [ "$release" == "null" ]; then
    err_message Invalid release_id: $release_id
fi

if [ "${dryrun}" == "true" ] ; then
    echo Exiting dry run
    exit 0
fi

