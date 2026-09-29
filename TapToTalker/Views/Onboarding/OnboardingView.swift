import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var app

    @State private var step = 0
    @State private var selectedMode: VocabularyMode = .intermediate
    @State private var pin = ""
    @State private var confirmPIN = ""
    @State private var pinError: String?
    @State private var editingCard: AACCard?
    @State private var selectedStarterID: String?
    @State private var appeared = false

    private let steps: [(title: String, symbol: String, tint: Color)] = [
        ("Level", "slider.horizontal.3", Color(red: 1.00, green: 0.86, blue: 0.42)),
        ("Cards", "photo.on.rectangle.angled", Color(red: 0.55, green: 0.82, blue: 0.68)),
        ("Protect", "lock.shield.fill", Color(red: 1.00, green: 0.72, blue: 0.62))
    ]

    var body: some View {
        GeometryReader { geo in
            let useCompactChrome = geo.size.height > geo.size.width
                || geo.size.width < 700

            ZStack {
                atmosphere

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, useCompactChrome ? 20 : 28)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    if useCompactChrome {
                        VStack(alignment: .leading, spacing: 16) {
                            sideRailCompact
                            stepContent(compact: true)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    } else {
                        HStack(alignment: .top, spacing: 28) {
                            sideRail
                                .frame(width: min(220, geo.size.width * 0.22))

                            stepContent(compact: false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)
                    }

                    attributionCredit
                        .padding(.horizontal, useCompactChrome ? 20 : 28)
                        .padding(.top, 4)

                    footer
                        .padding(.horizontal, useCompactChrome ? 20 : 28)
                        .padding(.bottom, 18)
                        .padding(.top, 6)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            selectedMode = app.vocabularyMode
            syncSelectedStarter()
            withAnimation(.easeOut(duration: 0.45)) { appeared = true }
        }
        .onChange(of: selectedMode) { _, _ in
            syncSelectedStarter()
        }
        .sheet(item: $editingCard) { card in
            CardEditorView(card: card)
        }
    }

    // MARK: - Atmosphere

    private var atmosphere: some View {
        ZStack {
            AACTheme.boardBackground
                .ignoresSafeArea()

            Circle()
                .fill(steps[0].tint.opacity(0.28))
                .frame(width: 420, height: 420)
                .blur(radius: 50)
                .offset(x: -280, y: -160)

            Circle()
                .fill(steps[1].tint.opacity(0.26))
                .frame(width: 380, height: 380)
                .blur(radius: 55)
                .offset(x: 320, y: 40)

            Circle()
                .fill(steps[2].tint.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 45)
                .offset(x: 80, y: 220)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack(spacing: 14) {
            Image("LaunchMark")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.10), radius: 10, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text("TapToTalker")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AACTheme.cardLabel)
                Text("A quick setup for caregivers")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text("\(step + 1) / \(steps.count)")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AACTheme.cardLabel.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.55), in: Capsule())
        }
    }

    private var sideRail: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                sideRailButton(index: index, item: item, compact: false)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding progress")
    }

    private var sideRailCompact: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                    sideRailButton(index: index, item: item, compact: true)
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding progress")
    }

    private func sideRailButton(
        index: Int,
        item: (title: String, symbol: String, tint: Color),
        compact: Bool
    ) -> some View {
        let isActive = index == step
        let isDone = index < step

        return Button {
            guard index <= step else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                step = index
            }
        } label: {
            HStack(spacing: compact ? 8 : 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: compact ? 12 : 14, style: .continuous)
                        .fill(isActive || isDone ? item.tint : Color.white.opacity(0.55))
                        .frame(width: compact ? 36 : 44, height: compact ? 36 : 44)
                        .shadow(color: isActive ? item.tint.opacity(0.45) : .clear, radius: 8, y: 3)

                    Image(systemName: isDone && !isActive ? "checkmark" : item.symbol)
                        .font(.system(size: compact ? 14 : 17, weight: .bold))
                        .foregroundStyle(isActive || isDone ? AACTheme.cardLabel : .secondary)
                }

                if compact {
                    Text(item.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AACTheme.cardLabel)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Step \(index + 1)")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(item.title)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(AACTheme.cardLabel)
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(compact ? 8 : 10)
            .background(
                RoundedRectangle(cornerRadius: compact ? 14 : 18, style: .continuous)
                    .fill(isActive ? Color.white.opacity(0.78) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 14 : 18, style: .continuous)
                    .strokeBorder(isActive ? item.tint.opacity(0.7) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(index > step)
        .accessibilityLabel("Step \(index + 1): \(item.title)")
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    @ViewBuilder
    private func stepContent(compact: Bool) -> some View {
        Group {
            switch step {
            case 0: levelStep
            case 1: cardsStep(compact: compact)
            default: protectStep(compact: compact)
            }
        }
        .id(step)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: step)
    }

    // MARK: - Step 1

    private var levelStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepIntro(
                eyebrow: "Communication level",
                title: "How should the board feel?",
                detail: "Pick a starting level. Fewer choices are calmer; more choices unlock richer phrases."
            )

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(VocabularyMode.allCases) { mode in
                    modeTile(mode)
                }
            }
        }
    }

    private func modeTile(_ mode: VocabularyMode) -> some View {
        let selected = selectedMode == mode
        let tint = modeTint(mode)

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                selectedMode = mode
            }
        } label: {
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    ForEach(0..<modeDotRows(mode), id: \.self) { row in
                        HStack(spacing: 5) {
                            ForEach(0..<modeDotColumns(mode, row: row), id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(tint)
                                    .frame(width: 18, height: 14)
                            }
                        }
                    }
                }
                .frame(width: 72, height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tint.opacity(0.35))
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(mode.title)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(AACTheme.cardLabel)
                        Spacer(minLength: 0)
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(selected ? Color.accentColor : .secondary.opacity(0.45))
                    }

                    Text(modeBadge(mode))
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(AACTheme.cardLabel.opacity(0.75))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(tint.opacity(0.55), in: Capsule())

                    Text(mode.detail)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(selected ? 0.92 : 0.62))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor : Color.white.opacity(0.5), lineWidth: selected ? 3 : 1)
            )
            .shadow(color: selected ? tint.opacity(0.35) : .black.opacity(0.04), radius: selected ? 14 : 6, y: 5)
            .scaleEffect(selected ? 1.015 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title). \(mode.detail)")
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Step 2

    private func cardsStep(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            stepIntro(
                eyebrow: "Personalize · \(selectedMode.title)",
                title: "Make the cards feel familiar",
                detail: "Pick a starter below, then edit any card in that path. The list matches your \(selectedMode.title.lowercased()) board."
            )

            let _ = app.overridesVersion

            starterSegments

            if let starter = selectedStarter {
                Text("\(editableCardsInSegment.count) cards in “\(app.override(for: starter.id)?.label ?? starter.label)”")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AACTheme.cardLabel.opacity(0.75))
            }

            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 12),
                        count: compact ? 2 : 4
                    ),
                    spacing: 12
                ) {
                    ForEach(editableCardsInSegment) { card in
                        customizeTile(card)
                    }
                }
                .padding(.bottom, 4)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: selectedStarterID)
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: selectedMode)

            Text("You can keep editing later from the board in Edit mode.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var starterSegments: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(homeStarters) { starter in
                    let selected = starter.id == selectedStarter?.id
                    let label = app.override(for: starter.id)?.label ?? starter.label
                    let emoji = app.override(for: starter.id)?.emoji ?? starter.emoji

                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            selectedStarterID = starter.id
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if let openMoji = OpenMoji.image(forEmoji: emoji) {
                                Image(uiImage: openMoji)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                            } else {
                                Text(emoji)
                                    .font(.body)
                            }
                            Text(label)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(AACTheme.cardLabel)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selected ? modeTint(selectedMode).opacity(0.85) : Color.white.opacity(0.62))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    selected ? Color.accentColor : Color.white.opacity(0.45),
                                    lineWidth: selected ? 2.5 : 1
                                )
                        )
                        .shadow(color: selected ? modeTint(selectedMode).opacity(0.3) : .clear, radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(label)
                    .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Card categories")
    }

    private func customizeTile(_ card: AACCard) -> some View {
        let label = app.override(for: card.id)?.label ?? card.label
        let emoji = app.override(for: card.id)?.emoji ?? card.emoji
        let customized = app.override(for: card.id) != nil
        let fill = AACTheme.cardFill(for: card.id, pathRootID: nil)

        return Button {
            editingCard = card
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let image = app.image(for: card.id) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else if let openMoji = OpenMoji.image(forEmoji: emoji) {
                            Image(uiImage: openMoji)
                                .resizable()
                                .scaledToFit()
                                .padding(10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            Text(emoji)
                                .font(.system(size: 42))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(height: 78)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Image(systemName: customized ? "checkmark.seal.fill" : "pencil.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(customized ? Color.accentColor : .white, customized ? .white : Color.accentColor)
                        .padding(6)
                }

                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(AACTheme.cardLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)

                Text(customized ? "Saved" : "Edit")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(customized ? Color.accentColor : .secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 168)
            .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AACTheme.cardLabel.opacity(0.08), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit \(label)")
    }

    // MARK: - Step 3

    private func protectStep(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            stepIntro(
                eyebrow: "Caregiver tools",
                title: "Keep settings safe",
                detail: "A PIN locks caregiver settings so the board stays the way you set it up."
            )

            VStack(alignment: .leading, spacing: 14) {
                labelRow(symbol: "lock.fill", tint: steps[2].tint, title: "Caregiver PIN")

                pinField(placeholder: "Create 4–8 digit PIN", text: $pin)
                pinField(placeholder: "Confirm PIN", text: $confirmPIN)

                if let pinError {
                    Text(pinError)
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color(red: 0.78, green: 0.18, blue: 0.18))
                } else {
                    Text("Optional — leave blank to skip for now.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: compact ? .infinity : 520, alignment: .leading)
            .background(panelBackground(tint: steps[2].tint))
        }
    }

    // MARK: - Footer

    private var attributionCredit: some View {
        Text(OpenMoji.attribution)
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Card symbols from OpenMoji, Creative Commons Attribution ShareAlike 4.0")
    }

    private var footer: some View {
        HStack(spacing: 14) {
            if step > 0 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { step -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .frame(minWidth: 120, minHeight: 52)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(AACTheme.cardLabel)
            }

            Spacer(minLength: 0)

            Button {
                advance()
            } label: {
                HStack(spacing: 8) {
                    Text(step < steps.count - 1 ? "Continue" : "Start talking")
                    Image(systemName: step < steps.count - 1 ? "arrow.right" : "waveform")
                }
                .font(.system(.headline, design: .rounded).weight(.bold))
                .frame(minWidth: 180, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Shared bits

    private func stepIntro(eyebrow: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.system(.caption, design: .rounded).weight(.bold))
                .tracking(1.1)
                .foregroundStyle(Color.accentColor)

            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AACTheme.cardLabel)

            Text(detail)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func labelRow(symbol: String, tint: Color, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(AACTheme.cardLabel)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(AACTheme.cardLabel)
        }
    }

    private func pinField(placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    private func panelBackground(tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private func modeBadge(_ mode: VocabularyMode) -> String {
        switch mode {
        case .simple: return "Beginner"
        case .intermediate: return "Everyday"
        case .guided: return "Focused"
        case .advanced: return "Full"
        }
    }

    private func modeTint(_ mode: VocabularyMode) -> Color {
        switch mode {
        case .simple: return Color(red: 1.00, green: 0.92, blue: 0.70)
        case .intermediate: return Color(red: 0.78, green: 0.88, blue: 0.98)
        case .guided: return Color(red: 0.78, green: 0.93, blue: 0.82)
        case .advanced: return Color(red: 0.94, green: 0.86, blue: 0.98)
        }
    }

    private func modeDotRows(_ mode: VocabularyMode) -> Int {
        switch mode {
        case .simple: return 1
        case .guided: return 2
        case .intermediate: return 2
        case .advanced: return 3
        }
    }

    private func modeDotColumns(_ mode: VocabularyMode, row: Int) -> Int {
        switch mode {
        case .simple: return 3
        case .guided: return 3
        case .intermediate: return row == 0 ? 4 : 3
        case .advanced: return 4
        }
    }

    /// Home starters visible for the level chosen in step 1 (same caps as the live board).
    private var homeStarters: [AACCard] {
        let filtered = DefaultVocabulary.root.options
            .filter { $0.visible(for: selectedMode) }
            .map { $0.filtered(for: selectedMode) }
        return Array(filtered.prefix(min(selectedMode.screenLimit, VocabularyMode.maxTilesPerScreen)))
    }

    private var selectedStarter: AACCard? {
        if let selectedStarterID,
           let match = homeStarters.first(where: { $0.id == selectedStarterID }) {
            return match
        }
        return homeStarters.first
    }

    /// Starter plus every descendant card available in the selected level (deduped by id).
    private var editableCardsInSegment: [AACCard] {
        guard let starter = selectedStarter else { return [] }
        return flattenUniqueCards(starter)
    }

    private func flattenUniqueCards(_ root: AACCard) -> [AACCard] {
        var seen = Set<String>()
        var result: [AACCard] = []

        func walk(_ card: AACCard) {
            if seen.insert(card.id).inserted {
                result.append(card)
            }
            for child in card.options {
                walk(child)
            }
        }

        walk(root)
        return result
    }

    private func syncSelectedStarter() {
        let ids = Set(homeStarters.map(\.id))
        if let selectedStarterID, ids.contains(selectedStarterID) { return }
        selectedStarterID = homeStarters.first?.id
    }

    private func advance() {
        if step == 0 {
            app.vocabularyMode = selectedMode
            syncSelectedStarter()
        }
        if step < steps.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                step += 1
            }
        } else {
            finish()
        }
    }

    private func finish() {
        let trimmed = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmed = confirmPIN.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty {
            guard trimmed.count >= 4, trimmed.count <= 8, trimmed.allSatisfy(\.isNumber) else {
                pinError = "Use a 4–8 digit numeric PIN, or leave blank to skip."
                return
            }
            guard trimmed == confirmed else {
                pinError = "PINs do not match."
                return
            }
        } else if !confirmed.isEmpty {
            pinError = "Clear confirm PIN, or enter a matching PIN."
            return
        }

        pinError = nil
        app.completeOnboarding(
            vocabularyMode: selectedMode,
            pin: trimmed
        )
    }
}
