class Const {
  static const String requiredText = '''
pyarmor
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
import sys
if __name__ == "__main__":
    f = sys.argv
    res = ""
    method = f[1]
    m = {"test": "test123"}
    print(m[method])
 ''';
}
