#!/usr/bin/env python3
"""
新能源智能运维 - 风力发电机组健康监测系统

功能：
1. 实时数据采集模拟
2. 异常检测算法
3. 健康评分
4. 预警通知
"""

import json
import random
import time
from datetime import datetime
from typing import Dict, List, Tuple


class WindTurbineMonitor:
    """风力发电机监测系统"""
    
    def __init__(self, turbine_id: str, capacity_mw: float = 2.5):
        self.turbine_id = turbine_id
        self.capacity_mw = capacity_mw
        self.history: List[Dict] = []
        
        # 正常参数范围
        self.normal_ranges = {
            'wind_speed': (3, 25),      # m/s
            'power_output': (0, 2500),  # kW
            'rotor_rpm': (5, 20),       # RPM
            'generator_temp': (20, 85), # °C
            'vibration': (0, 5),        # mm/s
            'noise_level': (60, 105)    # dB
        }
        
    def generate_reading(self, simulate_fault: bool = False) -> Dict:
        """生成模拟传感器数据"""
        
        if simulate_fault:
            # 模拟异常：发电机过热
            return {
                'timestamp': datetime.now().isoformat(),
                'turbine_id': self.turbine_id,
                'wind_speed': round(random.uniform(10, 18), 1),
                'power_output': round(random.uniform(1800, 2200), 1),
                'rotor_rpm': round(random.uniform(12, 16), 1),
                'generator_temp': round(random.uniform(92, 105), 1),  # 异常高温
                'vibration': round(random.uniform(3.5, 6.5), 2),      # 振动超标
                'noise_level': round(random.uniform(98, 112), 1),     # 噪音超标
                'status': 'WARNING',
                'anomalies': ['generator_temp', 'vibration', 'noise_level']
            }
        else:
            # 正常数据
            return {
                'timestamp': datetime.now().isoformat(),
                'turbine_id': self.turbine_id,
                'wind_speed': round(random.uniform(5, 15), 1),
                'power_output': round(random.uniform(800, 2000), 1),
                'rotor_rpm': round(random.uniform(8, 14), 1),
                'generator_temp': round(random.uniform(45, 70), 1),
                'vibration': round(random.uniform(1.5, 3.2), 2),
                'noise_level': round(random.uniform(75, 92), 1),
                'status': 'NORMAL',
                'anomalies': []
            }
    
    def calculate_health_score(self, reading: Dict) -> float:
        """计算健康评分 (0-100)"""
        score = 100
        
        # 发电机温度扣分
        temp = reading['generator_temp']
        if temp > 85:
            score -= min(30, (temp - 85) * 2)
        elif temp > 70:
            score -= 10
            
        # 振动扣分
        vibration = reading['vibration']
        if vibration > 5:
            score -= min(25, (vibration - 5) * 5)
        elif vibration > 3:
            score -= 8
            
        # 噪音扣分
        noise = reading['noise_level']
        if noise > 105:
            score -= min(20, (noise - 105) * 2)
        elif noise > 95:
            score -= 5
            
        # 功率异常扣分
        power = reading['power_output']
        expected_power = reading['wind_speed'] * 100  # 简单估算
        if power < expected_power * 0.5:
            score -= 15
            
        return max(0, min(100, score))
    
    def detect_anomalies(self, reading: Dict) -> List[str]:
        """检测异常"""
        anomalies = []
        
        # 检查各参数
        if reading['generator_temp'] > 85:
            anomalies.append(f"发电机过热: {reading['generator_temp']}°C")
        if reading['vibration'] > 5:
            anomalies.append(f"振动超标: {reading['vibration']} mm/s")
        if reading['noise_level'] > 105:
            anomalies.append(f"噪音超标: {reading['noise_level']} dB")
        if reading['wind_speed'] > 25:
            anomalies.append(f"风速过高: {reading['wind_speed']} m/s")
        if reading['rotor_rpm'] > 20:
            anomalies.append(f"转速过高: {reading['rotor_rpm']} RPM")
            
        return anomalies
    
    def generate_report(self, readings: List[Dict]) -> str:
        """生成运维报告"""
        if not readings:
            return "无数据"
            
        total_readings = len(readings)
        anomalies_count = sum(1 for r in readings if r['status'] == 'WARNING')
        avg_health = sum(self.calculate_health_score(r) for r in readings) / total_readings
        
        report = f"""
╔══════════════════════════════════════════════════════════╗
║        风力发电机健康监测报告 - {self.turbine_id}              ║
╚══════════════════════════════════════════════════════════╝

📊 统计信息:
  - 总读数: {total_readings}
  - 异常次数: {anomalies_count}
  - 健康评分: {avg_health:.1f}/100

⚠️  异常分析:
"""
        # 收集所有异常
        all_anomalies = []
        for r in readings:
            all_anomalies.extend(r.get('anomalies', []))
        
        if all_anomalies:
            from collections import Counter
            anomaly_counts = Counter(all_anomalies)
            for anomaly, count in anomaly_counts.most_common(5):
                report += f"  - {anomaly}: 出现 {count} 次\n"
        else:
            report += "  ✅ 未检测到异常\n"
            
        report += f"""
💡 建议:
"""
        if avg_health < 60:
            report += "  🔴 紧急: 需要立即停机检修\n"
        elif avg_health < 80:
            report += "  🟡 警告: 建议安排维护计划\n"
        else:
            report += "  🟢 正常: 持续监控即可\n"
            
        return report


def run_monitoring_demo():
    """运行监控演示"""
    print("🌬️  新能源智能运维系统 - 风力发电机健康监测 Demo")
    print("=" * 60)
    
    # 创建监测对象
    turbine = WindTurbineMonitor(turbine_id="WT-001", capacity_mw=2.5)
    
    # 模拟 10 次数据采集
    readings = []
    
    print("\n📡 开始数据采集...")
    print("-" * 60)
    
    for i in range(10):
        # 第 5 次和第 8 次模拟故障
        simulate = (i == 4 or i == 7)
        reading = turbine.generate_reading(simulate_fault=simulate)
        readings.append(reading)
        
        health = turbine.calculate_health_score(reading)
        anomalies = turbine.detect_anomalies(reading)
        
        status_icon = "✅" if reading['status'] == 'NORMAL' else "⚠️"
        print(f"{status_icon} 采样 {i+1:2d}: 风速={reading['wind_speed']:5.1f}m/s "
              f"功率={reading['power_output']:6.1f}kW "
              f"温度={reading['generator_temp']:5.1f}°C "
              f"健康={health:5.1f}")
        
        if anomalies:
            print(f"     ⚠️  异常: {', '.join(anomalies)}")
            
        time.sleep(0.5)  # 模拟采集间隔
    
    # 生成报告
    print("\n" + "=" * 60)
    report = turbine.generate_report(readings)
    print(report)
    
    # 返回结果用于集成测试
    return {
        'turbine_id': turbine.turbine_id,
        'total_readings': len(readings),
        'anomaly_count': sum(1 for r in readings if r['status'] == 'WARNING'),
        'avg_health': sum(turbine.calculate_health_score(r) for r in readings) / len(readings)
    }


if __name__ == "__main__":
    result = run_monitoring_demo()
    print(f"\n📊 测试结果: {result}")
