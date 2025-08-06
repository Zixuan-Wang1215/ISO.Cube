// Timer state machine
enum TimerState { case idle, armed, ready, running }

import SwiftUI
import AppKit
// Tab enumeration for bottom navigation
enum Tab { case timing, history, settings }

// History view placeholder
struct HistoryView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Text("History")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

// Settings view placeholder
struct SettingsView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Text("Settings")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

// Tab button component
typealias TabButtonLabel = String
struct TabButton: View {
    let label: TabButtonLabel
    let tab: Tab
    @Binding var selectedTab: Tab

    var body: some View {
        Button(action: { selectedTab = tab }) {
            Text(label)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(selectedTab == tab ? .white : .gray)
                .frame(width: 40, height: 40)
                .background(selectedTab == tab ? Color.white.opacity(0.2) : Color.clear)
                .cornerRadius(20)
        }

        .buttonStyle(PlainButtonStyle())
    }
}

// Content view with bottom navigation
struct ContentView: View {
    @State private var selectedTab: Tab = .timing
    @State private var timerState: TimerState = .idle

    // Computed property for selected tab index
    private var selectedTabIndex: Int {
        switch selectedTab {
        case .timing: return 0
        case .history: return 1
        case .settings: return 2
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    TimerView(timerState: $timerState).frame(width: geo.size.width, height: geo.size.height)
                    HistoryView().frame(width: geo.size.width, height: geo.size.height)
                    SettingsView().frame(width: geo.size.width, height: geo.size.height)
                }
                .offset(x: -CGFloat(selectedTabIndex) * geo.size.width)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            // Bottom tab bar with sliding capsule indicator
            VStack { Spacer()
                let buttonWidth: CGFloat = 40
                let spacing: CGFloat = 40
                let step = buttonWidth + spacing
                ZStack(alignment: .leading) {
                    // Glass background
                    HStack(spacing: spacing) {
                        Color.clear.frame(width: buttonWidth, height: 50)
                        Color.clear.frame(width: buttonWidth, height: 50)
                        Color.clear.frame(width: buttonWidth, height: 50)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(25)
                    // Circular highlight behind selected button
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: buttonWidth, height: buttonWidth)
                        .offset(x: step * CGFloat(selectedTabIndex) + 12)
                    // Buttons
                    HStack(spacing: spacing) {
                        TabButton(label: "T", tab: .timing, selectedTab: $selectedTab)
                        TabButton(label: "H", tab: .history, selectedTab: $selectedTab)
                        TabButton(label: "S", tab: .settings, selectedTab: $selectedTab)
                    }
                    .padding(12)
                }
                .padding(.bottom, 20)
                .opacity(timerState == .running ? 0 : 1)
            }
        }
    }
}

struct TimerView: View {
    @StateObject private var timerVM = TimerViewModel()
    @Binding var timerState: TimerState
    @State private var readyWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 0) {
            // 顶部区域：打乱公式和魔方展开图
            VStack(spacing: 16) {
                CubeScrambleView(scramble: timerVM.currentScramble)
                    .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .frame(height: 200)
            .padding(.horizontal)
            .padding(.top, 20)
            .opacity(timerState == .running ? 0 : 1)
            
            Spacer()
            
            // 中央计时显示
            VStack(spacing: 0) {
                Text(timerVM.displayTime)
                    .foregroundColor(timerState == .armed ? .red : timerState == .ready ? .green : .white)
                    .font(.system(size: timerState == .running ? 90 : 72, weight: .light, design: .monospaced))
                    .padding(.bottom, 40)
            }
            .padding(.top,100)
            Spacer()
            
            // 底部区域：3D魔方和蓝牙图标
            VStack(spacing: 0) {
                // 3D魔方视图 - 放在窗口底部

                Cube3DView(isTimerRunning: timerState == .running)
                    .frame(width: 2560, height: 500)
                    .padding(.bottom, -100)
                    .offset(y: 40)
                    .opacity(timerState == .running ? 0 : 1)
                
                // 蓝牙图标 - 右下角
                HStack {
                    Spacer()
                    Image(nsImage: NSImage(named: NSImage.bluetoothTemplateName)!)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.gray)
                        .frame(width: 24, height: 24)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
                .opacity(timerState == .running ? 0 : 1)
            }
        }
        .frame(minWidth: 600, minHeight: 800)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
                // SPACE key code is 49
                if event.keyCode == 49 {
                    switch event.type {
                    case .keyDown:
                        if timerState == .idle {
                            timerState = .armed
                            let work = DispatchWorkItem {
                                if timerState == .armed {
                                    timerState = .ready
                                }
                            }
                            readyWorkItem = work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
                        } else if timerState == .running {
                            timerVM.toggleTimer()
                            timerState = .idle
                            readyWorkItem?.cancel()
                        }
                    case .keyUp:
                        if timerState == .armed {
                            // released too early: cancel readiness
                            // released too early: cancel readiness
                            readyWorkItem?.cancel()
                            timerState = .idle
                        } else if timerState == .ready {
                            // proper release: start timing
                            timerState = .running
                            timerVM.toggleTimer()
                        }
                    default:
                        break
                    }
                    // Swallow the space event to prevent system beep
                    return nil
                }
                // Any key press when running stops the timer
                if timerState == .running && event.type == .keyDown {
                    timerVM.toggleTimer()
                    timerState = .idle
                    readyWorkItem?.cancel()
                    return nil
                }
                return event
            }
        }
    }
}
