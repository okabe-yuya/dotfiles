---
paths:
  - "**/*.kt"
  - "**/*.kts"
---

# コーディングルール（Kotlin）

## 基本方針

- Kotlin公式のコーディング規約に従うこと: https://kotlinlang.org/docs/coding-conventions.html


## Null安全

- `!!`（非nullアサーション）は原則使用禁止。安全呼び出し（`?.`）やエルビス演算子（`?:`）を使うこと
- nullが返る可能性のある箇所では、呼び出し側で適切にハンドリングすること

```kotlin
// bad
val name = user!!.name

// good
val name = user?.name ?: throw IllegalStateException("User must not be null")
```


## データクラス

- 値の保持を目的とするクラスには`data class`を使うこと
- Value Objectは`data class`で表現し、`init`ブロックでバリデーションを行うこと


## value class

- rules/conding-ddd.mdを参考に値オブジェクトを定義する場合に、単一のIDを定義する際は`value class`を使うこと

```kotlin
value class UserId(val value: UUID) {

}
```

## スコープ関数

- スコープ関数（`let`, `run`, `apply`, `also`, `with`）のネストは避けること
- 各スコープ関数の使い分けを意識すること
    - `let`: null安全な変換処理
    - `apply`: オブジェクトの初期化・設定
    - `also`: 副作用（ログ出力など）
    - `run`: オブジェクトに対する処理と結果の取得
    - `with`: 戻り値が不要な場合のオブジェクト操作


## 拡張関数

- 拡張関数はドメインの意味がある場合にのみ定義すること。便利だからという理由で乱用しない
- 既存クラスの責務を超える処理を拡張関数にしないこと
- 基本的にはドメインモデルにメソッドをロジックとして定義すること
    - 拡張関数とするのはコンテキストによってロジックが発生するようなケースだけに留めること


## コレクション操作

- `for`ループよりも`map`, `filter`, `flatMap`などの関数型操作を優先すること
- ただしチェーンが長くなりすぎる場合は可読性を考慮して中間変数を使うこと
- `Sequence`の使用はコレクションのサイズが大きい場合に検討すること


## 例外処理

- 業務例外はsealed classで表現することを検討すること
    - 無理に全てを型とする必要はない。アプリケーション・UseCase層で例外を発生させるような場合は不要である
- `runCatching`を使う場合、エラーを握りつぶさないこと（全言語共通ルール参照）

```kotlin
// 業務例外をsealed classで表現する例
sealed class OrderError {
    data class NotFound(val orderId: OrderId) : OrderError()
    data class AlreadyCancelled(val orderId: OrderId) : OrderError()
}
```


## sealed interfaceによる状態の型表現

- 同じドメイン概念でもライフサイクルの段階ごとにデータ構造や振る舞いが異なる場合、`sealed interface`で状態を分離すること
    - 1つのクラスに全状態のプロパティを持たせてnullableで管理しない
    - 各状態でのみ有効なプロパティ・操作を型で保証する
- 境界づけられたコンテキスト（coding-ddd.md参照）の文脈でも、コンテキストごとに同名の概念が異なるモデルを持つ場合に活用すること

```kotlin
// bad: 全状態を1クラスで表現し、nullableで管理する
data class Order(
    val id: OrderId,
    val items: List<OrderItem>,
    val submittedAt: Instant?,   // 発注前はnull
    val completedAt: Instant?,   // 発注後までnull
    val status: OrderStatus,
)

// good: 状態ごとに型を分離する
sealed interface Order {
    val id: OrderId
    val items: List<OrderItem>

    /** 発注前: カートに入っている状態 */
    data class Draft(
        override val id: OrderId,
        override val items: List<OrderItem>,
    ) : Order {
        fun submit(): Submitted {
            require(items.isNotEmpty()) { "空の注文は発注できない" }
            return Submitted(id, items, submittedAt = Instant.now())
        }
    }

    /** 発注中: 処理待ちの状態 */
    data class Submitted(
        override val id: OrderId,
        override val items: List<OrderItem>,
        val submittedAt: Instant,
    ) : Order {
        fun complete(): Completed =
            Completed(id, items, submittedAt, completedAt = Instant.now())
    }

    /** 発注後: 完了した状態 */
    data class Completed(
        override val id: OrderId,
        override val items: List<OrderItem>,
        val submittedAt: Instant,
        val completedAt: Instant,
    ) : Order
}
```

- `when`式で全状態を網羅的にハンドリングできるため、状態の追加時にコンパイラが漏れを検出してくれる


## sealed interface + when による網羅性チェック

- `sealed interface`（または`sealed class`）を`when`式と組み合わせる場合、`else`を書かないこと
    - `else`があると新しい状態を追加してもコンパイルエラーにならず、実装漏れが検出できなくなる
- `when`式の結果を変数に代入するか、戻り値として返すことで網羅性チェックをコンパイラに強制させること

```kotlin
// bad: elseがあるため、新しい状態を追加してもコンパイルが通ってしまう
fun handleOrder(order: Order) {
    when (order) {
        is Order.Draft -> { /* ... */ }
        is Order.Submitted -> { /* ... */ }
        else -> { /* ... */ }
    }
}

// good: 全状態を明示的に列挙し、戻り値で網羅性をコンパイラに強制する
fun handleOrder(order: Order): String =
    when (order) {
        is Order.Draft -> "下書き"
        is Order.Submitted -> "発注済み"
        is Order.Completed -> "完了"
        // 新しい状態が追加されるとここでコンパイルエラーになる
    }
```

- この手法は状態だけでなく、業務例外（sealed classによるエラー型）やドメインイベントの分岐にも同様に適用すること


## コルーチン

- コルーチンのスコープを適切に管理すること。`GlobalScope`は使用しない
- `suspend`関数はIOやネットワーク呼び出しなど、本当に非同期処理が必要な場合にのみ使うこと

## 避けるべき記述

- filterIsInstanceは便利ですが、新たな実装クラスの追加時にコンパイルエラーとならず網羅性チェックが漏れるため、仕様を避けること
    - when を使った網羅性チェックを用いてコードを書くこと
    - elseを使うのは{A, B, C}からAだけを扱いたいようなケースに限定すること

