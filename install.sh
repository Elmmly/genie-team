#!/bin/bash
# Genie Team Installer
# Install genie-team commands and configurations globally or per-project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_CLAUDE_DIR="$HOME/.claude"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo "Genie Team Installer v${VERSION}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  global              Install commands globally (~/.claude/commands/)"
    echo "  project [path]      Install to project (default: current directory)"
    echo "  update              Update existing installation"
    echo "  status              Show installation status"
    echo "  uninstall           Remove genie-team installation"
    echo ""
    echo "Options:"
    echo "  --commands-only     Only install commands (skip genies/templates)"
    echo "  --permissions       Also update permissions in settings.json"
    echo "  --force             Overwrite existing files without prompting"
    echo "  --dry-run           Show what would be done without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 global                    # Install commands globally"
    echo "  $0 global --permissions      # Install commands + update permissions"
    echo "  $0 project                   # Install to current project"
    echo "  $0 project ~/code/myapp      # Install to specific project"
    echo "  $0 update                    # Update all installations"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if source files exist
check_source() {
    if [[ ! -d "$SCRIPT_DIR/dist/commands" ]]; then
        log_error "Distribution files not found. Run 'make build' first or check installation."
        log_info "Expected: $SCRIPT_DIR/dist/commands/"
        exit 1
    fi
}

# Install commands to a target directory
install_commands() {
    local target_dir="$1"
    local force="$2"

    mkdir -p "$target_dir"

    for cmd_file in "$SCRIPT_DIR/dist/commands"/*.md; do
        if [[ -f "$cmd_file" ]]; then
            local filename=$(basename "$cmd_file")
            local target_file="$target_dir/$filename"

            if [[ -f "$target_file" && "$force" != "true" ]]; then
                log_warn "Skipping $filename (exists, use --force to overwrite)"
            else
                cp "$cmd_file" "$target_file"
                log_success "Installed $filename"
            fi
        fi
    done
}

# Install genie specs to a target directory
install_genies() {
    local target_dir="$1"
    local force="$2"

    mkdir -p "$target_dir"

    for genie_dir in "$SCRIPT_DIR/genies"/*; do
        if [[ -d "$genie_dir" ]]; then
            local genie_name=$(basename "$genie_dir")
            local target_genie_dir="$target_dir/$genie_name"

            mkdir -p "$target_genie_dir"

            for spec_file in "$genie_dir"/*.md; do
                if [[ -f "$spec_file" ]]; then
                    local filename=$(basename "$spec_file")
                    local target_file="$target_genie_dir/$filename"

                    if [[ -f "$target_file" && "$force" != "true" ]]; then
                        log_warn "Skipping genies/$genie_name/$filename (exists)"
                    else
                        cp "$spec_file" "$target_file"
                        log_success "Installed genies/$genie_name/$filename"
                    fi
                fi
            done
        fi
    done
}

# Update permissions in settings.json
update_permissions() {
    local settings_file="$1"
    local force="$2"

    # Default permissions from genie-team
    local permissions_json='{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git branch:*)",
      "Bash(git show:*)",
      "Bash(ls:*)",
      "Bash(tree:*)",
      "Bash(npm test:*)",
      "Bash(npm run test:*)",
      "Bash(pytest:*)",
      "Bash(jest:*)",
      "Bash(cargo test:*)",
      "Bash(eslint:*)",
      "Bash(tsc --noEmit:*)",
      "Bash(npm run build:*)",
      "Bash(npm audit:*)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:stackoverflow.com)",
      "WebFetch(domain:docs.*)"
    ]
  }
}'

    if [[ -f "$settings_file" ]]; then
        # Backup existing settings
        cp "$settings_file" "${settings_file}.backup"
        log_info "Backed up existing settings to ${settings_file}.backup"

        # Merge permissions (this is a simple approach - just adds the allow list)
        # For a proper merge, you'd need jq or similar
        if command -v jq &> /dev/null; then
            local existing=$(cat "$settings_file")
            local merged=$(echo "$existing" | jq --argjson perms "$permissions_json" '. * $perms')
            echo "$merged" > "$settings_file"
            log_success "Merged permissions into $settings_file"
        else
            log_warn "jq not installed - cannot merge settings. Manual merge required."
            log_info "Add these permissions to $settings_file:"
            echo "$permissions_json"
        fi
    else
        mkdir -p "$(dirname "$settings_file")"
        echo '{
  "alwaysThinkingEnabled": true,
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git branch:*)",
      "Bash(git show:*)",
      "Bash(ls:*)",
      "Bash(npm test:*)",
      "Bash(pytest:*)",
      "Bash(eslint:*)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:stackoverflow.com)"
    ]
  }
}' > "$settings_file"
        log_success "Created $settings_file with genie-team permissions"
    fi
}

# Create CLAUDE.md template
create_claude_md_template() {
    local target_file="$1"
    local force="$2"

    if [[ -f "$target_file" && "$force" != "true" ]]; then
        log_warn "Skipping CLAUDE.md (exists, use --force to overwrite)"
        return
    fi

    cat > "$target_file" << 'TEMPLATE'
# Project Name

> Brief description of this project

## Overview

[What this project does and why it exists]

## Architecture

[Key components and structure]

## Genie Team

This project uses [Genie Team](https://github.com/your-username/genie-team) for AI-assisted development.

**Available commands:**
- `/discover [topic]` - Explore problems with Scout genie
- `/shape [input]` - Define scope with Shaper genie
- `/design [contract]` - Technical design with Architect genie
- `/deliver [design]` - TDD implementation with Crafter genie
- `/discern [impl]` - Review with Critic genie
- `/diagnose` / `/tidy` - Maintenance with Tidier genie

**Workflows:**
- `/feature [topic]` - Full discovery → delivery cycle
- `/bugfix [issue]` - Quick bug fix workflow
- `/spike [question]` - Technical investigation
- `/cleanup` - Debt reduction cycle

## Context

[Important context for working on this project]

## Setup

[How to set up the development environment]

---

Last updated: $(date +%Y-%m-%d)
TEMPLATE

    log_success "Created CLAUDE.md template at $target_file"
}

# Global installation
cmd_global() {
    local force="false"
    local with_permissions="false"
    local dry_run="false"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force="true"; shift ;;
            --permissions) with_permissions="true"; shift ;;
            --dry-run) dry_run="true"; shift ;;
            *) shift ;;
        esac
    done

    log_info "Installing Genie Team globally..."

    check_source

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would install commands to $GLOBAL_CLAUDE_DIR/commands/"
        if [[ "$with_permissions" == "true" ]]; then
            log_info "[DRY RUN] Would update permissions in $GLOBAL_CLAUDE_DIR/settings.json"
        fi
        return
    fi

    # Install commands
    install_commands "$GLOBAL_CLAUDE_DIR/commands" "$force"

    # Update permissions if requested
    if [[ "$with_permissions" == "true" ]]; then
        update_permissions "$GLOBAL_CLAUDE_DIR/settings.json" "$force"
    fi

    echo ""
    log_success "Global installation complete!"
    log_info "Commands available in all projects: /discover, /shape, /design, etc."
}

# Project installation
cmd_project() {
    local project_path="${1:-.}"
    local force="false"
    local commands_only="false"
    local with_permissions="false"
    local dry_run="false"

    # Parse options
    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force="true"; shift ;;
            --commands-only) commands_only="true"; shift ;;
            --permissions) with_permissions="true"; shift ;;
            --dry-run) dry_run="true"; shift ;;
            *)
                if [[ -d "$1" ]]; then
                    project_path="$1"
                fi
                shift
                ;;
        esac
    done

    # Resolve to absolute path
    project_path="$(cd "$project_path" && pwd)"
    local claude_dir="$project_path/.claude"

    log_info "Installing Genie Team to project: $project_path"

    check_source

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would install commands to $claude_dir/commands/"
        if [[ "$commands_only" != "true" ]]; then
            log_info "[DRY RUN] Would install genies to $claude_dir/genies/"
            log_info "[DRY RUN] Would create $project_path/CLAUDE.md"
        fi
        return
    fi

    # Install commands
    install_commands "$claude_dir/commands" "$force"

    # Install genies and templates unless --commands-only
    if [[ "$commands_only" != "true" ]]; then
        install_genies "$claude_dir/genies" "$force"
        create_claude_md_template "$project_path/CLAUDE.md" "$force"

        # Create context directories
        mkdir -p "$project_path/docs/context"
        mkdir -p "$project_path/docs/analysis"
        mkdir -p "$project_path/docs/backlog"
        mkdir -p "$project_path/docs/cleanup"
        log_success "Created docs/ directory structure"
    fi

    # Update project permissions if requested
    if [[ "$with_permissions" == "true" ]]; then
        update_permissions "$claude_dir/settings.local.json" "$force"
    fi

    echo ""
    log_success "Project installation complete!"
    log_info "Edit CLAUDE.md with your project details"
}

# Update existing installations
cmd_update() {
    log_info "Updating Genie Team installations..."

    check_source

    # Update global if exists
    if [[ -d "$GLOBAL_CLAUDE_DIR/commands" ]]; then
        log_info "Updating global installation..."
        install_commands "$GLOBAL_CLAUDE_DIR/commands" "true"
    fi

    # Update current project if exists
    if [[ -d "./.claude/commands" ]]; then
        log_info "Updating current project..."
        install_commands "./.claude/commands" "true"

        if [[ -d "./.claude/genies" ]]; then
            install_genies "./.claude/genies" "true"
        fi
    fi

    log_success "Update complete!"
}

# Show installation status
cmd_status() {
    echo "Genie Team Installation Status"
    echo "==============================="
    echo ""

    # Check global
    echo "Global (~/.claude/):"
    if [[ -d "$GLOBAL_CLAUDE_DIR/commands" ]]; then
        local cmd_count=$(ls -1 "$GLOBAL_CLAUDE_DIR/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
        echo "  Commands: $cmd_count installed"
    else
        echo "  Commands: Not installed"
    fi

    if [[ -f "$GLOBAL_CLAUDE_DIR/settings.json" ]]; then
        echo "  Settings: Found"
    else
        echo "  Settings: Not found"
    fi

    echo ""

    # Check current project
    echo "Current Project (./.claude/):"
    if [[ -d "./.claude/commands" ]]; then
        local cmd_count=$(ls -1 "./.claude/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
        echo "  Commands: $cmd_count installed"
    else
        echo "  Commands: Not installed"
    fi

    if [[ -d "./.claude/genies" ]]; then
        local genie_count=$(ls -1d "./.claude/genies"/*/ 2>/dev/null | wc -l | tr -d ' ')
        echo "  Genies: $genie_count installed"
    else
        echo "  Genies: Not installed"
    fi

    if [[ -f "./CLAUDE.md" ]]; then
        echo "  CLAUDE.md: Found"
    else
        echo "  CLAUDE.md: Not found"
    fi
}

# Uninstall
cmd_uninstall() {
    local target="$1"

    case "$target" in
        global)
            if [[ -d "$GLOBAL_CLAUDE_DIR/commands" ]]; then
                log_info "Removing global commands..."
                rm -rf "$GLOBAL_CLAUDE_DIR/commands"
                log_success "Global commands removed"
            else
                log_warn "No global installation found"
            fi
            ;;
        project)
            if [[ -d "./.claude/commands" ]]; then
                log_info "Removing project commands..."
                rm -rf "./.claude/commands"
                log_success "Project commands removed"
            fi
            if [[ -d "./.claude/genies" ]]; then
                log_info "Removing project genies..."
                rm -rf "./.claude/genies"
                log_success "Project genies removed"
            fi
            ;;
        *)
            log_error "Specify 'global' or 'project' to uninstall"
            exit 1
            ;;
    esac
}

# Build distribution files (transform commands with inline genie prompts)
cmd_build() {
    log_info "Building distribution files..."

    local dist_dir="$SCRIPT_DIR/dist"
    mkdir -p "$dist_dir/commands"

    # For each command, embed the relevant genie system prompt
    for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
        local filename=$(basename "$cmd_file")
        local target_file="$dist_dir/commands/$filename"

        # Determine which genie to embed based on command
        local genie=""
        case "$filename" in
            discover.md) genie="scout" ;;
            shape.md) genie="shaper" ;;
            design.md|diagnose.md) genie="architect" ;;
            deliver.md) genie="crafter" ;;
            discern.md) genie="critic" ;;
            tidy.md) genie="tidier" ;;
        esac

        # Get uppercase genie name (macOS compatible)
        local genie_upper=$(echo "$genie" | tr '[:lower:]' '[:upper:]')

        if [[ -n "$genie" && -f "$SCRIPT_DIR/genies/$genie/${genie_upper}_SYSTEM_PROMPT.md" ]]; then
            # Embed genie system prompt at the top of the command
            local system_prompt="$SCRIPT_DIR/genies/$genie/${genie_upper}_SYSTEM_PROMPT.md"

            # Create combined file
            {
                # Extract the genie identity section (first ~50 lines)
                head -n 50 "$system_prompt"
                echo ""
                echo "---"
                echo ""
                echo "# Command Specification"
                echo ""
                cat "$cmd_file"
            } > "$target_file"

            log_success "Built $filename (with ${genie} genie)"
        else
            # Copy as-is for commands without specific genie
            cp "$cmd_file" "$target_file"
            log_success "Built $filename"
        fi
    done

    log_success "Build complete! Distribution files in $dist_dir/"
}

# Main
case "${1:-}" in
    global)
        shift
        cmd_global "$@"
        ;;
    project)
        shift
        cmd_project "$@"
        ;;
    update)
        cmd_update
        ;;
    status)
        cmd_status
        ;;
    uninstall)
        shift
        cmd_uninstall "$@"
        ;;
    build)
        cmd_build
        ;;
    -h|--help|help|"")
        print_usage
        ;;
    *)
        log_error "Unknown command: $1"
        print_usage
        exit 1
        ;;
esac
