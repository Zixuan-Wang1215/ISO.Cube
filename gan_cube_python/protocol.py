"""GAN魔方协议解析器"""

import struct
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from enum import Enum
from .definitions import FACE_NAMES, DIRECTION_NAMES

class EventType(Enum):
    """事件类型"""
    GYRO = 0x01
    MOVE = 0x02
    FACELETS = 0x04
    HARDWARE = 0x05
    BATTERY = 0x09
    DISCONNECT = 0x0D

@dataclass
class GanCubeMove:
    """魔方移动事件"""
    face: int  # 面: 0-U, 1-R, 2-F, 3-D, 4-L, 5-B
    direction: int  # 方向: 0-CW, 1-CCW, 2-180
    move: str  # 移动符号，如 "R", "U'", "F2"
    local_timestamp: Optional[float]  # 主机时间戳
    cube_timestamp: Optional[float]  # 魔方时间戳
    serial: int  # 序列号

@dataclass
class GanCubeState:
    """魔方状态"""
    cp: List[int]  # 角块排列
    co: List[int]  # 角块方向
    ep: List[int]  # 边块排列
    eo: List[int]  # 边块方向
    facelets: str  # Kociemba表示法

@dataclass
class GanCubeEvent:
    """魔方事件"""
    event_type: str
    timestamp: float
    data: Any

class GanProtocolMessageView:
    """协议消息视图，用于从二进制数据中提取位字段"""
    
    def __init__(self, message: bytes):
        # 修复位解析，与TypeScript版本一致
        # TypeScript: (byte + 0x100).toString(2).slice(1)
        # Python: 确保每个字节都是8位
        self.bits = ''.join(f'{(byte + 0x100):09b}'[1:] for byte in message)
    
    def get_bit_word(self, start_bit: int, bit_length: int, little_endian: bool = False) -> int:
        """获取指定位长度的值"""
        # 检查边界
        if start_bit < 0 or start_bit + bit_length > len(self.bits):
            print(f"Warning: Bit access out of bounds: start_bit={start_bit}, bit_length={bit_length}, total_bits={len(self.bits)}")
            return 0
        
        if bit_length <= 8:
            return int(self.bits[start_bit:start_bit + bit_length], 2)
        elif bit_length in [16, 32]:
            buf = bytearray(bit_length // 8)
            for i in range(len(buf)):
                buf[i] = int(self.bits[8 * i + start_bit:8 * i + start_bit + 8], 2)
            if little_endian:
                buf.reverse()
            if bit_length == 16:
                return struct.unpack('<H', buf)[0]
            else:
                return struct.unpack('<I', buf)[0]
        else:
            raise ValueError('不支持的位长度')

class GanGen2ProtocolDriver:
    """GAN Gen2协议驱动"""
    
    def __init__(self):
        self.last_serial = -1
        self.last_move_timestamp = 0
        self.cube_timestamp = 0
    
    def create_command_message(self, command_type: str) -> Optional[bytes]:
        """创建命令消息"""
        msg = bytearray(20)
        if command_type == "REQUEST_FACELETS":
            msg[0] = 0x04
        elif command_type == "REQUEST_HARDWARE":
            msg[0] = 0x05
        elif command_type == "REQUEST_BATTERY":
            msg[0] = 0x09
        elif command_type == "REQUEST_RESET":
            msg[:20] = [0x0A, 0x05, 0x39, 0x77, 0x00, 0x00, 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        else:
            return None
        return bytes(msg)
    
    def handle_state_event(self, event_message: bytes, timestamp: float) -> List[GanCubeEvent]:
        """处理状态事件"""
        events = []
        msg = GanProtocolMessageView(event_message)
        event_type = msg.get_bit_word(0, 4)
        
        # print(f"DEBUG: Event type: 0x{event_type:02X}, Message length: {len(event_message)}")
        # print(f"DEBUG: Raw message: {event_message.hex()}")
        
        if event_type == EventType.GYRO.value:
            # 处理陀螺仪事件
            # print("DEBUG: Processing GYRO event")
            qw = msg.get_bit_word(4, 16)
            qx = msg.get_bit_word(20, 16)
            qy = msg.get_bit_word(36, 16)
            qz = msg.get_bit_word(52, 16)
            
            vx = msg.get_bit_word(68, 4)
            vy = msg.get_bit_word(72, 4)
            vz = msg.get_bit_word(76, 4)
            
            events.append(GanCubeEvent(
                event_type="GYRO",
                timestamp=timestamp,
                data={
                    "quaternion": {
                        "x": (1 - (qx >> 15) * 2) * (qx & 0x7FFF) / 0x7FFF,
                        "y": (1 - (qy >> 15) * 2) * (qy & 0x7FFF) / 0x7FFF,
                        "z": (1 - (qz >> 15) * 2) * (qz & 0x7FFF) / 0x7FFF,
                        "w": (1 - (qw >> 15) * 2) * (qw & 0x7FFF) / 0x7FFF
                    },
                    "velocity": {
                        "x": (1 - (vx >> 3) * 2) * (vx & 0x7),
                        "y": (1 - (vy >> 3) * 2) * (vy & 0x7),
                        "z": (1 - (vz >> 3) * 2) * (vz & 0x7)
                    }
                }
            ))
            
        elif event_type == EventType.MOVE.value:
            # 处理移动事件
            # print("DEBUG: Processing MOVE event")
            # print(f"DEBUG: last_serial = {self.last_serial}")
            # 如果没有初始化过serial，先初始化
            if self.last_serial == -1:
                serial = msg.get_bit_word(4, 8)
                self.last_serial = serial
                # print(f"DEBUG: Initializing last_serial to {serial}")
            
            if self.last_serial != -1:
                serial = msg.get_bit_word(4, 8)
                diff = min((serial - self.last_serial) & 0xFF, 7)
                self.last_serial = serial
                
                # print(f"DEBUG: Serial: {serial}, Diff: {diff}, Last serial: {self.last_serial}")
                
                if diff > 0:
                    for i in range(diff - 1, -1, -1):
                        face = msg.get_bit_word(12 + 5 * i, 4)
                        direction = msg.get_bit_word(16 + 5 * i, 1)
                        
                        # print(f"DEBUG: Move {i}: face={face}, direction={direction}")
                        
                        # 添加边界检查
                        if face >= 6:  # 面索引范围0-5
                            print(f"Warning: Invalid face={face}, skipping move")
                            continue
                        if direction >= 2:  # 方向索引范围0-1
                            print(f"Warning: Invalid direction={direction}, skipping move")
                            continue
                            
                        # 使用正确的字符串索引方法，与TypeScript版本一致
                        move = "URFDLB"[face] + " '"[direction]
                        elapsed = msg.get_bit_word(47 + 16 * i, 16)
                        
                        if elapsed == 0:
                            elapsed = timestamp - self.last_move_timestamp
                        self.cube_timestamp += elapsed
                        
                        events.append(GanCubeEvent(
                            event_type="MOVE",
                            timestamp=timestamp,
                            data=GanCubeMove(
                                face=face,
                                direction=direction,
                                move=move.strip(),  # 去除空格
                                local_timestamp=timestamp if i == 0 else None,
                                cube_timestamp=self.cube_timestamp,
                                serial=(serial - i) & 0xFF
                            )
                        ))
                    self.last_move_timestamp = timestamp
                    
        elif event_type == EventType.FACELETS.value:
            # 处理面块状态事件
            # print("DEBUG: Processing FACELETS event")
            serial = msg.get_bit_word(4, 8)
            if self.last_serial == -1:
                self.last_serial = serial
                
            # print(f"DEBUG: Facelets serial: {serial}")
            
            # 解析角块和边块状态
            cp, co, ep, eo = self._parse_cube_state(msg)
            # print(f"DEBUG: Parsed state - CP: {cp}, CO: {co}, EP: {ep}, EO: {eo}")
            
            facelets = self._to_kociemba_facelets(cp, co, ep, eo)
            
            events.append(GanCubeEvent(
                event_type="FACELETS",
                timestamp=timestamp,
                data=GanCubeState(
                    cp=cp, co=co, ep=ep, eo=eo, facelets=facelets
                )
            ))
            
        elif event_type == EventType.HARDWARE.value:
            # 处理硬件信息事件
            # print("DEBUG: Processing HARDWARE event")
            hw_major = msg.get_bit_word(8, 8)
            hw_minor = msg.get_bit_word(16, 8)
            sw_major = msg.get_bit_word(24, 8)
            sw_minor = msg.get_bit_word(32, 8)
            gyro_supported = msg.get_bit_word(104, 1)
            
            hardware_name = ''
            for i in range(8):
                hardware_name += chr(msg.get_bit_word(i * 8 + 40, 8))
            
            events.append(GanCubeEvent(
                event_type="HARDWARE",
                timestamp=timestamp,
                data={
                    "hardware_name": hardware_name,
                    "hardware_version": f"{hw_major}.{hw_minor}",
                    "software_version": f"{sw_major}.{sw_minor}",
                    "gyro_supported": bool(gyro_supported)
                }
            ))
            
        elif event_type == EventType.BATTERY.value:
            # 处理电池事件
            # print("DEBUG: Processing BATTERY event")
            battery_level = msg.get_bit_word(8, 8)
            events.append(GanCubeEvent(
                event_type="BATTERY",
                timestamp=timestamp,
                data={"battery_level": min(battery_level, 100)}
            ))
        
        return events
    
    def _parse_cube_state(self, msg: GanProtocolMessageView) -> Tuple[List[int], List[int], List[int], List[int]]:
        """解析魔方状态"""
        cp, co, ep, eo = [], [], [], []
        
        # 角块
        for i in range(7):
            cp.append(msg.get_bit_word(12 + i * 3, 3))
            co.append(msg.get_bit_word(33 + i * 2, 2))
        cp.append(28 - sum(cp))
        co.append((3 - (sum(co) % 3)) % 3)
        
        # 边块
        for i in range(11):
            ep.append(msg.get_bit_word(47 + i * 4, 4))
            eo.append(msg.get_bit_word(91 + i, 1))
        ep.append(66 - sum(ep))
        eo.append((2 - (sum(eo) % 2)) % 2)
        
        return cp, co, ep, eo
    
    def _to_kociemba_facelets(self, cp: List[int], co: List[int], ep: List[int], eo: List[int]) -> str:
        """转换为Kociemba面块表示法"""
        # 角块面块映射
        CORNER_FACELET_MAP = [
            [8, 9, 20],   # URF
            [6, 18, 38],  # UFL
            [0, 36, 47],  # ULB
            [2, 45, 11],  # UBR
            [29, 26, 15], # DFR
            [27, 44, 24], # DLF
            [33, 53, 42], # DBL
            [35, 17, 51]  # DRB
        ]
        
        # 边块面块映射
        EDGE_FACELET_MAP = [
            [5, 10],   # UR
            [7, 19],   # UF
            [3, 37],   # UL
            [1, 46],   # UB
            [32, 16],  # DR
            [28, 25],  # DF
            [30, 43],  # DL
            [34, 52],  # DB
            [23, 12],  # FR
            [21, 41],  # FL
            [50, 39],  # BL
            [48, 14]   # BR
        ]
        
        faces = "URFDLB"
        facelets = [faces[i // 9] for i in range(54)]
        
        # 处理角块
        for i in range(8):
            if i < len(cp) and i < len(co):
                for p in range(3):
                    if (cp[i] < len(CORNER_FACELET_MAP) and co[i] < 3 and 
                        cp[i] >= 0 and co[i] >= 0 and
                        (p + co[i]) % 3 < len(CORNER_FACELET_MAP[i]) and
                        p < len(CORNER_FACELET_MAP[cp[i]])):
                        facelets[CORNER_FACELET_MAP[i][(p + co[i]) % 3]] = faces[CORNER_FACELET_MAP[cp[i]][p] // 9]
        
        # 处理边块
        for i in range(12):
            if i < len(ep) and i < len(eo):
                for p in range(2):
                    if (ep[i] < len(EDGE_FACELET_MAP) and eo[i] < 2 and
                        ep[i] >= 0 and eo[i] >= 0 and
                        (p + eo[i]) % 2 < len(EDGE_FACELET_MAP[i]) and
                        p < len(EDGE_FACELET_MAP[ep[i]])):
                        facelets[EDGE_FACELET_MAP[i][(p + eo[i]) % 2]] = faces[EDGE_FACELET_MAP[ep[i]][p] // 9]
        
        return ''.join(facelets)

class GanGen3ProtocolDriver:
    """GAN Gen3协议驱动"""
    def __init__(self):
        self.last_serial = -1
        self.last_move_timestamp = 0
        self.cube_timestamp = 0
    
    def create_command_message(self, command_type: str) -> Optional[bytes]:
        """创建命令消息"""
        msg = bytearray(16)
        if command_type == "REQUEST_FACELETS":
            msg[:2] = [0x68, 0x01]
        elif command_type == "REQUEST_HARDWARE":
            msg[:2] = [0x68, 0x04]
        elif command_type == "REQUEST_BATTERY":
            msg[:2] = [0x68, 0x07]
        elif command_type == "REQUEST_RESET":
            msg[:16] = [0x68, 0x05, 0x05, 0x39, 0x77, 0x00, 0x00, 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0x00, 0x00, 0x00]
        else:
            return None
        return bytes(msg)
    
    def handle_state_event(self, event_message: bytes, timestamp: float) -> List[GanCubeEvent]:
        """处理状态事件 - 简化实现"""
        # 这里需要实现Gen3协议的具体解析逻辑
        # 暂时返回空列表
        return []

class GanGen4ProtocolDriver:
    """GAN Gen4协议驱动"""
    def __init__(self):
        self.last_serial = -1
        self.last_move_timestamp = 0
        self.cube_timestamp = 0
    
    def create_command_message(self, command_type: str) -> Optional[bytes]:
        """创建命令消息"""
        msg = bytearray(20)
        if command_type == "REQUEST_FACELETS":
            msg[:6] = [0xDD, 0x04, 0x00, 0xED, 0x00, 0x00]
        elif command_type == "REQUEST_HARDWARE":
            msg[:5] = [0xDF, 0x03, 0x00, 0x00, 0x00]
        elif command_type == "REQUEST_BATTERY":
            msg[:6] = [0xDD, 0x04, 0x00, 0xEF, 0x00, 0x00]
        elif command_type == "REQUEST_RESET":
            msg[:16] = [0xD2, 0x0D, 0x05, 0x39, 0x77, 0x00, 0x00, 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0x00, 0x00, 0x00]
        else:
            return None
        return bytes(msg)
    
    def handle_state_event(self, event_message: bytes, timestamp: float) -> List[GanCubeEvent]:
        """处理状态事件 - 简化实现"""
        # 这里需要实现Gen4协议的具体解析逻辑
        # 暂时返回空列表
        return [] 