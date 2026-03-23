# GitHub Webhook Integration for TestClaude Team

## Overview

This setup adds GitHub webhook listening and CI waiting capabilities to the testclaude team orchestration system.

## New Scripts

### 1. `scripts/github-webhook-listener.sh`
Listens for GitHub webhook events and triggers appropriate actions:
- **Push events**: Notifies about new pushes
- **PR events**: Tracks PR creation, updates, merges
- **CI events**: Monitors check suite and check run completions
- **Status events**: Handles commit status updates

### 2. `scripts/wait-for-ci.sh`
Waits for GitHub Actions CI to complete:
- Polls GitHub API for check run status
- Handles success, failure, and timeout scenarios
- Updates task registry with CI status
- Auto-triggers review requests on success
- Auto-respawns agent on failure

### 3. Enhanced `scripts/notify.sh`
Now supports sending notifications to:
- Discord (via webhook)
- Slack (via webhook)
- Custom webhook endpoints
- Falls back to pending file queue

## Setup Instructions

### 1. Configure GitHub Webhook

Go to your GitHub repository settings:
1. Settings → Webhooks → Add webhook
2. Payload URL: `http://your-server:8080/webhook`
3. Content type: `application/json`
4. Secret: Generate a secure secret (e.g., `openssl rand -hex 32`)
5. Events: Select "Let me select individual events":
   - Pull requests
   - Push
   - Check suite
   - Check run
   - Status
6. Active: ✓

### 2. Set Up Environment Variables

Create or edit `/home/administrator/.openclaw-zero/workspace/teams/testclaude/.env`:

```bash
# GitHub webhook secret (must match what you set in GitHub)
GITHUB_WEBHOOK_SECRET=your-secret-here

# Notification webhooks (optional)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
CUSTOM_WEBHOOK_URL=https://your-service.com/webhook
```

### 3. Configure GitHub CLI Authentication

The `wait-for-ci.sh` script requires GitHub CLI to be authenticated:

```bash
# Authenticate (one-time)
gh auth login
# Choose: GitHub.com, HTTPS, Login with a web browser
```

### 4. Run the Webhook Listener

#### Option A: Direct execution (for testing)
```bash
cd ~/.openclaw-zero/workspace/teams/testclaude
./scripts/github-webhook-listener.sh --port 8080 --secret your-secret
```

#### Option B: As a systemd service (production)

1. Edit the service file with your webhook secret:
```bash
nano ~/.openclaw-zero/workspace/teams/testclaude/scripts/github-webhook.service
```

2. Install and start the service:
```bash
# Copy service file to systemd
sudo cp ~/.openclaw-zero/workspace/teams/testclaude/scripts/github-webhook.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable github-webhook
sudo systemctl start github-webhook

# Check status
sudo systemctl status github-webhook

# View logs
sudo journalctl -u github-webhook -f
```

#### Option C: Using cron with background job
```bash
# Add to crontab (runs at boot)
@reboot cd ~/.openclaw-zero/workspace/teams/testclaude && ./scripts/github-webhook-listener.sh --port 8080 &
```

### 5. Test the Webhook

Send a test webhook to verify everything works:

```bash
# Test PR event
curl -X POST http://localhost:8080 \
  -H "X-GitHub-Event: pull_request" \
  -H "X-Hub-Signature-256: sha256=$(echo -n '{"action":"opened"}' | openssl dgst -sha256 -hmac your-secret | awk '{print $2}')" \
  -d '{"action":"opened","pull_request":{"number":1,"title":"Test PR","head":{"ref":"feature/test"}},"repository":{"full_name":"test/repo"}}'
```

## Integration with Orchestrator

The webhook listener integrates with the existing orchestrator workflow:

1. **When PR is opened**:
   - Automatically starts `wait-for-ci.sh`
   - Updates task registry with PR info
   - Sends notification

2. **When CI passes**:
   - Updates task registry
   - Sends success notification
   - Auto-triggers `review-pr.sh` (if configured)

3. **When CI fails**:
   - Updates task registry
   - Sends failure notification
   - Auto-triggers `respawn-agent.sh` with failure context

4. **When PR is merged**:
   - Triggers `cleanup-agents.sh` for the task
   - Sends merge notification

## Monitoring

### Check webhook listener status
```bash
# If running as service
sudo systemctl status github-webhook

# Check logs
tail -f ~/.openclaw-zero/workspace/teams/testclaude/swarm/logs/webhook-*.log

# Check if port is listening
netstat -tlnp | grep 8080
```

### Manual CI status check
```bash
# Wait for CI on a specific PR
./scripts/wait-for-ci.sh owner/repo 123 --timeout 1800

# Check PR status
./scripts/check-pr-status.sh owner/repo 123
```

### View pending notifications
```bash
cat ~/.openclaw-zero/workspace/teams/testclaude/swarm/notifications/pending.json
```

## Configuration Options

### Webhook Listener
- `--port`: Port to listen on (default: 8080)
- `--secret`: GitHub webhook secret for verification

### CI Wait
- `--timeout`: Maximum wait time in seconds (default: 3600)
- `--poll-interval`: Check interval in seconds (hardcoded: 30)

### Notifications
- `DISCORD_WEBHOOK_URL`: Discord webhook URL
- `SLACK_WEBHOOK_URL`: Slack webhook URL
- `CUSTOM_WEBHOOK_URL`: Custom webhook endpoint

## Security Notes

1. **Webhook Secret**: Always use a strong secret and keep it secure
2. **Network Access**: Consider running behind a reverse proxy (nginx) for HTTPS
3. **Authentication**: GitHub CLI must be authenticated with appropriate permissions
4. **Rate Limits**: The script respects GitHub API rate limits with polling intervals

## Troubleshooting

### Webhook not received
- Check if firewall allows port 8080
- Verify webhook URL is correct and reachable
- Check webhook logs: `tail -f ~/.openclaw-zero/workspace/teams/testclaude/swarm/logs/webhook-*.log`

### CI status not updating
- Verify GitHub CLI is authenticated: `gh auth status`
- Check if the PR has CI checks configured
- Increase timeout value for long-running CI

### Notifications not sending
- Verify webhook URLs are correct
- Check if channels are configured in environment
- Check pending notifications: `cat ~/.openclaw-zero/workspace/teams/testclaude/swarm/notifications/pending.json`

## Next Steps

1. Configure webhook in your GitHub repository
2. Set up environment variables with your webhook URLs
3. Start the webhook listener (as service for production)
4. Test with a sample PR
5. Monitor logs to verify everything works

For questions or issues, check the logs and ensure all dependencies are installed (jq, nc, openssl, gh).
