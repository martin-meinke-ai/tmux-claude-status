# Custom tmux-claude-status Modifications

This is your custom version of tmux-claude-status with additional features.

## Location
- **Development version**: `~/Dev/tmux-claude-status/` (this directory)
- **Installed version**: `~/.config/tmux/plugins/tmux-claude-status/`

## Custom Features Added

### 1. Git Branch Tracking
- Shows the current git branch for each Claude session
- Branch indicator: 🌿 branch-name
- Displayed in both session switcher and status line

### 2. Unread Status
- Sessions where Claude has finished but you haven't visited are marked as "unread"
- Unread indicator: 📬
- Automatically cleared when you switch to the session
- Helps identify which sessions need your attention

## Installation

To apply changes from this development directory to your active installation:

```bash
# Copy all modified files
cp ~/Dev/tmux-claude-status/hooks/better-hook.sh ~/.config/tmux/plugins/tmux-claude-status/hooks/
cp ~/Dev/tmux-claude-status/scripts/*.sh ~/.config/tmux/plugins/tmux-claude-status/scripts/

# Reload tmux configuration
tmux source ~/.tmux.conf
```

## Files Modified

- `hooks/better-hook.sh` - Captures branch info and manages unread status
- `scripts/hook-based-switcher.sh` - Displays branch and unread indicators
- `scripts/status-line.sh` - Shows branch and unread counts in status bar

## Status Files

The plugin creates these files in `~/.cache/tmux-claude-status/`:
- `{session}.status` - Current status (working/done)
- `{session}.branch` - Current git branch
- `{session}.unread` - Unread marker (presence indicates unread)
- `{session}-remote.*` - Remote versions for SSH sessions

## Testing

Use the test script to verify everything is working:
```bash
~/test-branch-status.sh
```

## Original Repository
https://github.com/samleeney/tmux-claude-status