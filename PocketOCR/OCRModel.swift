import Combine
import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class OCRModel: ObservableObject {
    enum State {
        case idle
        case loading
        case recognizing
        case result(String)
        case empty
        case failed(String)
    }

    @Published private(set) var state = State.idle
    private var currentTask: Task<Void, Never>?

    func select(_ item: PhotosPickerItem) {
        currentTask?.cancel()
        state = .loading

        currentTask = Task {
            let loadFailure = State.failed("Не удалось загрузить фото. Выберите его ещё раз или попробуйте другое.")
            let data: Data
            do {
                guard let loadedData = try await item.loadTransferable(type: Data.self) else {
                    show(loadFailure)
                    return
                }
                data = loadedData
            } catch {
                show(loadFailure)
                return
            }

            guard !Task.isCancelled else { return }
            state = .recognizing

            do {
                let text = try await TextRecognizer.recognize(data)
                show(text.isEmpty ? .empty : .result(text))
            } catch TextRecognizer.Failure.invalidImage {
                show(.failed("Не удалось открыть изображение. Попробуйте выбрать другое фото."))
            } catch TextRecognizer.Failure.unsupportedLanguages {
                show(.failed("На этом устройстве Vision не поддерживает распознавание русского и английского вместе."))
            } catch {
                show(.failed("Не удалось распознать текст. Попробуйте выбрать фото ещё раз."))
            }
        }
    }

    private func show(_ newState: State) {
        guard !Task.isCancelled else { return }
        state = newState
    }
}
