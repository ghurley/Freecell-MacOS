import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            // Felt background
            LinearGradient(
                colors: [DS.felt, DS.feltDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                topRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                tableauArea
                    .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
        }
        .alert("🎉 You Win!", isPresented: $vm.showWinAlert) {
            Button("New Game") { vm.newGame() }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Congratulations! You completed FreeCell in \(vm.state.moveCount) moves.")
        }
        .onTapGesture {
            // Tapping the background clears selection
            vm.clearSelection()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("FREECELL")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(4)

            Spacer()

            HStack(spacing: 6) {
                Text("Moves: \(vm.state.moveCount)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.2)))
            }

            Spacer()

            HStack(spacing: 8) {
                headerButton("↩", "Undo", enabled: !vm.history.isEmpty) {
                    vm.undo()
                }
                headerButton("✦", "Auto", enabled: true) {
                    vm.autoMoveToFoundation()
                }
                headerButton("⊕", "New", enabled: true) {
                    vm.newGame()
                }
            }
        }
    }

    private func headerButton(_ icon: String, _ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.system(size: 15, weight: .bold))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(enabled ? .white : .white.opacity(0.35))
            .frame(width: 46, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(enabled ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Top Row (Free Cells + Foundations)

    private var topRow: some View {
        HStack(spacing: 0) {
            // Free Cells
            HStack(spacing: 10) {
                ForEach(0..<4) { idx in
                    freeCellSlot(idx)
                }
            }

            Spacer()

            // Foundations
            HStack(spacing: 10) {
                ForEach(0..<4) { idx in
                    foundationSlot(idx)
                }
            }
        }
    }

    private func freeCellSlot(_ idx: Int) -> some View {
        ZStack {
            if let card = vm.state.freeCells[idx] {
                CardView(card: card, isSelected: vm.isSelected(card))
                    .onTapGesture { vm.tapFreeCell(idx) }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else {
                EmptySlotView(label: "FREE")
                    .onTapGesture { vm.tapFreeCell(idx) }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.state.freeCells[idx])
    }

    private func foundationSlot(_ idx: Int) -> some View {
        let suitOrder: [Suit] = [.clubs, .diamonds, .hearts, .spades]
        let suit = suitOrder[idx]
        let pile = vm.state.foundations[idx]

        return ZStack {
            if let top = pile.last {
                CardView(card: top)
                    .onTapGesture { vm.tapFoundation(idx) }
                    .overlay(
                        pile.count < 13 ?
                        AnyView(Color.clear) :
                        AnyView(
                            RoundedRectangle(cornerRadius: DS.cardCorner)
                                .stroke(Color.yellow.opacity(0.6), lineWidth: 2)
                        )
                    )
            } else {
                EmptySlotView(suitSymbol: suit.symbol)
                    .onTapGesture { vm.tapFoundation(idx) }
            }

            // Card count badge
            if pile.count > 0 {
                Text("\(pile.count)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
                    .offset(x: 26, y: -42)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pile.count)
    }

    // MARK: - Tableau

    private var tableauArea: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 10
            let totalSpacing = spacing * 7
            let colWidth = (geo.size.width - totalSpacing) / 8
            let scale = min(1.0, colWidth / DS.cardW)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<8) { col in
                    tableauColumn(col, scale: scale)
                        .frame(width: colWidth)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func tableauColumn(_ col: Int, scale: CGFloat) -> some View {
        let cards = vm.state.tableau[col]

        return ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .top) {
                // Invisible background for tapping on empty column
                Color.clear
                    .frame(width: DS.cardW * scale, height: max(columnHeight(cards), DS.cardH * scale))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if cards.isEmpty { vm.tapEmptyTableau(col) }
                    }

                if cards.isEmpty {
                    EmptySlotView()
                        .scaleEffect(scale)
                        .frame(width: DS.cardW * scale, height: DS.cardH * scale)
                        .onTapGesture { vm.tapEmptyTableau(col) }
                } else {
                    cardStack(cards: cards, col: col, scale: scale)
                }
            }
            .frame(width: DS.cardW * scale, height: columnHeight(cards) + 8)
        }
        .frame(maxHeight: .infinity)
    }

    private func cardStack(cards: [Card], col: Int, scale: CGFloat) -> some View {
        ZStack(alignment: .top) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { idx, card in
                CardView(
                    card: card,
                    isSelected: vm.isSelected(card),
                    width: DS.cardW * scale,
                    height: DS.cardH * scale
                )
                .offset(y: CGFloat(idx) * DS.tableauOffset * scale)
                .zIndex(Double(idx))
                .onTapGesture {
                    vm.tapTableauCard(card, columnIndex: col)
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: vm.isSelected(card))
            }
        }
    }

    private func columnHeight(_ cards: [Card]) -> CGFloat {
        if cards.isEmpty { return DS.cardH }
        return DS.cardH + CGFloat(cards.count - 1) * DS.tableauOffset
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 960, height: 700)
}
