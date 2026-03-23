#!/usr/bin/env python3
"""
QA 团队 - API 自动化测试
测试 dashboard_api.py 的所有端点
"""

import unittest
import json
import requests
import threading
import time
from dashboard_api import app

class TestDashboardAPI(unittest.TestCase):
    """QA 团队 API 测试"""
    
    @classmethod
    def setUpClass(cls):
        """启动测试服务器"""
        cls.server = threading.Thread(target=lambda: app.run(host='127.0.0.1', port=5001, debug=False))
        cls.server.daemon = True
        cls.server.start()
        time.sleep(2)  # 等待服务器启动
        cls.base_url = 'http://127.0.0.1:5001'
    
    def test_health_check(self):
        """测试健康检查端点"""
        response = requests.get(f'{self.base_url}/api/health')
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data['status'], 'ok')
        self.assertEqual(data['service'], 'wind-turbine-monitor')
    
    def test_current_status(self):
        """测试实时数据端点"""
        response = requests.get(f'{self.base_url}/api/current')
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # 验证数据结构
        self.assertIn('current', data)
        self.assertIn('health_score', data)
        self.assertIn('status', data)
        
        # 验证健康评分范围
        self.assertTrue(0 <= data['health_score'] <= 100)
        
        # 验证传感器参数
        current = data['current']
        self.assertIn('wind_speed', current)
        self.assertIn('power_output', current)
        self.assertIn('generator_temp', current)
        self.assertIn('vibration', current)
        self.assertIn('noise_level', current)
    
    def test_history_endpoint(self):
        """测试历史数据端点"""
        # 先获取几次数据，产生历史
        for _ in range(3):
            requests.get(f'{self.base_url}/api/current')
            time.sleep(0.1)
        
        response = requests.get(f'{self.base_url}/api/history?limit=10')
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        self.assertIn('data', data)
        self.assertIn('total', data)
        self.assertTrue(len(data['data']) <= 10)
    
    def test_report_endpoint(self):
        """测试报告生成端点"""
        # 生成一些历史数据
        for _ in range(5):
            requests.get(f'{self.base_url}/api/current')
            time.sleep(0.1)
        
        response = requests.get(f'{self.base_url}/api/report')
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        self.assertIn('report', data)
        self.assertIn('statistics', data)
        
        stats = data['statistics']
        self.assertIn('total_readings', stats)
        self.assertIn('anomaly_count', stats)
        self.assertIn('avg_health_score', stats)
        self.assertIn('health_status', stats)
    
    def test_export_json(self):
        """测试导出 JSON 格式"""
        # 生成数据
        for _ in range(3):
            requests.get(f'{self.base_url}/api/current')
            time.sleep(0.1)
        
        response = requests.post(f'{self.base_url}/api/export', 
                                 json={'format': 'json'})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIsInstance(data, list)
    
    def test_export_csv(self):
        """测试导出 CSV 格式"""
        # 生成数据
        for _ in range(3):
            requests.get(f'{self.base_url}/api/current')
            time.sleep(0.1)
        
        response = requests.post(f'{self.base_url}/api/export', 
                                 json={'format': 'csv'})
        self.assertEqual(response.status_code, 200)
        self.assertIn('text/csv', response.headers.get('Content-Type', ''))
        self.assertTrue(len(response.text) > 0)
    
    def test_anomaly_detection(self):
        """测试异常检测功能"""
        response = requests.get(f'{self.base_url}/api/current')
        data = response.json()
        
        # 如果有异常，验证 anomalies 字段存在
        if data['status'] == 'WARNING':
            self.assertIn('anomalies', data['current'])
            self.assertGreater(len(data['current']['anomalies']), 0)


class TestFrontendIntegration(unittest.TestCase):
    """前端集成测试"""
    
    def test_frontend_file_exists(self):
        """测试前端文件存在"""
        import os
        self.assertTrue(os.path.exists('dashboard_frontend.html'))
        
        with open('dashboard_frontend.html', 'r') as f:
            content = f.read()
            self.assertIn('风力发电机健康监测仪表板', content)
            self.assertIn('ECharts', content)
            self.assertIn('refreshData', content)


if __name__ == '__main__':
    # 运行测试
    unittest.main(verbosity=2)
