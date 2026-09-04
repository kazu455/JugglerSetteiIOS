import SwiftUI

struct ContentView: View {
    private let machines = JugglerMachineRepository.machines

    @State private var selectedMachine: JugglerMachine = JugglerMachineRepository.machines.first!
    @State private var totalSpinsText = ""
    @State private var bigCountText = ""
    @State private var regCountText = ""
    @State private var grapeCountText = ""

    @State private var results: [EstimationResult]?
    @State private var errorMessage: String?
    @State private var showReferenceTable = false

    var body: some View {
        NavigationStack {
            Form {
                Section("機種") {
                    Picker("機種を選択", selection: $selectedMachine) {
                        ForEach(machines) { machine in
                            Text(machine.displayName).tag(machine)
                        }
                    }
                    .onChange(of: selectedMachine) { _, newValue in
                        results = nil
                        errorMessage = nil
                        if !newValue.hasGrapeData {
                            grapeCountText = ""
                        }
                    }
                }

                Section("実戦データ") {
                    LabeledTextField(label: "総回転数", text: $totalSpinsText)
                    LabeledTextField(label: "BIG回数", text: $bigCountText)
                    LabeledTextField(label: "REG回数", text: $regCountText)
                    LabeledTextField(
                        label: selectedMachine.hasGrapeData
                            ? "ぶどう回数（任意）"
                            : "ぶどう回数（この機種は非公表のため不使用）",
                        text: $grapeCountText
                    )
                    .disabled(!selectedMachine.hasGrapeData)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }

                Section {
                    Button("設定を判別する") {
                        runEstimation()
                    }
                }

                if let results {
                    Section("設定判別結果（期待度）") {
                        ResultBars(results: results)
                        Text("※ あくまで統計的な期待度の目安です。少数データでは信頼性が下がります。設定6を保証するものではありません。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(showReferenceTable ? "設定判別要素表を閉じる ▲" : "\(selectedMachine.displayName) の設定判別要素表を見る ▼") {
                        showReferenceTable.toggle()
                    }
                    if showReferenceTable {
                        ReferenceTable(machine: selectedMachine)
                    }
                }
            }
            .navigationTitle("ジャグラー設定判別")
        }
    }

    private func runEstimation() {
        guard let spins = Int(totalSpinsText), spins > 0,
              let big = Int(bigCountText),
              let reg = Int(regCountText) else {
            errorMessage = "総回転数・BIG回数・REG回数を正しく入力してください"
            results = nil
            return
        }
        errorMessage = nil
        let grape = Int(grapeCountText)
        let input = EstimationInput(totalSpins: spins, bigCount: big, regCount: reg, grapeCount: grape)
        results = SettingEstimator.estimate(machine: selectedMachine, input: input)
    }
}

private struct LabeledTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
        }
    }
}

private struct ResultBars: View {
    let results: [EstimationResult]

    private var best: EstimationResult? {
        results.max(by: { $0.posteriorProbability < $1.posteriorProbability })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(results) { r in
                let percent = Int((r.posteriorProbability * 100).rounded())
                let isBest = r.setting == best?.setting
                HStack {
                    Text("設定\(r.setting)")
                        .frame(width: 56, alignment: .leading)
                        .fontWeight(isBest ? .bold : .regular)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isBest ? Color.orange : Color.blue)
                                .frame(width: geo.size.width * CGFloat(min(max(r.posteriorProbability, 0), 1)))
                        }
                    }
                    .frame(height: 20)
                    Text("\(percent)%")
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
    }
}

private struct ReferenceTable: View {
    let machine: JugglerMachine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("設定").fontWeight(.bold).frame(width: 44, alignment: .leading)
                Text("BIG").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                Text("REG").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                Text("ぶどう").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            ForEach(machine.settings) { s in
                HStack {
                    Text("設定\(s.setting)").frame(width: 44, alignment: .leading)
                    Text(String(format: "1/%.1f", s.bigDenom)).frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(format: "1/%.1f", s.regDenom)).frame(maxWidth: .infinity, alignment: .leading)
                    Text(s.grapeDenom.map { String(format: "1/%.2f", $0) } ?? "非公表")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption)
            }
            if !machine.hasGrapeData {
                Text("※ この機種はメーカーがぶどう確率を公表していないため、判別にはBIG/REG確率のみを使用します。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    ContentView()
}
