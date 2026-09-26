import 'package:flutter/material.dart';
import 'package:tiger_hacks_frontend/util.dart' show themeSeedColor;

class LiveView extends StatefulWidget {
  const LiveView({
    super.key,
    required this.title,
    required this.placeholder,
    this.compact = false,
  });

  final String title;
  final String placeholder;
  final bool compact;

  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {
  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return compact
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title),
                const SizedBox(height: 6),
                Container(
                  height: 112,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.placeholder),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: themeSeedColor.withAlpha(50),
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    widget.placeholder,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ],
          );
  }
}
