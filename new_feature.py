#!/usr/bin/env python3
"""
新功能: 数据导出模块
用于演示 PR 审查流程
"""

import json
import csv
from typing import List, Dict

def export_to_json(data: List[Dict], filename: str) -> bool:
    """导出数据到 JSON 文件"""
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        print(f"导出失败: {e}")
        return False

def export_to_csv(data: List[Dict], filename: str) -> bool:
    """导出数据到 CSV 文件"""
    if not data:
        return False
    try:
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)
        return True
    except Exception as e:
        print(f"导出失败: {e}")
        return False

def main():
    # 测试数据
    sample_data = [
        {"id": 1, "name": "测试1", "value": 100},
        {"id": 2, "name": "测试2", "value": 200},
    ]
    
    # 导出测试
    export_to_json(sample_data, "output.json")
    export_to_csv(sample_data, "output.csv")
    print("导出完成")

if __name__ == "__main__":
    main()
