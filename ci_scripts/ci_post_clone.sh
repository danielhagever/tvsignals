#!/bin/sh
set -e
# Xcode Cloud's build image has no Node — install it, then build the web app + sync Capacitor.
if ! command -v node >/dev/null 2>&1; then
  echo "→ Installing Node via Homebrew"
  brew install node
fi
echo "→ Node $(node --version), npm $(npm --version)"
cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "→ Installing dependencies"; npm ci
echo "→ Staging web app";        npm run build
echo "→ Syncing Capacitor iOS";  npx cap sync ios
echo "✓ ci_post_clone done"
