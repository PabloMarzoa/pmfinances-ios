import SwiftUI
import UniformTypeIdentifiers

public struct ConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject public var viewModel: FinancialViewModel
    @AppStorage("app_language") private var appLanguage: String = "es"

    @State private var showFolderPicker: Bool = false
    @State private var showCategoryManagement: Bool = false
    @State private var isReloading: Bool = false

    public init(viewModel: FinancialViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Cabecera de la App
                    appBrandingHeader

                    // Selección de Idioma
                    languageSection

                    // Estado actual del almacenamiento
                    storageStatusCard

                    // Gestión de Categorías
                    categoryManagementSection

                    // Acciones principales de configuración
                    folderConfigurationSection

                    // Explicación de sincronización iCloud
                    iCloudInstructionsSection

                    // Cargar datos de ejemplo / Restablecer
                    advancedSection
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Almacenamiento y Sincronización")
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
            .fileImporter(
                isPresented: $showFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                handleFolderSelection(result: result)
            }
            .sheet(isPresented: $showCategoryManagement) {
                CategoryManagementView(viewModel: viewModel)
            }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
        #if os(macOS)
        .frame(minWidth: 440, idealWidth: 460, minHeight: 520)
        #endif
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private var appBrandingHeader: some View {
        HStack(spacing: 14) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(6)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("PMFinances")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Gestión y control de finanzas personales")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.purple)

                Text("Idioma de la Aplicación")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Picker("Idioma", selection: $appLanguage) {
                Text("Español").tag("es")
                Text("English").tag("en")
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

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

    private var categoryManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categorías de Movimientos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Button {
                showCategoryManagement = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.green.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: "tag.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.green)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Gestionar Categorías")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("\(viewModel.categories.count) categorías configuradas")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
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
