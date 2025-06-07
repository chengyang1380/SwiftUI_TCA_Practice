# SwiftUI_TCA_Practice

![New Zealand — Deer Park Heights Queenstown](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20+%20TCA%20(Onevcat)/IMG_8286.jpg?raw=true)

New Zealand — Deer Park Heights Queenstown

這篇是閱讀了喵神的文章 [TCA - SwiftUI 的救星？](https://onevcat.com/2021/12/tca-1/)，這一系列喵神分成了四篇來講解，每篇都有許多重點，而且也是從易到難，很好閱讀，以下是個人的學習筆記，內容幾乎原文搬過來的，但也有一些是學習過程中額外補充的，因為有語法的更新，所以建議可以先閱讀原文，假如遇到語法不支援之類的問題，在參考這邊。

以下程式碼語法已更新至 TCA [v1.20.2](https://github.com/pointfreeco/swift-composable-architecture/releases/tag/1.20.2) 

附上完整 [demo](https://github.com/chengyang1380/SwiftUI_TCA_Practice)，使用 Xcode 16.4

# 第一章

### 前言

從2019年發表 SwiftUI 至今，也要6年的歷史了，Apple 發表至今沒有給他特定的架構，例如以前的 UIKit 有 MVC 架構。

官方很多教學，有[資料傳遞](https://developer.apple.com/tutorials/app-dev-training/passing-data-with-bindings)，也有[狀態管理](https://developer.apple.com/tutorials/app-dev-training/managing-state-and-life-cycle)，但似乎也不夠指導我們寫出穩定的 app。

在 SwiftUI 中做到了 single source of truth: 所有的 View 都是由狀態變化出來的，但是也有一些問題，例如：

- 在使用時數據管理是個人覺得學習門檻比較高的地方，因為有各種狀態的屬性包裝器(Property Wrapper)要先搞懂，像是 `@State, @Binding, @StateObject, @ObservedObject, @EnvironmentObject`  之類的，假如沒有先搞清楚他們的特性，很多時候是不知道如何正確使用。
- 很多修改狀態的程式碼室內檻在 `View.body` 內，或者只能在 `body` 中和其他 View 的程式碼混雜再一起。而且同一個狀態可能會被多個不相關的 View 直接修改(例如： `@Binding`)，這些修改難以追蹤定位，在 app 很複雜的情況下簡直是噩夢。
- 測試困難，這點有一點反直覺，因為 SwiftUI 框架的 View 是由狀態決定的，所以理論上我們只需要測試狀態（也就是 Model 層），這應該是很容易的事，但是照著 Apple 官方教學來看，app 中會有許多 private 狀態，這些難以 Mock，而且就算可以，如何測試對這些狀態修改也是問題。

簡單地克服方法當然也有，把各種狀態的屬性包裝器完全搞懂，盡可能減少共享可變狀態來避免被意外修改，或者按照 Apple 的[推薦](https://developer.apple.com/videos/play/wwdc2019/233/)準備一組 preview 的數據，然後打開 View 文件去挨個檢查 preview 的結果，但是還是有些自動化的[工具](https://www.kodeco.com/24426963-snapshot-testing-tutorial-for-swiftui-getting-started)可以協助

但結論就是我們需要一種架構，讓使用 SwiftUI 更容易輕鬆。

### 從 Elm 啟發

---

Elm 架構 ( The Elm Architecture, TEA)

![image.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/image.png?raw=true)

1. 在 View 上做某個操作（例如點擊某個按鈕），這時會以消息的方式傳送。在 Elm 中的某種機制將會捕獲到這消息。
2. 偵測到新消息來時，它會和當前 `Model` 一起作為輸入傳遞給 `update` 函數。這個函數通常是開發者需要花費時間最多的部分，控制 app 狀態的變化。是 Elm 架構的核心，需要根據輸入的消息和狀態，演算出新的 `Model` 。
3. 這個新的 `Model` 將替換原有的 `Model` ，並準備在下一個 `msg` 到來時，再次重複上面的過程，去捕獲新的狀態。
4. Elm 執行時負責在得到新 `Model` 後呼叫 `View` 函數，渲染出結果。用戶可以透過他再次發送新的消息，重複上面的循環。

目前對 TEA 有基本的了解，我們回頭看一下 SwiftUI 中的實現，就像步驟4一樣：當 `@State` 或 `@ObservedObject` 的 `@Published` 發生變化時，SwiftUI 會自動呼叫 `View.body` 為我們渲染新畫面。

### 簡單範例

---

一個很簡單的範例，功能就是有一個數字，可以分別用加和減按鈕控制，使用 SwiftUI + TCA 做法如下：

```swift
// logic
@Reducer
struct Counter {

    @Dependency(\.counterEnvironment) var environment

    @ObservableState
    struct State: Equatable {
        var count: Int = 0
    }

    enum Action {
        case increment
        case decrement
    }
    
    struct Environment {}
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .decrement:
                state.count -= 1
            case .increment:
                state.count += 1
            }
            return .none
        }
    }
}

extension DependencyValues {
    var counterEnvironment: Counter.Environment {
        get { self[Counter.Environment.self] }
        set { self[Counter.Environment.self] = newValue }
    }
}

// view
struct CounterView: View {

    @Bindable var store: StoreOf<Counter>

    var body: some View {
        HStack {
            Button("-") { store.send(.decrement) }
            Text("\(store.count)")
            Button("+") { store.send(.increment) }
        }
    }
}

#Preview {
    CounterView(
        store: Store(initialState: Counter.State()) {
            Counter()
        }
    )
}
```

**我們先看最核心的 Reducer：**

1. 發送訊息，而非直接改變狀態：
任何操作，都向 `store` 發送 `Action` ，而 `Action` 適合用 enum 定義。
2. 只在 Reducer 中改變狀態：
`Reducer` 是邏輯核心，也是 TCA 中最靈活的地方，所以狀態的改變，應在 `Reducer` 中完成，他的初始化是長這樣：

```swift
public func reduce(
    into state: inout Body.State, action: Body.Action
) -> Effect<Body.Action>
```

`inout` 的 `State` 讓我們可以「原地」對 `state` 進行變更，而不需要明確地返回它。這個函數的回傳值是一個 `Effect`，它代表不應該在 Reducer 中的副作用，例如 API 請求，取得當前時間等。

但記得在非同步的事件，例如 API 請求，我們通常會寫 `.run { send in ... }` ，不要在這裡面直接改變狀態，應該要由一個 Action 來改變，所以通常 call API 後的結果處理會有兩個 Action ( Success 和 Failure）。

1. 更新狀態並觸發渲染：
在 Reducer 閉包中改變狀態是合法的，新的狀態將被 TCA 用來觸發 view 的渲染，保存下來等待下一次 Action 到來。

**Reducer 的核心是純函式特性**

- Action 一般來說就像 User 的某個操作，例如點擊按鈕
- Environment 提供依賴解決了 reducer **輸入階段**的副作用（比如 reducer 需要獲取某個 `Date` 等），這很關鍵，Dependency injection (依賴注入)都從這來做。
- Effect 解決的則是 reducer **輸出階段**的副作用，如果在 Reducer 接收到某個行為之後，需要做出非狀態變化的反應，比如發送一個網路請求、向硬碟寫一些數據，或是監聽某個通知等，都需要透過 Effect 進行。
- Effect 定義了需要在純函數外執行的程式碼，以及處理結果的方式：一般來說這個執行過程會是一個耗時的行為，行為的結果通過 `Action` 的方式在未來某個時間再次觸發 reducer 並更新最終狀態。
- TCA 在運行 reducer 的程式碼，並獲取到返回的 `Effect` 後，負責執行它所定義的程式碼，然後按照需要發送新的 `Action` 。

### **Debug & Test**

---

在 TCA 中有非常方便的 `debug()` 方法，打印出接收到 Action 以及其中 State 的變化

```swift
 var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            ...
            }
        }
        ._printChanges()
    }
```

![image.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/image%201.png?raw=true)

而且他只有在 `#if DEBUG` 的編譯條件下打印

```swift
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct CounterTests {

    @Test
    func increment() async throws {
      let store = TestStore(initialState: Counter.State()) {
            Counter()
        }
        await store.send(.increment) {
            $0.count = 1
        }
    }
}
```

假設出錯的話，故意寫一個錯誤的測試

```swift
    @Test
    func increment() async throws {
        await store.send(.increment) {
            $0.count = 2
        }
    }
```

![Screenshot 2025-03-31 at 18.15.02.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/Screenshot_2025-03-31_at_18.15.02.png?raw=true)

也可以很好 debug，一目瞭然

另外官方建議測試的 store 都是各自獨立，不要寫成共享的 gloabl 變數

```swift
@MainActor
 struct FeatureTests {
   // 👎 Don't do this:
-  let store = TestStore(initialState: Feature.State()) {
-    Feature()
-  }

   @Test
   func basics() async {
     // 👍 Do this:
+    let store = TestStore(initialState: Feature.State()) {
+      Feature()
+    }
     // ...
   }
 }
```

原因：

- 這樣可以確保**每個測試都有乾淨的初始狀態**，避免受其他測試影響。
- 你可以根據不同的測試需求，**精確地設定 `initialState` 和 `dependencies`**。
- 假如真的需要用 global 變數共享，記得每個測試使用完要 `await store.finish()`

### **Store 和 ViewStore**

---

切分 Store 避免不必要的 view 更新， `Store` 是狀態持有者，同時也負責在運行的時候連結 `State` 和 `Action` 。Single source of truth 是狀態驅動 UI 的最基本原則之一，由於這個要求，我們希望持有狀態的角色只有一個。因此很常見的選擇是，一整個 app 只有一個 `Store` 。UI 對這個 `Store` 進行觀察。UI 對這 Store 進行觀察 (比如透過將它設置為 `@ObservedObject`)，攫取它们所需要的狀態，並對狀態的變化做出響應。

![image.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/image%202.png?raw=true)

通常一個 `Store` 會存在非常多的狀態，但是具體的 `View` 一般只需要其中一個很小的子集。比如上圖中 View1 只需要 Sate1 不需要知道 State2

如果讓 `View` 直接觀察整個 `Store` ，某個狀態發生變化時，SwiftUI 將會要求所有對 `Store` 進行觀察的 UI 更新，這樣就造成所有的 view 都對 `body` 進行重新渲染，是非常消耗資源的。
（這讓我聯想到 iOS 17 後 Apple 推出 `Observation` ，也是一樣的道理，原本使用 `ObservableObject` 的 Model，假如有更新時，會更新的 UI，效能較差，但新的 `Observation` 不會）

例如下圖的 State 2 發生了變化，但是不依賴 State 2 的 View 1 和 View 1-1 只是因為觀察了 Store，也會由於 `@ObservedObject` 的特性，重新對 `body` 進行求值：

![image.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/image%203.png?raw=true)

而 TCA 為了避免這問題，把傳統意義的 `Store` 進行拆分，發明了 `ViewStore` 的概念：

`Store` 依然是狀態的實際管理者和持有者，它代表了 app 狀態的 **純數據層** 的表示。在 TCA 的使用者來看 `Store` 最重要的功能，是對狀態進行切分

程式碼

```swift
// state:
struct State1 {
  struct State1_1 {
    var foo: Int
  }
  
  var childState: State1_1
  var bar: Int
}

struct State2 {
  var baz: Int
}

struct AppState {
  var state1: State1
  var state2: State2
}

let store = Store(
  initialState: AppState( /* */ ),
  reducer: appReducer,
  environment: ()
)
```

在將 Store 傳遞給不同頁面使用時，可以用 .scope 將其「切分」，這在後面章節會再詳細說明

```swift
let store: Store<AppState, AppAction>

var body: some View {
  TabView {
    View1(
      store: store.scope(
        state: \.state1, action: AppAction.action1
      )
    )
    View2(
      store: store.scope(
        state: \.state2, action: AppAction.action2
      )
    )
  }
}
```

這樣就可以限制每個頁面能夠訪問到的狀態，抱持清晰。

![image.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/image%204.png?raw=true)

```swift
struct CounterView: View {
  let store: Store<Counter, CounterAction>
  var body: some View {
    WithViewStore(store) { viewStore in
      HStack {
        Button("-") { viewStore.send(.decrement) }
        Text("\(viewStore.count)")
        Button("+") { viewStore.send(.increment) }
      }
    }
  }
}
```

TCA 透過 `WithViewStore` 來把一個代表純資料的 Store 轉換成 SwiftUI 可觀測的資料。不出意外，當 `WithViewStore` 接受的閉包滿足 View 協議時，它本身也將滿足 View，這也是為什麼我們能在 CounterView 的 body 直接用它來構建一個 View 的原因。 `WithViewStore` 這個 view，在內部持有一個 `ViewStore` 類型，它進一步保持了對於 store 的引用。作為 View，它透過 `@ObservedObject` 對這個 `ViewStore` 進行觀察，並回應它的變更。因此，如果我們的 View 持有的只是切分後的 Store，那麼原始 Store 其他部分的變更，就不會影響到目前這個 Store 的切片，從而保證那些和當前 UI 不相關的狀態改變，不會導致當前 UI 的刷新。

> 注意！ [`WithViewStore`](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/withviewstore/) 的用法已棄用，可參考 [Migrated to 1.7](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.7/#Using-ObservableState) 的文件
> 

 iOS 17 以下，用 `WithPerceptionTracking` ，且 store property 要這樣宣告 `@Perception.Bindable var store: StoreOf<Feature>` 。

但假設是 iOS 17 以上，`WithViewStore` 和 `WithPerceptionTracking` 都不用了

而且現在會使用 `@ObservableState` 在 State 上，而 view 上的 store 加上 `@Bindable` 。

```swift
@Reducer
struct Feature {
	  @ObservableState
	  struct State {
	  ...
		}
}

struct View: View {
	  @Bindable var store: StoreOf<Feature>
	  ...
}
```

# 第二章

### 綁定和普通狀態的區別

---

在上篇的功能裡，基本上狀態驅動 UI 的流程是：點擊按鈕 → 發送 Action → 更新 State → 觸發 UI 更新

除了單純透過狀態來更新 UI，在 SwiftUI 同時也支持反向使用 `@Binding` 的方式把某個 State 綁定給 UI 元件，這些元件不用經由我們的程式碼就能改變某個狀態，例如 `TextField`, `Toogle` 等。

但假如 view 有能力直接改變狀態，其實就違反了 TCA 中關於只能在 reducer 中更改狀態的規定。對於這種情況，TCA 中為 View Store 增加了將狀態轉換爲一種「特殊綁定關係」的方法。

### 實作

---

```swift
enum Action {
  case increment
  case decrement
+ case setCount(String)
  case reset
}

    var body: some ReducerOf<Self> {
        Reduce { state, action in
			  // ...
			+ case .setCount(let text):
			+   if let value = Int(text) {
			+     state.count = value
			+   }
			+   return .none
			  // ...
		}
```

再把 `body` 中原來的 `Text` 替換 `TextField` 

```swift
var body: some View {
    // ...
-   Text("\(viewStore.count)")
+   TextField(
+     String(viewStore.count),
+     text: store.binding(
+       get: { String($0.count) },
+       send: { CounterAction.setCount($0) }
+     )
+   )
+     .frame(width: 40)
+     .multilineTextAlignment(.center)
      .foregroundColor(colorOfCount(viewStore.count))
}
```

`viewStore.binding` 方法接受 get 和 send 兩個參數，它們都是和目前 View Store 及綁定 view 類型相關的泛型函數。在特化 (將泛型在這個上下文中轉換為具體類型) 後

- `get: (Counter) -> String` 負責為物件 View (這裡的 `TextField` ) 提供資料。
- `send: (String) -> CounterAction` 負責將 View 新發送的值轉換為 View Store 可以理解的 action，並發送它來觸發 `counterReducer`。

在 `counterReducer` 接到 `binding` 給予的 `setCount` 事件後，我們就回到使用 reducer 進行狀態更新，並驅動 UI 的標準 TCA 循環中了。

但在我的 demo code ，是使用 swiftUI native 的 `Binding`，在 binding 的時候，當 textField 輸入文字時就是發一個 action `setCont(String)` ，待會在 View 的部分會看到。

再來我們可以簡化一下程式碼，到 Counter 裡新增：

```swift
extension Counter.State {
    var countString: String {
        get { String(count) }
        set { count = Int(newValue) ?? count }
    }

    var countFloat: Float {
        get { Float(count) }
        set { count = Int(newValue) }
    }
}
```

Reduce 的部分，就可以變成這樣

```swift
 case .setCount(let text):
			state.countString = text
```

然後 View 的部分，TextField 改成這樣

```swift
TextField(
    String(store.count),
    text: Binding(
        get: { store.countString },
        set: { store.send(.setCount($0)) }
    )
)
```

### 多個綁定值

如果在同一個 Feature 中，有多個綁定值的話，使用例子中這樣的方式，每次都會需要新增一個 action，然後再 `binding` 中 `send` 它。這是千篇一律的模板程式碼，TCA 中設計了 [`BindingState`](https://pointfreeco.github.io/swift-composable-architecture/0.56.0/documentation/composablearchitecture/bindingstate), [`BindableAction`](https://pointfreeco.github.io/swift-composable-architecture/0.56.0/documentation/composablearchitecture/bindableaction), 以及 [`BindingReducer`](https://pointfreeco.github.io/swift-composable-architecture/0.56.0/documentation/composablearchitecture/bindingreducer) 來解決，讓多個綁定的寫法簡單一點，具體來說，分成三步：

1. 為 `State` 中的需要和 UI 綁定的變數新增 `@BindableState` 。
2. 將 `Action` 聲明為 `BindableAction` ，然後新增一個「特殊」的 case `binding(BindingAction<Feature>)` 。
3. 在 Reducer 中處理這個 `.binding` ，並新增 `.binding()` 調用。

用程式碼來說就是：

```swift
// 1
struct MyState: Equatable {
+ @BindableState var foo: Bool = false
+ @BindableState var bar: String = ""
}

// 2
- enum MyAction {
+ enum MyAction: BindableAction {
+   case binding(BindingAction<MyState>)
}

// 3
let myReducer = //...
  // ...
+ case .binding:
+   return .none
}
+ .binding()
```

這樣一番操作後，可以在 View 裡用類似標準 SwiftUI 的做法，使用 `$` 取 `projected value` 來進行 Binding 了：

```swift
struct MyView: View {
  let store: Store<MyState, MyAction>
  var body: some View {
    WithViewStore(store) { viewStore in
+     Toggle("Toggle!", isOn: viewStore.binding(\.$foo))
+     TextField("Text Field!", text: viewStore.binding(\.$bar))
    }
  }
}
```

這樣一來，即使有多個 binding 值，都可以只用一個 `.binding` action 處理。這段程式碼能運作是因為 `BindableAction` 要求一個簽名為 `BindingAction<State> -> Self` 且名為 `binding` 的函式：

```swift
public protocol BindableAction {
  static func binding(_ action: BindingAction<State>) -> Self
}
```

利用了 enum case 作為函式使用的 Swift 新特性，程式碼變得很優雅。

詳細可以參考[官方文件](https://pointfreeco.github.io/swift-composable-architecture/0.56.0/documentation/composablearchitecture/bindings)（寫法有稍微不一樣）

### Environment

現在可以輸入數字了，我們來做個猜數字的小遊戲，玩法就是從 -100 到 100 之間，隨機一個數字，我們要猜這數字，數字太大太小都要回報給 User。

所以我們先加一個 `var secret = Int.random(in: -100...100)` 至 State 裡，由他來產出一個隨機數。

```swift
    @ObservableState
    struct State: Equatable {
        var count: Int = 0
        let secret = Int.random(in: -100...100)
     }
```

再來檢查 `count` 和 `secret` 的關係，返回答案

```swift
extension Counter {
  enum CheckResult {
    case lower, equal, higher
  }
  
  var checkResult: CheckResult {
    if count < secret { return .lower }
    if count > secret { return .higher }
    return .equal
  }
}
```

再來就可以修改 View

```swift
struct CounterView: View {
  @Bindable var store: StoreOf<Counter>
  var body: some View {
      VStack {
+       checkLabel(with: store.checkResult)
        HStack {
          Button("-") { store.send(.decrement) }
          // ...
  }
  
  func checkLabel(with checkResult: Counter.CheckResult) -> some View {
    switch checkResult {
    case .lower:
      return Label("Lower", systemImage: "lessthan.circle")
        .foregroundColor(.red)
    case .higher:
      return Label("Higher", systemImage: "greaterthan.circle")
        .foregroundColor(.red)
    case .equal:
      return Label("Correct", systemImage: "checkmark.circle")
        .foregroundColor(.green)
    }
  }
}
```

最後我們就有

![Screenshot 2025-05-18 at 22.42.08.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/Screenshot_2025-05-18_at_22.42.08.png?raw=true)

### 外部依賴

當我們答對後，Reset 按鈕只能清除，不能重新一局，我們讓遊戲好玩一點，變成下一局

所以我們調整

```swift
enum Action {
  // ...
- case reset
+ case playNext
}

struct CounterView: View {
  // ...
  var body: some View {
    // ...
-   Button("Reset") { store.send(.reset) }
+   Button("Next") { store.send(.playNext) }
  }
}
```

在邏輯的部分

```swift
@ObservableState
struct State: Equatable {
  var count: Int = 0
- let secret = Int.random(in: -100 ... 100)
+ var secret = Int.random(in: -100 ... 100)
}

var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			- case .reset:
			+ case .playNext:
			    state.count = 0
			+   state.secret = Int.random(in: -100 ... 100)
		    return .none
  // ...
```

現在來跑一下測試，結果沒意外是失敗的

```swift
func testReset() throws {
- store.send(.reset) { state in
+ store.send(.playNext) { state in
    state.count = 0
  }
}
```

這是因為 `.playNext` 現在不僅重設 `count`，也會隨機產生新的 `secret`。而 `TestStore` 會把 send 閉包結束時的 state 和真正的由 reducer 操作的 state 進行比較並斷言：前者沒有設定合適的 `secret`，導致它們並不相等，所以測試失敗了。

我們需要一種穩定的方式，來確保測試成功。

### 使用環境值解決依賴

在 TCA 中，為了保證可測試性，reducer **必須**是純函數，也就是說相同輸入 (state, action 和 environment) 的組合，必須能給出相同的輸入（在這輸出是 state 和 effect，後面的章節在接觸 effect 角色）

其中使用了 `Int.random` 所以無法保證每次的結果，TCA 中的 Environment 就是要處理這種情況，對應外部依賴的情況。

首先程式碼是

```swift
struct Environment {
+ var generateRandom: (ClosedRange<Int>) -> Int
}
```

再來原本 `CounterEnvironment()` 加上 `generateRandom` 的設定。

另一種更常見和簡潔的做法，是為 `Counter.Environment` 定義一組環境，然後把他們傳到相對應的地方：

```swift
struct Environment {
  var generateRandom: (ClosedRange<Int>) -> Int
  
+ static let liveValue = Self(
+   generateRandom: Int.random
+ )
+ static let testValue = Self(
// ...
}

CounterView(
	store: Store(initialState: Counter.State()) {
	  Counter()
  } withDependencies: {
	  $0.counterEnvironment = .testValue
  }
)
```

現在，在 reducer 中，就可以使用注入的環境值來達到和原來一樣的結果了

```swift
let counterReducer = // ... {
- state, action, _ in
+ state, action, environment in
  // ...
  case .playNext:
    state.count = 0
-   state.secret = Int.random(in: -100 ... 100)
+   state.secret = environment.generateRandom(-100 ... 100)
    return .none
  // ...
}
```

在 test target 中，就可以創建一個 `.test` 環境

```swift
extension Counter.Environment {
  static let test = CounterEnvironment(generateRandom: { _ in 5 })
}
```

現在，在生成 `TestStore` 的時候，使用 `.test` ，然後在斷言時生成合適的 `Counter` 作為新的 state，測試就能順利通過了

```swift
store = TestStore(initialState: Counter.State()) {
    Counter()
} withDependencies: {
    $0.counterEnvironment = .init(
        generateRandom: { _ in 10 },
        uuid: { .dummy }
    )
}

@Test
func playNext() async throws {
    await store.send(.playNext) {
        $0.count = 0
        $0.secret = 5        
    }
}
```

### 其他常見的依賴

除了像是 random 系列以外，凡事隨著調用環境變化（包括 ID、時間、地點、各種外部狀態等等）而打破 reducer 純函數特性的外部依賴，都應該被納入 Environment 的範疇。

有些可以同步完成，像是 `Int.random` ，但有些則需要一定的時間才得到結果，比如獲取位置和發送網路請求。對於後者，可以轉換為 `Effect` 。

# 第三章


### Effect

Elm-like 的狀態管理之所以能夠保持可測試及可擴展，**核心要求是 Reducer 的純函數特性**

Environment 透過提供依賴解決了 reducer **輸入階段**的副作用（比如 reducer 需要獲取某個 `Date` 等），而 Effect 解決的則是 reducer **輸出階段**的副作用：如果在 Reducer 接收到某個行為之後，需要做出非狀態變化的反應，比如發送一個網路請求，像硬盤寫一些數據，或者監聽某個通知等，都需要透過返回 `Effect` 進行。

`Effect` 定義了需要在純函數外執行的程式碼，以及處理結果的方式：一般來說這個執行過程會是一個耗時行為，行為的結果透過 `Action` 的方式在未來某個時間再次觸發 reducer 並更新最終狀態。TCA 在運行 reducer 的程式碼，並獲取返回的 `Effect` 後，**負責執行他所定義的程式碼，然後按照需要發送新的 `Action` 。**

### Time Effect

接下來我們想做一個這樣的功能，倒數計時，並且會顯示開始時間

![image.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/image%205.png?raw=true)

首先定義 TimerFeature，其中的 State 很單純

```swift

@Reducer
struct TimerFeature {
    @ObservableState
    struct State: Equatable {
        var started: Date? = nil
        var duration: TimeInterval = 0
    }
}

```

然後是 Action 的定義，**開始計時**和**結束計時**，這兩個 action 很明確，問題在於我們該如何更新 `TimeState.duration` 呢？按照 TCA 的架構方式，reducer 是唯一能夠設置 State 的地方，而 reducer 又需要接收某個 action 進行驅動。因此，很顯然還需要一個 action，來表示**每次 time duration 的更新**，在這裡我們把它叫做 `timeUpdated` 

```swift
@Reducer
struct TimerFeature {
		struct State: Equtable { 
		// ...
		enum Action {
		  case start
		  case stop
		  case timeUpdated
}
```

有了 State 和 Action，接下來就是 Reducer 了， `.timeUpdated` 是最簡單的，假設每次 `.timeUpdated` 發生時，讓 `state.duration` 增加 0.01s

```swift
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {  switch action {
        case .start: 
            fatalError("Not implemented")
        case .timeUpdated:
            state.duration += 0.01
            return .none
        case .stop:
            fatalError("Not implemented")
        }
    }
}
```

現在，我們只要想辦法在 `.start` 的 case 進行一些奇妙的「設定」，讓 TCA 運行時每隔 10ms 發送一次 `.timeUpdated` action 就可以了。把這類行為進行抽象：在處理 Action 時，進行一些 TCA 系統之外的操作，把結果轉換為新的 Action 反饋到 TCA 系統裡，這類行為就是一個 Effect。

對於 Timer，TCA 框架直接定義了 `Effect.timer` 。在 `timeReducer` 中，我們直接使用它來返回一個按時間觸發的 effect:

```swift
struct TimerEnvironment {
+ // 1
+ var date: () -> Date
+ var mainQueue: AnySchedulerOf<DispatchQueue>

+ static var live: TimerEnvironment {
+   .init(
+     date: Date.init,
+     mainQueue: .main
+   )
+ }
}

let timerReducer = Reducer<TimerState, TimerAction, TimerEnvironment> {
  state, action, environment in
+ // 2  
+ struct TimerId: Hashable {} 

  switch action {
  case .start: 
-   fatalError("Not implemented")
+   if state.started == nil {
+     state.started = environment.date()
+   }
+   // 3
+   return Effect.timer(
+     id: TimerId(),
+     every: .milliseconds(10),
+     tolerance: .zero,
+     on: environment.mainQueue
+   ).map { time -> TimerAction in
+     // 4
+     return TimerAction.timeUpdated
+   }
  case .timeUpdated:
    state.duration += 0.01
    return .none
  case .stop:
    fatalError("Not implemented")
  }
}
```

以上為舊寫法，新寫法可以直接這樣用

```swift
@Dependency(\.date) var date
@Dependency(\.continuousClock) var clock

var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .start:
            if state.started == nil {
                state.started = date()
                state.duration = 0
            }
            return .run { send in
                for await _ in self.clock.timer(interval: .milliseconds(10)) {
                    await send(.timeUpdated)
                }
            }
            .cancellable(id: TimerID())
        case .timeUpdated:
            state.duration += 0.01
            return .none
            // ...
```

1. 類似上一篇文中，對於外部輸入，我們使用環境值來進行注入
2. 為了能夠實現 Effect 的取消，我們需要創建的 Effect 指定一個 id。這裡 `TimerId` 是一個最簡單的滿足了 `Hashable` 的類型
3. TCA 中直接提供建立一個 timer 的方法，建立一個 `TimerId` 的實例作為這個 Effect 的 id。
4. `Effect.timer` 返回類型 `Effect<DispathchQueue.SchedulerTimeType, Never>` 。而在 `timerReducer` 中，我們要求返回值為 `Effect<Action, Never>` 。TCA 為 `Effect` 的 output 轉換提供人見人愛的 `map` 方法。用它就可以把返回結果轉為我們需要的類型了。

遇到 `.start` 後，reducer 返回一個 timer Effect，開啟一個「副作用」。之後每隔 10ms， `.timeUpdated` 就會被發送一次，reducer 獲取到這個 action，並用它來更新 `duration` 。

### Effect 取消

在 `.stop` 中我們需要讓 timer 停止，可以透過返回一個特殊的 `Effect.cancel` 來取消操作：

```swift
let timerReducer = Reducer<TimerState, TimerAction, TimerEnvironment> {
  state, action, environment in
  
  struct TimerId: Hashable {}
  switch action {
  // ...
  case .stop:
-   fatalError("Not implemented")
+   return .cancel(id: TimerId())

  // ...
} 
```

透過把 hash value 相同的 `TimerId` 內部類型實例傳遞個 `.cancel` ，TCA 就會幫我們尋找到之前開始的 timer，並停下來了。

最困難的 reducer 部分已經搞定了，接下來建立 `TimerLabelView` ，並按要求畫 UI，就很簡單了。

```swift
struct TimerLabel: View {
    @Bindable var store: StoreOf<TimerFeature>

    var body: some View {
        VStack(alignment: .leading) {
            Label(
                store.state.started == nil
                    ? "-"
                    : "\(store.started!.formatted(date: .omitted, time: .standard))",
                systemImage: "clock"
            )
            Label(
                "\(store.duration, format: .number)s",
                systemImage: "timer"
            )
        }
    }
}
```

而且我們可以很簡單的在 preview 上測試結果

![ezgif-1b1f2ece92492b.gif](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/ezgif-1b1f2ece92492b.gif?raw=true)

```swift
#Preview {
    let store = Store(initialState: TimerFeature.State()) {
        TimerFeature()
    }
    VStack {
        TimerLabel(store: store)
        HStack {
            Button("Start") { store.send(.start) }
            Button("Stop") { store.send(.stop) }
        }.padding()
    }
}
```

在上面的例子中，多次點擊 Start 按鈕也不會出事，因為在透過 `Effect.timer` 建立新的計時 Effect 時，它的內部已經使用吃入的 id 先進行了一次 `.cancel` 處理。

我們有時候想要阻止 User 因為連點按鈕，造成連續 call API 也可以善用 Cancel 功能。

### 測試 Effect

在把 `TimerLabelView` 組合到 app 之前，先來看看怎麼測試。經常寫測試就會遇到這樣的難題：如何寫好一個異步操作的測試。這類異步操作不僅僅涉及到像是本例中 timer 這種類型，也可能有像是網路請求或者等待遇用戶輸入等更具體普遍意義的情形。在傳統做法中，我們往往會依靠 test stub 和 mock 對象加上一定的注入，或乾脆直接等待固定的時間，然後再驗證結果，這些手段是有效的，但是 stub 和 mock 不僅為測試帶來更多的外部依賴和複雜度，也許要我們對實際程式碼進行修改，讓他可以被注入，而強行等待的方法，不僅會拉長測試所需要的時間，而且隨著環境不同，這些測試失效也面臨著失效的可能性。

在 TCA 中，由於存在 Environment 類型，我們「天然」擁有一個系統外部的注入點。這一部分，我們會來看看如何使用注入的 scheduler 完成 `timeReducer` 的測試。

在定義 `TimerEnvironment` 時，我們將 State 系統外部的部分都囊括了起來，包括 `date` 和 `mainQueue` 。在實際的 app 程式碼裡，我們把 `AnySchedulerOf<DispatchQueue>.main` （他其實就是 `DispatchQueue.main` ）賦給了 `mainQueue` ，來讓 timer 的事件運行在主隊列上。 `.main` 是和 app 以及真實世界綁定的隊列，對 State 體系來說，這是一個巨大的「副作用」。在測試中，我們需要一個能夠被我們精確控制和操作的隊列，來保證測試不被外界影響。TCA 中我們定義裡一個簡單好用的類型， `TestScheduler` 。

為 `TimerLabel` 新增測試：

```swift
// TimerLabelTests.swift
import XCTest
import ComposableArchitecture
@testable import CounterDemo

class TimerLabelTests: XCTestCase {
  let scheduler = DispatchQueue.test
  
  // ...
}
```

`DispatchQueue.test` 是 TCA 專門為測試定義的，他的型別為 `TestSchedulerOf<DispatchQueue>` 。 `TestSchedulerOf` 不像 `.main` 這樣的隊列，會隨著 app 和真實時間向前運行，他上面定義了一系列操作方法，讓我們可以手動控制時刻。

```swift
class TimerLabelTests: XCTestCase {
  let scheduler = DispatchQueue.test
  
  func testTimerUpdate() throws {
    let store = TestStore(
      initialState: TimerState(),
      reducer: timerReducer,
      environment: TimerEnvironment(
        date: { Date(timeIntervalSince1970: 100) },
        mainQueue: scheduler.eraseToAnyScheduler()
      )
    )
    // ...
  }
}
```

最後操作就是 `scheduler` ，然後判斷狀態的部分

```swift
 func testTimerUpdate() throws {
    // ...
    
    store.send(.start) {
      $0.started = Date(timeIntervalSince1970: 100)
    }
    
    // 1
    scheduler.advance(by: .milliseconds(35))
    // 2
    store.receive(.timeUpdated) {
      $0.duration = 0.01
    }
    store.receive(.timeUpdated) {
      $0.duration = 0.02
    }
    store.receive(.timeUpdated) {
      $0.duration = 0.03
    }
    // 3
    store.send(.stop)
  }
```

1. `advance(by:)` 將這個 `scheduler` 的「時針」前進給定了時間，也就是說，讓時間流逝。不在依賴不精確的現實世界，也不依賴運行這個測試的具體設備和環境，而可以準確將計時器調整到 35ms 的位置。
2. 使用 `.recive` 來斷言接收到了某個事件，並且在閉包中驗證 State 的改變。這裡由於 1 中 `scheduler.advance` 的原因，我們會期望收到三次 `.timeUpdated` （因為在 `timerReducer` 的實現中我們只定了 10ms 觸發一次 timer）。
3. 最後，向 `store` 發送 `.stop` action 來取消 timer。

在上面的斷言中，刪除 2 的其中任意一個 `receive` 或者移除 3 的 `send(.stop)` ，都會導致測試的失敗。TCA 在對應 Effect 測試時，會對還未被 `receive` 的 action 以及還在運行的 Effect 進行斷言，這個特性非常優秀，保證了涉及的異步操作「萬無一失」。

### 其他 Effect 和測試

除了 Timer 之外，在實際開發中還有各種異步操作，例如網路請求，TCA 都提供一系列方法處理，來把基於閉包或者 `Publisher` 的異步操作封裝成一個可以 reducer 返回的 `Effect` 。

**網路請求 Effect**

```swift
import Combine

// 原文，用到 Combine 的 Publisher，最後會再轉成 Effect
let sampleRequest = URLSession.shared
  .dataTaskPublisher(for: URL(string: "https://example.com")!)
  .map { element -> String in
    return String(data: element.data, encoding: .utf8) ?? ""
  }
  
// 我們直接包成一個 Effect，因為只是 demo 用，沒有 catch error
var sampleRequest: Effect<Result<String, URLError>> {
    .run { send in
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = String(data: data, encoding: .utf8) ?? ""
        await send(.success(result))
    }
}
```

一個常見的 request publisher，在 TCA 中，我們已經看到很多將外部作用放在 `Environment` 中的例子，網路請求是一個非常的大副作用

```swift
// 原文
struct SampleTextEnvironment {
  var loadText: () -> Effect<String, URLError>
  var mainQueue: AnySchedulerOf<DispatchQueue>
  static let live = SampleTextEnvironment(
    loadText: { sampleRequest.eraseToEffect() },
    mainQueue: .main
  )
}

// 新做法，直接返回 Effect，原文的 eraseToEffect() 已棄用 
struct Environment {
    var loadText: () -> Effect<Result<String, URLError>>
    var queue: AnySchedulerOf<DispatchQueue>
    
    static var liveValue = Self(
        loadText: { sampleRequest },
        queue: .global()
    )
}
```

`effectToEffect` 是 TCA 定義在 `Publisher` 上的輔助方法

剩下的部分就是定義相關的 State 和 Reducer 了：

```swift
enum SampleTextAction: Equatable {
  case load
  case loaded(Result<String, URLError>)
}

struct SampleTextState: Equatable {
  var loading: Bool
  var text: String
}

let sampleTextReducer = Reducer<SampleTextState, SampleTextAction, SampleTextEnvironment> {
  state, action, environment in
  switch action {
  case .load:
    state.loading = true
    // 1
    return environment.loadText()
      .receive(on: environment.mainQueue)
      .catchToEffect(SampleTextAction.loaded)
  case .loaded(let result):
    // 2
    state.loading = false
    do {
      state.text = try result.get()
    } catch {
      state.text = "Error: \(error)"
    }
    return .none
  }
}

// 在原文 1 的部分，在新的寫法已經沒有 Effect.receive(on:) 以及 .catcheToEffect()
// 目前想到類似的寫法是這樣，先用 queue 卡住，等他完成後再來去做 loadText()
	switch action {
  case .load:
    state.loading = true
		return .run { send in
	    try await environment.queue.sleep(for: .zero)
		}.concatenate(with:
	    environment.loadText()
		    .map { .loaded($0) }
		)
		// ...
```

1. 這種做法在 TCA 處理 Effect 很常見，對於一個接收 Effect 結果的 Action，將關聯值定義為 `Result<Value, Error>` 的形式，可以讓 reducer 的部分程式碼簡化很多。
2. 在 `.load` 中返回 `Effect` 執行完成，並經由轉換後 `.loaded` action 被發送。這給了 `Reducer` 一個處理 `Effect` 結果和更新狀態的機會。在 TCA 中，對於異步操作我們會看到大量這種模式。

最後

```swift
 struct SampleTextView: View {
  
    let store: Store<SampleTextState, SampleTextAction>
  
    var body: some View {
      WithViewStore(store) { viewStore in
        ZStack {
          VStack {
            Button("Load") { viewStore.send(.load) }
            Text(viewStore.text)
          }
          if viewStore.loading {
            ProgressView().progressViewStyle(.circular)
          }
        }
      }
    }
  }
```

**測試網路請求**

網路請求 Effect 的測試，和之前 Timer 測試相似，透過注入 Environment 注入的方式，提供合適的 `loadText` 和 `mainQueue` ，就能控制 Effect 的行為了

```swift
class SampleTextTests: XCTestCase {
  
  let scheduler = DispatchQueue.test
  
  func testSampleTextRequest() throws {
    let store = TestStore(
      initialState: SampleTextState(loading: false, text: ""),
      reducer: sampleTextReducer,
      environment: SampleTextEnvironment(
        // 1
        loadText: { Effect(value: "Hello World") },
        mainQueue: scheduler.eraseToAnyScheduler()
      )
    )
    store.send(.load) { state in
      state.loading = true
    }
    // 2
    scheduler.advance()
    store.receive(.loaded(.success("Hello World"))) { state in
      state.loading = false
      state.text = "Hello World"
    }
  }
}
```

1. 提供一個實際的 `dataTask` publisher，這裡直接返回一個 “Hello World”  作為完成值的 `Effect` 。代表一個「即將發生」的外部「返回值」
2. 和上面 timer 的例子相似，使用 `.test` 和 `advance` 讓測試向前運行。假如新增參數時， `.zero` 會被使用，這代表 `scheduler` 不會發生時間流逝，但會把所有當前「堆積」的 Effect 事件都發送出去。TCA 也準備了另一個特殊的 `.immediate` 來簡化流程：

```swift
class SampleTextTests: XCTestCase {
  
- let scheduler = DispatchQueue.test
  
  func testSampleTextRequest() throws {
    let store = TestStore(
      initialState: SampleTextState(loading: false, text: ""),
      reducer: sampleTextReducer,
      environment: SampleTextEnvironment(
        loadText: { Effect(value: "Hello World") },
-       mainQueue: scheduler.eraseToAnyScheduler()
+       mainQueue: .immediate
      )
    )
    store.send(.load) { state in
      state.loading = true
    }
-   scheduler.advance()
    store.receive(.loaded(.success("Hello World"))) { state in
      state.loading = false
      state.text = "Hello World"
    }
  }
}
```

`.immediate` 會忽視 Effect（或者說 Publisher）中有關時間的部分，而立即讓這些 Effect 完成，因此可以把 `scheduler` 移除，簡化程式碼。

**更多類型的 Effect 以及 Effect 操作**

除了 Timer, Publisher 以外，像是基於 closure callback 的異步方式，或者全新的 Swift Concurrency 的操作，TCA 都在 `Effect` 類型中為他們提供相應的封裝方式。

假如是多個異步操作的情況，TCA 有 `concatenate` (這是就是我們新寫法用到的，順次執行多個 `Effect` ）和 `merge` （同時執行多個 `Effect` ）的手動。假如不關心返回值也不需要再完成時觸發新的 action，則可以使用 `fireAndForget` (已棄用）操作。

以 TCA 的角度來看 Combine Publisher 的用法似乎逐漸汰換，使用 Swift Concurrency async/await 似乎比較是趨勢。

### **Composable**

現在有猜數字的 `CounterView` 和表示時間的 `TimerLabelView` ，要怎麼把它們結合？

![image.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/image%206.png?raw=true)

小組件是由 State, Action, Reducer 和 Environment 組成，然後把小組件組裝成大組件也是一樣的方式。

**Game State**

先從 `State` 開始

```swift
@Reducer
struct GameFeature {
		@ObservableState
		struct State: Equatable {
			  var counter: Counter = .init()
			  var timer: TimerState = .init()
		}
}
```

**Game Action**

接下來是 `Action` 

```swift
enum Action {
  case counter(CounterAction)
  case timer(TimerAction)
}
```

**Game Environment**

先暫時用空的，後續看官方的例子，假如是官方定義的那幾個 Dependency 幾乎不使用 Environment 了，而是直接宣告需要什麼 Dependency，例如 `@Dependency(\.continuousClock) var clock` 直接使用，不用包在 Environment，然後例如是 call API，也應該會有一個獨立的 Dependency，加進來。 

```swift
struct Environment { }
```

實際開發中，我們重複定義了一些相同的環境值，比如 `date` 或 `mainQueue` 。這類相同環境其實可以新增包裝，讓他們更好 reuse。但由於 `GameState` 的狀態變化並「**不涉及更多的外部副作用**」，所以為了簡單說明，暫時留空。

> 實際上「**不涉及副作用**」這個說法是錯誤的，更準確來說，`GameState` 内部的 `Counter` 和 `TimerState`都是有副作用的。這些副作用，在 `Game` 的層級上不應該由 `CounterEnvironment.live` 或者 `TimerEnvironment.live` 來定義，而應該從 `GameEnvironment` 中轉換過去。
> 

**Game Reducer**

是最困難的部分，核心思想有三條：

1. 組件的行為都由 reducer 定義的。子組件行為，也應該由子組件的 reducer 自己決定。因此需要使用已有的 `counterReducer` 和 `timerReducer` ，並**把 `GameAction` 轉換為子組件所需的 `CounterAction` 或 `TimerAction` 並傳遞給他們**。
2. 子組件對各種 State 進行修改的結果，需要反應到父組件中，才能完成父組件 `View` 的刷新。這個例子中， `counterReducer` 和 `timerReducer` 會更改個字的 `Counter` 和 `TimerState` ，但是 `GameState` 中的 `counter` 和 `timer` 並不會被子組件的 reducer 更改（因為 `GameState` 是一個 struct）因此需要一種方式**讓子組件 reducer 能夠設置父組件對應的 state**。
3. 多個組件需要聯合起來工作，各組件的 reducer 需要**進行合併**。

在 SwiftUI，記得程式碼的順序，會影響執行結果，例如下方的 code，假設 Reduce 與 Scope 交換，在 `let result = Result(…)` 拿 `state.counter` 的結果不一樣， Scope 先執行的話就等於會把 `state.counter` 更新重置

```swift
		var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                case .counter(.playNext):
                    let result = Result(counterState: state.counter, spentTime: state.timer.duration - state.lastTimestamp)
                    state.results.append(result)
                    state.lastTimestamp = state.timer.duration
                    return .none
                default: return .none
            }
        }
        Scope(state: \.counter, action: \.counter) {
            Counter()
        }.transformDependency(\.counterEnvironment) { dependency in
            dependency.generateRandom = environment.generateRandom
            dependency.uuid = environment.uuid
        }
        Scope(state: \.timer, action: \.timer) {
            TimerFeature()
        }.transformDependency(\.date) { dependency in
            dependency.now = environment.date()
        }
    }
```

View 的部分很單純

```swift
struct GameView: View {

    @Bindable var store: StoreOf<GameFeature>

    var body: some View {
        VStack {
            resultLabel(store.state.resultState.results)
            Divider()
            TimerLabel(store: store.scope(state: \.timer, action: \.timer))
            CounterView(store: store.scope(state: \.counter, action: \.counter))
        }.onAppear {
            store.send(.timer(.start))
        }
    }
}
```

### **紀錄結果並顯示數據**

在 `CounterView` 的 “Next” 按鈕按下後，開啟新的題目。但我們需要把之前的遊玩結果記錄下來，所以在宣告一個

```swift
struct GameResult: Equatable {
  let secret: Int
  let guess: Int
  let timeSpent: TimeInterval
}
```

舉例來說，如果第一個數字是 10，我們在按下 “Next” 之前已經讓 counter 變成了 10，且耗時 5 秒，那麼我們需要記錄 `GameResult(secret: 10, guess: 10, timeSpent: 5.0)`；對於沒有猜對就繼續的情況，我們也用同樣的類型記錄下來。記錄的結果保存在 `GameFeature.State` 的一個陣列中：

```swift
struct GameState: Equatable {
  var counter: Counter = .init()
  var timer: TimerState = .init() 
+ var results: [GameResult] = []
}
```

# 第四章

### **使用 `IdentifiedArray`**

與 `Array` 相比的優點：

- 一樣有 Element 順序，index 的 O(1) 存取，且跟 `Array` 一樣兼容的 API
- 但和 `Array` 還是有小差異，其中的 element 都要遵守 `Identifiable` protocol，要確保每個元素都是唯一的
- 因為有唯一性，所以查找效率很高

使用 `Array` 的一些壞處，在 app 資料很簡單的時候很好，但只要一複雜，處理 `Array` 的效能問題或者出錯。

- 要根據相等 (也就是 `Array.firstIndex(of:)` ) 來找出其中的某個元素會需要 O(n) 的複雜度。
- 使用 index 來取得元素雖然是 O(1)，但是如果處理異步的情況，非同步操作開始時的 index 有可能和之後的 index 不一致，導致錯誤 (試想在異步期間，以同步的方式刪除了某些元素的情況：異步操作之前保存的 index 將會失效，訪問這個 index 可能獲取到不同的元素，甚至引起 crash）。

`IdentifiedArray` 可以處理上述兩個問題，所以建議能使用 `IdentifiedArray` 就使用。

```swift
- struct GameResult: Equatable {
+ struct GameResult: Equatable, Identifiable {
-   let secret: Int
-   let guess: Int
+   let counter: Counter
    let timeSpent: TimeInterval

-   var correct: Bool { secret == guess }
+   var correct: Bool { counter.secret == counter.count }
+   var id: UUID { counter.id }
}
```

然後更新，讓編譯通過

```swift
let gameReducer = Reducer<GameState, GameAction, GameEnvironment>.combine(
  .init { state, action, environment in
    switch action {
    case .counter(.playNext):
      let result = GameResult(
-       secret: state.counter.secret,
-       guess: state.counter.count,
+       counter: state.counter,
        timeSpent: state.timer.duration - state.lastTimestamp
      )
      // ...
  },
  // ...
)

struct GameView: View {
  var body: some View {
    // ...
-      resultLabel(viewStore.state)
+      resultLabel(viewStore.state.elements)
  }
  
  // ...
}
```

### 使用獨立 feature 的方式進行構建

幾乎每個 View 都會搭配一個 feature，他的組成最基本的就是 state, reducer, environment 和 action，TCA 最優秀的一點：**我們只需要著眼於創建簡單的小組件，然後透過組合的方式把它們添加到大組件中**。

Feature:

```swift
import ComposableArchitecture
import Foundation

@Reducer
struct GameResultListFeature {
    @ObservableState
    struct State: Equatable {
        var results: IdentifiedArrayOf<GameResult> = []
    }

    enum Action {
        case remove(offset: IndexSet)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .remove(let offset):
                state.results.remove(atOffsets: offset)
                return .none
            }
        }
    }
}
```

View:

```swift
import ComposableArchitecture
import SwiftUI

struct GameResultListView: View {

    @Bindable var store: StoreOf<GameResultListFeature>

    var body: some View {
        List {
            ForEach(store.state.results) { result in
                HStack {
                    Image(systemName: result.correct ? "checkmark.circle" : "x.circle")
                    Text("Secret: \(result.counter.secret)")
                    Text("Answer: \(result.counter.count)")
                }.foregroundColor(result.correct ? .green : .red)
            }
        }
    }
}

#Preview {
    GameResultListView(
        store: Store(initialState: GameResultListFeature.State(results: [
            GameResult.init(counter: .init(count: 10, secret: 10, id: .init()), spentTime: 100),
            GameResult.init(counter: .init(), spentTime: 100)
        ])) {
            GameResultListFeature()
        }
    )
}

```

![Screenshot 2025-05-04 at 15.39.55.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/Screenshot_2025-05-04_at_15.39.55.png?raw=true)

### 支持刪除

在 SwiftUI 上要加上預設的刪除操作很單純，只要為 cell 加上 `onDelete` 就可以了，我們額外再加一個顆 `EditButton` 。

```swift
struct GameResultListView: View {

    @Bindable var store: StoreOf<GameResultListFeature>

    var body: some View {
        List {
            ForEach(store.state.results) { result in
                HStack {
                    Image(systemName: result.correct ? "checkmark.circle" : "x.circle")
                    Text("Secret: \(result.counter.secret)")
                    Text("Answer: \(result.counter.count)")
                }.foregroundColor(result.correct ? .green : .red)
            }.onDelete { store.send(.remove(offset: $0)) }
        }
        .toolbar {
            EditButton()
        }
    }
}
```

### Navigation 導航

### **基本導航**

接下來就是用導航的方式顯示這新頁面 (`GameResultListView`)，在 app 主頁面中，已經有將小組件使用 `pullback` 的方式進行組合了，將 list feature 和 app 其他部分的 feature 組合的方式並沒有什麼不同：也就是把子組件的 state，action，reducer 和 view 都整合到父組件去。

在這，我們計劃在 navigation bar 上新增一個 Detail 按鈕，透過 NavigationLink 的方式顯示 GameResultListView。首先，在 CounterDemoApp.swift 中新增一個 NavigationView，作為整個 app 的容器：

```swift
struct CounterDemoApp: App {
  var body: some Scene {
    WindowGroup {
+     NavigationStack {
        GameView(
          store: Store(
            initialState: GameFeature.State(),
            reducer: {
              GameFeature()
            }
          )
        )
+     }
    }
  }
}
```

在這 [`NavigationView`](https://developer.apple.com/documentation/swiftui/navigationview) 即將棄用，所要改用 `NavigationStack` 。

**State:**

在 `GameFeature.State` 將 `var results = IdentifiedArrayOf<GameResult>()` 改成 `var resultState: GameResultListFeature.State = .init()`

```swift
struct GameFeature {
    @Dependency(\.gameFeatureEnvironment) var environment

    @ObservableState
    struct State: Equatable {
        var counter: Counter.State = .init()
        var timer: TimerFeature.State = .init()

        var resultState: GameResultListFeature.State = .init()
        var lastTimestamp = 0.0
    }
```

**Action:**

在 `GameResultListView` 操作結果數據時，我們希望將結果拉回 `GameFeature.State.results` 裡，因此我們需要處理 `GameResultListAction` 的 action，在 `GameFeature.Action` 新增一個 `case listResult(GameResultListFeature.Action)`

```swift
@Reducer
struct GameFeature {
    @Dependency(\.gameFeatureEnvironment) var environment

    @ObservableState
    struct State: Equatable {
			...
    }

    enum Action {
        case counter(Counter.Action)
        case timer(TimerFeature.Action)
+       case listResult(GameResultListFeature.Action)
    }
```

**Reducer:**

更新 `GameFeature` 的 reducer 部分

```swift
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .counter(.playNext):
                let result = GameResult(
                    counter: state.counter,
                    spentTime: state.timer.duration - state.lastTimestamp
                )
                state.resultState.results.append(result)
                state.lastTimestamp = state.timer.duration
                return .none
            default: return .none
            }
        }
        ...
        Scope(state: \.timer, action: \.timer) {
            TimerFeature()
        }.transformDependency(\.date) { dependency in
            dependency.now = environment.date()
        }
        Scope(state: \.resultState, action: \.listResult) {
            GameResultListFeature()
        }
    }
```

這樣接收到 `.listResult` 這 action 時，在 `GameResultListFeature` 造成的結果（新的 result list state 會更新）

**View:**

最後，在 body 中建立 `NavigationLink`，用 `scope` 把 `results` 切割出來，把新的 `store` 傳遞給 `GameResultListView` 作為目標 view，導覽就完成了：

```swift
struct GameView: View {

    @Bindable var store: StoreOf<GameFeature>

    var body: some View {
        VStack {
            resultLabel(store.state.resultState.results)
            Divider()
            TimerLabel(store: store.scope(state: \.timer, action: \.timer))
            CounterView(store: store.scope(state: \.counter, action: \.counter))
        }.onAppear {
            store.send(.timer(.start))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Detail") {
                    GameResultListView(store: store.scope(state: \.resultState, action: \.listResult))
                }
            }
        }
    }
```

這時就可以執行專案看看，玩了幾場猜數字後，可以到 Detail 頁面查看結果，而且跟 GameView 的資料是有連動的，全部刪除後會發現最上面的 Result label 有變回 0/0 correct。

![Screen Recording 2025-05-04 at 17.04.46.gif](https://raw.githubusercontent.com/chengyang1380/ProgrammingNotes/refs/heads/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/Screen_Recording_2025-05-04_at_17.04.46.gif?raw=true)

pullback (新版改用 Scope）的行為

![image.png](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20%2B%20TCA%20(Onevcat)/image%207.png?raw=true)

### 存在的問題

TCA 這類類似 Elm 的架構形式，一大特點是 State 完全決定 UI，這也是在進行 UI 測試時很重要的手段：只要我們能建立出合適的 State (model 層)，我們就能期待固定的 UI，這讓整個 app 的介面成為一個「純函數」： `UI = F(State)` 。

但像上面這個簡單的導航範例，會破壞這公式，顯示主頁面時的 State 和顯示清單頁面時的 State 是無法區分的，同一種狀態可能會對應不同的 UI。這是因為管理導航的狀態存在於 SwiftUI 內部，它在我們的 State 中沒有體現出來。

如果不是很計較 app 的嚴肅性，那麼這種簡單的導航關係也不是不能接受。不過為了滿足純函數的要求，我們來看看 SwiftUI 提供的另一種導航方式，也就是基於 Binding 值控制的導航，要如何與 TCA 協同工作。

*個人理解*：跳轉頁面的過程盡可能是可以控制 State (model 層），這為了方便測試為主，也是 TCA 很重要的特性，盡可能由狀態驅動。

### 基於 Binding 的導航

除了上述最簡單的 `init(_:destination:)` 以外， `NavigationLink` 還有另外一個版本，帶有 `Binding` 。

```swift
init(
  _ titleKey: LocalizedStringKey, 
  isActive: Binding<Bool>, 
  @ViewBuilder destination: () -> Destination
)

init<V>(
  _ titleKey: LocalizedStringKey, 
  tag: V, 
  selection: Binding<V?>, 
  @ViewBuilder destination: () -> Destination
) where V : Hashable
```

前者  `isActive: Binding<Bool>`，這個 `Binding` 可以透過兩種方式控制導覽狀態：

- 由 SwiftUI 控制：當使用者透過 UI 觸發導航時，SwiftUI 負責將這個值設為 `true`。在使用回退按鈕返回時，SwiftUI 負責將這個值設為 `false`。
- 由我們自行控制：我們也可以透過程式碼把這個 `Binding` 值設為 `true` 或 `false` 來觸發對應的導覽和回退行為。

而後者，相較於前者的 `Bool`，後者接受 `V?` 的綁定值和一個代表當前 `NavigationLink` 的 `tag` 值：當 `selection` 的 `V` 和 `tag` 的 `V` 相同時，導航生效並展示 `destination` 的內容。為了判斷這個相同，SwiftUI 要求 `V` 滿足 `Hashable`。

這兩個變體為 TCA 提供了機會，可以透過 State 來控制導航狀態：只要我們在 `GameState` 中新增一個代表的導航狀態的變數，就可以透過把這個變數轉換為 Binding 並設定它，來讓狀態和 UI 一一對應：即 state 為 `true` 或者 non-nil 值為時，顯示詳細頁面；否則為 `false` 或 nil 時，顯示詳細頁面

**Identified**

在這個例子中，我們選用 `Binding<V?>` 的方法來控制。在 `GameState` 中新增一個屬性：

```swift
@Reducer
struct GameFeature {
    @Dependency(\.gameFeatureEnvironment) var environment

    @ObservableState
    struct State: Equatable {
				...
        var resultListState: Identified<UUID, GameResultListFeature.State>?
    }
```

`Binding<V?>` 中需要 `V` 滿足 `Hashable`，這裡我們原本的目標是讓 `GameResultListFeature.State.results` (也就是 `IdentifiedArrayOf<GameResult>`) 滿足 `Hashable`。

這是一個相對困難的任務：我們可以為 `IdentifiedArray` 新增 `Hashable` 實現，但這並不是一個好選擇：這兩個型別定義都不屬於我們，我們無法控制將來 TCA 是否會為 `IdentifiedArray` 引入 `Hashable` 實作。 

TCA 中將一個任意值轉為 `Hashable` 更簡單的方式就是用 `Identified` 包裝它，手動為它賦予一個 id 值，用它作為 `V` 的類型。在我們的例子中，導航只有一個單一的狀態，所以我們完全可以定義一個通用的 `UUID` 作為 `NavigationLink` 的 `tag`，在 `GameView.swift` 的頂層 scope 添加下面的定義：

```swift
let resultListStateTag = UUID()
```

> 使用 `Binding<V?>` 和 `tag` 的版本，更多是為了區分多個可能的導航情況 (例如一個清單中的各個選項都可能導航至下一個頁面)。
實際上，對於我們這裡的例子，因為只有一個可能的觸發導航的情況它，所以並沒有必要使用 tag 的方式控制，只需要使用 `Binding<Bool>` 就可以了。不過我們還是選擇 `Binding` 的版本作為例子，因為它更具一般性，更通用。
> 

### **Binding 和導航 Action 處理**

我們需要在 `reducer` 中捕獲這個 action 並為 `resultListState` 設定合適的值。在 `GameAction` 裡加入控制導航的 action 成員：

```swift
    enum Action {
        case counter(Counter.Action)
        case timer(TimerFeature.Action)
        case listResult(GameResultListFeature.Action)
+       case setNavigation(UUID?)
    }
```

然後更新 `body` 中 `NavigationLink` 的部分，改為使用 `Binding`

```swift
struct GameView: View {

    @Bindable var store: StoreOf<GameFeature>

    let resultListStateTag = UUID()

    var body: some View {
				...
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(
                    "Detail",
                    tag: resultListStateTag,
                    selection: .init(
                        get: { store.resultListState?.id },
                        set: { id in store.send(.setNavigation(id)) }
                    ),
                    destination: {
                        Text("Sample")
                    }
                )
            }
        }
    }
```

目前使用這 NavigationLink API 會有警告 `'init(_:tag:selection:destination:)' was deprecated in iOS 16.0: use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView`

也沒找到其他替代方案 https://github.com/pointfreeco/swift-composable-architecture/issues/3420

當 `NavigationLink` 的 `selection` 被觸發時， `.setNavigation(resultListStateTag)` 被發送，在 `GameFeature.Reducer` 中，捕獲這個 `action` 並進行處理：

```swift
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .counter(.playNext):
                ...
            case .setNavigation(.some(let id)):
                state.resultListState = .init(state.resultState, id: id)
                return .none
            case .setNavigation(.none):
								if let newState = state.resultListState?.value {
                    state.resultState = newState
                }
                state.resultListState = nil
                return .none
            default: return .none
            }
        }
```

接收到帶有 `id` 的 `.setNavigation` action 時，我們手動設定 `resultListState`，這會觸發 `Navigation`。

所以在有 id 時，點進到 detail 頁面時，把自身 `state.resuateState` 傳給 `resultListState` 。

而再返回時再把 `resultListState?.value.results` 的資料回傳回 `state.resuateState.results` ，在把 `resultListState` 清除。

現在， `GameFeatureReducer`  `pullback (Scope)` ，將結果拉回 `resultState`。

```swift
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .counter(.playNext):
                ...
                return .none
            case .setNavigation(.some(let id)):
                state.resultListState = .init(state.resultState, id: id)
                return .none
            case .setNavigation(.none):
                if let newState = state.resultListState?.value {
                    state.resultState = newState
                }
                state.resultListState = nil
                return .none
            default: return .none
            }
        }
        ...
        Scope(state: \.resultListState!.value, action: \.listResult) {
            GameResultListFeature()
        }
    }
```

如果你還記得 `pullback (Scope)` 的初衷，它的目的是把原本作用在本地域上的 `reducer` 轉換為能夠作用在全域域的 `reducer`。

在這裡，我們想要做的是把 `GameResultListFeature.Reducer` 對 `GameResultListFeature.State` 造成的變更，拉回 `GameFeatureState.resultListState!.value` 中。

### IfLetStore

整個過程的最後一步，就是在 `NavigationLink` 的 `destination` 裡建立正確的 `GameResultListView`。

和上面 `pullback (Scope)` 的情況類似，我們不再選擇使用 `results`，而是使用 `\.resultListState?.value` 來切割 `store`：

```swift
store.scope(
		state: \.resultListState?.value,
    action: \.listResult
)
```

但這樣做得到的是一個可選值 state 的類型 `Store<GameResultListFeature.State?, GameResultListFeature.Action>`，它並不能滿足 `GameResultListView` 所需的 `Store<GameResultListFeature.State, GameResultListFeature.Action>`。

TCA 在處理 store 中可選值屬性的切割時，使用 `IfLetStore` 來進行包裝，它會根據其中狀態可選值是否為 `nil` 來建立不同的 view，新寫法可以直接使用 `if let store = store.scope(...)`：

```swift
var body: some View {
  // ...
  NavigationLink(
    "Detail",
    tag: resultListStateTag,
    selection: viewStore.binding(get: \.resultListState?.id, send: GameAction.setNavigation),
    destination: {
-     Text("Sample")
+       if let store = store.scope(
+         state: \.resultListState?.value,
+         action: \.listResult
+       ) { GameResultListView(store: store) }
    }
  )
}
```

至此，我們完成了最完整的使用 `Binding` 進行導航的方式。

運行 app，你會發現看起來整個 app 的行為和簡單導航時並沒有什麼區別。

但是我們現在可以透過建立合適的 `GameFeature.State`，來直接顯示結果詳細頁面。

這在追蹤和調試 app 中帶來巨大便利，也正是 TCA 的強大之處。例如，在 CounterDemoApp 中，我們可以加入一些 sample：

```swift
import ComposableArchitecture
import SwiftUI

@main
struct SwiftUI_TCA_PracticeApp: App { // CounterDemoApp
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GameView(
                    store: Store(
                        initialState: testState,
                        reducer: {
                            GameFeature()
                        }
                    )
                )
            }
        }
    }
}

let sample = GameResultListFeature.State(results: [
    .init(counter: .init(count: 10, secret: 10, id: .init()), spentTime: 100),
    .init(counter: .init(), spentTime: 500),
])

let testState = GameFeature.State(
    counter: .init(),
    timer: .init(),
    resultState: sample,
    lastTimestamp: 100,
    resultListState: .init(sample, id: resultListStateTag)
)
```

現在運行 app，我們會被直接導航到結果頁面。

確保唯一的 state 對應的唯一 UI，可以讓開發快速定位問題：只需要提供 app 出現問題時的 state，理論上就可以穩定重現並立即開始調試。

⚠️ 理論上應該是可以開啟 app 後導航到結果頁面，但目前以結果來說是並沒有，而且反而會造成按鈕失效，根本原因個人也還在研究，將 `resultListStateTag` 換成 `UUID()` 按鈕會正常，又或者 `resultListState: nil` 也是，假如不管開啟 app 直接跳轉進去的話， `resultListState` 可以直接不要 init。

### **更多討論**

**SwiftUI 導航最佳實踐**

雖然 Apple 在 SwiftUI 導航上做了不少努力，但是傳統的幾種導航方式有一定缺失：不論是 navigation 還是 sheet，對於基於 Binding 的導航，控制導航狀態的 Binding 值並不會被傳遞到 [NavigationLink](https://developer.apple.com/documentation/swiftui/navigationlink) 的 `destination` 還是 [View.sheet](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)) 的 `content` 中，這導致後續頁面無法有效修改前置頁面的資料來源，從而造成數據源不統一。

在 TCA 中因為無法直接修改 state，我們選擇透過在 Binding 變更時傳送 action 的方式來更新 state。這種方法在 TCA 裡非常合適，但在普通的 SwiftUI app 裡雖然也可行，卻顯得有點格格不入。 TCA 的維護者對此專門[開源了一套工具](https://github.com/pointfreeco/swiftui-navigation)，來補充原生 SwiftUI 架構在導航上的不足，其中也包含了對於這個主題的更深入的討論。

**ViewStore 的各種形式**

在上面的例子中，我們看到了在 View 中使用 `IfLetStore(if let store = store.scope(...)` 來切分 state 中的可選值的方法。

另一個特殊的 Store 形式是 `ForEachStore`，它針對 State 中的 `IdentifiedArray`，將每個元素切割成一個新的 Store。如果 `List` 中的每個 cell 自成一套 feature 的話 (例如範例的猜數字 app 中，允許結果清單頁面的每個結果 cell 再點進去，並顯示一個 CounterView 來修改內容的話)，這種方式將讓我們很容易把 List 和 TCA 進行結合。與 `IfLetStore` 的關係類似，在組合 reducer 時，TCA 也為 `IdentifiedArray` 的屬性準備了 `forEach` 方法來把陣列中的各個元素變更拉回全域狀態的對應元素中。我們將把關於數組切分和拉回的課題作為練習留給讀者。

另外，對於 enum 形式的 State，TCA 也準備了相應的 `SwitchStore` 和 `CaseLet`，可以讓我們以相似的語法根據不同 State 屬性創建 view。關於這些內容，在理解了 TCA 的工作原理後，就都是一些類似語法糖的存在，可以在實際用到時再加以確認。

### **Alert 和结果儲存**

可能有細心的同學會問，在上面 `Binding` 導航的時候，為什麼不直接選擇在 `.setNavigation(.some(let id))` 的時候單獨只設置一個 `UUID`，而保持將結果直接 pullback 到 `results` 呢？ `resultListState` 存在的意義是什麼？或者甚至，為什麼不直接使用 `Binding<Bool>` 的 `NavigationLink` 版本呢？

對於很多情況，在 list view 裡直接操作 `results` 是完全可行的，不過如果我們有需要暫時保留原來資料的場景的話，在 `.setNavigation(.some(let id))` 中複製一份 `results` (在例子中我們透過建立新的 `Identified` 值進行複製，在編輯過程中保持原有 `results` 的穩定，並在完全結束後再把更改後的 `resultListState` 重新賦給 `results` 就是必要的了。

我們透過一個例子來說明，例如現在我們希望在從列表頁面回後多加一次 alert 彈跳窗確認，當使用者確認更改後透過網路請求向 Server「報告」這次更改，然後成功後再刷新 UI。如果使用者選擇放棄修改的話，則維持原來的結果不變。

**AlertState**

顯示一個 alert 在 app 開發中是非常常見的，TCA 為此內建了一個專門用來管理 alert 的類型： `AlertState`。為了讓 alert 能夠運作，我們可以為它新增一組 action，描述 alert 的按鈕點擊行為。在 `GameFeature.swift` 中新增：

```swift
    enum GameAlertAction: Equatable {
        case alertSaveButtonTapped
        case alertCancelButtonTapped
    }
```

然後在 `GameFeature.State` 新增 `alert` 屬性，以及 Action。

```swift
    @ObservableState
    struct State: Equatable {
		    ...
        @Presents var alert: AlertState<GameAlertAction>?
    }
    
     enum Action {
        case counter(Counter.Action)
				...
        case alertAction(PresentationAction<GameAlertAction>)
    }
```

這邊有兩個 keyword 簡單介紹一下，其他細節可以參考 TCA [教學文件](https://pointfreeco.github.io/swift-composable-architecture/main/tutorials/composablearchitecture/02-01-yourfirstpresentation/)。

[`@Presents`](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/presents()/) 是 TCA 用來管理彈出式 UI 狀態（像是 alert、sheet、popover）的屬性包裝器。

- 用 `@Presents` 宣告的狀態，TCA 會自動處理顯示與消失，減少手動管理的錯誤。
- 它能和 `.alert`、`.sheet` 等 SwiftUI 修飾器自動整合，讓 UI 狀態和資料狀態同步。
- Reducer 會自動收到彈窗相關的 action，讓你更容易處理使用者互動。
- 建議用 `@Presents` 來管理所有彈出式 UI 狀態，讓程式碼更安全、簡潔且不易出錯。

[`PresentationAction`](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/presentationaction) 它是一個 enum，代表兩個操作 `presented(_:)` 和 `dismiss` ，而且可以讓 parent 觀察 child 的事件變化。

和處理導航關係時一樣，在 reducer 裡設定 `alert` 可選值，就可以控制 `alert` 的顯示和隱藏。我們計劃在從結果列表頁面返回時展示這個 `alert`，修改 `GameFeature.Reducer` 的 `setNavigation(.none)` 分支：

```swift
case .setNavigation(.none):
    if state.resultListState?.value.results != state.resultState.results {
        state.alert = .init(
            title: { TextState("Save Changes?") },
            actions: {
                ButtonState<GameFeature.GameAlertAction>.init(
                    action: .send(.alertSaveButtonTapped),
                    label: { .init("OK") }
                )
                ButtonState<GameFeature.GameAlertAction>.init(
                    role: .cancel,
                    action: .send(.alertCancelButtonTapped),
                    label: { .init("Cancel") }
                )
            }
        )
    } else {
        state.resultListState = nil
    }
    return .none
```

最後在 `GameView` 加上 `alert` 

```swift
    var body: some View {
        ...
        .toolbar {
            ...
        }
        .alert($store.scope(state: \.alert, action: \.alertAction))
    }
```

### Dismiss 以及處理按鈕事件

現在 build 起來之後，到 detail 頁面做修改後，按下返回，確實會跳 alert，但點擊 alert 按鈕是沒有作用的。

`.alertAction(.dismiss):` 會在 alert dismiss 時觸發，所以不管按下 OK 還是 Cancel 都會執行，順序是由 OK or Cancel 先，最後才是 dismiss 執行。

```swift
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            ...
            case .alertAction(.dismiss):
                state.alert = nil
                return .none
            case .alertAction(.presented(.alertSaveButtonTapped)):
                if let newState = state.resultListState?.value {
                    state.resultState = newState
                }
                state.resultListState = nil
                return .none
            case .alertAction(.presented(.alertCancelButtonTapped)):
                state.resultListState = nil
                return .none
            default: return .none
            }
```

最後執行，就可以得到一個有正確功能的 alert。

### **Effect 和 Loading UI**

最後我們來嘗試發起一個 request ，並完成時更新 `results` 。為了單純一點，這邊就用 `delay` 的 `Effect` 來模擬 request。

先新增 Action

```swift
    enum Action {
        case counter(Counter.Action)
        ...
        case saveResult(Result<Void, URLError>)
    }
```

再來是 State

```swift
    @ObservableState
    struct State: Equatable {
        var counter: Counter.State = .init()
        ...
        var savingResults: Bool = false
    }
```

接下來就是我們的邏輯核心，加上 `@Dependency(\.mainQueue) var mainQueue` 就可以在寫測試時控制 delay 時間。

```swift
@Reducer
struct GameFeature {
    @Dependency(\.mainQueue) var mainQueue

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // ...
            case .alertAction(.presented(.alertSaveButtonTapped)):
                state.savingResults = true
                return .run { send in
                    try await mainQueue.sleep(for: .seconds(2))
                    await send(.saveResult(.success(Void())))
                }
            // ...
            case .saveResult(let result):
                state.savingResults = false
                if let newState = state.resultListState?.value {
                    state.resultState = newState
                }
                state.resultListState = nil
                return .none
            default: return .none
            }
        }

```

最後就是 View 的部分

```swift
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(
                    // ...
                    }, label: {
                        if store.savingResults {
                            ProgressView()
                        } else {
                            Text("Detail")
                        }
                    })
            }
        }
```

結果就出來了

![Screen Recording 2025-05-18 at 14.58.52.gif](https://github.com/chengyang1380/ProgrammingNotes/blob/main/Images/SwiftUI/SwiftUI%20+%20TCA%20(Onevcat)/Screen_Recording_2025-05-18_at_14.58.52.gif?raw=true)

## 總結

在這 TCA 教成已告一段落，我們看到 TCA 各組件以及他們組裝方式，還有常見的用法和模式，並對他的思想進行了探索。 我们理解和弄清了架構的思想，那麼使用頂層  API 就只是手到擒来。

對於更大且更複雜的 app 架構，TCA 框架會面臨其他一些問題，例如資料在多個 feature 間共享的方式，state 過於龐大後可能帶來的效能問題，以及跨越多個層級傳遞資料的方式等。本文寫作時，這些問題都沒有特別完美且通用的解決方式。不過，TCA 並沒有到達 1.0 版本，它本身也在快速發展和演進中，幾乎每個月都會有全新的特性甚至破壞性的變化被引入。如果你遇到了棘手的問題，或者對最佳實踐有所疑問，不妨到 TCA 的[專案和 issue 頁面中](https://github.com/pointfreeco/swift-composable-architecture)尋求答案或幫助。將你的心得和體會總結，並透過某種方式回饋給社區，也會為這個計畫的建造帶來好處。

想要進一步學習 TCA 的話，除了它本身帶有的[幾個 demo](https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples) 以外，Point-Free 實際上還開源了一個相當完整的專案：[isowords](https://github.com/pointfreeco/isowords)。另外，他們主持的[每週教學節目](https://www.pointfree.co/)，也對包括 TCA 在內的許多 Swift 主題進行了非常深刻的討論，如果學有餘力，我個人十分推薦。

個人心得：SwiftUI + TCA 確實是很有挑戰，本人是從 UIKit + MVC 架構開始學習 iOS 開發，從中從 MVC 到 MVVM，還是基於 UIKit，所以學習曲線很順，但現在 SwiftUI + TCA 學習曲線真的很抖，而且 TCA 的變化很快，目前最新版是 2025/06/07 的 1.20.2，在透過王巍 (onevcat) 大大的文章學習時，有很多語法已經變化很多，另外還有 SwiftUI 變化也很快，尤其從 iOS 17 之後有了 `Observation` 的特性，在 model 不用遵守 `Observable Object` 的寫法，效能就相差巨大，而且 TCA 的寫法也變很多，例如可以使用 `Observation` 的 `@Bindable` ，但近來隨著 iOS 版本的上升，很多舊版本開始棄用，很多 app 可能最低支援都是 iOS 15, 16 了，所以現在是個好時機，好好使用 SwiftUI，可以把專案內一些比較不重要，且單純又獨立的頁面或功能，嘗試 SwiftUI + TCA 了。

最後附上 [demo](https://github.com/chengyang1380/SwiftUI_TCA_Practice)，使用 Xcode 16.4，TCA 1.20.2

# 參考了

- [https://onevcat.com/2021/12/tca-1/](https://onevcat.com/2021/12/tca-1/)
- [https://onevcat.com/2021/12/tca-2/](https://onevcat.com/2021/12/tca-2/)
- [https://onevcat.com/2022/03/tca-3/](https://onevcat.com/2022/03/tca-3/)
- [https://onevcat.com/2022/05/tca-4/](https://onevcat.com/2022/05/tca-4/)
