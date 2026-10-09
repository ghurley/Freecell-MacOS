import SwiftUI

// MARK: - Card Model

enum Suit: Int, CaseIterable, Codable {
    case clubs = 0, diamonds, hearts, spades

    var symbol: String {
        switch self {
        case .clubs:    return "♣"
        case .diamonds: return "♦"
        case .hearts:   return "♥"
        case .spades:   return "♠"
        }
    }

    var isRed: Bool { self == .hearts || self == .diamonds }

    var color: Color { isRed ? Color(red: 0.85, green: 0.15, blue: 0.15) : Color(red: 0.08, green: 0.08, blue: 0.12) }
}

enum Rank: Int, CaseIterable, Codable {
    case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

    var display: String {
        switch self {
        case .ace:   return "A"
        case .jack:  return "J"
        case .queen: return "Q"
        case .king:  return "K"
        default:     return "\(rawValue)"
        }
    }
}

struct Card: Identifiable, Equatable, Codable {
    let id: UUID
    let suit: Suit
    let rank: Rank

    init(suit: Suit, rank: Rank) {
        self.id = UUID()
        self.suit = suit
        self.rank = rank
    }

    var isRed: Bool { suit.isRed }

    static func == (lhs: Card, rhs: Card) -> Bool { lhs.id == rhs.id }
}

// MARK: - Game State

enum DropTarget: Equatable {
    case freeCell(Int)
    case foundation(Int)
    case tableau(Int)
}

struct GameState: Codable {
    var tableau: [[Card]]       // 8 columns
    var freeCells: [Card?]      // 4 free cells
    var foundations: [[Card]]   // 4 foundations (one per suit)
    var moveCount: Int = 0
    var isWon: Bool = false

    static func newGame() -> GameState {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank))
            }
        }
        deck.shuffle()

        var tableau: [[Card]] = Array(repeating: [], count: 8)
        for (i, card) in deck.enumerated() {
            tableau[i % 8].append(card)
        }

        return GameState(
            tableau: tableau,
            freeCells: [nil, nil, nil, nil],
            foundations: [[], [], [], []]
        )
    }

    // Check if a card can go on a foundation
    func canPlaceOnFoundation(_ card: Card, foundationIndex: Int) -> Bool {
        let pile = foundations[foundationIndex]
        if pile.isEmpty {
            return card.rank == .ace
        }
        let top = pile.last!
        return top.suit == card.suit && top.rank.rawValue + 1 == card.rank.rawValue
    }

    // Check if a card can go on a tableau column
    func canPlaceOnTableau(_ card: Card, columnIndex: Int) -> Bool {
        let column = tableau[columnIndex]
        if column.isEmpty { return true }
        let top = column.last!
        return top.isRed != card.isRed && top.rank.rawValue - 1 == card.rank.rawValue
    }

    // Number of empty free cells
    var emptyFreeCells: Int { freeCells.filter { $0 == nil }.count }

    // Number of empty tableau columns
    var emptyTableauColumns: Int { tableau.filter { $0.isEmpty }.count }

    // Max cards that can be moved as a sequence (supermove rule)
    func maxMovableCards(toEmptyColumn: Bool) -> Int {
        let emptyCells = emptyFreeCells
        let emptyColumns = emptyTableauColumns - (toEmptyColumn ? 1 : 0)
        return (emptyCells + 1) * Int(pow(2.0, Double(emptyColumns)))
    }

    // Check if sequence of cards is a valid moveable stack
    func isValidSequence(_ cards: [Card]) -> Bool {
        guard cards.count > 1 else { return true }
        for i in 0..<cards.count - 1 {
            let upper = cards[i]
            let lower = cards[i + 1]
            if upper.isRed == lower.isRed { return false }
            if upper.rank.rawValue - 1 != lower.rank.rawValue { return false }
        }
        return true
    }

    mutating func checkWin() {
        isWon = foundations.allSatisfy { $0.count == 13 }
    }
}
