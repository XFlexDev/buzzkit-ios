import SwiftUI

/// An animated glow that rides the border of any view.
///
/// ```swift
/// BorderBeam(borderRadius: 16) {
///     Card()
/// }
/// ```
///
/// Or as a modifier on an existing view:
///
/// ```swift
/// Toggle("Reminders", isOn: $on)
///     .borderBeam(size: .sm, colorVariant: .ocean, isVisible: on)
/// ```
///
/// The beam is rendered as an overlay and never intercepts touches. When
/// `active` is `false` the animation freezes in place; `isVisible` fades the
/// whole effect — animate it from the call site to make the beam appear and
/// disappear with a transition. Reduce Motion pauses all movement.
public struct BorderBeam<Content: View>: View {
    private let overlay: BeamOverlay
    private let content: Content

    /// Creates a border beam around `content`.
    /// - Parameters:
    ///   - borderRadius: Corner radius of the border the beam rides.
    ///   - size: `.md`, `.sm`, `.line`, `.pulseInner` or `.pulseOutside`.
    ///   - colorVariant: `.colorful`, `.mono`, `.ocean`, `.sunset` or `.accent`.
    ///   - strength: Glow intensity, 0–1.
    ///   - active: Pauses the animation when `false`.
    ///   - theme: Forces a light or dark look; `nil` follows `colorScheme`.
    ///   - speed: Multiplier on the animation rate; 1 is one lap per `period`.
    ///   - beamCount: Number of evenly spaced beams traveling together (1–6).
    ///   - direction: `.clockwise` or `.counterclockwise`.
    ///   - period: Seconds per lap (and the breathing period of pulse variants).
    ///   - showsTrack: Draws a faint static ring under the traveling beam.
    ///   - cornerStyle: `.continuous` or `.circular` corners.
    ///   - isVisible: Fades the whole effect; animate it from the call site.
    ///   - content: The view the beam wraps.
    public init(
        borderRadius: CGFloat = 12,
        size: BorderBeamSize = .md,
        colorVariant: BorderBeamColorVariant = .colorful,
        strength: Double = 0.7,
        active: Bool = true,
        theme: BorderBeamTheme? = nil,
        speed: Double = 1,
        beamCount: Int = 1,
        direction: BorderBeamDirection = .clockwise,
        period: Double = 4,
        showsTrack: Bool = true,
        cornerStyle: RoundedCornerStyle = .continuous,
        isVisible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.overlay = BeamOverlay(
            borderRadius: borderRadius,
            size: size,
            colorVariant: colorVariant,
            strength: strength,
            active: active,
            theme: theme,
            speed: speed,
            beamCount: beamCount,
            direction: direction,
            period: period,
            showsTrack: showsTrack,
            cornerStyle: cornerStyle,
            isVisible: isVisible
        )
        self.content = content()
    }

    public var body: some View {
        content.overlay(overlay)
    }
}

extension View {
    /// Rides an animated glow around this view's border. See ``BorderBeam``.
    public func borderBeam(
        borderRadius: CGFloat = 12,
        size: BorderBeamSize = .md,
        colorVariant: BorderBeamColorVariant = .colorful,
        strength: Double = 0.7,
        active: Bool = true,
        theme: BorderBeamTheme? = nil,
        speed: Double = 1,
        beamCount: Int = 1,
        direction: BorderBeamDirection = .clockwise,
        period: Double = 4,
        showsTrack: Bool = true,
        cornerStyle: RoundedCornerStyle = .continuous,
        isVisible: Bool = true
    ) -> some View {
        overlay(
            BeamOverlay(
                borderRadius: borderRadius,
                size: size,
                colorVariant: colorVariant,
                strength: strength,
                active: active,
                theme: theme,
                speed: speed,
                beamCount: beamCount,
                direction: direction,
                period: period,
                showsTrack: showsTrack,
                cornerStyle: cornerStyle,
                isVisible: isVisible
            )
        )
    }
}

/// The overlay the public API renders. Carries the animation clock: time only
/// accumulates while `animating` is on, so pausing and resuming keeps the beam's
/// position instead of jumping.
struct BeamOverlay: View {
    var borderRadius: CGFloat = 12
    var size: BorderBeamSize = .md
    var colorVariant: BorderBeamColorVariant = .colorful
    var strength: Double = 0.7
    var active: Bool = true
    var theme: BorderBeamTheme?
    var speed: Double = 1
    var beamCount: Int = 1
    var direction: BorderBeamDirection = .clockwise
    var period: Double = 4
    var showsTrack: Bool = true
    var cornerStyle: RoundedCornerStyle = .continuous
    var isVisible: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Reference instant the running clock measures from.
    @State private var clockStart = Date()
    /// Time banked while paused, so resume continues from the same position.
    @State private var bankedTime: TimeInterval = 0

    private var animating: Bool { active && !reduceMotion }
    private var resolvedTheme: BorderBeamTheme {
        theme ?? (colorScheme == .dark ? .dark : .light)
    }
    private var clampedStrength: Double { min(1, max(0, strength)) }
    private var beams: Int { min(6, max(1, beamCount)) }
    private var lap: Double { max(0.5, period) }

    var body: some View {
        Group {
            if animating {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    layers(at: timeline.date)
                }
            } else {
                layers(at: clockStart)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(false)
        .onAppear { clockStart = Date() }
        .onChange(of: animating) { isAnimating in
            if isAnimating {
                clockStart = Date()
            } else {
                bankedTime += Date().timeIntervalSince(clockStart)
            }
        }
    }

    /// Seconds of animation time elapsed — frozen while paused.
    private func elapsed(at date: Date) -> TimeInterval {
        animating ? bankedTime + date.timeIntervalSince(clockStart) : bankedTime
    }

    private func angle(at date: Date) -> Double {
        direction.sign * elapsed(at: date) * 360 * speed / lap
    }

    /// 0…1 breathing phase shared by the pulse variants.
    private func breath(at date: Date) -> Double {
        (sin(2 * .pi * elapsed(at: date) * speed / lap) + 1) / 2
    }

    @ViewBuilder
    private func layers(at date: Date) -> some View {
        let shape = RoundedRectangle(cornerRadius: borderRadius, style: cornerStyle)
        if size.isPulse {
            pulseLayer(shape: shape, phase: breath(at: date))
        } else {
            ZStack {
                if showsTrack {
                    shape.strokeBorder(
                        Color.primary.opacity(resolvedTheme == .dark ? 0.14 : 0.1),
                        style: StrokeStyle(lineWidth: 1)
                    )
                }
                ForEach(0..<beams, id: \.self) { index in
                    beamArc(shape: shape, at: angle(at: date) + Double(index) * 360 / Double(beams))
                }
            }
        }
    }

    private func beamArc(shape: RoundedRectangle, at degrees: Double) -> some View {
        let gradient = AngularGradient(
            gradient: Gradient(
                stops: BeamStops.arc(
                    colors: colorVariant.tailColors(theme: resolvedTheme),
                    head: colorVariant.headColor(theme: resolvedTheme),
                    tailFraction: size.tailFraction
                )
            ),
            center: .center,
            angle: .degrees(degrees)
        )
        let style = StrokeStyle(lineWidth: size.lineWidth)
        return ZStack {
            if size.glowRadius > 0 {
                shape.strokeBorder(gradient, style: style)
                    .blur(radius: size.glowRadius * clampedStrength)
                    .opacity(0.8)
            }
            shape.strokeBorder(gradient, style: style)
        }
        .compositingGroup()
        .blendMode(resolvedTheme == .dark ? .plusLighter : .normal)
    }

    private func pulseLayer(shape: RoundedRectangle, phase: Double) -> some View {
        let ring = AngularGradient(
            gradient: Gradient(
                colors: BeamStops.pulse(
                    colors: colorVariant.tailColors(theme: resolvedTheme),
                    head: colorVariant.headColor(theme: resolvedTheme)
                )
            ),
            center: .center
        )
        let level = 0.35 + 0.65 * phase
        return ZStack {
            let style = StrokeStyle(lineWidth: size.lineWidth)
            if size == .pulseInner {
                shape.strokeBorder(ring, style: style)
                    .blur(radius: size.glowRadius * (0.4 + clampedStrength))
            } else {
                shape.stroke(ring, style: style)
                    .blur(radius: size.glowRadius * (0.4 + clampedStrength))
                    .padding(-(size.lineWidth + 2))
            }
        }
        .opacity(level * (0.45 + clampedStrength * 0.55))
        .blendMode(resolvedTheme == .dark ? .plusLighter : .normal)
    }
}

#if DEBUG
struct BorderBeam_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(BorderBeamColorVariant.allCases, id: \.self) { variant in
                    ForEach(BorderBeamSize.allCases, id: \.self) { size in
                        Text("\(variant.rawValue) · \(size.rawValue)")
                            .font(.caption)
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .background(
                                Color.secondary.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .borderBeam(
                                borderRadius: 14,
                                size: size,
                                colorVariant: variant
                            )
                    }
                }
            }
            .padding()
        }
    }
}
#endif
