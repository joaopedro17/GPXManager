import SwiftUI

// MARK: - Models

private struct HelpSection: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let steps: [HelpStep]
}

private struct HelpStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let detail: String
    let tip: String?
    let code: String?

    init(number: Int, title: String, detail: String, tip: String? = nil, code: String? = nil) {
        self.number = number
        self.title = title
        self.detail = detail
        self.tip = tip
        self.code = code
    }
}

// MARK: - HelpView

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let sections: [HelpSection] = [
        HelpSection(
            icon: "mappin.and.ellipse",
            iconColor: .teal,
            title: "What is a GPX File?",
            steps: [
                HelpStep(number: 1, title: "A GPX file is a standard GPS format", detail: "It stores coordinates (latitude and longitude) that tools like Xcode can read to simulate device location.", tip: nil),
                HelpStep(number: 2, title: "Two export modes", detail: "Waypoints are static named pins — the device jumps to each one. A Route is a track Xcode animates through in sequence, simulating movement.", tip: "Use Waypoints to test individual geofence triggers. Use Route to simulate a user physically traveling between zones.")
            ]
        ),
        HelpSection(
            icon: "square.and.arrow.down",
            iconColor: .blue,
            title: "Using a GPX File in Xcode",
            steps: [
                HelpStep(number: 1, title: "Export from this app", detail: "Select one or more coordinates, choose Waypoints or Route, then tap Export. Save the .gpx file to iCloud Drive for easy Mac access.", tip: nil),
                HelpStep(number: 2, title: "Add to your Xcode project", detail: "Drag the .gpx file into your Xcode project navigator. When prompted, tick \"Copy items if needed\" and select your target.", tip: nil),
                HelpStep(number: 3, title: "Configure your scheme", detail: "Go to Product → Scheme → Edit Scheme → Run → Options. Under Core Location, set Default Location to your .gpx file.", tip: nil),
                HelpStep(number: 4, title: "Build and debug", detail: "Run your app in debug mode. The device location will be set to the coordinates in your GPX file from the moment the app launches.", tip: "You must run via Xcode in debug mode — location simulation is not available in release builds or TestFlight.")
            ]
        ),
        HelpSection(
            icon: "point.topleft.down.to.point.bottomright.curvepath",
            iconColor: .mint,
            title: "Creating a Route",
            steps: [
                HelpStep(number: 1, title: "Add all your stops", detail: "Tap + and add each coordinate you want in the route. Give them clear names like \"Entrance\", \"Zone A\", \"Exit\" to stay organized.", tip: nil),
                HelpStep(number: 2, title: "Reorder to set the sequence", detail: "Tap Reorder in the top-left, then drag coordinates into the order you want Xcode to animate through them.", tip: "The top of the list = first stop. Xcode follows the sequence exactly as shown."),
                HelpStep(number: 3, title: "Select your stops", detail: "Tap Done to exit reorder mode, then tap each coordinate you want included. Use Select All to include everything.", tip: nil),
                HelpStep(number: 4, title: "Export as Route", detail: "Switch the picker to Route and tap Export. The .gpx will contain a track segment Xcode uses to animate the simulated location.", tip: nil),
                HelpStep(number: 5, title: "Watch it run in Xcode", detail: "With the route GPX configured in your scheme, Xcode will move the simulated location through each stop while your app is running in debug.", tip: "The animation speed is fixed by Xcode — it moves at a consistent pace between each coordinate pair.")
            ]
        ),
        HelpSection(
            icon: "hammer.fill",
            iconColor: .orange,
            title: "Setting Up the Target App",
            steps: [
                HelpStep(
                    number: 1,
                    title: "Create a new Xcode project",
                    detail: "Open Xcode → New Project → iOS → App. Give it any name (e.g. \"LocationTester\"). SwiftUI interface, Swift language. This will be your dedicated debug host for GPX testing.",
                    tip: "Keep this project separate from your production app. Its only job is to load your location logic and respond to the simulated GPX coordinates."
                ),
                HelpStep(
                    number: 2,
                    title: "Add the GPX file to this project",
                    detail: "Export a GPX from GPX Manager, then drag it into the Xcode project navigator of your target app. Tick \"Copy items if needed\" and make sure your target is checked.",
                    tip: nil
                ),
                HelpStep(
                    number: 3,
                    title: "Configure the scheme to use the GPX",
                    detail: "Go to Product → Scheme → Edit Scheme → Run → Options. Set Default Location to your .gpx file. The simulated location will be active as soon as the app launches in debug.",
                    tip: nil
                ),
                HelpStep(
                    number: 4,
                    title: "Build, run, and verify",
                    detail: "Run on your real device via Xcode. The device location will immediately reflect your GPX coordinates.",
                    tip: "You must run via Xcode in debug mode — location simulation is not available in release builds or TestFlight."
                ),
                HelpStep(
                    number: 5,
                    title: "Swapping the GPX file",
                    detail: "To test a different set of coordinates, export a new GPX from GPX Manager, drag it into the project replacing the old one, update the scheme's Default Location if the filename changed, and rebuild.",
                    tip: "If you keep the same filename (e.g. always export as \"test.gpx\"), you can overwrite it in the project without touching the scheme — just clean and rebuild."
                )
            ]
        ),
        HelpSection(
            icon: "lightbulb",
            iconColor: .yellow,
            title: "Tips & Gotchas",
            steps: [
                HelpStep(number: 1, title: "Get coordinates from Google Maps", detail: "Long-press any point on Google Maps — it shows the lat/lng at the bottom. Tap it to copy.", tip: nil),
                HelpStep(number: 2, title: "You can have multiple GPX files", detail: "Keep a file per test scenario — e.g. route_entrance_to_exit.gpx, waypoints_all_zones.gpx. Switch between them in your scheme as needed.", tip: nil),
                HelpStep(number: 3, title: "Simulator vs real device", detail: "Location simulation works on both, but always validate geofencing on a real device before sign-off — the Simulator handles region monitoring differently.", tip: nil),
                HelpStep(number: 4, title: "The GPX file must stay in the project", detail: "If you remove the .gpx from your Xcode project, the scheme location setting will silently fall back to none. Keep your files under version control.", tip: nil)
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerBanner
                    ForEach(sections) { section in
                        SectionCard(section: section)
                    }
                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "map.fill")
                .font(.system(size: 28))
                .foregroundStyle(.teal)
                .frame(width: 52, height: 52)
                .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text("GPX Manager Guide")
                    .font(.headline)
                Text("Learn how to export coordinates and simulate location in Xcode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 8)
    }

    // MARK: - Footer

    private var footerNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .font(.caption)
            Text("Location simulation requires building through Xcode in debug mode. It cannot be done from release or TestFlight builds.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - SectionCard

private struct SectionCard: View {
    let section: HelpSection
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(section.iconColor)
                        .frame(width: 34, height: 34)
                        .background(section.iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))

                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(section.steps) { step in
                        StepRow(step: step, accentColor: section.iconColor)
                        if step.id != section.steps.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - CodeBlock

private struct CodeBlock: View {
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Button {
                UIPasteboard.general.string = code
                withAnimation { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { copied = false }
                }
            } label: {
                Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(copied ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.systemFill), in: RoundedRectangle(cornerRadius: 10))
        .padding(.leading, 36)
    }
}

// MARK: - StepRow

private struct StepRow: View {
    let step: HelpStep
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(step.number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 24, height: 24)
                    .background(accentColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.subheadline.weight(.medium))
                    Text(step.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let code = step.code {
                CodeBlock(code: code)
            }

            if let tip = step.tip {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .padding(.top, 1)
                    Text(tip)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .padding(.leading, 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Preview

#Preview {
    HelpView()
}
