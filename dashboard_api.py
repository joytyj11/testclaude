#!/usr/bin/env python3
"""
风力发电机监控仪表板 - 后端 API
TestClaude 团队开发
"""

import json
import random
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
from wind_turbine_monitor import WindTurbineMonitor

app = Flask(__name__)
CORS(app)

# 初始化监测器
turbine = WindTurbineMonitor("WT-001")

# 存储历史数据
history_data = []

@app.route('/api/health', methods=['GET'])
def health_check():
    """健康检查"""
    return jsonify({
        'status': 'ok',
        'service': 'wind-turbine-monitor',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/current', methods=['GET'])
def get_current_status():
    """获取当前状态"""
    # 随机决定是否模拟故障 (20% 概率)
    simulate_fault = random.random() < 0.2
    reading = turbine.generate_reading(simulate_fault=simulate_fault)
    health_score = turbine.calculate_health_score(reading)
    
    # 存储到历史
    history_data.append({
        'timestamp': reading['timestamp'],
        'health_score': health_score,
        'reading': reading
    })
    
    # 只保留最近 100 条
    if len(history_data) > 100:
        history_data.pop(0)
    
    return jsonify({
        'current': reading,
        'health_score': health_score,
        'status': reading['status']
    })

@app.route('/api/history', methods=['GET'])
def get_history():
    """获取历史数据"""
    limit = request.args.get('limit', default=20, type=int)
    return jsonify({
        'data': history_data[-limit:],
        'total': len(history_data)
    })

@app.route('/api/report', methods=['GET'])
def generate_report():
    """生成运维报告"""
    if not history_data:
        return jsonify({'error': 'No data available'}), 404
    
    readings = [item['reading'] for item in history_data]
    report_text = turbine.generate_report(readings)
    
    # 计算统计数据
    avg_health = sum(item['health_score'] for item in history_data) / len(history_data)
    anomalies = sum(1 for item in history_data if item['reading']['status'] == 'WARNING')
    
    return jsonify({
        'report': report_text,
        'statistics': {
            'total_readings': len(history_data),
            'anomaly_count': anomalies,
            'avg_health_score': round(avg_health, 2),
            'health_status': 'GOOD' if avg_health > 80 else 'WARNING' if avg_health > 60 else 'CRITICAL'
        }
    })

@app.route('/api/export', methods=['POST'])
def export_report():
    """导出报告 (JSON/CSV)"""
    format_type = request.json.get('format', 'json')
    
    if format_type == 'json':
        return jsonify(history_data)
    elif format_type == 'csv':
        import csv
        from io import StringIO
        
        output = StringIO()
        if history_data:
            fieldnames = ['timestamp', 'health_score', 'wind_speed', 'power_output', 
                         'generator_temp', 'vibration', 'noise_level', 'status']
            writer = csv.DictWriter(output, fieldnames=fieldnames)
            writer.writeheader()
            for item in history_data:
                row = {
                    'timestamp': item['timestamp'],
                    'health_score': item['health_score'],
                    'wind_speed': item['reading']['wind_speed'],
                    'power_output': item['reading']['power_output'],
                    'generator_temp': item['reading']['generator_temp'],
                    'vibration': item['reading']['vibration'],
                    'noise_level': item['reading']['noise_level'],
                    'status': item['reading']['status']
                }
                writer.writerow(row)
        
        return output.getvalue(), 200, {'Content-Type': 'text/csv'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
