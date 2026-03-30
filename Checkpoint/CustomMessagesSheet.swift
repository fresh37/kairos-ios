//
//  CustomMessagesSheet.swift
//  Checkpoint
//
//  Sheet for managing user-defined notification messages.
//  Presented from SettingsDrawer via the "Custom Messages" row.
//

import SwiftUI

struct CustomMessagesSheet: View {
    @Binding var messages: [String]
    @Binding var isEnabled: Bool

    @Environment(\.dismiss)  private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var showAddSheet = false
    @State private var editingMessage: EditTarget?

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        SettingsGroup(label: "Custom Messages") {
                            Toggle(isOn: $isEnabled) {
                                Text("Use in Notifications")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(theme.textPrimary)
                            }
                            .tint(theme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }

                        SettingsGroup(label: "Your Messages") {
                            if messages.isEmpty {
                                Text("No messages yet. Tap Add to create one.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(theme.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(messages.indices, id: \.self) { index in
                                    if index > 0 {
                                        Rectangle()
                                            .fill(theme.divider)
                                            .frame(height: 0.5)
                                            .padding(.leading, 16)
                                    }
                                    messageRow(index: index)
                                }
                            }
                        }

                        Button {
                            showAddSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(theme.accent)
                                Text("Add Message")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(theme.accent)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .background(theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Custom Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .colorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(theme.background)
        .sheet(isPresented: $showAddSheet) {
            EditMessageSheet(initialText: "") { newText in
                messages.append(newText)
            }
            .environment(\.appTheme, theme)
        }
        .sheet(item: $editingMessage) { target in
            EditMessageSheet(initialText: target.text) { newText in
                guard target.index < messages.count else { return }
                messages[target.index] = newText
            }
            .environment(\.appTheme, theme)
        }
    }

    // MARK: - Message row

    private func messageRow(index: Int) -> some View {
        HStack {
            Text(messages[index])
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button {
                editingMessage = EditTarget(index: index, text: messages[index])
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(theme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)

            Button(role: .destructive) {
                guard index < messages.count else { return }
                messages.remove(at: index)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(theme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - EditTarget

private struct EditTarget: Identifiable {
    let id = UUID()
    let index: Int
    let text: String
}

#Preview {
    CustomMessagesSheet(
        messages: .constant(["What are you grateful for right now?", "Notice your breath."]),
        isEnabled: .constant(true)
    )
}
