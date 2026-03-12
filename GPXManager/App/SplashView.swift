import SwiftUI

struct SplashView: View {
    @State private var opacity = 0.0
    @State private var scale = 1.0
    @State private var isFinished = false

    var body: some View {
        if isFinished {
            ContentView()
        } else {
            splash
        }
    }

    private var splash: some View {
        ZStack {
            // Background — matches logo
            Color(red: 0.059, green: 0.106, blue: 0.176)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.059, green: 0.106, blue: 0.176),
                                    Color(red: 0.102, green: 0.180, blue: 0.271)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .teal.opacity(0.4), radius: 20, y: 8)

                    // Grid lines
                    Canvas { context, size in
                        let lines: [(CGPoint, CGPoint)] = [
                            (CGPoint(x: size.width / 2, y: 0), CGPoint(x: size.width / 2, y: size.height)),
                            (CGPoint(x: 0, y: size.height / 2), CGPoint(x: size.width, y: size.height / 2))
                        ]
                        for (start, end) in lines {
                            var path = Path()
                            path.move(to: start)
                            path.addLine(to: end)
                            context.stroke(path, with: .color(.teal.opacity(0.08)), lineWidth: 1)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    // Route dashed line
                    Canvas { context, size in
                        var path = Path()
                        path.move(to: CGPoint(x: 28, y: 38))
                        path.addCurve(
                            to: CGPoint(x: 72, y: 38),
                            control1: CGPoint(x: 38, y: 62),
                            control2: CGPoint(x: 62, y: 62)
                        )
                        context.stroke(
                            path,
                            with: .color(.teal.opacity(0.7)),
                            style: StrokeStyle(lineWidth: 2.5, dash: [5, 4], dashPhase: 0)
                        )
                    }
                    .frame(width: 100, height: 100)

                    // Pin A — left
                    PinShape()
                        .fill(Color.teal.opacity(0.6))
                        .frame(width: 14, height: 18)
                        .offset(x: -22, y: -12)

                    // Pin B — center (main, larger)
                    PinShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.243, green: 1.0, blue: 0.839), Color(red: 0, green: 0.761, blue: 0.659)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 20, height: 26)
                        .offset(x: 0, y: 6)
                        .shadow(color: .teal.opacity(0.5), radius: 6)

                    // Pin C — right
                    PinShape()
                        .fill(Color.teal.opacity(0.6))
                        .frame(width: 14, height: 18)
                        .offset(x: 22, y: -12)
                }
                .frame(width: 100, height: 100)

                // App name
                VStack(spacing: 4) {
                    Text("GPX Manager")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Location Testing Tool")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // Fade in
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 1.0
                }

                // After a short hold, scale up and fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(.easeIn(duration: 0.4)) {
                        scale = 1.15
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isFinished = true
                    }
                }
            }
        }
    }
}

// MARK: - PinShape

private struct PinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r = w / 2

        path.addArc(
            center: CGPoint(x: w / 2, y: r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: w / 2, y: h))
        path.addLine(to: CGPoint(x: 0, y: r))
        path.closeSubpath()
        return path
    }
}
