import SwiftUI

struct CaregiverSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var pinDraft: String = ""
    @State private var didLoadPIN = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Changes stay on this iPad.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("Vocabulary mode") {
                    ForEach(VocabularyMode.allCases) { mode in
                        modeRow(mode)
                    }
                }

                Section("Card mode") {
                    ForEach(CardMode.allCases) { mode in
                        cardModeRow(mode)
                    }
                }

                Section {
                    SecureField("Caregiver PIN", text: $pinDraft)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .onAppear {
                            if !didLoadPIN {
                                pinDraft = app.settings.caregiverPIN
                                didLoadPIN = true
                            }
                        }

                    Button("Save PIN settings") {
                        app.saveCaregiverPIN(pinDraft)
                    }
                    .font(.headline)

                    if app.hasPIN {
                        Button("Clear PIN", role: .destructive) {
                            pinDraft = ""
                            app.clearPIN()
                        }
                    }
                } header: {
                    Text("Caregiver PIN")
                } footer: {
                    Text("Optional. When a PIN is saved, opening Settings asks for it first. Clear the field and save to remove PIN protection.")
                }
            }
            .navigationTitle("Caregiver settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func modeRow(_ mode: VocabularyMode) -> some View {
        Button {
            app.vocabularyMode = mode
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: app.vocabularyMode == mode ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(app.vocabularyMode == mode ? Color.accentColor : .secondary)
                    .font(.title2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(mode.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title). \(mode.detail)")
        .accessibilityAddTraits(app.vocabularyMode == mode ? [.isSelected, .isButton] : .isButton)
    }

    private func cardModeRow(_ mode: CardMode) -> some View {
        Button {
            app.cardMode = mode
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: app.cardMode == mode ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(app.cardMode == mode ? Color.accentColor : .secondary)
                    .font(.title2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(mode.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title). \(mode.detail)")
        .accessibilityAddTraits(app.cardMode == mode ? [.isSelected, .isButton] : .isButton)
    }
}
