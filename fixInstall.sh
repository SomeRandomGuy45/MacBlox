#!/bin/bash

: "

    Hello!
    This scripts will help you to create a frameworks folder which places the dylib files that it needs
    This can be used if your using something like brew when creating your apps! 

"

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

checkDepOfDylib() {
    local file="$1"
    local BUILD_DIR="$2"
    local SEARCH_DIR="$3"
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

        file_cleaned="${file//[[:space:]]/}"
        if [[ "$clean_line" == "${file_cleaned}" || "$clean_line" == "${file_cleaned}:" ]]; then
            continue
        fi

        dylib_name="Frameworks/$(basename "$clean_line")"
        echo "Original line: $line"
        echo "Cleaned line: $clean_line"
        echo "Destination path: ${BUILD_DIR}${dylib_name}"
        if [ -e "${BUILD_DIR}${dylib_name}" ]; then
            echo "${BUILD_DIR}${dylib_name} already exists."
        else
            cp -r "$clean_line" "${BUILD_DIR}${dylib_name}"
        fi
        
        # Set the new ID for the library
        install_name_tool -id "@executable_path/../${dylib_name}" "${BUILD_DIR}${dylib_name}"
        echo "Set ID for ${BUILD_DIR}${dylib_name} to @executable_path/../${dylib_name}"
        
        # Update the path in the original file
        install_name_tool -change "$clean_line" "@executable_path/../${dylib_name}" "$file"
        checkDepOfDylib "${BUILD_DIR}${dylib_name}" "$BUILD_DIR" "$SEARCH_DIR"
    done
}

fix_paths() {
    local file="$1"
    local BUILD_DIR="$2"
    local SEARCH_DIR="$3"
    echo "Processing file: $file"
    echo "Using BUILD_DIR: $BUILD_DIR"
    echo "$SEARCH_DIR"
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
            new_path="${BASH_REMATCH[1]}"

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
}

update_paths() {
    local file="$1"
    local BUILD_DIR="$2"
    local SEARCH_DIR="$3"
    echo "Processing file: $file"
    echo "Using BUILD_DIR: $BUILD_DIR"
    echo "$SEARCH_DIR"

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

        file_cleaned="${file//[[:space:]]/}"
        if [[ "$clean_line" == "${file_cleaned}" || "$clean_line" == "${file_cleaned}:" ]]; then
            continue
        fi

        dylib_name="Frameworks/$(basename "$clean_line")"
        #echo "Original line: $line"
        echo "Cleaned line: $clean_line"
        #echo "Destination path: ${BUILD_DIR}${dylib_name}"
        cp -r "$clean_line" "${BUILD_DIR}${dylib_name}"
        
        # Set the new ID for the library
        install_name_tool -id "@executable_path/../${dylib_name}" "${BUILD_DIR}${dylib_name}"
        echo "Set ID for ${BUILD_DIR}${dylib_name} to @executable_path/../${dylib_name}"
        
        # Update the path in the original file
        install_name_tool -change "$clean_line" "@executable_path/../${dylib_name}" "$file"
        checkDepOfDylib "${BUILD_DIR}${dylib_name}" "$BUILD_DIR" "$SEARCH_DIR"
    done
}

# Ensure the Frameworks directory exists
mkdir -p "${BUILD_DIR}Frameworks"

echo "Frameworks directory created at: ${BUILD_DIR}Frameworks"

# Find all relevant files in the directory and update paths, processing files directly in the script
find "$SEARCH_DIR" \( -type f -name "*.dylib" -o -type f \) | while IFS= read -r file; do
    fix_paths "$file" "$BUILD_DIR" "$SEARCH_DIR"
    update_paths "$file" "$BUILD_DIR" "$SEARCH_DIR"
done

echo "Path update completed."