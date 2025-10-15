

import asyncio
import sys
import os
import time
from gan_cube_python.connection import GanCubeManager

# 重定向标准输出来过滤DEBUG信息
class DebugFilter:
    def __init__(self, original_stdout):
        self.original_stdout = original_stdout
        self.buffer = ""
    
    def write(self, text):
        # 过滤掉DEBUG开头的行
        lines = text.split('\n')
        filtered_lines = []
        for line in lines:
            # 不再过滤DEBUG日志，保留所有非空行
            if line.strip():
                filtered_lines.append(line)
        if filtered_lines:
            self.original_stdout.write('\n'.join(filtered_lines) + '\n')
        self.original_stdout.flush()
    
    def flush(self):
        self.original_stdout.flush()

async def main():
    try:
        # 应用DEBUG过滤器
        original_stdout = sys.stdout
        debug_filter = DebugFilter(original_stdout)
        sys.stdout = debug_filter
        
        # 连接到魔方
        cube = await GanCubeManager.connect()
        print("Connected successfully!")
        
        # 陀螺仪数据缓存
        latest_gyro_data = None
        
        # 设置事件处理器
        def on_move(move_data):
            print(f"Move: {move_data.move}, Serial: {move_data.serial}")
            # 每次move后主动请求状态
            asyncio.create_task(request_state_after_move())
        
        def on_state(state_data):
            print(f"State: {state_data.facelets}")
        
        def on_gyro(gyro_data):
            # 陀螺仪数据处理器，缓存最新数据
            nonlocal latest_gyro_data
            latest_gyro_data = gyro_data
        
        async def request_state_after_move():
            try:
                await cube.request_state()
            except Exception as e:
                print(f"Failed to request state: {e}")
        
    
        
        cube.on_move(on_move)
        cube.on_state(on_state)
        cube.on_gyro(on_gyro)
        
        print("Start turning the cube to see events...")
        print("Press Ctrl+C to stop")
        print("Gyro data will be output every second...")
        
        # 启动陀螺仪数据输出任务

        
        # 保持连接
        while cube.is_connected:
            await asyncio.sleep(1)
        
        # 取消陀螺仪任务

            
    except KeyboardInterrupt:
        print("\nStopping...")
        if 'cube' in locals():
            await cube.disconnect()
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        # 恢复标准输出
        sys.stdout = original_stdout

if __name__ == "__main__":
    asyncio.run(main()) 