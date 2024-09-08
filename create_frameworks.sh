#!/bin/bash

# Ensure the script is executed with the correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/AppsDir"
    exit 1
fi

APPS_DIR="$1"

# Check if the given directory exists
if [ ! -d "$APPS_DIR" ]; then
    echo "Error: Directory $APPS_DIR does not exist."
    exit 1
fi

# Function to find and copy the dylib from /usr/local/ and /usr/
copy_library() {
    local lib_name="$1"
    local frameworks_dir="$2"

    # Search in /usr/local
    local lib_path
    lib_path=$(find /usr/local -name "$lib_name" -type f 2>/dev/null)
    if [ -n "$lib_path" ]; then
        echo "Found $lib_name in /usr/local"
        mkdir -p "$frameworks_dir/$(dirname "$lib_name")"
        cp -f "$lib_path" "$frameworks_dir/"
        return 0
    fi

    # Search in /usr
    lib_path=$(find /usr -name "$lib_name" -type f 2>/dev/null)
    if [ -n "$lib_path" ]; then
        echo "Found $lib_name in /usr"
        mkdir -p "$frameworks_dir/$(dirname "$lib_name")"
        cp -f "$lib_path" "$frameworks_dir/"
        return 0
    fi

    return 1
}

# Find all .app directories recursively in the given directory
find "$APPS_DIR" -type d -name "*.app" | while read -r app; do
    echo "Processing $app..."

    # Create a Frameworks directory if it doesn't exist
    FRAMEWORKS_DIR="$app/Contents/Frameworks"
    mkdir -p "$FRAMEWORKS_DIR"

    # Find all executable files inside the .app package
    find "$app/Contents" -type f -perm +111 | while read -r exec_file; do
        # List the dependencies of the executable file
        dependencies=$(otool -L "$exec_file" | awk '/\t\/.*\.dylib/ {print $1}' | sed 's/^[[:space:]]*//')

        for dep in $dependencies; do
            echo $dep
            if [[ "$dep" =~ ^@ ]]; then
                # Handle @executable_path/../Frameworks dependencies
                lib_name=$(basename "$dep")
                echo "Processing framework: $dep"
                if copy_library "$lib_name" "$FRAMEWORKS_DIR"; then
                    echo "Copied $lib_name to $FRAMEWORKS_DIR"
                else
                    echo "Library $lib_name not found in /usr/local or /usr"
                fi
            else
                # Handle absolute paths directly
                if [[ "$dep" == /usr/local/* || "$dep" == /usr/* ]]; then
                    dep_name=$(basename "$dep")
                    echo "Copying dependency: $dep"
                    mkdir -p "$FRAMEWORKS_DIR"
                    cp -f "$dep" "$FRAMEWORKS_DIR/"
                else
                    echo "Skipping non-handled dependency: $dep"
                fi
            fi
        done
    done
done

echo "Done."
