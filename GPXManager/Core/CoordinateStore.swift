import SwiftUI
import Combine

class CoordinateStore: ObservableObject {
    @Published var coordinates: [Coordinate] = []
    @Published var selectedIDs: Set<UUID> = []

    private let saveKey = "gpx_coordinates"

    init() { load() }

    // MARK: - Groups

    var groups: [String] {
        var seen = Set<String>()
        return coordinates.compactMap {
            seen.insert($0.group).inserted ? $0.group : nil
        }
    }

    func coordinates(in group: String) -> [Coordinate] {
        coordinates.filter { $0.group == group }
    }

    func renameGroup(_ old: String, to new: String) {
        let trimmed = new.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != old else { return }
        for i in coordinates.indices where coordinates[i].group == old {
            coordinates[i].group = trimmed
        }
        save()
    }

    func deleteGroup(_ group: String) {
        let ids = coordinates.filter { $0.group == group }.map { $0.id }
        coordinates.removeAll { $0.group == group }
        ids.forEach { selectedIDs.remove($0) }
        save()
    }

    // MARK: - CRUD

    func add(_ coordinate: Coordinate) {
        coordinates.append(coordinate)
        save()
    }

    func update(_ coordinate: Coordinate) {
        guard let index = coordinates.firstIndex(where: { $0.id == coordinate.id }) else { return }
        coordinates[index] = coordinate
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        coordinates.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func moveWithinGroup(_ group: String, from source: IndexSet, to destination: Int) {
        var groupCoords = coordinates.filter { $0.group == group }
        groupCoords.move(fromOffsets: source, toOffset: destination)

        var result: [Coordinate] = []
        var groupIterator = groupCoords.makeIterator()
        for coord in coordinates {
            if coord.group == group {
                if let next = groupIterator.next() {
                    result.append(next)
                }
            } else {
                result.append(coord)
            }
        }
        coordinates = result
        save()
    }

    func delete(at offsets: IndexSet) {
        let idsToRemove = offsets.map { coordinates[$0].id }
        coordinates.remove(atOffsets: offsets)
        idsToRemove.forEach { selectedIDs.remove($0) }
        save()
    }

    func delete(_ coordinate: Coordinate) {
        coordinates.removeAll { $0.id == coordinate.id }
        selectedIDs.remove(coordinate.id)
        save()
    }

    func deleteInGroup(_ group: String, at offsets: IndexSet) {
        let groupCoords = coordinates(in: group)
        let toDelete = offsets.map { groupCoords[$0] }
        toDelete.forEach { delete($0) }
    }

    // MARK: - Import

    func importCoordinates(_ imported: [Coordinate]) {
        coordinates.append(contentsOf: imported)
        save()
    }

    // MARK: - Selection

    func toggleSelection(_ coordinate: Coordinate) {
        if selectedIDs.contains(coordinate.id) {
            selectedIDs.remove(coordinate.id)
        } else {
            selectedIDs.insert(coordinate.id)
        }
    }

    func isSelected(_ coordinate: Coordinate) -> Bool {
        selectedIDs.contains(coordinate.id)
    }

    func toggleSelectAll() {
        if selectedIDs.count == coordinates.count {
            selectedIDs.removeAll()
        } else {
            selectedIDs = Set(coordinates.map { $0.id })
        }
    }

    func toggleSelectGroup(_ group: String) {
        let ids = Set(coordinates(in: group).map { $0.id })
        if ids.isSubset(of: selectedIDs) {
            selectedIDs.subtract(ids)
        } else {
            selectedIDs.formUnion(ids)
        }
    }

    func isGroupFullySelected(_ group: String) -> Bool {
        let ids = coordinates(in: group).map { $0.id }
        return !ids.isEmpty && ids.allSatisfy { selectedIDs.contains($0) }
    }

    // MARK: - Persistence

    private func save() {
        if let encoded = try? JSONEncoder().encode(coordinates) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Coordinate].self, from: data) else { return }
        coordinates = decoded
    }
}
