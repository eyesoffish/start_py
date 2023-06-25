import 'dart:convert';
import 'dart:io';

import 'package:demo_project/const.dart';
import 'package:demo_project/init_py.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/process_run.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String res = "";
  String err = "";
  List<String> list = [];
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      InitPy.initPy((sender) {
        setState(() {
          list.add(sender);
        });
      });
    });
  }

  void _incrementCounter() async {
    setState(() {
      _counter++;
    });
    final file = InitPy.execMap[ExecEnum.task];

    try {
      // InitPy.initPy();
      // var shell = ProcessCmd("/bin/bash", [..."-c python3 $file test"]);
      // final _temp = await Process.run("which", ["python"], runInShell: true);
      // final _temp = await p.run(file!, ["test"]);
      // final _temp = await shell.run("/Users/zoulin/miniconda3/bin/ptyhon $file test");
      // final _temp = await shell.run("sh $file");
      // final process = await Process.start(
      //   '/bin/bash',
      //   ['-c', 'python3 $file test'],
      //   runInShell: false,
      // );
      // final temp = await runCmd(shell);
      // final temp = await runExecutableArguments(
      //   "/bin/bash",
      //   ["-c", "python3 ${InitPy.execMap[ExecEnum.task]} '${Const.task}' test"],
      // );
      final shell = Shell(runInShell: true);
      // String code = base64Encode(utf8.encode(Const.task));
      final _run = "python3 -c '''${Const.task}''' test 123";
      print(_run);
      final temp = await shell.run(_run);
      Clipboard.setData(const ClipboardData(text: "python3 -c ${Const.task} test 123"));
      setState(() {
        res = "${temp.outText}";
        err = "${temp.errText}";
      });
    } catch (e) {
      setState(() {
        _counter = -100;
        err = "$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SelectableText(
              'err: $err',
            ),
            Text("res: $res"),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
