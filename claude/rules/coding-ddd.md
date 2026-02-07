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


## Domain Service

- 特定のEntityやValue Objectに属さないドメインロジックを配置すること
- 状態を持たないこと（ステートレス）
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

