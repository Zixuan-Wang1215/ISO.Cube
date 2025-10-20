import Foundation
import SwiftUI

// MARK: - Language Support
enum Language: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chinese:
            return "中文"
        }
    }
    
    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .chinese:
            return "🇨🇳"
        }
    }
}

// MARK: - Localization Keys
enum LocalizationKey: String, CaseIterable {
    // Settings
    case settings = "settings"
    case language = "language"
    case selectLanguage = "select_language"
    
    // Timer
    case timer = "timer"
    case scramble = "scramble"
    case history = "history"
    case ready = "ready"
    case inspecting = "inspecting"
    case running = "running"
    
    // History
    case average = "average"
    case best = "best"
    case worst = "worst"
    case totalSolves = "total_solves"
    case session = "session"
    
    // Actions
    case done = "done"
    case cancel = "cancel"
    case confirm = "confirm"
    case delete = "delete"
    case edit = "edit"
    case save = "save"
    
    // Cube
    case cube = "cube"
    case connect = "connect"
    case disconnect = "disconnect"
    case connected = "connected"
    case disconnected = "disconnected"
    case battery = "battery"
    
    // Penalties
    case penalty = "penalty"
    case plusTwo = "plus_two"
    case dnf = "dnf"
    case noPenalty = "no_penalty"
    
    // Common
    case noSolvesYet = "no_solves_yet"
    case noSession = "no_session"
    
    // Scramble
    case enterScramble = "enter_scramble"
    case scrambleSequence = "scramble_sequence"
    case commentOptional = "comment_optional"
    case addComment = "add_comment"
    
    // Confirmation
    case confirmResult = "confirm_result"
    case ok = "ok"
    case enterToConfirm = "enter_to_confirm"
    case escToCancel = "esc_to_cancel"
    
    // Actions
    case stop = "stop"
    case run = "run"
    case connectAndStream = "connect_and_stream"
    case noOutput = "no_output"
    
    // Session
    case selectSession = "select_session"
    case renameSession = "rename_session"
    case addSession = "add_session"
    case newSession = "new_session"
    case sessionName = "session_name"
    case enterSessionName = "enter_session_name"
    case addNewSession = "add_new_session"
    case deleteSession = "delete_session"
    case areYouSureDelete = "are_you_sure_delete"
    case thisActionCannotBeUndone = "this_action_cannot_be_undone"
    
    // Bluetooth
    case ganSmartCubes = "gan_smart_cubes"
    case scanningForCubes = "scanning_for_cubes"
    case noCubesFound = "no_cubes_found"
    case unknownDevice = "unknown_device"
    case refresh = "refresh"
    case stopScanning = "stop_scanning"
    case cubeInfo = "cube_info"
    case deviceName = "device_name"
    case notConnected = "not_connected"
    case batteryLevel = "battery_level"
    case unknown = "unknown"
    case expandedState = "expanded_state"
    case realtimeState = "realtime_state"
    case noStateData = "no_state_data"
}

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
            // Post notification for language change
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    private init() {
        // Load saved language or default to system language
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Try to detect system language
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = systemLanguage.hasPrefix("zh") ? .chinese : .english
        }
    }
    
    func localizedString(for key: LocalizationKey) -> String {
        return localizedString(for: key.rawValue)
    }
    
    fileprivate func localizedString(for key: String) -> String {
        let languageCode = currentLanguage.rawValue

        // English translations
        let englishTranslations: [String: String] = [
            "settings": "Settings",
            "language": "Language",
            "select_language": "Select Language",
            "timer": "Timer",
            "scramble": "Scramble",
            "history": "History",
            "ready": "Ready",
            "inspecting": "Inspecting",
            "running": "Running",
            "average": "Average",
            "best": "Best",
            "worst": "Worst",
            "total_solves": "Total Solves",
            "session": "Session",
            "done": "Done",
            "cancel": "Cancel",
            "confirm": "Confirm",
            "delete": "Delete",
            "edit": "Edit",
            "save": "Save",
            "cube": "Cube",
            "connect": "Connect",
            "disconnect": "Disconnect",
            "connected": "Connected",
            "disconnected": "Disconnected",
            "battery": "Battery",
            "penalty": "Penalty",
            "plus_two": "+2",
            "dnf": "DNF",
            "no_penalty": "No Penalty",
            "no_solves_yet": "No solves yet",
            "no_session": "No Session",
            "enter_scramble": "Enter scramble",
            "scramble_sequence": "Scramble sequence...",
            "comment_optional": "Comment (optional)",
            "add_comment": "Add a comment...",
            "confirm_result": "Confirm Result",
            "ok": "OK",
            "enter_to_confirm": "Enter to confirm",
            "esc_to_cancel": "ESC to cancel",
            "stop": "Stop",
            "run": "Run",
            "connect_and_stream": "Connect & Stream Moves",
            "no_output": "(no output)",
            "select_session": "Select Session",
            "rename_session": "Rename Session",
            "add_session": "Add Session",
            "new_session": "New Session",
            "session_name": "Session Name",
            "enter_session_name": "Enter session name",
            "add_new_session": "Add New Session",
            "delete_session": "Delete Session",
            "are_you_sure_delete": "Are you sure you want to delete",
            "this_action_cannot_be_undone": "This action cannot be undone.",
            "gan_smart_cubes": "GAN Smart Cubes",
            "scanning_for_cubes": "Scanning for GAN Smart Cubes...",
            "no_cubes_found": "No GAN Cubes found",
            "unknown_device": "Unknown Device",
            "refresh": "Refresh",
            "stop_scanning": "Stop Scanning",
            "cube_info": "Cube Info",
            "device_name": "Device Name:",
            "not_connected": "Not connected",
            "battery_level": "Battery Level:",
            "unknown": "Unknown",
            "expanded_state": "Expanded State:",
            "realtime_state": "Real-time State:",
            "no_state_data": "No state data"
        ]
        
        // Chinese translations
        let chineseTranslations: [String: String] = [
            "settings": "设置",
            "language": "语言",
            "select_language": "选择语言",
            "timer": "计时器",
            "scramble": "打乱",
            "history": "历史",
            "ready": "准备",
            "inspecting": "观察",
            "running": "计时中",
            "average": "平均",
            "best": "最佳",
            "worst": "最差",
            "total_solves": "总次数",
            "session": "会话",
            "done": "完成",
            "cancel": "取消",
            "confirm": "确认",
            "delete": "删除",
            "edit": "编辑",
            "save": "保存",
            "cube": "魔方",
            "connect": "连接",
            "disconnect": "断开",
            "connected": "已连接",
            "disconnected": "已断开",
            "battery": "电池",
            "penalty": "惩罚",
            "plus_two": "+2",
            "dnf": "DNF",
            "no_penalty": "无惩罚",
            "no_solves_yet": "暂无成绩",
            "no_session": "无会话",
            "enter_scramble": "输入打乱",
            "scramble_sequence": "打乱序列...",
            "comment_optional": "备注（可选）",
            "add_comment": "添加备注...",
            "confirm_result": "确认结果",
            "ok": "OK",
            "enter_to_confirm": "回车确认",
            "esc_to_cancel": "ESC取消",
            "stop": "停止",
            "run": "运行",
            "connect_and_stream": "连接并流式传输",
            "no_output": "（无输出）",
            "select_session": "选择组",
            "rename_session": "重命名组",
            "add_session": "添加组",
            "new_session": "新组",
            "session_name": "组名称",
            "enter_session_name": "输入组名称",
            "add_new_session": "添加新组",
            "delete_session": "删除组",
            "are_you_sure_delete": "确定要删除",
            "this_action_cannot_be_undone": "此操作无法撤销。",
            "gan_smart_cubes": "GAN智能魔方",
            "scanning_for_cubes": "正在扫描GAN智能魔方...",
            "no_cubes_found": "未找到GAN魔方",
            "unknown_device": "未知设备",
            "refresh": "刷新",
            "stop_scanning": "停止扫描",
            "cube_info": "魔方信息",
            "device_name": "设备名称:",
            "not_connected": "未连接",
            "battery_level": "电池电量:",
            "unknown": "未知",
            "expanded_state": "展开状态:",
            "realtime_state": "实时状态:",
            "no_state_data": "无状态数据"
        ]
        
        let translations = languageCode == "zh" ? chineseTranslations : englishTranslations
        return translations[key] ?? key
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Localized String Extension
extension String {
    var localized: String {
        // If the string matches a LocalizationKey, use the enum-based lookup for type safety;
        // otherwise fall back to the generic string-based lookup which returns the key itself
        // when no translation is found.
        if let key = LocalizationKey(rawValue: self) {
            return LocalizationManager.shared.localizedString(for: key)
        } else {
            return LocalizationManager.shared.localizedString(for: self)
        }
    }
}

// MARK: - Localization Key Extension
extension LocalizationKey {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
}
