import SwiftUI
import AppKit

struct PopoverView: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.secondary)
                Text("Claude")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { store.refreshNow() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            HStack(spacing: 24) {
                GaugeView(percent: store.snapshot.contextPercent)
                Spacer()
                RingView(percent: store.snapshot.contextPercent)
            }
            .frame(maxWidth: .infinity)

            Text("Contexto da sessão ativa · \(TokenFormat.short(store.snapshot.contextUsedTokens)) / \(TokenFormat.short(store.snapshot.contextLimitTokens))")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 8) {
                Text("HISTÓRICO DE USO (14 DIAS)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                HistoryChartView(days: store.snapshot.last14Days)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("DETALHES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                DetailsView(snapshot: store.snapshot)
            }

            Divider()

            Toggle("Mostrar % na barra de menu", isOn: $store.showPercentInMenuBar)
                .toggleStyle(.checkbox)
                .font(.system(size: 11))

            Divider()

            HStack {
                Text("Atualizado \(relativeTime(store.snapshot.lastUpdated))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Sair") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
