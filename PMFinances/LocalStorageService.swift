import Foundation

public struct FileStorageMetadata: Sendable {
    public let exists: Bool
    public let lastModified: Date?
    public let sizeInBytes: Int64
    public let recordCount: Int
    public let fileName: String

    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let formatterLock = NSLock()

    public var formattedSize: String {
        Self.formatterLock.lock()
        defer { Self.formatterLock.unlock() }
        return Self.byteCountFormatter.string(fromByteCount: sizeInBytes)
    }

    public var formattedDate: String {
        guard let lastModified else { return "No disponible" }
        Self.formatterLock.lock()
        defer { Self.formatterLock.unlock() }
        return Self.dateFormatter.string(from: lastModified)
    }
}

public final class LocalStorageService: Sendable {
    public static let shared = LocalStorageService()

    private let bookmarkKey = "finanzas_storage_folder_bookmark"
    private let customPathDisplayKey = "finanzas_storage_folder_display_path"
    private let fileName = "finanzas.json"
    private let categoriesFileName = "categories.json"
    private let legacyCategoriesFileName = "categorias.json"

    private static let recordsDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let recordsEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let categoriesDecoder = JSONDecoder()

    private static let categoriesEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let cacheLock = NSLock()
    private var cachedStorageFolderURL: URL?
    private var cachedIsICloudStorage: Bool = false
    private var cachedDisplayName: String = "Carpeta local de la App"
    private var isCacheValid: Bool = false

    private init() {
        createDefaultFolderIfNeeded()
    }

    private func invalidateCache() {
        cacheLock.lock()
        isCacheValid = false
        cachedStorageFolderURL = nil
        cacheLock.unlock()
    }

    private func requiresSecurityScope(for url: URL) -> Bool {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        if url.path.hasPrefix(docs.path) {
            return false
        }
        return true
    }

    private func startAccessIfNeeded(for folderURL: URL) -> Bool {
        guard isCustomFolderConfigured && requiresSecurityScope(for: folderURL) else {
            return false
        }
        return folderURL.startAccessingSecurityScopedResource()
    }

    // MARK: - Folder Management

    public var isCustomFolderConfigured: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    public var currentFolderDisplayName: String {
        _ = getStorageFolderURL()
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return cachedDisplayName
    }

    public var isICloudStorage: Bool {
        _ = getStorageFolderURL()
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return cachedIsICloudStorage
    }

    public func saveFolderURL(_ url: URL) throws {
        let needsScope = requiresSecurityScope(for: url)
        let didStart = needsScope ? url.startAccessingSecurityScopedResource() : false
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }

        #if os(iOS)
        let bookmarkData = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #elseif os(macOS)
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #endif
        UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
        UserDefaults.standard.set(url.lastPathComponent, forKey: customPathDisplayKey)
        invalidateCache()

        // Ensure finanzas.json exists in the newly selected folder
        let fileURL = url.appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let initialRecords = MockData.generateMockRecords()
            try writeRecords(initialRecords, to: fileURL)
        }

        // Ensure categories.json exists in the newly selected folder (migrating legacy categorias.json if needed)
        let categoriesURL = url.appendingPathComponent(categoriesFileName)
        let legacyCatURL = url.appendingPathComponent(legacyCategoriesFileName)
        if !FileManager.default.fileExists(atPath: categoriesURL.path) {
            if FileManager.default.fileExists(atPath: legacyCatURL.path) {
                try? FileManager.default.moveItem(at: legacyCatURL, to: categoriesURL)
            } else {
                let defaults = FinancialCategory.defaultCategories
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(defaults)
                try data.write(to: categoriesURL, options: .atomic)
            }
        }

        // Auto-sync any categories found in the records to categories.json
        if let existingRecords = try? fetchRecords() {
            _ = try? syncCategoriesWithRecords(existingRecords)
        }
    }

    public func resetToDefaultFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: customPathDisplayKey)
        invalidateCache()
        createDefaultFolderIfNeeded()
    }

    public func getStorageFolderURL() -> URL? {
        cacheLock.lock()
        if isCacheValid {
            let url = cachedStorageFolderURL
            cacheLock.unlock()
            return url
        }
        cacheLock.unlock()

        let resolved = resolveStorageFolderURL()

        cacheLock.lock()
        cachedStorageFolderURL = resolved
        if let resolved = resolved {
            let path = resolved.path.lowercased()
            cachedIsICloudStorage = path.contains("mobile documents") || path.contains("icloud")
            if let stored = UserDefaults.standard.string(forKey: customPathDisplayKey), !stored.isEmpty {
                cachedDisplayName = stored
            } else {
                cachedDisplayName = resolved.lastPathComponent
            }
        } else {
            cachedIsICloudStorage = false
            cachedDisplayName = "Carpeta local de la App"
        }
        isCacheValid = true
        cacheLock.unlock()

        return resolved
    }

    private func resolveStorageFolderURL() -> URL? {
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) {
            var isStale = false
            do {
                #if os(iOS)
                let resolveOptions: URL.BookmarkResolutionOptions = .withoutUI
                #elseif os(macOS)
                let resolveOptions: URL.BookmarkResolutionOptions = [.withoutUI, .withSecurityScope]
                #endif

                let resolvedURL = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: resolveOptions,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                if isStale {
                    #if os(iOS)
                    let bookmarkOptions: URL.BookmarkCreationOptions = []
                    #elseif os(macOS)
                    let bookmarkOptions: URL.BookmarkCreationOptions = .withSecurityScope
                    #endif
                    if let freshBookmark = try? resolvedURL.bookmarkData(
                        options: bookmarkOptions,
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
        let legacyCatURL = folder.appendingPathComponent(legacyCategoriesFileName)
        if !FileManager.default.fileExists(atPath: catURL.path) {
            if FileManager.default.fileExists(atPath: legacyCatURL.path) {
                try? FileManager.default.moveItem(at: legacyCatURL, to: catURL)
            } else {
                let defaults = FinancialCategory.defaultCategories
                if let data = try? Self.categoriesEncoder.encode(defaults) {
                    try? data.write(to: catURL, options: .atomic)
                }
            }
        }

        // Auto-sync any categories found in the records to categories.json
        if let existingRecords = try? fetchRecords() {
            _ = try? syncCategoriesWithRecords(existingRecords)
        }
    }

    // MARK: - Records CRUD

    public func fetchRecords() throws -> [FinancialRecord] {
        guard let fileURL = getDatabaseFileURL(), let folderURL = getStorageFolderURL() else {
            return []
        }

        let didStart = startAccessIfNeeded(for: folderURL)
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let records = try Self.recordsDecoder.decode([FinancialRecord].self, from: data)
        return records
    }

    public func saveAllRecords(_ records: [FinancialRecord]) throws {
        guard let fileURL = getDatabaseFileURL(), let folderURL = getStorageFolderURL() else {
            throw NSError(domain: "LocalStorageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No se encontró la carpeta de destino."])
        }

        let didStart = startAccessIfNeeded(for: folderURL)
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        try writeRecords(records, to: fileURL)
    }

    public func createRecord(name: String, cantidad: Double, categoria: String, tipo: TransactionType, fecha: Date) throws -> FinancialRecord {
        ensureCategoryExists(named: categoria)
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
        ensureCategoryExists(named: updated.categoria)
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
        _ = try? syncCategoriesWithRecords(sample)
    }

    // MARK: - Category Sync with Records

    @discardableResult
    public func syncCategoriesWithRecords(_ records: [FinancialRecord]) throws -> [CategoryItem] {
        var currentCategories = (try? fetchCategories()) ?? FinancialCategory.defaultCategories
        let existingNames = Set(currentCategories.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        var newItems: [CategoryItem] = []
        var addedNames = Set<String>()

        for record in records {
            let trimmed = record.categoria.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let lower = trimmed.lowercased()
            if !existingNames.contains(lower) && !addedNames.contains(lower) {
                addedNames.insert(lower)
                let hex = FinancialCategory.defaultColorHex(for: trimmed)
                newItems.append(CategoryItem(name: trimmed, hexColor: hex))
            }
        }

        if !newItems.isEmpty {
            currentCategories.append(contentsOf: newItems)
            currentCategories.sort(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
            try saveCategories(currentCategories)
        }

        return currentCategories
    }

    public func ensureCategoryExists(named categoryName: String) {
        let trimmed = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard var currentCategories = try? fetchCategories() else { return }
        if !currentCategories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            let hex = FinancialCategory.defaultColorHex(for: trimmed)
            currentCategories.append(CategoryItem(name: trimmed, hexColor: hex))
            currentCategories.sort(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
            try? saveCategories(currentCategories)
        }
    }

    // MARK: - Categories CRUD

    public func fetchCategories() throws -> [CategoryItem] {
        guard let fileURL = getCategoriesFileURL(), let folderURL = getStorageFolderURL() else {
            return FinancialCategory.defaultCategories
        }

        let didStart = startAccessIfNeeded(for: folderURL)
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let legacyCatURL = folderURL.appendingPathComponent(legacyCategoriesFileName)
            if FileManager.default.fileExists(atPath: legacyCatURL.path) {
                try? FileManager.default.moveItem(at: legacyCatURL, to: fileURL)
            }
        }

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let defaults = FinancialCategory.defaultCategories
            try? saveCategories(defaults)
            return defaults
        }

        let data = try Data(contentsOf: fileURL)
        let items = try Self.categoriesDecoder.decode([CategoryItem].self, from: data)
        CategoryRegistry.shared.register(categories: items)
        return items
    }

    public func saveCategories(_ categories: [CategoryItem]) throws {
        guard let fileURL = getCategoriesFileURL(), let folderURL = getStorageFolderURL() else {
            throw NSError(domain: "LocalStorageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No se encontró la carpeta de destino."])
        }

        let didStart = startAccessIfNeeded(for: folderURL)
        defer {
            if didStart {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Self.categoriesEncoder.encode(categories)
        try data.write(to: fileURL, options: .atomic)

        CategoryRegistry.shared.reset(to: categories)
    }

    // MARK: - Metadata

    public func getMetadata(knownRecordCount: Int? = nil) -> FileStorageMetadata {
        guard let fileURL = getDatabaseFileURL(), let folderURL = getStorageFolderURL() else {
            return FileStorageMetadata(exists: false, lastModified: nil, sizeInBytes: 0, recordCount: 0, fileName: fileName)
        }

        let didStart = startAccessIfNeeded(for: folderURL)
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
        var count = knownRecordCount ?? 0

        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            fileSize = (attrs[.size] as? NSNumber)?.int64Value ?? 0
            modDate = attrs[.modificationDate] as? Date
        }

        if knownRecordCount == nil, let data = try? Data(contentsOf: fileURL) {
            if let records = try? Self.recordsDecoder.decode([FinancialRecord].self, from: data) {
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
        let data = try Self.recordsEncoder.encode(records)
        try data.write(to: url, options: .atomic)
    }
}
