'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeftIcon, PlusIcon, XMarkIcon, UserIcon, CalendarIcon } from '@heroicons/react/24/outline';

interface Task {
  id: string;
  title: string;
  description: string;
  status: 'todo' | 'in-progress' | 'done';
  agent?: string;
  priority: 'high' | 'medium' | 'low';
  createdAt: string;
  dueDate?: string;
  labels?: string[];
}

export default function Kanban() {
  const [tasks, setTasks] = useState<Task[]>([
    { id: '1', title: '开发 API 端点', description: '实现风力发电机监控 API，包括 /api/current、/api/history', status: 'todo', agent: 'TestClaude', priority: 'high', createdAt: '2024-01-15', dueDate: '2024-01-18', labels: ['backend', 'api'] },
    { id: '2', title: '前端仪表板', description: '使用 ECharts 实现实时图表和健康评分仪表', status: 'in-progress', agent: 'UI Team', priority: 'high', createdAt: '2024-01-15', dueDate: '2024-01-17', labels: ['frontend', 'visualization'] },
    { id: '3', title: '编写测试用例', description: 'API 自动化测试，覆盖所有端点', status: 'todo', agent: 'QA Team', priority: 'medium', createdAt: '2024-01-14', dueDate: '2024-01-19', labels: ['testing', 'automation'] },
    { id: '4', title: '文档更新', description: '更新 API 文档和 README', status: 'done', agent: 'TestClaude', priority: 'low', createdAt: '2024-01-13', dueDate: '2024-01-15', labels: ['documentation'] },
    { id: '5', title: '部署到生产', description: '配置 CI/CD 并部署到服务器', status: 'todo', agent: 'DevOps', priority: 'high', createdAt: '2024-01-15', dueDate: '2024-01-20', labels: ['deployment', 'devops'] },
    { id: '6', title: '性能优化', description: '优化 API 响应时间和数据库查询', status: 'in-progress', agent: 'TestClaude', priority: 'medium', createdAt: '2024-01-14', dueDate: '2024-01-18', labels: ['performance'] },
  ]);

  const [showNewTask, setShowNewTask] = useState(false);
  const [newTask, setNewTask] = useState<Partial<Task>>({});
  const [draggedTask, setDraggedTask] = useState<string | null>(null);

  const columns = {
    todo: { title: '待办', color: 'bg-gray-100 dark:bg-gray-700', icon: '📋' },
    'in-progress': { title: '进行中', color: 'bg-yellow-50 dark:bg-yellow-900/20', icon: '⚡' },
    done: { title: '已完成', color: 'bg-green-50 dark:bg-green-900/20', icon: '✅' }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'text-red-600 bg-red-100 dark:bg-red-900/30 dark:text-red-400';
      case 'medium': return 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900/30 dark:text-yellow-400';
      default: return 'text-green-600 bg-green-100 dark:bg-green-900/30 dark:text-green-400';
    }
  };

  const getPriorityText = (priority: string) => {
    switch (priority) {
      case 'high': return '高';
      case 'medium': return '中';
      default: return '低';
    }
  };

  const moveTask = (taskId: string, newStatus: Task['status']) => {
    setTasks(tasks.map(task => 
      task.id === taskId ? { ...task, status: newStatus } : task
    ));
  };

  const handleDragStart = (taskId: string) => {
    setDraggedTask(taskId);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleDrop = (status: Task['status']) => {
    if (draggedTask) {
      moveTask(draggedTask, status);
      setDraggedTask(null);
    }
  };

  const addTask = () => {
    if (newTask.title) {
      const task: Task = {
        id: Date.now().toString(),
        title: newTask.title,
        description: newTask.description || '',
        status: 'todo',
        agent: newTask.agent || 'Unassigned',
        priority: newTask.priority as 'high' | 'medium' | 'low' || 'medium',
        createdAt: new Date().toISOString().split('T')[0],
        labels: newTask.labels || [],
      };
      setTasks([...tasks, task]);
      setNewTask({});
      setShowNewTask(false);
    }
  };

  const deleteTask = (taskId: string) => {
    setTasks(tasks.filter(task => task.id !== taskId));
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="mb-8 flex items-center justify-between">
          <div>
            <Link href="/" className="inline-flex items-center text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white mb-4">
              <ArrowLeftIcon className="w-4 h-4 mr-2" />
              返回仪表板
            </Link>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">任务看板</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">拖拽管理任务，跟踪进度</p>
          </div>
          <button
            onClick={() => setShowNewTask(true)}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <PlusIcon className="w-5 h-5" />
            <span>新建任务</span>
          </button>
        </div>

        {/* 新建任务模态框 */}
        {showNewTask && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-md">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-bold text-gray-900 dark:text-white">新建任务</h2>
                <button onClick={() => setShowNewTask(false)} className="text-gray-500 hover:text-gray-700">
                  <XMarkIcon className="w-6 h-6" />
                </button>
              </div>
              <div className="space-y-4">
                <input
                  type="text"
                  placeholder="任务标题"
                  value={newTask.title || ''}
                  onChange={(e) => setNewTask({ ...newTask, title: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700"
                />
                <textarea
                  placeholder="任务描述"
                  value={newTask.description || ''}
                  onChange={(e) => setNewTask({ ...newTask, description: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700"
                  rows={3}
                />
                <select
                  value={newTask.priority || 'medium'}
                  onChange={(e) => setNewTask({ ...newTask, priority: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700"
                >
                  <option value="low">低优先级</option>
                  <option value="medium">中优先级</option>
                  <option value="high">高优先级</option>
                </select>
                <button
                  onClick={addTask}
                  className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700"
                >
                  创建任务
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {Object.entries(columns).map(([status, { title, color, icon }]) => (
            <div
              key={status}
              className={`rounded-lg ${color} p-4`}
              onDragOver={handleDragOver}
              onDrop={() => handleDrop(status as Task['status'])}
            >
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                  {icon} {title} ({tasks.filter(t => t.status === status).length})
                </h2>
              </div>
              <div className="space-y-3 min-h-[400px]">
                {tasks.filter(task => task.status === status).map(task => (
                  <div
                    key={task.id}
                    draggable
                    onDragStart={() => handleDragStart(task.id)}
                    className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow-sm cursor-move hover:shadow-md transition-shadow group"
                  >
                    <div className="flex items-start justify-between mb-2">
                      <h3 className="font-medium text-gray-900 dark:text-white flex-1">{task.title}</h3>
                      <button
                        onClick={() => deleteTask(task.id)}
                        className="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-red-500 transition-opacity"
                      >
                        <XMarkIcon className="w-4 h-4" />
                      </button>
                    </div>
                    <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">{task.description}</p>
                    
                    <div className="flex items-center justify-between text-xs">
                      <div className="flex items-center space-x-2">
                        <span className={`px-2 py-1 rounded-full ${getPriorityColor(task.priority)}`}>
                          {getPriorityText(task.priority)}
                        </span>
                        {task.agent && (
                          <span className="flex items-center text-gray-500">
                            <UserIcon className="w-3 h-3 mr-1" />
                            {task.agent}
                          </span>
                        )}
                      </div>
                      {task.dueDate && (
                        <span className="flex items-center text-gray-400">
                          <CalendarIcon className="w-3 h-3 mr-1" />
                          {task.dueDate}
                        </span>
                      )}
                    </div>
                    
                    {task.labels && task.labels.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-2">
                        {task.labels.map(label => (
                          <span key={label} className="px-2 py-0.5 bg-gray-100 dark:bg-gray-700 rounded text-xs">
                            {label}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
