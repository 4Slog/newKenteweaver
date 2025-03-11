import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A popup dialog that displays feedback, suggestions, and actions to the user.
///
/// This component is used for showing AI feedback, pattern validation results,
/// and other interactive feedback throughout the application.
class FeedbackPopup extends StatelessWidget {
  /// The title of the feedback popup
  final String title;

  /// The main message to display
  final String message;

  /// Whether the feedback represents a success state
  final bool isSuccess;

  /// List of suggestions to display
  final List<String> suggestions;

  /// Callback when the popup is closed
  final VoidCallback? onClose;

  /// Callback when the primary action button is pressed
  final VoidCallback? onAction;

  /// Label for the primary action button (null to hide button)
  final String? actionLabel;

  /// Optional icon to display next to the title
  final IconData? icon;

  /// Optional widget to display below the message (such as an image or chart)
  final Widget? contentWidget;

  const FeedbackPopup({
    Key? key,
    required this.title,
    required this.message,
    this.isSuccess = true,
    this.suggestions = const [],
    this.onClose,
    this.onAction,
    this.actionLabel,
    this.icon,
    this.contentWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                const Divider(),

                // Message
                _buildMessage(context),

                // Optional content widget
                if (contentWidget != null) ...[
                  const SizedBox(height: 16),
                  contentWidget!,
                ],

                // Suggestions
                if (suggestions.isNotEmpty) ...[
                  const Divider(),
                  _buildSuggestions(context),
                ],

                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section with title and close button
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? (isSuccess ? Icons.check_circle : Icons.info_outline),
                color: isSuccess ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isSuccess ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose ?? () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
      ],
    );
  }

  /// Builds the main message section
  Widget _buildMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 36), // Align with the title text
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the suggestions section
  Widget _buildSuggestions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 8),
            child: Text(
              'Suggestions:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 36),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Builds the action buttons section
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Close/Cancel button
          TextButton(
            onPressed: onClose ?? () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),

          // Action button (if provided)
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kenteGold,
                foregroundColor: Colors.black,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }

  /// Static method to show a success feedback dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    List<String> suggestions = const [],
    VoidCallback? onAction,
    String? actionLabel,
    Widget? contentWidget,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => FeedbackPopup(
        title: title,
        message: message,
        isSuccess: true,
        suggestions: suggestions,
        onAction: onAction,
        actionLabel: actionLabel,
        contentWidget: contentWidget,
      ),
    );
  }

  /// Static method to show an error feedback dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    List<String> suggestions = const [],
    VoidCallback? onAction,
    String? actionLabel,
    Widget? contentWidget,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => FeedbackPopup(
        title: title,
        message: message,
        isSuccess: false,
        suggestions: suggestions,
        onAction: onAction,
        actionLabel: actionLabel,
        contentWidget: contentWidget,
        icon: Icons.error_outline,
      ),
    );
  }

  /// Static method to show an informational feedback dialog
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    List<String> suggestions = const [],
    VoidCallback? onAction,
    String? actionLabel,
    Widget? contentWidget,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => FeedbackPopup(
        title: title,
        message: message,
        isSuccess: true,
        suggestions: suggestions,
        onAction: onAction,
        actionLabel: actionLabel,
        contentWidget: contentWidget,
        icon: Icons.info_outline,
      ),
    );
  }
}
