import SwiftUI

struct CoordinateRow: View {
    let coordinate: Coordinate
    @ObservedObject var store: CoordinateStore
    var isReordering: Bool = false
    var onEdit: (() -> Void)? = nil

    var isSelected: Bool { store.isSelected(coordinate) }

    var body: some View {
        HStack(spacing: 14) {
            // Selection toggle
            if !isReordering {
                Button {
                    store.toggleSelection(coordinate)
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
                .buttonStyle(.plain)
            }

            // Coordinate info — tapping opens edit
            Button {
                if !isReordering { onEdit?() }
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(coordinate.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Text(coordinate.latitudeString)
                        Text("·")
                        Text(coordinate.longitudeString)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if !isReordering {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
    }
}
