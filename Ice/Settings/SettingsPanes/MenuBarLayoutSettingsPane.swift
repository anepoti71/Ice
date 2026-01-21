//
//  MenuBarLayoutSettingsPane.swift
//  Ice
//

import SwiftUI

struct MenuBarLayoutSettingsPane: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if !ScreenCapture.cachedCheckPermissions() {
            missingScreenRecordingPermission
        } else if appState.menuBarManager.isMenuBarHiddenBySystemUserDefaults {
            cannotArrange
        } else {
            IceForm(alignment: .leading, spacing: 20) {
                header
                layoutBars
#if SWIFT_PACKAGE
                debugStatus
#endif
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        Text("Drag to arrange your menu bar items")
            .font(.title2)

        IceGroupBox {
            AnnotationView(
                alignment: .center,
                font: .callout.bold()
            ) {
                Label {
                    Text("Tip: you can also arrange menu bar items by Command + dragging them in the menu bar")
                } icon: {
                    Image(systemName: "lightbulb")
                }
            }
        }
    }

    @ViewBuilder
    private var layoutBars: some View {
        VStack(spacing: 25) {
            ForEach(MenuBarSection.Name.allCases, id: \.self) { section in
                layoutBar(for: section)
            }
        }
    }

#if SWIFT_PACKAGE
    @ViewBuilder
    private var debugStatus: some View {
        let access = appState.permissionsManager.accessibilityPermission.hasPermission
        let screen = appState.permissionsManager.screenRecordingPermission.hasPermission
        let cachedScreen = ScreenCapture.cachedCheckPermissions()
        let totalItems = appState.itemManager.itemCache.allItems.count
        let managedItems = appState.itemManager.itemCache.managedItems.count
        let cachedImages = appState.imageCache.images.count
        let windowList = Bridging.getWindowList(option: [.menuBarItems, .activeSpace]).count
        let fallbackWindows = WindowInfo.getOnScreenWindows(excludeDesktopWindows: true)
            .filter { $0.isMenuBarItem }
        let fallbackWindowList = fallbackWindows.count
        let onScreenWindowCount = Bridging.onScreenWindowCount
        let menuBarItems = MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
        let hiddenControlPresent = menuBarItems.contains { $0.info == .hiddenControlItem }
        let alwaysHiddenControlPresent = menuBarItems.contains { $0.info == .alwaysHiddenControlItem }
        let iceIconPresent = menuBarItems.contains { $0.info == .iceIcon }
        let fallbackDetails = fallbackWindows.prefix(8).map { window in
            let title = window.title?.isEmpty == false ? window.title! : "<no title>"
            let owner = window.ownerName ?? "<no owner>"
            return "\(title) — \(owner)"
        }
        let fallbackItemDetails = fallbackWindows.prefix(8).compactMap { window -> String? in
            guard let item = MenuBarItem(itemWindow: window) else {
                return nil
            }
            let ownerName = item.ownerName ?? "<no owner>"
            let bundleID = item.owningApplication?.bundleIdentifier ?? "<no bundle>"
            return "\(item.info.description) — \(ownerName) — \(bundleID)"
        }
        let icePID = getpid()
        let iceBundle = Bundle.main.bundleIdentifier ?? "<no bundle>"
        let windowPIDDetails = fallbackWindows.prefix(8).map { window in
            let title = window.title ?? "<nil>"
            let isIce = window.ownerPID == icePID
            return "PID:\(window.ownerPID) wid:\(window.windowID) title:\(title) isIce:\(isIce)"
        }
        // Control item window IDs
        let hiddenSection = appState.menuBarManager.section(withName: .hidden)
        let hiddenControlWindowID = hiddenSection?.controlItem.windowID
        let hiddenControlWindow = hiddenSection?.controlItem.window
        let hiddenControlWindowNumber = hiddenControlWindow?.windowNumber
        let alwaysHiddenSection = appState.menuBarManager.section(withName: .alwaysHidden)
        let alwaysHiddenControlWindowID = alwaysHiddenSection?.controlItem.windowID
        let visibleSection = appState.menuBarManager.section(withName: .visible)
        let iceIconWindowID = visibleSection?.controlItem.windowID

        // Check if control item window IDs exist in fallback windows
        let hiddenInFallback = fallbackWindows.contains { $0.windowID == hiddenControlWindowID }
        let allWindowIDs = fallbackWindows.map { $0.windowID }

        IceGroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text("Debug Status (SwiftPM build)")
                    .font(.headline)
                Text("Accessibility: \(access ? "granted" : "missing")")
                Text("Screen Recording: \(screen ? "granted" : "missing")")
                Text("ScreenCapture cached: \(cachedScreen ? "true" : "false")")
                Text("Bridging menu bar windows: \(windowList)")
                Text("Fallback menu bar windows: \(fallbackWindowList)")
                Text("On-screen window count: \(onScreenWindowCount)")
                Text("MenuBarItem count: \(menuBarItems.count)")
                Text("Ice icon present: \(iceIconPresent ? "yes" : "no")")
                Text("Hidden control present: \(hiddenControlPresent ? "yes" : "no")")
                Text("Always-hidden control present: \(alwaysHiddenControlPresent ? "yes" : "no")")
                Text("Item cache total: \(totalItems)")
                Text("Item cache managed: \(managedItems)")
                Text("Image cache count: \(cachedImages)")
                Text("Cache keys: \(appState.imageCache.images.keys.prefix(5).map { $0.description }.joined(separator: ", "))")
                let visibleItems = appState.itemManager.itemCache[.visible]
                Text("Visible items: \(visibleItems.prefix(5).map { $0.info.description }.joined(separator: ", "))")
                Divider()
                Text("Ice PID: \(icePID)")
                Text("Ice Bundle: \(iceBundle)")
                Text("IceIcon windowID: \(iceIconWindowID.map { String($0) } ?? "nil")")
                Text("Hidden ctrl window: \(hiddenControlWindow != nil ? "exists" : "nil")")
                Text("Hidden ctrl windowNumber: \(hiddenControlWindowNumber.map { String($0) } ?? "nil")")
                Text("Hidden ctrl windowID: \(hiddenControlWindowID.map { String($0) } ?? "nil")")
                Text("AlwaysHidden ctrl windowID: \(alwaysHiddenControlWindowID.map { String($0) } ?? "nil")")
                Text("Hidden ctrl in fallback: \(hiddenInFallback ? "yes" : "no")")
                Text("All fallback wIDs: \(allWindowIDs.prefix(6).map { String($0) }.joined(separator: ", "))")
                Text("All titles: \(fallbackWindows.prefix(8).map { $0.title ?? "<nil>" }.joined(separator: ", "))")
                Text("Looking for HItem: \(fallbackWindows.contains { $0.title == "HItem" } ? "found" : "NOT found")")
                Text("Title contains 'Item': \(fallbackWindows.filter { $0.title?.contains("Item") == true }.map { $0.title ?? "" }.joined(separator: ", "))")
                Text("Hidden section exists: \(hiddenSection != nil ? "yes" : "no")")
                Text("Hidden ctrl isAddedToMenuBar: \(hiddenSection?.controlItem.isAddedToMenuBar == true ? "yes" : "no")")
                Text("Hidden ctrl isVisible: \(hiddenSection?.controlItem.isVisible == true ? "yes" : "no")")
                Text("Hidden ctrl window exists: \(hiddenSection?.controlItem.window != nil ? "yes" : "no")")
                Text("Hidden ctrl window.title: \"\(hiddenSection?.controlItem.window?.title ?? "<nil>")\"")
                Text("Hidden ctrl window.isVisible: \(hiddenSection?.controlItem.window?.isVisible == true ? "yes" : "no")")
                Text("Hidden ctrl windowFrame: \(hiddenSection?.controlItem.windowFrame.map { "\(Int($0.width))x\(Int($0.height))" } ?? "nil")")
                // Try to get CGWindowID directly from window number (even if negative)
                let hiddenWinNum = hiddenSection?.controlItem.window?.windowNumber
                Text("Hidden ctrl windowNumber (raw): \(hiddenWinNum.map { String($0) } ?? "nil")")
                // Check if raw windowNumber exists in fallback (cast to CGWindowID)
                let hiddenWinNumAsCG = hiddenWinNum.map { CGWindowID(bitPattern: Int32(truncatingIfNeeded: $0)) }
                Text("Hidden as CGWindowID: \(hiddenWinNumAsCG.map { String($0) } ?? "nil")")
                Text("Hidden CGWindowID in fallback: \(hiddenWinNumAsCG.map { wid in fallbackWindows.contains { $0.windowID == wid } } == true ? "yes" : "no")")
                if !windowPIDDetails.isEmpty {
                    Divider()
                    Text("Window PIDs:")
                    ForEach(windowPIDDetails, id: \.self) { detail in
                        Text(detail)
                    }
                }
                if !fallbackDetails.isEmpty {
                    Divider()
                    Text("Fallback sample:")
                    ForEach(fallbackDetails, id: \.self) { detail in
                        Text(detail)
                    }
                }
                if !fallbackItemDetails.isEmpty {
                    Divider()
                    Text("Fallback items:")
                    ForEach(fallbackItemDetails, id: \.self) { detail in
                        Text(detail)
                    }
                }
            }
            .font(.footnote)
        }
    }
#endif

    @ViewBuilder
    private var cannotArrange: some View {
        Text("Ice cannot arrange menu bar items in automatically hidden menu bars")
            .font(.title3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var missingScreenRecordingPermission: some View {
        VStack {
            Text("Menu bar layout requires screen recording permissions")
                .font(.title2)

            Button {
                appState.navigationState.settingsNavigationIdentifier = .advanced
            } label: {
                Text("Go to Advanced Settings")
            }
            .buttonStyle(.link)
        }
    }

    @ViewBuilder
    private func layoutBar(for section: MenuBarSection.Name) -> some View {
        if
            let section = appState.menuBarManager.section(withName: section),
            section.isEnabled
        {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(section.name.displayString) Section")
                    .font(.system(size: 14))
                    .padding(.leading, 2)

                LayoutBar(section: section)
                    .environmentObject(appState.imageCache)
            }
        }
    }
}
