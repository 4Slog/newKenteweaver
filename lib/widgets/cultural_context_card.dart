import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CulturalContextCard extends StatefulWidget {
  final String title;
  final String description;
  final String? imageAsset;
  final IconData fallbackIcon;
  final VoidCallback? onLearnMore;
  final bool expandable;
  final bool initiallyExpanded;

  const CulturalContextCard({
    Key? key,
    required this.title,
    required this.description,
    this.imageAsset,
    this.fallbackIcon = Icons.history_edu,
    this.onLearnMore,
    this.expandable = true,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<CulturalContextCard> createState() => _CulturalContextCardState();
}

class _CulturalContextCardState extends State<CulturalContextCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.kenteGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section always visible
          InkWell(
            onTap: widget.expandable ? _toggleExpanded : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildImage(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!widget.expandable || !_isExpanded)
                          Text(
                            _getShortDescription(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (widget.expandable)
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5)
                          .animate(_controller),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                ],
              ),
            ),
          ),

          // Expandable content
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller.view,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightFactor.value,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (widget.onLearnMore != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: TextButton.icon(
                          onPressed: widget.onLearnMore,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Learn More'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.kenteBlue,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          widget.imageAsset!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
        ),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.kenteGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        widget.fallbackIcon,
        size: 30,
        color: AppTheme.kenteGold,
      ),
    );
  }

  String _getShortDescription() {
    if (widget.description.length <= 50) {
      return widget.description;
    }

    return '${widget.description.substring(0, 47)}...';
  }
}

// Factory constructors for common cultural cards
class KenteCulturalCards {
  static CulturalContextCard colorMeanings({VoidCallback? onLearnMore}) {
    return CulturalContextCard(
      title: 'Kente Color Meanings',
      description: 'In traditional Kente cloth, colors carry specific cultural meanings. Gold represents royalty and wealth, blue symbolizes peace and harmony, red signifies spiritual energy and lifeblood, green represents growth and renewal, black represents maturity and spiritual connection to ancestors, and white symbolizes purification and festive occasions.',
      imageAsset: 'assets/images/tutorial/color_meaning_diagram.png',
      fallbackIcon: Icons.palette,
      onLearnMore: onLearnMore,
    );
  }

  static CulturalContextCard patternMeanings({VoidCallback? onLearnMore}) {
    return CulturalContextCard(
      title: 'Traditional Patterns',
      description: 'Kente patterns each tell a story. The Dame-Dame (checker) pattern represents duality in Akan philosophy. Babadua (horizontal stripes) symbolizes cooperation. Kente cloth is traditionally woven by men on narrow looms, with strips sewn together to create larger cloths for royalty and important ceremonies.',
      imageAsset: 'assets/images/tutorial/basic_pattern_explanation.png',
      fallbackIcon: Icons.grid_on,
      onLearnMore: onLearnMore,
    );
  }

  static CulturalContextCard historicalContext({VoidCallback? onLearnMore}) {
    return CulturalContextCard(
      title: 'History of Kente Cloth',
      description: 'Kente originated with the Asante people of Ghana in the 17th century, though the art of weaving in the region dates back to 3000 BCE. According to legend, two friends learned the art of weaving by observing a spider weaving its web. Originally worn by royalty and spiritual leaders during special ceremonies, Kente has evolved to become a symbol of African pride and heritage worldwide.',
      fallbackIcon: Icons.history_edu,
      onLearnMore: onLearnMore,
    );
  }

  static CulturalContextCard modernSignificance({VoidCallback? onLearnMore}) {
    return CulturalContextCard(
      title: 'Modern Significance',
      description: 'Today, Kente cloth has transcended its origins to become a powerful symbol of African identity, pride, and connection to heritage. It appears in academic graduation ceremonies, cultural celebrations, and as a fashion statement worldwide. The distinctive patterns continue to inspire modern design while maintaining their deep cultural significance.',
      fallbackIcon: Icons.auto_awesome,
      onLearnMore: onLearnMore,
    );
  }
}
