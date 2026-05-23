# AI Chat Feature

## Muc tieu
- Feature nay dung de build UI `AI Chat Tab` truoc khi noi navigation that.
- Toan bo du lieu dang duoc mock theo kieu `load tu db` va `reply tu backend`, de sau nay doi sang API that ma khong can viet lai UI.

## Cau truc file
- `domain/models/chat_message.dart`
  - model du lieu chat
  - enum role user/assistant
  - attachment model cho image chat
  - support text message va image message
- `data/mock_ai_chat_repository.dart`
  - gia lap load lich su hoi thoai tu db
  - gia lap tao AI reply sau khi user gui tin nhan
  - co 2 scenario mock:
    - `AiChatMockScenario.shortConversation`
    - `AiChatMockScenario.longConversation`
- `presentation/widgets/chat_message_bubbles.dart`
  - `AiTextMessageBubble`
  - `AiInsightMessageBubble`
  - `AiImageMessageBubble`
  - `UserTextMessageBubble`
  - `UserImageMessageBubble`
  - `AiChatQuickReplies`
  - `AiChatDayDivider`
  - `AiChatTimestamp`
  - `AiChatBottomNavPreview`
- `presentation/widgets/chat_composer.dart`
  - o nhap chat
  - draft attachment preview
  - send button
- `presentation/screens/ai_chat_tab.dart`
  - ghep tat ca component lai thanh man hinh chat hoan chinh

## 2 loai bubble chinh

### 1. Chat thuong
- User:
  - `UserTextMessageBubble`
- AI:
  - `AiTextMessageBubble`
  - Neu AI co structured advice thi dung `AiInsightMessageBubble`

### 2. Chat co hinh anh
- User:
  - `UserImageMessageBubble`
- AI:
  - `AiImageMessageBubble`

## Cach dung screen

```dart
const AiChatTab()
```

Hoac de test case chat it:

```dart
const AiChatTab(
  scenario: AiChatMockScenario.shortConversation,
)
```

Hoac de dung trong app shell that sau nay va bo preview bottom nav:

```dart
const AiChatTab(
  showBottomNavPreview: false,
)
```

## Cach gui message tu code
- Screen se goi `_sendCurrentDraft()`.
- Neu co `draftAttachment` thi tao `AiChatMessage.userImage(...)`.
- Neu khong co attachment thi tao `AiChatMessage.userText(...)`.
- Sau do append vao list va goi repository de lay AI reply mock.

## Cach map API/db that sau nay

### Load lich su chat tu db
- Thay `MockAiChatRepository.loadInitialConversation()` bang repository that.
- Tra ve `List<AiChatMessage>`.

### Gui message len backend
- Thay `MockAiChatRepository.buildReplyFor(...)` bang use case call API.
- Response backend can map ve `AiChatMessage.assistantText(...)` hoac `AiChatMessage.assistantInsight(...)`.

## Xu ly case chat it va chat nhieu
- Chat it:
  - `ListView` van hien top-aligned tu nhien, khong stretch bubble.
- Chat nhieu:
  - screen dung `ScrollController`
  - sau moi lan load thread hoac gui message, se auto-scroll xuong cuoi
  - quick replies dung horizontal scroll rieng
  - input composer support multi-line va gioi han max height

## Ghi chu tich hop
- Hien chua noi vao `MainShellScreen` theo yeu cau.
- Co the them route hoac them tab sau nay ma khong can sua lai bubble/component.
