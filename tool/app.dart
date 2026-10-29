import 'dart:io';

Future<void> run(String cmd, List<String> args) async {
  final p = await Process.start(cmd, args, mode: ProcessStartMode.inheritStdio, runInShell: true);
  if (await p.exitCode != 0) { stderr.writeln('Failed: $cmd ${args.join(' ')}'); exit(1); }
}

void patchManifest() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  var s = f.readAsStringSync();
  if (s.contains('POST_NOTIFICATIONS')) return;
  const perms = '''<uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>''';
  const recv = '''<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>''';
  s = s.replaceFirst('<application', '$perms\n    <application').replaceFirst('</application>', '    $recv\n    </application>');
  f.writeAsStringSync(s);
}

void patchGradle() {
  for (final n in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final f = File(n);
    if (!f.existsSync()) continue;
    var s = f.readAsStringSync();
    if (s.contains('coreLibraryDesugaring')) return;
    final kts = n.endsWith('.kts');
    s = s.replaceFirst('compileOptions {', kts ? 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true' : 'compileOptions {\n        coreLibraryDesugaringEnabled true');
    s += kts ? '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n' : "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n";
    f.writeAsStringSync(s);
    return;
  }
}

void patchLabel() {
  final m = File('android/app/src/main/AndroidManifest.xml');
  if (m.existsSync()) {
    m.writeAsStringSync(m.readAsStringSync().replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Khabo Na"'));
  }
  final p = File('ios/Runner/Info.plist');
  if (p.existsSync()) {
    p.writeAsStringSync(p.readAsStringSync().replaceAllMapped(
      RegExp(r'(<key>CFBundle(?:DisplayName|Name)</key>\s*<string>)[^<]*'), (x) => '${x[1]}Khabo Na'));
  }
}

void patchPlist() {
  final f = File('ios/Runner/Info.plist');
  if (!f.existsSync()) return;
  var s = f.readAsStringSync();
  if (s.contains('NSCameraUsageDescription')) return;
  f.writeAsStringSync(s.replaceFirst('<dict>', '<dict>\n\t<key>NSCameraUsageDescription</key>\n\t<string>Take photos of your meals.</string>'));
}

Future<void> main(List<String> a) async {
  if (a.isEmpty) { stdout.writeln('Usage:\n  dart run tool/app.dart setup\n  dart run tool/app.dart build apk|bundle <API_BASE_URL> <APP_TOKEN>'); return; }
  if (a[0] == 'setup') {
    if (!Directory('android').existsSync()) await run('flutter', ['create', '--platforms=android,ios', '--project-name', 'khabo_na', '--org', 'com.khabona', '.']);
    final t = File('test/widget_test.dart');
    if (t.existsSync()) t.deleteSync();
    patchManifest(); patchGradle(); patchPlist(); patchLabel();
    await run('flutter', ['pub', 'get']);
    await run('dart', ['run', 'flutter_launcher_icons']);
    stdout.writeln('Setup done. Run: flutter run');
  } else if (a[0] == 'build' && a.length >= 4) {
    await run('flutter', ['build', a[1] == 'bundle' ? 'appbundle' : 'apk', '--release', if (a[1] != 'bundle') '--split-per-abi',
      '--obfuscate', '--split-debug-info=build/symbols', '--dart-define=API_BASE=${a[2]}', '--dart-define=APP_TOKEN=${a[3]}']);
    stdout.writeln('Done. Output is in build/app/outputs/. Keep build/symbols for crash reports.');
  } else { stderr.writeln('Wrong arguments. Run without arguments for help.'); }
}