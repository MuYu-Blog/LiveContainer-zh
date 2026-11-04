//
//  LCAppPreferencesView.swift
//  LiveContainerSwiftUI
//
//  「应用设置」子页：原设置页杂项段的开关整体收进这里，
//  设置主页只留一行入口（与存储管理同款）。各开关的
//  AppStorage 键与行为原样保留。
//

import Foundation
import SwiftUI
import UserNotifications

struct LCAppPreferencesView: View {
    @AppStorage("LCFrameShortcutIcons") var frameShortIcon = false
    @AppStorage("LCSwitchAppWithoutAsking") var silentSwitchApp = false
    @AppStorage("LCOpenWebPageWithoutAsking") var silentOpenWebPage = false
    @AppStorage("LCDontSignApp", store: LCUtils.appGroupUserDefault) var dontSignApp = false
    @AppStorage("LCStrictHiding", store: LCUtils.appGroupUserDefault) var strictHiding = false

    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    @EnvironmentObject private var sharedModel : SharedModel

    private var notificationAuthText: String {
        switch notificationAuthStatus {
        case .authorized: return "已开启"
        case .denied: return "已关闭"
        case .notDetermined: return "未申请"
        case .provisional: return "临时授权"
        case .ephemeral: return "临时"
        @unknown default: return "未知"
        }
    }
    private func refreshNotificationAuth() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { notificationAuthStatus = settings.authorizationStatus }
        }
    }

    var body: some View {
        Form {
            Section {
            Toggle(isOn: $frameShortIcon) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        LCSettingsIcon(systemName: "plus.app", color: .green)
                        Text("lc.settings.FrameIcon".loc)
                    }
                    Text("lc.settings.FrameIconDesc".loc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $silentSwitchApp) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        LCSettingsIcon(systemName: "eye.slash", color: .gray)
                        Text("lc.settings.silentSwitchApp".loc)
                    }
                    Text("lc.settings.silentSwitchAppDesc".loc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $silentOpenWebPage) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        LCSettingsIcon(systemName: "globe", color: .teal)
                        Text("lc.settings.silentOpenWebPage".loc)
                    }
                    Text("lc.settings.silentOpenWebPageDesc".loc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            if sharedModel.isHiddenAppUnlocked {
                Toggle(isOn: $strictHiding) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            LCSettingsIcon(systemName: "hand.raised.fill", color: .red)
                            Text("lc.settings.strictHiding".loc)
                        }
                        Text("lc.settings.strictHidingDesc".loc)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Toggle(isOn: $dontSignApp) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        LCSettingsIcon(systemName: "signature", color: .orange)
                        Text("lc.settings.dontSign".loc)
                    }
                    Text("lc.settings.dontSignDesc".loc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                clearNotifications()
            } label: {
                HStack {
                    LCSettingsIcon(systemName: "bell.slash.fill", color: .red)
                    Text("lc.settings.clearNotifications".loc)
                }
            }
            // 通知权限行：状态从系统实时读；未申请点一下
            // 直接申请，已拒绝点一下跳系统设置，已开启不
            // 显示按钮。从系统设置回来时刷新一次状态。
            HStack {
                LCSettingsIcon(systemName: "bell.fill", color: .orange)
                Text("通知权限")
                Spacer()
                Text(notificationAuthText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if notificationAuthStatus != .authorized {
                    Button(notificationAuthStatus == .denied ? "去设置" : "开启") {
                        if notificationAuthStatus == .denied {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } else {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                                refreshNotificationAuth()
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .onAppear { refreshNotificationAuth() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                refreshNotificationAuth()
            }
            }
        }
        .navigationTitle("应用设置")
    }

    func clearNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        if #available(iOS 16.0, *) {
            notificationCenter.setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}
