import SwiftUI

// MARK: - Design Constants

struct DS {
    static let cardW: CGFloat = 80
    static let cardH: CGFloat = 110
    static let cardCorner: CGFloat = 8
    static let tableauOffset: CGFloat = 28
    static let tableauOffsetFacedown: CGFloat = 20

    // Colors
    static let felt = Color(red: 0.08, green: 0.26, blue: 0.12)
    static let feltDark = Color(red: 0.05, green: 0.18, blue: 0.08)
    static let cardBg = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let selectedBorder = Color(red: 1.0, green: 0.85, blue: 0.2)
    static let slotBorder = Color.white.opacity(0.25)
    static let slotFill = Color.black.opacity(0.15)
}

// MARK: - Card View

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var isFaceDown: Bool = false
    var width: CGFloat = DS.cardW
    var height: CGFloat = DS.cardH

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.cardCorner)
                .fill(DS.cardBg)
                .shadow(color: .black.opacity(0.25), radius: 3, x: 1, y: 2)

            if isFaceDown {
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.4, blue: 0.7),
                                     Color(red: 0.1, green: 0.25, blue: 0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                backPattern
            } else {
                cardFace
            }

            if isSelected {
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .stroke(DS.selectedBorder, lineWidth: 2.5)
                    .shadow(color: DS.selectedBorder.opacity(0.5), radius: 4)
            }
        }
        .frame(width: width, height: height)
    }

    private var cardFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top-left rank + suit
            VStack(alignment: .leading, spacing: -2) {
                Text(card.rank.display)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(card.suit.color)
                Text(card.suit.symbol)
                    .font(.system(size: 12))
                    .foregroundColor(card.suit.color)
            }
            .padding(.leading, 5)
            .padding(.top, 5)

            Spacer()

            // Center suit
            Text(card.suit.symbol)
                .font(.system(size: 30))
                .foregroundColor(card.suit.color.opacity(0.85))
                .frame(maxWidth: .infinity)

            Spacer()

            // Bottom-right rank + suit (rotated)
            VStack(alignment: .trailing, spacing: -2) {
                Text(card.suit.symbol)
                    .font(.system(size: 12))
                    .foregroundColor(card.suit.color)
                Text(card.rank.display)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(card.suit.color)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 5)
            .padding(.bottom, 5)
            .rotationEffect(.degrees(180))
        }
    }

    private var backPattern: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.06
            Canvas { ctx, cgSize in
                for row in stride(from: size, to: cgSize.height, by: size * 2.5) {
                    for col in stride(from: size, to: cgSize.width, by: size * 2.5) {
                        let rect = CGRect(x: col - size/2, y: row - size/2, width: size, height: size)
                        ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.12)))
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.cardCorner))
    }
}

// MARK: - Empty Slot View

struct EmptySlotView: View {
    var label: String? = nil
    var suitSymbol: String? = nil
    var width: CGFloat = DS.cardW
    var height: CGFloat = DS.cardH

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.cardCorner)
                .fill(DS.slotFill)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardCorner)
                        .stroke(DS.slotBorder, lineWidth: 1.5)
                )

            VStack(spacing: 4) {
                if let sym = suitSymbol {
                    Text(sym)
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.25))
                }
                if let lbl = label {
                    Text(lbl)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        CardView(card: Card(suit: .hearts, rank: .ace))
        CardView(card: Card(suit: .spades, rank: .king))
        CardView(card: Card(suit: .diamonds, rank: .queen), isSelected: true)
        EmptySlotView(label: "FREE")
    }
    .padding(20)
    .background(DS.felt)
}
