import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = FinancialViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Storage Folder Banner (if default local)
                        if !viewModel.isCustomFolderConfigured {
                            folderSelectionBanner
                        }

                        // Error Banner
                        if let error = viewModel.errorMessage {
                            errorBanner(error)
                        }

                        // KPI Cards
                        KPICardsView(stats: viewModel.stats)

                        // Charts & Visualizations
                        ChartsView(
                            stats: viewModel.stats,
                            selectedCategories: viewModel.selectedCategories,
                            onCategoryTapped: { cat in
                                viewModel.toggleCategory(cat)
                            }
                        )

                        // Filters Bar
                        FiltersBarView(viewModel: viewModel)

                        // Transactions List Section
                        transactionsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 80) // Spacing for floating button
                }
                .background(Color.appBackground)
                .refreshable {
                    await viewModel.loadData()
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewModel.showCreateModal = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Nuevo Movimiento")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                    }
                }

                // Toast Notification
                if viewModel.showSuccessToast {
                    VStack {
                        Spacer()
                        Text(viewModel.toastMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.85))
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                            .padding(.bottom, 75)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.easeInOut, value: viewModel.showSuccessToast)
                }
            }
            .navigationTitle("Control de Finanzas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    statusBadgeButton
                }
                .sharedBackgroundVisibility(.hidden)
                .contentMarginsRemoved()
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Control de Finanzas")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    toolbarActionButtons
                }
                #else
                ToolbarItem(placement: .navigation) {
                    statusBadgeButton
                }
                .sharedBackgroundVisibility(.hidden)
                .contentMarginsRemoved()
                ToolbarItemGroup(placement: .primaryAction) {
                    toolbarActionButtons
                }
                #endif
            }
            .sheet(isPresented: $viewModel.showCreateModal) {
                CreateRecordView(viewModel: viewModel)
            }
            .sheet(item: $viewModel.selectedRecordForEdit) { record in
                EditRecordView(viewModel: viewModel, record: record)
            }
            .sheet(isPresented: $viewModel.showConfigModal) {
                ConfigView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var statusBadgeButton: some View {
        Button {
            viewModel.showConfigModal = true
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(viewModel.statusBadgeColor)
                    .frame(width: 7, height: 7)

                Text(viewModel.statusBadgeTitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(viewModel.statusBadgeColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(viewModel.statusBadgeColor.opacity(0.18))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(viewModel.statusBadgeColor.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    @ViewBuilder
    private var toolbarActionButtons: some View {
        // Export CSV
        ShareLink(
            item: viewModel.generateCsvContent(),
            preview: SharePreview("finanzas_export.csv", image: Image(systemName: "tablecells"))
        ) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14))
        }

        // Settings
        Button {
            viewModel.showConfigModal = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 14))
        }
    }

    // MARK: - Banner Components

    private var folderSelectionBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1.0))

            VStack(alignment: .leading, spacing: 2) {
                Text("Sincronización iCloud disponible")
                    .font(.system(size: 13, weight: .bold))
                Text("Elige una carpeta en iCloud Drive para mantener tus datos sincronizados.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Elegir") {
                viewModel.showConfigModal = true
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.2, green: 0.6, blue: 1.0))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.3), lineWidth: 1)
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.red)
                .lineLimit(2)

            Spacer()

            Button("Reintentar") {
                Task {
                    await viewModel.loadData()
                }
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.red)
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Transactions Section

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Movimientos")
                    .font(.system(size: 17, weight: .bold))

                Spacer()

                Text("\(viewModel.filteredRecords.count) registrados")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if viewModel.filteredRecords.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Text("No se encontraron movimientos")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Prueba a ajustar o borrar los filtros aplicados.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    if viewModel.hasActiveFilters {
                        Button("Restablecer Filtros") {
                            viewModel.clearFilters()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.top, 4)
                        .foregroundStyle(.green)
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredRecords) { record in
                        Button {
                            viewModel.selectedRecordForEdit = record
                        } label: {
                            TransactionRowView(record: record)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.appCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.appBorder, lineWidth: 0.8)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                viewModel.selectedRecordForEdit = record
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteRecord(id: record.id)
                                }
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
