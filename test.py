import os

def test():
    if "p123123" not in os.popen("rpm -qa | grep p7").read().strip(): print('Отсутствует SecurLogon. Установите, пожалуйста.'); return
    print('yes')

test()