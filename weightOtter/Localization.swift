//
//  Localization.swift
//  Système i18n : FR / EN / JA.
//  Langue par défaut = langue du téléphone, modifiable dans le Profil.
//

import Foundation
import Combine
import SwiftUI

enum AppLang: String, CaseIterable, Identifiable {
    case fr, en, ja
    var id: String { rawValue }
    var label: String {
        switch self {
        case .fr: return "Français"
        case .en: return "English"
        case .ja: return "日本語"
        }
    }
}

@MainActor
final class Localizer: ObservableObject {

    @Published var lang: AppLang {
        didSet { UserDefaults.standard.set(lang.rawValue, forKey: "appLang") }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "appLang"),
           let l = AppLang(rawValue: saved) {
            lang = l
        } else {
            // On lit la préférence de l'appareil plutôt que Locale.current :
            // Locale.current est résolu contre les langues du bundle et
            // retomberait sur l'anglais si une localisation manquait.
            let code = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"
            switch code {
            case "fr": lang = .fr
            case "ja": lang = .ja
            default:   lang = .en
            }
        }
    }

    /// Traduit une clé. Renvoie la clé brute si absente (utile pour les messages d'erreur déjà traduits).
    func t(_ key: String) -> String {
        guard let row = Self.ui[key] else { return key }
        switch lang {
        case .fr: return row[0]
        case .en: return row.count > 1 ? row[1] : row[0]
        case .ja: return row.count > 2 ? row[2] : row[0]
        }
    }

    /// Un message aléatoire de la loutre, dans la langue courante.
    func otterMessage() -> String {
        let pool: [String]
        switch lang {
        case .fr: pool = Self.otterFR
        case .en: pool = Self.otterEN
        case .ja: pool = Self.otterJA
        }
        return pool.randomElement() ?? pool[0]
    }

    // MARK: - Table de l'interface  [fr, en, ja]

    static let ui: [String: [String]] = [
        "tab.list":     ["Liste", "List", "リスト"],
        "tab.chart":    ["Graphique", "Chart", "グラフ"],
        "tab.track":    ["Track", "Track", "トラック"],
        "tab.summary":  ["Résumé", "Summary", "サマリー"],
        "tab.profile":  ["Profil", "Profile", "プロフィール"],
        "nav.entries":  ["Pesées", "Weighings", "計量"],
        "nav.chart":    ["Graphique", "Chart", "グラフ"],
        "nav.track":    ["Track", "Track", "トラック"],
        "nav.summary":  ["Résumé", "Summary", "まとめ"],
        "nav.profile":  ["Profil", "Profile", "プロフィール"],

        // Résumé
        "sum.initial":  ["POIDS INITIAL", "INITIAL WEIGHT", "開始体重"],
        "sum.current":  ["POIDS ACTUEL", "CURRENT WEIGHT", "現在の体重"],
        "sum.lost":     ["PERTE TOTALE", "TOTAL LOSS", "総減量"],
        "sum.days":     ["JOURS SUIVIS", "DAYS TRACKED", "追跡日数"],
        "sum.perweek":  ["PERTE / SEMAINE", "LOSS / WEEK", "週間減量"],
        "sum.bf":       ["% MASSE GRASSE", "% BODY FAT", "体脂肪率"],
        "sum.lean":     ["MASSE MAIGRE", "LEAN MASS", "除脂肪体重"],
        "sum.tdee":     ["TDEE ESTIMÉ", "ESTIMATED TDEE", "推定TDEE"],
        "sum.avgdef":   ["DÉFICIT MOY / JOUR", "AVG DEFICIT / DAY", "平均赤字/日"],
        "sum.totdef":   ["DÉFICIT TOTAL", "TOTAL DEFICIT", "総赤字"],
        "sum.proj30":   ["PROJECTION J+30", "PROJECTION D+30", "30日後予測"],
        "sum.goalin":   ["OBJECTIF ESTIMÉ DANS", "GOAL ESTIMATED IN", "目標まで"],
        "sum.loggeddays": ["jour(s) loggé(s)", "logged day(s)", "日分の記録"],
        "sum.fattheo":  ["de gras (théorique)", "of fat (theoretical)", "の脂肪（理論値）"],
        "sum.target":   ["Cible :", "Target:", "目標："],
        "sum.daysunit": ["jours", "days", "日"],
        "sum.empty":    ["Aucune donnée. Ajoutez des pesées d'abord.",
                         "No data. Add weigh-ins first.",
                         "データなし。先に記録を追加してください。"],

        // Auth
        "auth.login":       ["Connexion", "Login", "ログイン"],
        "auth.register":    ["Créer compte", "Sign up", "アカウント作成"],
        "auth.username":    ["NOM D'UTILISATEUR", "USERNAME", "ユーザー名"],
        "auth.username.ph": ["ex : simon", "e.g. simon", "例：simon"],
        "auth.pin":         ["CODE PIN (6 CHIFFRES)", "PIN CODE (6 DIGITS)", "PINコード（6桁）"],
        "auth.btn.login":   ["CONNEXION", "LOGIN", "ログイン"],
        "auth.btn.register":["CRÉER LE COMPTE", "CREATE ACCOUNT", "アカウント作成"],

        // Erreurs (Store en émet les clés)
        "err.noname":   ["Entrez un nom d'utilisateur", "Enter a username", "ユーザー名を入力してください"],
        "err.pin6":     ["PIN à 6 chiffres requis", "6-digit PIN required", "6桁のPINが必要です"],
        "err.pinshort": ["PIN incomplet", "Incomplete PIN", "PINが不完全です"],
        "err.taken":    ["Ce nom est déjà utilisé", "This name is already taken", "この名前は既に使用されています"],
        "err.wrong":    ["Nom ou PIN incorrect", "Wrong name or PIN", "名前またはPINが違います"],
        "err.signup":   ["Création du compte impossible. Réessayez.", "Could not create account. Please try again.", "アカウントを作成できませんでした。もう一度お試しください。"],

        // Aide / support
        "help.title":   ["Aide", "Help", "ヘルプ"],
        "help.subject": ["Diet Otter — Aide / PIN oublié", "Diet Otter — Help / Forgot PIN", "Diet Otter — ヘルプ / PINを忘れた"],
        "help.body": [
            "Bonjour,\n\nJ'ai besoin d'aide avec mon compte (par exemple : PIN oublié).\nMerci de décrire votre problème ci-dessous :\n",
            "Hello,\n\nI need help with my account (e.g. forgotten PIN).\nPlease describe your problem below:\n",
            "こんにちは、\n\nアカウントについてサポートが必要です（例：PINを忘れた）。\n以下に問題をご記入ください：\n"],
        "help.account": ["Mon nom de compte :", "My account name:", "アカウント名："],
        "help.fallback.title": ["Contacter le support", "Contact support", "サポートに連絡"],
        "help.fallback.msg": [
            "Impossible d'ouvrir l'app Mail. Écrivez-nous à :",
            "Couldn't open the Mail app. Email us at:",
            "メールアプリを開けませんでした。こちらにご連絡ください："],
        "help.copy":    ["Copier l'adresse", "Copy address", "アドレスをコピー"],

        // Avertissement
        "disc.warning": ["AVERTISSEMENT", "DISCLAIMER", "注意事項"],
        "disc.b1": [
            "WeightOtter est un simple outil de suivi personnel. Il ne fournit aucun avis, diagnostic ou traitement médical.",
            "WeightOtter is a simple personal tracking tool. It provides no medical advice, diagnosis or treatment.",
            "WeightOtterは個人用の記録ツールです。医療的助言・診断・治療は提供しません。"],
        "disc.b2": [
            "Les estimations (masse grasse, calories, projections de poids) sont approximatives et purement indicatives.",
            "Estimates (body fat, calories, weight projections) are approximate and purely indicative.",
            "推定値（体脂肪・カロリー・体重予測）は概算であり参考用です。"],
        "disc.b3": [
            "Consultez un médecin ou un professionnel de santé avant toute démarche de perte ou de prise de poids.",
            "Consult a doctor or health professional before any weight loss or gain plan.",
            "減量・増量を始める前に医師または専門家に相談してください。"],
        "disc.b4": [
            "Veillez à une alimentation équilibrée et variée. Aucun objectif affiché ne constitue une recommandation nutritionnelle.",
            "Keep a balanced, varied diet. No displayed goal is a nutritional recommendation.",
            "バランスの良い食事を心がけてください。表示される目標は栄養指導ではありません。"],
        "disc.b5": [
            "En cas de doute, de malaise ou de condition médicale, contactez immédiatement un professionnel de santé.",
            "If in doubt, unwell or with a medical condition, contact a health professional immediately.",
            "不調や持病がある場合は直ちに専門家に連絡してください。"],
        "disc.btn": ["J'AI COMPRIS", "I UNDERSTAND", "理解しました"],
        "disc.footer": [
            "Outil de suivi personnel — ne remplace pas un avis médical. Consultez un professionnel de santé.",
            "Personal tracking tool — not a substitute for medical advice. Consult a health professional.",
            "個人用記録ツール — 医療的助言の代わりにはなりません。専門家に相談を。"],

        // Pesées
        "entry.new":     ["NOUVELLE ENTRÉE", "NEW ENTRY", "新規入力"],
        "entry.date":    ["Date", "Date", "日付"],
        "entry.weight":  ["POIDS (KG)", "WEIGHT (KG)", "体重 (KG)"],
        "entry.cal":     ["CALORIES DE LA VEILLE", "PREVIOUS DAY'S CALORIES", "前日のカロリー"],
        "entry.waist":   ["TOUR DE TAILLE (CM)", "WAIST (CM)", "腹囲 (CM)"],
        "entry.hip":     ["TOUR DE HANCHES (CM)", "HIP (CM)", "ヒップ (CM)"],
        "entry.add":     ["+ AJOUTER", "+ ADD", "＋ 追加"],
        "entry.history": ["HISTORIQUE", "HISTORY", "履歴"],
        "entry.empty":   ["Aucune entrée.", "No entries.", "データなし。"],
        "entry.exists": [
            "Oups ! Une pesée existe déjà pour ce jour. Supprime-la d'abord, ou choisis une autre date.",
            "Oops! A weigh-in already exists for this day. Delete it first, or pick another date.",
            "おっと！この日の記録は既に存在します。先に削除するか、別の日付を選んでください。"],
        "proj.future":   ["ESTIMATIONS FUTURES", "FUTURE ESTIMATES", "将来の予測"],
        "proj.7d":       ["Dans 7 jours", "In 7 days", "7日後"],
        "proj.1m":       ["Dans 1 mois", "In 1 month", "1ヶ月後"],
        "proj.3m":       ["Dans 3 mois", "In 3 months", "3ヶ月後"],
        "proj.xmas":     ["Prochain Noël", "Next Christmas", "次のクリスマス"],
        "proj.july":     ["1er juillet prochain", "Next July 1st", "次の7月1日"],
        "proj.goal.title":   ["ATTEINDRE UN OBJECTIF", "REACH A TARGET", "目標体重に到達"],
        "proj.goal.ph":      ["Poids cible (kg)", "Target weight (kg)", "目標体重 (kg)"],
        "proj.goal.btn":     ["CALCULER", "CALCULATE", "計算"],
        "proj.goal.result":  ["Estimé le", "Estimated on", "推定日："],
        "proj.goal.days":    ["jours", "days", "日"],
        "proj.goal.reached": ["Objectif déjà atteint !", "Target already reached!", "目標達成済み！"],
        "proj.goal.opp":     ["Tendance opposée à cet objectif", "Trend is opposite to this target", "トレンドが目標と逆方向"],
        "proj.goal.toolow": [
            "Objectif sous le seuil de maigreur (%.1f kg pour votre taille). Parlez-en à un professionnel de santé.",
            "Target below the underweight threshold (%.1f kg for your height). Please talk to a health professional.",
            "目標が低体重の基準（身長から %.1f kg）を下回っています。医療専門家にご相談ください。"],
        "proj.capped": [
            "Projections bornées à %.1f kg (IMC 18,5) — une tendance linéaire ne se prolonge pas indéfiniment.",
            "Projections capped at %.1f kg (BMI 18.5) — a linear trend does not continue forever.",
            "予測は %.1f kg（BMI 18.5）で打ち止めです — 直線的な傾向は永遠には続きません。"],
        "entry.range": [
            "Ce poids semble irréaliste. Vérifie la valeur saisie (entre 20 et 400 kg).",
            "That weight looks unrealistic. Please check the value (between 20 and 400 kg).",
            "その体重は現実的ではないようです。入力値をご確認ください（20〜400 kg）。"],

        // Erreurs d'écriture
        "err.network.title": ["Sauvegarde impossible", "Could not save", "保存できませんでした"],
        "err.network": [
            "Tes données n'ont pas pu être enregistrées. Vérifie ta connexion et réessaie.",
            "Your data could not be saved. Check your connection and try again.",
            "データを保存できませんでした。通信状況を確認して再試行してください。"],

        // Publicité
        "ad.label":   ["PUBLICITÉ", "ADVERTISEMENT", "広告"],
        "ad.close":   ["FERMER", "CLOSE", "閉じる"],
        "ad.wait":    ["Fermeture dans %d s", "Closes in %d s", "%d 秒後に閉じられます"],
        "ad.support": [
            "Les pubs financent WeightOtter. Merci !",
            "Ads keep WeightOtter free. Thank you!",
            "広告のおかげで WeightOtter は無料です。ありがとうございます！"],
        "ad.house": [
            "Suivi de poids & composition corporelle",
            "Weight & body composition tracking",
            "体重・体組成のトラッキング"],

        // Track
        "track.today":   ["AUJOURD'HUI", "TODAY", "今日"],
        "track.cal":     ["calorie", "calorie", "カロリー"],
        "track.protein": ["protéine", "protein", "タンパク質"],
        "track.logbook": ["carnet de bord", "logbook", "記録"],
        "track.backtoday": ["← Revenir à aujourd'hui", "← Back to today", "← 今日に戻る"],
        "track.empty":   ["Aucun jour enregistré", "No day logged yet", "記録された日はありません"],

        // Pavé numérique (digicode)
        "digi.back":     ["Retour", "Back", "戻る"],
        "digi.add.hint": ["Vous allez ajouter", "You will add", "追加する量"],
        "digi.sub.hint": ["Vous allez retirer", "You will remove", "削除する量"],
        "digi.current":  ["Actuellement enregistré", "Currently recorded", "現在の記録"],
        "digi.newtotal": ["Nouveau total", "New total", "新しい合計"],

        // Graphique
        "chart.seg.weight": ["POIDS", "WEIGHT", "体重"],
        "chart.seg.fat":    ["GRAISSE", "FAT", "体脂肪"],
        "chart.seg.cal":    ["CALORIES", "CALORIES", "カロリー"],
        "chart.weight":  ["POIDS", "WEIGHT", "体重"],
        "chart.bf":      ["% MASSE GRASSE", "% BODY FAT", "体脂肪率"],
        "chart.bf.kg":   ["MASSE GRASSE (KG)", "FAT MASS (KG)", "体脂肪量 (KG)"],
        "chart.nodata":  ["Pas assez de données", "Not enough data", "データ不足"],
        "chart.proj":    ["PROJECTION (JOURS)", "PROJECTION (DAYS)", "予測（日）"],

        // Profil
        "prof.info":     ["INFOS PERSONNELLES", "PERSONAL INFO", "個人情報"],
        "prof.age":      ["ÂGE", "AGE", "年齢"],
        "prof.height":   ["TAILLE (CM)", "HEIGHT (CM)", "身長 (CM)"],
        "prof.sex":      ["SEXE", "SEX", "性別"],
        "prof.sex.m":    ["Homme", "Male", "男性"],
        "prof.sex.f":    ["Femme", "Female", "女性"],
        "prof.activity": ["ACTIVITÉ", "ACTIVITY", "活動レベル"],
        "prof.goal":     ["POIDS OBJECTIF (KG)", "GOAL WEIGHT (KG)", "目標体重 (KG)"],
        "prof.measures": ["MESURES CORPORELLES", "BODY MEASUREMENTS", "体の計測"],
        "prof.waist":    ["TOUR DE TAILLE (CM)", "WAIST (CM)", "腹囲 (CM)"],
        "prof.neck":     ["TOUR DE COU (CM) — optionnel", "NECK (CM) — optional", "首囲 (CM) — 任意"],
        "prof.hip":      ["TOUR DE HANCHES (CM)", "HIP (CM)", "ヒップ (CM)"],
        "prof.waist.last": ["Tour de taille (dernière pesée)", "Waist (latest weigh-in)", "腹囲（直近の計量）"],
        "prof.hip.last":   ["Tour de hanches (dernière pesée)", "Hip (latest weigh-in)", "ヒップ（直近の計量）"],
        "prof.measures.hint": [
            "Le tour de taille est repris de votre dernière pesée (onglet Pesées). Le tour de cou active la méthode Navy (plus précise).",
            "Waist is taken from your latest weigh-in (Weighings tab). Neck unlocks the Navy method (more precise).",
            "腹囲は直近の計量（計量タブ）から取得されます。首囲を加えるとNavy法（高精度）が使えます。"],
        "prof.body":     ["COMPOSITION CORPORELLE", "BODY COMPOSITION", "体組成"],
        "prof.bf":       ["% Masse grasse", "% Body fat", "体脂肪率"],
        "prof.lean":     ["Masse maigre", "Lean mass", "除脂肪体重"],
        "prof.bmr":      ["BMR", "BMR", "基礎代謝"],
        "prof.tdee":     ["TDEE estimé / jour", "Estimated TDEE / day", "推定TDEE/日"],
        "prof.account":  ["MON COMPTE", "MY ACCOUNT", "アカウント"],
        "prof.username": ["Pseudo", "Nickname", "ニックネーム"],
        "prof.privacy":  ["Politique de confidentialité", "Privacy policy", "プライバシーポリシー"],
        "prof.save":     ["ENREGISTRER LE PROFIL", "SAVE PROFILE", "プロフィールを保存"],
        "prof.logout":   ["SE DÉCONNECTER", "LOG OUT", "ログアウト"],
        "prof.lang":     ["LANGUE", "LANGUAGE", "言語"],
        "prof.lang.hint": [
            "Diet Otter est disponible en français, en anglais et en japonais. Par défaut, l'app suit la langue de votre iPhone.",
            "Diet Otter is available in French, English and Japanese. By default, the app follows your iPhone's language.",
            "Diet Otterは日本語・英語・フランス語に対応しています。初期設定ではiPhoneの言語に従います。"],
        "prof.delete":   ["SUPPRIMER MON COMPTE", "DELETE MY ACCOUNT", "アカウントを削除"],
        "prof.delete.title": ["Supprimer le compte ?", "Delete account?", "アカウントを削除しますか？"],
        "prof.delete.msg": [
            "Cette action est définitive. Toutes tes données (pesées, suivi, profil) seront effacées et irrécupérables.",
            "This action is permanent. All your data (weigh-ins, tracking, profile) will be erased and cannot be recovered.",
            "この操作は取り消せません。すべてのデータ（計量・記録・プロフィール）が削除され、復元できません。"],
        "prof.delete.confirm": ["Supprimer définitivement", "Delete permanently", "完全に削除"],
        "prof.delete.error": [
            "La suppression a échoué. Vérifie ta connexion et réessaie.",
            "Deletion failed. Check your connection and try again.",
            "削除に失敗しました。接続を確認して再試行してください。"],
        "prof.cancel":   ["Annuler", "Cancel", "キャンセル"],

        "act.sed":    ["Sédentaire", "Sedentary", "座りがち"],
        "act.light":  ["Légère", "Light", "軽い活動"],
        "act.mod":    ["Modérée", "Moderate", "中程度"],
        "act.active": ["Active", "Active", "活動的"],
        "act.very":   ["Très active", "Very active", "非常に活動的"],
        "acttip.sed": [
            "Bureau toute la journée · < 5 000 pas · aucun sport",
            "Desk job all day · < 5,000 steps · no exercise",
            "デスクワーク · 5000歩未満 · 運動なし"],
        "acttip.light": [
            "5 000–7 500 pas · 1–2 entraînements légers/sem",
            "5,000–7,500 steps · 1–2 light workouts/week",
            "5000〜7500歩 · 週1〜2回の軽い運動"],
        "acttip.mod": [
            "7 500–10 000 pas · 3–4 sessions sport/sem",
            "7,500–10,000 steps · 3–4 sport sessions/week",
            "7500〜10000歩 · 週3〜4回の運動"],
        "acttip.active": [
            "10 000–12 500 pas · 5–6 sessions intenses/sem",
            "10,000–12,500 steps · 5–6 intense sessions/week",
            "10000〜12500歩 · 週5〜6回の激しい運動"],
        "acttip.very": [
            "> 12 500 pas · sport quotidien ou travail physique",
            "> 12,500 steps · daily sport or physical job",
            "12500歩超 · 毎日運動または肉体労働"],

        "otter.title": ["TRANSMISSION", "TRANSMISSION", "通信"],
    ]

    // MARK: - Messages de la loutre (50 par langue)

    static let otterFR: [String] = [
        "En 2147, peser sa nourriture est illégal : on la scanne d'un clignement d'œil. Profite du présent.",
        "Conseil temporel : bois de l'eau. Oui, même en l'an 3000 ça marche encore.",
        "Fun fact : en 2231, le brocoli est élu gouverneur de Mars. Mange tes légumes, par diplomatie.",
        "Ton toi de 2090 t'envoie un hologramme : « continue ». Et il a une coupe incroyable.",
        "Astuce de l'an 2500 : marcher 10 000 pas recharge ta combinaison anti-gravité.",
        "Fun fact : dans le futur, les escaliers sont exposés au musée. Profites-en.",
        "Les loutres de l'espace recommandent 8 h de sommeil. La sieste cosmique est surcotée.",
        "En 2099 le sucre se télécharge. En attendant, vas-y mollo sur les biscuits.",
        "Transmission de 3012 : tu orbites parfaitement. Continue.",
        "Fun fact : en 2400, courir après la navette est un sport olympique.",
        "Conseil du futur : un repas équilibré = 3 couleurs. Le gris ne compte pas.",
        "Les archives de 2150 confirment que tu as réussi. Ne fais pas mentir l'Histoire.",
        "Fun fact : dans 200 ans, les miroirs font des compliments. Sois patient.",
        "Alerte temporelle : ton futur toi a oublié pourquoi il s'inquiétait. Respire.",
        "En 3050 la motivation se vend en capsules. La tienne est gratuite : utilise-la.",
        "Fun fact : en 2300, les ascenseurs demandent « tu es sûr ? » avant chaque étage.",
        "Les nutritionnistes de 2180 sont unanimes : le petit-déjeuner existe toujours. Mange-le.",
        "Voyageur temporel, sache-le : en 2222 ton corps te remerciera pour aujourd'hui.",
        "Fun fact : en 2500, l'eau plate gagne enfin contre l'eau gazeuse. Hydrate-toi.",
        "Conseil galactique : étire-toi. Même les robots de 2400 font des étirements.",
        "Fun fact : en 2600, les pas sont une monnaie. Tu es en train de devenir riche.",
        "Ton hologramme de 2070 dit : « la régularité bat la perfection ». Il a raison.",
        "En 2900, les balances ne donnent que des encouragements. Sois ta propre balance gentille.",
        "Fun fact : en 2350, dormir tôt rapporte des points d'expérience.",
        "Les loutres cosmiques le confirment : un petit progrès reste un progrès.",
        "Transmission de 3000 : la planète Snack a été mise en quarantaine. Tu es prévenu.",
        "Fun fact : en 2280, la patience est classée énergie renouvelable.",
        "Conseil de l'an 2450 : compare-toi à toi-même d'hier, jamais aux autres.",
        "En 2199, marcher sous les étoiles soigne presque tout. Sors un peu.",
        "Fun fact : en 2700, les légumes ont leur propre chaîne d'hologrammes. Très populaire.",
        "Ton toi du futur a un message : « merci d'avoir commencé aujourd'hui ».",
        "En 3100, l'abandon a été déclaré démodé. Reste tendance, continue.",
        "Fun fact : en 2333, boire de l'eau débloque un succès secret.",
        "Les archives stellaires disent : tu es plus fort que ton excuse préférée.",
        "Conseil temporel : un verre d'eau avant le repas = +5 en sagesse.",
        "Fun fact : en 2600, le brocoli vaut plus que l'or. Diversifie ton assiette.",
        "En 2088, les jours « sans motivation » comptent double si tu agis quand même.",
        "Transmission urgente : ton futur toi te fait un pouce levé inter-dimensionnel.",
        "Fun fact : en 2450, sourire est obligatoire le mardi. Entraîne-toi.",
        "Les loutres de l'espace disent : repose-toi sans culpabiliser. Le repos est un carburant.",
        "En 2777, la constance est devenue un super-pouvoir. Tu es en train de le développer.",
        "Fun fact : en 2155, les portes te félicitent quand tu sors marcher.",
        "Conseil galactique : mange lentement. En 3000 c'est considéré comme un art.",
        "Ton toi de 2120 confirme : ce petit effort d'aujourd'hui, il s'en souvient encore.",
        "Fun fact : en 2950, l'eau est servie avec un compliment gratuit.",
        "Transmission du futur : tu n'as pas besoin d'être parfait, juste de continuer.",
        "En 2400, on a prouvé scientifiquement qu'un pas de plus ne fait jamais de mal.",
        "Fun fact : en 2280, dormir 8 h donne un bonus de chance pour la journée.",
        "Les archives de 3000 t'observent. Spoiler : elles sourient.",
        "Conseil de loutre cosmique : sois fier de toi aujourd'hui. C'est un ordre du futur.",
    ]

    static let otterEN: [String] = [
        "In 2147, weighing your food is illegal — you scan it with a blink. Enjoy the present.",
        "Temporal tip: drink water. Yes, it still works in the year 3000.",
        "Fun fact: in 2231, broccoli is elected governor of Mars. Eat your veggies, diplomatically.",
        "Your 2090 self sends a hologram: \"keep going.\" And the haircut is amazing.",
        "Tip from 2500: walking 10,000 steps recharges your anti-gravity suit.",
        "Fun fact: in the future, stairs are museum exhibits. Make the most of them.",
        "Space otters recommend 8 hours of sleep. Cosmic naps are overrated.",
        "In 2099 sugar is downloadable. Until then, go easy on the cookies.",
        "Transmission from 3012: you're orbiting perfectly. Carry on.",
        "Fun fact: in 2400, chasing the shuttle is an Olympic sport.",
        "Tip from the future: a balanced meal = 3 colors. Grey doesn't count.",
        "The 2150 archives confirm you succeeded. Don't make History a liar.",
        "Fun fact: in 200 years, mirrors give compliments. Be patient.",
        "Temporal alert: your future self forgot what it worried about. Breathe.",
        "In 3050 motivation is sold in capsules. Yours is free — use it.",
        "Fun fact: in 2300, elevators ask \"are you sure?\" before every floor.",
        "2180 nutritionists agree: breakfast still exists. Eat it.",
        "Time traveler, know this: in 2222 your body will thank you for today.",
        "Fun fact: in 2500, still water finally beats sparkling. Stay hydrated.",
        "Galactic tip: stretch. Even 2400 robots stretch.",
        "Fun fact: in 2600, steps are currency. You're getting rich.",
        "Your 2070 hologram says: \"consistency beats perfection.\" It's right.",
        "In 2900, scales only give encouragement. Be your own kind scale.",
        "Fun fact: in 2350, going to bed early earns experience points.",
        "Cosmic otters confirm: a small step forward is still progress.",
        "Transmission from 3000: planet Snack is under quarantine. You've been warned.",
        "Fun fact: in 2280, patience is classified as renewable energy.",
        "Tip from 2450: compare yourself to yesterday's you, never to others.",
        "In 2199, walking under the stars cures almost everything. Go outside.",
        "Fun fact: in 2700, vegetables have their own hologram channel. Very popular.",
        "Your future self has a message: \"thanks for starting today.\"",
        "In 3100, giving up was declared outdated. Stay trendy, keep going.",
        "Fun fact: in 2333, drinking water unlocks a secret achievement.",
        "The stellar archives say: you're stronger than your favorite excuse.",
        "Temporal tip: a glass of water before meals = +5 wisdom.",
        "Fun fact: in 2600, broccoli is worth more than gold. Diversify your plate.",
        "In 2088, \"no motivation\" days count double if you act anyway.",
        "Urgent transmission: your future self gives an inter-dimensional thumbs up.",
        "Fun fact: in 2450, smiling is mandatory on Tuesdays. Practice.",
        "Space otters say: rest without guilt. Rest is fuel.",
        "In 2777, consistency became a superpower. You're developing it.",
        "Fun fact: in 2155, doors congratulate you for going out to walk.",
        "Galactic tip: eat slowly. In 3000 it's considered an art.",
        "Your 2120 self confirms: today's small effort, it still remembers it.",
        "Fun fact: in 2950, water is served with a free compliment.",
        "Transmission from the future: you don't need to be perfect, just to continue.",
        "In 2400, science proved one more step never hurts.",
        "Fun fact: in 2280, 8 hours of sleep grants a luck bonus.",
        "The 3000 archives are watching you. Spoiler: they're smiling.",
        "Cosmic otter's advice: be proud of yourself today. Future's orders.",
    ]

    static let otterJA: [String] = [
        "2147年、食べ物を量るのは違法。瞬きでスキャンする時代。今を楽しんで。",
        "時を超えた助言：水を飲もう。3000年でも有効だよ。",
        "豆知識：2231年、ブロッコリーが火星知事に当選。外交のため野菜を食べて。",
        "2090年の君からホログラム：「続けて」。髪型が最高だった。",
        "2500年の豆知識：1万歩歩くと反重力スーツが充電される。",
        "豆知識：未来では階段は博物館の展示品。今のうちに使おう。",
        "宇宙ラッコの推奨：睡眠8時間。宇宙昼寝は過大評価。",
        "2099年、砂糖はダウンロード式。それまではお菓子はほどほどに。",
        "3012年からの通信：完璧な軌道だ。その調子。",
        "豆知識：2400年、シャトル追いかけはオリンピック種目。",
        "未来の助言：バランスの良い食事＝3色以上。灰色は数えない。",
        "2150年の記録は君の成功を確認済み。歴史を嘘つきにしないで。",
        "豆知識：200年後、鏡は褒めてくれる。気長に待とう。",
        "時間警報：未来の君は何を心配していたか忘れた。深呼吸を。",
        "3050年、やる気はカプセル販売。君のは無料だ。使おう。",
        "豆知識：2300年、エレベーターは各階で「本当に？」と聞く。",
        "2180年の栄養士は同意見：朝食はまだ存在する。食べよう。",
        "時の旅人よ、知っておいて。2222年、体は今日の君に感謝する。",
        "豆知識：2500年、ついに炭酸水より普通の水が勝つ。水分補給を。",
        "銀河の助言：ストレッチを。2400年のロボットだってやってる。",
        "豆知識：2600年、歩数は通貨。君は今お金持ちになりつつある。",
        "2070年の君のホログラム：「継続は完璧に勝る」。その通り。",
        "2900年、体重計は励ましだけくれる。優しい体重計に君がなろう。",
        "豆知識：2350年、早寝は経験値がもらえる。",
        "宇宙ラッコ公認：小さな前進も前進だ。",
        "3000年からの通信：スナック惑星は隔離中。警告したよ。",
        "豆知識：2280年、忍耐は再生可能エネルギーに分類された。",
        "2450年の助言：他人ではなく昨日の自分と比べよう。",
        "2199年、星空の下を歩くとほぼ何でも治る。外へ出よう。",
        "豆知識：2700年、野菜は専用ホログラム番組を持つ。大人気。",
        "未来の君からメッセージ：「今日始めてくれてありがとう」。",
        "3100年、あきらめは時代遅れと宣言された。流行に乗って続けよう。",
        "豆知識：2333年、水を飲むと隠し実績が解除される。",
        "星々の記録いわく：君はお気に入りの言い訳より強い。",
        "時を超えた助言：食前の水一杯＝知恵+5。",
        "豆知識：2600年、ブロッコリーは金より高価。皿を多様に。",
        "2088年、「やる気ゼロ」の日も行動すれば2倍にカウント。",
        "緊急通信：未来の君が次元を超えた親指サインを送ってる。",
        "豆知識：2450年、火曜は笑顔が義務。練習しよう。",
        "宇宙ラッコいわく：罪悪感なく休もう。休息は燃料だ。",
        "2777年、継続は超能力になった。君は今それを育てている。",
        "豆知識：2155年、散歩に出るとドアが祝福してくれる。",
        "銀河の助言：ゆっくり食べよう。3000年では芸術とされる。",
        "2120年の君が確認：今日の小さな努力、まだ覚えてるよ。",
        "豆知識：2950年、水は無料の褒め言葉付きで提供される。",
        "未来からの通信：完璧じゃなくていい。続けるだけでいい。",
        "2400年、もう一歩は決して無駄にならないと科学が証明した。",
        "豆知識：2280年、8時間睡眠で一日の幸運ボーナス。",
        "3000年の記録が君を見ている。ネタバレ：微笑んでる。",
        "宇宙ラッコの助言：今日の自分を誇りに思おう。未来からの命令だ。",
    ]
}
