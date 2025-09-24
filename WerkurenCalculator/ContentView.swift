//
//  ContentView.swift
//  WerkurenCalculator
//
//  Gemaakt voor Batiste – omzetting van de HTML calculator naar SwiftUI
//

import SwiftUI

struct ContentView: View {
    // Persistente instellingen (zoals localStorage in de webversie)
    @AppStorage("vih_rate_hour") private var rateHour: Double = 0
    @AppStorage("vih_rate_travel") private var rateTravel: Double = 0
    @AppStorage("vih_std_cost") private var stdCost: Bool = false

    // Sessiewaarden
    @State private var km: Double = 0
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil

    // MARK: - Berekeningen
    private var workedHours: Double {
        guard let s = startDate, let e = endDate else { return 0 }
        return max(0, e.timeIntervalSince(s) / 3600)
    }

    private var billedHours: Double {
        guard let s = startDate, let e = endDate else { return 0 }
        let seconds = max(0, e.timeIntervalSince(s))
        let fullHours = Int(seconds / 3600)
        let remMinutes = Int((seconds - Double(fullHours) * 3600) / 60)
        let extra: Double = remMinutes == 0 ? 0 : (remMinutes <= 30 ? 0.5 : 1.0)
        return Double(fullHours) + extra
    }

    private var labourCost: Double { billedHours * rateHour }
    private var travelCost: Double { km * rateTravel }
    private var standardCost: Double { stdCost ? 5.0 : 0.0 }
    private var total: Double { (endDate != nil ? labourCost + travelCost + standardCost : 0) }

    // MARK: - Formatters
    private let numberFormat: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(0...2))
    private let currencyBE = FloatingPointFormatStyle<Double>.Currency.currency(code: "EUR").precision(.fractionLength(2)).locale(Locale(identifier: "nl_BE"))

    private func timeString(_ d: Date?) -> String {
        guard let d = d else { return "–" }
        return d.formatted(date: .omitted, time: .standard)
    }

    // MARK: - UI
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                    // Titel
                    VStack(spacing: 0) {
                        Text("Vancoillie ") + Text("IT").foregroundStyle(.blue).fontWeight(.heavy) + Text(" Hulp")
                    }
                    .font(.system(size: 28, weight: .heavy))
                    .padding(.top, 8)

                    // Uurtarief & Vervoer
                    GroupBox("Uurtarief & Vervoer") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Uurtarief (€)") {
                                TextField("bv. 45", value: $rateHour, format: numberFormat)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                            }
                            LabeledContent("Vervoertarief per km (€)") {
                                TextField("bv. 0,35", value: $rateTravel, format: numberFormat)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                            }
                            Toggle("Standaardkost van €5 toepassen", isOn: $stdCost)
                                .fontWeight(.semibold)
                        }
                        .padding(.top, 4)
                    }
                    .groupBoxStyle(.calculator)

                    // Rit & Tijd
                    GroupBox("Rit & Tijd") {
                        VStack(alignment: .leading, spacing: 14) {
                            LabeledContent("Aantal km") {
                                TextField("0", value: $km, format: numberFormat)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 160)
                            }

                            VStack(spacing: 12) {
                                timeRow(label: "Starttijd:", value: timeString(startDate))
                                timeRow(label: "Eindtijd:", value: timeString(endDate))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)

                            HStack(spacing: 12) {
                                Button("START") { startDate = Date(); endDate = nil }
                                    .buttonStyle(.start)
                                    .disabled(startDate != nil && endDate == nil)
                                Button("STOP") { endDate = Date() }
                                    .buttonStyle(.stop)
                                    .disabled(startDate == nil || endDate != nil)
                            }
                        }
                    }
                    .groupBoxStyle(.calculator)

                    // Totaal
                    GroupBox("Totaal bedrag") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(total.formatted(currencyBE))
                                .font(.title3).fontWeight(.heavy)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            if endDate != nil {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Uren × uurtarief: \(workedHours.formatted(.number.precision(.fractionLength(2)))) u (gefactureerd: \(billedHours.formatted(.number.precision(.fractionLength(2)))) u) × \(rateHour.formatted(currencyBE)) = \(labourCost.formatted(currencyBE))")
                                    Text("Km × vervoertarief: \(km.formatted(.number.precision(.fractionLength(1)))) km × \(rateTravel.formatted(currencyBE)) = \(travelCost.formatted(currencyBE))")
                                    Text("Standaardkost: \(standardCost.formatted(currencyBE))")
                                }
                                .foregroundStyle(.secondary)
                                .fontWeight(.semibold)
                            } else {
                                Text("Druk op STOP om te berekenen.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .groupBoxStyle(.calculator)
                }
                    .padding()
                }
                // Removed navigationTitle so the navigation bar title no longer appears.
                .onTapGesture {
                    hideKeyboard()
                }
            }
        }
    }

    // Helper view voor tijd
    private func timeRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.title3).fontWeight(.black)
            Spacer()
            Text(value)
                .font(.headline).fontWeight(.heavy)
                .frame(minWidth: 160)
                .padding(.vertical, 8).padding(.horizontal, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Styles
private struct CalculatorGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.label
                .font(.headline.weight(.heavy))
            configuration.content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}

private extension GroupBoxStyle where Self == CalculatorGroupBoxStyle { static var calculator: CalculatorGroupBoxStyle { .init() } }

private struct StartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.blue))
            .shadow(color: .black.opacity(0.16), radius: configuration.isPressed ? 4 : 8, y: configuration.isPressed ? 2 : 6)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

private struct StopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.red))
            .shadow(color: .black.opacity(0.16), radius: configuration.isPressed ? 4 : 8, y: configuration.isPressed ? 2 : 6)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

private extension ButtonStyle where Self == StartButtonStyle { static var start: StartButtonStyle { .init() } }
private extension ButtonStyle where Self == StopButtonStyle { static var stop: StopButtonStyle { .init() } }

#Preview { ContentView() }

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
