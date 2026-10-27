import SwiftUI
import Supabase

// MARK: - PickerView

struct PickerView: View {
    @Environment(AppState.self) private var appState
    @State private var showCirclePicker = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var reloadID = UUID()
    private var session: PickSession? {
        guard let snapshot = appState.pickSession, let userId = appState.currentUser?.id else { return nil }
        return PickSession(snapshot: snapshot, userId: userId)
    }
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
                if let error = appState.pickError {
                    Text(error).font(Atlas.Font.sans(12)).foregroundColor(Atlas.burnt)
                        .padding(.horizontal, Atlas.screenHPad).padding(.top, 8)
                }
                if let circle = appState.activeCircle {
                    if let match = appState.activePickMatch {
                        matchedView(restaurant: match, circle: circle)
                    } else if let s = session, s.snapshot.memberIds.count < 2 {
                        statusState("Pick together", detail: "Add another member to this circle to find a shared match.")
                    } else if let s = session, !s.queue.isEmpty {
                        if s.isComplete {
                            completeView(session: s, circle: circle)
                        } else {
                            pickContent(session: s, circle: circle)
                        }
                    } else if session == nil {
                        statusState(appState.pickError == nil ? "Syncing your round…" : "Unable to sync",
                                    detail: "Everyone in the circle sees the same saved round.")
                    } else {
                        emptyWishlistState
                    }
                } else {
                    emptyCircleState
                }
            }
        }
        .task(id: "\(appState.activeCircle?.id.uuidString ?? "none")-\(scenePhase == .active)-\(reloadID)") {
            guard scenePhase == .active, let circleId = appState.activeCircle?.id else { return }
            await appState.observePickSession(circleId: circleId)
        }
        .onChange(of: appState.pickSession?.id) { _, _ in
            matchedRestaurant = nil
            dragOffset = .zero
        }
        .onChange(of: appState.pickSession?.matchedRestaurantId) { _, newValue in
            if newValue != nil { matchedRestaurant = appState.activePickMatch }
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
                        matchedRestaurant = nil
                    },
                    onPickAgain: {
                        matchedRestaurant = nil
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
        .disabled(appState.isPickBusy || appState.pickError != nil)
    }

    // MARK: - Matched State (persists after MatchView confirm)

    private func matchedView(restaurant: Restaurant, circle: ScoutCircle) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                CircleAccentRule(circle: circle, label: (session?.timeOfDay ?? .current).matchedAccentLabel)
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
            CircleAccentRule(circle: circle, label: session.timeOfDay.accentLabel)
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
            .allowsHitTesting(!appState.isPickBusy && appState.pickError == nil)
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
                guard let restaurantId = session.lastVotedId else { return }
                Task { await appState.sendPickAction("undo", restaurantId: restaurantId) }
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
        .disabled(appState.isPickBusy || appState.pickError != nil)
    }

    // MARK: - Partner Status Bar

    private func partnerBar(session: PickSession, circle: ScoutCircle) -> some View {
        let partners = session.snapshot.memberIds.filter { $0 != appState.currentUser?.id }
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(partners, id: \.self) { partnerId in
                let done = session.snapshot.progress(for: partnerId)
                let initials = circle.members.first { $0.userId == partnerId }?.initials ?? "Member"
                HStack(spacing: 10) {
                    Text(initials).font(Atlas.Font.sans(12, weight: .semibold)).foregroundColor(Atlas.burnt)
                    Text("\(done) of \(session.totalCount) done")
                        .font(Atlas.Font.sans(12)).foregroundColor(Atlas.ink2)
                    Spacer()
                    if done == 0 { Text("Waiting").font(Atlas.Font.sans(11)).foregroundColor(Atlas.ink3) }
                }
            }
            if partners.isEmpty {
                Text("Waiting for your circle members").font(Atlas.Font.sans(12)).foregroundColor(Atlas.ink2)
            }
            if appState.isPickBusy { ProgressView().tint(Atlas.burnt) }
        }
        .padding(14).background(Atlas.paper2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, Atlas.screenHPad).padding(.top, 20)
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
                    (Text(session.timeOfDay.completePrefix)
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
                    Text(session.snapshot.everyoneFinished ? "No match this round" : "Waiting for your circle")
                        .font(Atlas.Font.serif(28))
                        .foregroundColor(Atlas.ink)
                        .multilineTextAlignment(.center)
                    Text(session.snapshot.everyoneFinished ? "Everyone finished without a shared yes. Try a new round together." : "Your votes are saved. A match appears when everyone says yes to the same place.")
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
            .disabled(!session.snapshot.everyoneFinished || appState.isPickBusy || appState.pickError != nil)
            if session.canUndo {
                Button("Undo last vote") {
                    guard let id = session.lastVotedId else { return }
                    Task { await appState.sendPickAction("undo", restaurantId: id) }
                }
                .font(Atlas.Font.sans(13)).foregroundColor(Atlas.burnt).padding(.top, 12)
                .disabled(appState.isPickBusy || appState.pickError != nil)
            }
            partnerBar(session: session, circle: circle)

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

    private func statusState(_ title: String, detail: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text(title).font(Atlas.Font.serif(26)).foregroundColor(Atlas.ink)
            Text(detail).font(Atlas.Font.sans(14)).foregroundColor(Atlas.ink2).multilineTextAlignment(.center)
            Button("Refresh") { reloadID = UUID() }.foregroundColor(Atlas.burnt)
            Spacer(minLength: Atlas.listBottomPad)
        }.padding(.horizontal, Atlas.screenHPad)
    }

    private func startSession() {
        Task { await appState.sendPickAction("reset") }
        dragOffset = .zero
    }

    private func performSwipe(yes: Bool) {
        guard let card = session?.currentCard, !appState.isPickBusy, appState.pickError == nil else { return }
        dragOffset = .zero
        Task { await appState.sendPickAction("vote", restaurantId: card.id, yes: yes) }
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
