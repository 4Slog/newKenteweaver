import 'package:flutter/material.dart';

/// A widget that showcases UI enhancement features
class EnhancedUIShowcase extends StatefulWidget {
  /// Creates a new enhanced UI showcase widget
  const EnhancedUIShowcase({Key? key}) : super(key: key);

  @override
  State<EnhancedUIShowcase> createState() => _EnhancedUIShowcaseState();
}

class _EnhancedUIShowcaseState extends State<EnhancedUIShowcase> {
  // UI settings
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.orange;
  double _animationSpeed = 1.0;
  bool _reduceMotion = false;
  bool _highContrastMode = false;
  double _textScaleFactor = 1.0;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('UI Enhancement Settings'),
          const SizedBox(height: 24),
          
          _buildThemeSettings(),
          const SizedBox(height: 24),
          
          _buildAccessibilitySettings(),
          const SizedBox(height: 24),
          
          _buildUIComponentsShowcase(),
          const SizedBox(height: 24),
          
          _buildSaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildThemeSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Theme mode
            ListTile(
              title: const Text('Theme Mode'),
              trailing: DropdownButton<ThemeMode>(
                value: _themeMode,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _themeMode = value;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
              ),
            ),
            
            // Primary color
            ListTile(
              title: const Text('Primary Color'),
              trailing: _buildColorPicker(_primaryColor, (color) {
                setState(() {
                  _primaryColor = color;
                });
              }),
            ),
            
            // Accent color
            ListTile(
              title: const Text('Accent Color'),
              trailing: _buildColorPicker(_accentColor, (color) {
                setState(() {
                  _accentColor = color;
                });
              }),
            ),
            
            // Animation speed
            ListTile(
              title: const Text('Animation Speed'),
              subtitle: Slider(
                value: _animationSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 3,
                label: _getAnimationSpeedLabel(_animationSpeed),
                onChanged: (value) {
                  setState(() {
                    _animationSpeed = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccessibilitySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Reduce motion
            SwitchListTile(
              title: const Text('Reduce Motion'),
              subtitle: const Text('Minimize animations throughout the app'),
              value: _reduceMotion,
              onChanged: (value) {
                setState(() {
                  _reduceMotion = value;
                });
              },
            ),
            
            // High contrast mode
            SwitchListTile(
              title: const Text('High Contrast Mode'),
              subtitle: const Text('Increase contrast for better visibility'),
              value: _highContrastMode,
              onChanged: (value) {
                setState(() {
                  _highContrastMode = value;
                });
              },
            ),
            
            // Text scale factor
            ListTile(
              title: const Text('Text Size'),
              subtitle: Slider(
                value: _textScaleFactor,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(_textScaleFactor * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _textScaleFactor = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUIComponentsShowcase() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UI Components Showcase',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Enhanced buttons
            Text(
              'Enhanced Buttons',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildEnhancedButton(
                  label: 'Primary',
                  onPressed: () {},
                  backgroundColor: _primaryColor,
                ),
                _buildEnhancedButton(
                  label: 'Secondary',
                  onPressed: () {},
                  backgroundColor: Colors.grey.shade300,
                  textColor: Colors.black87,
                ),
                _buildEnhancedButton(
                  label: 'Accent',
                  onPressed: () {},
                  backgroundColor: _accentColor,
                ),
                _buildEnhancedButton(
                  label: 'Disabled',
                  onPressed: null,
                  backgroundColor: _primaryColor.withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Enhanced cards
            Text(
              'Enhanced Cards',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildEnhancedCard(
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('This is an enhanced card with animations and accessibility features.'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Enhanced text fields
            Text(
              'Enhanced Text Fields',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildEnhancedTextField(
              label: 'Name',
              hint: 'Enter your name',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 8),
            _buildEnhancedTextField(
              label: 'Email',
              hint: 'Enter your email',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // Enhanced list items
            Text(
              'Enhanced List Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildEnhancedListItem(
              title: 'List Item 1',
              subtitle: 'This is a description for list item 1',
              leading: Icons.star,
              onTap: () {},
            ),
            _buildEnhancedListItem(
              title: 'List Item 2',
              subtitle: 'This is a description for list item 2',
              leading: Icons.favorite,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSaveButton() {
    return Center(
      child: _buildEnhancedButton(
        label: 'Save Settings',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved')),
          );
        },
        backgroundColor: _primaryColor,
        icon: Icons.save,
      ),
    );
  }
  
  Widget _buildColorPicker(Color currentColor, Function(Color) onColorChanged) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Color'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    onColorChanged(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == currentColor ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEnhancedButton({
    required String label,
    required Function()? onPressed,
    required Color backgroundColor,
    Color textColor = Colors.white,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    // Create button with or without icon
    Widget buttonChild;
    
    if (isLoading) {
      buttonChild = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor)),
        ],
      );
    } else {
      buttonChild = Text(label, style: TextStyle(color: textColor));
    }
    
    // Create button with appropriate animation
    final buttonWidget = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: buttonChild,
    );
    
    // Apply animations if enabled
    if (!_reduceMotion) {
      return AnimatedContainer(
        duration: Duration(milliseconds: (300 / _animationSpeed).round()),
        width: fullWidth ? double.infinity : null,
        child: buttonWidget,
      );
    } else {
      return Container(
        width: fullWidth ? double.infinity : null,
        child: buttonWidget,
      );
    }
  }
  
  Widget _buildEnhancedCard({
    required Widget child,
    bool interactive = false,
    Function()? onTap,
    double elevation = 2.0,
  }) {
    final cardWidget = Card(
      elevation: _highContrastMode ? elevation * 2 : elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _highContrastMode
            ? BorderSide(color: Theme.of(context).dividerColor)
            : BorderSide.none,
      ),
      child: interactive
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: child,
            )
          : child,
    );
    
    // Apply animations if enabled
    if (!_reduceMotion) {
      return AnimatedContainer(
        duration: Duration(milliseconds: (300 / _animationSpeed).round()),
        child: cardWidget,
      );
    } else {
      return cardWidget;
    }
  }
  
  Widget _buildEnhancedTextField({
    required String label,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    Function()? onSuffixIconTap,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    final textField = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: 16 * _textScaleFactor,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixIconTap,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _highContrastMode
                ? Colors.black
                : Theme.of(context).dividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _primaryColor,
            width: _highContrastMode ? 2 : 1,
          ),
        ),
      ),
    );
    
    // Apply animations if enabled
    if (!_reduceMotion) {
      return AnimatedContainer(
        duration: Duration(milliseconds: (300 / _animationSpeed).round()),
        child: textField,
      );
    } else {
      return textField;
    }
  }
  
  Widget _buildEnhancedListItem({
    required String title,
    String? subtitle,
    IconData? leading,
    Widget? trailing,
    Function()? onTap,
  }) {
    final listItem = ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16 * _textScaleFactor,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14 * _textScaleFactor,
              ),
            )
          : null,
      leading: leading != null
          ? Icon(
              leading,
              color: _highContrastMode ? Colors.black : _primaryColor,
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
    
    // Apply animations if enabled
    if (!_reduceMotion) {
      return AnimatedContainer(
        duration: Duration(milliseconds: (300 / _animationSpeed).round()),
        child: listItem,
      );
    } else {
      return listItem;
    }
  }
  
  String _getAnimationSpeedLabel(double speed) {
    if (speed <= 0.5) return 'Slow';
    if (speed <= 1.0) return 'Normal';
    if (speed <= 1.5) return 'Fast';
    return 'Very Fast';
  }
} 