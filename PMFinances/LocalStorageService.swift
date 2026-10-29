import Foundation

public struct FileStorageMetadata: Sendable {
    public let exists: Bool
    public let lastModified: Date?
    public let sizeInBytes: Int64
    public let recordCount: Int
    public let fileName: String

    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeInBytes)
    }

    public var formattedDate: String {
        guard let lastModified else { return "No disponible" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastModified)
    }
}

public final class LocalStorageService: Sendable {
    public static let shared = LocalStorageService()

    private let bookmarkKey = "finanzas_storage_folder_bookmark"
    private let customPathDisplayKey = "finanzas_storage_folder_display_path"
    private let fileName = "finanzas.json"
    private let categoriesFileName = "categorias.json"

    private init() {
        createDefaultFolderIfNeeded()
    }

    // MARK: - Folder Management

    public var isCustomFolderConfigured: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    public var currentFolderDisplayName: String {
        if let stored = UserDefaults.standard.string(forKey: customPathDisplayKey), !stored.isEmpty {
            return stored
        }
        if let folderURL = getStorageFolderURL() {
            return folderURL.lastPathComponent
        }
        return "Carpeta local de la App"
    }

    public var isICloudStorage: Bool {
        guard let folderURL = getStorageFolderURL() else { return false }
        let path = folderURL.path.lowercased()
        return path.contains("mobile documents") || path.contains("icloud")
    }

    public func saveFolderURL(_ url: URL) throws {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }

        #if os(iOS) || os(macOS)
        let bookmarkData = try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
        UserDefaults.standard.set(url.lastPathComponent, forKey: customPathDisplayKey)
        #endif

        // Ensure finanzas.json exists in the newly selected folder
        let fileURL = url.appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let initialRecords = MockData.generateMockRecords()
            try writeRecords(initialRecords, to: fileURL)
        }

        // Ensure categorias.json exists in the newly selected folder
        let categoriesURL = url.appendingPathComponent(categoriesFileName)
        if !FileManager.default.fileExists(atPath: categoriesURL.path) {
            let defaults = FinancialCategory.defaultCategories
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(defaults)
            try data.write(to: categoriesURL, options: .atomic)
        }
    }

    public func resetToDefaultFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: customPathDisplayKey)
        createDefaultFolderIfNeeded()
    }

    public func getStorageFolderURL() -> URL? {
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) {
            var isStale = false
            do {
                let resolvedURL = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withoutUI,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                if isStale {
                    if let freshBookmark = try? resolvedURL.bookmarkData(
                        options: .minimalBookmark,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        UserDefaults.standard.set(freshBookmark, forKey: bookmarkKey)
                    }
                }
                return resolvedURL
            } catch {
                print("Error resolving folder bookmark: \(error)")
            }
        }
        return defaultFolderURL()
    }

    public func getDatabaseFileURL() -> URL? {
        guard let folderURL = getStorageFolderURL() else { return nil }
        return folderURL.appendingPathComponent(fileName)
    }

    public func getCategoriesFileURL() -> URL? {
        guard let folderURL = getStorageFolderURL() else { return nil }
        return folderURL.appendingPathComponent(categoriesFileName)
    }

    private func defaultFolderURL() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = documentsURL.appendingPathComponent("Finanzas", isDirectory: true)
        return folder
    }

    private func createDefaultFolderIfNeeded() {
        guard let folder = defaultFolderURL() else { return }
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let fileURL = folder.appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let initialRecords = MockData.generateMockRecords()
            try? writeRecords(initialRecords, to: fileURL)
        }
        let catURL = folder.appendingPathComponent(categoriesFileName)
        if !FileManager.default.fileExists(atPath: catURL.path) {
            let defaults = FinancialCategory.defaultCategories
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(defaults) {
                try? data.write(to: catURL, options: .atomic)
            }
        }
    }

    // MARK: - Records CRUD

    public func fetchRecords() throws -> [FinancialRecord] {
        guard let fileURL = getDatabaseFileURL(), let folderURL = getStorageFolderURL() else {
            return []
        }

        let didStart = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([FinancialRecord].self, from: data)
        return records
    }

    public func saveAllRecords(_ records: [FinancialRecord]) throws {
        guard let fileURL = getDatabaseFileURL(), let folderURL = getStorageFolderURL() else {
            throw NSError(domain: "LocalStorageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No se encontró la carpeta de destino."])
        }

        let didStart = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        try writeRecords(records, to: fileURL)
    }

    public func createRecord(name: String, cantidad: Double, categoria: String, tipo: TransactionType, fecha: Date) throws -> FinancialRecord {
        var records = try fetchRecords()
        let newRecord = FinancialRecord(
            id: UUID().uuidString,
            name: name,
            cantidad: cantidad,
            categoria: categoria,
            fecha: fecha,
            tipo: tipo
        )
        records.insert(newRecord, at: 0)
        try saveAllRecords(records)
        return newRecord
    }

    public func updateRecord(_ updated: FinancialRecord) throws {
        var records = try fetchRecords()
        if let index = records.firstIndex(where: { $0.id == updated.id }) {
            records[index] = updated
            try saveAllRecords(records)
        } else {
            throw NSError(domain: "LocalStorageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Registro no encontrado."])
        }
    }

    public func deleteRecord(id: String) throws {
        var records = try fetchRecords()
        records.removeAll(where: { $0.id == id })
        try saveAllRecords(records)
    }

    public func loadDemoData() throws {
        let sample = MockData.generateMockRecords()
        try saveAllRecords(sample)
    }

    // MARK: - Categories CRUD

    public func fetchCategories() throws -> [CategoryItem] {
        guard let fileURL = getCategoriesFileURL(), let folderURL = getStorageFolderURL() else {
            return FinancialCategory.defaultCategories
        }

        let didStart = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let defaults = FinancialCategory.defaultCategories
            try? saveCategories(defaults)
            return defaults
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let items = try decoder.decode([CategoryItem].self, from: data)
        CategoryRegistry.shared.register(categories: items)
        return items
    }

    public func saveCategories(_ categories: [CategoryItem]) throws {
        guard let fileURL = getCategoriesFileURL(), let folderURL = getStorageFolderURL() else {
            throw NSError(domain: "LocalStorageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No se encontró la carpeta de destino."])
        }

        let didStart = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(categories)
        try data.write(to: fileURL, options: .atomic)

        CategoryRegistry.shared.reset(to: categories)
    }

    // MARK: - Metadata

    public func getMetadata() -> FileStorageMetadata {
        guard let fileURL = getDatabaseFileURL(), let folderURL = getStorageFolderURL() else {
            return FileStorageMetadata(exists: false, lastModified: nil, sizeInBytes: 0, recordCount: 0, fileName: fileName)
        }

        let didStart = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return FileStorageMetadata(exists: false, lastModified: nil, sizeInBytes: 0, recordCount: 0, fileName: fileName)
        }

        var fileSize: Int64 = 0
        var modDate: Date? = nil
        var count = 0

        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            fileSize = (attrs[.size] as? NSNumber)?.int64Value ?? 0
            modDate = attrs[.modificationDate] as? Date
        }

        if let data = try? Data(contentsOf: fileURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let records = try? decoder.decode([FinancialRecord].self, from: data) {
                count = records.count
            }
        }

        return FileStorageMetadata(
            exists: true,
            lastModified: modDate,
            sizeInBytes: fileSize,
            recordCount: count,
            fileName: fileName
        )
    }

    private func writeRecords(_ records: [FinancialRecord], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(records)
        try data.write(to: url, options: .atomic)
    }
}
