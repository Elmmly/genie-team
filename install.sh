#!/bin/bash
# Genie Team Installer
# Install genie-team commands, skills, rules, agents, schemas, and MCP servers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_CLAUDE_DIR="$HOME/.claude"
VERSION="2.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_usage() {
    cat << EOF
Genie Team Installer v${VERSION}

Usage: $0 <command> [options]

Commands:
  global              Install globally (~/.claude/) - available to all projects
  project [path]      Install to project (default: current directory)
  prehook [path]      Install pre-commit hooks to a project (standalone, non-destructive)
  status              Show installation status
  uninstall           Remove genie-team installation

Options:
  --commands          Install commands only
  --skills            Install skills only
  --rules             Install rules only
  --agents            Install agents only
  --genies            Install genie specs only (project only)
  --schemas           Install schemas only
  --stacks            Install stack profile templates only
  --scripts           Install scripts only (genies)
  --hooks             Install hooks only (context re-injection)
  --mcp               Install MCP server only (imagegen for Designer genie)
  --all               Install everything (default, includes MCP)
  --skip-mcp          Skip MCP server installation
  --force             Overwrite existing files
  --sync              Clean install: remove target dirs before copying (removes obsolete files)
  --dry-run           Show what would be done

Examples:
  $0 global                      # Full global install (includes MCP)
  $0 global --commands           # Commands only (for slash commands)
  $0 global --skills             # Skills only (for automatic behaviors)
  $0 global --mcp                # Install/configure MCP server only
  $0 project                     # Full project install (includes MCP)
  $0 project ~/code/myapp        # Install to specific project
  $0 project --skip-mcp          # Full install without MCP server
  $0 project --force             # Re-install/upgrade
  $0 project --sync              # Update existing install (removes obsolete files)
EOF
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# PATH configuration
SCRIPTS_PATH="$GLOBAL_CLAUDE_DIR/scripts"
PATH_EXPORT_LINE="export PATH=\"\$PATH:\$HOME/.claude/scripts\""

# Detect user's shell profile
detect_shell_profile() {
    local shell_name
    shell_name="$(basename "${SHELL:-/bin/bash}")"
    case "$shell_name" in
        zsh)  echo "$HOME/.zshrc" ;;
        bash)
            # Prefer .bash_profile on macOS, .bashrc on Linux
            if [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        *)    echo "$HOME/.profile" ;;
    esac
}

# Add ~/.claude/scripts to PATH if not already present
setup_scripts_path() {
    local dry_run="$1"

    # Already on PATH — nothing to do
    if echo "$PATH" | tr ':' '\n' | grep -qx "$SCRIPTS_PATH"; then
        log_info "Scripts already on PATH"
        return 0
    fi

    local profile
    profile="$(detect_shell_profile)"

    # Already in profile file — just not active in this shell
    if [[ -f "$profile" ]] && grep -qF '.claude/scripts' "$profile"; then
        log_info "PATH entry exists in $profile (restart shell to activate)"
        return 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would add scripts to PATH in $profile"
        return 0
    fi

    {
        echo ""
        echo "# Genie Team scripts (genies)"
        echo "$PATH_EXPORT_LINE"
    } >> "$profile"
    log_success "Added scripts to PATH in $profile"
    log_info "Run: source $profile  (or restart your shell)"
    return 0
}

# MCP server configuration
MCP_SERVER_NAME="imagegen"
MCP_SERVER_PKG="@fastmcp-me/imagegen-mcp"

# Detect if running inside a git worktree (not the main working tree)
detect_worktree() {
    local git_dir git_common_dir
    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 1
    git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
    [[ "$git_dir" != "$git_common_dir" ]]
}

# Get the main worktree path from inside any worktree (or main tree)
get_main_worktree() {
    local common_dir
    common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
    # common-dir is the .git/ dir; parent is the main worktree
    dirname "$(cd "$common_dir" && pwd)"
}

# Check if claude CLI is available
check_claude_cli() {
    command -v claude &>/dev/null
}

# Check if MCP server is already installed (any scope)
check_mcp_installed() {
    claude mcp get "$MCP_SERVER_NAME" &>/dev/null 2>&1
}

# Get the scope of an installed MCP server (local, user, or project)
get_mcp_scope() {
    local output
    output=$(claude mcp get "$MCP_SERVER_NAME" 2>/dev/null) || return 1
    if echo "$output" | grep -q "User config"; then
        echo "user"
    elif echo "$output" | grep -q "Project config"; then
        echo "project"
    else
        echo "local"
    fi
}

# Detect which image generation API keys are set in the environment
detect_api_keys() {
    local found=""
    [[ -n "${GOOGLE_API_KEY:-}" ]] && found="${found}GOOGLE "
    [[ -n "${OPENAI_API_KEY:-}" ]] && found="${found}OPENAI "
    [[ -n "${REPLICATE_API_TOKEN:-}" ]] && found="${found}REPLICATE "
    echo "$found"
}

# Print API key setup guidance
print_api_key_guidance() {
    local found_keys="$1"

    echo ""
    log_info "Image generation API keys for Designer genie (/brand:image):"
    echo ""

    if echo "$found_keys" | grep -q "GOOGLE"; then
        log_success "GOOGLE_API_KEY detected (Gemini Flash + Pro)"
    else
        echo "  GOOGLE_API_KEY — not found"
        echo "    Enables: Gemini 2.5 Flash (default) + Gemini 3 Pro (--pro)"
        echo "    Get key: https://aistudio.google.com/apikey"
    fi

    if echo "$found_keys" | grep -q "OPENAI"; then
        log_success "OPENAI_API_KEY detected (DALL-E, gpt-image-1)"
    else
        echo "  OPENAI_API_KEY — not found (optional)"
        echo "    Enables: OpenAI DALL-E 3 and gpt-image-1"
        echo "    Get key: https://platform.openai.com/api-keys"
    fi

    echo ""
    echo "  To configure, add to your shell profile (~/.bashrc or ~/.zshrc):"
    echo "    export GOOGLE_API_KEY='your-key-here'"
    echo ""
    echo "  Without API keys, the Designer genie works in prompt-only mode"
    echo "  (crafts optimized prompts you can paste into free tools)."
    echo ""
}

# Install imagegen MCP server for Designer genie
install_mcp_server() {
    local scope="$1"
    local force="$2"
    local dry_run="$3"

    # Gate: claude CLI must be available
    if ! check_claude_cli; then
        log_warn "Claude CLI not found — skipping MCP server installation"
        log_info "Install Claude Code, then run: $0 global --mcp"
        return 0
    fi

    # Collision detection: check if already installed at any scope
    if check_mcp_installed; then
        local existing_scope
        existing_scope=$(get_mcp_scope)
        if [[ "$force" != "true" ]]; then
            log_info "MCP server '$MCP_SERVER_NAME' already installed (scope: $existing_scope)"
            return 0
        fi
        # Force mode: remove existing before re-adding
        if [[ "$dry_run" == "true" ]]; then
            log_info "[DRY RUN] Would remove existing MCP server '$MCP_SERVER_NAME' (scope: $existing_scope)"
        else
            claude mcp remove "$MCP_SERVER_NAME" -s "$existing_scope" &>/dev/null 2>&1 || \
                claude mcp remove "$MCP_SERVER_NAME" &>/dev/null 2>&1 || true
            log_info "Removed existing MCP server '$MCP_SERVER_NAME' for reinstall"
        fi
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would install MCP server '$MCP_SERVER_NAME' (scope: $scope)"
        log_info "[DRY RUN] Package: $MCP_SERVER_PKG"
        return 0
    fi

    # Build --env flags from detected API keys in the current environment
    local env_flags=()
    [[ -n "${GOOGLE_API_KEY:-}" ]] && env_flags+=(-e "GOOGLE_API_KEY=${GOOGLE_API_KEY}")
    [[ -n "${OPENAI_API_KEY:-}" ]] && env_flags+=(-e "OPENAI_API_KEY=${OPENAI_API_KEY}")
    [[ -n "${REPLICATE_API_TOKEN:-}" ]] && env_flags+=(-e "REPLICATE_API_TOKEN=${REPLICATE_API_TOKEN}")
    # Pin Gemini image model to stable production version
    env_flags+=(-e "GOOGLE_IMAGE_MODEL=${GOOGLE_IMAGE_MODEL:-gemini-2.5-flash-image}")

    # Install the MCP server
    log_info "Installing MCP server '$MCP_SERVER_NAME' (scope: $scope)..."
    local add_output
    if add_output=$(claude mcp add "$MCP_SERVER_NAME" -s "$scope" "${env_flags[@]}" -- npx -y "$MCP_SERVER_PKG" 2>&1); then
        log_success "Installed MCP server: $MCP_SERVER_NAME"
    else
        log_error "Failed to install MCP server '$MCP_SERVER_NAME'"
        log_info "Output: $add_output"
        log_info "Install manually: claude mcp add -s $scope -e GOOGLE_API_KEY=\$GOOGLE_API_KEY $MCP_SERVER_NAME -- npx -y $MCP_SERVER_PKG"
        return 0
    fi

    # Report API key status
    local found_keys
    found_keys=$(detect_api_keys)
    if [[ -z "$found_keys" ]]; then
        print_api_key_guidance "$found_keys"
    else
        echo ""
        log_info "API key status:"
        echo "$found_keys" | grep -q "GOOGLE" && \
            log_success "  GOOGLE_API_KEY (Gemini Flash + Pro)"
        echo "$found_keys" | grep -q "OPENAI" && \
            log_success "  OPENAI_API_KEY (DALL-E, gpt-image-1)"
        echo "$found_keys" | grep -q "REPLICATE" && \
            log_success "  REPLICATE_API_TOKEN (Flux, Qwen, SeedDream)"
        echo ""
    fi

    return 0
}

# Clean only genie-team files before sync (preserves user's own files)
# $1 = source dir (in genie-team repo), $2 = dest dir (installed location)
# $3 = label, $4 = dry_run
clean_genie_files() {
    local src="$1"
    local dest="$2"
    local label="$3"
    local dry_run="$4"

    [[ ! -d "$dest" ]] && return 0
    [[ ! -d "$src" ]] && return 0

    local count=0
    for item in "$src"/*; do
        local name
        name=$(basename "$item")
        if [[ -d "$item" && -d "$dest/$name" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                log_info "[DRY RUN] Would remove $dest/$name/"
            else
                rm -rf "${dest:?}/${name:?}"
                count=$((count + 1))
            fi
        elif [[ -f "$item" && -f "$dest/$name" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                log_info "[DRY RUN] Would remove $dest/$name"
            else
                rm "$dest/$name"
                count=$((count + 1))
            fi
        fi
    done

    if [[ "$dry_run" != "true" && $count -gt 0 ]]; then
        log_info "Cleaned $count $label files for sync"
    fi
}

# Copy directory contents
copy_dir() {
    local src="$1"
    local dest="$2"
    local force="$3"
    local label="$4"

    if [[ ! -d "$src" ]]; then
        log_warn "Source not found: $src"
        return 1
    fi

    mkdir -p "$dest"
    local count=0

    # Handle nested directories (like skills/)
    if [[ -d "$src" ]]; then
        for item in "$src"/*; do
            if [[ -d "$item" ]]; then
                # It's a directory (e.g., skills/tdd-discipline/)
                local dirname=$(basename "$item")
                local target_dir="$dest/$dirname"

                if [[ -d "$target_dir" && "$force" != "true" ]]; then
                    log_warn "Skipping $label/$dirname (exists)"
                else
                    mkdir -p "$target_dir"
                    cp -r "$item"/* "$target_dir/" 2>/dev/null || true
                    count=$((count + 1))
                fi
            elif [[ -f "$item" ]]; then
                # It's a file
                local filename=$(basename "$item")
                local target_file="$dest/$filename"

                if [[ -f "$target_file" && "$force" != "true" ]]; then
                    log_warn "Skipping $label/$filename (exists)"
                else
                    cp "$item" "$target_file"
                    count=$((count + 1))
                fi
            fi
        done
    fi

    if [[ $count -gt 0 ]]; then
        log_success "Installed $count $label"
    fi
    return 0
}

# Install commands
install_commands() {
    local dest="$1"
    local force="$2"
    copy_dir "$SCRIPT_DIR/commands" "$dest" "$force" "commands"
}

# Install skills
install_skills() {
    local dest="$1"
    local force="$2"
    copy_dir "$SCRIPT_DIR/skills" "$dest" "$force" "skills"
}

# Install rules
install_rules() {
    local dest="$1"
    local force="$2"
    copy_dir "$SCRIPT_DIR/rules" "$dest" "$force" "rules"
}

# Install agents
install_agents() {
    local dest="$1"
    local force="$2"
    copy_dir "$SCRIPT_DIR/agents" "$dest" "$force" "agents"
}

# Install schemas
install_schemas() {
    local dest="$1"
    local force="$2"
    copy_dir "$SCRIPT_DIR/schemas" "$dest" "$force" "schemas"
}

# Install stack profile templates
install_stacks() {
    local dest="$1"
    local force="$2"
    copy_dir "$SCRIPT_DIR/stacks" "$dest" "$force" "stacks"
}

# Install consolidated genie specs (all .md files per genie)
install_genies() {
    local dest="$1"
    local force="$2"

    mkdir -p "$dest"
    local count=0

    for genie_dir in "$SCRIPT_DIR/genies"/*; do
        if [[ -d "$genie_dir" ]]; then
            local genie_name=$(basename "$genie_dir")
            local target_dir="$dest/$genie_name"
            mkdir -p "$target_dir"

            for md_file in "$genie_dir"/*.md; do
                if [[ -f "$md_file" ]]; then
                    local filename=$(basename "$md_file")
                    if [[ -f "$target_dir/$filename" && "$force" != "true" ]]; then
                        log_warn "Skipping genies/$genie_name/$filename (exists)"
                    else
                        cp "$md_file" "$target_dir/$filename"
                        count=$((count + 1))
                    fi
                fi
            done
        fi
    done

    if [[ $count -gt 0 ]]; then
        log_success "Installed $count genie files"
    fi
}

# Install scripts (genies only — single CLI entry point)
install_scripts() {
    local dest="$1"
    local force="$2"

    if [[ ! -d "$SCRIPT_DIR/scripts" ]]; then
        log_warn "Source not found: $SCRIPT_DIR/scripts"
        return 1
    fi

    mkdir -p "$dest"
    local count=0

    # Clean up legacy scripts from previous installations
    local legacy_files=("run-pdlc.sh" "run-batch.sh" "run-quality-checks.sh"
                        "genie-session.sh" "genie-quality")
    for legacy in "${legacy_files[@]}"; do
        if [[ -f "$dest/$legacy" ]]; then
            rm "$dest/$legacy"
            log_info "Removed legacy script: $legacy"
        fi
    done

    # Only install genies (the single entry point) to PATH.
    # genie-session is a library sourced by genies (not a standalone command).
    # genie-quality logic is inlined in genies quality subcommand.
    local script="$SCRIPT_DIR/scripts/genies"
    if [[ -f "$script" && -x "$script" ]]; then
        local target_file="$dest/genies"

        if [[ -f "$target_file" && "$force" != "true" ]]; then
            log_warn "Skipping scripts/genies (exists)"
        else
            cp "$script" "$target_file"
            chmod +x "$target_file"
            count=$((count + 1))
        fi
    fi

    # Copy genie-session library alongside genies (sourced, not on PATH directly)
    local session_lib="$SCRIPT_DIR/scripts/genie-session"
    if [[ -f "$session_lib" ]]; then
        cp "$session_lib" "$dest/genie-session"
        chmod +x "$dest/genie-session"
    fi

    # Copy validate/ directory (used by genies quality subcommand)
    if [[ -d "$SCRIPT_DIR/scripts/validate" ]]; then
        mkdir -p "$dest/validate"
        cp "$SCRIPT_DIR/scripts/validate"/*.sh "$dest/validate/" 2>/dev/null || true
        chmod +x "$dest/validate"/*.sh 2>/dev/null || true
    fi

    if [[ $count -gt 0 ]]; then
        log_success "Installed $count scripts"
    fi
    return 0
}

# Merge hook configuration into a settings file
merge_hook_config() {
    local settings_file="$1"
    local cmd_prefix="$2"

    local hook_config
    hook_config=$(cat << HOOKJSON
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${cmd_prefix}/track-command.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${cmd_prefix}/track-artifacts.sh"
          }
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${cmd_prefix}/verify-stack.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact|clear",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${cmd_prefix}/reinject-context.sh"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)

    if ! command -v jq &>/dev/null; then
        log_warn "jq not found — cannot merge hook configuration"
        log_info "Add hooks configuration manually to $settings_file"
        return 0
    fi

    mkdir -p "$(dirname "$settings_file")"

    if [[ -f "$settings_file" ]]; then
        local merged
        merged=$(jq --argjson hooks "$(echo "$hook_config" | jq '.hooks')" \
            '.hooks = (.hooks // {}) * $hooks' "$settings_file")
        echo "$merged" > "$settings_file"
        log_success "Merged hook config into $(basename "$settings_file")"
    else
        echo "$hook_config" | jq '.' > "$settings_file"
        log_success "Created $(basename "$settings_file") with hook config"
    fi
}

# Install hooks (scripts + settings configuration)
install_hooks() {
    local hooks_dest="$1"
    local settings_file="$2"
    local cmd_prefix="$3"
    local force="$4"

    if [[ ! -d "$SCRIPT_DIR/hooks" ]]; then
        log_warn "Source hooks not found: $SCRIPT_DIR/hooks"
        return 1
    fi

    mkdir -p "$hooks_dest"
    local count=0

    for script in "$SCRIPT_DIR/hooks"/*.sh; do
        if [[ -f "$script" ]]; then
            local filename=$(basename "$script")
            local target_file="$hooks_dest/$filename"

            if [[ -f "$target_file" && "$force" != "true" ]]; then
                log_warn "Skipping hooks/$filename (exists)"
            else
                cp "$script" "$target_file"
                chmod +x "$target_file"
                count=$((count + 1))
            fi
        fi
    done

    if [[ $count -gt 0 ]]; then
        log_success "Installed $count hook scripts"
    fi

    merge_hook_config "$settings_file" "$cmd_prefix"
}

# Global installation
cmd_global() {
    local force="false"
    local sync="false"
    local install_commands="false"
    local install_skills="false"
    local install_rules="false"
    local install_agents="false"
    local install_schemas="false"
    local install_stacks_flag="false"
    local install_scripts_flag="false"
    local install_hooks_flag="false"
    local install_mcp="false"
    local skip_mcp="false"
    local install_all="true"
    local dry_run="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force="true" ;;
            --sync) sync="true"; force="true" ;;
            --commands) install_commands="true"; install_all="false" ;;
            --skills) install_skills="true"; install_all="false" ;;
            --rules) install_rules="true"; install_all="false" ;;
            --agents) install_agents="true"; install_all="false" ;;
            --schemas) install_schemas="true"; install_all="false" ;;
            --stacks) install_stacks_flag="true"; install_all="false" ;;
            --scripts) install_scripts_flag="true"; install_all="false" ;;
            --hooks) install_hooks_flag="true"; install_all="false" ;;
            --mcp) install_mcp="true"; install_all="false" ;;
            --skip-mcp) skip_mcp="true" ;;
            --all) install_all="true" ;;
            --dry-run) dry_run="true" ;;
        esac
        shift
    done

    log_info "Installing Genie Team globally to $GLOBAL_CLAUDE_DIR/"
    [[ "$sync" == "true" ]] && log_info "Sync mode: will remove obsolete files"

    if [[ "$dry_run" == "true" ]]; then
        [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
            log_info "[DRY RUN] Would install commands"
        [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
            log_info "[DRY RUN] Would install skills"
        [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
            log_info "[DRY RUN] Would install rules"
        [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
            log_info "[DRY RUN] Would install agents"
        [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
            log_info "[DRY RUN] Would install schemas"
        [[ "$install_all" == "true" || "$install_stacks_flag" == "true" ]] && \
            log_info "[DRY RUN] Would install stack profiles"
        [[ "$install_all" == "true" || "$install_scripts_flag" == "true" ]] && \
            log_info "[DRY RUN] Would install scripts"
        [[ "$install_all" == "true" || "$install_scripts_flag" == "true" ]] && \
            setup_scripts_path "true"
        [[ "$install_all" == "true" || "$install_hooks_flag" == "true" ]] && \
            log_info "[DRY RUN] Would install hooks"
        if [[ "$skip_mcp" != "true" ]]; then
            [[ "$install_all" == "true" || "$install_mcp" == "true" ]] && \
                install_mcp_server "user" "$force" "true"
        fi
        [[ "$sync" == "true" ]] && \
            log_info "[DRY RUN] Would clean directories before installing"
        return 0
    fi

    # Clean genie-team files if sync mode (preserves user's own files)
    if [[ "$sync" == "true" ]]; then
        [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/commands" "$GLOBAL_CLAUDE_DIR/commands" "commands" "$dry_run"
        [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/skills" "$GLOBAL_CLAUDE_DIR/skills" "skills" "$dry_run"
        [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/rules" "$GLOBAL_CLAUDE_DIR/rules" "rules" "$dry_run"
        [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/agents" "$GLOBAL_CLAUDE_DIR/agents" "agents" "$dry_run"
        [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/schemas" "$GLOBAL_CLAUDE_DIR/schemas" "schemas" "$dry_run"
        [[ "$install_all" == "true" || "$install_stacks_flag" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/stacks" "$GLOBAL_CLAUDE_DIR/stacks" "stacks" "$dry_run"
        [[ "$install_all" == "true" || "$install_scripts_flag" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/scripts" "$GLOBAL_CLAUDE_DIR/scripts" "scripts" "$dry_run"
        [[ "$install_all" == "true" || "$install_hooks_flag" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/hooks" "$GLOBAL_CLAUDE_DIR/hooks" "hooks" "$dry_run"
    fi

    [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
        install_commands "$GLOBAL_CLAUDE_DIR/commands" "$force"

    [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
        install_skills "$GLOBAL_CLAUDE_DIR/skills" "$force"

    [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
        install_rules "$GLOBAL_CLAUDE_DIR/rules" "$force"

    [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
        install_agents "$GLOBAL_CLAUDE_DIR/agents" "$force"

    [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
        install_schemas "$GLOBAL_CLAUDE_DIR/schemas" "$force"

    [[ "$install_all" == "true" || "$install_stacks_flag" == "true" ]] && \
        install_stacks "$GLOBAL_CLAUDE_DIR/stacks" "$force"

    # Scripts installation (genies)
    [[ "$install_all" == "true" || "$install_scripts_flag" == "true" ]] && \
        install_scripts "$GLOBAL_CLAUDE_DIR/scripts" "$force"

    # Hooks installation (scripts + settings merge)
    [[ "$install_all" == "true" || "$install_hooks_flag" == "true" ]] && \
        install_hooks "$GLOBAL_CLAUDE_DIR/hooks" "$GLOBAL_CLAUDE_DIR/settings.json" "$GLOBAL_CLAUDE_DIR/hooks" "$force"

    # Add scripts to PATH (so genies works from any project)
    [[ "$install_all" == "true" || "$install_scripts_flag" == "true" ]] && \
        setup_scripts_path "$dry_run"

    # MCP server installation (scope: user = available to all projects)
    if [[ "$skip_mcp" != "true" ]]; then
        [[ "$install_all" == "true" || "$install_mcp" == "true" ]] && \
            install_mcp_server "user" "$force" "false"
    fi

    echo ""
    log_success "Global installation complete!"
    echo ""
    echo "Available:"
    echo "  Lifecycle:  /discover, /define, /design, /deliver, /discern, /done"
    echo "  Utility:    /commit (anytime)"
    echo "  Workflows:  /feature, /bugfix, /spike, /cleanup, /run"
    echo "  Brand:      /brand, /brand:image, /brand:tokens"
    echo "  Maintain:   /diagnose, /tidy"
    echo "  Bootstrap:  /spec:init, /arch:init, /arch --workshop"
    echo "  Context:    /context:load, /context:summary, /context:recall, /context:refresh,"
    echo "              /handoff"
    echo "  Help:       /genie:help, /genie:status"
    echo "  Skills:     tdd-discipline, code-quality, conventional-commits, problem-first,"
    echo "              pattern-enforcement, spec-awareness, architecture-awareness,"
    echo "              brand-awareness"
    echo "  Agents:     scout, shaper, architect, crafter, critic, tidier, designer"
    echo "  Schemas:    shaped-work-contract, design-document, execution-report, review-document,"
    echo "              adr, architecture-diagram, brand-spec"
    echo "  Stacks:     typescript, go, rust, csharp, java (language-specific quality profiles)"
    echo "  Scripts:    genies (autonomous runner + batch + session + quality)"
    echo "  Hooks:      context re-injection on compaction (track-command, track-artifacts, reinject-context)"
    echo "  MCP:        imagegen (image generation via Gemini/OpenAI)"
    echo ""
    echo "Scripts are on PATH — run from any project directory:"
    echo "  genies --parallel 3 --trunk --verbose"
    echo "  genies --through define \"explore auth improvements\""
    echo "  genies session list"
    echo "  genies quality docs/*.md"
}

# Project installation
cmd_project() {
    local project_path="."
    local force="false"
    local sync="false"
    local install_commands="false"
    local install_skills="false"
    local install_rules="false"
    local install_agents="false"
    local install_genies="false"
    local install_schemas="false"
    local install_stacks_flag="false"
    local install_scripts_flag="false"
    local install_hooks_flag="false"
    local install_mcp="false"
    local skip_mcp="false"
    local install_all="true"
    local dry_run="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force="true" ;;
            --sync) sync="true"; force="true" ;;
            --commands) install_commands="true"; install_all="false" ;;
            --skills) install_skills="true"; install_all="false" ;;
            --rules) install_rules="true"; install_all="false" ;;
            --agents) install_agents="true"; install_all="false" ;;
            --genies) install_genies="true"; install_all="false"; log_warn "DEPRECATED: --genies flag is deprecated. Genies are now consolidated into agents/. Use --agents instead." ;;
            --schemas) install_schemas="true"; install_all="false" ;;
            --stacks) install_stacks_flag="true"; install_all="false" ;;
            --scripts) install_scripts_flag="true"; install_all="false" ;;
            --hooks) install_hooks_flag="true"; install_all="false" ;;
            --mcp) install_mcp="true"; install_all="false" ;;
            --skip-mcp) skip_mcp="true" ;;
            --all) install_all="true" ;;
            --dry-run) dry_run="true" ;;
            *)
                if [[ -d "$1" ]]; then
                    project_path="$1"
                fi
                ;;
        esac
        shift
    done

    project_path="$(cd "$project_path" && pwd)"
    local claude_dir="$project_path/.claude"

    # Detect worktree context
    local is_worktree="false"
    local main_worktree=""
    if (cd "$project_path" && detect_worktree) 2>/dev/null; then
        is_worktree="true"
        main_worktree="$(cd "$project_path" && get_main_worktree)"
    fi

    # MCP scope: user in worktrees (shared across sessions), local otherwise (project-private)
    local mcp_scope="local"
    [[ "$is_worktree" == "true" ]] && mcp_scope="user"

    log_info "Installing Genie Team to $project_path/"
    [[ "$is_worktree" == "true" ]] && log_info "Worktree detected (main: $main_worktree)"
    [[ "$sync" == "true" ]] && log_info "Sync mode: will remove obsolete files"

    if [[ "$dry_run" == "true" ]]; then
        [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
            log_info "[DRY RUN] Would install commands to $claude_dir/commands/"
        [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
            log_info "[DRY RUN] Would install skills to $claude_dir/skills/"
        [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
            log_info "[DRY RUN] Would install rules to $claude_dir/rules/"
        [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
            log_info "[DRY RUN] Would install agents to $claude_dir/agents/"
        [[ "$install_genies" == "true" ]] && \
            log_info "[DRY RUN] Would install genie specs to $claude_dir/genies/ (DEPRECATED)"
        [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
            log_info "[DRY RUN] Would install schemas to $claude_dir/schemas/"
        [[ "$install_all" == "true" || "$install_stacks_flag" == "true" ]] && \
            log_info "[DRY RUN] Would install stack profiles to $claude_dir/stacks/"
        [[ "$install_all" == "true" || "$install_scripts_flag" == "true" ]] && \
            log_info "[DRY RUN] Would install scripts to $claude_dir/scripts/"
        [[ "$install_all" == "true" || "$install_hooks_flag" == "true" ]] && \
            log_info "[DRY RUN] Would install hooks to $claude_dir/hooks/"
        if [[ "$skip_mcp" != "true" ]]; then
            [[ "$install_all" == "true" || "$install_mcp" == "true" ]] && \
                install_mcp_server "$mcp_scope" "$force" "true"
        fi
        [[ "$sync" == "true" ]] && \
            log_info "[DRY RUN] Would clean directories before installing"
        return 0
    fi

    # Clean directories if sync mode
    if [[ "$sync" == "true" ]]; then
        [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/commands" "$claude_dir/commands" "commands" "$dry_run"
        [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/skills" "$claude_dir/skills" "skills" "$dry_run"
        [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/rules" "$claude_dir/rules" "rules" "$dry_run"
        [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/agents" "$claude_dir/agents" "agents" "$dry_run"
        [[ "$install_genies" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/genies" "$claude_dir/genies" "genies" "$dry_run"
        [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/schemas" "$claude_dir/schemas" "schemas" "$dry_run"
        [[ "$install_all" == "true" || "$install_stacks_flag" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/stacks" "$claude_dir/stacks" "stacks" "$dry_run"
        [[ "$install_all" == "true" || "$install_scripts_flag" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/scripts" "$claude_dir/scripts" "scripts" "$dry_run"
        [[ "$install_all" == "true" || "$install_hooks_flag" == "true" ]] && \
            clean_genie_files "$SCRIPT_DIR/hooks" "$claude_dir/hooks" "hooks" "$dry_run"
    fi

    [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
        install_commands "$claude_dir/commands" "$force"

    [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
        install_skills "$claude_dir/skills" "$force"

    [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
        install_rules "$claude_dir/rules" "$force"

    [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
        install_agents "$claude_dir/agents" "$force"

    [[ "$install_genies" == "true" ]] && \
        install_genies "$claude_dir/genies" "$force"

    [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
        install_schemas "$claude_dir/schemas" "$force"

    [[ "$install_all" == "true" || "$install_stacks_flag" == "true" ]] && \
        install_stacks "$claude_dir/stacks" "$force"

    # Scripts installation (genies)
    [[ "$install_all" == "true" || "$install_scripts_flag" == "true" ]] && \
        install_scripts "$claude_dir/scripts" "$force"

    # Hooks installation (scripts + settings merge)
    [[ "$install_all" == "true" || "$install_hooks_flag" == "true" ]] && \
        install_hooks "$claude_dir/hooks" "$claude_dir/settings.local.json" ".claude/hooks" "$force"

    # MCP server installation (scope determined above: user for worktrees, local otherwise)
    if [[ "$skip_mcp" != "true" ]]; then
        [[ "$install_all" == "true" || "$install_mcp" == "true" ]] && \
            install_mcp_server "$mcp_scope" "$force" "false"
    fi

    # Create project structure
    if [[ "$install_all" == "true" ]]; then
        mkdir -p "$project_path/docs/backlog"
        mkdir -p "$project_path/docs/analysis"
        mkdir -p "$project_path/docs/decisions"
        mkdir -p "$project_path/docs/specs"
        mkdir -p "$project_path/docs/architecture/components"
    fi

    # Worktree: symlink genie memory to main worktree (shared learning)
    if [[ "$is_worktree" == "true" && -n "$main_worktree" ]]; then
        local main_memory="$main_worktree/.claude/agent-memory"
        local wt_memory="$claude_dir/agent-memory"
        if [[ -d "$main_memory" && ! -L "$wt_memory" && ! -d "$wt_memory" ]]; then
            mkdir -p "$claude_dir"
            ln -sf "$main_memory" "$wt_memory"
            log_success "Linked genie memory to main worktree"
        elif [[ -L "$wt_memory" ]]; then
            log_info "Genie memory symlink already exists"
        fi
    fi

    echo ""
    log_success "Project installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Run /genie:help to see available commands"
    echo "  2. Start with /context:load, /discover [topic], or /feature [topic]"
    echo ""
    echo "Directories created:"
    echo "  docs/backlog/        — Living backlog items"
    echo "  docs/analysis/       — Discovery and design documents"
    echo "  docs/decisions/      — Architecture Decision Records (ADRs)"
    echo "  docs/architecture/   — C4 diagrams (system-context, containers, components)"
    echo "  docs/specs/          — Product specifications by domain"
    echo ""
    echo "Available:"
    echo "  Lifecycle:  /discover, /define, /design, /deliver, /discern, /done"
    echo "  Utility:    /commit (anytime)"
    echo "  Workflows:  /feature, /bugfix, /spike, /cleanup, /run"
    echo "  Brand:      /brand, /brand:image, /brand:tokens"
    echo "  Maintain:   /diagnose, /tidy"
    echo "  Bootstrap:  /spec:init, /arch:init, /arch --workshop"
    echo "  Context:    /context:load, /context:summary, /context:recall, /context:refresh,"
    echo "              /handoff"
    echo "  Help:       /genie:help, /genie:status"
    echo "  Skills:     tdd-discipline, code-quality, conventional-commits, problem-first,"
    echo "              pattern-enforcement, spec-awareness, architecture-awareness,"
    echo "              brand-awareness, stack-awareness"
    echo "  Agents:     scout, shaper, architect, crafter, critic, tidier, designer"
    echo "  Schemas:    shaped-work-contract, design-document, execution-report, review-document,"
    echo "              adr, architecture-diagram, brand-spec"
    echo "  Stacks:     typescript, go, rust, csharp, java (language-specific quality profiles)"
    echo "  Scripts:    genies (autonomous runner + batch + session + quality)"
    echo "  Hooks:      context re-injection on compaction (track-command, track-artifacts, reinject-context)"
    echo "  MCP:        imagegen (image generation via Gemini/OpenAI)"
}

# Show status
cmd_status() {
    echo "Genie Team Installation Status"
    echo "==============================="
    echo ""

    echo "Global (~/.claude/):"
    for dir in commands skills rules agents schemas stacks scripts hooks; do
        if [[ -d "$GLOBAL_CLAUDE_DIR/$dir" ]]; then
            local count=$(find "$GLOBAL_CLAUDE_DIR/$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "  $dir: $count files"
        else
            echo "  $dir: not installed"
        fi
    done
    if [[ -d "$GLOBAL_CLAUDE_DIR/agent-memory" ]]; then
        local mem_count=$(find "$GLOBAL_CLAUDE_DIR/agent-memory" -name "MEMORY.md" 2>/dev/null | wc -l | tr -d ' ')
        echo "  agent-memory: $mem_count agents with memory"
    fi

    echo ""
    echo "Project (./.claude/):"
    for dir in commands skills rules agents schemas stacks hooks scripts; do
        if [[ -d "./.claude/$dir" ]]; then
            local count=$(find "./.claude/$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "  $dir: $count files"
        else
            echo "  $dir: not installed"
        fi
    done
    if [[ -d "./.claude/agent-memory" ]]; then
        local mem_count=$(find "./.claude/agent-memory" -name "MEMORY.md" 2>/dev/null | wc -l | tr -d ' ')
        echo "  agent-memory: $mem_count agents with memory"
    fi

    echo ""
    if [[ -f "./CLAUDE.md" ]]; then
        echo "CLAUDE.md: found"
    else
        echo "CLAUDE.md: not found"
    fi

    echo ""
    echo "MCP Servers:"
    if check_claude_cli; then
        if check_mcp_installed; then
            local mcp_scope
            mcp_scope=$(get_mcp_scope)
            echo "  $MCP_SERVER_NAME: installed (scope: $mcp_scope)"
        else
            echo "  $MCP_SERVER_NAME: not installed"
        fi
    else
        echo "  Claude CLI not found — cannot check MCP status"
    fi
}

# Uninstall
cmd_uninstall() {
    local target="${1:-}"

    case "$target" in
        global)
            log_info "Removing global installation..."
            for dir in commands skills rules agents schemas scripts hooks; do
                if [[ -d "$GLOBAL_CLAUDE_DIR/$dir" ]]; then
                    clean_genie_files "$SCRIPT_DIR/$dir" "$GLOBAL_CLAUDE_DIR/$dir" "$dir" "false"
                    # Remove directory only if empty after cleaning
                    rmdir "$GLOBAL_CLAUDE_DIR/$dir" 2>/dev/null && \
                        log_success "Removed $dir (empty)" || \
                        log_success "Cleaned genie-team files from $dir"
                fi
            done
            # agent-memory is entirely genie-team owned — safe to remove
            if [[ -d "$GLOBAL_CLAUDE_DIR/agent-memory" ]]; then
                rm -rf "${GLOBAL_CLAUDE_DIR:?}/agent-memory"
                log_success "Removed agent-memory"
            fi
            # Clean up PATH entry from shell profile
            local profile
            profile="$(detect_shell_profile)"
            if [[ -f "$profile" ]] && grep -qF '.claude/scripts' "$profile"; then
                sed -i'' -e '/# Genie Team scripts/d' -e '/\.claude\/scripts/d' "$profile"
                log_success "Removed PATH entry from $profile"
            fi
            if check_claude_cli && check_mcp_installed; then
                local mcp_scope
                mcp_scope=$(get_mcp_scope)
                if [[ "$mcp_scope" == "user" ]]; then
                    claude mcp remove "$MCP_SERVER_NAME" -s user &>/dev/null 2>&1 && \
                        log_success "Removed MCP server: $MCP_SERVER_NAME (global)"
                else
                    log_info "MCP server '$MCP_SERVER_NAME' installed at scope '$mcp_scope' — skipping (use 'uninstall project' to remove local)"
                fi
            fi
            ;;
        project)
            log_info "Removing project installation..."
            for dir in commands skills rules agents hooks schemas scripts; do
                if [[ -d "./.claude/$dir" ]]; then
                    clean_genie_files "$SCRIPT_DIR/$dir" "./.claude/$dir" "$dir" "false"
                    rmdir "./.claude/$dir" 2>/dev/null && \
                        log_success "Removed $dir (empty)" || \
                        log_success "Cleaned genie-team files from $dir"
                fi
            done
            # genies/ is entirely genie-team owned — safe to remove
            if [[ -d "./.claude/genies" ]]; then
                rm -rf "./.claude/genies"
                log_success "Removed genies"
            fi
            if check_claude_cli && check_mcp_installed; then
                local mcp_scope
                mcp_scope=$(get_mcp_scope)
                if [[ "$mcp_scope" == "local" ]]; then
                    claude mcp remove "$MCP_SERVER_NAME" -s local &>/dev/null 2>&1 && \
                        log_success "Removed MCP server: $MCP_SERVER_NAME (local)"
                else
                    log_info "MCP server '$MCP_SERVER_NAME' installed at scope '$mcp_scope' — skipping (use 'uninstall global' to remove user-scope)"
                fi
            fi
            ;;
        *)
            log_error "Specify 'global' or 'project'"
            exit 1
            ;;
    esac
}

# Pre-commit hook installation (standalone, non-destructive)
cmd_prehook() {
    local target_path="."
    local force="false"
    local dry_run="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force="true" ;;
            --dry-run) dry_run="true" ;;
            *)
                if [[ -d "$1" ]]; then
                    target_path="$1"
                fi
                ;;
        esac
        shift
    done

    target_path="$(cd "$target_path" && pwd)"

    log_info "Installing pre-commit hooks to $target_path/"

    # Guard: must be a git repo
    if [[ ! -d "$target_path/.git" ]]; then
        log_error "$target_path is not a git repository"
        exit 1
    fi

    # Guard: check for existing .pre-commit-config.yaml
    if [[ -f "$target_path/.pre-commit-config.yaml" && "$force" != "true" ]]; then
        log_error ".pre-commit-config.yaml already exists at $target_path"
        log_info "Use --force to overwrite, or manually merge from:"
        log_info "  $SCRIPT_DIR/templates/pre-commit-config.yaml"
        exit 1
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would install .pre-commit-config.yaml"
        log_info "[DRY RUN] Would install .yamllint.yml"
        log_info "[DRY RUN] Would install scripts/validate/ scripts"
        if command -v pre-commit &>/dev/null; then
            log_info "[DRY RUN] Would run pre-commit install"
        fi
        return 0
    fi

    # 1. Copy .pre-commit-config.yaml template
    cp "$SCRIPT_DIR/templates/pre-commit-config.yaml" "$target_path/.pre-commit-config.yaml"
    log_success "Installed .pre-commit-config.yaml"

    # 2. Copy .yamllint.yml template (skip if exists and not force)
    if [[ ! -f "$target_path/.yamllint.yml" || "$force" == "true" ]]; then
        cp "$SCRIPT_DIR/templates/yamllint.yml" "$target_path/.yamllint.yml"
        log_success "Installed .yamllint.yml"
    else
        log_warn "Skipping .yamllint.yml (exists)"
    fi

    # 3. Copy validation scripts
    mkdir -p "$target_path/scripts/validate"
    local count=0
    for script in "$SCRIPT_DIR/scripts/validate"/*.sh; do
        if [[ -f "$script" ]]; then
            cp "$script" "$target_path/scripts/validate/"
            chmod +x "$target_path/scripts/validate/$(basename "$script")"
            count=$((count + 1))
        fi
    done
    log_success "Installed $count validation scripts to scripts/validate/"

    # 4. Run pre-commit install if available
    if command -v pre-commit &>/dev/null; then
        (cd "$target_path" && pre-commit install) 2>/dev/null && \
            log_success "Ran pre-commit install" || \
            log_warn "pre-commit install failed — run manually: cd $target_path && pre-commit install"
    else
        log_warn "pre-commit not found — install it to activate hooks:"
        log_info "  brew install pre-commit  OR  pip install pre-commit"
        log_info "  Then run: cd $target_path && pre-commit install"
    fi

    echo ""
    log_success "Pre-commit hooks installed!"
    echo ""
    echo "Hooks installed:"
    echo "  Tier 1: YAML frontmatter lint, shellcheck, check-json, check-yaml"
    echo "  Tier 2: Frontmatter schema validation (required fields, enum values)"
    echo "  Tier 3: Cross-reference integrity (spec_ref, adr_refs, etc.)"
    echo "  Tier 4: Source/installed sync (disabled in template — configure SYNC_MAP)"
    echo ""
    echo "Bypass: git commit --no-verify"
}

# Support sourcing for tests (skip main dispatch)
if [[ "${INSTALL_SOURCED:-}" == "true" ]]; then
    return 0 2>/dev/null || true
fi

# Main
case "${1:-}" in
    global)   shift; cmd_global "$@" ;;
    project)  shift; cmd_project "$@" ;;
    prehook)  shift; cmd_prehook "$@" ;;
    status)   cmd_status ;;
    uninstall) shift; cmd_uninstall "$@" ;;
    -h|--help|help|"") print_usage ;;
    *)
        # Treat first arg as path for convenience
        if [[ -d "$1" ]]; then
            cmd_project "$@"
        else
            log_error "Unknown command: $1"
            print_usage
            exit 1
        fi
        ;;
esac
