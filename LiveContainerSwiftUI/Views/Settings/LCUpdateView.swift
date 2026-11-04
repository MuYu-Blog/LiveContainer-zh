//
//  LCUpdateView.swift
//  LiveContainerSwiftUI
//
//  「更新」子页：原设置页更新段整体收进这里，设置主页
//  只留一行入口（与存储管理同款）。更新源已改为
//  MuYu-Blog/LiveContainer-zh 自己的 update release。
//

import Foundation
import SwiftUI

struct LCUpdateView: View {
    @State var errorShow = false
    @State var errorInfo = ""

    // App 内更新检查（CZF，2026-10-29）：查 fork 自己的 update release
    // release，对比本机 LCVersionInfo 里的短提交号；有新版不
    // 自己下载安装（侧载 App 换不了自己的包），而是跳
    // sideinstaller://install?url=，由 SideInstaller 🅥 下载、
    // 签名、覆盖安装，SideInstaller 那边还会再弹一次确认。
    @State private var updateStatusText = "点一下检查"
    @State private var updateChecking = false
    @State private var updateInfo: CZFUpdateInfo?
    private func startUpdateCheck() {
        guard !updateChecking else { return }
        updateChecking = true
        updateStatusText = "检查中…"
        CZFUpdateCheck.check { result in
            DispatchQueue.main.async {
                updateChecking = false
                switch result {
                case .failure:
                    updateInfo = nil
                    updateStatusText = "检查失败，点一下重试"
                case .success(let info):
                    if let current = CZFUpdateCheck.currentCommit(), current == info.commit {
                        updateInfo = nil
                        updateStatusText = "已是最新（\(current)）"
                    } else {
                        updateInfo = info
                        var text = "有新版：\(info.commit)"
                        if let date = info.publishedAt {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            text += " · \(formatter.string(from: date))"
                        }
                        updateStatusText = text
                    }
                }
            }
        }
    }
    private func openSideInstallerInstall() {
        guard let info = updateInfo else { return }
        var components = URLComponents()
        components.scheme = "sideinstaller"
        components.host = "install"
        components.queryItems = [URLQueryItem(name: "url", value: info.downloadURL.absoluteString)]
        guard let url = components.url else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                errorInfo = "没能打开 SideInstaller 🅥，请确认它已安装"
                errorShow = true
            }
        }
    }
    // 去 Seal 更新：照抄 openSideInstallerInstall，只换 scheme。
    // Seal 注册了 seal 和 sidestore 两个 scheme，用户定用
    // sidestore://install?url= 这个格式，不要自创 seal://。
    private func openSealInstall() {
        guard let info = updateInfo else { return }
        var components = URLComponents()
        components.scheme = "sidestore"
        components.host = "install"
        components.queryItems = [URLQueryItem(name: "url", value: info.downloadURL.absoluteString)]
        guard let url = components.url else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                errorInfo = "没能打开 Seal，请确认它已安装"
                errorShow = true
            }
        }
    }

    var body: some View {
        Form {
            Section {
            Button {
                startUpdateCheck()
            } label: {
                HStack {
                    LCSettingsIcon(systemName: "arrow.down.circle", color: .blue)
                    Text("检查更新")
                    Spacer()
                    Text(updateStatusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(updateChecking)
            if updateInfo != nil {
                Button {
                    openSideInstallerInstall()
                } label: {
                    HStack {
                        LCSettingsIcon(systemName: "arrow.clockwise.circle", color: .green)
                        Text("去 SideInstaller 更新")
                    }
                }
                Button {
                    openSealInstall()
                } label: {
                    HStack {
                        LCSettingsIcon(systemName: "arrow.clockwise.circle", color: .green)
                        Text("去 Seal 更新")
                    }
                }
                Text("点更新会跳到 SideInstaller 🅥 下载安装，安装时会关闭 LiveContainer，装好后重新打开；更新前建议先在数据管理里备份一次。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            }
        }
        .navigationTitle("更新")
        .alert("lc.common.error".loc, isPresented: $errorShow){
        } message: {
            Text(errorInfo)
        }
    }
}
