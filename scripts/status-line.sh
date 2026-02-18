#!/usr/bin/env bash

# Status line script for tmux status bar
# Shows Claude status across all sessions

STATUS_DIR="$HOME/.cache/tmux-claude-status"
NOTIFICATION_SOUND="/usr/share/sounds/freedesktop/stereo/complete.oga"
LAST_STATUS_FILE="$STATUS_DIR/.last-status-summary"

# Count Claude sessions by status and collect branch info
count_claude_status() {
    local working=0
    local done=0
    local unread=0
    local total_claude=0
    local working_branches=""

    # Check all tmux sessions including SSH remote status
    while IFS= read -r session; do
        [ -z "$session" ] && continue

        # Check for SSH remote status file (e.g., reachgpu-remote.status)
        local remote_status_file="$STATUS_DIR/${session}-remote.status"
        local status_file="$STATUS_DIR/${session}.status"
        local remote_branch_file="$STATUS_DIR/${session}-remote.branch"
        local branch_file="$STATUS_DIR/${session}.branch"
        local remote_unread_file="$STATUS_DIR/${session}-remote.unread"
        local unread_file="$STATUS_DIR/${session}.unread"

        # Get branch for this session
        local branch=""
        if [ -f "$remote_branch_file" ]; then
            branch=$(cat "$remote_branch_file" 2>/dev/null)
        elif [ -f "$branch_file" ]; then
            branch=$(cat "$branch_file" 2>/dev/null)
        fi

        # Check if unread
        local is_unread=false
        if [ -f "$remote_unread_file" ] || [ -f "$unread_file" ]; then
            is_unread=true
        fi

        # Check if we have any status for this session
        if [ -f "$remote_status_file" ]; then
            # SSH session with remote status
            local status=$(cat "$remote_status_file" 2>/dev/null)
            if [ -n "$status" ]; then
                ((total_claude++))
                case "$status" in
                    "working")
                        ((working++))
                        if [ -n "$branch" ]; then
                            if [ -z "$working_branches" ]; then
                                working_branches="$branch"
                            else
                                working_branches="$working_branches,$branch"
                            fi
                        fi
                        ;;
                    "done")
                        if [ "$is_unread" = true ]; then
                            ((unread++))
                        else
                            ((done++))
                        fi
                        ;;
                    "wait") ((working++)) ;;  # Treat wait as working for status line
                esac
            fi
        elif [ -f "$status_file" ]; then
            # Local session status
            local status=$(cat "$status_file" 2>/dev/null)
            if [ -n "$status" ]; then
                ((total_claude++))
                case "$status" in
                    "working")
                        ((working++))
                        if [ -n "$branch" ]; then
                            if [ -z "$working_branches" ]; then
                                working_branches="$branch"
                            else
                                working_branches="$working_branches,$branch"
                            fi
                        fi
                        ;;
                    "done")
                        if [ "$is_unread" = true ]; then
                            ((unread++))
                        else
                            ((done++))
                        fi
                        ;;
                    "wait") ((working++)) ;;  # Treat wait as working for status line
                esac
            fi
        fi
    done < <(tmux list-sessions -F "#{session_name}" 2>/dev/null)

    echo "$working:$done:$unread:$total_claude:$working_branches"
}

# Play notification sound
play_notification() {
    if command -v paplay >/dev/null 2>&1 && [ -f "$NOTIFICATION_SOUND" ]; then
        paplay "$NOTIFICATION_SOUND" 2>/dev/null &
    elif command -v afplay >/dev/null 2>&1; then
        # macOS fallback
        afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
    elif command -v beep >/dev/null 2>&1; then
        # Terminal beep fallback
        beep 2>/dev/null &
    else
        # Last resort: terminal bell
        echo -ne '\a'
    fi
}

# Get current status
IFS=':' read -r working done unread total_claude working_branches <<< "$(count_claude_status)"

# Load previous status
prev_working=0
if [ -f "$LAST_STATUS_FILE" ]; then
    prev_working=$(cat "$LAST_STATUS_FILE" 2>/dev/null || echo "0")
fi

# Save current working count
echo "$working" > "$LAST_STATUS_FILE"

# Check if any Claude just finished (working count decreased)
if [ "$prev_working" -gt "$working" ] && [ "$prev_working" -gt 0 ]; then
    play_notification
fi

# Format branch info if present
branch_info=""
if [ -n "$working_branches" ] && [ "$working" -gt 0 ]; then
    # Deduplicate branches (in case multiple Claudes are on same branch)
    unique_branches=$(echo "$working_branches" | tr ',' '\n' | sort -u | paste -sd',' -)
    # Format for display
    branch_info=" #[fg=cyan]🌿 $unique_branches#[default]"
fi

# Generate status line output
if [ "$total_claude" -eq 0 ]; then
    # No Claude sessions
    echo ""
elif [ "$working" -eq 0 ] && [ "$unread" -eq 0 ] && [ "$done" -gt 0 ]; then
    # All Claudes are done and read
    echo "#[fg=green,bold]✓ All Claudes ready#[default]"
elif [ "$unread" -gt 0 ] && [ "$working" -eq 0 ]; then
    # Some unread, no working
    if [ "$done" -gt 0 ]; then
        echo "#[fg=magenta,bold]📬 $unread unread#[default] #[fg=green]✓ $done done#[default]"
    else
        echo "#[fg=magenta,bold]📬 $unread unread#[default]"
    fi
elif [ "$working" -gt 0 ] && [ "$unread" -gt 0 ]; then
    # Some working, some unread
    if [ "$done" -gt 0 ]; then
        echo "#[fg=yellow,bold]⚡ $working working#[default]$branch_info #[fg=magenta]📬 $unread unread#[default] #[fg=green]✓ $done done#[default]"
    else
        echo "#[fg=yellow,bold]⚡ $working working#[default]$branch_info #[fg=magenta]📬 $unread unread#[default]"
    fi
elif [ "$working" -gt 0 ] && [ "$done" -gt 0 ]; then
    # Some working, some done (no unread)
    echo "#[fg=yellow,bold]⚡ $working working#[default]$branch_info #[fg=green]✓ $done done#[default]"
elif [ "$working" -gt 0 ]; then
    # All Claudes are working
    if [ "$working" -eq 1 ]; then
        echo "#[fg=yellow,bold]⚡ Claude is working#[default]$branch_info"
    else
        echo "#[fg=yellow,bold]⚡ $working Claudes are working#[default]$branch_info"
    fi
fi