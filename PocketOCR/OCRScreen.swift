import PhotosUI
import SwiftUI
import UIKit

struct OCRScreen: View {
    @StateObject private var model = OCRModel()
    @State private var selection: PhotosPickerItem?
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                photoControls
                resultCard
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .tint(.indigo)
        .onChange(of: selection) { _, item in
            guard let item else { return }
            copied = false
            model.select(item)
            selection = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "text.viewfinder")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.indigo)
                .padding(14)
                .background(Color.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                .accessibilityHidden(true)

            Text("Pocket OCR")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            Text("Извлекайте текст с фотографий на русском и английском.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var photoControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $selection, matching: .images, preferredItemEncoding: .current) {
                Label("Выбрать фото", systemImage: "photo")
                    .font(.headline)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .controlSize(.large)

            Label("Распознавание на устройстве", systemImage: "lock")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Результат")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            switch model.state {
            case .idle:
                status("Здесь появится текст с фотографии.", symbol: "text.alignleft")
            case .loading:
                ProgressView("Загружаем фото…")
                    .frame(minHeight: 44, alignment: .leading)
            case .recognizing:
                ProgressView("Распознаём текст…")
                    .frame(minHeight: 44, alignment: .leading)
            case .result(let text):
                Text(verbatim: text)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    UIPasteboard.general.string = text
                    copied = true
                } label: {
                    if copied {
                        Label("Скопировано", systemImage: "checkmark")
                    } else {
                        Label("Скопировать текст", systemImage: "doc.on.doc")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            case .empty:
                status("Текст не найден. Попробуйте фото, на котором надписи хорошо видны.",
                       symbol: "text.magnifyingglass")
            case .failed(let message):
                status(message, symbol: "exclamationmark.circle")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func status(_ message: String, symbol: String) -> some View {
        Label(message, systemImage: symbol)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
