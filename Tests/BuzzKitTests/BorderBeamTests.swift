import SwiftUI
import Testing

@testable import BorderBeamKit

struct BorderBeamTests {
    @Test
    func everySizeMapsToAValidGeometry() {
        for size in BorderBeamSize.allCases {
            #expect(size.lineWidth > 0)
            #expect(size.glowRadius >= 0)
            #expect(size.tailFraction > 0 && size.tailFraction < 0.5)
        }
    }

    @Test
    func pulseSizesArePulses() {
        #expect(BorderBeamSize.pulseInner.isPulse)
        #expect(BorderBeamSize.pulseOutside.isPulse)
        #expect(!BorderBeamSize.md.isPulse)
        #expect(!BorderBeamSize.sm.isPulse)
        #expect(!BorderBeamSize.line.isPulse)
    }

    @Test
    func arcStopsAreMonotonicAndHeadStraddlesTheWrap() {
        let colors: [Color] = [.teal, .blue]
        let stops = BeamStops.arc(colors: colors, head: .white, tailFraction: 0.26)
        #expect(stops.count == 8)
        for (a, b) in zip(stops, stops.dropFirst()) {
            #expect(a.location < b.location)
        }
        #expect(stops.first?.location == 0)
        #expect(stops.last?.location == 1)
    }

    @Test
    func singleTailColorStillProducesAFullArc() {
        let stops = BeamStops.arc(colors: [.accentColor], head: .white, tailFraction: 0.2)
        #expect(stops.count == 8)
        for (a, b) in zip(stops, stops.dropFirst()) {
            #expect(a.location < b.location)
        }
    }

    @Test
    func pulseGradientLoopsWithoutASeam() {
        let loop = BeamStops.pulse(colors: [.orange, .pink], head: .white)
        #expect(loop.first == loop.last)
        #expect(loop.count == 4)
    }

    @Test
    func directionSigns() {
        #expect(BorderBeamDirection.clockwise.sign == 1)
        #expect(BorderBeamDirection.counterclockwise.sign == -1)
    }

    @Test
    func everyVariantHasTailColorsInBothThemes() {
        for variant in BorderBeamColorVariant.allCases {
            #expect(!variant.tailColors(theme: .dark).isEmpty)
            #expect(!variant.tailColors(theme: .light).isEmpty)
        }
    }
}
