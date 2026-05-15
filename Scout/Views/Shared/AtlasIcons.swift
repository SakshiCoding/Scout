import SwiftUI

// MARK: - Tab bar icons (transcribed from direction-a.jsx AIcon component)
// Stroke weight: 1.6pt, round caps/joins, no fill

struct TabIcon: View {
    let tab: TabItem
    let color: Color
    var size: CGFloat = 22

    var body: some View {
        switch tab {
        case .list:    ListIcon(color: color, size: size)
        case .map:     MapIcon(color: color, size: size)
        case .pick:    PickIcon(color: color, size: size)
        case .journal: JournalIcon(color: color, size: size)
        }
    }
}

// Bullet list icon: three dots on left, three horizontal lines on right
private struct ListIcon: View {
    let color: Color
    let size: CGFloat
    var body: some View {
        Canvas { ctx, _ in
            let s = size / 22
            let stroke = GraphicsContext.Shading.color(color)
            let dotSize: CGFloat = 1.8 * s

            func dot(x: CGFloat, y: CGFloat) {
                ctx.fill(Circle().path(in: CGRect(x: (x - 0.9) * s, y: (y - 0.9) * s, width: dotSize, height: dotSize)), with: stroke)
            }
            dot(x: 5, y: 6); dot(x: 5, y: 11); dot(x: 5, y: 16)

            var p = Path(); p.move(to: CGPoint(x: 9*s, y: 6*s));  p.addLine(to: CGPoint(x: 17*s, y: 6*s))
            var p2 = Path(); p2.move(to: CGPoint(x: 9*s, y: 11*s)); p2.addLine(to: CGPoint(x: 17*s, y: 11*s))
            var p3 = Path(); p3.move(to: CGPoint(x: 9*s, y: 16*s)); p3.addLine(to: CGPoint(x: 15*s, y: 16*s))

            let style = StrokeStyle(lineWidth: 1.6*s, lineCap: .round, lineJoin: .round)
            ctx.stroke(p, with: stroke, style: style)
            ctx.stroke(p2, with: stroke, style: style)
            ctx.stroke(p3, with: stroke, style: style)
        }
        .frame(width: size, height: size)
    }
}

// Map pin (teardrop with inner circle)
private struct MapIcon: View {
    let color: Color
    let size: CGFloat
    var body: some View {
        Canvas { ctx, _ in
            let s = size / 22
            let stroke = GraphicsContext.Shading.color(color)
            let style  = StrokeStyle(lineWidth: 1.6*s, lineCap: .round, lineJoin: .round)

            var pin = Path()
            pin.move(to: CGPoint(x: 11*s, y: 3.5*s))
            pin.addCurve(to: CGPoint(x: 5.5*s, y: 9*s),
                         control1: CGPoint(x: 7.7*s, y: 3.5*s),
                         control2: CGPoint(x: 5.5*s, y: 5.9*s))
            pin.addCurve(to: CGPoint(x: 11*s, y: 18.5*s),
                         control1: CGPoint(x: 5.5*s, y: 12.8*s),
                         control2: CGPoint(x: 11*s, y: 18.5*s))
            pin.addCurve(to: CGPoint(x: 16.5*s, y: 9*s),
                         control1: CGPoint(x: 11*s, y: 18.5*s),
                         control2: CGPoint(x: 16.5*s, y: 12.8*s))
            pin.addCurve(to: CGPoint(x: 11*s, y: 3.5*s),
                         control1: CGPoint(x: 16.5*s, y: 5.9*s),
                         control2: CGPoint(x: 14.3*s, y: 3.5*s))
            pin.closeSubpath()

            let dotRect = CGRect(x: (11-2.1)*s, y: (9-2.1)*s, width: 4.2*s, height: 4.2*s)
            let dot = Path(ellipseIn: dotRect)

            ctx.stroke(pin, with: stroke, style: style)
            ctx.stroke(dot, with: stroke, style: style)
        }
        .frame(width: size, height: size)
    }
}

// Two overlapping rotated cards
private struct PickIcon: View {
    let color: Color
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2 * (size/22))
                .stroke(color, lineWidth: 1.6 * (size/22))
                .frame(width: 9 * (size/22), height: 12 * (size/22))
                .offset(x: -3 * (size/22), y: 0.5 * (size/22))
                .rotationEffect(.degrees(-8))
            RoundedRectangle(cornerRadius: 2 * (size/22))
                .stroke(color, lineWidth: 1.6 * (size/22))
                .frame(width: 9 * (size/22), height: 12 * (size/22))
                .offset(x: 3 * (size/22), y: -0.5 * (size/22))
                .rotationEffect(.degrees(8))
        }
        .frame(width: size, height: size)
    }
}

// Open book
private struct JournalIcon: View {
    let color: Color
    let size: CGFloat
    var body: some View {
        Canvas { ctx, _ in
            let s = size / 22
            let stroke = GraphicsContext.Shading.color(color)
            let style  = StrokeStyle(lineWidth: 1.6*s, lineCap: .round, lineJoin: .round)

            var left = Path()
            left.move(to: CGPoint(x: 11*s, y: 6*s))
            left.addCurve(to: CGPoint(x: 4*s, y: 16.4*s),
                          control1: CGPoint(x: 9*s, y: 4.6*s),
                          control2: CGPoint(x: 6.6*s, y: 4.2*s))
            left.addCurve(to: CGPoint(x: 11*s, y: 18*s),
                          control1: CGPoint(x: 6.6*s, y: 16.2*s),
                          control2: CGPoint(x: 9*s, y: 16.6*s))

            var right = Path()
            right.move(to: CGPoint(x: 11*s, y: 6*s))
            right.addCurve(to: CGPoint(x: 18*s, y: 16.4*s),
                           control1: CGPoint(x: 13*s, y: 4.6*s),
                           control2: CGPoint(x: 15.4*s, y: 4.2*s))
            right.addCurve(to: CGPoint(x: 11*s, y: 18*s),
                           control1: CGPoint(x: 15.4*s, y: 16.2*s),
                           control2: CGPoint(x: 13*s, y: 16.6*s))

            var spine = Path()
            spine.move(to: CGPoint(x: 11*s, y: 6*s))
            spine.addLine(to: CGPoint(x: 11*s, y: 18*s))

            ctx.stroke(left,  with: stroke, style: style)
            ctx.stroke(right, with: stroke, style: style)
            ctx.stroke(spine, with: stroke, style: style)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Reusable small icons

struct ChevronDown: View {
    var color: Color = Atlas.ink2
    var size: CGFloat = 10
    var body: some View {
        Canvas { ctx, _ in
            var p = Path()
            p.move(to:    CGPoint(x: 1,      y: 1))
            p.addLine(to: CGPoint(x: size/2, y: size - 1))
            p.addLine(to: CGPoint(x: size - 1, y: 1))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct ChevronRight: View {
    var color: Color = Atlas.ink3
    var size: CGFloat = 10
    var body: some View {
        Canvas { ctx, _ in
            var p = Path()
            p.move(to:    CGPoint(x: 1,          y: 1))
            p.addLine(to: CGPoint(x: size - 1,   y: size/2))
            p.addLine(to: CGPoint(x: 1,          y: size - 1))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct ChevronLeft: View {
    var color: Color = Atlas.ink
    var size: CGFloat = 10
    var body: some View {
        Canvas { ctx, _ in
            var p = Path()
            p.move(to:    CGPoint(x: size - 1, y: 1))
            p.addLine(to: CGPoint(x: 1,        y: size/2))
            p.addLine(to: CGPoint(x: size - 1, y: size - 1))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct ThreeDotsIcon: View {
    var color: Color = Atlas.ink
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { _ in
                Circle().fill(color).frame(width: 3.5, height: 3.5)
            }
        }
    }
}

struct CheckmarkIcon: View {
    var color: Color = Atlas.paper
    var size: CGFloat = 11
    var body: some View {
        Canvas { ctx, _ in
            let s = size / 11
            var p = Path()
            p.move(to:    CGPoint(x: 1*s, y: 5*s))
            p.addLine(to: CGPoint(x: 4*s, y: 8*s))
            p.addLine(to: CGPoint(x: 10*s, y: 1*s))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: 1.8*s, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct CloseIcon: View {
    var color: Color = Atlas.ink
    var size: CGFloat = 12
    var body: some View {
        Canvas { ctx, _ in
            var p1 = Path()
            p1.move(to: CGPoint(x: 2, y: 2))
            p1.addLine(to: CGPoint(x: size - 2, y: size - 2))
            var p2 = Path()
            p2.move(to: CGPoint(x: size - 2, y: 2))
            p2.addLine(to: CGPoint(x: 2, y: size - 2))
            let style = StrokeStyle(lineWidth: 1.6, lineCap: .round)
            ctx.stroke(p1, with: .color(color), style: style)
            ctx.stroke(p2, with: .color(color), style: style)
        }
        .frame(width: size, height: size)
    }
}

// Close button — paper2 circle
struct CloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            CloseIcon()
                .frame(width: 32, height: 32)
                .background(Atlas.paper2)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// Drag handle pill
struct SheetDragHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 99)
            .fill(Atlas.rule)
            .frame(width: 44, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 14)
    }
}
