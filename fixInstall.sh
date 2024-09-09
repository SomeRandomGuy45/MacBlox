#!/bin/bash

# Define the path where your executables and libraries are located
SEARCH_DIR="$1"
BUILD_DIR="$2"

echo "BUILD_DIR: $BUILD_DIR"

ARCH=$(uname -m)

if [ "$ARCH" = "arm64" ]; then
    echo "Running on ARM64 (Apple Silicon)"
    REPLACEMENT_PATH="/opt/homebrew/opt"
elif [ "$ARCH" = "x86_64" ]; then
    echo "Running on x86_64 (Intel)"
    REPLACEMENT_PATH="/usr/local/opt"
else
    echo "Unknown architecture: $ARCH"
    exit 1
fi

# Function to update the paths, passing BUILD_DIR as an argument
update_paths() {
    local file="$1"
    local BUILD_DIR="$2"
    echo "Processing file: $file"
    echo "Using BUILD_DIR: $BUILD_DIR"

    # Extract the old paths from otool output and clean them up
    otool -L "$file" | grep '@executable_path/../Frameworks/' | while IFS= read -r line; do
        # Remove the version info and any whitespace
        clean_line=$(echo "$line" | sed -e 's/ (compatibility version.*)//')
        clean_line="${clean_line//[[:space:]]/}"

        echo "Original line: $line"
        echo "Cleaned line: $clean_line"

        # Extract the old path
        if [[ "$clean_line" =~ ^@executable_path/../Frameworks/(.*) ]]; then
            old_path="@executable_path/../Frameworks/${BASH_REMATCH[1]}"
            lib_name=$(basename "${BASH_REMATCH[1]}")
            new_path="${REPLACEMENT_PATH}/${BASH_REMATCH[1]}"

            # Debug output
            echo "Old path: $old_path"
            echo "New path: $new_path"

            # Update the path with install_name_tool
            if [ -f "$new_path" ]; then
                install_name_tool -change "$old_path" "$new_path" "$file"
                echo "Updated $old_path to $new_path in $file"
            else
                echo "Warning: $new_path does not exist."
            fi
        else
            echo "No match for line: $clean_line"
        fi
    done

    # Handle additional cases
    otool -L "$file" | while IFS= read -r line; do
        clean_line=$(echo "$line" | sed -e 's/ (compatibility version.*)//')
        clean_line="${clean_line//[[:space:]]/}"

        if [[ "$clean_line" =~ ^@executable_path/../Frameworks/(.*) ]]; then
            continue
        fi
        if [[ "$clean_line" =~ /usr/lib/(.*) ]]; then
            continue
        fi
        if [[ "$clean_line" =~ /System/Library/Frameworks/(.*) ]]; then
            continue
        fi

        dylib_name="Frameworks/$(basename "$clean_line")"
        echo "Original line: $line"
        echo "Cleaned line: $clean_line"
        echo "Destination path: ${BUILD_DIR}${dylib_name}"
        cp -r "$clean_line" "${BUILD_DIR}${dylib_name}"
        
        # Set the new ID for the library
        install_name_tool -id "@executable_path/../${dylib_name}" "${BUILD_DIR}${dylib_name}"
        echo "Set ID for ${BUILD_DIR}${dylib_name} to @executable_path/../${dylib_name}"
        
        # Update the path in the original file
        install_name_tool -change "$clean_line" "@executable_path/../${dylib_name}" "$file"
    done
}

export -f update_paths

# Ensure the Frameworks directory exists
mkdir -p "${BUILD_DIR}Frameworks"

echo "Frameworks directory created at: ${BUILD_DIR}Frameworks"

# Find all relevant files in the directory and update paths, passing BUILD_DIR explicitly
find "$SEARCH_DIR" \( -type f -name "*.dylib" -o -type f \) -exec bash -c 'update_paths "$0" "$1"' {} "$BUILD_DIR" \;

echo "Path update completed."