//
//  plugin.swift
//  Runner
//
//  Created by 邹琳 on 2023/6/5.
//

import Foundation
import FlutterMacOS

public class MyPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.test", binaryMessenger: registrar.messenger)
    let instance = MyPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if(call.method == "test") {
      if let arr = call.arguments as? [Any] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/Users/zoulin/miniconda3/bin/python") // 指定Python解释器路径
        task.arguments = ["\(arr[0])", "\(arr[1])"] // 指定Python脚本路径

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print(output)
//                result(output)
            }
        } catch {
            print("Error executing Python script: \(error)")
        }
      }
    }
  }
}
