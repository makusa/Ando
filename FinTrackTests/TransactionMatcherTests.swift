//
//  TransactionMatcherTests.swift
//  Rapprochement bancaire — règle R7.
//
//  Deux erreurs opposées, aussi graves l'une que l'autre :
//   • trop strict → doublons dans les comptes de l'utilisateur ;
//   • trop permissif → deux dépenses distinctes fusionnées, une disparaît.
//
//  Les seuils (4 jours, un demi-cent) ne sont pas arbitraires : la date saisie
//  est celle de l'ACHAT, la date bancaire celle de la COMPTABILISATION, qui
//  suit de quelques jours.
//
import XCTest
@testable import FinTrack

final class TransactionMatcherTests: XCTestCase {

    private let compte = "compte-A"

    private func jour(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
    }

    private func candidat(_ id: String, _ montant: Decimal, _ date: Date,
                          compte cle: String? = nil, revenu: Bool = false) -> MatchCandidate {
        MatchCandidate(id: id, accountKey: cle ?? compte, isIncome: revenu,
                       amount: montant, date: date)
    }

    private func decider(_ montant: Decimal, _ date: Date,
                         _ candidats: [MatchCandidate],
                         compte cle: String? = nil,
                         revenu: Bool = false) -> TransactionMatchDecision {
        TransactionMatcher.decide(
            incomingAccountKey: cle ?? compte, incomingIsIncome: revenu,
            incomingAmount: montant, incomingDate: date, candidates: candidats)
    }

    // MARK: - Les trois issues

    func testSansCandidatOnCreeLaTransaction() {
        XCTAssertEqual(decider(45.67, jour(2026, 3, 10), []), .insertNew)
    }

    func testUnSeulCandidatEstAdopteAutomatiquement() {
        let c = candidat("m1", 45.67, jour(2026, 3, 10))
        XCTAssertEqual(decider(45.67, jour(2026, 3, 10), [c]), .autoLink(candidateId: "m1"))
    }

    func testPlusieursCandidatsPartentEnRevision() {
        // Deux dépenses identiques le même jour : l'app ne doit pas choisir à la
        // place de l'utilisateur, au risque d'en faire disparaître une.
        let a = candidat("m1", 45.67, jour(2026, 3, 10))
        let b = candidat("m2", 45.67, jour(2026, 3, 10))
        guard case .review(let ids) = decider(45.67, jour(2026, 3, 10), [a, b]) else {
            return XCTFail("deux candidats équivalents doivent aller en révision")
        }
        XCTAssertEqual(Set(ids), ["m1", "m2"])
    }

    func testLesCandidatsEnRevisionSontOrdonnesParProximiteDeDate() {
        // Pour que la liste proposée soit utile, le plus proche d'abord.
        let loin = candidat("loin", 45.67, jour(2026, 3, 7))
        let proche = candidat("proche", 45.67, jour(2026, 3, 10))
        guard case .review(let ids) = decider(45.67, jour(2026, 3, 11), [loin, proche]) else {
            return XCTFail("attendu : révision")
        }
        XCTAssertEqual(ids.first, "proche")
    }

    // MARK: - La fenêtre de 4 jours

    func testQuatreJoursDEcartCestEncoreUnMatch() {
        let c = candidat("m1", 45.67, jour(2026, 3, 10))
        XCTAssertEqual(decider(45.67, jour(2026, 3, 14), [c]), .autoLink(candidateId: "m1"))
    }

    func testCinqJoursDEcartCestTropLoin() {
        let c = candidat("m1", 45.67, jour(2026, 3, 10))
        XCTAssertEqual(decider(45.67, jour(2026, 3, 15), [c]), .insertNew)
    }

    func testLaFenetreFonctionneDansLesDeuxSens() {
        // La banque peut aussi dater avant la saisie manuelle.
        let c = candidat("m1", 45.67, jour(2026, 3, 14))
        XCTAssertEqual(decider(45.67, jour(2026, 3, 10), [c]), .autoLink(candidateId: "m1"))
    }

    func testLHeureDeSaisieNeFaitPasRaterUnMatch() {
        // La comparaison porte sur les JOURS : une saisie à 23 h et une écriture
        // bancaire le lendemain à 1 h ne sont séparées que d'un jour civil.
        let tard = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0,
                                         of: jour(2026, 3, 10))!
        let tot = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0,
                                        of: jour(2026, 3, 11))!
        let c = candidat("m1", 45.67, tard)
        XCTAssertEqual(decider(45.67, tot, [c]), .autoLink(candidateId: "m1"))
    }

    // MARK: - La tolérance d'un demi-cent

    func testUnArtefactDArrondiNeFaitPasRaterUnMatch() {
        // Les montants arrivent parfois en nombres à virgule flottante : 45,67
        // peut devenir 45,670000000001. La tolérance absorbe cela.
        let c = candidat("m1", Decimal(45.67), jour(2026, 3, 10))
        XCTAssertEqual(decider(Decimal(string: "45.67")!, jour(2026, 3, 10), [c]),
                       .autoLink(candidateId: "m1"))
    }

    func testUnCentDEcartCestUnMontantDifferent() {
        // La limite à ne pas franchir : deux montants réellement distincts ne
        // doivent jamais fusionner.
        let c = candidat("m1", 45.67, jour(2026, 3, 10))
        XCTAssertEqual(decider(45.68, jour(2026, 3, 10), [c]), .insertNew)
    }

    // MARK: - Compte et sens

    func testUnMemeMontantSurUnAutreCompteNeCorrespondPas() {
        let c = candidat("m1", 45.67, jour(2026, 3, 10), compte: "compte-B")
        XCTAssertEqual(decider(45.67, jour(2026, 3, 10), [c]), .insertNew)
    }

    func testUneDepenseNeCorrespondPasAUnRevenu() {
        // Un remboursement de 45,67 $ n'est pas l'achat de 45,67 $.
        let revenu = candidat("m1", 45.67, jour(2026, 3, 10), revenu: true)
        XCTAssertEqual(decider(45.67, jour(2026, 3, 10), [revenu], revenu: false), .insertNew)
    }

    // MARK: - Les seuils eux-mêmes

    func testLesSeuilsRestentCeuxQuiSontDocumentes() {
        // Si quelqu'un change ces constantes, la note « Règles d'affaires »
        // devient fausse : ce test force à faire les deux ensemble.
        XCTAssertEqual(TransactionMatcher.dateWindowDays, 4)
        XCTAssertEqual(TransactionMatcher.amountEpsilon, Decimal(string: "0.005")!)
    }
}
