import 'dart:io';

import 'package:demo_project/const.dart';
import 'package:oktoast/oktoast.dart';

import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

enum ExecEnum {
  open,
  task,
  sh,
}

class InitPy {
  static final Map<ExecEnum, String> execMap = {};
  static void initPy(Function(String) callback) async {
    final shell = Shell(runInShell: true);
    final path = await getLibraryDirectory();
    final d = Directory("${path.path}/arc");
    if (!d.existsSync()) await shell.run("mkdir ${path.path}/arc");

    _pipInstall(d.path).then((value) async {
      callback("命令: 创建文件");
      await _wOpen(d.path);
      await _wTask(d.path);
      try {
        final res = await shell.run("pyarmor obfuscate ${execMap[ExecEnum.task]} --output ${d.path}/dist");
        callback("脚本执行err: ${res.errText}脚本执行正常: ${res.outText}");
        RegExp commandRegex = RegExp(r"with `([^`]+)`");
        Match? match = commandRegex.firstMatch(res.outText);

        if (match != null) {
          String command = match.group(1)!;
          callback("命令: $command");
          final res = await shell.run("$command obfuscate ${execMap[ExecEnum.task]} --output ${d.path}/dist");
        }
      } catch (e) {
        callback("脚本err: $e");
      }
      shell.run("rm -f ${execMap[ExecEnum.task]}");
      shell.run("rm -f ${execMap[ExecEnum.open]}");
      execMap[ExecEnum.task] = "${d.path}/dist/task.py";
      execMap[ExecEnum.open] = "${d.path}/dist/open.py";
    });
  }

  static Future<void> _pipInstall(String path) async {
    final shell = Shell(runInShell: true);
    final f = File("$path/requirements.txt");
    await shell.run("touch $path/requirements.txt");
    f.writeAsStringSync(Const.requiredText, flush: true);
    try {
      await shell.run("pip install -r ${f.path}");
    } catch (e) {
      showToast("$e");
    }
  }

  static Future<void> _wOpen(String path) async {
    final file = "$path/open.py";
    final shell = Shell(runInShell: true);
    await shell.run("touch $file");
    // -- write py file
    final f = File(file);
    execMap[ExecEnum.open] = file;
    f.writeAsStringSync(Const.open, flush: true);
  }

  static Future<void> _wTask(String path) async {
    final file = "$path/task.py";
    final shell = Shell(runInShell: true);
    await shell.run("touch $file");
    // -- write py file
    final f = File(file);
    execMap[ExecEnum.task] = file;
    f.writeAsStringSync(Const.task, flush: true);
  }
}
