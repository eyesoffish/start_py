import 'dart:io';

import 'package:demo_project/const.dart';

import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

enum ExecEnum {
  open,
  task,
  sh,
}

class InitPy {
  static final Map<ExecEnum, String> execMap = {};
  static void initPy() async {
    final shell = Shell(runInShell: true);
    final path = await getLibraryDirectory();
    final d = Directory("${path.path}/arc");
    if (!d.existsSync()) await shell.run("mkdir ${path.path}/arc");

    _pipInstall(d.path);
    _wOpen(d.path);
    _wTask(d.path);
    _wShell(d.path);
  }

  static void _pipInstall(String path) async {
    final shell = Shell(runInShell: true);
    final f = File("$path/requirements.txt");
    await shell.run("touch $path/requirements.txt");
    f.writeAsStringSync(Const.requiredText, flush: true);
    shell.run("pip install -r ${f.path}");
  }

  static void _wOpen(String path) async {
    final file = "$path/open.py";
    final shell = Shell(runInShell: true);
    await shell.run("touch $file");
    // -- write py file
    final f = File(file);
    execMap[ExecEnum.open] = file;
    f.writeAsStringSync(Const.open, flush: true);
  }

  static void _wShell(String path) async {
    final file = "$path/shell.sh";
    final shell = Shell(runInShell: true);
    await shell.run("touch $file");
    // -- write py file
    final f = File(file);
    execMap[ExecEnum.sh] = file;
    f.writeAsStringSync(Const.shell, flush: true);
  }

  static void _wTask(String path) async {
    final file = "$path/task.py";
    final shell = Shell(runInShell: true);
    await shell.run("touch $file");
    // -- write py file
    final f = File(file);
    execMap[ExecEnum.task] = file;
    f.writeAsStringSync(Const.task, flush: true);
  }
}
