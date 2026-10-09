import SwiftUI

// MARK: - Tableau Column

struct TableauColumnView: View {
    let columnIndex: Int
    let cards: [Card]
    @ObservedObject var vm: GameViewModel

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .top) {
            // Drop target + background
            Color.clear
                .frame(width: DS.cardW, height: totalHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    if cards.isEmpty {
                        vm.tapEmptyTableau(columnIndex)
                    }
                }

            if cards.isEmpty {
                EmptySlotView()
                    .onTapGesture { vm.tapEmptyTableau(columnIndex) }
            } else {
                cardStack
            }
        }
        .frame(width: DS.cardW, height: max(totalHeight, DS.cardH))
    }

    private var cardStack: some View {
        ZStack(alignment: .top) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { idx, card in
                let isInSelectedGroup = vm.isSelected(card)
                let isLastInSelected = isInSelectedGroup && card == vm.selectedCards.last
                let dragCards = draggableCards(from: idx)
                let canDrag = vm.state.isValidSequence(dragCards)

                cardCell(card: card, idx: idx, isSelected: isInSelectedGroup)
                    .offset(y: CGFloat(idx) * DS.tableauOffset)
                    .zIndex(Double(idx))
                    .onTapGesture {
                        vm.tapTableauCard(card, columnIndex: columnIndex)
                    }
                    .gesture(
                        canDrag ? dragGesture(card: card, idx: idx) : nil
                    )
            }
        }
    }

    private func cardCell(card: Card, idx: Int, isSelected: Bool) -> some View {
        CardView(card: card, isSelected: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func draggableCards(from idx: Int) -> [Card] {
        Array(cards[idx...])
    }

    private func dragGesture(card: Card, idx: Int) -> some Gesture {
        DragGesture()
            .onChanged { _ in }
            .onEnded { _ in
                // Simple click-to-select for now (drag handled by tap)
            }
    }

    private var totalHeight: CGFloat {
        if cards.isEmpty { return DS.cardH }
        return DS.cardH + CGFloat(cards.count - 1) * DS.tableauOffset
    }
}
