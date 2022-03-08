#!/bin/zsh

KKP_SCRIPTS_DIR="scripts"
CUSTOME_SOURCE_SCRIPTS_DIR="$PROJECT_DIR/$KKP_SCRIPTS_DIR"
DESTINATION_SCRIPTS_DIR="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/$KKP_SCRIPTS_DIR"

mkdir -p "$CUSTOME_SOURCE_SCRIPTS_DIR"
rm -rf "$DESTINATION_SCRIPTS_DIR"
mkdir -p "$DESTINATION_SCRIPTS_DIR"

# copy everything in the data dir to the app (doesn't just have to be lua files, can be images, sounds, etc...)
if [[ -d "$PROJECT_DIR/kkp" ]]; then;
	# If we are using the framework, there is no kkp dir
	cp -r "$PROJECT_DIR/kkp/stdlib" "$DESTINATION_SCRIPTS_DIR/kkp"
fi

cp -r "$CUSTOME_SOURCE_SCRIPTS_DIR/" "$DESTINATION_SCRIPTS_DIR"

# This forces xcode to load all the Lua scripts (without having to clean
# the project first"
THE_FUTURE=$(date -v +1M -j +"%m%d%H%M")
touch -t $THE_FUTURE "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH"/*.plist