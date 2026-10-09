# weightOtter 🦦

体重とカロリーを記録して、グラフで変化を確認できるiPhoneアプリ
*An iPhone app to log your weight and calories and follow the trend on charts.*

## 機能 / Features

- 体重・カロリーの記録 / weight and calorie logging
- グラフ（Swift Charts）、カロリーは7日間の移動平均でなめらかに / charts with Swift Charts, calories smoothed with a 7-day moving average
- アカウントとクラウド同期（Supabase）。Webアプリと同じデータを共有 / accounts and cloud sync with Supabase, shared with the web version
- 3言語：日本語・英語・フランス語（アプリ内で切り替え、日付とグラフも追従）/ 3 languages, switchable in the app, dates and charts follow
- Google AdMob（同意画面のあとに表示）/ Google AdMob, shown after the consent screen

## 技術 / Tech

- Swift · SwiftUI · Swift Charts
- Supabase（認証・データベース、Row Level Security）/ Supabase auth and database with Row Level Security
- Google Mobile Ads SDK

## 動かし方 / Setup

Supabaseの設定はリポジトリに含めていません。`Secrets.example.swift` を `weightOtter/Secrets.swift` にコピーし、自分のプロジェクトのURLとキーを入れてください。

*The Supabase configuration is not in the repository. Copy `Secrets.example.swift` to `weightOtter/Secrets.swift` and fill in your own project URL and key.*

## 作者 / Author

**Simon Depussay（シモン デプセ）** — [simondepussay.com](https://simondepussay.com)
