import SwiftUI

/// How the beam renders on the border.
public enum BorderBeamSize: String, Sendable, CaseIterable, Equatable {
    /// A medium beam with a soft glow.
    case md
    /// A smaller, subtler beam.
    case sm
    /// A crisp hairline beam with no glow.
    case line
    /// A glow that breathes on the inside edge of the border instead of traveling.
    case pulseInner = "pulse-inner"
    /// A glow that breathes around the outside of the border instead of traveling.
    case pulseOutside = "pulse-outside"

    var isPulse: Bool { self == .pulseInner || self == .pulseOutside }

    var lineWidth: CGFloat {
        switch self {
        case .md: return 2.5
        case .sm: return 1.75
        case .line: return 1
        case .pulseInner: return 2.5
        case .pulseOutside: return 3
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .md: return 7
        case .sm: return 4
        case .line: return 0
        case .pulseInner: return 5
        case .pulseOutside: return 10
        }
    }

    /// The fraction of the perimeter the lit arc covers (must stay under 0.5).
    var tailFraction: Double {
        switch self {
        case .md: return 0.26
        case .sm: return 0.22
        case .line: return 0.18
        case .pulseInner, .pulseOutside: return 0.26
        }
    }
}

/// The beam's palette.
public enum BorderBeamColorVariant: String, Sendable, CaseIterable, Equatable {
    /// Rainbow hues with a white head.
    case colorful
    /// White on dark themes, near-black on light themes.
    case mono
    /// Teals and blues.
    case ocean
    /// Oranges, pinks and violets.
    case sunset
    /// The view's accent color.
    case accent

    func headColor(theme: BorderBeamTheme) -> Color {
        switch self {
        case .mono:
            return theme == .dark ? .white : Color(white: 0.15)
        default:
            return .white
        }
    }

    func tailColors(theme: BorderBeamTheme) -> [Color] {
        switch self {
        case .colorful:
            return [
                Color(red: 0.35, green: 0.8, blue: 1.0),
                Color(red: 0.7, green: 0.45, blue: 1.0),
            ]
        case .mono:
            return theme == .dark
                ? [.white.opacity(0.85), .white.opacity(0.55)]
                : [Color(white: 0.2).opacity(0.85), Color(white: 0.35).opacity(0.55)]
        case .ocean:
            return [.teal, .blue]
        case .sunset:
            return [.orange, .pink]
        case .accent:
            return [.accentColor]
        }
    }
}

/// Whether the beam renders for a light or dark interface. `nil` follows `colorScheme`.
public enum BorderBeamTheme: String, Sendable, Equatable {
    case light
    case dark
}

/// Which way the beam travels around the border.
public enum BorderBeamDirection: String, Sendable, Equatable {
    case clockwise
    case counterclockwise

    var sign: Double { self == .clockwise ? 1 : -1 }
}

/// Gradient-stop construction, extracted so tests can pin the beam geometry.
enum BeamStops {
    /// A beam straddles the gradient's wrap point: a bright head at 0/1 fading through
    /// the variant's tail colors to transparent, symmetric on both sides.
    static func arc(colors: [Color], head: Color, tailFraction t: Double) -> [Gradient.Stop] {
        let c1 = colors.first ?? head
        let c2 = colors.count > 1 ? colors[1] : c1
        return [
            .init(color: head, location: 0),
            .init(color: c1, location: t * 0.35),
            .init(color: c2.opacity(0.55), location: t * 0.7),
            .init(color: c2.opacity(0), location: t),
            .init(color: c2.opacity(0), location: 1 - t),
            .init(color: c2.opacity(0.55), location: 1 - t * 0.7),
            .init(color: c1, location: 1 - t * 0.35),
            .init(color: head, location: 1),
        ]
    }

    /// A closed color loop for the pulse variants — first and last match so the
    /// angular gradient wraps without a seam.
    static func pulse(colors: [Color], head: Color) -> [Color] {
        let c1 = colors.first ?? head
        let c2 = colors.count > 1 ? colors[1] : c1
        return [c1, head, c2, c1]
    }
}
