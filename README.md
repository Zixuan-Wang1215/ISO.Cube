# GAN智能魔方Python库

这是一个用于连接和控制GAN智能魔方的Python库，基于Web Bluetooth API的TypeScript版本转换而来。

## 功能特性

- ✅ **完整的蓝牙连接** - 使用bleak库实现跨平台蓝牙连接
- ✅ **AES-128-CBC加密/解密** - 使用pycryptodome实现
- ✅ **协议解析** - 支持GAN Gen2/Gen3/Gen4协议
- ✅ **事件处理** - 异步事件驱动架构
- ✅ **时间戳处理** - 线性回归拟合解决时钟偏差
- ✅ **状态获取** - 获取魔方面块状态、电池、硬件信息
- ✅ **移动检测** - 实时检测魔方移动

## 支持的设备

- GAN Gen2协议智能魔方:
  - GAN Mini ui FreePlay
  - GAN12 ui FreePlay
  - GAN12 ui
  - GAN356 i Carry S
  - GAN356 i Carry
  - GAN356 i 3
  - Monster Go 3Ai
- MoYu AI 2023 (使用GAN Gen2协议)
- GAN Gen3协议智能魔方:
  - GAN356 i Carry 2
- GAN Gen4协议智能魔方:
  - GAN12 ui Maglev
  - GAN14 ui FreePlay

## 安装

```bash
pip install -r requirements.txt
```

## 快速开始

### 方法1: 使用内置示例

```bash
# 运行内置示例
python gan_cube_python/example.py
```

### 方法2: 使用测试脚本

```bash
# 运行测试脚本
python test_connection.py
```

### 方法3: 自定义代码

```python
import asyncio
from gan_cube_python import GanCubeManager

async def main():
    # 连接魔方
    cube = await GanCubeManager.connect()
    
    # 注册事件处理器
    def on_move(move_data):
        print(f"移动: {move_data.move}")
    
    def on_facelets(state_data):
        print(f"魔方状态: {state_data.facelets}")
    
    cube.on("MOVE", on_move)
    cube.on("FACELETS", on_facelets)
    
    # 请求当前状态
    await cube.send_command("REQUEST_FACELETS")
    
    # 保持连接
    while True:
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(main())
```

## 事件类型

- `MOVE` - 魔方移动事件
- `FACELETS` - 魔方面块状态事件
- `GYRO` - 陀螺仪事件
- `BATTERY` - 电池事件
- `HARDWARE` - 硬件信息事件
- `DISCONNECT` - 断开连接事件

## 命令类型

- `REQUEST_FACELETS` - 请求面块状态
- `REQUEST_HARDWARE` - 请求硬件信息
- `REQUEST_BATTERY` - 请求电池信息
- `REQUEST_RESET` - 重置魔方状态

## 故障排除

### 1. 找不到设备
- 确保GAN魔方已开启并处于可发现状态
- 检查蓝牙是否已启用
- 确保设备名称包含"GAN"、"MG"或"AICUBE"

### 2. 连接失败
- 确保没有其他应用正在使用该魔方
- 尝试重启魔方
- 检查系统蓝牙权限

### 3. 解密错误
- 如果无法获取MAC地址，库会使用默认盐值
- 某些设备可能需要手动提供MAC地址

### 4. 协议不匹配
- 确保您的魔方型号在支持列表中
- 检查设备是否使用正确的协议版本

## 开发说明

### 项目结构
```
gan_cube_python/
├── __init__.py          # 主模块入口
├── definitions.py       # 常量定义
├── encrypter.py         # 加密器实现
├── protocol.py          # 协议解析器
├── connection.py        # 连接管理器
├── utils.py            # 工具函数
├── example.py          # 使用示例
├── requirements.txt    # 依赖列表
└── README.md          # 项目说明
```

### 扩展功能
- 实现完整的Gen3/Gen4协议解析
- 添加更多事件类型支持
- 实现更精确的时间戳处理
- 添加数据记录和分析功能

## 许可证

MIT License 