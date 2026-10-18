//
//  ExchangeRateTests.swift
//  Conversion de devises — bogue B1.
//
//  Jusqu'au 18 octobre 2026, `convert` retournait le montant INCHANGÉ quand un
//  taux manquait. Un patrimoine net mêlant dollars américains et canadiens
//  s'affichait donc comme si 1 $ US valait 1 $ CA — environ 40 % d'erreur,
//  sans aucun signal — et un virement entre devises s'enregistrait au mauvais
//  montant dans les comptes de l'utilisateur.
//
//  Ce n'était pas un oubli ponctuel : la signature non optionnelle ne
//  permettait rien d'autre. Ces tests verrouillent le contrat inverse —
//  impossible n'est pas zéro, et impossible n'est pas « le montant brut ».
//
import XCTest
@testable import Ando

final class ExchangeRateTests: XCTestCase {

    /// Taux relatifs au dollar canadien : 1 $ CA = 0,74 $ US = 450 FCFA.
    private let taux: [String: Decimal] = ["USD": 0.74, "XAF": 450, "CAD": 1]
    private let base = "CAD"

    private func convertir(_ montant: Decimal, _ de: String, _ vers: String,
                           taux: [String: Decimal]? = nil) -> Decimal? {
        ExchangeRateManager.convert(montant, from: de, to: vers,
                                    rates: taux ?? self.taux, base: base)
    }

    // MARK: - Le cœur du bogue

    func testTauxManquantRetourneNilEtNonLeMontantBrut() {
        // Le yen n'est pas dans la table.
        XCTAssertNil(convertir(1000, "JPY", "CAD"),
                     "Un taux absent doit donner nil, jamais le montant inchangé")
        XCTAssertNil(convertir(1000, "CAD", "JPY"))
    }

    func testTableVideRetourneNil() {
        XCTAssertNil(convertir(1000, "USD", "CAD", taux: [:]),
                     "Sans aucun taux chargé, aucune conversion n'est possible")
    }

    func testTauxNulRetourneNilPlutotQueDiviserParZero() {
        XCTAssertNil(convertir(1000, "USD", "CAD", taux: ["USD": 0, "CAD": 1]))
    }

    func testMemeDeviseRetourneLeMontantSansTaux() {
        // Seul cas où rendre le montant tel quel est juste : il n'y a rien à
        // convertir. Doit fonctionner même sans table de taux.
        XCTAssertEqual(convertir(1000, "CAD", "CAD", taux: [:]), 1000)
    }

    // MARK: - Exactitude du calcul

    func testDepuisLaDeviseDeBase() {
        // 1 000 $ CA → $ US au taux 0,74
        XCTAssertEqual(convertir(1000, "CAD", "USD"), 740)
    }

    func testVersLaDeviseDeBase() {
        // 740 $ US → $ CA : division par 0,74
        XCTAssertEqual(convertir(740, "USD", "CAD"), 1000)
    }

    func testConversionCroiseePasseParLaBase() {
        // 740 $ US → FCFA : 740 / 0,74 = 1 000 $ CA, puis × 450 = 450 000
        XCTAssertEqual(convertir(740, "USD", "XAF"), 450_000)
    }

    func testConversionCroiseeEchoueSiUneSeuleDeviseManque() {
        // L'euro manque : ni l'aller ni le retour ne doivent produire un nombre.
        XCTAssertNil(convertir(100, "USD", "EUR"))
        XCTAssertNil(convertir(100, "EUR", "USD"))
    }

    func testMontantNegatifConserveSonSigne() {
        // Les dettes passent par le même chemin que les actifs.
        XCTAssertEqual(convertir(-1000, "CAD", "USD"), -740)
    }

    // MARK: - Somme multidevise

    func testTotalPartielExclutCeQuIlNePeutConvertir() {
        var total = MultiCurrencyTotal()
        total.add(convertir(1000, "CAD", "CAD"))   // 1000
        total.add(convertir(740, "USD", "CAD"))    // 1000
        total.add(convertir(500, "JPY", "CAD"))    // impossible

        XCTAssertEqual(total.value, 2000,
                       "Le montant non convertible ne doit pas être additionné brut")
        XCTAssertEqual(total.missing, 1)
        XCTAssertTrue(total.isPartial)
    }

    func testTotalCompletNEstPasMarquePartiel() {
        var total = MultiCurrencyTotal()
        total.add(convertir(1000, "CAD", "CAD"))
        total.add(convertir(740, "USD", "CAD"))

        XCTAssertEqual(total.value, 2000)
        XCTAssertEqual(total.missing, 0)
        XCTAssertFalse(total.isPartial)
    }

    func testTotalVideEstNeutre() {
        let total = MultiCurrencyTotal()
        XCTAssertEqual(total.value, 0)
        XCTAssertFalse(total.isPartial)
    }

    /// Le scénario qui a donné son nom au bogue : un portefeuille mi-canadien
    /// mi-américain, taux indisponibles. L'ancien code affichait 2 000 $ ;
    /// le nouveau affiche 1 000 $ en signalant qu'un poste manque.
    func testScenarioB1_PatrimoineMixteSansTaux() {
        var total = MultiCurrencyTotal()
        total.add(ExchangeRateManager.convert(1000, from: "CAD", to: "CAD",
                                              rates: [:], base: base))
        total.add(ExchangeRateManager.convert(1000, from: "USD", to: "CAD",
                                              rates: [:], base: base))

        XCTAssertEqual(total.value, 1000)
        XCTAssertEqual(total.missing, 1)
        XCTAssertNotEqual(total.value, 2000,
                          "Régression B1 : les devises non converties sont de retour dans le total")
    }
}
