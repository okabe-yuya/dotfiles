# DDD ルール

## Entity

- 一意な識別子（ID）を持ち、ライフサイクルを通じて同一性が保たれるオブジェクトとして設計すること
- ビジネスロジックはEntityの内部に持たせること。外部から状態を取り出して操作しない
- setterを安易に公開しない。状態の変更はビジネス上の意味を持つメソッドを通じて行うこと

```kotlin
// bad
user.name = "new name"

// good
user.changeName("new name")
```

- Entityの等価性はIDで判断すること。プロパティの一致で比較しない
- 不変条件（invariant）は`init`ブロックで検証し、不正な状態のEntityが存在できないようにすること
    - バリデーションをサービス側に置くと、別の生成経路で検証が漏れるリスクがある

```kotlin
// bad: サービス側でバリデーション
class ApplyOverwriteService {
    fun apply(invoice: Invoice, amount: BigInteger) {
        require(amount >= BigInteger.ZERO) // ここでしか守られない
        val overwrite = InvoiceOverwrite(amount = amount)
    }
}

// good: Entity自身が不変条件を保証
data class InvoiceOverwrite(val amount: BigInteger) {
    init {
        require(amount >= BigInteger.ZERO) { "上書き額は0以上である必要があります" }
    }
}
```

- nullable なプロパティを暗黙のデフォルト値で埋めないこと。ドメイン上「なぜ null になりうるか」が隠れる
    - null を許容するならドメインモデルの型で明示し、利用側で意図的に扱う

```kotlin
// bad: null を握りつぶしてデフォルト値で埋める
val amount = invoice.burdenAmount ?: BigInteger.ZERO

// good: nullable のまま型で表現し、必要なら不変条件で明示的に弾く
data class InvoiceOverwrite(
    val originalBurdenAmount: BigInteger?,
) {
    init {
        require(originalBurdenAmount != null) { "負担額が存在しない請求には適用できません" }
    }
}
```


## Value Object

- 識別子を持たず、属性の値そのものが意味を持つオブジェクトとして設計すること
- 不変（immutable）であること。生成後に状態を変更しない
- 等価性は全属性の一致で判断すること
- 自身のバリデーションは生成時に行い、不正な状態のValue Objectが存在できないようにすること

```kotlin
// bad
val email = "invalid"  // 文字列のまま扱う

// good
data class Email(val value: String) {
    init {
        require(value.matches(EMAIL_REGEX)) { "不正なメールアドレス: $value" }
    }
}
```

- プリミティブ型をそのまま使い回さないこと。ドメインの意味がある値はValue Objectとして表現する
- メソッドの引数型で事前条件を表現すること。呼び出し側で null チェック済みなら、受け取る側は non-null にする
    - 「null が来たら何もしない」というロジックをメソッド内部に持たせず、型レベルで制約する

```kotlin
// bad: 呼び出し側で null チェックしているのに、受け取る側も nullable
fun apply(amount: BigInteger?) {
    if (amount == null) return
    // ...
}

// good: 型で事前条件を表現
fun apply(amount: BigInteger) {
    // amount は non-null が保証されている
}
```


## Aggregate

- トランザクション整合性の境界を定義する単位として設計すること
- Aggregate Rootを通じてのみ内部のEntityやValue Objectにアクセスする
- 外部から内部オブジェクトへの直接参照を持たないこと
- Aggregate間の参照はIDで行い、オブジェクト参照を直接持たないこと

```kotlin
// bad
order.items[0].product.category.name  // Aggregateの境界を越えた深い参照

// good
val productId = orderItem.productId
val product = productRepository.findById(productId)
```

- Aggregateは可能な限り小さく保つこと。大きくなりすぎる場合は境界の見直しを検討する


## Repository

- Aggregateの永続化と取得を担うインターフェースとして定義すること
- Repositoryのインターフェースはドメイン層に置き、実装はインフラ層に置くこと
- コレクションのように振る舞うインターフェースを提供すること（`find`, `save`, `delete` など）
- クエリの都合でドメインモデルを歪めないこと。参照系で複雑な取得が必要な場合は専用のQueryServiceを検討する
    - QueryServiceはUseCase層にinterfaceを定義して、実装はインフラ層におくこと

```kotlin
// ドメイン層
interface UserRepository {
    fun findById(id: UserId): User?
    fun save(user: User)
}

// インフラ層
class UserRepositoryImpl(...) : UserRepository {
    override fun findById(id: UserId): User? { ... }
    override fun save(user: User) { ... }
}
```

- 永続化には`save`メソッドを公開すること。引数にはドメインモデルを受け取る
    - 必要であれば、createdUserIdやupdatedUserIdを第2・3引数で受け取っても良いです
    - saveメソッドの実装クラスでは、`upsert`を使うこと
    - 保存・更新はこの`save`メソッドで完結させること

- Repositoryの実装クラスでは、別のRepositoryを使わないこと
    - Aggregateの原則に違反している
    - 別のRepositoryが必要ということは集約を正しく表現できていないということになる


## ファクトリ

- ドメインモデルの生成ロジックはモデル自身に持たせること（`companion object` のファクトリメソッド）
    - 生成時に必要な知識がモデルに集約され、外部から組み立ての詳細を知る必要がなくなる
    - 複数の生成経路がある場合も、ファクトリメソッドを分けることで意図が明確になる
- 外部のサービスがコンストラクタに個々のフィールドを渡して直接生成するのは避けること

```kotlin
// bad: サービス側で各フィールドを組み立てて直接生成
val overwrite = InvoiceOverwrite(
    id = InvoiceOverwriteId.random(),
    originalAmount = invoice.totalAmount,
    burdenAmount = invoice.burdenAmount,
    overwriteAmount = newAmount,
    createdBy = userId,
    createTime = now,
)

// good: ファクトリメソッドに生成責務を集約
val overwrite = InvoiceOverwrite.create(
    invoice = invoice,
    overwriteAmount = newAmount,
    userId = userId,
    now = now,
)
```


## Domain Service

- 特定のEntityやValue Objectに属さないドメインロジックを配置すること
- 状態を持たないこと（ステートレス）
    - 時刻（`Clock`）のような環境依存値をインスタンス変数に持たせない。メソッド引数（`Instant`）で受け取ることで、テスト容易性を確保する

```kotlin
// bad: Clock をインスタンス変数に持つ
class ApplyOverwriteService(private val clock: Clock) {
    fun apply(invoice: Invoice) {
        val now = clock.instant()
    }
}

// good: Instant をメソッド引数で受け取る
class ApplyOverwriteService {
    fun apply(invoice: Invoice, now: Instant) {
        // now を直接使う
    }
}
```

- 安易にDomain Serviceを作らないこと。まずEntityやValue Objectに配置できないか検討する

```kotlin
// Entity単体では判断できないビジネスルールの例
class TransferService(
    private val accountRepository: AccountRepository,
) {
    fun transfer(from: AccountId, to: AccountId, amount: Money) {
        // 2つのAggregateにまたがる処理
    }
}
```


## Application Service

- ユースケースの調整役として設計すること。ドメインロジックは含めない
- トランザクション管理はこの層で行うこと
- ドメインオブジェクトの生成・取得・操作の呼び出し・永続化の流れを調整する

```kotlin
class CreateOrderUseCase(
    private val orderRepository: OrderRepository,
    private val productRepository: ProductRepository,
) {
    fun exec(input: CreateOrderInput): CreateOrderOutput {
        // 1. 必要なドメインオブジェクトを取得
        val product = productRepository.findById(input.productId)
            ?: throw NotFoundException("Product not found")

        // 2. ドメインロジックを実行
        val order = Order.create(product, input.quantity)

        // 3. 永続化
        orderRepository.save(order)

        return CreateOrderOutput(order.id)
    }
}
```


## デメテルの法則（最小知識の原則）

- 外部からはドメインモデルの直接のプロパティだけを参照すること
    - ドメインモデルの内部では参照することは問題ない
    - しかし、プロパティがエンティティや値オブジェクトとして定義されている場合は、そちらに定義すること
- メソッドチェーンで深くアクセスするコードはこの法則に違反している可能性が高い

```kotlin
// bad: 3段階以上のメソッドチェーン
val cityName = order.customer.address.city.name

// good: 必要な情報を直接提供するメソッドを定義する
val cityName = order.shippingCityName()
```

- 違反を見つけた場合は、責務の配置が適切かを見直すこと


## 凝集度

- 1つのクラス・モジュールは1つの責務に集中させること
- 関連するデータとそれを操作するロジックは同じ場所に配置すること
- クラスのフィールドのうち、一部のメソッドでしか使われないものが多い場合は凝集度が低い兆候。クラスの分割を検討する
- ドメインロジックがApplication ServiceやControllerに漏れ出している場合は、ドメインオブジェクトに移動すること


## レイヤー構造

- 依存の方向は常に外から内へ。ドメイン層は他の層に依存しない
    - 典型的な構成: Controller → Application Service → Domain → Infrastructure（実装）
- ドメイン層にフレームワーク固有のアノテーションやライブラリを持ち込まないこと
- 層をまたぐデータの受け渡しにはDTOやInput/Outputクラスを使い、ドメインオブジェクトを直接外部に公開しないこと


## ユビキタス言語

- ドメインエキスパートと開発者が共通して使う用語をコード上でもそのまま使うこと
- クラス名、メソッド名、変数名はユビキタス言語に基づいて命名すること
    - 開発者都合の技術用語（`data`, `info`, `manager`, `handler`など）を安易にドメインの名前として使わない
    - 例えば「注文」を扱うなら`OrderManager`ではなく、ドメインの言葉で`Order`, `OrderService`とすること
- ユビキタス言語に存在しない概念をコードに導入する場合は、まずドメインエキスパートと用語を合意すること
- プロジェクト内で同じ概念に対して複数の呼び方が混在しないよう統一すること
    - 例: 「顧客」と「ユーザー」が同じ概念を指しているなら、どちらか一方に統一する
- ユビキタス言語が変わった場合は、コード上の命名もリネームすること。古い用語を残さない


## ドメインイベント

### 基本方針

- ドメイン上で起きた重要な出来事をイベントとして明示的に表現すること
- イベント名は過去形で命名する: `OrderPlaced`, `PaymentCompleted`, `UserRegistered`
- イベントは不変（immutable）であること。発生した事実を表すため、後から変更しない
- イベントには発生日時と、そのイベントを理解するために必要な最小限の情報を含めること

```kotlin
data class OrderPlaced(
    val orderId: OrderId,
    val customerId: CustomerId,
    val totalAmount: Money,
    val occurredAt: Instant,
)
```

### Publish（発行）

- イベントの発行はAggregate内のドメイン操作の結果として行うこと
- Application Service（UseCase）がイベントの発行を調整しても良いが、「何のイベントを発行すべきか」の判断はドメイン層に持たせること
- 永続化とイベント発行の整合性に注意すること
    - 同一トランザクション内で永続化とイベント発行を行うか、Outboxパターンなどで結果整合性を担保すること
    - イベントが発行されたのに永続化が失敗する、またはその逆が起きないようにすること

```kotlin
// Aggregate内でイベントを生成する例
class Order private constructor(...) {
    private val domainEvents = mutableListOf<DomainEvent>()

    fun place(): Order {
        // ビジネスロジック
        domainEvents.add(OrderPlaced(id, customerId, totalAmount, Instant.now()))
        return this
    }

    fun occurredEvents(): List<DomainEvent> = domainEvents.toList()
}

// Application Serviceでイベントを発行する
class PlaceOrderUseCase(
    private val orderRepository: OrderRepository,
    private val eventPublisher: DomainEventPublisher,
) {
    fun exec(input: PlaceOrderInput) {
        val order = Order.create(input).place()
        orderRepository.save(order)
        eventPublisher.publishAll(order.occurredEvents())
    }
}
```

### Subscribe（購読）

- イベントハンドラは1つのイベントに対して1つの責務を持つようにすること
- ハンドラの命名は `{処理内容}When{イベント名}DomainEventHandler` の形式に従うこと
    - ハンドラ名を読むだけで「どのイベントをきっかけに」「何をするか」がわかるようにする

```kotlin
// bad: 何のイベントに反応するか、何をするかが名前から読み取れない
class SendOrderConfirmationEmail : DomainEventHandler<OrderPlaced>

// good: イベント名と処理内容がクラス名に含まれている
class SendConfirmationEmailWhenOrderPlacedDomainEventHandler
    : DomainEventHandler<OrderPlaced>

class ValidateOrAddBuyerAggregateWhenOrderStartedDomainEventHandler
    : DomainEventHandler<OrderStartedDomainEvent>
```

- ハンドラ内では別のAggregate操作や外部システム連携を行って良いが、元のAggregateを直接変更しないこと
- イベントハンドラの処理が失敗した場合のリトライ戦略を考慮すること
    - 冪等性を担保し、同じイベントが複数回処理されても問題ないようにすること
- 同期的に処理すべきか非同期で良いかを判断すること
    - 即座に整合性が必要 → 同期処理
    - 結果整合性で十分 → 非同期処理（メッセージキュー等）

