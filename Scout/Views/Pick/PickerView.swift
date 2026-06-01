import SwiftUI

// MARK: - PickSession (local value type, no Supabase needed for Phase 2)

struct PickSession {
    var queue: [Restaurant]
    var currentIndex: Int = 0
    private(set) var yesIds: Set<UUID> = []
    private(set) var skipIds: Set<UUID> = []
    let partnerYesIds: Set<UUID>
    private var history: [(id: UUID, wasYes: Bool)] = []

    var currentCard: Restaurant? { currentIndex < queue.count ? queue[currentIndex] : nil }
    var nextCard: Restaurant?    { (currentIndex + 1) < queue.count ? queue[currentIndex + 1] : nil }
    var backCard: Restaurant?    { (currentIndex + 2) < queue.count ? queue[currentIndex + 2] : nil }

    var totalCount: Int { queue.count }
    var isComplete: Bool { currentIndex >= queue.count }
    var canUndo: Bool { !history.isEmpty }

    var partnerDoneCount: Int {
        min(totalCount, Int(Double(currentIndex) * 1.3) + 1)
    }

    var firstMatch: Restaurant? {
        queue.first { yesIds.contains($0.id) && partnerYesIds.contains($0.id) }
    }

    init(restaurants: [Restaurant]) {
        let capped = Array(restaurants.shuffled().prefix(8))
        queue = capped
        let yesCount = max(1, Int(Double(capped.count) * 0.6))
        partnerYesIds = Set(capped.shuffled().prefix(yesCount).map { $0.id })
    }

    mutating func swipeYes() {
        guard let card = currentCard else { return }
        yesIds.insert(card.id)
        history.append((id: card.id, wasYes: true))
        currentIndex += 1
    }

    mutating func swipeSkip() {
        guard let card = currentCard else { return }
        skipIds.insert(card.id)
        history.append((id: card.id, wasYes: false))
        currentIndex += 1
    }

    mutating func undo() {
        guard let last = history.last, currentIndex > 0 else { return }
        history.removeLast()
        currentIndex -= 1
        if last.wasYes { yesIds.remove(last.id) } else { skipIds.remove(last.id) }
    }
}

// MARK: - PickerView

struct PickerView: View {
    @Environment(AppState.self) private var appState
    @State private var showCirclePicker = false
    @State private var session: PickSession?
    @State private var dragOffset: CGSize = .zero
    @State private var matchedRestaurant: Restaurant?

    private let swipeThreshold: CGFloat = 90
    private let cardW: CGFloat = 310
    private let cardH: CGFloat = 388

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                if let circle = appState.activeCircle {
                    if let s = session, !s.queue.isEmpty {
                        if s.isComplete {
                            completeView(session: s, circle: circle)
                        } else {
                            pickContent(session: s, circle: circle)
                        }
                    } else {
                        emptyWishlistState
                    }
                } else {
                    emptyCircleState
                }
            }
        }
        .onAppear { startSession() }
        .onChange(of: appState.activeCircle?.id) { _, _ in startSession() }
        .sheet(isPresented: $showCirclePicker) {
            CirclePickerSheet(isPresented: $showCirclePicker)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .fullScreenCover(item: $matchedRestaurant) { restaurant in
            if let circle = appState.activeCircle {
                MatchView(restaurant: restaurant, circle: circle) {
                    matchedRestaurant = nil
                    startSession()
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if let circle = appState.activeCircle {
                CircleSwitcherPill(circle: circle, onTap: { showCirclePicker = true })
            }
            Spacer()
            if let s = session, !s.isComplete, !s.queue.isEmpty {
                Text("Round \(s.currentIndex + 1) of \(s.totalCount)")
                    .font(Atlas.Font.serif(13))
                    .foregroundColor(Atlas.ink2)
                    .padding(.trailing, 20)
            }
        }
        .padding(.top, 46)
    }

    // MARK: - Pick Content

    private func pickContent(session: PickSession, circle: ScoutCircle) -> some View {
        VStack(spacing: 0) {
            headingSection(circle: circle)
            cardStack(session: session)
            actionButtons(session: session)
            partnerBar(session: session, circle: circle)
            Spacer(minLength: Atlas.listBottomPad)
        }
    }

    // MARK: - Heading

    private func headingSection(circle: ScoutCircle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CircleAccentRule(circle: circle, label: "TONIGHT")
            (Text("Pick ")
                .font(Atlas.Font.serif(36))
                .foregroundColor(Atlas.ink)
            + Text("for us")
                .font(Atlas.Font.serif(36, italic: true))
                .foregroundColor(Atlas.burnt))
                .padding(.top, 10)
            Text("From your wishlist")
                .font(Atlas.Font.sans(13.5))
                .foregroundColor(Atlas.ink2)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.top, 12)
    }

    // MARK: - Card Stack

    private func cardStack(session: PickSession) -> some View {
        ZStack {
            // Back card (third in queue)
            if let back = session.backCard {
                PickCard(restaurant: back, width: cardW, height: cardH)
                    .rotationEffect(.degrees(-2.5))
                    .offset(y: 20)
                    .scaleEffect(0.91)
                    .opacity(0.85)
                    .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Atlas.paper2)
                    .frame(width: cardW, height: cardH)
                    .rotationEffect(.degrees(-2.5))
                    .offset(y: 20)
                    .scaleEffect(0.91)
                    .opacity(0.4)
            }

            // Middle card (second in queue)
            if let next = session.nextCard {
                PickCard(restaurant: next, width: cardW, height: cardH)
                    .rotationEffect(.degrees(1.5))
                    .offset(y: 10)
                    .scaleEffect(0.96)
                    .opacity(0.92)
                    .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Atlas.paper)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Atlas.rule, lineWidth: 1))
                    .frame(width: cardW, height: cardH)
                    .rotationEffect(.degrees(1.5))
                    .offset(y: 10)
                    .scaleEffect(0.96)
                    .opacity(0.55)
            }

            // Top card (current — draggable)
            if let top = session.currentCard {
                topCard(restaurant: top)
            }
        }
        .frame(width: cardW, height: cardH + 20)
        .padding(.top, 18)
        .animation(.spring(response: 0.36, dampingFraction: 0.78), value: session.currentIndex)
    }

    private func topCard(restaurant: Restaurant) -> some View {
        let swipeRatio = dragOffset.width / 140
        let rotation = Double(swipeRatio) * 8
        let yesOpacity = Double(max(0, min(1, swipeRatio)))
        let skipOpacity = Double(max(0, min(1, -swipeRatio)))

        return PickCard(restaurant: restaurant, width: cardW, height: cardH)
            .rotationEffect(.degrees(rotation))
            .offset(dragOffset)
            .overlay(alignment: .topTrailing) {
                verdictBadge("♥ Yes", bg: Atlas.burnt)
                    .rotationEffect(.degrees(-2))
                    .padding(.top, 30)
                    .padding(.trailing, -8)
                    .opacity(yesOpacity)
            }
            .overlay(alignment: .topLeading) {
                verdictBadge("✗ Skip", bg: Atlas.ink.opacity(0.7))
                    .rotationEffect(.degrees(2))
                    .padding(.top, 30)
                    .padding(.leading, -8)
                    .opacity(skipOpacity)
            }
            .shadow(
                color: Color(red: 50/255, green: 30/255, blue: 10/255).opacity(0.22),
                radius: 22, x: 0, y: 16
            )
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Atlas.ink.opacity(0.06), lineWidth: 1))
            .gesture(
                DragGesture()
                    .onChanged { v in
                        withAnimation(.interactiveSpring(response: 0.2)) {
                            dragOffset = v.translation
                        }
                    }
                    .onEnded { v in
                        let x = v.translation.width
                        if x > swipeThreshold {
                            performSwipe(yes: true)
                        } else if x < -swipeThreshold {
                            performSwipe(yes: false)
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
    }

    private func verdictBadge(_ text: String, bg: Color) -> some View {
        Text(text)
            .font(Atlas.Font.sans(11, weight: .bold))
            .foregroundColor(Atlas.paper)
            .kerning(1.2)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(bg)
            .clipShape(Capsule())
    }

    // MARK: - Action Buttons

    private func actionButtons(session: PickSession) -> some View {
        HStack(spacing: 28) {
            // Skip
            Button { performSwipe(yes: false) } label: {
                ZStack {
                    Circle()
                        .fill(Atlas.paper)
                        .overlay(Circle().stroke(Atlas.rule, lineWidth: 1))
                        .frame(width: 56, height: 56)
                    Text("✕")
                        .font(Atlas.Font.serif(20))
                        .foregroundColor(Atlas.ink2)
                }
            }
            .buttonStyle(.plain)
            .cardShadow()

            // Yes
            Button { performSwipe(yes: true) } label: {
                ZStack {
                    Circle()
                        .fill(Atlas.burnt)
                        .frame(width: 72, height: 72)
                    Text("♥")
                        .font(Atlas.Font.serif(28))
                        .foregroundColor(Atlas.paper)
                }
            }
            .buttonStyle(.plain)
            .shadow(color: Atlas.burnt.opacity(0.35), radius: 12, x: 0, y: 10)

            // Undo
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    guard var s = self.session else { return }
                    s.undo()
                    self.session = s
                    dragOffset = .zero
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Atlas.paper)
                        .overlay(Circle().stroke(Atlas.rule, lineWidth: 1))
                        .frame(width: 56, height: 56)
                    Text("↺")
                        .font(Atlas.Font.serif(20))
                        .foregroundColor(Atlas.ink2)
                }
            }
            .buttonStyle(.plain)
            .cardShadow()
            .disabled(!session.canUndo)
            .opacity(session.canUndo ? 1 : 0.38)
        }
        .padding(.top, 26)
    }

    // MARK: - Partner Status Bar

    private func partnerBar(session: PickSession, circle: ScoutCircle) -> some View {
        let partner = circle.members.dropFirst().first ?? circle.members.last
        let done = session.partnerDoneCount
        let total = max(1, session.totalCount)
        let progress = min(1.0, Double(done) / Double(total))
        let name = partner?.initials ?? "Partner"

        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(Atlas.ink).frame(width: 30, height: 30)
                Text(name)
                    .font(Atlas.Font.serif(12))
                    .foregroundColor(Atlas.paper)
            }

            (Text(name)
                .font(Atlas.Font.sans(12.5, weight: .semibold))
                .foregroundColor(Atlas.ink)
            + Text(" is also picking · \(done) of \(session.totalCount) done")
                .font(Atlas.Font.sans(12.5))
                .foregroundColor(Atlas.ink2))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .leading) {
                Capsule().fill(Atlas.rule).frame(width: 40, height: 6)
                Capsule()
                    .fill(Atlas.burnt)
                    .frame(width: max(4, 40 * CGFloat(progress)), height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: done)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Atlas.paper2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, Atlas.screenHPad)
        .padding(.top, 20)
    }

    // MARK: - Session Complete State

    private func completeView(session: PickSession, circle: ScoutCircle) -> some View {
        VStack(spacing: 0) {
            Spacer()
            if let match = session.firstMatch {
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle().fill(circle.accentSwiftUIColor).frame(width: 7, height: 7)
                        Text("IT'S A MATCH")
                            .font(Atlas.Font.sans(10.5, weight: .semibold))
                            .foregroundColor(Atlas.ink3)
                            .kerning(2)
                    }
                    (Text("Tonight: ")
                        .font(Atlas.Font.serif(32))
                        .foregroundColor(Atlas.ink)
                    + Text(match.name)
                        .font(Atlas.Font.serif(32, italic: true))
                        .foregroundColor(Atlas.burnt))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Atlas.screenHPad)

                    Button {
                        matchedRestaurant = match
                    } label: {
                        Text("See your match")
                            .font(Atlas.Font.sans(14.5, weight: .semibold))
                            .foregroundColor(Atlas.paper)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Atlas.ink)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Atlas.screenHPad)
                    .padding(.top, 8)
                }
            } else {
                VStack(spacing: 12) {
                    Text("No match this round")
                        .font(Atlas.Font.serif(28))
                        .foregroundColor(Atlas.ink)
                        .multilineTextAlignment(.center)
                    Text("Keep swiping or try a fresh set.")
                        .font(Atlas.Font.sans(14))
                        .foregroundColor(Atlas.ink2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Atlas.screenHPad)
            }

            Button { startSession() } label: {
                Text("Pick again")
                    .font(Atlas.Font.sans(14, weight: .medium))
                    .foregroundColor(Atlas.ink2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .overlay(Capsule().stroke(Atlas.rule, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.top, 16)

            Spacer(minLength: Atlas.listBottomPad)
        }
    }

    // MARK: - Empty States

    private var emptyWishlistState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Atlas.ink3)
            Text("Nothing to pick from")
                .font(Atlas.Font.serif(24))
                .foregroundColor(Atlas.ink)
            Text("Add restaurants to your wishlist to start picking.")
                .font(Atlas.Font.sans(14))
                .foregroundColor(Atlas.ink2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Atlas.screenHPad)
            Spacer(minLength: Atlas.listBottomPad)
        }
    }

    private var emptyCircleState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Select a circle to pick for")
                .font(Atlas.Font.serif(22))
                .foregroundColor(Atlas.ink2)
            Spacer(minLength: Atlas.listBottomPad)
        }
    }

    // MARK: - Session Management

    private func startSession() {
        let candidates = appState.restaurants.filter { $0.status == .wantToTry }
        session = candidates.isEmpty ? nil : PickSession(restaurants: candidates)
        dragOffset = .zero
    }

    // MARK: - Swipe Mechanics

    private func performSwipe(yes: Bool) {
        guard session?.currentCard != nil else { return }
        let direction: CGFloat = yes ? 1 : -1

        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: direction * 520, height: dragOffset.height * 0.4)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            guard var current = session else { return }
            dragOffset = .zero
            if yes { current.swipeYes() } else { current.swipeSkip() }
            session = current
            if current.isComplete, let match = current.firstMatch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    matchedRestaurant = match
                }
            }
        }
    }
}

// MARK: - PickCard

struct PickCard: View {
    let restaurant: Restaurant
    let width: CGFloat
    let height: CGFloat

    private var heroHeight: CGFloat { height * 0.565 }

    var body: some View {
        VStack(spacing: 0) {
            heroPlaceholder
            infoSection
        }
        .frame(width: width, height: height)
        .background(Atlas.paper)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var heroPlaceholder: some View {
        ZStack {
            Atlas.paper2

            LinearGradient(
                colors: [Atlas.paper2, Color(hex: "#E8DCCA")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            Text(String(restaurant.name.prefix(1)))
                .font(Atlas.Font.serif(100))
                .foregroundColor(Atlas.ink.opacity(0.07))

            LinearGradient(
                colors: [.clear, Atlas.ink.opacity(0.08)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .frame(height: heroHeight)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            kickerLine
            Text(restaurant.name)
                .font(Atlas.Font.serif(26))
                .foregroundColor(Atlas.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.top, 6)
            statsRow
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var kickerLine: some View {
        HStack(spacing: 5) {
            if let c = restaurant.cuisine {
                Text(c.uppercased())
                    .foregroundColor(Atlas.ink3)
            }
            if let p = restaurant.priceTier {
                Text("·").foregroundColor(Atlas.ink3.opacity(0.6))
                Text(p.rawValue)
                    .foregroundColor(Atlas.ink3)
            }
            if let d = restaurant.formattedDistance {
                Text("·").foregroundColor(Atlas.ink3.opacity(0.6))
                Text("\(d) MI")
                    .foregroundColor(Atlas.ink3)
            }
        }
        .font(Atlas.Font.sans(10.5))
        .kerning(1.4)
        .lineLimit(1)
    }

    private var statsRow: some View {
        HStack(spacing: 24) {
            if let rating = restaurant.rating {
                PickStat(value: String(format: "%.1f", rating), label: "Rating")
            }
            if let d = restaurant.formattedDistance {
                PickStat(value: d, label: "Miles")
            }
            if let p = restaurant.priceTier {
                PickStat(value: p.rawValue, label: "Tier")
            }
        }
        .padding(.top, 12)
    }
}

private struct PickStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Atlas.Font.serif(22))
                .foregroundColor(Atlas.ink)
            Text(label.uppercased())
                .font(Atlas.Font.sans(9.5))
                .foregroundColor(Atlas.ink3)
                .kerning(1.4)
        }
    }
}

#Preview {
    PickerView()
        .environment(AppState.preview)
}
