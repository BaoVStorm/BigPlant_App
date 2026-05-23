import '../domain/models/chat_message.dart';

class MockAiChatRepository {
  Future<List<AiChatMessage>> loadInitialConversation({
    AiChatMockScenario scenario = AiChatMockScenario.longConversation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return scenario == AiChatMockScenario.shortConversation
        ? _shortConversation()
        : _longConversation();
  }

  Future<AiChatMessage> buildReplyFor(AiChatMessage userMessage) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (userMessage.hasAttachment) {
      return AiChatMessage.assistantInsight(
        id: 'reply-${DateTime.now().microsecondsSinceEpoch}',
        sentAt: DateTime.now(),
        text:
            'Dua tren hinh anh ban gui, cay co dau hieu thieu am. Mep la kho, gion va chuyen nau thuong lien quan toi moi truong qua kho hoac tuoi chua du sau.',
        insightTitle: 'Goi y khac phuc:',
        checklistItems: const [
          'Thu phun suong cho la 1-2 lan moi ngay.',
          'Chi tuoi dam khi 3-4cm dat be mat da kho.',
          'Tranh dat cay duoi huong gio dieu hoa lien tuc.',
        ],
        followUpPrompt:
            'Ban co muon toi tao mot lich nhac tuoi nuoc va phun suong cho cay nay khong?',
        quickReplies: const [
          'Co, giup toi len lich',
          'Tim hieu them ve benh nay',
        ],
      );
    }

    return AiChatMessage.assistantText(
      id: 'reply-${DateTime.now().microsecondsSinceEpoch}',
      sentAt: DateTime.now(),
      text:
          'Toi da ghi nhan yeu cau cua ban. Khi backend AI chat duoc noi, cau tra loi chi tiet se duoc thay the truc tiep tai bubble nay ma khong can sua UI.',
    );
  }

  AiChatAttachment buildMockAttachment() {
    return const AiChatAttachment(
      id: 'draft-monstera-leaf',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCU0ZXPlbeJy7Z4LE4aR5IXovIOUay1xr_sqB4YYziuwD-8m4Wpq9oML-weot-Q4A2vAgENN770T7c4sajO7SAuWHbqACssJ48xjv0aT1VSA1-PxGOeXSPESPVdQXBAdfXIDZQu3gEXTLU9pOdiwQX-O_fDS2hrGGoGsYY2faNs0eDqqoXizWHVRmKBOxsZgcFVZztLxEgxEu1ix4d35OK_f2IPWdMP--Yf1Qgne2CDi9jMrlnF4yzW2xHh8-HngxbT-52RoRbijLK5',
      altText: 'Anh la Monstera bi kho mep.',
      aspectRatio: 1,
      caption: 'Anh la Monstera bi kho mep.',
    );
  }

  List<AiChatMessage> _shortConversation() {
    return [
      AiChatMessage.assistantText(
        id: 'welcome-short',
        sentAt: DateTime(2026, 5, 19, 9, 41),
        text:
            'Xin chao! Toi la tro ly AI cua BigPlant. Toi co the ho tro nhan dien cay, goi y cham soc va giai dap cac cau hoi ve thuc vat.',
      ),
      AiChatMessage.userText(
        id: 'user-short-1',
        sentAt: DateTime(2026, 5, 19, 9, 45),
        text: 'Chao BigPlant, cho toi mot goi y cham soc nhanh cho cay ZZ Plant.',
      ),
      AiChatMessage.assistantText(
        id: 'assistant-short-1',
        sentAt: DateTime(2026, 5, 19, 9, 46),
        text:
            'ZZ Plant thich anh sang gian tiep va rat so bi tuoi qua tay. Hay doi dat kho ro moi tuoi lai, uu tien dat thoat nuoc nhanh.',
      ),
    ];
  }

  List<AiChatMessage> _longConversation() {
    final attachment = buildMockAttachment();
    return [
      AiChatMessage.assistantText(
        id: 'welcome-long',
        sentAt: DateTime(2026, 5, 19, 9, 41),
        text:
            'Xin chao! Toi la tro ly AI cua BigPlant. Toi co the giup ban nhan dien cay trong, tu van cach cham soc hoac giai dap thac mac ve thuc vat. Ban can toi giup gi hom nay?',
      ),
      AiChatMessage.userImage(
        id: 'user-long-1',
        sentAt: DateTime(2026, 5, 19, 9, 45),
        text:
            'Chao BigPlant, cay Monstera cua toi dao nay la bi kho o mep, ban xem giup no bi lam sao nhe.',
        attachment: attachment,
      ),
      AiChatMessage.assistantInsight(
        id: 'assistant-long-1',
        sentAt: DateTime(2026, 5, 19, 9, 46),
        text:
            'Dua tren hinh anh ban gui, cay Monstera cua ban dang co dau hieu thieu am. Mep la kho, gion va chuyen sang mau nau thuong do moi truong qua kho hoac tuoi nuoc chua du sau.',
        insightTitle: 'Goi y khac phuc:',
        checklistItems: const [
          'Hay thu phun suong them cho la 1-2 lan moi ngay.',
          'Dam bao dat kho khoang 3-4cm be mat truoc khi tuoi dam lai.',
          'Tranh dat cay truc tiep duoi huong gio dieu hoa.',
        ],
        followUpPrompt:
            'Ban co muon toi len lich nhac nho tuoi nuoc va phun suong cho cay nay khong?',
        quickReplies: const [
          'Co, giup toi len lich',
          'Tim hieu them ve benh nay',
        ],
      ),
    ];
  }
}
