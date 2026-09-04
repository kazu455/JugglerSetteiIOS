import Foundation

/// 入力された実戦データ(総回転数・BIG回数・REG回数・ぶどう回数)から、
/// 各設定(1〜6)の事後確率をベイズ推定で算出する。
///
/// 各役の出現回数は「総回転数×出現確率」を期待値とするポアソン分布に
/// 従うと仮定し、対数尤度を計算して合成する(独立性を仮定した近似)。
/// 事前分布は一様(全設定が等確率)としている。
struct EstimationInput {
    let totalSpins: Int
    let bigCount: Int
    let regCount: Int
    let grapeCount: Int? // 入力しない場合は nil (ぶどうはカウント困難なため任意)
}

struct EstimationResult: Identifiable {
    let setting: Int
    let posteriorProbability: Double // 0.0〜1.0
    var id: Int { setting }
}

enum SettingEstimator {

    /// log( P(k ; lambda) ) をポアソン分布で計算。lambda = spins * prob
    private static func poissonLogLikelihood(_ k: Int, _ lambda: Double) -> Double {
        guard lambda > 0.0 else { return -Double.infinity }
        // log(lambda^k * e^-lambda / k!) = k*ln(lambda) - lambda - ln(k!)
        var logFactorial = 0.0
        if k >= 2 {
            for i in 2...k {
                logFactorial += log(Double(i))
            }
        }
        return Double(k) * log(lambda) - lambda - logFactorial
    }

    static func estimate(machine: JugglerMachine, input: EstimationInput) -> [EstimationResult] {
        let logLikelihoods: [(Int, Double)] = machine.settings.map { setting in
            let bigLambda = Double(input.totalSpins) * setting.bigProb
            let regLambda = Double(input.totalSpins) * setting.regProb
            var logL = poissonLogLikelihood(input.bigCount, bigLambda)
                + poissonLogLikelihood(input.regCount, regLambda)

            if let grapeCount = input.grapeCount, let grapeProb = setting.grapeProb {
                let grapeLambda = Double(input.totalSpins) * grapeProb
                logL += poissonLogLikelihood(grapeCount, grapeLambda)
            }
            return (setting.setting, logL)
        }

        // オーバーフロー防止のため最大値を引いてから exp する
        let maxLogL = logLikelihoods.map { $0.1 }.max() ?? 0
        let rawLikelihoods = logLikelihoods.map { (s, logL) in (s, exp(logL - maxLogL)) }
        let sum = rawLikelihoods.reduce(0.0) { $0 + $1.1 }

        return rawLikelihoods
            .map { (s, l) in EstimationResult(setting: s, posteriorProbability: sum > 0 ? l / sum : 0) }
            .sorted { $0.setting < $1.setting }
    }
}
