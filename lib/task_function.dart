import 'package:web3dart/web3dart.dart';
import 'dart:async';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'dart:math';

dynamic dealAmount(String amount) {
  int ratioStatus = 0;
  dynamic amt;

  if (amount.contains('%')) {
    ratioStatus = 1;
    amt = double.parse(amount.split('%')[0]) / 100;
  } else if (amount.contains('-')) {
    dynamic low = double.parse(amount.split('-')[0]);
    dynamic up = double.parse(amount.split('-')[1]);
    amt = (low + Random().nextDouble() * (up - low)).toStringAsFixed(5);
  } else {
    amt = double.parse(amount);
  }

  return [ratioStatus, amt];
}

String normalABI() {
  return '[{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
}

Future<dynamic> getABI(String RPCname, String contractAddress) async {
  String urlScan = '';
  if (RPCname == 'ETH') {
    urlScan = 'https://api.etherscan.io/api?module=contract&action=getabi&address=$contractAddress';
  } else if (RPCname == 'ARB') {
    urlScan = 'https://api.arbiscan.io/api?module=contract&action=getabi&address=$contractAddress';
  } else if (RPCname == 'OP') {
    urlScan = 'https://api-optimistic.etherscan.io/api?module=contract&action=getabi&address=$contractAddress';
  } else if (RPCname == 'BSC') {
    urlScan = 'https://api.bscscan.com/api?module=contract&action=getabi&address=$contractAddress';
  } else if (RPCname == 'POLYGON') {
    urlScan = 'https://api.polygonscan.com/api?module=contract&action=getabi&address=$contractAddress';
  }

  var response = await http.get(Uri.parse(urlScan));
  var responseBody = jsonDecode(response.body);
  var abi = jsonDecode(responseBody['result']);
  return abi;
}

Future<void> callContract(
    int serial,
    Web3Client client,
    EthereumAddress contractAddress,
    dynamic contractAbi,
    String functionName,
    EthereumAddress fromAddr,
    Credentials credentials,
    int gas,
    EtherAmount value,
    List<dynamic> args,
    {int gaslimit = 0}) async {
  final contract = DeployedContract(contractAbi, contractAddress);
  final function = contract.function(functionName);
  final nonce = await client.getTransactionCount(fromAddr);
  final gasMax = EtherAmount.fromInt(EtherUnit.gwei, gas);
  final gasPrice = await client.getGasPrice();

  int count = 0;

  while (count < 180) {
    if (gasPrice.getInWei >= gasMax.getInWei || gasPrice.getInWei == gasMax.getInWei) {
      final transaction = Transaction.callContract(
        contract: contract,
        function: function,
        parameters: args,
        from: fromAddr,
        gasPrice: gasMax,
        value: value,
        nonce: nonce,
        maxGas: gaslimit > 0 ? gaslimit : null,
      );
      final transactionHash = await client.sendTransaction(credentials, transaction);
      print('$serial 号 txHash: $transactionHash');

      TransactionReceipt? txnReceipt;
      while (txnReceipt == null) {
        try {
          txnReceipt = await client.getTransactionReceipt(transactionHash);
        } catch (e) {
          // Handle error
        }
        if (txnReceipt != null) {
          print('$serial 号完成 tx');
          break;
        } else {
          print('$serial 号 gas 过低，等待写入区块中...');
          count++;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      if (count == 180) {
        print('执行结果：$serial 号 gas 过低，180s 未被写入进区块，tx hash：$transactionHash。');
      }
    } else {
      print('当前 gas 高于设定 gas，请等待');
      await Future.delayed(Duration(seconds: 5));
    }
  }
}

void stargateBridge(int serial, String RPC, String source, String des, String fromAddr, String privKey, String amount,
    String gas, String tokenName) async {
  final w3 = Web3Client(RPC, http.Client());

  final List<dynamic> dealAmountResult = dealAmount(amount);
  final int ratioStatus = dealAmountResult[0];
  final dynamic amt = dealAmountResult[1];

  String stargateContract = '';
  int poolID;
  int chainID;
  int topoolID;
  int tochainID;
  if (tokenName.toLowerCase() == 'eth') {
    if (source == 'ETH') {
      stargateContract = '0x150f94B44927F078737562f0fcF3C95c01Cc2376';
      poolID = 13;
      chainID = 101;
    } else if (source == 'ARB') {
      stargateContract = '0xbf22f0f184bCcbeA268dF387a49fF5238dD23E40';
      poolID = 13;
      chainID = 110;
    } else if (source == 'OP') {
      stargateContract = '0xB49c4e680174E331CB0A7fF3Ab58afC9738d5F8b';
      poolID = 13;
      chainID = 111;
    }

    if (des == 'ETH') {
      topoolID = 13;
      tochainID = 101;
    } else if (des == 'ARB') {
      topoolID = 13;
      tochainID = 110;
    } else if (des == 'OP') {
      topoolID = 13;
      tochainID = 111;
    }

    BigInt balanceA = await getGasBalance(w3, fromAddr);
    int gaslimit = 1000000;

    BigInt tosendvalue;
    if (ratioStatus == 1) {
      tosendvalue =
          (balanceA - BigInt.parse(gas.toString()) * BigInt.from(gaslimit) / BigInt.from(1e9) - BigInt.from(1)) * amt;
    } else {
      tosendvalue = BigInt.parse(amt);
    }

    EtherAmount value = EtherAmount.fromBigInt(EtherUnit.ether, tosendvalue);
    final _fromAddr = EthereumAddress.fromHex(fromAddr);
    String stargetABI = await getABI(source, stargateContract);
    callContract(serial, w3, EthereumAddress.fromHex(stargateContract), stargetABI, 'swapETH', _fromAddr, privKey, gas,
        value, tochainID, fromAddr, fromAddr, value, (value.getInEther * BigInt.from(0.975)).toInt());
  }
}
