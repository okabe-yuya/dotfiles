# my-review 観点別 bad / good 例

SKILL.md のチェックリストのうち、**レビューで繰り返し指摘した頻出観点**だけを bad / good の対比で補足する。
コード例は特定プロダクトの実装に依存しない**汎用化した擬似コード**で、観点そのものを伝えることを目的とする（実際の型名・ドメイン語は載せない）。

観点の網羅はあくまで SKILL.md 本文が担う。ここは「文言だけだと伝わりにくい頻出パターン」の温度感を補うためのもの。

---

## B. ユーザー向け通知はドメイン層でなく UseCase／入口層で（例外で落とさず結果で返す）

**観点**: ドメインモデル・Factory・Repository はビジネス上の成否を戻り値（Result 等）で返すだけにする。ユーザーへエラーを通知するか否かは呼び出し側（UseCase／入口層）の責務。ドメイン層で例外を投げると、呼び出し側は「その例外をどう扱うか」を毎回考えさせられる。

```kotlin
// bad: ドメイン層がユーザー通知と例外送出まで抱えている
class PeriodFactory(private val notifier: UserNotifier) {
    fun create(input: PeriodInput): Period {
        if (input.start > input.end) {
            notifier.notify("期間が不正です")        // ← ドメイン層で通知
            throw IllegalArgumentException("invalid") // ← 例外で呼び出し側に丸投げ
        }
        return Period(input.start, input.end)
    }
}
```

```kotlin
// good: ドメインは成否を Result で返し、通知するかは UseCase が決める
class PeriodFactory {
    fun create(input: PeriodInput): Result<Period, DomainError> {
        if (input.start > input.end) return Result.failure(DomainError.InvalidRange)
        return Result.success(Period(input.start, input.end))
    }
}

class CreatePeriodUseCase(private val factory: PeriodFactory) {
    fun exec(input: PeriodInput): CreateResult =
        when (val r = factory.create(input)) {
            is Result.Success -> { repository.save(r.value); CreateResult.Ok }
            is Result.Failure -> CreateResult.NotifyUser(r.error.message) // 通知は入口側で
        }
}
```

**なぜ**: 「想定内の失敗（不正入力・重複・前提未達）」は例外ではなく型で表現する。通知手段（画面表示 / ログ / 無視）は状況で変わるため、ドメインに固定させず呼び出し側に委ねる。

---

## A. 安易な default 値／default 引数を付けない

**観点**: 入力（API の input・関数引数・データクラスのプロパティ）に `= null` や `= false` などの既定値を反射的に付けない。「使われないかもしれないケース」を見越して nullable／default にすると、値が欠けても既定に流れてしまい意図が隠れる。常に値が必要なら**必須**にする。

```kotlin
// bad: 呼び出し側は常に指定するのに default null にしている
data class ListItemsInput(
    val filter: String,
    val sortOrder: SortOrder? = null, // 表示と別の順序が要る想定は無いのに nullable
)

fun buildQuery(input: ListItemsInput): Query {
    val order = input.sortOrder ?: SortOrder.Default // ← 既定に流れて意図が埋もれる
    // ...
}
```

```kotlin
// good: 常に必要な値は必須にする（欠けたらコンパイル／バリデーションで弾ける）
data class ListItemsInput(
    val filter: String,
    val sortOrder: SortOrder,
)

fun buildQuery(input: ListItemsInput): Query {
    // input.sortOrder は必ず存在する
}
```

**なぜ**: default 値は「呼び出し側が指定を省ける」利点より、「未指定が既定に化けて気づけない」害の方が大きい場面が多い。省略可能にするなら「なぜ省略され得るか」を説明できるときだけにする。

---

## C. 不変条件は init で全経路を守り、ユーザー入力エラーは Factory が Result で拾う

**観点**: 不変条件の検証は `init { require(...) }` に一元化し、全生成経路（`copy` 含む）を守る最後の砦にする。そのうえで、**ユーザーに通知して直させる失敗**（外部入力由来）だけ、Factory／状態遷移メソッドが Result で返して入口層にハンドリングさせる。Factory は検証を書き直さず init の例外を catch して Result に変換する。ID はモデル内部で発行し、外部から渡させない。

判断基準は「**その失敗を直すのは誰か**」。開発者が直す＝バグ（内部の値で本来失敗しない）なら init の例外を境界（500＋ログ）まで飛ばしてよい。ユーザーが直す＝入力ミス等なら、抜け落ちて通知がロストしないよう Result で型に出す。迷ったら Result 側に寄せる。

```kotlin
// bad: init が無く検証が UseCase 側だけ → copy 等の別経路が無検証の抜け道になる
data class Subscription(val id: SubscriptionId, val plan: Plan)

class SubscribeUseCase {
    fun exec(plan: Plan): SubscribeResult {
        if (!plan.isActivatable()) return SubscribeResult.Invalid // 検証がここだけ
        val id = SubscriptionId.random()                          // 外部で採番
        return SubscribeResult.Ok(Subscription(id, plan))         // 不正インスタンスを作れてしまう
    }
}
```

```kotlin
// good: init を砦として常に置き、Factory は init の例外を catch して Result 化。ID は内部発行
data class Subscription private constructor(val id: SubscriptionId, val plan: Plan) {
    init { require(plan.isActivatable()) { "plan not activatable" } } // 全経路(copy含む)を守る

    companion object {
        // ユーザー入力起因の失敗は型で返す。検証ロジックは init に一元化
        fun create(plan: Plan): Result<Subscription, DomainError> =
            try { Result.success(Subscription(SubscriptionId.random(), plan)) }
            catch (e: IllegalArgumentException) { Result.failure(DomainError.InvalidPlan) }
    }
}

class SubscribeUseCase {
    fun exec(plan: Plan): SubscribeResult =
        when (val r = Subscription.create(plan)) {
            is Result.Success -> SubscribeResult.Ok(r.value)
            is Result.Failure -> SubscribeResult.Invalid // 入口層で通知
        }
}
```

**なぜ**: init を残せばどの経路から作っても不変条件が守られる（`copy()` は primary constructor を通るので init を実行する）。検証を init に一元化しておけば Factory は例外を Result に変換するだけで済み、ロジックが二重化しない。「作れたか否か」を型で受け取れるので、ユーザー通知が要る失敗が握りつぶされない。

**失敗の型について**: 原則は sealed な `DomainError` で失敗を表し、ユーザー向け文言は入口層で `DomainError → メッセージ` にマップする（`String` メッセージや `Boolean` で失敗を返さない）。型なら網羅分岐・付随データ・安定したテストが得られ、通知文言をドメインに漏らさずに済む。ただし小さな生成まで厳密に `DomainError` を定義するのは過剰なこともある。**レビューではハードルールにせず、`Result<T, String>` 等で足りるかを都度ユーザーに確認して許容度を決める**温度感で扱う。
