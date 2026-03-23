#!/usr/bin/env python3
"""
天气查询功能模块
使用 wttr.in API 获取天气信息
"""

import requests
import sys

def get_weather(city):
    """获取指定城市的天气信息"""
    try:
        # 使用 wttr.in API，返回简洁格式
        url = f"https://wttr.in/{city}?format=%l:+%c+%t+%w+%h"
        response = requests.get(url, timeout=5)
        
        if response.status_code == 200:
            return response.text.strip()
        else:
            return f"无法获取{city}的天气信息"
    except Exception as e:
        return f"查询失败: {str(e)}"

def main():
    if len(sys.argv) < 2:
        print("用法: python weather.py <城市名>")
        print("示例: python weather.py 北京")
        return
    
    city = sys.argv[1]
    result = get_weather(city)
    print(result)

if __name__ == "__main__":
    main()
