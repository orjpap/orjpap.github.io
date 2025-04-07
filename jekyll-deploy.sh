#!/bin/bash

# Simple script to build and deploy Jekyll site from source to master

echo "🚀 Starting deployment process..."

# Make sure we're on the source branch
git checkout source
if [ $? -ne 0 ]; then
    echo "❌ Failed to switch to source branch"
    exit 1
fi

# Build the site
echo "📦 Building Jekyll site..."
bundle exec jekyll build
if [ $? -ne 0 ]; then
    echo "❌ Jekyll build failed"
    exit 1
fi

# Switch to master branch
echo "🔄 Switching to master branch..."
git checkout master
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
git commit -m "Update site from source branch"
git push origin master

# Switch back to source
git checkout source

echo "✅ Deployment complete!"

