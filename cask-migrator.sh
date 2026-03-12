#!/bin/bash

forcing=false
remove=false

searchdir="/Applications"
installdir="/Applications"

while getopts ":d:i:fhr" opt; do
    case ${opt} in
        h|:|\? )
            echo "Options"
            echo "  -f          Don't ask for confirmation for each application (Probably a bad idea)."
            echo "  -r          Permanently remove old applications. By default just moves to trash"
            echo "  -d [dir]    Search directory for .app files. Default: /Applications"
            echo "  -i [dir]    Install directory for cask. Default: /Applications"
            echo "  -h          Print this help message and exit."
            exit 0
            ;;
        f )
            forcing=true
            ;;
        r )
            remove=true
            ;;
        d )
            searchdir=$OPTARG
            ;;
        i )
            installdir=$OPTARG
            ;;
    esac
done
shift $(( OPTIND - 1 ))

# store list of installed casks for fast access
installed=$(brew list --cask 2>/dev/null)

shopt -s nullglob
for filename in "$searchdir"/*.app; do
    # extract appname from filename
    appname="$(basename "$filename" .app | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"

    # check if already installed by cask
    if echo "$installed" | grep -qFx "$appname"; then
        echo "$appname already installed by cask"
        continue
    fi

    # check if cask is available to install
    if ! brew info --cask "$appname" &> /dev/null; then
        continue
    fi

    # ask for confirmation if not in force mode
    if ! $forcing; then
        read -p "Able to re-install $filename as $appname via cask. Proceed? (Y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            continue
        fi
    fi

    echo "Installing $appname..."

    # try adopting the existing app in-place first (no files removed)
    if brew install --cask --adopt "$appname" --appdir="$installdir" 2>/dev/null; then
        echo "$appname adopted successfully."
        continue
    fi

    # adopt failed (version mismatch etc.), fall back to remove-then-install
    echo "Adopt failed for $appname, falling back to reinstall..."
    if $remove; then
        rm -rf "$filename"
    else
        if ! mv "$filename" ~/.Trash; then
            echo "Error: could not move $filename to Trash. Skipping." >&2
            continue
        fi
    fi

    if ! brew install --cask "$appname" --appdir="$installdir"; then
        echo "Error: brew install failed for $appname." >&2
        if ! $remove; then
            echo "Restoring $appname from Trash..." >&2
            mv ~/.Trash/"$(basename "$filename")" "$filename"
        fi
    fi

done
