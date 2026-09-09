import SwiftUI

private struct Segment {
    let label: String
    let value: Int
    let color: Color
}

struct DetailsView: View {
    let snapshot: UsageSnapshot

    // Only "fresh" tokens go into the proportional bar. Cache-read tokens
    // are typically 10-400x larger than everything else combined (it's the
    // whole conversation re-read every turn), so mixing it in here would
    // just render as a single solid-colored bar and hide the real signal.
    private var segments: [Segment] {
        [
            Segment(label: "Entrada", value: snapshot.todayInputTokens, color: .blue),
            Segment(label: "Saída", value: snapshot.todayOutputTokens, color: .orange),
            Segment(label: "Cache (escrita)", value: snapshot.todayCacheCreationTokens, color: .red),
        ]
    }

    private var total: Int { max(snapshot.todayFreshTokens, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tokens novos hoje:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(TokenFormat.short(snapshot.todayFreshTokens) + " tokens")
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

                Divider()

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 10, height: 10)
                    Text("Cache reaproveitado:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(TokenFormat.short(snapshot.todayCacheReadTokens))
                        .fontWeight(.medium)
                }
                .font(.system(size: 12))
                Text("Contexto reutilizado a cada turno, cobrado com desconto — não é \"trabalho novo\", por isso fica fora da barra acima.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

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
