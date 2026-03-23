'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { ArrowLeftIcon, UserGroupIcon, MagnifyingGlassIcon, ChevronRightIcon } from '@heroicons/react/24/outline';

interface Agent {
  id: string;
  name: string;
  role: string;
  status: 'online' | 'busy' | 'offline';
  emoji?: string;
  description?: string;
  tools?: string[];
  subAgents?: Agent[];
  lastActive?: string;
  color?: string;
}

export default function TeamMap() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [search, setSearch] = useState('');
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);
  const [expandedAgents, setExpandedAgents] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // 模拟完整的团队层级数据
    const mockAgents: Agent[] = [
      {
        id: 'orchestrator',
        name: 'Orchestrator',
        role: '团队协调者',
        status: 'online',
        emoji: '🎯',
        description: '负责任务分发、资源协调和整体监控',
        tools: ['sessions_spawn', 'subagents', 'sessions_send'],
        lastActive: '刚刚',
        color: 'from-purple-500 to-pink-500',
        subAgents: [
          {
            id: 'testclaude',
            name: 'TestClaude',
            role: '测试与质量保障',
            status: 'online',
            emoji: '🧪',
            description: '负责自动化测试、质量保障和 CI/CD 流程',
            tools: ['test_all_fixes.sh', 'review-pr.sh', 'notify.sh'],
            lastActive: '2分钟前',
            color: 'from-blue-500 to-cyan-500',
            subAgents: [
              { id: 'qa-1', name: 'QA Assistant', role: '测试执行', status: 'busy', emoji: '🔍', lastActive: '5分钟前' },
              { id: 'qa-2', name: 'Code Reviewer', role: '代码审查', status: 'online', emoji: '👁️', lastActive: '刚刚' },
            ]
          },
          {
            id: 'github',
            name: 'GitHub Assistant',
            role: '代码协作',
            status: 'busy',
            emoji: '🐙',
            description: '处理 issues、PR 和代码审查',
            tools: ['gh issue', 'gh pr', 'gh api'],
            lastActive: '1分钟前',
            color: 'from-gray-600 to-gray-800',
          },
          {
            id: 'feishu',
            name: 'Feishu Bot',
            role: '通知与文档',
            status: 'online',
            emoji: '📝',
            description: '发送通知、处理文档',
            tools: ['feishu_doc', 'feishu_wiki', 'message'],
            lastActive: '3分钟前',
            color: 'from-green-500 to-emerald-500',
          },
          {
            id: 'weather',
            name: 'Weather Agent',
            role: '数据采集',
            status: 'online',
            emoji: '🌤️',
            description: '天气数据采集和分析',
            tools: ['weather.py', 'web_fetch'],
            lastActive: '10分钟前',
            color: 'from-yellow-500 to-orange-500',
          },
        ]
      }
    ];
    setAgents(mockAgents);
    setLoading(false);
  }, []);

  const toggleExpand = (agentId: string) => {
    setExpandedAgents(prev =>
      prev.includes(agentId) ? prev.filter(id => id !== agentId) : [...prev, agentId]
    );
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online': return 'bg-green-500';
      case 'busy': return 'bg-yellow-500';
      default: return 'bg-gray-400';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'online': return '在线';
      case 'busy': return '忙碌';
      default: return '离线';
    }
  };

  const renderAgentTree = (agent: Agent, level: number = 0) => {
    const isExpanded = expandedAgents.includes(agent.id);
    const hasChildren = agent.subAgents && agent.subAgents.length > 0;

    return (
      <div key={agent.id} className="relative">
        <div
          className={`ml-${level * 6} relative flex items-start space-x-3 p-4 rounded-lg cursor-pointer transition-all hover:bg-gray-50 dark:hover:bg-gray-700/50 ${
            selectedAgent?.id === agent.id ? 'bg-blue-50 dark:bg-blue-900/20 border-l-4 border-blue-500' : ''
          }`}
          onClick={() => setSelectedAgent(agent)}
        >
          {/* 连接线 */}
          {level > 0 && (
            <div className="absolute left-0 top-1/2 w-6 h-px bg-gray-300 dark:bg-gray-600" />
          )}
          
          {/* 展开/折叠按钮 */}
          {hasChildren && (
            <button
              onClick={(e) => { e.stopPropagation(); toggleExpand(agent.id); }}
              className="absolute -left-2 top-1/2 transform -translate-y-1/2 w-4 h-4 bg-gray-200 dark:bg-gray-600 rounded-full flex items-center justify-center text-xs"
            >
              {isExpanded ? '−' : '+'}
            </button>
          )}

          {/* Agent 图标 */}
          <div className={`w-12 h-12 bg-gradient-to-r ${agent.color || 'from-blue-500 to-purple-500'} rounded-full flex items-center justify-center text-2xl shadow-md`}>
            {agent.emoji || '🤖'}
          </div>

          {/* Agent 信息 */}
          <div className="flex-1">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white">{agent.name}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">{agent.role}</p>
              </div>
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full ${getStatusColor(agent.status)}`} />
                <span className="text-xs text-gray-500">{getStatusText(agent.status)}</span>
                {agent.lastActive && (
                  <span className="text-xs text-gray-400">· {agent.lastActive}</span>
                )}
              </div>
            </div>
            {agent.description && (
              <p className="text-sm text-gray-600 dark:text-gray-300 mt-1">{agent.description}</p>
            )}
          </div>
          <ChevronRightIcon className="w-5 h-5 text-gray-400" />
        </div>

        {/* 子 Agent */}
        {hasChildren && isExpanded && (
          <div className="ml-6 border-l-2 border-gray-200 dark:border-gray-700">
            {agent.subAgents!.map(sub => renderAgentTree(sub, level + 1))}
          </div>
        )}
      </div>
    );
  };

  const filteredAgents = agents.filter(agent => 
    agent.name.toLowerCase().includes(search.toLowerCase()) ||
    agent.role.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="mb-8">
          <Link href="/" className="inline-flex items-center text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white mb-4">
            <ArrowLeftIcon className="w-4 h-4 mr-2" />
            返回仪表板
          </Link>
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">团队地图</h1>
              <p className="text-gray-600 dark:text-gray-400 mt-2">查看 Agent 层级关系和实时状态</p>
            </div>
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="搜索 Agent..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              />
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* 团队树 */}
          <div className="lg:col-span-2 bg-white dark:bg-gray-800 rounded-lg shadow-md overflow-hidden">
            <div className="p-4 border-b border-gray-200 dark:border-gray-700">
              <h2 className="font-semibold text-gray-900 dark:text-white">组织结构</h2>
            </div>
            <div className="p-4 max-h-[600px] overflow-y-auto">
              {loading ? (
                <div className="text-center py-8">加载中...</div>
              ) : (
                filteredAgents.map(agent => renderAgentTree(agent))
              )}
            </div>
          </div>

          {/* Agent 详情面板 */}
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md">
            <div className="p-4 border-b border-gray-200 dark:border-gray-700">
              <h2 className="font-semibold text-gray-900 dark:text-white">Agent 详情</h2>
            </div>
            <div className="p-4">
              {selectedAgent ? (
                <div className="space-y-4">
                  <div className="flex items-center space-x-3">
                    <div className={`w-16 h-16 bg-gradient-to-r ${selectedAgent.color || 'from-blue-500 to-purple-500'} rounded-full flex items-center justify-center text-3xl`}>
                      {selectedAgent.emoji || '🤖'}
                    </div>
                    <div>
                      <h3 className="text-xl font-bold text-gray-900 dark:text-white">{selectedAgent.name}</h3>
                      <p className="text-gray-500">{selectedAgent.role}</p>
                    </div>
                  </div>
                  
                  {selectedAgent.description && (
                    <div>
                      <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">描述</h4>
                      <p className="text-sm text-gray-600 dark:text-gray-400">{selectedAgent.description}</p>
                    </div>
                  )}
                  
                  {selectedAgent.tools && selectedAgent.tools.length > 0 && (
                    <div>
                      <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">可用工具</h4>
                      <div className="flex flex-wrap gap-2">
                        {selectedAgent.tools.map(tool => (
                          <span key={tool} className="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded text-xs font-mono">
                            {tool}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                  
                  <div>
                    <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">最后活跃</h4>
                    <p className="text-sm text-gray-600">{selectedAgent.lastActive || '未知'}</p>
                  </div>
                  
                  <button className="w-full mt-4 bg-blue-600 hover:bg-blue-700 text-white py-2 rounded-lg transition-colors">
                    开始对话 →
                  </button>
                </div>
              ) : (
                <div className="text-center py-8 text-gray-500">
                  <UserGroupIcon className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                  <p>选择一个 Agent 查看详情</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
