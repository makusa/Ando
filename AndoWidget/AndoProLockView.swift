//  AndoProLockView.swift — ce que les widgets affichent sans Pro.
//
//  L'extension tourne dans un autre processus : elle n'a accès ni à StoreKit
//  ni au gestionnaire de droits. L'état d'achat lui parvient par le champ
//  `isPro` de la charge utile partagée, recopié à chaque écriture par
//  WidgetDataWriter.
//
//  Le verrou n'affiche aucun montant. C'est le but : un widget qui montrerait
//  la valeur nette en la barrant d'un cadenas livrerait quand même le chiffre.

import SwiftUI
import WidgetKit

struct AndoProLockView: View {
    let data: AndoWidgetData
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            // Pas de place pour une phrase : le cadenas seul.
            Image(systemName: "lock.fill")
                .font(.title3)
                .widgetAccentable()

        case .accessoryInline, .accessoryRectangular:
            Label(data.str("proLocked"), systemImage: "lock.fill")
                .font(.caption)

        case .systemSmall:
            VStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.title3)
                Text(data.str("proLocked"))
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        default:
            VStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.title2)
                Text(data.str("proLocked"))
                    .font(.headline)
                Text(data.str("proHint"))
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
