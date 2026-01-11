import 'dart:convert';
import 'dart:developer';
import 'dart:ui' as ui;

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
  final TextEditingController _customInputController = TextEditingController();
  ui.TextDirection inputDirection = ui.TextDirection.ltr;
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
        title: Text(
          "Stocky AI".tr(),
          style: TextStyle(color: colorScheme.onBackground),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onBackground,
      ),
      body: _buildUI(),
    );
  }

  getDirection(String text) {
    if (text.isEmpty) return ui.TextDirection.ltr;

    final firstChar = text.characters.first;
    final isRtl = RegExp(r'^[\u0600-\u06FF]').hasMatch(firstChar);
    return isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr;
  }

  Widget _buildUI() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    // You need a controller for your custom input

    return Column(
      // 1. Wrap everything in a Column
      children: [
        Expanded(
          child: DashChat(
            currentUser: currentUser,
            // 2. We handle sending manually now, but we keep this required param.
            // Note: DashChat might still show an input bar.
            // To hide it completely, check if your version supports 'readOnly: true'
            // or simply ignore the built-in input and use yours.
            onSend: (ChatMessage m) {
              // This is only for the BUILT-IN input.
              _sendToGoogle(m);
            },
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
                        // ... (rest of your markdown styles)
                      ),
                );
              },
            ),
            // 3. Hide the default input bar so we can use our own
            // (If your version of DashChat doesn't hide it with readOnly,
            // you might need to set inputOptions to have height 0 or invisible)
            readOnly: true,
          ),
        ),

        // 4. YOUR CUSTOM INPUT BAR WITH SPELL CHECK
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      inputDirection = getDirection(val);
                    });
                  },
                  textAlign: inputDirection == ui.TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  textDirection: inputDirection,
                  controller: _customInputController,
                  style: TextStyle(color: colorScheme.onSurface),

                  // --- THE SPELL CHECK CONFIGURATION ---
                  spellCheckConfiguration: SpellCheckConfiguration(
                    misspelledTextStyle: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.red,
                      decorationStyle: TextDecorationStyle.wavy,
                    ),
                  ),

                  // -------------------------------------
                  decoration: InputDecoration(
                    hintTextDirection: ui.TextDirection.rtl,

                    hint: Text(
                      "Ask about your stock...".tr(),
                      textAlign: context.locale.languageCode == 'ar'
                          ? TextAlign.right
                          : TextAlign.left,
                    ),
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor:
                        colorScheme.surface, // Adjust to match your design
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      // Create the message object manually
                      final newMessage = ChatMessage(
                        text: value,
                        user: currentUser,
                        createdAt: DateTime.now(),
                      );
                      _sendToGoogle(newMessage);
                      _customInputController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Custom Send Button
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  alignment: Alignment.center,
                  icon: Icon(
                    Icons.send_rounded,
                    color: colorScheme.onPrimary,
                    size: 28,
                  ),
                  onPressed: () {
                    if (_customInputController.text.trim().isNotEmpty) {
                      final newMessage = ChatMessage(
                        text: _customInputController.text,
                        user: currentUser,
                        createdAt: DateTime.now(),
                      );
                      _sendToGoogle(newMessage);
                      _customInputController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),
      ],
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
