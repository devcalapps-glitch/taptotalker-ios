import SwiftUI
import PhotosUI
import UIKit

struct CardEditorView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    let card: AACCard

    @State private var labelText: String = ""
    @State private var emojiText: String = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var pendingImageData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Card") {
                    LabeledContent("Built-in") {
                        HStack(spacing: 8) {
                            if let openMoji = OpenMoji.image(forEmoji: card.emoji) {
                                Image(uiImage: openMoji)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                            } else {
                                Text(card.emoji)
                            }
                            Text(card.label)
                        }
                    }
                }

                Section("Custom label") {
                    TextField("Label", text: $labelText)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Custom emoji") {
                    TextField("Emoji", text: $emojiText)
                        .font(.largeTitle)
                }

                Section("Custom image") {
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityLabel("Custom card image preview")
                    }

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Choose photo", systemImage: "photo")
                    }
                    .onChange(of: pickerItem) { _, item in
                        Task { await loadImage(from: item) }
                    }
                }

                Section {
                    Button("Save custom card", action: save)
                        .font(.headline)

                    Button("Reset to default", role: .destructive) {
                        app.clearCardOverride(cardID: card.id)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                let existing = app.override(for: card.id)
                labelText = existing?.label ?? card.label
                emojiText = existing?.emoji ?? card.emoji
                previewImage = app.image(for: card.id)
            }
        }
    }

    private func save() {
        app.saveCardOverride(
            cardID: card.id,
            label: labelText,
            emoji: emojiText,
            imageData: pendingImageData
        )
        // A completed edit returns caregivers to the normal custom board.
        app.cardMode = .custom
        dismiss()
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            let jpeg = image.jpegData(compressionQuality: 0.82)
            await MainActor.run {
                previewImage = image
                pendingImageData = jpeg
            }
        }
    }
}
