import SwiftUI
import MapKit

struct EditCoordinateView: View {
    @ObservedObject var store: CoordinateStore
    let coordinate: Coordinate
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var latitudeText: String
    @State private var longitudeText: String
    @State private var group: String
    @State private var newGroupName = ""
    @State private var isAddingGroup = false
    @State private var validationError: String?

    init(store: CoordinateStore, coordinate: Coordinate) {
        self.store = store
        self.coordinate = coordinate
        _name = State(initialValue: coordinate.name)
        _latitudeText = State(initialValue: coordinate.latitudeString)
        _longitudeText = State(initialValue: coordinate.longitudeString)
        _group = State(initialValue: coordinate.group)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(latitudeText) != nil &&
        Double(longitudeText) != nil
    }

    private var allGroups: [String] {
        var groups = store.groups
        if !groups.contains(group) { groups.append(group) }
        return groups.sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location Name") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                }

                Section("Coordinates") {
                    HStack {
                        Text("Lat")
                            .foregroundStyle(.secondary)
                            .frame(width: 32, alignment: .leading)
                        TextField("Latitude", text: $latitudeText)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Lng")
                            .foregroundStyle(.secondary)
                            .frame(width: 32, alignment: .leading)
                        TextField("Longitude", text: $longitudeText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Group") {
                    Picker("Group", selection: $group) {
                        ForEach(allGroups, id: \.self) { Text($0).tag($0) }
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

                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Coordinate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { submit() }
                        .disabled(!isFormValid)
                }
            }
        }
    }

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

        var updated = coordinate
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.latitude = lat
        updated.longitude = lng
        updated.group = group.trimmingCharacters(in: .whitespaces)

        store.update(updated)
        dismiss()
    }
}
