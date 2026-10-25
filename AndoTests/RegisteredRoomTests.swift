//
//  RegisteredRoomTests.swift
//  Droits de cotisation CELI / CELIAPP / REER.
//
//  Ces règles viennent de la loi fiscale fédérale, pas de nos choix : un écart
//  ici fait sur-cotiser un utilisateur, qui écope d'une pénalité mensuelle. Rien
//  à l'écran ne le signalerait. C'est pourquoi ce fichier existe.
//
//  Chaque test nomme la règle qu'il protège (R1 à R4 dans la note
//  « Règles d'affaires »).
//
import XCTest
@testable import Ando

final class RegisteredRoomTests: XCTestCase {

    // Dates fixes : un test qui dépend du jour où il tourne finit par mentir.
    private func jour(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
    }

    private func cotisation(_ montant: Decimal, _ date: Date) -> RegisteredEntryData {
        RegisteredEntryData(date: date, amount: montant, isContribution: true)
    }

    private func retrait(_ montant: Decimal, _ date: Date) -> RegisteredEntryData {
        RegisteredEntryData(date: date, amount: montant, isContribution: false)
    }

    // MARK: - R1 · Ancrage

    func testAncrageSansMouvementDonneLeMontantDeLArc() {
        // L'utilisateur saisit ce que l'ARC affiche ; sans aucun mouvement,
        // le moteur doit le rendre tel quel.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celi, anchorYear: 2026, anchorAmount: 15_000,
            entries: [], asOf: jour(2026, 6, 1))
        XCTAssertEqual(r.availableRoom, 15_000)
    }

    func testUneCotisationReduitLeDroitDAutant() {
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celi, anchorYear: 2026, anchorAmount: 15_000,
            entries: [cotisation(5_000, jour(2026, 3, 1))], asOf: jour(2026, 6, 1))
        XCTAssertEqual(r.availableRoom, 10_000)
        XCTAssertEqual(r.lifetimeContributed, 5_000)
    }

    func testLesMouvementsPosterieursALaDateDemandeeSontIgnores() {
        // Une cotisation future ne doit pas amputer le droit d'aujourd'hui.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celi, anchorYear: 2026, anchorAmount: 15_000,
            entries: [cotisation(5_000, jour(2026, 11, 1))], asOf: jour(2026, 6, 1))
        XCTAssertEqual(r.availableRoom, 15_000)
    }

    // MARK: - R2 · CELI : le retrait restaure, mais l'année suivante

    func testCeliUnRetraitNeRestaureRienDansLAnneeCourante() {
        // L'erreur classique : recotiser le montant retiré la même année.
        // Le moteur ne doit pas l'encourager.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celi, anchorYear: 2026, anchorAmount: 15_000,
            entries: [cotisation(10_000, jour(2026, 2, 1)),
                      retrait(4_000, jour(2026, 5, 1))],
            asOf: jour(2026, 8, 1))
        XCTAssertEqual(r.availableRoom, 5_000, "le retrait ne doit pas revenir dans l'année")
    }

    func testCeliLeRetraitRevientLeJanvierSuivantAvecLeDroitAnnuel() {
        // 15 000 − 10 000 = 5 000, puis +7 000 (droit 2027) +4 000 (retrait 2026).
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celi, anchorYear: 2026, anchorAmount: 15_000,
            entries: [cotisation(10_000, jour(2026, 2, 1)),
                      retrait(4_000, jour(2026, 5, 1))],
            asOf: jour(2027, 1, 2))
        XCTAssertEqual(r.availableRoom, 16_000)
    }

    func testCeliLeDroitAnnuelSAjouteChaqueAnnee() {
        // De 2024 à 2026 : 0 au départ, +7 000 en 2025, +7 000 en 2026.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celi, anchorYear: 2024, anchorAmount: 0,
            entries: [], asOf: jour(2026, 6, 1))
        XCTAssertEqual(r.availableRoom, 14_000)
    }

    // MARK: - R3 · CELIAPP : aucune restauration, plafond à vie

    func testCeliappUnRetraitNeRestaureJamaisLeDroit() {
        // Différence majeure avec le CELI : au CELIAPP, le retrait est définitif.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celiapp, anchorYear: 2026, anchorAmount: 8_000,
            entries: [cotisation(8_000, jour(2026, 2, 1)),
                      retrait(8_000, jour(2026, 5, 1))],
            asOf: jour(2027, 6, 1))
        XCTAssertEqual(r.availableRoom, 8_000,
                       "seul le droit annuel 2027 doit s'ajouter, pas le retrait")
    }

    func testCeliappLeReportEstPlafonne() {
        // Sans cotiser en 2026, le report vers 2027 est plafonné : le droit ne
        // s'accumule pas indéfiniment.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celiapp, anchorYear: 2026, anchorAmount: 8_000,
            entries: [], asOf: jour(2027, 6, 1))
        let plafondReport = RegisteredType.celiapp.maxCarryforwardPerYear ?? 0
        XCTAssertLessThanOrEqual(r.availableRoom, plafondReport + 8_000)
    }

    func testCeliappLePlafondAVieNestJamaisDepasse() {
        // 40 000 $ à vie : même après plusieurs années sans cotiser, le droit
        // disponible ne peut pas excéder ce qui reste sous le plafond.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celiapp, anchorYear: 2023, anchorAmount: 8_000,
            entries: [], asOf: jour(2030, 6, 1))
        let plafond = RegisteredType.celiapp.lifetimeCap ?? 0
        XCTAssertEqual(plafond, 40_000)
        XCTAssertLessThanOrEqual(r.availableRoom, plafond)
    }

    func testCeliappLePlafondTientComptteDeCeQuiEstDejaCotise() {
        // 30 000 déjà cotisés : il ne peut rester que 10 000 de droit.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celiapp, anchorYear: 2026, anchorAmount: 8_000,
            lifetimeContributedAtAnchor: 30_000,
            entries: [], asOf: jour(2030, 6, 1))
        XCTAssertLessThanOrEqual(r.availableRoom, 10_000)
    }

    // MARK: - R4 · REER : estimation plafonnée au maximum fédéral

    func testReerUneEstimationExageréeEstRamenéeAuPlafondFederal() {
        // Un utilisateur qui saisit 100 000 $ de droit annuel ne doit pas voir
        // son droit gonfler au-delà du maximum légal : mieux vaut sous-estimer.
        let r = RegisteredRoomCalculator.availableRoom(
            type: .reer, anchorYear: 2025, anchorAmount: 0,
            reerAnnualRoom: 100_000, entries: [], asOf: jour(2026, 6, 1))
        XCTAssertEqual(r.availableRoom, RegisteredLimits.reerAnnualMax(forYear: 2026))
    }

    func testReerUneEstimationRaisonnableEstConservee() {
        let r = RegisteredRoomCalculator.availableRoom(
            type: .reer, anchorYear: 2025, anchorAmount: 0,
            reerAnnualRoom: 5_000, entries: [], asOf: jour(2026, 6, 1))
        XCTAssertEqual(r.availableRoom, 5_000)
    }

    func testReerUnRetraitNeRestaurePasLeDroit() {
        let r = RegisteredRoomCalculator.availableRoom(
            type: .reer, anchorYear: 2026, anchorAmount: 10_000,
            entries: [cotisation(10_000, jour(2026, 2, 1)),
                      retrait(10_000, jour(2026, 5, 1))],
            asOf: jour(2027, 6, 1))
        XCTAssertEqual(r.availableRoom, 0, "le REER ne restaure pas le droit retiré")
    }

    // MARK: - Sur-cotisation

    func testSurCotisationDetecteeEtChiffree() {
        let r = RegisteredRoomCalculator.availableRoom(
            type: .celi, anchorYear: 2026, anchorAmount: 7_000,
            entries: [cotisation(9_000, jour(2026, 3, 1))], asOf: jour(2026, 6, 1))
        XCTAssertTrue(r.isOverContributed)
        XCTAssertEqual(r.excess, 2_000)
    }

    func testPenaliteMensuelleUnPourCentDeLExcedent() {
        // Règle fiscale : 1 % par mois sur l'excédent.
        XCTAssertEqual(RegisteredRoomCalculator.estimatedMonthlyPenalty(excess: 2_000), 20)
    }

    // MARK: - Les tables de limites

    func testLimitesCeliConnues() {
        XCTAssertEqual(RegisteredLimits.celiAnnualLimit(forYear: 2015), 10_000)
        XCTAssertEqual(RegisteredLimits.celiAnnualLimit(forYear: 2023), 6_500)
        XCTAssertEqual(RegisteredLimits.celiAnnualLimit(forYear: 2026), 7_000)
    }

    func testAvantDeuxMilleNeufLeCeliNexistePas() {
        XCTAssertEqual(RegisteredLimits.celiAnnualLimit(forYear: 2008), 0)
    }

    func testAuDelaDeLaTableLaDerniereLimiteEstMaintenue() {
        // Si la table prend du retard, le droit ne doit pas silencieusement
        // tomber à zéro : on tient la dernière valeur connue.
        XCTAssertEqual(RegisteredLimits.celiAnnualLimit(forYear: 2030),
                       RegisteredLimits.celiAnnualLimit(forYear: 2026))
        XCTAssertTrue(RegisteredLimits.celiLimitIsExtrapolated(forYear: 2030))
    }
}
