'use client';

import { useState, useRef, useEffect } from 'react';
import Link from 'next/link';
import { 
  ArrowLeftIcon, 
  PaperAirplaneIcon, 
  UserIcon, 
  MicrophoneIcon, 
  PaperClipIcon,
  FaceSmileIcon,
  XMarkIcon
} from '@heroicons/react/24/outline';

interface Message {
  id: string;
  role: 'user' | 'agent';
  content: string;
  timestamp: Date;
  agentName?: string;
  agentAvatar?: string;
  attachments?: { name: string; url: string }[];
  isTyping?: boolean;
}

interface Agent {
  id: string;
  name: string;
  avatar: string;
  status: 'online' | 'busy' | 'offline';
  description: string;
}

export default function Chat() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [selectedAgent, setSelectedAgent] = useState<string>('all');
  const [agents, setAgents] = useState<Agent[]>([]);
  const [isTyping, setIsTyping] = useState(false);
  const [showAgentPanel, setShowAgentPanel] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    // 模拟 Agent 数据
    const mockAgents: Agent[] = [
      { id: 'testclaude', name: 'TestClaude', avatar: '🧪', status: 'online', description: '测试与质量保障专家' },
      { id: 'github', name: 'GitHub Assistant', avatar: '🐙', status: 'busy', description: '代码审查和 PR 管理' },
      { id: 'feishu', name: 'Feishu Bot', avatar: '📝', status: 'online', description: '文档处理和通知' },
      { id: 'weather', name: 'Weather Agent', avatar: '🌤️', status: 'online', description: '天气数据采集' },
    ];
    setAgents(mockAgents);

    // 欢迎消息
    setMessages([
      {
        id: 'welcome',
        role: 'agent',
        content: '👋 你好！我是 TestClaude 团队的助手。我可以帮你管理 Agent、查看任务、分析数据、处理文档。\n\n有什么需要帮助的吗？',
        timestamp: new Date(),
        agentName: 'TestClaude Assistant',
        agentAvatar: '🎯'
      }
    ]);
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input,
      timestamp: new Date()
    };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsTyping(true);

    // 模拟 Agent 响应延迟
    setTimeout(() => {
      const response = generateResponse(input, selectedAgent);
      const agentMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'agent',
        content: response,
        timestamp: new Date(),
        agentName: selectedAgent === 'all' ? 'TestClaude Assistant' : agents.find(a => a.id === selectedAgent)?.name,
        agentAvatar: selectedAgent === 'all' ? '🎯' : agents.find(a => a.id === selectedAgent)?.avatar
      };
      setMessages(prev => [...prev, agentMessage]);
      setIsTyping(false);
    }, 1000 + Math.random() * 1000);
  };

  const generateResponse = (query: string, agentId: string): string => {
    const lowerQuery = query.toLowerCase();
    
    if (lowerQuery.includes('agent') || lowerQuery.includes('团队')) {
      const agentList = agents.map(a => `- ${a.avatar} **${a.name}**: ${a.description} (${a.status === 'online' ? '在线' : '忙碌'})`).join('\n');
      return `TestClaude 团队共有 ${agents.length} 个 Agent：\n\n${agentList}\n\n需要了解哪个 Agent 的详细信息？我可以帮你与特定 Agent 对话。`;
    }
    
    if (lowerQuery.includes('任务') || lowerQuery.includes('看板')) {
      return `📊 **任务看板统计**\n\n- 待办任务: 3 个\n- 进行中: 2 个\n- 已完成: 1 个\n\n**高优先级任务**:\n1. 开发 API 端点 (截止: 2024-01-18)\n2. 前端仪表板 (截止: 2024-01-17)\n3. 部署到生产 (截止: 2024-01-20)\n\n需要查看详细任务列表吗？`;
    }
    
    if (lowerQuery.includes('成本') || lowerQuery.includes('费用')) {
      return `💰 **本月成本分析**\n\n总成本: $12.45\n\n按 Agent 分布:\n- TestClaude: $4.50 (36%)\n- GitHub Assistant: $3.20 (26%)\n- Feishu Bot: $2.80 (22%)\n- Weather Agent: $1.95 (16%)\n\n成本趋势: 较上周上涨 8%，建议检查 API 使用情况。`;
    }
    
    if (lowerQuery.includes('天气')) {
      return `🌤️ **天气查询**\n\n上海: ☀️ 晴，8°C，湿度 49%\n北京: ☁️ 多云，5°C，湿度 65%\n深圳: 🌧️ 小雨，18°C，湿度 83%\n\n需要查询其他城市吗？`;
    }
    
    if (lowerQuery.includes('帮助') || lowerQuery.includes('help')) {
      return `📖 **我可以帮你做什么？**\n\n1. **团队管理**: 查看 Agent 状态、团队地图\n2. **任务管理**: 创建任务、查看看板、跟踪进度\n3. **成本分析**: 查看费用统计、优化建议\n4. **文档处理**: 读取 Feishu 文档、生成报告\n5. **代码协作**: 审查 PR、管理 Issues\n6. **数据查询**: 天气信息、系统状态\n\n直接告诉我你想做什么！`;
    }
    
    return `收到你的消息："${query}"\n\n我可以帮你：\n✅ 查看 Agent 状态和团队信息\n✅ 管理任务看板和跟踪进度\n✅ 分析成本数据和使用情况\n✅ 查询天气和其他数据\n✅ 处理文档和发送通知\n\n需要什么帮助？`;
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-6xl mx-auto px-4 py-8">
        <div className="mb-8">
          <Link href="/" className="inline-flex items-center text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white mb-4">
            <ArrowLeftIcon className="w-4 h-4 mr-2" />
            返回仪表板
          </Link>
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">对话</h1>
              <p className="text-gray-600 dark:text-gray-400 mt-2">与 Agent 实时交流，获取帮助</p>
            </div>
            <button
              onClick={() => setShowAgentPanel(!showAgentPanel)}
              className="flex items-center space-x-2 px-4 py-2 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
            >
              <UserIcon className="w-5 h-5" />
              <span>切换 Agent</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* Agent 列表侧边栏 */}
          {showAgentPanel && (
            <div className="lg:col-span-1 bg-white dark:bg-gray-800 rounded-lg shadow-md p-4">
              <h3 className="font-semibold mb-3 text-gray-900 dark:text-white">可用 Agent</h3>
              <div className="space-y-2">
                <button
                  onClick={() => { setSelectedAgent('all'); setShowAgentPanel(false); }}
                  className={`w-full text-left p-3 rounded-lg transition-colors ${selectedAgent === 'all' ? 'bg-blue-50 dark:bg-blue-900/20 border-l-4 border-blue-500' : 'hover:bg-gray-50 dark:hover:bg-gray-700'}`}
                >
                  <div className="flex items-center space-x-3">
                    <span className="text-2xl">🎯</span>
                    <div>
                      <p className="font-medium">所有 Agent</p>
                      <p className="text-xs text-gray-500">智能路由</p>
                    </div>
                  </div>
                </button>
                {agents.map(agent => (
                  <button
                    key={agent.id}
                    onClick={() => { setSelectedAgent(agent.id); setShowAgentPanel(false); }}
                    className={`w-full text-left p-3 rounded-lg transition-colors ${selectedAgent === agent.id ? 'bg-blue-50 dark:bg-blue-900/20 border-l-4 border-blue-500' : 'hover:bg-gray-50 dark:hover:bg-gray-700'}`}
                  >
                    <div className="flex items-center space-x-3">
                      <span className="text-2xl">{agent.avatar}</span>
                      <div className="flex-1">
                        <div className="flex items-center space-x-2">
                          <p className="font-medium">{agent.name}</p>
                          <div className={`w-2 h-2 rounded-full ${agent.status === 'online' ? 'bg-green-500' : agent.status === 'busy' ? 'bg-yellow-500' : 'bg-gray-400'}`} />
                        </div>
                        <p className="text-xs text-gray-500">{agent.description}</p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* 聊天区域 */}
          <div className={`${showAgentPanel ? 'lg:col-span-3' : 'lg:col-span-4'} bg-white dark:bg-gray-800 rounded-lg shadow-md overflow-hidden flex flex-col h-[600px]`}>
            {/* 聊天头部 */}
            <div className="p-4 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-700/50">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full flex items-center justify-center text-xl">
                  {selectedAgent === 'all' ? '🎯' : agents.find(a => a.id === selectedAgent)?.avatar || '🤖'}
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 dark:text-white">
                    {selectedAgent === 'all' ? 'TestClaude Assistant' : agents.find(a => a.id === selectedAgent)?.name}
                  </h3>
                  <p className="text-xs text-gray-500">
                    {selectedAgent === 'all' ? '在线 · 随时为您服务' : agents.find(a => a.id === selectedAgent)?.status === 'online' ? '在线' : '忙碌中'}
                  </p>
                </div>
              </div>
            </div>

            {/* 消息列表 */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              {messages.map((message) => (
                <div
                  key={message.id}
                  className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  <div className={`max-w-[70%] ${message.role === 'user' ? 'order-2' : 'order-1'}`}>
                    {message.role === 'agent' && (
                      <div className="flex items-center space-x-2 mb-1">
                        <span className="text-sm font-medium text-gray-600 dark:text-gray-400">
                          {message.agentName}
                        </span>
                        <span className="text-xs text-gray-400">{formatTime(message.timestamp)}</span>
                      </div>
                    )}
                    <div className={`rounded-lg p-3 ${
                      message.role === 'user'
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white'
                    }`}>
                      <div className="whitespace-pre-wrap">{message.content}</div>
                    </div>
                    {message.role === 'user' && (
                      <div className="text-right mt-1">
                        <span className="text-xs text-gray-400">{formatTime(message.timestamp)}</span>
                      </div>
                    )}
                  </div>
                  {message.role === 'agent' && (
                    <div className="w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 to-purple-500 flex items-center justify-center text-sm mr-3">
                      {message.agentAvatar || '🎯'}
                    </div>
                  )}
                </div>
              ))}
              {isTyping && (
                <div className="flex justify-start">
                  <div className="bg-gray-100 dark:bg-gray-700 rounded-lg p-3">
                    <div className="flex space-x-1">
                      <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" />
                      <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-100" />
                      <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-200" />
                    </div>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* 输入区域 */}
            <div className="p-4 border-t border-gray-200 dark:border-gray-700">
              <div className="flex items-end space-x-2">
                <button className="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">
                  <PaperClipIcon className="w-5 h-5" />
                </button>
                <button className="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">
                  <MicrophoneIcon className="w-5 h-5" />
                </button>
                <button className="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">
                  <FaceSmileIcon className="w-5 h-5" />
                </button>
                <textarea
                  ref={inputRef}
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyPress={handleKeyPress}
                  placeholder="输入消息... (Enter 发送)"
                  className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white resize-none focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={1}
                />
                <button
                  onClick={handleSend}
                  disabled={!input.trim() || isTyping}
                  className="p-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <PaperAirplaneIcon className="w-5 h-5" />
                </button>
              </div>
              <p className="text-xs text-gray-400 mt-2">
                当前对话模式: {selectedAgent === 'all' ? '智能路由 (自动选择最佳 Agent)' : `直接与 ${agents.find(a => a.id === selectedAgent)?.name} 对话`}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
