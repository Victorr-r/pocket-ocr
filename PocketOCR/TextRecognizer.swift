import Foundation
import ImageIO
import Vision

enum TextRecognizer {
    enum Failure: Error {
        case invalidImage
        case unsupportedLanguages
    }

    static func recognize(_ data: Data) async throws -> String {
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            return try recognizeImage(data)
        }

        return try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: {
            worker.cancel()
        }
    }

    private static func recognizeImage(_ data: Data) throws -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw Failure.invalidImage
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
        let orientationValue = (properties as? [String: Any])?[kCGImagePropertyOrientation as String]
        let orientation = (orientationValue as? UInt32)
            .flatMap(CGImagePropertyOrientation.init(rawValue:)) ?? .up

        let request = VNRecognizeTextRequest()
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let languages = ["ru-RU", "en-US"]
        let supported = try request.supportedRecognitionLanguages()
        guard languages.allSatisfy(supported.contains) else {
            throw Failure.unsupportedLanguages
        }
        request.recognitionLanguages = languages

        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        try Task.checkCancellation()
        try handler.perform([request])
        try Task.checkCancellation()

        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
