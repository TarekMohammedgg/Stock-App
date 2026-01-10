import 'package:flutter/material.dart';
// import 'package:gdrive_tutorial/core/app_theme.dart';

class ConnectionErrorScreen extends StatelessWidget {
  const ConnectionErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi, color: Theme.of(context).primaryColor),
                SizedBox(width: 5),
                Text(
                  "Offline Access to Internet",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
