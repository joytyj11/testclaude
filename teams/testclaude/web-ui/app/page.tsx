'use client';

import { useEffect, useState } from 'react';
import { 
  HomeIcon, 
  ChatBubbleLeftRightIcon, 
  ChartBarIcon, 
  ClockIcon,
  ServerIcon,
  CommandLineIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';

interface Agent {
  name: string;
  role: string;
  status: 'online' | 'offline' | 'busy';
  lastActive: string;
}

interface GatewayStatus {
  running: boolean;
  version?: string;
  port?: number;
  uptime?: string;
}

export default function Home() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [gateway, setGateway] = useState<GatewayStatus>({ running: false });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchStatus = async () => {
    try {
      const response = await fetch('/api/status');
      const data = await response.json();
      setAgents(data.agents || []);
      setGateway(data.gateway || { running: false });
    } catch (error) {
      console.error('Failed to fetch status:', error);
      toast.error('无法连接到 OpenClaw Gateway');
    } finally {
      setLoading(false);
    }
  };

  const handleRestartGateway = async () => {
    toast.loading('正在重启 Gateway...');
    try {
      const response = await fetch('/api/gateway/restart', { method: 'POST' });
      const data = await response.json();
      if (data.success) {
        toast.success('Gateway 重启成功');
        setTimeout(fetchStatus, 2000);
      } else {
        toast.error('重启失败: ' + data.error);
      }
    } catch (error) {
      toast.error('重启失败');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <header className="bg-white dark:bg-gray-800 shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold">TC</span>
              </div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                TestClaude Manager
              </h1>
              <span className="text-sm text-gray-500 dark:text-gray-400">v1.0.0</span>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full ${gateway.running ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`} />
                <span className="text-sm text-gray-600 dark:text-gray-300">
                  Gateway {gateway.running ? '运行中' : '未运行'}
                </span>
              </div>
              {!gateway.running && (
                <button onClick={handleRestartGateway} className="btn-primary text-sm">
                  启动 Gateway
                </button>
              )}
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="stat-card">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-blue-100 text-sm">活跃 Agents</p>
                <p className="text-3xl font-bold mt-2">{agents.filter(a => a.status === 'online').length}</p>
              </div>
              <CommandLineIcon className="w-10 h-10 text-blue-200" />
            </div>
          </div>
          
          <div className="stat-card bg-gradient-to-br from-green-500 to-teal-600">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-green-100 text-sm">总 Agents</p>
                <p className="text-3xl font-bold mt-2">{agents.length}</p>
              </div>
              <ServerIcon className="w-10 h-10 text-green-200" />
            </div>
          </div>
          
          <div className="stat-card bg-gradient-to-br from-orange-500 to-red-600">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-orange-100 text-sm">活跃会话</p>
                <p className="text-3xl font-bold mt-2">{agents.filter(a => a.status === 'busy').length}</p>
              </div>
              <ChatBubbleLeftRightIcon className="w-10 h-10 text-orange-200" />
            </div>
          </div>
          
          <div className="stat-card bg-gradient-to-br from-purple-500 to-pink-600">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-purple-100 text-sm">系统负载</p>
                <p className="text-3xl font-bold mt-2">{Math.round(agents.length / 10 * 100)}%</p>
              </div>
              <ChartBarIcon className="w-10 h-10 text-purple-200" />
            </div>
          </div>
        </div>

        {/* Agents List */}
        <div className="card mb-8">
          <h2 className="text-xl font-semibold mb-4 text-gray-900 dark:text-white">
            🤖 团队成员
          </h2>
          {loading ? (
            <div className="text-center py-8 text-gray-500">加载中...</div>
          ) : agents.length === 0 ? (
            <div className="text-center py-8 text-gray-500">暂无 Agent 数据</div>
          ) : (
            <div className="space-y-3">
              {agents.map((agent, idx) => (
                <div key={idx} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:shadow transition-shadow">
                  <div className="flex items-center space-x-3">
                    <div className={`w-3 h-3 rounded-full ${
                      agent.status === 'online' ? 'bg-green-500' : 
                      agent.status === 'busy' ? 'bg-yellow-500' : 'bg-gray-400'
                    }`} />
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">{agent.name}</p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">{agent.role}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-gray-600 dark:text-gray-300">
                      {agent.status === 'online' ? '在线' : agent.status === 'busy' ? '忙碌' : '离线'}
                    </p>
                    <p className="text-xs text-gray-400">{agent.lastActive}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="card">
            <div className="flex items-center space-x-3 mb-3">
              <ChatBubbleLeftRightIcon className="w-6 h-6 text-blue-600" />
              <h3 className="text-lg font-semibold">快速对话</h3>
            </div>
            <p className="text-gray-600 dark:text-gray-300 text-sm mb-4">
              与任意 Agent 进行实时对话
            </p>
            <button className="btn-primary w-full">
              开始对话 →
            </button>
          </div>
          
          <div className="card">
            <div className="flex items-center space-x-3 mb-3">
              <ClockIcon className="w-6 h-6 text-green-600" />
              <h3 className="text-lg font-semibold">任务监控</h3>
            </div>
            <p className="text-gray-600 dark:text-gray-300 text-sm mb-4">
              查看运行中的任务和队列
            </p>
            <button className="btn-secondary w-full">
              查看任务 →
            </button>
          </div>
          
          <div className="card">
            <div className="flex items-center space-x-3 mb-3">
              <ChartBarIcon className="w-6 h-6 text-purple-600" />
              <h3 className="text-lg font-semibold">性能分析</h3>
            </div>
            <p className="text-gray-600 dark:text-gray-300 text-sm mb-4">
              查看资源使用和性能指标
            </p>
            <button className="btn-secondary w-full">
              查看报告 →
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}
