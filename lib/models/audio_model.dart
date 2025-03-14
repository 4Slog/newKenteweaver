enum AudioType {
  storyTheme('story_theme.mp3'),
  learningTheme('learning_theme.mp3'),
  challengeTheme('challenge_theme.mp3'),
  success('success.mp3'),
  failure('failure.mp3'),
  buttonTap('button_tap.mp3'),
  confirmationTap('confirmation_tap.mp3'),
  cancelTap('cancel_tap.mp3'),
  navigationTap('navigation_tap.mp3'),
  achievement('achievement.mp3'),
  click('click.mp3'),
  complete('complete.mp3');

  final String filename;
  const AudioType(this.filename);
} 