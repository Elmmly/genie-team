#!/bin/bash
# Genie Team Installer
# Install genie-team commands, skills, rules, agents, schemas, genies, and MCP servers

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
  status              Show installation status
  uninstall           Remove genie-team installation

Options:
  --commands          Install commands only
  --skills            Install skills only
  --rules             Install rules only
  --agents            Install agents only
  --genies            Install genie specs only (project only)
  --schemas           Install schemas only
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

# MCP server configuration
MCP_SERVER_NAME="imagegen"
MCP_SERVER_PKG="@fastmcp-me/imagegen-mcp"

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

# Clean directory before sync (removes obsolete files)
clean_dir() {
    local dest="$1"
    local label="$2"
    local dry_run="$3"

    if [[ -d "$dest" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_info "[DRY RUN] Would remove $dest/ before sync"
        else
            rm -rf "$dest"
            log_info "Cleaned $label for sync"
        fi
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
                    ((count++))
                fi
            elif [[ -f "$item" ]]; then
                # It's a file
                local filename=$(basename "$item")
                local target_file="$dest/$filename"

                if [[ -f "$target_file" && "$force" != "true" ]]; then
                    log_warn "Skipping $label/$filename (exists)"
                else
                    cp "$item" "$target_file"
                    ((count++))
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
    copy_dir "$SCRIPT_DIR/.claude/commands" "$dest" "$force" "commands"
}

# Install skills
install_skills() {
    local dest="$1"
    local force="$2"
    copy_dir "$SCRIPT_DIR/.claude/skills" "$dest" "$force" "skills"
}

# Install rules
install_rules() {
    local dest="$1"
    local force="$2"
    copy_dir "$SCRIPT_DIR/.claude/rules" "$dest" "$force" "rules"
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
                        ((count++))
                    fi
                fi
            done
        fi
    done

    if [[ $count -gt 0 ]]; then
        log_success "Installed $count genie files"
    fi
}

# Create CLAUDE.md template
create_claude_md() {
    local target="$1"
    local force="$2"

    if [[ -f "$target" && "$force" != "true" ]]; then
        log_warn "Skipping CLAUDE.md (exists)"
        return
    fi

    cp "$SCRIPT_DIR/templates/CLAUDE.md" "$target" 2>/dev/null || cat > "$target" << 'EOF'
# Project Name

> Brief description of this project

## Genie Team Quick Reference

- `/genie:help` - Show all commands
- `/feature [topic]` - Full lifecycle delivery
- `/bugfix [issue]` - Quick fix flow

### The 7 D's Lifecycle
```
/discover → /define → /design → /deliver → /discern → /commit → /done
```

## Project Context

### Overview
<!-- What this project does -->

### Architecture
<!-- Key components and patterns -->

### Conventions
<!-- Project-specific standards -->
EOF

    log_success "Created CLAUDE.md template"
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
        if [[ "$skip_mcp" != "true" ]]; then
            [[ "$install_all" == "true" || "$install_mcp" == "true" ]] && \
                install_mcp_server "user" "$force" "true"
        fi
        [[ "$sync" == "true" ]] && \
            log_info "[DRY RUN] Would clean directories before installing"
        return 0
    fi

    # Clean directories if sync mode
    if [[ "$sync" == "true" ]]; then
        [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
            clean_dir "$GLOBAL_CLAUDE_DIR/commands" "commands" "$dry_run"
        [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
            clean_dir "$GLOBAL_CLAUDE_DIR/skills" "skills" "$dry_run"
        [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
            clean_dir "$GLOBAL_CLAUDE_DIR/rules" "rules" "$dry_run"
        [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
            clean_dir "$GLOBAL_CLAUDE_DIR/agents" "agents" "$dry_run"
        [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
            clean_dir "$GLOBAL_CLAUDE_DIR/schemas" "schemas" "$dry_run"
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

    # MCP server installation (scope: user = available to all projects)
    if [[ "$skip_mcp" != "true" ]]; then
        [[ "$install_all" == "true" || "$install_mcp" == "true" ]] && \
            install_mcp_server "user" "$force" "false"
    fi

    echo ""
    log_success "Global installation complete!"
    echo ""
    echo "Available:"
    echo "  Lifecycle:  /discover, /define, /design, /deliver, /discern, /commit, /done"
    echo "  Workflows:  /feature, /bugfix, /spike, /cleanup"
    echo "  Brand:      /brand, /brand:image, /brand:tokens"
    echo "  Maintain:   /diagnose, /tidy"
    echo "  Bootstrap:  /spec:init, /arch:init"
    echo "  Context:    /context:load, /context:summary, /context:recall, /context:refresh,"
    echo "              /handoff"
    echo "  Help:       /genie:help, /genie:status"
    echo "  Skills:     tdd-discipline, code-quality, conventional-commits, problem-first,"
    echo "              pattern-enforcement, spec-awareness, architecture-awareness,"
    echo "              brand-awareness"
    echo "  Agents:     scout, architect, critic, tidier, designer"
    echo "  Schemas:    shaped-work-contract, design-document, execution-report, review-document,"
    echo "              adr, architecture-diagram, brand-spec"
    echo "  MCP:        imagegen (image generation via Gemini/OpenAI)"
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
            --genies) install_genies="true"; install_all="false" ;;
            --schemas) install_schemas="true"; install_all="false" ;;
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

    log_info "Installing Genie Team to $project_path/"
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
        [[ "$install_all" == "true" || "$install_genies" == "true" ]] && \
            log_info "[DRY RUN] Would install genie specs to $claude_dir/genies/"
        [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
            log_info "[DRY RUN] Would install schemas to $project_path/schemas/"
        if [[ "$skip_mcp" != "true" ]]; then
            [[ "$install_all" == "true" || "$install_mcp" == "true" ]] && \
                install_mcp_server "local" "$force" "true"
        fi
        [[ "$sync" == "true" ]] && \
            log_info "[DRY RUN] Would clean directories before installing"
        return 0
    fi

    # Clean directories if sync mode
    if [[ "$sync" == "true" ]]; then
        [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
            clean_dir "$claude_dir/commands" "commands" "$dry_run"
        [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
            clean_dir "$claude_dir/skills" "skills" "$dry_run"
        [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
            clean_dir "$claude_dir/rules" "rules" "$dry_run"
        [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
            clean_dir "$claude_dir/agents" "agents" "$dry_run"
        [[ "$install_all" == "true" || "$install_genies" == "true" ]] && \
            clean_dir "$claude_dir/genies" "genies" "$dry_run"
        [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
            clean_dir "$project_path/schemas" "schemas" "$dry_run"
    fi

    [[ "$install_all" == "true" || "$install_commands" == "true" ]] && \
        install_commands "$claude_dir/commands" "$force"

    [[ "$install_all" == "true" || "$install_skills" == "true" ]] && \
        install_skills "$claude_dir/skills" "$force"

    [[ "$install_all" == "true" || "$install_rules" == "true" ]] && \
        install_rules "$claude_dir/rules" "$force"

    [[ "$install_all" == "true" || "$install_agents" == "true" ]] && \
        install_agents "$claude_dir/agents" "$force"

    [[ "$install_all" == "true" || "$install_genies" == "true" ]] && \
        install_genies "$claude_dir/genies" "$force"

    [[ "$install_all" == "true" || "$install_schemas" == "true" ]] && \
        install_schemas "$project_path/schemas" "$force"

    # MCP server installation (scope: local = project-private)
    if [[ "$skip_mcp" != "true" ]]; then
        [[ "$install_all" == "true" || "$install_mcp" == "true" ]] && \
            install_mcp_server "local" "$force" "false"
    fi

    # Create project structure
    if [[ "$install_all" == "true" ]]; then
        mkdir -p "$project_path/docs/backlog"
        mkdir -p "$project_path/docs/analysis"
        mkdir -p "$project_path/docs/decisions"
        mkdir -p "$project_path/docs/specs"
        mkdir -p "$project_path/docs/architecture/components"
        create_claude_md "$project_path/CLAUDE.md" "$force"
    fi

    echo ""
    log_success "Project installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit CLAUDE.md with your project details"
    echo "  2. Run /genie:help to see available commands"
    echo "  3. Start with /context:load, /discover [topic], or /feature [topic]"
    echo ""
    echo "Directories created:"
    echo "  docs/backlog/        — Living backlog items"
    echo "  docs/analysis/       — Discovery and design documents"
    echo "  docs/decisions/      — Architecture Decision Records (ADRs)"
    echo "  docs/architecture/   — C4 diagrams (system-context, containers, components)"
    echo "  docs/specs/          — Product specifications by domain"
    echo ""
    echo "Available:"
    echo "  Lifecycle:  /discover, /define, /design, /deliver, /discern, /commit, /done"
    echo "  Workflows:  /feature, /bugfix, /spike, /cleanup"
    echo "  Brand:      /brand, /brand:image, /brand:tokens"
    echo "  Maintain:   /diagnose, /tidy"
    echo "  Bootstrap:  /spec:init, /arch:init"
    echo "  Context:    /context:load, /context:summary, /context:recall, /context:refresh,"
    echo "              /handoff"
    echo "  Help:       /genie:help, /genie:status"
    echo "  Skills:     tdd-discipline, code-quality, conventional-commits, problem-first,"
    echo "              pattern-enforcement, spec-awareness, architecture-awareness,"
    echo "              brand-awareness"
    echo "  Agents:     scout, architect, critic, tidier, designer"
    echo "  Genies:     scout, shaper, architect, crafter, critic, tidier, designer"
    echo "  Schemas:    shaped-work-contract, design-document, execution-report, review-document,"
    echo "              adr, architecture-diagram, brand-spec"
    echo "  MCP:        imagegen (image generation via Gemini/OpenAI)"
}

# Show status
cmd_status() {
    echo "Genie Team Installation Status"
    echo "==============================="
    echo ""

    echo "Global (~/.claude/):"
    for dir in commands skills rules agents schemas; do
        if [[ -d "$GLOBAL_CLAUDE_DIR/$dir" ]]; then
            local count=$(find "$GLOBAL_CLAUDE_DIR/$dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
            echo "  $dir: $count files"
        else
            echo "  $dir: not installed"
        fi
    done

    echo ""
    echo "Project (./.claude/ and ./schemas/):"
    for dir in commands skills rules agents genies; do
        if [[ -d "./.claude/$dir" ]]; then
            local count=$(find "./.claude/$dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
            echo "  $dir: $count files"
        else
            echo "  $dir: not installed"
        fi
    done
    if [[ -d "./schemas" ]]; then
        local count=$(find "./schemas" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        echo "  schemas: $count files"
    else
        echo "  schemas: not installed"
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
            for dir in commands skills rules agents schemas; do
                if [[ -d "$GLOBAL_CLAUDE_DIR/$dir" ]]; then
                    rm -rf "$GLOBAL_CLAUDE_DIR/$dir"
                    log_success "Removed $dir"
                fi
            done
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
            for dir in commands skills rules agents genies; do
                if [[ -d "./.claude/$dir" ]]; then
                    rm -rf "./.claude/$dir"
                    log_success "Removed $dir"
                fi
            done
            if [[ -d "./schemas" ]]; then
                rm -rf "./schemas"
                log_success "Removed schemas"
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

# Main
case "${1:-}" in
    global)   shift; cmd_global "$@" ;;
    project)  shift; cmd_project "$@" ;;
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
