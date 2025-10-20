

import asyncio
import sys
import os
import time
from gan_cube_python.connection import GanCubeManager
import kociemba

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
        
        # 检查是否提供了设备地址参数
        if len(sys.argv) < 3:
            print("Error: Both UUID and MAC address are required")
            print("Usage: python test_raw_data.py <UUID> <MAC_ADDRESS>")
            return
        
        uuid_address = sys.argv[1]  # 用于连接
        mac_address = sys.argv[2]   # 用于生成盐值
        
        print(f"Connecting to device UUID: {uuid_address}")
        print(f"Using MAC address for salt: {mac_address}")
        
        # 连接到魔方
        cube = await GanCubeManager.connect(uuid_address, mac_address)
        print("Connected successfully!")
        # 发送连接确认消息给Swift应用
        print("CUBE_CONNECTED_CONFIRMATION")
        
        # 连接完成后主动请求一次魔方状态，避免漏掉第一步
        print("Requesting initial cube state...")
        try:
            await cube.request_state()
            print("Initial state requested successfully")
        except Exception as e:
            print(f"Failed to request initial state: {e}")
        
        # 陀螺仪数据缓存
        latest_gyro_data = None
        # 标记是否已经执行过初始解
        initial_solution_executed = False
        
        # 设置事件处理器
        def on_move(move_data):
            print(f"Move: {move_data.move}, Serial: {move_data.serial}")
            # 每次move后主动请求状态
            asyncio.create_task(request_state_after_move())
        
        def expand_double_moves(solution):
            """将解中的双倍移动（如R2）拆分成两个单次移动（R R）"""
            if not solution or solution.strip() == "":
                return ""
            
            moves = solution.split()
            expanded_moves = []
            
            for move in moves:
                if move.endswith("2"):
                    # 将R2拆分成R R
                    base_move = move[:-1]  # 去掉"2"
                    expanded_moves.append(base_move)
                    expanded_moves.append(base_move)
                else:
                    expanded_moves.append(move)
            
            return " ".join(expanded_moves)
        
        def on_state(state_data):
            nonlocal initial_solution_executed
            print(f"State: {state_data.facelets}")
            
            # 只在初始状态时计算解，执行一次后就不再计算
            if not initial_solution_executed:
                try:
                    solved_state = "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"
                    target_state = state_data.facelets
                    
                    # 检查魔方是否已经是还原状态
                    if target_state == solved_state:
                        print("Cube is already solved, no solution needed")
                        print(f"CUBE_SOLUTION: ")
                    else:
                        # 使用kociemba求解
                        solution = kociemba.solve(solved_state, target_state)
                        # 拆分双倍移动
                        expanded_solution = expand_double_moves(solution)
                        print(f"CUBE_SOLUTION: {expanded_solution}")
                    
                    # 标记已经执行过初始解
                    initial_solution_executed = True
                    
                except Exception as e:
                    print(f"Failed to solve cube state: {e}")
        
        def on_gyro(gyro_data):
            # 陀螺仪数据处理器，缓存最新数据
            nonlocal latest_gyro_data
            latest_gyro_data = gyro_data
        
        def on_battery(battery_data):
            # 电量数据处理器
            print(f"Battery: {battery_data}")
        
        # 模拟电量数据用于测试
        async def simulate_battery():
            await asyncio.sleep(5)  # 等待5秒后发送模拟电量数据
            print("Battery: 85%")
        
        async def request_state_after_move():
            try:
                await cube.request_state()
            except Exception as e:
                print(f"Failed to request state: {e}")
        
    
        
        cube.on_move(on_move)
        cube.on_state(on_state)
        cube.on_gyro(on_gyro)
        cube.on_battery(on_battery)
        
        print("Start turning the cube to see events...")
        print("Press Ctrl+C to stop")
        print("Gyro data will be output every second...")
        
        # 启动模拟电量任务
        asyncio.create_task(simulate_battery())
        
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