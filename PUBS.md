# Publicités — AdMob

AdMob est **intégré, configuré avec les vrais identifiants et fonctionnel**.
Vérifié dans le simulateur : formulaire de consentement UMP → popup ATT →
interstitiel qui s'affiche.

| | |
|---|---|
| App ID | `ca-app-pub-9526420306965592~1734753023` (`Info.plist`) |
| Bloc interstitiel | `ca-app-pub-9526420306965592/6616524551` (`AdManager.swift`) |
| `app-ads.txt` | `~/Desktop/WeightOtter/app-ads.txt`, part avec le site |

Sur simulateur, le SDK sert automatiquement des annonces de test même avec ces
identifiants réels : le développement ne génère aucune impression comptée.
Les pubs deviennent réelles à partir d'un build TestFlight ou App Store.

---

## Comment ça se déclenche

La pub n'est pas collée à un bouton. On déclare des « moments » et
`AdManager` décide.

| Moment | Où | Probabilité |
|---|---|---|
| `.calorie` | validation du digicode sur le compteur calories (`TrackView`) | 25 % |
| `.protein` | validation du digicode sur le compteur protéines | 15 % |
| `.weighIn` | ajout d'une pesée (`EntriesView`) | 35 % |

Tirage aléatoire à chaque fois : impossible à anticiper, et il n'y a pas de
pub à chaque saisie.

### Garde-fous (`AdConfig`, en haut de `AdManager.swift`)

| Réglage | Valeur | Rôle |
|---|---|---|
| `enabled` | `true` | coupe-circuit global — `false` désactive tout |
| `cooldown` | 3 min | jamais deux pubs coup sur coup |
| `maxPerDay` | 6 | plafond quotidien, remis à zéro chaque jour |
| `maxAge` | 50 min | une pub plus vieille est jetée, jamais présentée |

Trois protections supplémentaires :
- pas de pub si la sauvegarde vient d'échouer (l'alerte d'erreur passe avant) ;
- si aucune annonce n'est chargée ou si elle a expiré, **rien ne s'affiche** et
  le manager recharge en silence — jamais d'écran vide ;
- les compteurs (plafond du jour, cooldown) ne sont consommés qu'au moment où
  la pub s'affiche vraiment. Un affichage raté ne coûte plus un créneau.

Un interstitiel ne sert qu'une fois : le suivant est préchargé dès la
fermeture du précédent.

---

## Ce qu'il reste à faire

1. **Publier l'app sur l'App Store.**
2. Dans AdMob, **lier l'app à sa fiche App Store** (« Add stores to your AdMob
   app »). Google fait quelques vérifications, ça prend en général deux ou
   trois jours. Tant que ce n'est pas fait, le remplissage publicitaire reste
   très faible — l'app fonctionne normalement, elle n'affiche simplement
   presque rien.
3. Déployer le site WeightOtter sur Netlify et vérifier que
   `https://<ton-site>/app-ads.txt` répond bien. Google va le chercher à la
   racine du **site développeur déclaré dans App Store Connect** : sans lui,
   ton inventaire est vu comme non autorisé et beaucoup d'acheteurs
   n'enchérissent pas.
4. Dans App Store Connect, remplir la fiche *Confidentialité des données* en
   cohérence avec `PrivacyInfo.xcprivacy` : identifiant publicitaire et
   données publicitaires, utilisés pour le suivi.

## Consentement

La chaîne est déjà câblée dans `AdManager.start()`, appelée au lancement :

1. **UMP** (`UMPConsentForm`) — obligatoire en Europe, sans effet ailleurs.
2. **ATT** (`ATTrackingManager`) — présenté après UMP, comme l'exige Google.
   Texte du popup traduit dans les trois `InfoPlist.strings`.

Si l'utilisateur refuse l'un ou l'autre, on envoie `npa=1` : annonces **non
personnalisées**. C'est légal, ça ne bloque rien, et ça rapporte quand même.

En `DEBUG`, la géographie est forcée sur l'EEE (`UMPDebugSettings`) pour que
le formulaire s'affiche à chaque fois pendant les tests. En `RELEASE`, la vraie
géolocalisation s'applique.

---

## Ce qui a déjà été mis à jour avec AdMob

- `Info.plist` : `GADApplicationIdentifier`, `SKAdNetworkItems` (46 réseaux),
  `NSUserTrackingUsageDescription` (localisé FR/EN/JA).
- `PrivacyInfo.xcprivacy` : `NSPrivacyTracking = true`, domaines Google,
  `DeviceID` et `AdvertisingData` déclarés en usage publicitaire tiers.
- La politique de confidentialité (`~/Desktop/WeightOtter/privacy.html`,
  section 4) décrit AdMob et le choix laissé à l'utilisateur.

**Restant côté App Store Connect** : la fiche *Confidentialité des données*
doit déclarer la même chose que `PrivacyInfo.xcprivacy` — identifiant
publicitaire et données publicitaires, utilisés pour le suivi.

---

## Point de vigilance App Store

L'app est classée **Santé et remise en forme**. Les pubs y sont autorisées,
mais Apple refuse les publicités trompeuses à prétention santé (compléments
miracles, régimes express). Exclus ces catégories dans AdMob
(*Blocking controls*) avant la mise en ligne.
