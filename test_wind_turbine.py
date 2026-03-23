#!/usr/bin/env python3
"""
测试脚本 - 验证风力发电机监测系统
"""

import unittest
import json
from wind_turbine_monitor import WindTurbineMonitor


class TestWindTurbineMonitor(unittest.TestCase):
    """测试风力发电机监测系统"""
    
    def setUp(self):
        self.turbine = WindTurbineMonitor("TEST-001")
        
    def test_initialization(self):
        """测试初始化"""
        self.assertEqual(self.turbine.turbine_id, "TEST-001")
        self.assertEqual(self.turbine.capacity_mw, 2.5)
        self.assertEqual(len(self.turbine.history), 0)
        
    def test_normal_reading(self):
        """测试正常数据生成"""
        reading = self.turbine.generate_reading(simulate_fault=False)
        
        self.assertIn('timestamp', reading)
        self.assertEqual(reading['turbine_id'], "TEST-001")
        self.assertEqual(reading['status'], 'NORMAL')
        self.assertEqual(len(reading['anomalies']), 0)
        
        # 验证参数范围
        self.assertTrue(3 <= reading['wind_speed'] <= 25)
        self.assertTrue(0 <= reading['power_output'] <= 2500)
        self.assertTrue(20 <= reading['generator_temp'] <= 85)
        
    def test_fault_reading(self):
        """测试故障数据生成"""
        reading = self.turbine.generate_reading(simulate_fault=True)
        
        self.assertEqual(reading['status'], 'WARNING')
        self.assertGreater(len(reading['anomalies']), 0)
        
        # 故障时温度应超标
        self.assertGreater(reading['generator_temp'], 85)
        
    def test_health_score(self):
        """测试健康评分计算"""
        # 正常数据
        normal = self.turbine.generate_reading(simulate_fault=False)
        normal_score = self.turbine.calculate_health_score(normal)
        self.assertGreater(normal_score, 80)
        
        # 故障数据
        fault = self.turbine.generate_reading(simulate_fault=True)
        fault_score = self.turbine.calculate_health_score(fault)
        self.assertLess(fault_score, 70)
        
    def test_anomaly_detection(self):
        """测试异常检测"""
        reading = self.turbine.generate_reading(simulate_fault=True)
        anomalies = self.turbine.detect_anomalies(reading)
        
        self.assertGreater(len(anomalies), 0)
        
        # 检查异常类型
        anomaly_text = ' '.join(anomalies)
        self.assertTrue(
            '过热' in anomaly_text or 
            '超标' in anomaly_text
        )
        
    def test_report_generation(self):
        """测试报告生成"""
        readings = [
            self.turbine.generate_reading(simulate_fault=False) for _ in range(5)
        ]
        readings.append(self.turbine.generate_reading(simulate_fault=True))
        
        report = self.turbine.generate_report(readings)
        
        self.assertIn('风力发电机健康监测报告', report)
        self.assertIn('TEST-001', report)
        self.assertIn('异常', report)
        
    def test_data_integrity(self):
        """测试数据完整性"""
        reading = self.turbine.generate_reading()
        
        # 验证所有必要字段
        required_fields = [
            'timestamp', 'turbine_id', 'wind_speed', 
            'power_output', 'rotor_rpm', 'generator_temp',
            'vibration', 'noise_level', 'status', 'anomalies'
        ]
        for field in required_fields:
            self.assertIn(field, reading)
            
    def test_health_score_range(self):
        """测试健康评分范围"""
        for _ in range(20):
            reading = self.turbine.generate_reading(simulate_fault=random.choice([True, False]))
            score = self.turbine.calculate_health_score(reading)
            self.assertTrue(0 <= score <= 100, f"Score {score} out of range")


if __name__ == "__main__":
    import random
    unittest.main(verbosity=2)
