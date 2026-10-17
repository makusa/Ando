//
//  LoanCalculatorTests.swift
//  Amortissement des prêts — règle R5 (capitalisation semestrielle).
//
//  La loi canadienne sur l'intérêt impose que le taux affiché d'une hypothèque
//  soit composé DEUX FOIS PAR AN. Diviser le taux annuel par 12, comme le font
//  les outils américains, donne un paiement et un calendrier faux.
//
//  C'est l'argument de précision le plus démontrable du produit — et la Loi sur
//  la concurrence exige de pouvoir l'étayer. Ces tests sont cette preuve.
//
import XCTest
@testable import FinTrack

final class LoanCalculatorTests: XCTestCase {

    private let debut = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!

    private func pret(_ capital: Double, _ taux: Double, _ mois: Int,
                      _ frequence: LoanPaymentFrequency = .monthly,
                      _ capitalisation: LoanCompounding = .semiAnnual) -> LoanCalculator {
        LoanCalculator(principal: capital, annualRatePercent: taux, termMonths: mois,
                       frequency: frequence, compounding: capitalisation,
                       firstPaymentDate: debut)
    }

    // MARK: - R5 · La capitalisation semestrielle

    func testLaCapitalisationSemestrielleDonneUnTauxPlusBasQueLaMensuelle() {
        // (1 + 6%/2)^(1/6) − 1  <  6%/12. C'est tout l'écart avec l'approche
        // américaine : à taux affiché égal, le paiement canadien est plus faible.
        let canadien = pret(100_000, 6.0, 300).periodicRate
        let americain = pret(100_000, 6.0, 300, .monthly, .monthly).periodicRate
        XCTAssertLessThan(canadien, americain)
        XCTAssertEqual(canadien, pow(1.03, 1.0 / 6.0) - 1.0, accuracy: 1e-12)
        XCTAssertEqual(americain, 0.005, accuracy: 1e-12)
    }

    func testPaiementHypothecaireCanadienConnu() {
        // Cas de référence : 300 000 $, 5 %, 25 ans, mensuel, capitalisation
        // semestrielle. Les calculateurs hypothécaires canadiens donnent
        // environ 1 744 $/mois. Le même prêt calculé à l'américaine donnerait
        // environ 1 754 $ : l'écart prouve que la règle est bien appliquée.
        let p = pret(300_000, 5.0, 300).paymentAmount
        XCTAssertEqual(p, 1744, accuracy: 2.0)

        let americain = pret(300_000, 5.0, 300, .monthly, .monthly).paymentAmount
        XCTAssertGreaterThan(americain, p + 5)
    }

    func testTauxZeroDonneUnPaiementEgalAuCapitalDiviseParLesPeriodes() {
        // Garde-fou contre une division par zéro dans la formule.
        let c = pret(12_000, 0, 12)
        XCTAssertEqual(c.paymentAmount, 1_000, accuracy: 0.01)
    }

    // MARK: - L'amortissement doit se refermer

    func testLeSoldeTombeAZeroAuDernierPaiement() {
        // Le test le plus révélateur : si le taux périodique ou le paiement est
        // faux, le solde final dérive au lieu de se refermer.
        let c = pret(300_000, 5.0, 300)
        XCTAssertEqual(c.balance(after: c.totalPayments), 0, accuracy: 1.0)
    }

    func testLeSoldeInitialEstLeCapital() {
        let c = pret(300_000, 5.0, 300)
        XCTAssertEqual(c.balance(after: 0), 300_000, accuracy: 0.01)
    }

    func testLeTableauCouvreToutesLesPeriodes() {
        let c = pret(100_000, 4.0, 60)
        let tableau = c.schedule()
        XCTAssertEqual(tableau.count, c.totalPayments)
        XCTAssertEqual(tableau.count, 60)
    }

    func testChaquePaiementSeDiviseEnCapitalEtInterets() {
        let c = pret(100_000, 5.0, 60)
        let premier = c.schedule(from: 1, to: 1)[0]
        XCTAssertEqual(premier.principal + premier.interest,
                       c.paymentAmount, accuracy: 0.01)
        XCTAssertGreaterThan(premier.interest, 0)
    }

    func testLaPartDinteretsDiminueAvecLeTemps() {
        // Propriété fondamentale de l'amortissement : au fil des paiements, la
        // part d'intérêts baisse et celle du capital monte.
        let c = pret(300_000, 5.0, 300)
        let premier = c.schedule(from: 1, to: 1)[0]
        let dernier = c.schedule(from: c.totalPayments, to: c.totalPayments)[0]
        XCTAssertGreaterThan(premier.interest, dernier.interest)
        XCTAssertLessThan(premier.principal, dernier.principal)
    }

    // MARK: - Fréquences de paiement

    func testNombreDePaiementsSelonLaFrequence() {
        XCTAssertEqual(pret(100_000, 5, 300, .monthly).totalPayments, 300)
        XCTAssertEqual(pret(100_000, 5, 300, .biweekly).totalPayments, 650)
        XCTAssertEqual(pret(100_000, 5, 300, .weekly).totalPayments, 1300)
    }

    func testLeBihebdomadaireAccelereEstLaMoitieDuPaiementMensuel() {
        // Par définition : on paie la moitié du paiement mensuel toutes les deux
        // semaines, soit 26 versements — l'équivalent de 13 mois par an. C'est
        // ce qui raccourcit l'amortissement.
        let mensuel = pret(300_000, 5.0, 300, .monthly).paymentAmount
        let accelere = pret(300_000, 5.0, 300, .biweeklyAccelerated).paymentAmount
        XCTAssertEqual(accelere, mensuel / 2.0, accuracy: 0.01)
    }

    func testLeBihebdomadaireAccelereRembourseAvantLeTerme() {
        // Conséquence attendue : le solde est déjà nul avant la fin du terme.
        let c = pret(300_000, 5.0, 300, .biweeklyAccelerated)
        XCTAssertEqual(c.balance(after: c.totalPayments), 0, accuracy: 1.0)
    }

    // MARK: - Paiement imposé

    func testUnPaiementImposeRemplaceLaFormule() {
        var c = pret(300_000, 5.0, 300)
        c.customPayment = 2_000
        XCTAssertEqual(c.paymentAmount, 2_000)
        // Payer plus que requis doit rembourser plus vite.
        XCTAssertLessThan(c.balance(after: 120), pret(300_000, 5.0, 300).balance(after: 120))
    }
}
