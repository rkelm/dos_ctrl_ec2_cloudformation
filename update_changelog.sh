#!/bin/bash

# *** Updates changelog from commit messages ***

# ++ Configuration ++
changelog_file_name="CHANGELOG"
changelog_file_name_temp="CHANGELOG.TEMP"
tag_name_new="$1"

show_usage() {
    echo "usage: $(basename $0) <new-tag-name>"
    echo ""
    echo "This script must be run in the projects root directory."
    echo "The git workspace and index must be clean, because the script will "
    echo "commit the updated CHANGELOG and create an annotated version tag."
    echo "It will then git push all --follow-tags to the default remote."
}

if [ "$tag_name_new" == "-h" ] || [ "$tag_name_new" == "--help" ] ; then
    show_usage
    exit 0
fi

if [ -z "$tag_name_new" ] ; then
    echo "Missing required parameter <new-tag-name>."
    show_usage
    exit 1
fi

if [ ! -f "README.md" ] ; then
    echo "Could not find file README.md! Maybe this is the wrong directory?"
    show_usage
    exit 1
fi

# Ensure a clean git workspace.
if ! _output="$(git status --porcelain)" || [ ! -z "$_output" ] ; then
    echo "git workspace ist not clean. Please commit or re-checkout."
    show_usage
    exit 1
fi
# Ensure a clean git index.
if "$(git diff --cached --exit-code)" ; then
    echo "git workspace ist not clean. Please commit or re-checkout."
    show_usage
    exit 1
fi

# Get last tag name.
tag_name_prior="$(git describe --abbrev=0 --match 'v*')"

# ++ Create new CHANGELOG file ++
rm -f "$changelog_file_name_temp"

# Write heading.
echo "Changes in ${tag_name_new}" > "$changelog_file_name_temp"
echo "" >> "$changelog_file_name_temp"
echo "Exporting commit messages from last release tag $tag_name_prior."
# Later only export commit notes beginning with a square bracket using --grep="\["
git log "$tag_name_prior..HEAD" --pretty=format:"+ %s" | tee -a "$changelog_file_name_temp"
echo "" >> "$changelog_file_name_temp"
echo "" >> "$changelog_file_name_temp"
# Append old file
cat "$changelog_file_name" >> "$changelog_file_name_temp"

# Delete old file and rename new file.
rm "$changelog_file_name"
mv "$changelog_file_name_temp" "$changelog_file_name"

# ++ Commit new CHANGELOG, tag and push.

echo "Commiting and creating new version tag $tag_name_new"
git add "$changelog_file_name"
git commit -m 'Updated CHANGELOG'
git tag -a "$tag_name_new" -m "Release $tag_name_new"
echo "Pushing commits and tags."
git push --follow-tags

echo "Done updating $changelog_file_name and creating version tag."
