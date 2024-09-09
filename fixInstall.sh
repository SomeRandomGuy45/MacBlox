#!/bin/bash

# Define the path where your executables and libraries are located
SEARCH_DIR="$1"

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

# Function to update the paths
update_paths() {
    local file="$1"
    echo "Processing file: $file"

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
            new_path="${REPLACEMENT_PATH}/${BASH_REMATCH[1]}"

            # Debug output
            echo "Old path: $old_path"
            echo "New path: $new_path"

            # Update the path with install_name_tool
            install_name_tool -change "$old_path" "$new_path" "$file"
            echo "Updated $old_path to $new_path in $file"
        else
            echo "No match for line: $clean_line"
        fi
    done
}

export -f update_paths

# Find all relevant files in the directory and update paths
find "$SEARCH_DIR" \( -type f -name "*.dylib" -o -type f \) -exec bash -c 'update_paths "$0"' {} \;

echo "Path update completed."
