import 'dart:io';

import 'package:demo_project/const.dart';
import 'package:oktoast/oktoast.dart';

import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

enum ExecEnum {
  open,
  task,
}

class InitPy {
  static final Map<ExecEnum, String> execMap = {};
  static void initPy(Function(String) callback) async {
    final shell = Shell(runInShell: true);
    final path = await getApplicationDocumentsDirectory();
    final temp = await run(
      "unzip -o ${path.path}/dist.zip -d ${path.path}",
      runInShell: true,
    );
    execMap[ExecEnum.task] = "${path.path}/dist/exec.py";
    execMap[ExecEnum.open] = "${path.path}/dist/exec.py";
  }
}
