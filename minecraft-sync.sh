#!/bin/bash


GIT_REPO_PATH="$HOME/curseforge/minecraft/minecraft-sync"
GIT_REPO_SAVE="$HOME/curseforge/minecraft/minecraft-sync"
MINECRAFT_SAVE="$HOME/curseforge/minecraft/Instances/lite shader"
MINECRAFT_EXE="/c/AutoHotkey/minecraft2p.exe"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "[Minecraft Sync]${GREEN}[INFO]${NC} $1\n"
}

warn() {
    echo -e "[Minecraft Sync]${YELLOW}[WARN]${NC} $1\n"
}

error() {
    echo -e "[Minecraft Sync]${RED}[ERROR]${NC} $1\n"
}

pull_saves() {
    log "Pulling latest saves from GitHub..."

    if [ -d "$GIT_REPO_PATH" ]; then
        cd "$GIT_REPO_PATH"

        git remote update -p
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)

        if [ "$LOCAL" != "$REMOTE" ]; then
            git reset --hard origin/main
            rsync -aP "$GIT_REPO_SAVE/saves" "$MINECRAFT_SAVE"
            log "Saves synced from GitHub"
        else
            log "Already up to date"
        fi
    else
        error "Git repository not found at $GIT_REPO_PATH"
    fi
}

push_saves() {
    log "Pushing saves to GitHub..."

    trap 'error "Error trapped, read message above and re-run after fixing"; sleep 7; exit 1' ERR

    if [ -d "$GIT_REPO_PATH" ]; then
        cd "$GIT_REPO_PATH"

        rsync -aP "$MINECRAFT_SAVE/saves" "$GIT_REPO_SAVE"
        git add saves/

        if [ -n "$(git status --porcelain)" ]; then
            git commit -m "save: $(date '+%Y-%m-%d %H:%M:%S')"

            if git push origin main; then
                log "Saves backed up to GitHub"
            else
                warn "Could not push to GitHub (may be offline)"
            fi
        else
            log "No save changes detected"
        fi
    else
        error "Git repository not found at $GIT_REPO_PATH"
    fi
}

log "--- Minecraft Save Sync Started ---"
pull_saves

log "--- Minecraft Started ---"
"$MINECRAFT_EXE" & PID=$!
wait -f $PID 
log "--- Minecraft Closed ---"

push_saves
log "--- Save Sync Complete ---"
sleep 2
