import SwiftUI

struct SessionDropdownView: View {
    @ObservedObject var historyManager: HistoryManager
    @State private var isExpanded = false
    let onExpansionChange: (Bool) -> Void
    @State private var showingAddSession = false
    @State private var showingRenameSession = false
    @State private var showingDeleteAlert = false
    @State private var newSessionName = ""
    @State private var sessionToRename: SessionModel?
    @State private var sessionToDelete: SessionModel?
    
    var body: some View {
        ZStack {
            // Main dropdown button (completely fixed position)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                    onExpansionChange(isExpanded)
                }
            }) {
                HStack(spacing: 6) {
                    Text("📝")
                        .font(.system(size: 14))
                    
                    Text(historyManager.currentSession?.name ?? "\(LocalizationKey.newSession.localized) 1")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 15)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.9))
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 120, height: 50)
            .position(x: 60, y: 25) // 完全固定位置
            .onTapGesture {
                // 阻止事件冒泡
            }
            
            // Expanded dropdown content (positioned above button)
            if isExpanded {
                VStack(spacing: 0) {
                    // Scrollable session list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(historyManager.sessions) { session in
                                SessionRowView(
                                    session: session,
                                    isSelected: session.id == historyManager.currentSessionId,
                                    onSelect: {
                                        historyManager.setCurrentSession(id: session.id)
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isExpanded = false
                                            onExpansionChange(false)
                                        }
                                    },
                                    onRename: {
                                        sessionToRename = session
                                        newSessionName = session.name
                                        showingRenameSession = true
                                    },
                                    onDelete: {
                                        sessionToDelete = session
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.trailing, 8) // 给右侧留出空间
                    }
                    .frame(maxHeight: 100) // 限制滚动区域高度
                    
                    // Fixed Add button at bottom
                    Button(action: {
                        newSessionName = ""
                        showingAddSession = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Text(LocalizationKey.addSession.localized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 160, height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: -4)
                )
                .position(x: 80, y: -60) // 固定在按钮上方
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottom)))
                .onTapGesture {
                    // 阻止事件冒泡
                }
            }
        }
        .frame(width: 120, height: 50)
        .onTapGesture {
            // 点击列表外部时收起
            if isExpanded {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SessionDropdownShouldClose"))) { _ in
            // 接收外部通知收起列表
            if isExpanded {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded = false
                }
            }
        }
        .sheet(isPresented: $showingAddSession) {
            AddSessionView(
                sessionName: $newSessionName,
                onSave: { name in
                    if historyManager.createSession(name: name) {
                        showingAddSession = false
                    }
                },
                onCancel: {
                    showingAddSession = false
                }
            )
        }
        .sheet(isPresented: $showingRenameSession) {
            RenameSessionView(
                sessionName: $newSessionName,
                onSave: { name in
                    if let session = sessionToRename {
                        if historyManager.renameSession(id: session.id, newName: name) {
                            showingRenameSession = false
                            sessionToRename = nil
                        }
                    }
                },
                onCancel: {
                    showingRenameSession = false
                    sessionToRename = nil
                }
            )
        }
        .alert(LocalizationKey.deleteSession.localized, isPresented: $showingDeleteAlert) {
            Button(LocalizationKey.cancel.localized, role: .cancel) {
                sessionToDelete = nil
            }
            Button(LocalizationKey.delete.localized, role: .destructive) {
                if let session = sessionToDelete {
                    let success = historyManager.deleteSession(id: session.id)
                    if success {
                        sessionToDelete = nil
                    }
                }
            }
        } message: {
            if let session = sessionToDelete {
                Text("\(LocalizationKey.areYouSureDelete.localized) '\(session.name)'? \(LocalizationKey.thisActionCannotBeUndone.localized)")
            }
        }
    }
}

struct SessionRowView: View {
    let session: SessionModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Text(session.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Context menu for rename/delete
            Menu {
                Button(LocalizationKey.renameSession.localized) {
                    onRename()
                }
                
                Button(LocalizationKey.deleteSession.localized, role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .opacity(isHovered ? 1.0 : 0.8)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

struct AddSessionView: View {
    @Binding var sessionName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizationKey.addNewSession.localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            TextField(LocalizationKey.sessionName.localized, text: $sessionName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.white)
                .background(Color.black.opacity(0.8))
                .focused($isTextFieldFocused)
                .onAppear {
                    // 确保TextField在视图出现时获得焦点
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
            
            HStack(spacing: 16) {
                Button(LocalizationKey.cancel.localized) {
                    onCancel()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(LocalizationKey.save.localized) {
                    onSave(sessionName)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .frame(width: 300)
        .onAppear {
            // 确保视图完全渲染后再设置焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextFieldFocused = true
            }
        }
    }
}

struct RenameSessionView: View {
    @Binding var sessionName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizationKey.renameSession.localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            TextField(LocalizationKey.sessionName.localized, text: $sessionName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.white)
                .background(Color.black.opacity(0.8))
                .focused($isTextFieldFocused)
                .onAppear {
                    // 确保TextField在视图出现时获得焦点
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
            
            HStack(spacing: 16) {
                Button(LocalizationKey.cancel.localized) {
                    onCancel()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(LocalizationKey.save.localized) {
                    onSave(sessionName)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .frame(width: 300)
        .onAppear {
            // 确保视图完全渲染后再设置焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextFieldFocused = true
            }
        }
    }
}

