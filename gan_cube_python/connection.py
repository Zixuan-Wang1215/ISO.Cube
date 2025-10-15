# -*- coding: utf-8 -*-
"""GAN魔方连接管理器 - 简化版"""

import asyncio
import time
import sys
from typing import Optional, Callable
from bleak import BleakClient, BleakScanner
from .definitions import *
from .encrypter import GanGen2CubeEncrypter, GanGen3CubeEncrypter, GanGen4CubeEncrypter
from .protocol import GanGen2ProtocolDriver, GanGen3ProtocolDriver, GanGen4ProtocolDriver, GanCubeEvent

# 设置输出编码
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

class GanCubeConnection:
    """GAN魔方连接类 - 简化版"""
    
    def __init__(self, device, client: BleakClient, encrypter, driver):
        self.device = device
        self.client = client
        self.encrypter = encrypter
        self.driver = driver
        self.move_handler = None
        self.state_handler = None
        self.gyro_handler = None
        self.is_connected = True
    
    @property
    def device_name(self) -> str:
        return self.device.name or "GAN-XXXX"
    
    def on_move(self, handler: Callable):
        """注册移动事件处理器"""
        self.move_handler = handler
    
    def on_state(self, handler: Callable):
        """注册状态事件处理器"""
        self.state_handler = handler
    
    def on_gyro(self, handler: Callable):
        """注册陀螺仪事件处理器"""
        self.gyro_handler = handler
    
    def _emit_move(self, move_data):
        """触发移动事件"""
        if self.move_handler:
            try:
                self.move_handler(move_data)
            except Exception as e:
                print(f"Move handler error: {e}")
    
    def _emit_state(self, state_data):
        """触发状态事件"""
        if self.state_handler:
            try:
                self.state_handler(state_data)
            except Exception as e:
                print(f"State handler error: {e}")
    
    def _emit_gyro(self, gyro_data):
        """触发陀螺仪事件"""
        if self.gyro_handler:
            try:
                self.gyro_handler(gyro_data)
            except Exception as e:
                print(f"Gyro handler error: {e}")
    
    async def _notification_handler(self, sender, data: bytes):
        """处理通知数据"""
        if len(data) >= 16:
            try:
                decrypted_data = self.encrypter.decrypt(data)
                # 输出解密后的十六进制数据，方便调试
    
                events = self.driver.handle_state_event(decrypted_data, time.time())
                for event in events:
                    if event.event_type == "MOVE":
                        self._emit_move(event.data)
                    elif event.event_type == "FACELETS":
                        self._emit_state(event.data)
                    elif event.event_type == "GYRO":
                        self._emit_gyro(event.data)
            except Exception as e:
                print(f"Data processing error: {e}")
                import traceback
                traceback.print_exc()
    
    async def send_command(self, command_type: str):
        """发送命令到魔方"""
        if not self.is_connected:
            raise RuntimeError("Cube is not connected")
        
        command_message = self.driver.create_command_message(command_type)
        if command_message is None:
            raise ValueError(f"Unknown command type: {command_type}")
        
        # 加密命令消息
        encrypted_message = self.encrypter.encrypt(command_message)
        
        # 发送到魔方
        # 需要找到命令特征UUID
        for service in self.client.services:
            for char in service.characteristics:
                if char.uuid.lower() in [GAN_GEN2_COMMAND_CHARACTERISTIC, GAN_GEN3_COMMAND_CHARACTERISTIC, GAN_GEN4_COMMAND_CHARACTERISTIC]:
                    await self.client.write_gatt_char(char.uuid, encrypted_message)
                    return
        
        raise RuntimeError("Command characteristic not found")
    
    async def request_state(self):
        """请求魔方状态"""
        await self.send_command("REQUEST_FACELETS")
    
    async def disconnect(self):
        """断开连接"""
        self.is_connected = False
        if self.client.is_connected:
            await self.client.disconnect()

class GanCubeManager:
    """GAN魔方管理器 - 简化版"""
    
    @staticmethod
    def _generate_salt_from_mac(mac_address: str) -> bytes:
        """从MAC地址或UUID生成盐值"""
        # 检查是否为UUID格式
        if '-' in mac_address:
            # UUID格式，取前6个字节
            uuid_parts = mac_address.replace('-', '')
            if len(uuid_parts) >= 12:
                # 取前12个字符（6个字节）
                hex_string = uuid_parts[:12]
                salt = bytes.fromhex(hex_string)
                print(f"Salt from UUID {mac_address}: {salt.hex()}")
                return salt
            else:
                # 如果UUID太短，使用默认盐值
                print(f"Warning: Invalid UUID format, using default salt")
                return bytes([0x00] * 6)
        else:
            # MAC地址格式
            parts = mac_address.split(':')
            if len(parts) == 6:
                salt = bytes(int(part, 16) for part in reversed(parts))
                print(f"Salt from MAC {mac_address}: {salt.hex()}")
                return salt
            else:
                # 如果格式不正确，使用默认盐值
                print(f"Warning: Invalid MAC format, using default salt")
                return bytes([0x00] * 6)
    
    @staticmethod
    async def connect(manual_mac: Optional[str] = None) -> GanCubeConnection:
        """连接到GAN魔方"""
        print("Scanning for GAN cube devices...")
        
        # 扫描设备
        print("Scanning Bluetooth devices...")
        devices = await BleakScanner.discover(timeout=10.0)
        print(f"Found {len(devices)} Bluetooth devices:")
        
        # 处理返回的数据结构
        for i, device in enumerate(devices):
            device_name = getattr(device, 'name', None) or 'Unknown'
            print(f"  {i+1}. {device_name} [{device.address}]")
        
        target_device = None
        
        # 查找GAN魔方设备
        for device in devices:
            device_name = getattr(device, 'name', None)
            if device_name:
                device_name_upper = device_name.upper()
                print(f"Checking device: '{device_name}' -> '{device_name_upper}'")
                if any(prefix in device_name_upper for prefix in ["GAN", "MG", "AICUBE", "CUBE", "ICARRY"]):
                    target_device = device
                    print(f"Found matching device: {device_name}")
                    break
        
        if not target_device:
            print("Error: No GAN cube device found")
            print("Please ensure:")
            print("  1. GAN cube is powered on and discoverable")
            print("  2. Device is within Bluetooth range")
            print("  3. Device name contains 'GAN', 'MG', 'AiCube' or 'Cube'")
            raise RuntimeError("No GAN cube device found")
        
        device_name = getattr(target_device, 'name', 'Unknown')
        print(f"Found device: {device_name} [{target_device.address}]")
        
        # 尝试从制造商数据中提取MAC地址
        mac_address = target_device.address  # 默认使用设备地址
        
        # 使用固定的MAC地址
        mac_address = "AB:12:34:5C:3E:D0"
        print(f"Using fixed MAC address: {mac_address}")
        
        # 生成盐值
        salt = GanCubeManager._generate_salt_from_mac(mac_address)
        
        # 连接设备
        print("Connecting to device...")
        print(f"Device address: {target_device.address}")
        print(f"Device name: {device_name}")
        
        # 尝试使用设备地址连接
        try:
            client = BleakClient(target_device.address)
            await client.connect()
        except Exception as e:
            print(f"Failed to connect using address: {e}")
            # 尝试使用设备名称
            try:
                client = BleakClient(device_name)
                await client.connect()
                print("Connected using device name")
            except Exception as e2:
                print(f"Failed to connect using name: {e2}")
                raise e2
        print("Device connected successfully")
        
        # 确定魔方类型和设置加密器
        print("Identifying cube type...")
        services = client.services
        print("Found service collection")
        
        encrypter = None
        driver = None
        state_char = None
        
        # 遍历服务集合
        for service in services:
            service_uuid = service.uuid.lower()
            print(f"Checking service: {service_uuid}")
            
            if service_uuid == GAN_GEN2_SERVICE:
                print("Identified as GAN Gen2 cube")
                # 查找特征
                for char in service.characteristics:
                    if char.uuid.lower() == GAN_GEN2_STATE_CHARACTERISTIC:
                        state_char = char
                        break
                
                if state_char:
                    key_data = GAN_ENCRYPTION_KEYS[1] if device_name.startswith('AiCube') else GAN_ENCRYPTION_KEYS[0]
                    encrypter = GanGen2CubeEncrypter(
                        bytes(key_data["key"]), 
                        bytes(key_data["iv"]), 
                        salt
                    )
                    driver = GanGen2ProtocolDriver()
                    break
                else:
                    print("Error: Required characteristics not found")
                    
            elif service_uuid == GAN_GEN3_SERVICE:
                print("Identified as GAN Gen3 cube")
                # 查找特征
                for char in service.characteristics:
                    if char.uuid.lower() == GAN_GEN3_STATE_CHARACTERISTIC:
                        state_char = char
                        break
                
                if state_char:
                    key_data = GAN_ENCRYPTION_KEYS[0]
                    encrypter = GanGen3CubeEncrypter(
                        bytes(key_data["key"]), 
                        bytes(key_data["iv"]), 
                        salt
                    )
                    driver = GanGen3ProtocolDriver()
                    break
                else:
                    print("Error: Required characteristics not found")
                    
            elif service_uuid == GAN_GEN4_SERVICE:
                print("Identified as GAN Gen4 cube")
                # 查找特征
                for char in service.characteristics:
                    if char.uuid.lower() == GAN_GEN4_STATE_CHARACTERISTIC:
                        state_char = char
                        break
                
                if state_char:
                    key_data = GAN_ENCRYPTION_KEYS[0]
                    encrypter = GanGen4CubeEncrypter(
                        bytes(key_data["key"]), 
                        bytes(key_data["iv"]), 
                        salt
                    )
                    driver = GanGen4ProtocolDriver()
                    break
                else:
                    print("Error: Required characteristics not found")
        
        if not encrypter or not driver:
            await client.disconnect()
            raise RuntimeError("Unsupported cube device or target BLE service not found")
        
        # 创建连接对象
        connection = GanCubeConnection(target_device, client, encrypter, driver)
        
        # 订阅通知
        print(f"Subscribing to state notifications: {state_char.uuid}")
        await client.start_notify(state_char.uuid, connection._notification_handler)
        
        print("Successfully connected to GAN cube")
        print("Ready to detect moves and state changes!")
        return connection 