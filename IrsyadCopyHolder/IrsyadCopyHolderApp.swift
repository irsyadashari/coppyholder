//
//  IrsyadCopyHolderApp.swift
//  IrsyadCopyHolder
//
//  Created by Muh Irsyad Ashari on 7/15/25.
//

import SwiftUI
import SwiftData
import ServiceManagement

@main
struct IrsyadCopyHolderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ClipboardItemModel.self)
    }
}
