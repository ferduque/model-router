#!/usr/bin/env bash
# Double-clickable installer for Mac.
# Installs the model-router skill, then opens the key file so you can paste
# your OpenRouter API key (from https://openrouter.ai -> Keys).
cd "$(dirname "$0")"
bash ./install.sh
echo ""
echo "Opening the key file in TextEdit — replace the placeholder with your"
echo "OpenRouter key, then save and close. That's the only manual step."
open -e "$HOME/.model-router/env"
echo ""
read -r -p "Press Enter to close this window..."
