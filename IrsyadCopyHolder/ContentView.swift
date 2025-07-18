//
//  ContentView.swift
//  IrsyadCopyHolder
//
//  Created by Muh Irsyad Ashari on 7/15/25.
//

import SwiftUI
import AppKit
import SwiftData

@Model
class ClipboardItemModel {
    @Attribute(.unique) var id: UUID
    var content: String
    var date: Date
    
    init(id: UUID = UUID(), content: String, date: Date = .now) {
        self.id = id
        self.content = content
        self.date = date
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItemModel.date, order: .reverse) private var items: [ClipboardItemModel]
    
    @State private var selectedItem: ClipboardItemModel?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var highlightedItemID: UUID?
    @State private var lastCopied: String = ""
    @State private var isManuallyCopying = false
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            NavigationSplitView {
                ScrollViewReader { proxy in
                    List(selection: $selectedItem) {
                        ForEach(items) { item in
                            VStack(alignment: .leading) {
                                Text(item.content)
                                    .lineLimit(1)
                                Text(item.date, format: Date.FormatStyle(date: .numeric, time: .standard))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(item.id == highlightedItemID ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                            .onTapGesture(count: 2) {
                                isManuallyCopying = true
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(item.content, forType: .string)
                                lastCopied = item.content
                                toastMessage = "Copied to clipboard"
                                highlightedItemID = item.id
                                selectedItem = item // ✅ Show it in the right pane
                                showToastWithTimeout()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    isManuallyCopying = false
                                }
                            }

                            .id(item.id)
                        }
                    }
                    .onChange(of: items.first?.id) { newID in
                        if let newID {
                            withAnimation {
                                proxy.scrollTo(newID, anchor: .top)
                            }
                        }
                    }
                    .navigationTitle("Clipboard")
                }
            } detail: {
                NavigationStack {
                    if let item = selectedItem ?? items.first {
                        ScrollView {
                            Text(item.content)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .navigationTitle("Latest Copied Item")
                    } else {
                        Text("No clipboard content")
                            .navigationTitle("Latest Copied Item")
                    }
                }
            }

            
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
        }
        .onReceive(timer) { _ in
            guard !isManuallyCopying else { return }
            
            if let copied = NSPasteboard.general.string(forType: .string),
               copied != lastCopied,
               !items.contains(where: { $0.content == copied }) {
                lastCopied = copied
                let newItem = ClipboardItemModel(content: copied, date: .now)
                modelContext.insert(newItem)
                selectedItem = nil
            }
        }
        .task {
            await deleteItemsOlderThanOneWeek()
        }
    }
    
    func deleteItemsOlderThanOneWeek() async {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        for item in items where item.date < oneWeekAgo {
            modelContext.delete(item)
        }
        
        try? modelContext.save()
        print("🧹 Deleted items older than 7 days")
    }

    
    private func showToastWithTimeout(duration: TimeInterval = 2.0) {
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                showToast = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ClipboardItemModel.self, inMemory: true)
}

