//
//  MemphisIllustrations.swift
//  Encore
//

import SwiftUI

// MARK: - Router

struct MemphisInstrumentIllustration: View {
    let category: String?

    var body: some View {
        Group {
            switch category {
            case "string":     MemphisGuitarIllustration()
            case "keys":       MemphisPianoIllustration()
            case "percussion": MemphisDrumIllustration()
            case "brass":      MemphisBrassIllustration()
            default:           MemphisGenericMusicIllustration()
            }
        }
    }
}

// MARK: - Guitar (String)

struct MemphisGuitarIllustration: View {
    var body: some View {
        ZStack {
            // Memphis accent dot — top left
            Circle()
                .fill(Color.encorePink)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 14, height: 14)
                .offset(x: -46, y: -28)

            // Small white dot
            Circle()
                .fill(.white.opacity(0.55))
                .frame(width: 9, height: 9)
                .offset(x: 46, y: 30)

            // Guitar body — pill / capsule
            Capsule()
                .fill(Color.encoreAccent)
                .overlay(Capsule().stroke(.black, lineWidth: 2.5))
                .frame(width: 52, height: 70)

            // Soundhole
            Circle()
                .fill(.black)
                .frame(width: 18, height: 18)

            // Strings (4)
            Rectangle().fill(.black).frame(width: 1.5, height: 70).offset(x: -8)
            Rectangle().fill(.black).frame(width: 1.5, height: 70).offset(x: -3)
            Rectangle().fill(.black).frame(width: 1.5, height: 70).offset(x: 3)
            Rectangle().fill(.black).frame(width: 1.5, height: 70).offset(x: 8)

            // Neck
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.encoreOrange)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 2.5))
                .frame(width: 14, height: 44)
                .offset(y: -56)

            // Headstock
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.encoreOrange)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 2.5))
                .frame(width: 26, height: 18)
                .offset(y: -82)

            // Tuning pegs
            Circle()
                .fill(.white)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 7, height: 7)
                .offset(x: -14, y: -84)
            Circle()
                .fill(.white)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 7, height: 7)
                .offset(x: 14, y: -84)

            // Bridge rectangle
            RoundedRectangle(cornerRadius: 2)
                .fill(.black)
                .frame(width: 26, height: 5)
                .offset(y: 22)
        }
    }
}

// MARK: - Piano / Keys

struct MemphisPianoIllustration: View {
    var body: some View {
        ZStack {
            // Memphis accent dots
            Circle()
                .fill(Color.encorePink)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 14, height: 14)
                .offset(x: -50, y: -24)
            Circle()
                .fill(Color.encoreAccent)
                .frame(width: 9, height: 9)
                .offset(x: 50, y: 28)

            // White keys background
            RoundedRectangle(cornerRadius: 6)
                .fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 2.5))
                .frame(width: 90, height: 68)

            // Key dividers (vertical lines inside)
            ForEach([-27, -9, 9, 27], id: \.self) { x in
                Rectangle()
                    .fill(.black)
                    .frame(width: 2, height: 68)
                    .offset(x: CGFloat(x))
            }

            // Black keys (WBWBWWBWBWBW pattern — 3 of 5 keys have a black key)
            RoundedRectangle(cornerRadius: 3)
                .fill(.black)
                .frame(width: 14, height: 42)
                .offset(x: -27, y: -14)

            RoundedRectangle(cornerRadius: 3)
                .fill(.black)
                .frame(width: 14, height: 42)
                .offset(x: -9, y: -14)

            RoundedRectangle(cornerRadius: 3)
                .fill(.black)
                .frame(width: 14, height: 42)
                .offset(x: 18, y: -14)
        }
    }
}

// MARK: - Drums / Percussion

struct MemphisDrumIllustration: View {
    var body: some View {
        ZStack {
            // Memphis accent dot
            Circle()
                .fill(Color.encorePink)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 14, height: 14)
                .offset(x: -46, y: -16)

            // Right drumstick
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.encoreAccent)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 2))
                .frame(width: 8, height: 54)
                .rotationEffect(.degrees(30))
                .offset(x: 24, y: -44)

            // Left drumstick
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.encoreAccent)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 2))
                .frame(width: 8, height: 54)
                .rotationEffect(.degrees(-30))
                .offset(x: -24, y: -44)

            // Drum shell side
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.encoreCoral)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 2.5))
                .frame(width: 74, height: 46)

            // Drum head top ellipse
            Ellipse()
                .fill(Color(hex: "FDE8D8"))
                .overlay(Ellipse().stroke(.black, lineWidth: 2.5))
                .frame(width: 74, height: 26)
                .offset(y: -23)

            // Tension bolt dots
            ForEach([-22, 0, 22], id: \.self) { x in
                Circle()
                    .fill(.black)
                    .frame(width: 5, height: 5)
                    .offset(x: CGFloat(x), y: -23)
            }

            // Bottom rim
            Ellipse()
                .fill(.clear)
                .overlay(Ellipse().stroke(.black, lineWidth: 2.5))
                .frame(width: 74, height: 26)
                .offset(y: 23)
        }
    }
}

// MARK: - Brass

struct MemphisBrassIllustration: View {
    var body: some View {
        ZStack {
            // Memphis accent
            Circle()
                .fill(Color.encoreAccent)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 14, height: 14)
                .offset(x: 46, y: -30)

            // Bell (large circle representing the flare)
            Circle()
                .fill(Color.encoreTeal)
                .overlay(Circle().stroke(.black, lineWidth: 2.5))
                .frame(width: 52, height: 52)
                .offset(x: 20, y: 8)

            // Tube body
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.encoreTeal)
                .frame(width: 52, height: 14)
                .offset(x: -8, y: 8)

            // Tube top border
            Rectangle().fill(.black).frame(width: 52, height: 2).offset(x: -8, y: 1)
            // Tube bottom border
            Rectangle().fill(.black).frame(width: 52, height: 2).offset(x: -8, y: 15)

            // Valves (3 circles stacked)
            HStack(spacing: 7) {
                valveCircle
                valveCircle
                valveCircle
            }
            .offset(x: -10, y: -14)

            // Mouthpiece
            Capsule()
                .fill(Color.encoreTeal)
                .overlay(Capsule().stroke(.black, lineWidth: 2))
                .frame(width: 8, height: 24)
                .offset(x: -38, y: 8)

            // Small pink dot
            Circle()
                .fill(Color.encorePink.opacity(0.85))
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 10, height: 10)
                .offset(x: -44, y: -16)
        }
    }

    private var valveCircle: some View {
        Circle()
            .fill(Color.encoreAccent)
            .overlay(Circle().stroke(.black, lineWidth: 2))
            .frame(width: 18, height: 18)
    }
}

// MARK: - Generic music note

struct MemphisGenericMusicIllustration: View {
    var body: some View {
        ZStack {
            // Memphis accent dots
            Circle()
                .fill(Color.encorePink)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 14, height: 14)
                .offset(x: -44, y: -22)
            Circle()
                .fill(.white.opacity(0.5))
                .frame(width: 9, height: 9)
                .offset(x: 46, y: 28)

            // Note stem
            Rectangle()
                .fill(.black)
                .frame(width: 3, height: 56)
                .offset(x: 15, y: -16)

            // Note head
            Ellipse()
                .fill(Color.encoreAccent)
                .overlay(Ellipse().stroke(.black, lineWidth: 2.5))
                .frame(width: 36, height: 28)
                .rotationEffect(.degrees(-18))
                .offset(x: -3, y: 20)

            // Flag (upper)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.encoreAccent)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 2))
                .frame(width: 26, height: 11)
                .rotationEffect(.degrees(12))
                .offset(x: 28, y: -32)

            // Flag (lower)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.encoreAccent)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 2))
                .frame(width: 24, height: 9)
                .rotationEffect(.degrees(8))
                .offset(x: 27, y: -20)

            // Second note head (background)
            Ellipse()
                .fill(Color.encoreTeal.opacity(0.7))
                .overlay(Ellipse().stroke(.black, lineWidth: 2))
                .frame(width: 30, height: 22)
                .rotationEffect(.degrees(-18))
                .offset(x: 28, y: -4)
        }
    }
}

// MARK: - Reusable icon scene (Memphis circle + SF symbol + accent dots)

struct MemphisIconScene: View {
    let icon: String
    let circleColor: Color
    var accentColor: Color = Color.encoreAccent
    var secondAccent: Color = Color.encorePink

    var body: some View {
        ZStack {
            // Hard shadow
            Circle()
                .fill(.black)
                .frame(width: 88, height: 88)
                .offset(x: 4, y: 4)

            // Main filled circle
            Circle()
                .fill(circleColor)
                .overlay(Circle().stroke(.black, lineWidth: 2.5))
                .frame(width: 88, height: 88)

            // SF Symbol
            Image(systemName: icon)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            // Top-left accent
            Circle()
                .fill(accentColor)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 18, height: 18)
                .offset(x: -54, y: -30)

            // Top-right accent
            Circle()
                .fill(secondAccent)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 12, height: 12)
                .offset(x: 56, y: -22)

            // Small black dot
            Circle()
                .fill(.black)
                .frame(width: 7, height: 7)
                .offset(x: 42, y: 42)

            // Tiny white dot
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: 5, height: 5)
                .offset(x: -46, y: 36)
        }
        .frame(width: 130, height: 130)
    }
}

// MARK: - Reusable empty view (scene + title + subtitle)

struct MemphisEmptyView: View {
    let icon: String
    let circleColor: Color
    var accentColor: Color = Color.encoreAccent
    var secondAccent: Color = Color.encorePink
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 20) {
            MemphisIconScene(
                icon: icon,
                circleColor: circleColor,
                accentColor: accentColor,
                secondAccent: secondAccent
            )

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.encoreText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.encoreTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search / browse empty state

struct MemphisEmptyStateIllustration: View {
    var body: some View {
        ZStack {
            // Background shapes
            Circle()
                .fill(Color.encoreLightPurple)
                .overlay(Circle().stroke(.black, lineWidth: 2.5))
                .frame(width: 90, height: 90)
                .offset(x: -6, y: 0)

            // Magnifier handle
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.encorePrimary)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 2))
                .frame(width: 11, height: 38)
                .rotationEffect(.degrees(45))
                .offset(x: 40, y: 36)

            // Music note inside lens
            Ellipse()
                .fill(Color.encorePrimary)
                .overlay(Ellipse().stroke(.black, lineWidth: 2))
                .frame(width: 22, height: 16)
                .rotationEffect(.degrees(-15))
                .offset(x: -12, y: 6)

            Rectangle()
                .fill(.black)
                .frame(width: 2.5, height: 20)
                .offset(x: 2, y: -5)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.encorePrimary)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(.black, lineWidth: 1.5))
                .frame(width: 14, height: 7)
                .rotationEffect(.degrees(10))
                .offset(x: 13, y: -11)

            // Accent dots
            Circle()
                .fill(Color.encoreAccent)
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 16, height: 16)
                .offset(x: -52, y: -32)
            Circle()
                .fill(Color.encorePink.opacity(0.85))
                .overlay(Circle().stroke(.black, lineWidth: 1.5))
                .frame(width: 10, height: 10)
                .offset(x: 54, y: -26)
            Circle()
                .fill(.black)
                .frame(width: 6, height: 6)
                .offset(x: -22, y: 48)
        }
        .frame(width: 130, height: 130)
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            ZStack {
                Color(hex: "7C3AED")
                MemphisGuitarIllustration()
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            ZStack {
                Color(hex: "059669")
                MemphisPianoIllustration()
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        HStack(spacing: 16) {
            ZStack {
                Color(hex: "D97706")
                MemphisDrumIllustration()
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            ZStack {
                Color(hex: "DB2777")
                MemphisBrassIllustration()
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        HStack(spacing: 16) {
            ZStack {
                Color(hex: "2563EB")
                MemphisGenericMusicIllustration()
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            MemphisEmptyStateIllustration()
        }
    }
    .padding()
    .background(Color(hex: "F2E8FF"))
}
