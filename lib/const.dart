class Const {
  static const String requiredText = '''
requests
web3
python-binance
 ''';
  static const String open = '''
import requests
import sys
def adspower(ads_serial_number, cache):
    global open_url, driver, close_url
    i=0
    while i<5:
        try:
            if int(cache) == 0:
                open_url = "http://local.adspower.com:50325/api/v1/browser/start?serial_number=" + ads_serial_number + "&open_tabs=1&clear_cache_after_closing=1&launch_args=[\\"--disable-popup-blocking\\"]"
            elif int(cache) == 1:
                open_url = "http://local.adspower.com:50325/api/v1/browser/start?serial_number=" + ads_serial_number + "&open_tabs=1&launch_args=[\\"--disable-popup-blocking\\"]"
            close_url = "http://local.adspower.com:50325/api/v1/browser/stop?serial_number=" + ads_serial_number
            resp = requests.get(open_url).json()
            print(resp)
            if resp["code"] != 0:
                print(resp["报错：msg"])
                print("报错：please check ads_serial_number")
                driver = 'err'
                close_url = 'err'
                i+=1
            else:
                chrome_driver = resp["data"]["webdriver"]
                chrome_options = Options()
                chrome_options.add_experimental_option("debuggerAddress", resp["data"]["ws"]["selenium"])
                driver = webdriver.Chrome(chrome_driver, options=chrome_options)
                break
        except:
            print('打开{}号浏览器失败，正在重试'.format(ads_serial_number))
            driver = 'err'
            close_url = 'err'
            i+=1
    if i>4:
        print('报错：打开{}号浏览器失败'.format(ads_serial_number))

    return driver, close_url

if __name__ == '__main__':
    adsNum = sys.argv[1]
    cache = sys.argv[2]
    adspower(adsNum,1)
 ''';
  static const String task = '''
import base64
import datetime
import hmac
import json
import random
import time
import sys
from hashlib import sha256
from binance.client import Client
from binance.exceptions import BinanceAPIException
import requests
from web3 import Web3,constants

# 基础函数
def getABI(RPCname,contract_address):
    url_scan = ''
    if RPCname == 'ETH':
        url_scan = f"https://api.etherscan.io/api?module=contract&action=getabi&address=" + str(
            contract_address)
    elif RPCname == 'ARB':
        url_scan = f"https://api.arbiscan.io/api?module=contract&action=getabi&address=" + str(
            contract_address)
    elif RPCname == 'OP':
        url_scan = f"https://api-optimistic.etherscan.io/api?module=contract&action=getabi&address=" + str(
            contract_address)
    elif RPCname == 'BSC':
        url_scan = f"https://api.bscscan.com/api?module=contract&action=getabi&address=" + str(
            contract_address)
    elif RPCname == 'POLYGON':
        url_scan = f"https://api.polygonscan.com/api?module=contract&action=getabi&address=" + str(
            contract_address)
    r = requests.get(url=url_scan)
    response = r.json()
    abi = json.loads(response["result"])
    return abi


def callcontract(serial,w3, conadd, conabi, funcname,add,Pkey, gas,value,*args,gaslimit=0):
    _contract = w3.eth.contract(address=conadd, abi=conabi)
    status_code = 0
    gas_max = w3.to_wei(gas, 'gwei')
    gas = w3.eth.gas_price
    while status_code == 0:
        if float(gas) < float(gas_max) or float(gas) == float(gas_max):
            if gaslimit==0:
                rawTx = _contract.functions[funcname](
                    *args
                ).build_transaction({
                    'nonce': w3.eth.get_transaction_count(add),
                    'from': add,
                    'value': value,
                    'gasPrice': gas_max
                })
            else:
                rawTx = _contract.functions[funcname](
                    *args
                ).build_transaction({
                    'nonce': w3.eth.get_transaction_count(add),
                    'from': add,
                    'value': value,
                    'gasPrice': gas_max,
                    'gasLimit': gaslimit
                })
            signTx = w3.eth.account.sign_transaction(rawTx, Pkey)
            txHash = w3.eth.send_raw_transaction(signTx.rawTransaction).hex()
            print(f'{serial}号txHash:', txHash)
            txn_receipt = None
            count = 0
            while txn_receipt is None and (count < 180):
                try:
                    txn_receipt = w3.eth.get_transaction_receipt(txHash)
                except:
                    pass
                if not txn_receipt is None:
                    print(f'执行结果：{serial}号完成tx')
                    status_code = 1
                else:
                    print(f'执行结果：{serial}号gas过低,等待写入区块中。。。')
                    count += 1
                    time.sleep(1)
            if count == 180:
                print(f'执行结果：{serial}号gas过低，180s未被写入进区块，tx hash：{txHash}。')
                status_code = 1
        else:
            print('当前gas高于设定gas，请等待')
            time.sleep(5)



def transfercontract(serial,w3, conadd,add,Pkey, gas,value,input_data,gaslimit=5000000):
    status_code = 0
    gas_max = w3.to_wei(gas, 'gwei')
    gas = w3.eth.gas_price
    while status_code == 0:
        if float(gas) < float(gas_max) or float(gas) == float(gas_max):
            rawTx = {
                'nonce': w3.eth.get_transaction_count(add),
                'from': add,
                'to': conadd,
                'value': value,
                'gas': gaslimit,
                'gasPrice': gas_max,
                'data': input_data
            }
            signTx = w3.eth.account.sign_transaction(rawTx, Pkey)
            txHash = w3.eth.send_raw_transaction(signTx.rawTransaction).hex()
            print(f'{serial}号txHash:', txHash)
            txn_receipt = None
            count = 0
            while txn_receipt is None and (count < 180):
                try:
                    txn_receipt = w3.eth.get_transaction_receipt(txHash)
                except:
                    pass
                if not txn_receipt is None:
                    print(f'执行结果：{serial}号完成tx')
                    status_code = 1
                else:
                    print(f'执行结果：{serial}号gas过低,等待写入区块中。。。')
                    count += 1
                    time.sleep(1)
            if count == 180:
                print(f'执行结果：{serial}号gas过低，180s未被写入进区块，tx hash：{txHash}。')
                status_code = 1
        else:
            print('当前gas高于设定gas，请等待')
            time.sleep(5)

def dealAmount(amount):
    ratio_status=0
    if '%' in amount:
        ratio_status=1
        amt=float(amount.split('%')[0])/100
    elif '-' in amount:
        low=amount.split('-')[0]
        up = amount.split('-')[1]
        amt=round(random.uniform(low,up),5)
    else:
        amt=amount
    return ratio_status, amt


def normalABI():
    ABI = '[{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]'
    return ABI

# ARC中会用到的功能函数

#查询代币余额
# PRC；代币地址；钱包地址
def checkTokenbalance(RPC,contract_address,fromAddr):
    w3 = Web3(Web3.HTTPProvider(RPC))
    abi=normalABI()
    Contract = w3.eth.contract(address=contract_address, abi=abi)
    balance = Contract.functions.balanceOf(fromAddr).call()
    dec=Contract.functions.decimals().call()
    real_bal=balance/10**dec
    return balance,dec,real_bal

# 查询gas币余额
# RPC；钱包地址
def getGasBalance(RPC,fromAddr):
    w3 = Web3(Web3.HTTPProvider(RPC))
    balance = w3.from_wei(w3.eth.get_balance(fromAddr), 'ether')
    return balance


# 发送gas币
# 序号；RPC；发出钱包地址；接收钱包地址；发出钱包私钥；数量（可以是数值也可以是百分比），设定gas
def sendGastoken(serial,RPC,fromAddr,toAddr,privKey,amount,gas):
    w3 = Web3(Web3.HTTPProvider(RPC))
    balanceA = getGasBalance(w3, fromAddr)
    gaslimit=600000
    ratio_status, amt=dealAmount(amount)
    if ratio_status==1:
        tosendvalue = (float(balanceA) - float(gas) * gaslimit / 1e9 - 0.0001)*amt
    else:
        tosendvalue = amt
    value = w3.to_wei(str(tosendvalue), 'ether')
    gas_max = w3.to_wei(gas, 'gwei')
    while True:
        gas = w3.eth.gas_price
        if float(gas) < float(gas_max) or float(gas) == float(gas_max):
            toAddr = w3.to_checksum_address(toAddr)
            tx = {
                'nonce': w3.eth.get_transaction_count(fromAddr),
                'to': toAddr,
                'value': value,
                'gas': gaslimit,
                'gasPrice': gas
            }
            break
        else:
            print('当前gas高于设定gas，请等待')
            time.sleep(1)
    signTx = w3.eth.account.sign_transaction(tx, privKey)
    txHash = w3.eth.send_raw_transaction(signTx.rawTransaction).hex()
    txn_receipt = None
    count = 0
    while txn_receipt is None and (count < 60):
        try:
            txn_receipt = w3.eth.get_transaction_receipt(txHash)
        except:
            pass
        if not txn_receipt is None:
            print(f'执行结果：{serial}号浏览器完成转账，转账金额：{tosendvalue}')
        else:
            count += 1
            time.sleep(5)
    if count == 60:
        print(f'执行结果：{serial}号浏览器gas过低，检测5分钟未被写入进区块，转账hash：{txHash}，请自行查询。')


# 发送代币
# 序号；RPC；代币合约地址；发出钱包地址；接收钱包地址；发出钱包私钥；数量（可以是数值也可以是百分比），设定gas
def sendToken(serial,RPC,contract_address,fromAddr,toAddr,privKey,amount,gas):
    w3 = Web3(Web3.HTTPProvider(RPC))
    coinconabi = normalABI()
    CoinContract = w3.eth.contract(address=contract_address, abi=coinconabi)
    Coinbalance = CoinContract.functions.balanceOf(fromAddr).call()
    dec = CoinContract.functions.decimals().call()
    ratio_status, amt = dealAmount(amount)
    if ratio_status == 1:
        tosendvalue = round(Coinbalance * amt)
    else:
        tosendvalue = amt*10**dec
    callcontract(serial, w3, contract_address, coinconabi, 'transfer', fromAddr, privKey, gas, 0, toAddr, tosendvalue)


# OKX提币
# OKXAPI；OKXAPI密码；OKXAPI密钥；代币名称；数量；接收钱包地址；链名称
def okxApiwithdraw(APIkey, passphrase, secreatkey, token_name, amount, toAddr, chain_name):
    trans_code = 0
    session = requests.session()
    method = 'GET'
    path = f'/api/v5/asset/currencies?ccy={token_name}'
    timestamp = str(datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + 'Z')
    secreatKey = secreatkey.encode('utf-8')
    enc_data = f'{timestamp}{method}{path}'.encode('utf-8')
    sign = base64.b64encode(hmac.new(secreatKey, enc_data, digestmod=sha256).digest()).decode()
    session.headers = {'Accept': 'application/json',
                       'Content-Type': 'application/json',
                       'OK-ACCESS-KEY': APIkey,
                       'OK-ACCESS-SIGN': sign,
                       'OK-ACCESS-TIMESTAMP': timestamp,
                       'OK-ACCESS-PASSPHRASE': passphrase,
                       }
    info = session.get(f"https://www.okx.com{path}").json()
    chainNum = len(info['data'])
    fee = ''
    chain = ''
    for i in range(int(chainNum)):
        chain = info['data'][i]['chain']
        if chain_name.lower() in chain.lower():
            fee = info['data'][i]['minFee']
            break
    method = 'POST'
    path = '/api/v5/asset/withdrawal'
    ratio_status,amt=dealAmount(amount)
    if ratio_status==0:
        body = {"amt": str(amt), "fee": fee, "dest": "4", "ccy": token_name, "chain": chain, "toAddr": toAddr}
        bodystr = json.dumps(body)
        timestamp = str(datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + 'Z')
        secreatKey = secreatkey.encode('utf-8')
        enc_data = f'{timestamp}{method}{path}{str(bodystr)}'.encode('utf-8')
        sign = base64.b64encode(hmac.new(secreatKey, enc_data, digestmod=sha256).digest()).decode()
        session.headers = {'Accept': 'application/json',
                           'Content-Type': 'application/json',
                           'OK-ACCESS-KEY': APIkey,
                           'OK-ACCESS-SIGN': sign,
                           'OK-ACCESS-TIMESTAMP': timestamp,
                           'OK-ACCESS-PASSPHRASE': passphrase,
                           }
        res = session.post(f"https://www.okx.com{path}", data=json.dumps(body)).json()
        print(res)
        if res['code'] == '0':
            trans_code = 1
        else:
            trans_code = 0
    return trans_code


# BN提币
# 序号；BNAPI；BNAPI密钥；代币名称；接收钱包地址；数量；链名称
def bnApiwithdraw(serial,api_key,api_secret,coin,toAddr,amount,chain_name):
    status=0
    ratio_status, amt = dealAmount(amount)
    if ratio_status == 0:
        client = Client(api_key, api_secret)
        try:
            result = client.withdraw(
                coin=coin,
                address=toAddr,
                amount=amt,
                network=chain_name)
        except BinanceAPIException as e:
            print(e)
            status=0
        else:
            print(f"{serial}号浏览器BN提币Success,{result}")
            status=1
    return status


# EVM链合约交互
# 序号；RPC；RPC名称；合约地址；钱包地址；钱包私钥；合约函数；设定gas；ETHvalue；data
def evmContractinteract(serial,RPC,RPCname,contract_address,fromAddr,privKey,funcname,gas, value, *args):
    w3 = Web3(Web3.HTTPProvider(RPC))
    Addr = w3.to_checksum_address(fromAddr)
    conabi = getABI(RPCname, contract_address)
    callcontract(serial, w3, contract_address, conabi, funcname, Addr, privKey, gas, value, *args)


# zk ETH，WETH互相兑换
# 序号；RPC；数量；x=1是eth兑换weth，2是weth兑换eth;钱包地址；钱包私钥；设定gas
def syncswap(serial,RPC, amount, x,fromAddr,privKey,gas):
    w3 = Web3(Web3.HTTPProvider(RPC))
    ratio_status, amt = dealAmount(amount)
    # x=1是eth兑换weth，2是weth兑换eth
    if x == 1:
        # ETH swap WETH
        balanceA = getGasBalance(w3, fromAddr)
        gaslimit = 2168979
        if ratio_status == 1:
            tosendvalue = (float(balanceA) - float(gas) * gaslimit / 1e9 - 0.0001) * amt
        else:
            tosendvalue = amt
        inputdata = '0xd0e30db0'
        value = w3.to_wei(tosendvalue, 'ether')
    else:
        # WETH swap ETH
        coinconabi = normalABI()
        CoinContract = w3.eth.contract(address=Web3.to_checksum_address('0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91'), abi=coinconabi)
        Coinbalance = CoinContract.functions.balanceOf(fromAddr).call()
        amount = Web3.to_hex(Coinbalance)[2:].rjust(64, '0')
        inputdata = '0x2e1a7d4d' + str(amount)
        value = 0

    # ETH swap WETH
    target_address = Web3.to_checksum_address('0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91')  # sync,weth合约地址
    transfercontract(serial,w3, target_address,fromAddr,privKey, gas,value,inputdata,gaslimit=2168979)


# L0跨链
# 序号；RPC；发出链名称；接收链名称；钱包地址；钱包私钥；数量；设定gas；代币名称（ETH或者USDC）
def stargateBridge(serial,RPC,source,des,fromAddr,privKey,amount,gas,token_name):
    w3 = Web3(Web3.HTTPProvider(RPC))
    ratio_status, amt = dealAmount(amount)
    stargate_contract=''
    if token_name.lower() == 'eth':
        if source == 'ETH':
            stargate_contract = '0x150f94B44927F078737562f0fcF3C95c01Cc2376'
            poolID = 13
            chainID = 101
        elif source == 'ARB':
            stargate_contract = '0xbf22f0f184bCcbeA268dF387a49fF5238dD23E40'
            poolID = 13
            chainID = 110
        elif source == 'OP':
            stargate_contract = '0xB49c4e680174E331CB0A7fF3Ab58afC9738d5F8b'
            poolID = 13
            chainID = 111
        if des == 'ETH':
            topoolID = 13
            tochainID = 101
        elif des == 'ARB':
            topoolID = 13
            tochainID = 110
        elif des == 'OP':
            topoolID = 13
            tochainID = 111
        balanceA = getGasBalance(w3, fromAddr)
        gaslimit = 1000000
        if ratio_status == 1:
            tosendvalue = (float(balanceA) - float(gas) * gaslimit / 1e9 - 0.0001) * amt
        else:
            tosendvalue = amt
        value = w3.to_wei(str(tosendvalue), 'ether')
        stargate_contract = Web3.to_checksum_address(stargate_contract)
        starget_abi = getABI(source, stargate_contract)
        callcontract(serial, w3, stargate_contract, starget_abi, 'swapETH', fromAddr, privKey, gas, value, tochainID,
                      fromAddr,fromAddr, value, int(value * 0.975))
    elif token_name.lower() == 'usdc':
        if source == 'ETH':
            token_contract='0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
            stargate_contract = '0x8731d54E9D02c286767d56ac03e8037C07e01e98'
            poolID = 1
            chainID = 101
        elif source == 'ARB':
            token_contract = '0xff970a61a04b1ca14834a43f5de4533ebddb5cc8'
            stargate_contract = '0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614'
            poolID = 1
            chainID = 110
        elif source == 'OP':
            token_contract = '0x7f5c764cbc14f9669b88837ca1490cca17c31607'
            stargate_contract = '0xB0D502E938ed5f4df2E681fE6E419ff29631d62b'
            poolID = 1
            chainID = 111
        elif source == 'Avalanche':
            token_contract = '0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E'
            stargate_contract = '0x45A01E4e04F14f7A4a6702c74187c5F6222033cd'
            poolID = 1
            chainID = 106
        elif source == 'Polygon':
            token_contract = '0x2791bca1f2de4661ed88a30c99a7a9449aa84174'
            stargate_contract = '0x45A01E4e04F14f7A4a6702c74187c5F6222033cd'
            poolID = 1
            chainID = 109
        elif source == 'Fantom':
            token_contract = '0x04068da6c83afcfa0e13ba15a6696662335d5b75'
            stargate_contract = '0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6'
            poolID = 1
            chainID = 112
        if des == 'ETH':
            topoolID = 1
            tochainID = 101
        elif des == 'ARB':
            topoolID = 1
            tochainID = 110
        elif des == 'OP':
            topoolID = 1
            tochainID = 111
        elif des == 'Avalanche':
            topoolID = 1
            tochainID = 106
        elif des == 'Polygon':
            topoolID = 1
            tochainID = 109
        elif des == 'Fantom':
            topoolID = 1
            tochainID = 112
        contract_address=Web3.to_checksum_address(token_contract)
        gaslimit = 1000000
        coinconabi = normalABI()
        CoinContract = w3.eth.contract(address=contract_address, abi=coinconabi)
        Coinbalance = CoinContract.functions.balanceOf(fromAddr).call()
        dec = CoinContract.functions.decimals().call()
        ratio_status, amt = dealAmount(amount)
        if ratio_status == 1:
            tosendvalue = round(Coinbalance * amt)
        else:
            tosendvalue = amt * 10 ** dec
        value = 0
        stargate_contract=Web3.to_checksum_address(stargate_contract)
        starget_abi = getABI(source, stargate_contract)
        callcontract(serial, w3, stargate_contract, starget_abi, 'swap', fromAddr, privKey, gas, value, tochainID,poolID,topoolID,fromAddr,tosendvalue,int(tosendvalue * 0.975),
                        [0, 0, "0x0000000000000000000000000000000000000001"],fromAddr,"0x")


# layerswap跨链
# RPC；发出链名称；接收链名称；钱包地址；数量；设定gas；钱包私钥；补充接收链gas（true或false）
def layerswap(RPC,source,des,fromAddr,amount,gas,privKey,refuel):
    if source.lower()=='eth':
        source_network='ETHEREUM_MAINNET'
    elif source.lower()=='op':
        source_network='OPTIMISM_MAINNET'
    elif source.lower()=='arb':
        source_network='ARBITRUM_MAINNET'
    elif source.lower()=='polygon':
        source_network='POLYGON_MAINNET'
    elif source.lower()=='polygonzk':
        source_network='POLYGONZK_MAINNET'
    elif source.lower()=='starknet':
        source_network='STARKNET_MAINNET'
    elif source.lower()=='bsc':
        source_network='BSC_MAINNET'
    elif source.lower()=='zkera':
        source_network='ZKSYNCERA_MAINNET'
    if des.lower()=='eth':
        destination_network='ETHEREUM_MAINNET'
    elif des.lower()=='op':
        destination_network='OPTIMISM_MAINNET'
    elif source.lower()=='arb':
        destination_network='ARBITRUM_MAINNET'
    elif source.lower()=='polygon':
        destination_network='POLYGON_MAINNET'
    elif source.lower()=='polygonzk':
        destination_network='POLYGONZK_MAINNET'
    elif source.lower()=='starknet':
        destination_network='STARKNET_MAINNET'
    elif source.lower()=='bsc':
        destination_network='BSC_MAINNET'
    elif source.lower()=='zkera':
        destination_network='ZKSYNCERA_MAINNET'

    w3 = Web3(Web3.HTTPProvider(RPC))
    ratio_status, amt = dealAmount(amount)
    balanceA = getGasBalance(w3, fromAddr)
    gaslimit = 1000000
    if ratio_status == 1:
        tosendvalue = (float(balanceA) - float(gas) * gaslimit / 1e9 - 0.0001) * amt
    else:
        tosendvalue = amt
    value = w3.to_wei(str(tosendvalue), 'ether')
    if tosendvalue>0.5:
        print('超过可跨链限额！')
    else:
        # 第一步，创建token
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36',
        }
        data = {
            'client_id': 'layerswap_bridge_ui',
            'grant_type': 'credentialless'
        }
        while True:
            try:
                response = requests.post('https://identity-api.layerswap.io/connect/token', data=data, headers=headers)
                res = response.json()
                access_token = res['access_token']
                print('0-layerswap,创建token成功')
                break
            except Exception as e:
                print(e)

        # 第二步，创建swap

        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36',
            'authorization': 'Bearer ' + access_token
        }
        data = {
            "amount": tosendvalue,
            "source_exchange": None,
            "source_network": source_network,
            "destination_network": destination_network,
            "destination_exchange": None,
            "asset": "ETH",
            "destination_address": fromAddr,
            "refuel": refuel
        }
        while True:
            try:
                response = requests.post('https://bridge-api.layerswap.io//api/swaps', json=data, headers=headers)
                res = response.json()
                swap_id = res['data']['swap_id']
                # print(swap_id)
                print(f'1-layerswap,创建task成功，swapid为{swap_id}')
                break
            except Exception as e:
                print(e)

        # 第三步，获取收款地址
        while True:
            try:
                response = requests.get(f'https://bridge-api.layerswap.io//api/swaps/{swap_id}', headers=headers)
                res = response.json()
                deposit_address = res['data']['deposit_address']
                status = res['data']['status']
                # print(deposit_address,status)
                print(f'2-layerswap,获取收款地址成功，deposit_address为{deposit_address}')
                break
            except Exception as e:
                print(e)

        # 转账
        target_address = Web3.to_checksum_address(deposit_address)
        nonce = w3.eth.get_transaction_count(fromAddr)  # 获取 nonce 值
        params = {
            'from': fromAddr,
            'nonce': nonce,
            'to': target_address,
            'value': value,
            'gas': 589138,
            'maxFeePerGas': w3.eth.gas_price,
            'maxPriorityFeePerGas': w3.eth.max_priority_fee,
        }
        try:
            signed_tx = w3.eth.account.sign_transaction(params, private_key=privKey)
            txn = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
            print(f'3-layerswap,转账成功,hash:{w3.to_hex(txn)}')
        except Exception as e:
            print(e)
            print(f'3-layerswap,转账失败')

        # 循环监控状态
        print('开始监控跨链是否到账')
        for i in range(100):
            try:
                response = requests.get(f'https://bridge-api.layerswap.io//api/swaps/{swap_id}', headers=headers)
                res = response.json()
                status = res['data']['status']
                print(status)
                time.sleep(5)
                if status == 'completed':
                    print('跨链成功到账')
                    return 1
                if i == 99:
                    print('超时未到账')
                    return 2
            except:
                pass


# zk velocore swap
# 序号；RPC；钱包地址；钱包私钥；设定gas；数量；x=1ETH换USDC，x=2USDC换ETH
def velocore(serial,RPC,fromAddr,privKey,gas,amount,x):
    w3 = Web3(Web3.HTTPProvider(RPC))
    weth = Web3.to_checksum_address('0x5aea5775959fbc2557cc8789bc1bf90a239d9a91')
    usdc = Web3.to_checksum_address('0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4')
    gaslimit=2361235 + random.randint(10000, 20000)
    if x == 1:
        ratio_status, amt = dealAmount(amount)
        balanceA = getGasBalance(w3, fromAddr)
        if ratio_status == 1:
            tosendvalue = (float(balanceA) - float(w3.eth.gas_price) * gaslimit / 1e9 - 0.0001) * amt
        else:
            tosendvalue = amt
        value = w3.to_wei(str(tosendvalue), 'ether')
    elif x == 2:
        coinconabi = normalABI()
        CoinContract = w3.eth.contract(address=usdc, abi=coinconabi)
        Coinbalance = CoinContract.functions.balanceOf(fromAddr).call()
        dec = CoinContract.functions.decimals().call()
        ratio_status, amt = dealAmount(amount)
        if ratio_status == 1:
            tosendvalue = round(Coinbalance * amt)
        else:
            tosendvalue = amt * 10 ** dec
        value = 0

    if x == 1:
        # ETH换USDC
        method = '0x67ffb66a'
        data1 = '0000000000000000000000000000000000000000000000000000000000000000'
        data2 = '0000000000000000000000000000000000000000000000000000000000000080'
    elif x == 2:
        # USDC换ETH
        method = '0x18a13086'
        data1 = Web3.to_hex(tosendvalue)[2:].rjust(64, '0')  # USDC的数量
        data2 = '0000000000000000000000000000000000000000000000000000000000000000' + '00000000000000000000000000000000000000000000000000000000000000a0'  # 输出数量不好获得
    data3 = fromAddr[2:].rjust(64, '0')
    data4 = Web3.to_hex(int(time.time() * 1000) + 1800000)[2:].rjust(64, '0')
    data5 = '0000000000000000000000000000000000000000000000000000000000000001'
    if x == 1:
        data6 = weth[2:].rjust(64, '0')
        data7 = usdc[2:].rjust(64, '0')
    elif x == 2:
        data6 = usdc[2:].rjust(64, '0')
        data7 = weth[2:].rjust(64, '0')
    data8 = '0000000000000000000000000000000000000000000000000000000000000000'

    inputdata = method + data1 + data2 + data3 + data4 + data5 + data6 + data7 + data8

    # swap
    routerAddress = Web3.to_checksum_address('0xd999E16e68476bC749A28FC14a0c3b6d7073F50c')
    transfercontract(serial,w3, routerAddress,fromAddr,privKey, gas,value,inputdata,gaslimit=gaslimit)


# zk spacefi swap
# 序号；RPC；钱包地址；钱包私钥；设定gas；数量；x=1ETH换USDC，x=2USDC换ETH
def spacefi(serial,RPC,fromAddr,privKey,gas,amount,x):
    w3 = Web3(Web3.HTTPProvider(RPC))
    weth = Web3.to_checksum_address('0x5aea5775959fbc2557cc8789bc1bf90a239d9a91')
    usdc = Web3.to_checksum_address('0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4')
    gaslimit = 2361235 + random.randint(10000, 20000)
    if x == 1:
        ratio_status, amt = dealAmount(amount)
        balanceA = getGasBalance(w3, fromAddr)
        if ratio_status == 1:
            tosendvalue = (float(balanceA) - float(w3.eth.gas_price) * gaslimit / 1e9 - 0.0001) * amt
        else:
            tosendvalue = amt
        value = w3.to_wei(str(tosendvalue), 'ether')
    elif x == 2:
        coinconabi = normalABI()
        CoinContract = w3.eth.contract(address=usdc, abi=coinconabi)
        Coinbalance = CoinContract.functions.balanceOf(fromAddr).call()
        dec = CoinContract.functions.decimals().call()
        ratio_status, amt = dealAmount(amount)
        if ratio_status == 1:
            tosendvalue = round(Coinbalance * amt)
        else:
            tosendvalue = amt * 10 ** dec
        value = 0

    if x == 1:
        # ETH换USDC
        method = '0x7ff36ab5'
        data1 = '0000000000000000000000000000000000000000000000000000000000000000'
        data2 = '0000000000000000000000000000000000000000000000000000000000000080'
    elif x == 2:
        # USDC换ETH
        method = '0x18cbafe5'
        data1 = Web3.to_hex(tosendvalue)[2:].rjust(64, '0')  # USDC的数量
        data2 = '0000000000000000000000000000000000000000000000000000000000000000' + '00000000000000000000000000000000000000000000000000000000000000a0'  # 获得这个输出数量太难了。
    data3 = fromAddr[2:].rjust(64, '0')
    data4 = Web3.to_hex(int(time.time()) + 1800)[2:].rjust(64, '0')
    data5 = '0000000000000000000000000000000000000000000000000000000000000002'
    if x == 1:
        data6 = weth[2:].rjust(64, '0')
        data7 = usdc[2:].rjust(64, '0')
    elif x == 2:
        data6 = usdc[2:].rjust(64, '0')
        data7 = weth[2:].rjust(64, '0')

    inputdata = method + data1 + data2 + data3 + data4 + data5 + data6 + data7

    # swap
    routerAddress = Web3.to_checksum_address('0xbE7D1FD1f6748bbDefC4fbaCafBb11C6Fc506d1d')
    transfercontract(serial,w3, routerAddress,fromAddr,privKey, gas,value,inputdata,gaslimit=gaslimit)


# zk izumi swap
# RPC；钱包地址；钱包私钥；数量；x=1ETH换USDC，x=2USDC换ETH
def izumi(RPC,fromAddr,privKey,amount,x):
    w3 = Web3(Web3.HTTPProvider(RPC))
    weth = Web3.to_checksum_address('0x5aea5775959fbc2557cc8789bc1bf90a239d9a91')
    usdc = Web3.to_checksum_address('0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4')
    if x == 1:
        ratio_status, amt = dealAmount(amount)
        balanceA = getGasBalance(w3, fromAddr)
        gaslimit = 1000000
        if ratio_status == 1:
            tosendvalue = (float(balanceA) - float(w3.eth.gas_price) * gaslimit / 1e9 - 0.0001) * amt
        else:
            tosendvalue = amt
        value = w3.to_wei(str(tosendvalue), 'ether')
    elif x == 2:
        gaslimit = 1000000
        coinconabi = normalABI()
        CoinContract = w3.eth.contract(address=usdc, abi=coinconabi)
        Coinbalance = CoinContract.functions.balanceOf(fromAddr).call()
        dec = CoinContract.functions.decimals().call()
        ratio_status, amt = dealAmount(amount)
        if ratio_status == 1:
            tosendvalue = round(Coinbalance * amt)
        else:
            tosendvalue = amt * 10 ** dec
        value = 0

    if x == 1:
        method = '0x75ceafe6'
        data1 = '0000000000000000000000000000000000000000000000000000000000000020' + '00000000000000000000000000000000000000000000000000000000000000a0'
        data2 = fromAddr[2:].rjust(64, '0')
        data3 = Web3.to_hex(value)[2:].rjust(64, '0')  # ETH数量
        data4 = '0000000000000000000000000000000000000000000000000000000000000000'  # 获得这个输出数量太难了。
        data5 = Web3.to_hex(int(time.time()) + 1800)[2:].rjust(64, '0')
        data6 = '000000000000000000000000000000000000000000000000000000000000002b' + '5aea5775959fbc2557cc8789bc1bf90a239d9a910007d03355df6d4c9c303572' + '4fd0e3914de96a5a83aaf4000000000000000000000000000000000000000000'
        data = method + data1 + data2 + data3 + data4 + data5 + data6
    elif x == 2:
        method = '0x75ceafe6'
        data1 = '0000000000000000000000000000000000000000000000000000000000000020' + '00000000000000000000000000000000000000000000000000000000000000a0' + '0000000000000000000000000000000000000000000000000000000000000000'
        data2 = Web3.to_hex(tosendvalue)[2:].rjust(64, '0')  # USDC数量
        data3 = '0000000000000000000000000000000000000000000000000000000000000000'  # 获得这个输出数量太难了。
        data4 = Web3.to_hex(int(time.time()) + 1800)[2:].rjust(64, '0')
        data5 = '000000000000000000000000000000000000000000000000000000000000002b' + '3355df6d4c9c3035724fd0e3914de96a5a83aaf40007d05aea5775959fbc2557' + 'cc8789bc1bf90a239d9a91000000000000000000000000000000000000000000'
        data = method + data1 + data2 + data3 + data4 + data5

    router_address = Web3.to_checksum_address('0x9606eC131EeC0F84c95D82c9a63959F2331cF2aC')
    router_abi = '[{"inputs":[{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"multicall","outputs":[{"internalType":"bytes[]","name":"results","type":"bytes[]"}],"stateMutability":"payable","type":"function"}]'
    router = w3.eth.contract(router_address, abi=router_abi)
    if x == 1:
        func = router.functions.multicall(
            [Web3.to_bytes(hexstr=data), Web3.to_bytes(hexstr='0x12210e8a')]
        )
    elif x == 2:
        data_in = '0x49404b7c0000000000000000000000000000000000000000000000000000000000000000' + fromAddr[2:].rjust(
            64, '0')
        func = router.functions.multicall(
            [Web3.to_bytes(hexstr=data), Web3.to_bytes(hexstr=data_in)]
        )

    nonce = w3.eth.get_transaction_count(fromAddr)  # 获取 nonce 值
    params = {
        'from': fromAddr,
        'nonce': nonce,
        'gas': 2361235 + random.randint(10000, 20000),
        'gasPrice': w3.eth.gas_price,
        'value': value
    }
    tx = func.build_transaction(params)
    signed_tx = w3.eth.account.sign_transaction(tx, private_key=privKey)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    print(f'成功，hash：{w3.to_hex(tx_hash)}')


# zk syncswap swap
# 序号；RPC；钱包地址；钱包私钥；设定gas；数量；x=1ETH换USDC，x=2USDC换ETH
def syncswap1(serial,RPC,fromAddr,privKey,gas,amount,x):
    w3 = Web3(Web3.HTTPProvider(RPC))
    weth = Web3.to_checksum_address('0x5aea5775959fbc2557cc8789bc1bf90a239d9a91')
    usdc = Web3.to_checksum_address('0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4')
    gaslimit = 2361235 + random.randint(10000, 20000)
    if x == 1:
        ratio_status, amt = dealAmount(amount)
        balanceA = getGasBalance(w3, fromAddr)
        if ratio_status == 1:
            tosendvalue = (float(balanceA) - float(w3.eth.gas_price) * gaslimit / 1e9 - 0.0001) * amt
        else:
            tosendvalue = amt
        value = w3.to_wei(str(tosendvalue), 'ether')
    elif x == 2:
        coinconabi = normalABI()
        CoinContract = w3.eth.contract(address=usdc, abi=coinconabi)
        Coinbalance = CoinContract.functions.balanceOf(fromAddr).call()
        dec = CoinContract.functions.decimals().call()
        ratio_status, amt = dealAmount(amount)
        if ratio_status == 1:
            tosendvalue = round(Coinbalance * amt)
        else:
            tosendvalue = amt * 10 ** dec
        value = 0

    # 获取池
    SyncSwapClassicPoolFactory = Web3.to_checksum_address('0xf2DAd89f2788a8CD54625C60b55cD3d2D0ACa7Cb')
    factory_abi = '[{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"getPool","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]'
    factory = w3.eth.contract(SyncSwapClassicPoolFactory, abi=factory_abi)
    weth = Web3.to_checksum_address('0x5aea5775959fbc2557cc8789bc1bf90a239d9a91')
    usdc = Web3.to_checksum_address('0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4')
    pool_address = factory.functions.getPool(weth, usdc).call()
    # print(pool_address)

    # 获取池信息getAmountOut
    if pool_address != constants.ADDRESS_ZERO:
        pool_abi = '[{"inputs":[{"internalType":"address","name":"_tokenIn","type":"address"},{"internalType":"uint256","name":"_amountIn","type":"uint256"},{"internalType":"address","name":"_sender","type":"address"}],"name":"getAmountOut","outputs":[{"internalType":"uint256","name":"_amountOut","type":"uint256"}],"stateMutability":"view","type":"function"}]'
        pool = w3.eth.contract(pool_address, abi=pool_abi)
        if x == 1:
            # ETH兑换usdc
            amountout = pool.functions.getAmountOut(weth, value, fromAddr).call()
        elif x == 2:
            # usdc兑换ETH
            amountout = pool.functions.getAmountOut(usdc, tosendvalue, fromAddr).call()
        # print(amountout)
    else:
        print('无池子信息')

    # 构建inputdata数据，1是ETH换usdc，2是USDC换回ETH
    method = '0x2cc4081e'
    data0 = '0000000000000000000000000000000000000000000000000000000000000060'
    data1 = Web3.to_hex(int(amountout*0.99))[2:].rjust(64, '0')
    data2 = Web3.to_hex(int(time.time()) + 1800)[2:].rjust(64, '0')
    data3 = '000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000060'
    if x == 1:
        data3_1 = constants.ADDRESS_ZERO[2:].rjust(64, '0')
    elif x == 2:
        data3_1 = usdc[2:].rjust(64, '0')
    data4 = Web3.to_hex(tosendvalue)[2:].rjust(64, '0')
    data5 = '00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020'
    data6 = pool_address[2:].rjust(64, '0')  # '0x80115c708e12edd42e504c1cd52aea96c547c05c'
    data7 = '0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000060'
    if x == 1:
        data7_1 = weth[2:].rjust(64, '0')
    elif x == 2:
        data7_1 = usdc[2:].rjust(64, '0')
    data8 = fromAddr[2:].rjust(64, '0')
    if x == 1:
        data9 = '00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000'
    elif x == 2:
        data9 = '00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000'
    inputdata = method + data0 + data1 + data2 + data3 + data3_1 + data4 + data5 + data6 + data7 + data7_1 + data8 + data9

    # swap
    routerAddress = Web3.to_checksum_address('0x2da10A1e27bF85cEdD8FFb1AbBe97e53391C0295')
    transfercontract(serial,w3, routerAddress,fromAddr,privKey, gas,value,inputdata,gaslimit=gaslimit)

if __name__ == "__main__":
    f = sys.argv
    res = ""
    match(f[1]):
        case "syncswap1":
            res = syncswap1(f[2], f[3], f[4], f[5], f[6], f[7], f[8])
        case "izumi":
            res =izumi(f[2], f[3], f[4], f[5], f[6])
        case "spacefi":
            res = spacefi(f[2], f[3], f[4], f[5], f[6], f[7],f[8])
        case "velocore":
            res = velocore(f[2], f[3], f[4], f[5], f[6], f[7],f[8])
        case "layerswap":
            res = layerswap(f[2], f[3], f[4], f[5], f[6], f[7],f[8], f[9])
        case "stargateBridge":
            res = stargateBridge(f[2], f[3], f[4], f[5], f[6], f[7],f[8], f[9], f[10])
        case "syncswap":
            res = syncswap(f[2], f[3], f[4], f[5], f[6], f[7],f[8])
        case "evmContractinteract":
            res = evmContractinteract(f[2], f[3], f[4], f[5], f[6], f[7],f[8], f[9], f[10])
        case "bnApiwithdraw":
            res = bnApiwithdraw(f[2], f[3], f[4], f[5], f[6], f[7],f[8])
        case "okxApiwithdraw":
            res = okxApiwithdraw(f[2], f[3], f[4], f[5], f[6], f[7],f[8])
        case "sendToken":
            res = sendToken(f[2], f[3], f[4], f[5], f[6], f[7],f[8], f[9])
        case "sendGastoken":
            res = sendGastoken(f[2], f[3], f[4], f[5], f[6], f[7],f[8], f[9])
        case "getGasBalance":
            res = getGasBalance(f[2], f[3])
        case "checkTokenbalance":
            res = checkTokenbalance(f[2], f[3], f[4])
    print(res)
 ''';
}
