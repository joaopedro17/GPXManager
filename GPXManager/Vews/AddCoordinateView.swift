import SwiftUI
import MapKit

// MARK: - AddCoordinateView

struct AddCoordinateView: View {
    @ObservedObject var store: CoordinateStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var latitudeText = ""
    @State private var longitudeText = ""
    @State private var group = "Ungrouped"
    @State private var newGroupName = ""
    @State private var isAddingGroup = false
    @State private var validationError: String?

    // Search
    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showResults = false
    @State private var suppressSearch = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(latitudeText) != nil &&
        Double(longitudeText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Address Search
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search address or place name", text: $searchQuery)
                            .autocorrectionDisabled()
                            .onChange(of: searchQuery) { _, newValue in
                                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                    searchResults = []
                                    showResults = false
                                }
                            }
                            .task(id: searchQuery) {
                                guard !suppressSearch else {
                                    suppressSearch = false
                                    return
                                }
                                let query = searchQuery.trimmingCharacters(in: .whitespaces)
                                guard !query.isEmpty else { return }
                                try? await Task.sleep(nanoseconds: 400_000_000)
                                guard !Task.isCancelled else { return }
                                await performSearch(query: query)
                            }
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                                searchResults = []
                                showResults = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Search")
                } footer: {
                    Text("Search for an address to auto-fill coordinates, or enter them manually below.")
                }

                // MARK: Search Results
                if showResults && !searchResults.isEmpty {
                    Section("Results") {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                applyResult(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name ?? "Unknown")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    let address = item.displayAddress
                                    if !address.isEmpty {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                // MARK: Group
                Section("Group") {
                    Picker("Group", selection: $group) {
                        ForEach(store.groups.isEmpty ? ["Ungrouped"] : store.groups, id: \.self) {
                            Text($0).tag($0)
                        }
                    }

                    if isAddingGroup {
                        HStack {
                            TextField("New group name", text: $newGroupName)
                                .autocorrectionDisabled()
                            Button("Add") {
                                let trimmed = newGroupName.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty {
                                    group = trimmed
                                    newGroupName = ""
                                    isAddingGroup = false
                                }
                            }
                            .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } else {
                        Button {
                            isAddingGroup = true
                        } label: {
                            Label("New Group", systemImage: "plus")
                                .font(.subheadline)
                        }
                    }
                }

                // MARK: Name
                Section("Location Name") {
                    TextField("e.g. Casino Main Entrance", text: $name)
                        .autocorrectionDisabled()
                }

                // MARK: Coordinates
                Section("Coordinates") {
                    HStack {
                        Text("Lat")
                            .foregroundStyle(.secondary)
                            .frame(width: 32, alignment: .leading)
                        TextField("e.g. 36.121230", text: $latitudeText)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Lng")
                            .foregroundStyle(.secondary)
                            .frame(width: 32, alignment: .leading)
                        TextField("e.g. -115.169500", text: $longitudeText)
                            .keyboardType(.decimalPad)
                    }
                }

                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Text("You can also get coordinates from Google Maps by long-pressing any location on the map.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Coordinate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { submit() }
                        .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: - Search

    @MainActor
    private func performSearch(query: String) async {
        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        let response = try? await MKLocalSearch(request: request).start()
        isSearching = false
        searchResults = response?.mapItems ?? []
        showResults = true
    }

    private func applyResult(_ item: MKMapItem) {
        let coord = item.location.coordinate
        latitudeText = String(format: "%.6f", coord.latitude)
        longitudeText = String(format: "%.6f", coord.longitude)

        name = item.name ?? item.displayAddress

        suppressSearch = true
        searchQuery = item.displayAddress.isEmpty ? (item.name ?? "") : item.displayAddress
        showResults = false
        searchResults = []
    }

    // MARK: - Submit

    private func submit() {
        guard let lat = Double(latitudeText), let lng = Double(longitudeText) else {
            validationError = "Please enter valid decimal coordinates."
            return
        }

        guard (-90...90).contains(lat) else {
            validationError = "Latitude must be between -90 and 90."
            return
        }

        guard (-180...180).contains(lng) else {
            validationError = "Longitude must be between -180 and 180."
            return
        }

        store.add(Coordinate(
            name: name.trimmingCharacters(in: .whitespaces),
            latitude: lat,
            longitude: lng,
            group: group.trimmingCharacters(in: .whitespaces)
        ))
        dismiss()
    }
}

// MARK: - MKMapItem extension

private extension MKMapItem {
    var displayAddress: String {
        address?.fullAddress ?? name ?? ""
    }
}
