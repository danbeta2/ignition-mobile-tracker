#!/bin/bash
# Script to add PrivacyPolicyView.swift to Xcode project

PROJ_FILE="Ignition Mobile Tracker.xcodeproj/project.pbxproj"
FILE_NAME="PrivacyPolicyView.swift"
FILE_PATH="Ignition Mobile Tracker/Features/Settings/$FILE_NAME"

# Generate UUIDs
UUID1=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
UUID2=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')

echo "Adding $FILE_NAME to Xcode project..."
echo "UUID1: $UUID1"
echo "UUID2: $UUID2"

# Backup
cp "$PROJ_FILE" "$PROJ_FILE.backup"

# Find the Settings group and add file reference
# This is a simplified approach - you need to manually add the references in the right sections

echo "Backup created. Please add the file manually in Xcode."
