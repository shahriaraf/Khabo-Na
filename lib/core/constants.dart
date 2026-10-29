const reasons = ['Hungry', 'Pressure', 'Stress', 'Boredom', 'Planned'];
const met = {'Walking': 3.5, 'Running': 9.0, 'Cycling': 7.0, 'Housework': 3.0, 'Standing work': 2.0, 'Desk work / study': 1.3};
const defaultReplies = ["I've eaten, thank you. It was delicious.", 'Can I take a small portion?', 'I will eat it later, please keep it for me.', 'I am following a plan to be healthy. Please support me.'];


class AppConfig {
  // Set at build time: --dart-define=API_BASE=https://your-server --dart-define=APP_TOKEN=secret
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:8787');
  static const appToken = String.fromEnvironment('APP_TOKEN', defaultValue: 'dev-token');
}
