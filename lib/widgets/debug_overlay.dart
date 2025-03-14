import 'package:flutter/material.dart';
import '../services/logging_service.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const DebugOverlay({
    Key? key,
    required this.child,
    this.enabled = false,
  }) : super(key: key);

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _showOverlay = false;
  final LoggingService _logger = LoggingService();
  LogLevel _filterLevel = LogLevel.debug;
  String _searchQuery = '';
  String? _filterTag;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      textDirection: TextDirection.ltr, // Add explicit text direction
      children: [
        widget.child,
        if (_showOverlay)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.8),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildDebugHeader(),
                    _buildFilterBar(),
                    Expanded(
                      child: _buildLogViewer(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildDebugButton(),
        ),
      ],
    );
  }

  Widget _buildDebugButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.grey.withOpacity(0.7),
      child: Icon(
        _showOverlay ? Icons.close : Icons.bug_report,
        color: Colors.white,
      ),
      onPressed: () {
        setState(() {
          _showOverlay = !_showOverlay;
        });
      },
    );
  }

  Widget _buildDebugHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[850],
      child: Row(
        children: [
          const Text(
            'Debug Console',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                // Refresh logs
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              _logger.clearLogs();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _showOverlay = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[900],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search logs...',
                    hintStyle: TextStyle(color: Colors.grey),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                    fillColor: Colors.black45,
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<LogLevel>(
                value: _filterLevel,
                dropdownColor: Colors.grey[850],
                style: const TextStyle(color: Colors.white),
                underline: Container(
                  height: 1,
                  color: Colors.white30,
                ),
                onChanged: (LogLevel? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _filterLevel = newValue;
                    });
                  }
                },
                items: LogLevel.values.map<DropdownMenuItem<LogLevel>>((LogLevel level) {
                  return DropdownMenuItem<LogLevel>(
                    value: level,
                    child: Text(
                      level.name.toUpperCase(),
                      style: TextStyle(
                        color: _getLogLevelColor(level),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTagFilterChip(null, 'All'),
                ..._getUniqueTags().map((tag) => _buildTagFilterChip(tag, tag)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilterChip(String? tag, String label) {
    final isSelected = _filterTag == tag;
    
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterTag = selected ? tag : null;
          });
        },
        backgroundColor: Colors.grey[800],
        selectedColor: Colors.blue[300],
        checkmarkColor: Colors.black,
      ),
    );
  }

  List<String> _getUniqueTags() {
    final logs = _logger.getLogs();
    final tags = <String>{};
    
    for (final log in logs) {
      if (log.tag != null) {
        tags.add(log.tag!);
      }
    }
    
    return tags.toList()..sort();
  }

  Widget _buildLogViewer() {
    final logs = _logger.getLogs(minLevel: _filterLevel);
    
    // Apply filters
    final filteredLogs = logs.where((log) {
      // Apply tag filter
      if (_filterTag != null && log.tag != _filterTag) {
        return false;
      }
      
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        return log.message.toLowerCase().contains(searchLower) ||
            (log.tag?.toLowerCase().contains(searchLower) ?? false) ||
            (log.error?.toLowerCase().contains(searchLower) ?? false);
      }
      
      return true;
    }).toList();
    
    if (filteredLogs.isEmpty) {
      return const Center(
        child: Text(
          'No logs match the current filters',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    final color = _getLogLevelColor(log.level);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '[${log.level.name.toUpperCase()}]',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (log.tag != null) ...[
                const SizedBox(width: 4),
                Text(
                  '[${log.tag}]',
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Text(
            log.message,
            style: TextStyle(color: color),
          ),
          if (log.error != null)
            Text(
              'Error: ${log.error}',
              style: TextStyle(color: Colors.red[300], fontSize: 12),
            ),
          if (log.stackTrace != null)
            Text(
              log.stackTrace!,
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.white;
      case LogLevel.warning:
        return Colors.yellow;
      case LogLevel.error:
        return Colors.orange;
      case LogLevel.critical:
        return Colors.red;
    }
  }
}
