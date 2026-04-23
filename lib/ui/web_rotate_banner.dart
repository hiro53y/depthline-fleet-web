import 'package:flutter/material.dart';

class WebRotateBanner extends StatelessWidget {
  const WebRotateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xDD08131B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x883BB2D0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const DefaultTextStyle(
            style: TextStyle(
              color: Color(0xFFE5F8FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'WEB版は横向き推奨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'スマホを横向きにすると、操作ボタンとレーダーが見やすくなります。',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
