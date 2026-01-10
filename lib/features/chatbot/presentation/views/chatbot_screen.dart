import 'dart:convert';
import 'dart:developer';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gdrive_tutorial/services/gAi_service.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';

class ChatbotScreen extends StatefulWidget {
  static String id = "ChatbotScreen";
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final GSheetService gSheetService = GSheetService();
  // final Gemini gemini = Gemini.instance;
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    // profileImage: "assets/gemini_logo.png",
  );
  List<ChatMessage> messages = [];
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> allSales = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getallProducts();
    getAllSales();
  }

  @override
  void dispose() {
    super.dispose();
    messages.clear();
  }

  Future<void> getallProducts() async {
    allProducts = await gSheetService.getProducts();
    final allProductjson = jsonEncode(allProducts);

    log("\n product is : $allProductjson");
  }

  Future<void> getAllSales() async {
    allSales = await gSheetService.getSales();
    final allSalesjson = jsonEncode(allSales);
    allSales.toString();
    log("\n sales is : $allSalesjson");
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text("Stocky AI".tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.primary,
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return DashChat(
      currentUser: currentUser,
      onSend: _sendToGoogle,
      messages: messages,
      messageOptions: MessageOptions(
        currentUserContainerColor: colorScheme.primary,
        containerColor: colorScheme.surface,
        currentUserTextColor: colorScheme.onPrimary,
        textColor: colorScheme.onSurface,
        messageTextBuilder: (message, _, __) {
          if (message.text.startsWith("Thinking")) {
            return AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  '...',
                  textStyle: TextStyle(color: colorScheme.onSurface),
                ),
              ],
              repeatForever: true,
              pause: const Duration(seconds: 1),
              isRepeatingAnimation: true,
            );
          }
          final isCurrentUser = message.user == currentUser;
          return MarkdownBody(
            data: message.text,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: TextStyle(
                    color: isCurrentUser
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  listBullet: TextStyle(
                    color: isCurrentUser
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  strong: TextStyle(
                    color: isCurrentUser
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color: isCurrentUser
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          );
        },
      ),
      inputOptions: InputOptions(
        sendButtonBuilder: (onSend) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            onPressed: onSend,
          ),
        ),
        inputTextStyle: TextStyle(color: colorScheme.onSurface),
        inputDecoration: InputDecoration(
          hintText: "Ask about your stock...".tr(),
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  _sendToGoogle(ChatMessage newMessage) async {
    FocusScope.of(context).unfocus();
    setState(() {
      messages = [newMessage, ...messages];
    });

    final thinkingMessage = ChatMessage(
      user: geminiUser,
      createdAt: DateTime.now(),
      text: "Thinking",
    );
    final reversedMessages = messages.reversed;
    final allMessages = reversedMessages
        .map((msg) {
          final role = msg.user == geminiUser ? "AI" : "User";
          return "$role: ${msg.text}";
        })
        .join("\n");
    log(allMessages);
    setState(() {
      messages = [thinkingMessage, ...messages];
    });

    final res = await GoogleAiService.generateText(
      notes: allMessages,
      allProducts: allProducts,
      allSales: allSales,
    );

    setState(() {
      messages.remove(thinkingMessage);
    });
    setState(() {
      messages = [
        ChatMessage(user: geminiUser, createdAt: DateTime.now(), text: res),
        ...messages,
      ];
    });
  }
}
