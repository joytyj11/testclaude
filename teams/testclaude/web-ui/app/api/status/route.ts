import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';
import path from 'path';

const execAsync = promisify(exec);

interface Agent {
  name: string;
  role: string;
  status: 'online' | 'offline' | 'busy';
  lastActive: string;
}

export async function GET() {
  try {
    // 检查 OpenClaw Gateway 状态
    let gatewayRunning = false;
    let gatewayVersion = '';
    try {
      const { stdout } = await execAsync('openclaw gateway status 2>&1');
      gatewayRunning = stdout.includes('running') || stdout.includes('listening');
      gatewayVersion = stdout.match(/version: (\d+\.\d+\.\d+)/)?.[1] || '';
    } catch (error) {
      console.error('Gateway check failed:', error);
    }

    // 读取 Agent 配置
    const workspacePath = process.env.WORKSPACE_PATH || '/home/administrator/.openclaw-zero/workspace';
    const agents: Agent[] = [];

    // 读取主 Agent
    const soulPath = path.join(workspacePath, 'SOUL.md');
    if (fs.existsSync(soulPath)) {
      const content = fs.readFileSync(soulPath, 'utf-8');
      const nameMatch = content.match(/name:\s*(.+)/i);
      agents.push({
        name: nameMatch ? nameMatch[1] : 'Main Agent',
        role: 'Orchestrator',
        status: 'online',
        lastActive: new Date().toLocaleString(),
      });
    }

    // 读取团队配置
    const teamPath = path.join(workspacePath, 'teams/testclaude');
    if (fs.existsSync(teamPath)) {
      // TestClaude 团队
      agents.push({
        name: 'TestClaude Team',
        role: 'Testing & QA',
        status: 'online',
        lastActive: new Date().toLocaleString(),
      });
    }

    // 读取 Agent 列表
    const agentsDir = path.join(workspacePath, 'agents');
    if (fs.existsSync(agentsDir)) {
      const dirs = fs.readdirSync(agentsDir);
      for (const dir of dirs) {
        const agentSoul = path.join(agentsDir, dir, 'SOUL.md');
        if (fs.existsSync(agentSoul)) {
          const content = fs.readFileSync(agentSoul, 'utf-8');
          const nameMatch = content.match(/name:\s*(.+)/i);
          agents.push({
            name: nameMatch ? nameMatch[1] : dir,
            role: 'Sub Agent',
            status: Math.random() > 0.7 ? 'busy' : 'online',
            lastActive: new Date().toLocaleString(),
          });
        }
      }
    }

    return NextResponse.json({
      agents,
      gateway: {
        running: gatewayRunning,
        version: gatewayVersion,
        port: 18789,
        uptime: 'N/A',
      },
    });
  } catch (error) {
    console.error('Status API error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch status' },
      { status: 500 }
    );
  }
}
