import SwiftUI
import UniformTypeIdentifiers

public struct ConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject public var viewModel: FinancialViewModel
    @AppStorage("app_language") private var appLanguage: String = "es"

    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
    }

    private var currentLanguageDisplayName: String {
        switch appLanguage {
        case "en": return "English"
        default: return "Español"
        }
    }

    private var storageLocationDisplayName: String {
        if viewModel.isICloudStorage {
            return "iCloud Drive"
        } else if viewModel.isCustomFolderConfigured {
            return "Carpeta local"
        } else {
            return "Por defecto"
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Cabecera de la App
                    appBrandingHeader

                    // Menú de Ajustes agrupado en submenús
                    VStack(spacing: 0) {
                        // 1. Submenú Idioma
                        NavigationLink {
                            LanguageSettingsView()
                        } label: {
                            menuRow(
                                icon: "globe",
                                iconColor: .purple,
                                title: "Idioma",
                                value: currentLanguageDisplayName
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .background(Color.appBorder)
                            .padding(.leading, 64)

                        // 2. Submenú Categorías
                        NavigationLink {
                            CategoryManagementView(viewModel: viewModel)
                        } label: {
                            menuRow(
                                icon: "tag.fill",
                                iconColor: .green,
                                title: "Categorías",
                                value: "\(viewModel.categories.count) categorías"
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .background(Color.appBorder)
                            .padding(.leading, 64)

                        // 3. Submenú Almacenamiento de datos
                        NavigationLink {
                            DataStorageSettingsView(viewModel: viewModel)
                        } label: {
                            menuRow(
                                icon: viewModel.isICloudStorage ? "icloud.fill" : (viewModel.isCustomFolderConfigured ? "folder.fill" : "internaldrive.fill"),
                                iconColor: viewModel.statusBadgeColor,
                                title: "Almacenamiento de datos",
                                value: storageLocationDisplayName
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Ajustes")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    CircularDismissButton()
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    CircularDismissButton()
                }
                #endif
            }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
        #if os(macOS)
        .frame(minWidth: 440, idealWidth: 460, minHeight: 520)
        #endif
        .preferredColorScheme(.dark)
    }

    // MARK: - Menu Row Component

    private func menuRow(icon: String, iconColor: Color, title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Branding Header

    private var appBrandingHeader: some View {
        HStack(spacing: 14) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .padding(6)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("PMFinances")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Gestión y control de finanzas personales")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - 1. Submenú Idioma

public struct LanguageSettingsView: View {
    @AppStorage("app_language") private var appLanguage: String = "es"

    public init() {}

    private let languages: [(code: String, name: String, nativeName: String)] = [
        ("es", "Español", "Español"),
        ("en", "Inglés", "English")
    ]

    public var body: some View {
        List {
            Section {
                ForEach(languages, id: \.code) { lang in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appLanguage = lang.code
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)

                                if lang.name != lang.nativeName {
                                    Text(lang.nativeName)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if appLanguage == lang.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.green)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.appCardBackground)
                }
            } header: {
                Text("Idioma de la Aplicación")
            } footer: {
                Text("El cambio de idioma se aplica inmediatamente a toda la aplicación.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Idioma")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - 3. Submenú Almacenamiento de Datos

public struct DataStorageSettingsView: View {
    @ObservedObject public var viewModel: FinancialViewModel
    @State private var showFolderPicker: Bool = false

    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Estado actual del almacenamiento
                storageStatusCard

                // Configuración de ubicación
                folderConfigurationSection

                // Guía de sincronización con iCloud
                iCloudInstructionsSection

                // Opciones avanzadas de datos
                advancedSection
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("Almacenamiento de datos")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleFolderSelection(result: result)
        }
    }

    // MARK: - Subviews

    private var storageStatusCard: some View {
        let meta = viewModel.metadata

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isICloudStorage ? "icloud.fill" : (viewModel.isCustomFolderConfigured ? "folder.fill" : "internaldrive.fill"))
                    .font(.system(size: 28))
                    .foregroundStyle(viewModel.statusBadgeColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.isICloudStorage ? "Sincronizado con iCloud" : (viewModel.isCustomFolderConfigured ? "Carpeta Personalizada" : "Almacenamiento Local"))
                        .font(.system(size: 16, weight: .bold))

                    Text("Archivo: finanzas.json")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .background(Color.appBorder)

            VStack(spacing: 8) {
                infoRow(label: "Carpeta activa", value: viewModel.currentFolderDisplayName)
                infoRow(label: "Movimientos guardados", value: "\(meta.recordCount)")
                infoRow(label: "Tamaño del archivo", value: meta.formattedSize)
                infoRow(label: "Última modificación", value: meta.formattedDate)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(viewModel.statusBadgeColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var folderConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ubicación de los Datos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Button {
                showFolderPicker = true
            } label: {
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 16))
                    Text(viewModel.isCustomFolderConfigured ? "Cambiar Carpeta de Guardado" : "Seleccionar Carpeta (iCloud o Local)")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.appCardBackground)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if viewModel.isCustomFolderConfigured {
                Button(role: .destructive) {
                    Task {
                        await viewModel.resetToDefaultFolder()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                        Text("Restablecer a Carpeta Local de la App")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    private var iCloudInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "icloud")
                    .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1.0))
                Text("¿Cómo sincronizar con iCloud?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                instructionRow(
                    step: "1",
                    text: "Pulsa en 'Seleccionar Carpeta'."
                )
                instructionRow(
                    step: "2",
                    text: "En el explorador de archivos, ve a 'iCloud Drive'."
                )
                instructionRow(
                    step: "3",
                    text: "Crea una carpeta llamada 'Finanzas' (o elige una existente) y pulsa 'Abrir'."
                )
                instructionRow(
                    step: "4",
                    text: "El archivo 'finanzas.json' se sincronizará automáticamente entre tus dispositivos Apple."
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Opciones de Datos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await viewModel.loadDemoData()
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15))
                    Text("Cargar Datos de Demostración")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.appCardBackground)
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    await viewModel.loadData()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15))
                    Text("Recargar Datos del Archivo")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.appCardBackground)
                .foregroundStyle(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder
    private func instructionRow(step: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(step)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color(red: 0.2, green: 0.6, blue: 1.0), in: Circle())

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private func handleFolderSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            Task {
                await viewModel.selectStorageFolder(url: selectedURL)
            }
        case .failure(let error):
            print("Error selecting folder: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ConfigView(viewModel: FinancialViewModel())
}
