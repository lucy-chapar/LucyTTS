import Foundation

enum AudioFileInfo {
    static func byteCount(for url: URL) -> Int? {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey])
        if let total = values?.totalFileSize, total > 0 {
            return total
        }
        if let size = values?.fileSize, size > 0 {
            return size
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int, size > 0 {
            return size
        }
        return nil
    }

    static func formattedSize(for url: URL) -> String {
        guard let bytes = byteCount(for: url) else {
            return "unknown size"
        }
        return formattedSize(bytes: bytes)
    }

    static func formattedSize(bytes: Int) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 0.1 {
            return String(format: "%.1f MB", mb)
        }
        let kb = Double(bytes) / 1024
        return String(format: "%.0f KB", kb)
    }
}
