#!/usr/bin/env bash
###############################################################################
# gimme.sh
#
# A basic script that watches a `urls.txt` file and fetches them via `wget`.
#
# This is expected to be run in a container and have a volume mounted to
# /mount. If a `urls.txt` file exists, it will start fetching any URLs listed
# in the file. Otherwise it will create an empty `urls.txt` file and wait for
# urls to be added.
#
# Fetched content is output into the `/mount/content` directory.
#
###############################################################################

# Echo an error message to stderr.
function error() {
    echo "error: ${1}" 1>&2
}

# Check that a /mount directory exists. This is not created in the Dockerfile
# proper, but instead it is expected to be mounted in on docker run. This is
# the directory where URLs are provided and where the fetched content is placed.
if [[ ! -d "/mount" ]]
then
    error "/mount not found, ensure a volume is mounted to the container on run, e.g."
    error ""
    error '    docker run -v ${PWD}/gimme:/mount ...'
fi

# If urls.txt does not exist, create it.
if [[ ! -f "/mount/urls.txt" ]]
then
    touch "/mount/urls.txt"
fi

# If the output directory does not exist, create it.
if [[ ! -d "/mount/contents" ]]
then
    mkdir "/mount/contents"
fi

# gimme()
#
# Get the contents at the specified URL.
gimme() {
    wget \
        -c \
        --no-cache \
        -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36" \
        -r \
        -nH \
        -np \
        -nv \
        -R "index.html*" \
        -R ".DS_Store,Thumbs.db,thumbcache.db,desktop.ini,_macosx" \
        -P /mount/contents \
        --no-check-certificate \
        $1
}

# go_gimme()
#
# Load URLs from file and get the contents for each URL in the file.
go_gimme() {
    while read -r line; do
        if [[ -n "${line}" ]]
        then
            echo "/////////////////////////////////////////////////////////////////////"
            echo "• ${line}"
            echo "---------------------------------------------------------------------"
            if ! gimme "${line}"
            then
                echo "${line}" >> /mount/errors.txt
            fi
            echo "/////////////////////////////////////////////////////////////////////"
        fi
    done <<< "$(cat /mount/urls.txt)"

    rm /mount/urls.txt
    touch /mount/urls.txt
}

echo "starting gimme watcher..."
while true; do
    inotifywait -q -e modify,create,moved_to /mount |
    while read -r directory events filename; do
        if [[ "${filename}" == "urls.txt" ]]; then
            if [[ "$(cat /mount/urls.txt | tr -d '[:space:]')" != "" ]]; then
                go_gimme
            fi
        fi
    done
done
