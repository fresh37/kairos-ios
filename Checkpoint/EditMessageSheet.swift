//
//  EditMessageSheet.swift
//  Checkpoint
//
//  Focused text-entry sheet used by CustomMessagesSheet
//  for both adding and editing custom notification messages.
//

import SwiftUI

struct EditMessageSheet: View {
    let initialText: String
    let onSave: (String) -> Void

    @Environment(\.dismiss)  private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    private var isAdding: Bool { initialText.isEmpty }
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Message")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(theme.textMuted)
                        .padding(.leading, 4)

                    TextField(
                        "e.g. Take a slow breath right now.",
                        text: $text,
                        axis: .vertical
                    )
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(theme.textPrimary)
                    .tint(theme.accent)
                    .lineLimit(3...6)
                    .focused($isFocused)
                    .padding(14)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .navigationTitle(isAdding ? "New Message" : "Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(theme.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(trimmed)
                        dismiss()
                    }
                    .foregroundStyle(canSave ? theme.accent : theme.textMuted)
                    .disabled(!canSave)
                }
            }
        }
        .colorScheme(.dark)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(theme.background)
        .onAppear {
            text = initialText
            isFocused = true
        }
    }
}

#Preview {
    EditMessageSheet(initialText: "") { _ in }
}
