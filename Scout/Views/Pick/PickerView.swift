import SwiftUI

// MARK: - Time of Day

enum TimeOfDay: Int {
    case morning = 0, lunch = 1, dinner = 2

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 { return .morning }
        if hour < 15 { return .lunch }
        return .dinner
    }

    var label: String {
        switch self {
        case .morning: return "Morning picks"
        case .lunch:   return "Lunch picks"
        case .dinner:  return "Dinner picks"
        }
    }

    func includes(_ type: Restaurant.EstablishmentType) -> Bool {
        switch self {
        case .morning:
            // Cafes, bakeries, and restaurants (many serve brunch/breakfast)
            return [.cafe, .bakery, .restaurant, .other].contains(type)
        case .lunch:
            // Everything
            return true
        case .dinner:
            // Full-service spots; filter out morning-only bakeries
            return [.restaurant, .bar, .brewery, .winery, .other].contains(type)
        }
    }
}

// MARK: - Deterministic seeded RNG (xorshift64)

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 6364136223846793005 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

private func pickSeed(circleId: UUID, timeOfDay: TimeOfDay) -> UInt64 {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    let s = "\(circleId.uuidString)-\(c.year!)-\(c.month!)-\(c.day!)-\(timeOfDay.rawValue)"
    // DJB2-style hash — deterministic across devices
    var hash: UInt64 = 5381
    for byte in s.utf8 { hash = hash &* 127 &+ UInt64(byte) }
    return hash
}

// MARK: - PickSession

struct PickSession {
    var queue: [Restaurant]
    var currentIndex: Int = 0
    private(set) var yesIds: Set<UUID> = []
    private(set) var skipIds: Set<UUID> = []
    let partnerYesIds: Set<UUID>
    let timeOfDay: TimeOfDay
    private var history: [(id: UUID, wasYes: Bool)] = []

    static let deckSize = 3

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

    // Seed is deterministic: same circle + same calendar day + same time window
    // → all members see the same 3 restaurants
    init(restaurants: [Restaurant], circleId: UUID) {
        let tod = TimeOfDay.current
        timeOfDay = tod

        let filtered = restaurants.filter { tod.includes($0.establishmentType) }
        let pool = filtered.isEmpty ? restaurants : filtered  // fallback: show all if filter empties deck

        var rng = SeededRNG(seed: pickSeed(circleId: circleId, timeOfDay: tod))
        let deck = Array(pool.shuffled(using: &rng).prefix(PickSession.deckSize))
        queue = deck

        // Partner votes use an offset seed so they differ from the user's own outcome
        var partnerRng = SeededRNG(seed: pickSeed(circleId: circleId, timeOfDay: tod) &+ 0xDEAD)
        let yesCount = max(1, Int(Double(deck.count) * 0.6))
        partnerYesIds = Set(deck.shuffled(using: &partnerRng).prefix(yesCount).map { $0.id })
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
    @State private var matchedRestaurant: Restaurant?  // drives the fullScreenCover

    private let swipeThreshold: CGFloat = 90
    private let cardW: CGFloat = 310
    private let cardH: CGFloat = 388

    var body: some View {
        ZStack {
            Atlas.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                if let circle = appState.activeCircle {
                    if let match = appState.activePickMatch {
                        matchedView(restaurant: match, circle: circle)
                    } else if let s = session, !s.queue.isEmpty {
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
        .onChange(of: appState.activeCircle?.id) { _, _ in
            appState.activePickMatch = nil
            startSession()
        }
        .sheet(isPresented: $showCirclePicker) {
            CirclePickerSheet(isPresented: $showCirclePicker)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(Atlas.sheetTopRadius)
        }
        .fullScreenCover(item: $matchedRestaurant) { restaurant in
            if let circle = appState.activeCircle {
                MatchView(
                    restaurant: restaurant,
                    circle: circle,
                    onConfirm: {
                        let r = restaurant
                        matchedRestaurant = nil
                        appState.activePickMatch = r          // stay on match; don't start a new session
                    },
                    onPickAgain: {
                        matchedRestaurant = nil
                        appState.activePickMatch = nil
                        startSession()
                    }
                )
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
            if appState.activePickMatch != nil {
                rematchButton
            } else if let s = session, !s.isComplete, !s.queue.isEmpty {
                Text("Round \(s.currentIndex + 1) of \(s.totalCount)")
                    .font(Atlas.Font.serif(13))
                    .foregroundColor(Atlas.ink2)
                    .padding(.trailing, 20)
            }
        }
        .padding(.top, 46)
    }

    private var rematchButton: some View {
        Button {
            appState.activePickMatch = nil
            startSession()
        } label: {
            ZStack {
                Circle()
                    .fill(Atlas.paper2)
                    .frame(width: 36, height: 36)
                Image(systemName: "shuffle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Atlas.ink2)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
    }

    // MARK: - Matched State (persists after MatchView confirm)

    private func matchedView(restaurant: Restaurant, circle: ScoutCircle) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                CircleAccentRule(circle: circle, label: "TONIGHT'S PICK")
                (Text("Going to ")
                    .font(Atlas.Font.serif(36))
                    .foregroundColor(Atlas.ink)
                + Text(restaurant.name)
                    .font(Atlas.Font.serif(36, italic: true))
                    .foregroundColor(Atlas.burnt))
                    .lineLimit(3)
                    .padding(.top, 10)
                if let cuisine = restaurant.cuisine {
                    Text(cuisine)
                        .font(Atlas.Font.sans(13.5))
                        .foregroundColor(Atlas.ink2)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Atlas.screenHPad)
            .padding(.top, 12)

            PickCard(restaurant: restaurant, width: cardW, height: cardH)
                .shadow(
                    color: Color(red: 50/255, green: 30/255, blue: 10/255).opacity(0.22),
                    radius: 22, x: 0, y: 16
                )
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Atlas.ink.opacity(0.06), lineWidth: 1))
                .padding(.top, 24)
                .allowsHitTesting(false)

            Spacer(minLength: Atlas.listBottomPad)
        }
    }

    // MARK: - Pick Content

    private func pickContent(session: PickSession, circle: ScoutCircle) -> some View {
        VStack(spacing: 0) {
            headingSection(session: session, circle: circle)
            cardStack(session: session)
            actionButtons(session: session)
            partnerBar(session: session, circle: circle)
            Spacer(minLength: Atlas.listBottomPad)
        }
    }

    // MARK: - Heading

    private func headingSection(session: PickSession, circle: ScoutCircle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CircleAccentRule(circle: circle, label: "TONIGHT")
            (Text("Pick ")
                .font(Atlas.Font.serif(36))
                .foregroundColor(Atlas.ink)
            + Text("for us")
                .font(Atlas.Font.serif(36, italic: true))
                .foregroundColor(Atlas.burnt))
                .padding(.top, 10)
            Text("\(session.timeOfDay.label) · \(session.totalCount) places")
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
                verdictBadge(yes: true)
                    .rotationEffect(.degrees(-2))
                    .padding(.top, 30)
                    .padding(.trailing, -8)
                    .opacity(yesOpacity)
            }
            .overlay(alignment: .topLeading) {
                verdictBadge(yes: false)
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

    private func verdictBadge(yes: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: yes ? "heart.fill" : "xmark")
                .font(.system(size: 10, weight: .semibold))
            Text(yes ? "YES" : "SKIP")
                .font(Atlas.Font.sans(11, weight: .bold))
                .kerning(0.8)
        }
        .foregroundColor(Atlas.paper)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(yes ? Atlas.burnt : Atlas.ink.opacity(0.72))
        .clipShape(Capsule())
    }

    // MARK: - Action Buttons

    private func actionButtons(session: PickSession) -> some View {
        HStack(spacing: 28) {
            Button { performSwipe(yes: false) } label: {
                ZStack {
                    Circle()
                        .fill(Atlas.paper)
                        .overlay(Circle().stroke(Atlas.rule, lineWidth: 1))
                        .frame(width: 56, height: 56)
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Atlas.ink2)
                }
            }
            .buttonStyle(.plain)
            .cardShadow()

            Button { performSwipe(yes: true) } label: {
                ZStack {
                    Circle()
                        .fill(Atlas.burnt)
                        .frame(width: 72, height: 72)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(Atlas.paper)
                }
            }
            .buttonStyle(.plain)
            .shadow(color: Atlas.burnt.opacity(0.35), radius: 12, x: 0, y: 10)

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
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .light))
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
        let name = partner?.initials ?? "?"

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
        guard let circleId = appState.activeCircle?.id else {
            session = nil
            return
        }
        let candidates = appState.restaurants.filter { $0.status == .wantToTry }
        session = candidates.isEmpty ? nil : PickSession(restaurants: candidates, circleId: circleId)
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
                Text(c.uppercased()).foregroundColor(Atlas.ink3)
            }
            if let p = restaurant.priceTier {
                Text("·").foregroundColor(Atlas.ink3.opacity(0.6))
                Text(p.rawValue).foregroundColor(Atlas.ink3)
            }
            if let d = restaurant.formattedDistance {
                Text("·").foregroundColor(Atlas.ink3.opacity(0.6))
                Text("\(d) MI").foregroundColor(Atlas.ink3)
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
