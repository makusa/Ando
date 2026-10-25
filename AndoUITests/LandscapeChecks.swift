import XCTest

/// B6 — garde-fou sur l'orientation.
///
/// `project.yml` a longtemps déclaré `UIInterfaceOrientationLandscapeLeft` et
/// `…Right` sans que l'interface ait jamais été vue autrement qu'en portrait.
/// Mesuré au simulateur le 25 octobre 2026 : en paysage, la liste des comptes
/// **ne défile pas**. Les comptes au-delà de la hauteur utile — à partir de
/// « Visa Infinite » dans le ménage de démonstration — deviennent
/// inatteignables. Le paysage a donc été retiré de la déclaration.
///
/// Ce test fixe le contrat : **demander une rotation ne doit jamais rendre du
/// contenu inatteignable.** Tant que l'app est portrait seul, la rotation est
/// sans effet et le test passe. Le jour où quelqu'un redéclare le paysage sans
/// corriger le défilement, il échoue.
///
/// Il mesure la même chose deux fois, avant et après rotation, parce qu'une
/// seule mesure ne distingue pas « inatteignable en paysage » de « ce libellé
/// n'existe pas ». C'est ce témoin qui a invalidé une première conclusion :
/// `app.scrollViews.count` vaut 0 dans les deux orientations — une `List`
/// SwiftUI ne s'expose pas comme `scrollView`, et ce chiffre ne prouvait rien.
final class LandscapeChecks: XCTestCase {

    /// Cinquième compte du ménage de démonstration : hors de l'écran au
    /// premier affichage, donc il faut défiler pour l'atteindre.
    private let compteEnBas = "Visa Infinite"

    private var app: XCUIApplication!
    private var index = 0

    override func setUpWithError() throws {
        continueAfterFailure = true
        index = 0
        app = XCUIApplication()
        app.launchArguments = [
            "-FTDemoMode",
            "-appLanguage", "fr",
            "-ando.dev.tierOverride", "placement",
            "-AppleLanguages", "(fr-CA)",
            "-AppleLocale", "fr_CA",
        ]
        app.launch()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    func testUneRotationNeRendJamaisDuContenuInatteignable() {
        attendre(2.5)

        let enPortrait = compteDuBasAtteignable()
        capturer("portrait")
        XCTAssertTrue(enPortrait,
                      "Témoin invalide : « \(compteEnBas) » devrait être atteignable en portrait. "
                      + "Le ménage de démonstration a-t-il changé ?")

        XCUIDevice.shared.orientation = .landscapeLeft
        attendre(2.5)
        let apresRotation = compteDuBasAtteignable()
        capturer("apres-rotation")

        XCTAssertTrue(apresRotation,
                      "Après rotation, « \(compteEnBas) » n'est plus atteignable : la liste ne "
                      + "défile pas. Si le paysage vient d'être redéclaré dans project.yml, il "
                      + "faut d'abord corriger le défilement.")

        XCUIDevice.shared.orientation = .portrait
        attendre(2.5)
        XCTAssertTrue(app.tabBars.buttons["Réglages"].waitForExistence(timeout: 10),
                      "La barre d'onglets ne survit pas à l'aller-retour portrait → paysage → portrait.")
    }

    // MARK: - Outils

    /// Ouvre l'onglet Comptes, défile, et dit si le dernier compte est présent
    /// dans l'arbre d'accessibilité. S'arrête dès que le compte est trouvé, au lieu de balayer un nombre fixe
    /// de fois. Ce n'est pas une optimisation : continuer à balayer une liste
    /// déjà arrivée au bout a figé le runner d'automatisation lors du premier
    /// passage en suite complète (« Wait for ca.bmsk.ando to idle », puis
    /// redémarrage). En portrait, un ou deux gestes suffisent désormais.
    private func compteDuBasAtteignable() -> Bool {
        let onglet = app.tabBars.buttons["Comptes"]
        guard onglet.waitForExistence(timeout: 15) else { return false }
        onglet.tap()
        attendre(1.5)

        let cible = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", compteEnBas))
            .firstMatch

        if cible.exists { return true }
        for _ in 0..<5 {
            app.swipeUp()
            attendre(0.6)
            if cible.exists { return true }
        }
        return false
    }

    private func capturer(_ nom: String) {
        index += 1
        let piece = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        piece.name = String(format: "%02d-%@", index, nom)
        piece.lifetime = .keepAlways
        add(piece)
    }

    private func attendre(_ secondes: TimeInterval) {
        Thread.sleep(forTimeInterval: secondes)
    }
}
