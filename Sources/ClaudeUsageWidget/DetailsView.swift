import SwiftUI

private struct Segment {
    let label: String
    let value: Int
    let color: Color
}

struct DetailsView: View {
    let snapshot: UsageSnapshot

    private var segments: [Segment] {
        [
            Segment(label: "Entrada", value: snapshot.todayInputTokens, color: .blue),
            Segment(label: "Saída", value: snapshot.todayOutputTokens, color: .orange),
            Segment(label: "Cache (escrita)", value: snapshot.todayCacheCreationTokens, color: .red),
            Segment(label: "Cache (leitura)", value: snapshot.todayCacheReadTokens, color: .secondary),
        ]
    }

    private var total: Int { max(snapshot.todayTotalTokens, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Usada hoje:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(TokenFormat.short(snapshot.todayTotalTokens) + " tokens")
                    .fontWeight(.semibold)
            }
            .font(.system(size: 12))

            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(segments.indices, id: \.self) { i in
                        let seg = segments[i]
                        Rectangle()
                            .fill(seg.color)
                            .frame(width: geo.size.width * CGFloat(seg.value) / CGFloat(total))
                    }
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(segments.indices, id: \.self) { i in
                    let seg = segments[i]
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(seg.color)
                            .frame(width: 10, height: 10)
                        Text(seg.label + ":")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(TokenFormat.short(seg.value))
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 12))
                }

                HStack {
                    Text("Custo estimado hoje:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(TokenFormat.cost(snapshot.estimatedCostToday))
                        .fontWeight(.medium)
                }
                .font(.system(size: 12))
                .padding(.top, 2)
            }
        }
    }
}
