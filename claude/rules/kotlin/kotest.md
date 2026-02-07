---
paths:
  - "**/*.kt"
---

# テストルール（Kotest / MockK）

## テストスタイル

- DescribeSpec を標準のテストスタイルとすること
- describe / context / it の構造で記述し、テスト対象の振る舞いを明確にすること

```kotlin
class OrderTest : DescribeSpec({
    describe("注文の作成") {
        context("在庫が十分にある商品の場合") {
            val product = createProduct(stock = 10)

            it("3個注文すると注文が作成される") {
                val order = Order.create(product, quantity = 3)

                order.items shouldHaveSize 1
                order.items.first().quantity shouldBe 3
            }
        }
    }
})
```


## テストの命名

- describe / context / it は日本語で記述すること
- describe: テスト対象の機能や操作を書く（「〜の作成」「〜の検証」）
- context: 前提条件や状況を書く（「〜の場合」「〜が存在するとき」）
- it: 期待される振る舞いを書く（「〜になる」「〜が返される」「〜が発生する」）


## テストの構造

- Arrange-Act-Assert パターンに従うこと
    - Arrange: context ブロック内でテストデータや前提条件を準備する
    - Act・Assert: it ブロック内でテスト対象の操作を実行し、結果を検証する
- 1つの it ブロックでは1つの振る舞いを検証すること
    - 複数の関連するアサーションを含めることは問題ないが、異なる振る舞いの検証は別の it に分けること

```kotlin
// bad: 1つの it で無関係な振る舞いを検証している
it("注文が作成され、メールが送信される") {
    val order = useCase.exec(input)
    order.status shouldBe OrderStatus.CREATED
    mailSender.sentMails shouldHaveSize 1  // 別の振る舞い
}

// good: 振る舞いごとに it を分ける
it("注文が作成される") {
    val order = useCase.exec(input)
    order.status shouldBe OrderStatus.CREATED
}

it("確認メールが送信される") {
    useCase.exec(input)
    mailSender.sentMails shouldHaveSize 1
}
```


## アサーション

- Kotest Matchers を使用すること。JUnit の `assertEquals` 等は使わない
- 基本的なマッチャー:
    - `shouldBe` / `shouldNotBe`: 等価性の検証
    - `shouldBeNull` / `shouldNotBeNull`: null検証
    - `shouldBeInstanceOf<T>()`: 型の検証
    - `shouldThrow<T> { }`: 例外の検証
    - `shouldHaveSize`: コレクションのサイズ検証
    - `shouldContain` / `shouldContainExactly`: コレクションの要素検証

```kotlin
// bad
assertEquals(expected, actual)
assertTrue(result is Order.Submitted)

// good
actual shouldBe expected
result.shouldBeInstanceOf<Order.Submitted>()
```

- 例外の検証では `shouldThrow` を使い、メッセージや型を検証すること

```kotlin
val exception = shouldThrow<IllegalArgumentException> {
    Email("invalid")
}
exception.message shouldBe "不正なメールアドレス: invalid"
```


## テストデータ

- テストデータの生成にはファクトリ関数を使うこと
- ファクトリ関数はデフォルト引数を持ち、テストで注目するパラメータだけを指定できるようにすること
- ファクトリ関数の命名は `create{ドメインモデル名}` とすること

```kotlin
// テストデータのファクトリ関数
fun createUser(
    id: UserId = UserId(UUID.randomUUID()),
    name: String = "テストユーザー",
    email: Email = Email("test@example.com"),
): User = User(id = id, name = name, email = email)

// テストでは注目するパラメータだけを指定する
context("メールアドレスが未認証のユーザーの場合") {
    val user = createUser(email = Email("unverified@example.com"))
}
```

- 複数のテストクラスで共通利用するファクトリ関数は、テスト用のヘルパーファイルに切り出すこと


## モック（MockK）

### 基本方針

- モックは DI で注入される依存（Repository, 外部サービスなど）に対して使用すること
- テスト対象のロジック自体をモックにしない
- ドメインモデルはモックせず、ファクトリ関数で実際のインスタンスを生成すること

```kotlin
// bad: テスト対象のドメインモデルをモックしている
val order = mockk<Order>()
every { order.totalAmount } returns Money(1000)

// good: 実際のインスタンスを使う
val order = createOrder(totalAmount = Money(1000))
```

### every / verify の使い分け

- `every`: テスト対象が依存を呼び出す際の戻り値をスタブする
- `verify`: テスト対象が依存を正しく呼び出したことを検証する
- 戻り値の設定が不要な場合は `justRun` を使うこと

```kotlin
class PlaceOrderUseCaseTest : DescribeSpec({
    val orderRepository = mockk<OrderRepository>()
    val eventPublisher = mockk<DomainEventPublisher>()
    val useCase = PlaceOrderUseCase(orderRepository, eventPublisher)

    describe("注文の確定") {
        context("有効な注文情報の場合") {
            val input = createPlaceOrderInput()
            every { orderRepository.save(any()) } just Runs
            every { eventPublisher.publishAll(any()) } just Runs

            it("注文がリポジトリに保存される") {
                useCase.exec(input)
                verify(exactly = 1) { orderRepository.save(any()) }
            }

            it("ドメインイベントが発行される") {
                useCase.exec(input)
                verify(exactly = 1) { eventPublisher.publishAll(any()) }
            }
        }
    }
})
```

### relaxed モック

- `relaxed = true` は使用しても良い
    - ただし、ロジックに関係するメソッドに関しては、明示的に `every` でスタブを定義する


## テストの独立性

- テスト間で状態を共有しないこと。各テストは独立して実行可能であること
- `beforeEach` / `afterEach` を活用してテストごとに状態をリセットすること
- モックの状態リセットには `clearMocks` を使うこと

```kotlin
class UserServiceTest : DescribeSpec({
    val userRepository = mockk<UserRepository>()

    beforeEach {
        clearMocks(userRepository)
    }

    // 各 describe / context ブロックは独立して実行可能
})
```

- テストの実行順序に依存するテストを書かないこと


## Property-based Testing

- 境界値や多様な入力パターンの検証に Kotest の Property-based Testing を活用すること
- `checkAll` と `Arb`（Arbitrary）を使用する
- 以下のようなケースで有効:
    - Value Object のバリデーション
    - 変換ロジックの可逆性（エンコード → デコードで元に戻ること）
    - 数値計算の性質（結合法則、交換法則など）

```kotlin
class MoneyTest : DescribeSpec({
    describe("金額の加算") {
        it("加算の順序を変えても結果は同じになる（交換法則）") {
            checkAll(Arb.int(0..1_000_000), Arb.int(0..1_000_000)) { a, b ->
                Money(a) + Money(b) shouldBe Money(b) + Money(a)
            }
        }
    }
})
```

- すべてのテストで Property-based Testing を使う必要はない。具体的な例示で十分なケースでは通常のテストを優先すること

