import SwiftUI
import Combine

// MARK: - Drag State

struct DragInfo {
    let cards: [Card]
    let source: DropTarget
}

// MARK: - Game View Model

class GameViewModel: ObservableObject {
    @Published var state: GameState
    @Published var selectedSource: DropTarget? = nil
    @Published var selectedCards: [Card] = []
    @Published var dragInfo: DragInfo? = nil
    @Published var showWinAlert = false
    @Published var history: [GameState] = []
    @Published var animatingCardId: UUID? = nil

    init() {
        state = GameState.newGame()
    }

    func newGame() {
        history.removeAll()
        state = GameState.newGame()
        selectedSource = nil
        selectedCards = []
        dragInfo = nil
        showWinAlert = false
    }

    func undo() {
        guard !history.isEmpty else { return }
        state = history.removeLast()
        selectedSource = nil
        selectedCards = []
    }

    // MARK: - Selection / Click Logic

    func tapFreeCell(_ index: Int) {
        if let source = selectedSource {
            // Try to place selected card(s) to free cell
            if selectedCards.count == 1 {
                attemptMove(from: source, to: .freeCell(index))
            } else {
                // Can't place stack on free cell
                clearSelection()
            }
        } else {
            // Select card in free cell
            if let card = state.freeCells[index] {
                selectedSource = .freeCell(index)
                selectedCards = [card]
            }
        }
    }

    func tapFoundation(_ index: Int) {
        if let source = selectedSource {
            if selectedCards.count == 1 {
                attemptMove(from: source, to: .foundation(index))
            } else {
                clearSelection()
            }
        }
        // Don't select from foundation
    }

    func tapTableauCard(_ card: Card, columnIndex: Int) {
        let colCards = state.tableau[columnIndex]
        guard let cardIdx = colCards.firstIndex(of: card) else { return }

        if let source = selectedSource {
            // Attempt to move to this column
            attemptMove(from: source, to: .tableau(columnIndex))
        } else {
            // Select cards from this position down
            let cards = Array(colCards[cardIdx...])
            if state.isValidSequence(cards) {
                let toEmpty = state.tableau[columnIndex].count == cards.count
                let maxMovable = state.maxMovableCards(toEmptyColumn: false)
                if cards.count <= maxMovable {
                    selectedSource = .tableau(columnIndex)
                    selectedCards = cards
                }
            }
        }
    }

    func tapEmptyTableau(_ columnIndex: Int) {
        if let source = selectedSource {
            attemptMove(from: source, to: .tableau(columnIndex))
        }
    }

    func clearSelection() {
        selectedSource = nil
        selectedCards = []
    }

    // MARK: - Move Logic

    func attemptMove(from source: DropTarget, to destination: DropTarget) {
        guard !selectedCards.isEmpty else {
            clearSelection()
            return
        }

        var newState = state
        let cards = selectedCards

        switch destination {
        case .freeCell(let idx):
            guard cards.count == 1, newState.freeCells[idx] == nil else {
                clearSelection()
                return
            }
            removeCards(cards, from: &newState, source: source)
            newState.freeCells[idx] = cards[0]

        case .foundation(let idx):
            guard cards.count == 1 else {
                clearSelection()
                return
            }
            guard newState.canPlaceOnFoundation(cards[0], foundationIndex: idx) else {
                clearSelection()
                return
            }
            removeCards(cards, from: &newState, source: source)
            newState.foundations[idx].append(cards[0])

        case .tableau(let colIdx):
            let toEmpty = newState.tableau[colIdx].isEmpty
            let maxMovable = newState.maxMovableCards(toEmptyColumn: toEmpty)

            if cards.count > maxMovable {
                clearSelection()
                return
            }

            if !newState.tableau[colIdx].isEmpty {
                guard newState.canPlaceOnTableau(cards[0], columnIndex: colIdx) else {
                    clearSelection()
                    return
                }
            }

            removeCards(cards, from: &newState, source: source)
            newState.tableau[colIdx].append(contentsOf: cards)
        }

        newState.moveCount += 1
        newState.checkWin()
        history.append(state)
        state = newState
        clearSelection()

        if state.isWon {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.showWinAlert = true
            }
        }
    }

    private func removeCards(_ cards: [Card], from state: inout GameState, source: DropTarget) {
        switch source {
        case .freeCell(let idx):
            state.freeCells[idx] = nil
        case .foundation(let idx):
            state.foundations[idx].removeLast()
        case .tableau(let colIdx):
            state.tableau[colIdx].removeLast(cards.count)
        }
    }

    // MARK: - Auto-move to Foundation

    func autoMoveToFoundation() {
        var moved = true
        while moved {
            moved = false
            // Check free cells
            for (i, card) in state.freeCells.enumerated() {
                guard let card = card else { continue }
                for j in 0..<state.foundations.count {
                    if state.canPlaceOnFoundation(card, foundationIndex: j) {
                        var newState = state
                        newState.freeCells[i] = nil
                        newState.foundations[j].append(card)
                        newState.moveCount += 1
                        newState.checkWin()
                        history.append(state)
                        state = newState
                        moved = true
                        break
                    }
                }
            }
            // Check tableau tops
            for (colIdx, col) in state.tableau.enumerated() {
                guard let card = col.last else { continue }
                for j in 0..<state.foundations.count {
                    if state.canPlaceOnFoundation(card, foundationIndex: j) {
                        var newState = state
                        newState.tableau[colIdx].removeLast()
                        newState.foundations[j].append(card)
                        newState.moveCount += 1
                        newState.checkWin()
                        history.append(state)
                        state = newState
                        moved = true
                        break
                    }
                }
            }
        }
        if state.isWon {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showWinAlert = true
            }
        }
    }

    // MARK: - Drag & Drop

    func beginDrag(cards: [Card], source: DropTarget) {
        clearSelection()
        dragInfo = DragInfo(cards: cards, source: source)
    }

    func endDrag(to destination: DropTarget?) {
        guard let drag = dragInfo else { return }
        dragInfo = nil
        guard let dest = destination else { return }
        selectedCards = drag.cards
        selectedSource = drag.source
        attemptMove(from: drag.source, to: dest)
    }

    func isSelected(_ card: Card) -> Bool {
        selectedCards.contains(card)
    }
}
