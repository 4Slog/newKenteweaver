import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/lesson_type.dart';
import '../providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class AssessmentScreen extends StatefulWidget {
  final Lesson lesson;

  const AssessmentScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool _isLoading = false;
  String? _error;
  int _currentQuestionIndex = 0;
  final List<Map<String, dynamic>> _answers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _error = null),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / widget.lesson.content['questions'].length,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        Expanded(
          child: _buildQuestion(),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    final questions = widget.lesson.content['questions'] as List;
    if (_currentQuestionIndex >= questions.length) {
      return const Center(
        child: Text('Assessment Complete!'),
      );
    }

    final question = questions[_currentQuestionIndex] as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1} of ${questions.length}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question['text'] as String,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ..._buildAnswerOptions(question),
        ],
      ),
    );
  }

  List<Widget> _buildAnswerOptions(Map<String, dynamic> question) {
    final options = question['options'] as List;
    return options.map((option) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ElevatedButton(
          onPressed: () => _selectAnswer(option),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
          ),
          child: Text(option['text'] as String),
        ),
      );
    }).toList();
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Exit'),
            ),
            ElevatedButton(
              onPressed: _answers.isEmpty ? null : _submitAssessment,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(Map<String, dynamic> answer) {
    setState(() {
      _answers.add({
        'questionIndex': _currentQuestionIndex,
        'selectedAnswer': answer,
      });
      
      if (_currentQuestionIndex < widget.lesson.content['questions'].length - 1) {
        _currentQuestionIndex++;
      }
    });
  }

  Future<void> _submitAssessment() async {
    try {
      setState(() => _isLoading = true);

      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      // Calculate score based on correct answers
      var correctAnswers = 0;
      final questions = widget.lesson.content['questions'] as List;
      
      for (final answer in _answers) {
        final questionIndex = answer['questionIndex'] as int;
        final selectedAnswer = answer['selectedAnswer'] as Map<String, dynamic>;
        final question = questions[questionIndex] as Map<String, dynamic>;
        
        if (selectedAnswer['isCorrect'] as bool) {
          correctAnswers++;
        }
      }

      final score = correctAnswers / questions.length;
      final attemptData = {
        'timestamp': DateTime.now().toIso8601String(),
        'score': score,
        'answers': _answers,
      };

      await appState.recordProgress(
        lessonId: widget.lesson.id,
        score: score,
        data: attemptData,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Failed to submit assessment: $e';
        _isLoading = false;
      });
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assessment Help'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Difficulty: ${widget.lesson.difficulty.toString().split('.').last}'),
              const SizedBox(height: 16),
              const Text('Instructions:'),
              const SizedBox(height: 8),
              Text(widget.lesson.description),
              const SizedBox(height: 16),
              const Text('Tips:'),
              const SizedBox(height: 8),
              const Text('• Read each question carefully'),
              const Text('• Select the best answer'),
              const Text('• You can\'t change answers once selected'),
              if (widget.lesson.prerequisites.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Required Knowledge:'),
                const SizedBox(height: 8),
                Text(widget.lesson.prerequisites.join(', ')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
