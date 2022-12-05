import os
import wget
from datetime import datetime

#-------------------------Переменные---------------------------

#Логирование
dir_log = "/var/log/install-assistant/"
main_log = "/var/log/install-assistant/install-assistant.log"
#Контроль выполнения пунктов 
dir_check = "/tmp/install-assistant/"
check_installed = "/tmp/install-assistant/check_installed"
#Текущее время
current_date = datetime.now().strftime("%D %H:%M:%S") 
#URL репозитория
repo_host = "http://10.81.11.173"

#--------------------------------------------------------------

#Проверка прав администратора
if os.getuid() != 0: exit()

#Создание журнала установки
if not os.path.exists(dir_log): 
    os.makedirs(dir_log) 
    open(main_log, "w")

#Создание файла контроля выполнения скрипта
if not os.path.exists(dir_check): 
    os.makedirs(dir_check)
    open(check_installed,"w")

#Проверка выполненности пункта
def check_done(section):
    with open(check_installed, "r") as f:
        if section in f.read(): print(section + ' - пункт уже выполнен.'); return

#Настройка репозитория
def addrepo():

    #Проверка выполненности пункта
    check_done("addrepo")

    #Список репозиториев
    repo_list = ["assistant.repo", "RedOS-Base.repo", "RedOS-Updates.repo", "RedOS-Kernels.repo"] 

    #Загрузка и проверка репозиториев
    for repo in repo_list:
        if os.path.isfile("/etc/yum.repos.d/" + repo): os.remove("/etc/yum.repos.d/" + repo)
        wget.download(repo_host + "/install-assistant/assistant_repo/" + repo, "/etc/yum.repos.d/")
        with open("/etc/yum.repos.d/" + repo) as f:
            if "10.78.203.3" in f.read(): print ("Репозиторий " + repo + " не установлен.") # Указать адрес расположения репозитория
            else: print ("Репозиторий " + repo + " не установлен. Проверьте файлы в папке /etc/yum.repos.d/"); quit()
    
    #Запись об успешном завершении функции
    with open(check_installed, "a") as f: f.write("\naddrepo=1") 


#Настройка системы
def update_system():

    #Обновление системы
    os.system("dnf update -y")
    
    #Удаление лишних пакетов
    os.system("dnf remove -y blueberry cheese vlc* brasero* ekiga* goldendict mate-dictionary dnfdragor*")

    #Добавление сервера синхронизации времени
    os.system("echo 'server adm.gazprom.ru' >> /etc/ntp.conf")
    os.system("systemctl restart ntpd")
    os.system("systemctl enable ntpd --now")
    
    #Загрузка скрипта для удаления лишних ядер
    wget.download(repo_host + "/install-assistant/assistant_repo/kernel.sh", "/tmp")
    os.system("`sh /tmp/kernel.sh` >> /etc/gdm/PreSession/Default")

#Изменение имени АРМ
def set_hostname():
    
    ud_hostname=os.popen("dmidecode -t system | grep Serial | awk -F' ' '{ print $3}'").read().strip()
    arm_hostname=os.popen("cat /etc/hostname").read().strip()
    if ud_hostname != arm_hostname: os.system("hostnamectl set-hostname " + ud_hostname)

#Установка ПО для работы с ключевыми носителями
def install_smartcard_software():
    
    #Проверка выполненности пункта
    check_done("install_smartcard_software")

    #Установка JaCarta, SAC
    os.system("dnf install -y jacartauc jcpkcs11-2 jcsecurbio pcsc-asedriveiiie-usb SafenetAuthenticationClient pcsc-lite")

    #Установка SecurLogon
    wget.download(repo_host + "/install-assistant/assistant_repo/SecurLogon.tar.gz", "/tmp/install-assistant")
    os.system("tar xvzf /tmp/install-assistant/SecurLogon.tar.gz -C /tmp/install-assistant/")
    os.system("rm -rf /tmp/install-assistant/SecurLogon.tar.gz")
    os.system("bash /tmp/install-assistant/install.sh -s -a -q")

#Настройка 2фа
def two_fa_config():
        
    #Проверка выполненности пункта
    check_done("two_fa_config")

    #Проверка наличия SecurLogon
    if "jcsecurlogon" not in os.popen("rpm -qa | grep jcsecurlogon").read().strip(): print('Отсутствует SecurLogon. Установите, пожалуйста.'); return

    #Настройка 2фа
    cert_list = ["iss.pem", "root.pem", "180_days.lic"]
    for cert in cert_list: wget.download(repo_host + "/install-assistant/assistant_repo/" + cert, "/tmp/install-assistant")
    