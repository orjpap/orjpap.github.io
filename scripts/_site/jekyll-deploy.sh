#!/bin/bash

# Simple script to build and deploy Jekyll site from source to master

echo "🚀 Starting deployment process..."

# Clean up SASS cache and _site directory
echo "🧹 Cleaning up temporary files..."
rm -rf .sass-cache _site

# Make sure we're on the source branch
git checkout source
if [ $? -ne 0 ]; then
    echo "❌ Failed to switch to source branch"
    exit 1
fi

# Get the current commit hash from source branch
SOURCE_COMMIT=$(git rev-parse --short HEAD)
echo "📝 Building from source commit: $SOURCE_COMMIT"

# Build the site
echo "📦 Building Jekyll site..."
bundle exec jekyll build
if [ $? -ne 0 ]; then
    echo "❌ Jekyll build failed"
    exit 1
fi

# Clean up SASS cache again after build
echo "🧹 Cleaning up SASS cache after build..."
rm -rf .sass-cache

# Switch to master branch with force
echo "🔄 Switching to master branch..."
git checkout -f master
if [ $? -ne 0 ]; then
    echo "❌ Failed to switch to master branch"
    exit 1
fi

# Copy the built site
echo "📋 Copying built site..."
cp -r _site/* .

# Commit and push changes
echo "💾 Committing and pushing changes..."
git add .
git commit -m "Update site from source branch (commit: $SOURCE_COMMIT)"
git push origin master

# Switch back to source
git checkout source

echo "✅ Deployment complete!"

