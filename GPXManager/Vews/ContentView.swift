import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = CoordinateStore()
    @State private var showingAddSheet = false
    @State private var showingHelp = false
    @State private var showingImport = false
    @State private var exportError: String?
    @State private var showingExportError = false
    @State private var exportSuccess = false
    @State private var importSuccess = false
    @State private var lastImportCount = 0
    @State private var exportMode: GPXExportMode = .waypoints
    @State private var editMode: EditMode = .inactive
    @State private var coordinateToEdit: Coordinate?
    @State private var coordinateToMove: Coordinate?
    @State private var groupToDelete: String?
    @State private var groupToRename: String?
    @State private var renamingText: String = ""
    @State private var importError: String?
    @State private var showingImportError = false

    @State private var draggingID: UUID?
    private var isReordering: Bool { editMode == .active }

    private var deleteGroupMessage: String {
        guard let group = groupToDelete else { return "" }
        let count = store.coordinates(in: group).count
        return "This will permanently delete \(count) coordinate\(count == 1 ? "" : "s") in \"\(group)\"."
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.coordinates.isEmpty {
                    emptyState
                } else {
                    coordinateList
                }
            }
            .navigationTitle("GPX Manager")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !store.coordinates.isEmpty {
                        Button(isReordering ? "Done" : "Reorder") {
                            withAnimation { editMode = isReordering ? .inactive : .active }
                        }
                        .foregroundStyle(isReordering ? .blue : .secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Button { showingImport = true } label: {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Button { showingHelp = true } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        Button { showingAddSheet = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                if !store.selectedIDs.isEmpty && !isReordering {
                    ToolbarItem(placement: .bottomBar) {
                        exportControls
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCoordinateView(store: store)
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .sheet(item: $coordinateToEdit) { coord in
                EditCoordinateView(store: store, coordinate: coord)
            }
            .confirmationDialog(
                "Move to Group",
                isPresented: Binding(
                    get: { coordinateToMove != nil },
                    set: { if !$0 { coordinateToMove = nil } }
                ),
                titleVisibility: .visible
            ) {
                ForEach(store.groups.filter { $0 != coordinateToMove?.group }, id: \.self) { group in
                    Button(group) {
                        if var coord = coordinateToMove {
                            coord.group = group
                            store.update(coord)
                        }
                        coordinateToMove = nil
                    }
                }
                Button("Cancel", role: .cancel) { coordinateToMove = nil }
            }
            .alert("Delete Group", isPresented: Binding(
                get: { groupToDelete != nil },
                set: { if !$0 { groupToDelete = nil } }
            )) {
                Button("Delete All Coordinates", role: .destructive) {
                    if let group = groupToDelete { store.deleteGroup(group) }
                    groupToDelete = nil
                }
                Button("Cancel", role: .cancel) { groupToDelete = nil }
            } message: {
                Text(deleteGroupMessage)
            }
            .fileImporter(
                isPresented: $showingImport,
                allowedContentTypes: [.init(filenameExtension: "gpx")!],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Export Failed", isPresented: $showingExportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "Unknown error.")
            }
            .alert("Import Failed", isPresented: $showingImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "Unknown error.")
            }
            .overlay {
                VStack {
                    if exportSuccess { exportSuccessBanner }
                    if importSuccess { importSuccessBanner }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("No Coordinates")
                .font(.title2.bold())
            Text("Tap + to add your first location, or import a GPX file.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Button { showingImport = true } label: {
                    Label("Import GPX", systemImage: "square.and.arrow.down")
                        .font(.subheadline)
                }
                Button { showingHelp = true } label: {
                    Label("How to use", systemImage: "questionmark.circle")
                        .font(.subheadline)
                }
            }
            .padding(.top, 4)
        }
        .padding()
    }

    // MARK: - Coordinate List

    private var coordinateList: some View {
        List {
            ForEach(store.groups, id: \.self) { group in
                Section {
                    ForEach(store.coordinates(in: group)) { coordinate in
                        CoordinateRow(
                            coordinate: coordinate,
                            store: store,
                            isReordering: isReordering,
                            onEdit: { coordinateToEdit = coordinate }
                        )
                        .onDrag {
                            draggingID = coordinate.id
                            return NSItemProvider(object: coordinate.id.uuidString as NSString)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                coordinateToEdit = coordinate
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)

                            if store.groups.count > 1 {
                                Button {
                                    coordinateToMove = coordinate
                                } label: {
                                    Label("Move", systemImage: "folder")
                                }
                                .tint(.orange)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.delete(coordinate)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { from, to in
                        store.moveWithinGroup(group, from: from, to: to)
                    }
                } header: {
                    HStack(spacing: 8) {
                        if groupToRename == group {
                            // Inline rename field
                            TextField("Group name", text: $renamingText)
                                .font(.caption.weight(.semibold))
                                .textCase(.none)
                                .autocorrectionDisabled()
                                .onSubmit { commitRename(from: group) }

                            Button {
                                commitRename(from: group)
                            } label: {
                                Text("Done")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                            .textCase(.none)

                            Button {
                                groupToRename = nil
                                renamingText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .textCase(.none)
                        } else {
                            Text(group)
                                .textCase(.uppercase)
                                .font(.caption.weight(.semibold))

                            Spacer()

                            if !isReordering {
                                HStack(spacing: 12) {
                                    Button(store.isGroupFullySelected(group) ? "Deselect" : "Select") {
                                        store.toggleSelectGroup(group)
                                    }
                                    .font(.caption)
                                    .textCase(.none)

                                    Button {
                                        renamingText = group
                                        groupToRename = group
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .textCase(.none)

                                    Button {
                                        groupToDelete = group
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundStyle(.red.opacity(0.7))
                                    }
                                    .textCase(.none)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        providers.first?.loadItem(forTypeIdentifier: "public.text") { item, _ in
                            guard let data = item as? Data,
                                  let uuidString = String(data: data, encoding: .utf8),
                                  let id = UUID(uuidString: uuidString) else { return }
                            DispatchQueue.main.async {
                                if var coord = store.coordinates.first(where: { $0.id == id }),
                                   coord.group != group {
                                    coord.group = group
                                    store.update(coord)
                                }
                                draggingID = nil
                            }
                        }
                        return true
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
    }

    // MARK: - Group Rename

    private func commitRename(from oldName: String) {
        let trimmed = renamingText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed != oldName {
            store.renameGroup(oldName, to: trimmed)
        }
        groupToRename = nil
        renamingText = ""
    }

    // MARK: - Export Controls

    private var exportControls: some View {
        VStack(spacing: 10) {
            Picker("Export Mode", selection: $exportMode) {
                Label("Waypoints", systemImage: "mappin").tag(GPXExportMode.waypoints)
                Label("Route", systemImage: "point.topleft.down.to.point.bottomright.curvepath").tag(GPXExportMode.route)
            }
            .pickerStyle(.segmented)

            Button { exportGPX() } label: {
                Label(exportLabel, systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var exportLabel: String {
        let count = store.selectedIDs.count
        switch exportMode {
        case .waypoints: return "Export Waypoints (\(count))"
        case .route:     return "Export Route (\(count) stops)"
        }
    }

    // MARK: - Banners

    private var exportSuccessBanner: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("GPX saved to Files").fontWeight(.medium)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 120)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { exportSuccess = false }
            }
        }
    }

    private var importSuccessBanner: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.teal)
                Text("Imported \(lastImportCount) coordinate\(lastImportCount == 1 ? "" : "s")").fontWeight(.medium)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 120)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { importSuccess = false }
            }
        }
    }

    // MARK: - Export

    private func exportGPX() {
        let selected = store.coordinates.filter { store.selectedIDs.contains($0.id) }
        guard !selected.isEmpty else { return }

        let gpx = GPXGenerator.generate(from: selected, mode: exportMode)
        let prefix = exportMode == .route ? "route" : "waypoints"
        let fileName = "\(prefix)_\(Int(Date().timeIntervalSince1970)).gpx"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try gpx.write(to: tempURL, atomically: true, encoding: .utf8)
            saveToFiles(url: tempURL)
        } catch {
            exportError = error.localizedDescription
            showingExportError = true
        }
    }

    private func saveToFiles(url: URL) {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        picker.shouldShowFileExtensions = true
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(picker, animated: true)
        }
        withAnimation { exportSuccess = true }
    }

    // MARK: - Import

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
            showingImportError = true
        case .success(let urls):
            guard let url = urls.first else { return }
            let fileName = url.deletingPathExtension().lastPathComponent
            let parsed = GPXImporter.parse(url: url, defaultGroup: fileName)
            guard !parsed.coordinates.isEmpty else {
                importError = "No valid waypoints found in this GPX file."
                showingImportError = true
                return
            }
            store.importCoordinates(parsed.coordinates)
            lastImportCount = parsed.coordinates.count
            withAnimation { importSuccess = true }
        }
    }
}
