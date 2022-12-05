#REPO_HOST='http://ia.red.os'
#CRT_HOST='http://ia.red.os'
#!/bin/bash
#REPO_HOST='http://10.1.36.27'
#CRT_HOST='http://10.1.36.27'
RHOMEDIR=$(eval echo ~$USER)


function start_message {
  zenity --info --width=420 --height=130 --text "Выполните обновление системы перед работой со скриптом.\nДля этого выберите пункт - <b>Настройка репозитория</b>,\nа после - <b>Обновление системы</b>."
}

#Проверка root прав
if [ "$(id -u)" != "0" ]; then
   zenity --error --text="Запустите скрипт от пользователя root"
   exit 1
fi

#Создание лога установки
if [ ! -f "/var/log/install-assistant/install-assistant.log" ]; 
    then 
        mkdir /var/log/install-assistant
        touch /var/log/install-assistant/install-assistant.log 
        timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log 
        echo "Файл логирования создан" >> /var/log/install-assistant/install-assistant.log
fi   

#Создание папки для отслеживания состояния выполнения скрипта
if [ ! -d "/tmp/install-assistant/" ]; 
    then 
        mkdir /tmp/install-assistant/
        touch /tmp/install-assistant/check_installed
        echo "Файл проверки состояния установки пункта создан" >> /var/log/install-assistant/install-assistant.log 
fi 

#Всплывающее окно
if ! grep addrepo=1 /tmp/install-assistant/check_installed;
    then
    start_message
fi

function final_install {
  zenity --info --width=200 --height=100 --text "Настройка завершена"
}


# Настройка репозитория, для конфигурирования репозиториев изменить на сервере файл /var/www/html/install-assistant/assistant_repo/assistant.repo
function addrepo {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log 

    if grep 'addrepo=1' /tmp/install-assistant/check_installed; 
        then
            echo 'Репозиторий уже настроен' && echo 'Репозиторий уже настроен' >> /var/log/install-assistant/install-assistant.log 
        else
            echo 'Изменение репозитория' >> /var/log/install-assistant/install-assistant.log 
            sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
            setenforce 0
            #rm -rf /etc/yum.repos.d/RedOS-Base.repo /etc/yum.repos.d/RedOS-Updates.repo
            wget -P /etc/yum.repos.d/ $REPO_HOST/install-assistant/assistant_repo/assistant.repo
            #wget -P /etc/yum.repos.d -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/assistant_repo/RedOS-Base.repo
            #wget -P /etc/yum.repos.d -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/assistant_repo/RedOS-Updates.repo
            #wget -P /etc/yum.repos.d -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/assistant_repo/RedOS-Kernels.repo
            echo "addrepo=1" >> /tmp/install-assistant/check_installed
            if grep "baseurl=http://lvn-mgmt1.adm.gazprom.ru/pulp/content/Gazprom/RedOS_7_3/RedOS_73/custom/RedOS_7_3/RedOS_7_3_Base" /etc/yum.repos.d/RedOS-Base.repo && grep "baseurl=http://lvn-mgmt1.adm.gazprom.ru/pulp/content/Gazprom/RedOS_7_3/RedOS_73/custom/RedOS_7_3/RedOS_7_3_Kernels" /etc/yum.repos.d/RedOS-Kernels.repo && grep "baseurl=http://lvn-mgmt1.adm.gazprom.ru/pulp/content/Gazprom/RedOS_7_3/RedOS_73/custom/RedOS_7_3/RedOS_7_3_Updates" /etc/yum.repos.d/RedOS-Updates.repo; 
                then  
                    echo "addrepo=1" >> /tmp/install-assistant/check_installed 
                    echo "
                    Репозиторий /etc/yum.repos.d/RedOS-Base.repo успешно настроен
                    Репозиторий /etc/yum.repos.d/RedOS-Kernels.repo успешно настроен
                    Репозиторий /etc/yum.repos.d/RedOS-Updates.repo успешно настроен
                    " >> /var/log/install-assistant/install-assistant.log 
                    echo -e "Репозиторий настроен успешно" >> /var/log/install-assistant/install-assistant.log 
                else 
                    echo -e "Настройка репозитория произошла с ошибкой. Проверьте файлы в папке /etc/yum.repos.d/"
            fi
    fi
}

#Обновление системы
function update_system {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log 
    su $USER -c 'dconf write /org/mate/desktop/session/idle-delay 60'

RUSER=$(logname)
RHOMEDIR=$(eval echo ~$USER)

    echo "Выполняется обновление системы" && echo "Обновление системы" >> /var/log/install-assistant/install-assistant.log
    dnf makecache
    dnf update -y

    #Удаление лишних пакетов
    echo "Удаление лишних пакетов" >> /var/log/install-assistant/install-assistant.log
    dnf remove blueberry  cheese vlc* brasero* ekiga* goldendict mate-dictionary dnfdragor* -y
    packages=(blueberry libreoffice cheese vlc brasero ekiga goldendict mate-dictionary dnfdragora)
    chck_deleted_pkgs=${#packages[@]}
    for i in ${packages[@]}
        do
        if [ `which $i` == "/usr/bin/$i" ];
            then
                echo "Пакет $i не удален" >> /var/log/install-assistant/install-assistant.log
            else
                echo "Пакет $i удален" >> /var/log/install-assistant/install-assistant.log
                let chck_deleted_pkgs=$chck_deleted_pkgs+-1
        fi
    done

    if [ $chck_deleted_pkgs == 0 ];
        then
            echo "Все пакеты удалены" >> /var/log/install-assistant/install-assistant.log
    fi

    #Добавление сервера синхронизации времени
    echo "Добавление сервера синхронизации времени" >> /var/log/install-assistant/install-assistant.log
    echo "server adm.gazprom.ru" >> /etc/ntp.conf
    systemctl restart ntpd
    systemctl enable ntpd --now

    if grep adm.gazprom.ru /etc/ntp.conf;
        then
            echo "Сервер синхронизации adm.gazprom.ru добавлен"  >> /var/log/install-assistant/install-assistant.log
    fi
    
    wget -P /tmp/ $REPO_HOST/install-assistant/tmp/kernel.sh
    echo "sh /tmp/kernel.sh" >> /etc/gdm/PreSession/Default
}

# Изменение имени АРМ
function set_hostname {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log 

    ud_hostname=$(dmidecode -t system | grep Serial | awk -F" " '{ print $3}')
    arm_hostname=$(cat /etc/hostname)

    if [[ "$arm_hostname" == "$ud_hostname" ]]; then
        echo "Имя компьтера $arm_hostname"
        else
            hostnamectl set-hostname "$ud_hostname"
            arm_hostname=$ud_hostname
            echo "Имя АРМ изменено на $arm_hostname" && echo "Имя АРМ изменено на $arm_hostname" >> /var/log/install-assistant/install-assistant.log 
    fi
}

#Установка ПО для работы с ключевыми носителями
function install_smartcard_software {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log 
    #Проверка наличия репозитория
    if ! grep addrepo=1 /tmp/install-assistant/check_installed;
        then
            echo "Установите репозиторий assistant.repo"
            echo "Установите репозиторий assistant.repo" >> /var/log/install-assistant/install-assistant.log 
            exit 1 
    fi   

    #Проверка выполнености пункта
    if grep "install_smartcard_software=1" /tmp/install-assistant/check_installed;
        then
            echo "ПО для работы с ключевыми носителями уже установлено"
            echo "ПО для работы с ключевыми носителями уже установлено" >> /var/log/install-assistant/install-assistant.log 
        else
            #Установка ПО для работы с ключевыми носителями
            echo 'Установка ПО для работы с ключевыми носителями' && echo 'Установка ПО для работы с ключевыми носителями' >> /var/log/install-assistant/install-assistant.log 
            echo "Лог установки находится по пути /var/log/install-assistant/install-assistant.log"
            #Установка JaCarta SAC 
            echo 'Лог подробной установки ПО для работы с ключевыми носителями создан по пути /var/log/install-assistant/install_smartcard_software.log' >> /var/log/install-assistant/install-assistant.log 
            echo "Производится установка JaCarta SAC..." && echo "Установка JaCarta SAC" >> /var/log/install-assistant/install_smartcard_software.log
            dnf install jacartauc jcpkcs11-2 pcsc-asedriveiiie-usb SafenetAuthenticationClient pcsc-lite -y >> /var/log/install-assistant/install_smartcard_software.log 

            #Установка SecurLogon
            echo "Производится установка SecurLogon..." && echo "Установка SecurLogon" >> /var/log/install-assistant/install_smartcard_software.log
            wget -P /tmp/install-assistant $CRT_HOST/install-assistant/tmp/SecurLogon.tar.gz >> /var/log/install-assistant/install_smartcard_software.log
            tar xvzf /tmp/install-assistant/SecurLogon.tar.gz -C /tmp/install-assistant/ >> /var/log/install-assistant/install_smartcard_software.log
            rm -rf /tmp/install-assistant/SecurLogon.tar.gz
            sudo bash /tmp/install-assistant/install.sh -s -a >> /var/log/install-assistant/install_smartcard_software.log 

            if rpm -qa | grep jacartauc && rpm -qa | grep jcpkcs11-2 && rpm -qa | grep pcsc-asedriveiiie-usb && rpm -qa | grep SafenetAuthenticationClient && rpm -qa | grep pcsc-lite && [ -f /usr/bin/jcsecurlogon-pkexec ]
                then
                    echo "Пакет `rpm -qa | grep jacartauc` установлен" >> /var/log/install-assistant/install-assistant.log 
                    echo "Пакет `rpm -qa | grep jcpkcs11-2` установлен" >> /var/log/install-assistant/install-assistant.log 
                    echo "Пакет `rpm -qa | grep pcsc-asedriveiiie-usb` установлен" >> /var/log/install-assistant/install-assistant.log 
                    echo "Пакет `rpm -qa | grep SafenetAuthenticationClient` установлен" >> /var/log/install-assistant/install-assistant.log 
                    echo "Пакет `rpm -qa | grep pcsc-lite` установлен" >> /var/log/install-assistant/install-assistant.log 
                    echo "SecurLogon установлен" >> /var/log/install-assistant/install-assistant.log 
                    echo "Все пакеты установлены!" >> /var/log/install-assistant/install-assistant.log 
                    echo "install_smartcard_software=1" >> /tmp/install-assistant/check_installed
                    echo "Установка завершена успешно" && echo "Установка завершена успешно" >> /var/log/install-assistant/install-assistant.log
            fi
    fi
}

#Настройка 2фа SecurLogon
function two_fa_config {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log

    #Проверка наличия репозитория
    if ! grep addrepo=1 /tmp/install-assistant/check_installed;
        then
            echo "Установите репозиторий assistant.repo"
            echo "Установите репозиторий assistant.repo" >> /var/log/install-assistant/install-assistant.log
            exit 1 
    fi

    #Установка SecurLogon
    if grep "two_fa_config=1" /tmp/install-assistant/check_installed;
        then
            echo "SecurLogon уже настроен"
            echo "SecurLogon уже настроен" >> /var/log/install-assistant/install-assistant.log
        else
            if which jcsecurlogon; 
                then
                    echo "Выполняется настройка SecurLogon" && echo "Выполняется настройка SecurLogon" >> /var/log/install-assistant/install-assistant.log
                    wget -P /tmp/install-assistant $CRT_HOST/install-assistant/keys/domain_crt/iss.pem
                    wget -P /tmp/install-assistant $CRT_HOST/install-assistant/keys/domain_crt/root.pem
                    wget -P /tmp/install-assistant $CRT_HOST/install-assistant/keys/domain_crt/180_days.lic
                    jc-greeter.py -s on
                    sudo jcsecurlogon --network-install --cert="/tmp/install-assistant/iss.pem" --cert="/tmp/install-assistant/root.pem" --license-file="/tmp/install-assistant/180_days.lic"
                    sleep 6
                    sudo jcsecurlogon --network-install --cert="/tmp/install-assistant/iss.pem" --cert="/tmp/install-assistant/root.pem"
                    sleep 6

                    aa="\"actionOnTokenDisabled\": \"-1\""
                    bb="\"actionOnTokenDisabled\": \"1\""
                    sed -i "s/$aa/$bb/" /usr/local/etc/jcsecurlogon/jcsecurlogond.conf

                    echo "two_fa_config=1" >> /tmp/install-assistant/check_installed
                    echo "SecurLogon успешно настроен" && echo "SecurLogon успешно настроен" >> /var/log/install-assistant/install-assistant.log
                else
                    echo "Securlogon не установлен" && echo "Securlogon не установлен" >> /var/log/install-assistant/install-assistant.log
                    exit 1
            fi
    fi
}

#Установка базового ПО
function install_base_software {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log

    #Проверка наличия репозитория
    if ! grep addrepo=1 /tmp/install-assistant/check_installed;
        then
            echo "Установите репозиторий assistant.repo"
            echo "Установите репозиторий assistant.repo" >> /var/log/install-assistant/install-assistant.log
            exit 1 
    fi

    #Проверка выполнености пункта
    if grep install_base_software=1 /tmp/install-assistant/check_installed;
        then
            echo "Программное обеспечение уже установлено"
            echo "Программное обеспечение уже установлено" >> /var/log/install-assistant/install-assistant.log
        else
            echo "Установка базового ПО" && echo "Установка базового ПО" >> /var/log/install-assistant/install-assistant.log
            echo "Лог установки находится по пути /var/log/install-assistant/install-assistant.log"
            echo 'Лог подробной установки базового ПО создан по пути /var/log/install-assistant/install_base_software.log' >> /var/log/install-assistant/install-assistant.log
            # Установка r7-office r7-organizer firefox 1C
            echo "Производится установка r7-office r7-organizer firefox 1C" && echo "Установка r7-office r7-organizer firefox 1C" >> /var/log/install-assistant/install_base_software.log
            dnf install r7-office r7-office-organizer firefox -y >> /var/log/install-assistant/install_base_software.log
			
			echo "Настройка Р7-Офис плагины" >> /var/log/install-assistant/install_base_software.log
			
			rm -rf /opt/r7-office/desktopeditors/editors/sdkjs-plugins 
			wget -O /opt/r7-office/desktopeditors/editors/sdkjs-plugins.tar.gz $REPO_HOST/install-assistant/r7-office/sdkjs-plugins.tar.gz 
			tar xvzf /opt/r7-office/desktopeditors/editors/sdkjs-plugins.tar.gz -C /opt/r7-office/desktopeditors/editors
			rm -rf /opt/r7-office/desktopeditors/editors/sdkjs-plugins.tar.gz
			
			
			

            # Установка Pinta
            dnf install pinta -y >> /var/log/install-assistant/install_base_software.log

            # Установка VK-teams
            echo "Производится установка VK-teams" && echo "Установка VK-teams" >> /var/log/install-assistant/install_base_software.log
            wget -P /tmp/vkteams -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/tmp/vkteams.tar.gz
            cd /tmp/vkteams && tar xvzf /tmp/vkteams/vkteams.tar.gz
            #rm -f Skala_R.tar.gz vkteams.tar.gz
            chmod 777 -R /tmp/vkteams
            echo -e "[Desktop Entry]
            Name=Vkteams
            Name[ru]=Vkteams
            GenericName=Vkteams
            GenericName[ru]=Vkteams
            Path=/tmp/vkteams/
            Exec=/tmp/vkteams/vkteams
            Icon=vkteams
            Categories=Network;
            Keywords=Vkteams
            Comment=Vk teams
            Comment[ru]=Клиент для запуска Vk teams
            Terminal=false
            Type=Application
            StartupNotify=true" >> /tmp/vkteams.desktop

            # Установка Скала-Р
            echo "Производится установка Скала-Р" && echo "Установка Скала-Р" >> /var/log/install-assistant/install_base_software.log
            wget -P /tmp/Skala_R -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/tmp/Skala_R.tar.gz
            cd /tmp/Skala_R && tar xvzf /tmp/Skala_R/Skala_R.tar.gz
            dnf install xdotool xfreerdp libyaml -y >> /var/log/install-assistant/install_base_software.log
            dnf install /tmp/Skala_R/RXClient/rx*/*.rpm -y >> /var/log/install-assistant/install_base_software.log
            rpm -i /tmp/Skala_R/vdi-client*/environment-client-agent-red7/*.rpm >> /var/log/install-assistant/install_base_software.log
            rpm -i /tmp/Skala_R/vdi-client*/vdi*.rpm >> /var/log/install-assistant/install_base_software.log

            if which r7-office firefox && [ -f /opt/vdi-client/bin/linux_vdi_client_wrapper.sh ] && [ -f /tmp/vkteams/vkteams ]; 
                then
                    echo "Установлен пакет `rpm -qa | grep r7-office-organizer`" >> /var/log/install-assistant/install-assistant.log
                    echo "Установлен пакет `rpm -qa | grep r7-office-7`" >> /var/log/install-assistant/install-assistant.log
                    echo "Установлен пакет `rpm -qa | grep firefox`" >> /var/log/install-assistant/install-assistant.log
                    echo "Установлен VK teams" >> /var/log/install-assistant/install-assistant.log
                    echo "Установлена Скала-Р" >> /var/log/install-assistant/install-assistant.log
                    echo "install_base_software=1" >> /tmp/install-assistant/check_installed
                    echo "Установка завершена успешно" && echo "Установка завершена успешно" >> /var/log/install-assistant/install-assistant.log
                else
                    if which r7-office;
                        then
                            echo "r7-office установлен" >> /var/log/install-assistant/install-assistant.log
                        else
                            echo "r7-office не установлен" >> /var/log/install-assistant/install-assistant.log
                    fi
                    if which firefox;
                        then
                            echo "firefox установлен" >> /var/log/install-assistant/install-assistant.log
                        else
                            echo "firefox не установлен" >> /var/log/install-assistant/install-assistant.log
                    fi
                    if [ -f /opt/vdi-client/bin/linux_vdi_client_wrapper.sh ];
                        then
                            echo "Скала-Р установлен" >> /var/log/install-assistant/install-assistant.log
                        else
                            echo "Скала-Р не установлен" >> /var/log/install-assistant/install-assistant.log
                    fi
                    if [ -f /tmp/vkteams/vkteams ];
                        then
                            echo "vkteams установлен" >> /var/log/install-assistant/install-assistant.log
                        else
                            echo "vkteams не установлен" >> /var/log/install-assistant/install-assistant.log
                    fi
            fi 
    fi
}

#Установка СЗИ
function install_SZI {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log

    #Проверка наличия репозитория
    if ! grep addrepo=1 /tmp/install-assistant/check_installed;
        then
            echo "Установите репозиторий assistant.repo"
            echo "Установите репозиторий assistant.repo" >> /var/log/install-assistant/install-assistant.log
            exit 1 
    fi

    sed -i 's^SELINUX=enforcing^SELINUX=permissive^' /etc/selinux/config 
    setenforce 0
    dnf install perl-Getopt-Long perl-File-Copy -y
    wget -P /tmp/kesl/ -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/tmp/KESL.tar.gz
    tar xvzf /tmp/kesl/KESL.tar.gz -C /tmp/kesl/
    sh /tmp/kesl/klnagent64*.sh
    /opt/kaspersky/klnagent64/bin/klnagchk
    dnf install /tmp/kesl/kesl-11*.rpm -y
    /opt/kaspersky/kesl/bin/kesl-setup.pl --autoinstall=/tmp/kesl/autoinstall_kesl.ini
    dnf install /tmp/kesl/kesl-gui-*.rpm -y
    chown root /usr/
    chown root /opt/
    chown root -R /var/opt/kaspersky/
    chmod u-w,g-w /usr/
    chmod u-w,g-w /opt/ 
    chmod u-w,g-w /var/opt/kaspersky/
    rm -rf /tmp/kesl

    #Проверка выполнености пункта
    if grep install_SZI=1 /tmp/install-assistant/check_installed;
        then
            echo "Средства защиты информации уже установлены"
            echo "Средства защиты информации уже установлены" >> /var/log/install-assistant/install-assistant.log
        else
            # Установка РИИБ
            echo 'Выполняется установка РИИБ...' && echo 'Выполняется установка РИИБ...' >> /var/log/install-assistant/install_SZI.log && echo 'Выполняется установка РИИБ...' >> /var/log/install-assistant/install-assistant.log
            wget -P /tmp/ -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/tmp/agent-install-0.10.90-august.sh
            chmod +x /tmp/agent-install-0.10.90-august.sh
            sh /tmp/agent-install-0.10.90-august.sh spb02-l-scapp.adm.gazprom.ru 10443

            # Установка Litoria
            echo 'Выполняется установка Litoria...' && echo 'Выполняется установка Litoria...' >> /var/log/install-assistant/install_SZI.log && echo 'Выполняется установка Litoria...' >> /var/log/install-assistant/install-assistant.log
            dnf install litoria-* -y >> /var/log/install-assistant/install_SZI.log 


            if rpm -qa | grep kesl && rpm -qa | grep litoria;
                then
                    echo "Установлен пакет `rpm -qa | grep kesl`" >> /var/log/install-assistant/install-assistant.log
                    echo "Установлен пакет `rpm -qa | grep litoria`" >> /var/log/install-assistant/install-assistant.log
                    echo "Установлен пакет РИИБ" >> /var/log/install-assistant/install-assistant.log
                    echo "install_SZI=1" >> /tmp/install-assistant/check_installed
                    echo "Установка завершена успешно" && echo "Установка завершена успешно" >> /var/log/install-assistant/install-assistant.log
            fi
    fi
}

#Установка x2go
function install_x2go {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log

    if grep "ExecStart=/usr/bin/x11vnc -many -shared -display :0 -auth guess -noxdamage -rfbauth /etc/vncpasswd" /lib/systemd/system/x11vnc.service;
        then
            echo "X2GO уже установлен и настроен. Пароль: qwerty1" && echo "X2GO уже установлен и настроен. Пароль: qwerty1"  >> /var/log/install-assistant/install-assistant.log
        else
            echo "Выполняется установка и настройка X2GO клиента" && echo "Выполняется установка и настройка X2GO клиента" >> /var/log/install-assistant/install-assistant.log
            dnf install x11vnc x2goserver -y
            x11vnc -storepasswd qwerty1 /etc/vncpasswd
            touch /lib/systemd/system/x11vnc.service
            echo -e "[Unit]
            Description=x11vnc server for GDM
            After=display-manager.service

            [Service]
            ExecStart=/usr/bin/x11vnc -many -shared -display :0 -auth guess -noxdamage -rfbauth /etc/vncpasswd
            Restart=on-failure
            RestartSec=3

            [Install]
            WantedBy=graphical.target" >> /lib/systemd/system/x11vnc.service
            systemctl enable x11vnc --now

            if grep "ExecStart=/usr/bin/x11vnc -many -shared -display :0 -auth guess -noxdamage -rfbauth /etc/vncpasswd" /lib/systemd/system/x11vnc.service;
                then
                    echo "X2GO установлен" && echo "X2GO установлен"  >> /var/log/install-assistant/install-assistant.log
                    echo "Пароль: qwerty1" && echo "Пароль: qwerty1"  >> /var/log/install-assistant/install-assistant.log
                else
                    echo "X2GO не установлен"
            fi
    fi
}

#Отключение обновлений Р7
function disable_updates_r7 {
    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log    
    echo "Отключение обновлений Р7" && echo "Отключение обновлений Р7" >> /var/log/install-assistant/install-assistant.log 
    if grep "disable_updates_r7=1" /tmp/install-assistant/check_installed;
        then
            echo "Обновления уже отключены" && echo "Обновления уже отключены" >> /var/log/install-assistant/install-assistant.log
        else
            if ! which r7-office;
                then 
                    echo "Р7 не установлен" && echo "Р7 не установлен" >> /var/log/install-assistant/install-assistant.log
            else
echo "{

  \"policies\": {

    \"DisableAppUpdate\": true

  }

}" >> /opt/r7-office/organizer/distribution/policies.json

            sed -i 's/pref("app.update.channel", "default");/pref("app.update.channel", "no");/' /opt/r7-office/organizer/defaults/pref/channel-prefs.js
            echo "pref(\"app.update.auto\", false);" >> /opt/r7-office/organizer/defaults/pref/channel-prefs.js
            echo "pref(\"app.update.enabled\", false);" >> /opt/r7-office/organizer/defaults/pref/channel-prefs.js

            if grep "pref(\"app.update.enabled\", false);" /opt/r7-office/organizer/defaults/pref/channel-prefs.js && grep DisableAppUpdate /opt/r7-office/organizer/distribution/policies.json;
                then
                    echo "Обновление Р7 отключено" && echo "Обновление Р7 отключено" >> /var/log/install-assistant/install-assistant.log
                    echo "disable_updates_r7=1" >> /tmp/install-assistant/check_installed
                else
                    echo "Ошибка при отключении обновлений"
            fi
            fi
    fi         
}

#Установка 1C
function install_1c {
    #Проверка выполнености пункта
    if grep "1c-$USER=1" /tmp/install-assistant/check_installed;
        then
            echo ""
        else
            #Проверка наличия репозитория
            if ! grep addrepo=1 /tmp/install-assistant/check_installed;
                then
                    echo "Установите репозиторий assistant.repo"
                    echo "Установите репозиторий assistant.repo" >> /var/log/install-assistant/install-assistant.log 
                    exit 1 
            fi

            timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log

            echo "Выполняется установка 1C..." && echo "Выполняется установка 1C..." >> /var/log/install-assistant/install-assistant.log
            dnf install 1c-enterprise* msttcore-fonts-installer -y
            su $USER -c '/opt/1cv8/x86_64/8.3.18.1289/1cestart'
            sleep 5
            killall 1cv8s
            #rm -rf $RHOMEDIR/.1C/1cestart/*
            wget -P $RHOMEDIR/.1C/1cestart/ -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/tmp/ibases.v8i
            chmod 777 $RHOMEDIR/.1C/1cestart/*

            if rpm -qa | grep 1c-enterprise && rpm -qa | grep msttcore-fonts-installer;
                then
                    echo "1c-$USER=1" >> /tmp/install-assistant/check_installed
                    echo "Установка завершена успешно"  >> /var/log/install-assistant/install-assistant.log
            fi
    fi
}

#Установка цитрикса
function install_stunnel {
    #Создание лога установки
    if [ ! -f "/var/log/install-assistant/install-assistant.log" ]; 
        then 
            mkdir /var/log/install-assistant
            touch /var/log/install-assistant/install-assistant.log 
            timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log
            echo "Файл логирования создан" >> /var/log/install-assistant/install-assistant.log
    fi    

    timedatectl | grep Local >> /var/log/install-assistant/install-assistant.log

    #Проверка выполнености пункта
    if grep "citrix_$USER=1" /tmp/install-assistant/check_installed;
        then
            echo ""
        else
            echo "Выполняется установка citrix..." && echo "Выполняется установка citrix..." >> /var/log/install-assistant/install-assistant.log 
            echo "Лог подробной установки находится по пути /var/log/install-assistant/citrix-$USER.log" && echo "Лог подробной установки находится по пути /var/log/install-assistant/citrix-$USER.log" >> /var/log/install-assistant/install-assistant.log 
            update-ca-trust enable
            wget -P /etc/pki/ca-trust/source/anchors/ --recursive --reject="index.html*" --no-parent -nd $CRT_HOST/install-assistant/keys/ >> /var/log/install-assistant/citrix-$USER.log
            update-ca-trust extract

            wget -P /etc/pki/ --recursive --reject="index.html*" --no-parent -nd $REPO_HOST/install-assistant/stunnel/crt/ >> /var/log/install-assistant/citrix-$USER.log
            wget -P /etc/sysconfig $REPO_HOST/install-assistant/stunnel/iuspt-in.cnf >> /var/log/install-assistant/citrix-$USER.log
            wget -P /etc/sysconfig $REPO_HOST/install-assistant/stunnel/iuspt-out.cnf >> /var/log/install-assistant/citrix-$USER.log
            wget -P /usr/lib/systemd/system/ $REPO_HOST/install-assistant/stunnel/iuspt-in.service >> /var/log/install-assistant/citrix-$USER.log
            wget -P /usr/lib/systemd/system/ $REPO_HOST/install-assistant/stunnel/iuspt-out.service >> /var/log/install-assistant/citrix-$USER.log

            setenforce 0
            sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config


            #Установка Firefox и создание профиля
            dnf clean all
            dnf install firefox -y >> /var/log/install-assistant/citrix-$USER.log

            echo "pref('security.tls.version.enable-deprecated', true);" >> /usr/lib64/firefox/browser/defaults/preferences/all-redsoft.js
            echo "pref('network.negotiate-auth.allow-non-fqdn', true);" >> /usr/lib64/firefox/browser/defaults/preferences/all-redsoft.js
            echo "pref('network.negotiate-auth.delegation-uris', '.vkteam.adm.gazprom.ru');" >> /usr/lib64/firefox/browser/defaults/preferences/all-redsoft.js
            echo "pref('network.negotiate-auth.trusted-uris', '.vkteam.adm.gazprom.ru, https://');" >> /usr/lib64/firefox/browser/defaults/preferences/all-redsoft.js

            if [ -f "$RHOMEDIR/.mozilla/" ]; then
            echo "профиль Firefox создан"
            else
            echo "Повторное создание профиля Firefox"
            sudo -u $USER firefox &
            sleep 30
            killall firefox
            fi

            #Установка КриптоПРО 4 и stunnel GOST
            echo 'Установка КриптоПро' && echo 'Установка КриптоПро' >> /var/log/install-assistant/citrix-$USER.log
            #cprocsp-stunnel-64
            dnf install cprocsp-rdr-jacarta-64 cprocsp-rdr-pcsc-64.x86_64 cprocsp-rdr-rutoken-64.x86_64 ifd-rutokens.x86_64 lsb-cprocsp-base lsb-cprocsp-rdr-64 \
            lsb-cprocsp-kc1-64 lsb-cprocsp-capilite-64 cprocsp-curl-64 lsb-cprocsp-ca-certs cprocsp-rdr-gui-gtk-64 cprocsp-rdr-pcsc-64 cprocsp-rdr-emv-64 \
            cprocsp-rdr-inpaspot-64 cprocsp-rdr-mskey-64 cprocsp-rdr-novacard-64 cprocsp-rdr-rutoken-64  lsb-cprocsp-pkcs11-64 lsb-cprocsp-capilite-64 -y  --nogpgcheck -x lsb-cprocsp-kc2-64-4.0.9963-5.x86_64 >> /var/log/install-assistant/citrix-$USER.log

            echo "Установка Aladdin ПО" && echo "Установка Aladdin ПО" >> /var/log/install-assistant/citrix-$USER.log
            #Aladdin_PO_install
            dnf install jacartauc.x86_64 jcpkcs11-2.x86_64 -y --nogpgcheck >> /var/log/install-assistant/citrix-$USER.log
            #Установка клиента Citrix, Safenet, Stunnel
            echo "Установка Citrix, Safenet, Stunnel" && echo "Установка Citrix, Safenet, Stunnel" >> /var/log/install-assistant/citrix-$USER.log
            dnf install pcsc-asedriveiiie-usb.x86_64 ICAClient SafenetAuthenticationClient cprocsp-stunnel-64 pcsc-lite stunnel --nogpgcheck -y >> /var/log/install-assistant/citrix-$USER.log

            #Автоматическое подключение считывателя
            touch $RHOMEDIR/.mozilla/trig

            # подключение библиотек смарткарт к цитриксу
            ln -sf /usr/lib64/libeToken.so '/opt/Citrix/ICAClient/PKCS#11/'
            ln -sf /usr/lib64/libjcPKCS11-2.so '/opt/Citrix/ICAClient/PKCS#11/'

            # сертификат для цитрикс-клиента
            cp /etc/pki/127.0.0.1.crt /opt/Citrix/ICAClient/keystore/cacerts/127.0.0.1.pem
            /opt/Citrix/ICAClient/util/ctx_rehash >> /var/log/install-assistant/citrix-$USER.log

            # русская клавиатура для цитрикса
            sed -i 's/KeyboardLayout=/KeyboardLayout=Russian/g' /opt/Citrix/ICAClient/config/All_Regions.ini
            sed -i 's/KeyboardLayout=/KeyboardLayout=Russian/g' /opt/Citrix/ICAClient/config/usertemplate/All_Regions.ini

            systemctl daemon-reload
            # обновляем системное хранилище сертификатов для браузера
            update-ca-trust >> /var/log/install-assistant/citrix-$USER.log

            # подключаем в загрузку туннели
            systemctl enable iuspt-in.service
            systemctl enable iuspt-out.service

            mkdir -p /opt/cprocsp/var/run/stunnel

            systemctl start iuspt-in.service
            systemctl start iuspt-out.service

            # подключаем сертификаты к КриптоПро
            echo "Подключение сертификатов" && echo "Подключение сертификатов" >> /var/log/install-assistant/citrix-$USER.log
            /opt/cprocsp/bin/amd64/certmgr -install -store mCA -file /etc/pki/gazprom_inform_ca_gost_2012.cer >> /var/log/install-assistant/citrix-$USER.log
            /opt/cprocsp/bin/amd64/certmgr -install -store mROOT -file /etc/pki/root_gazprom_ca_gost_2012.cer >> /var/log/install-assistant/citrix-$USER.log

            FF_BD_DIR=$(ls $RHOMEDIR/.mozilla/firefox/ | grep default-default)

            echo "
            library=/usr/lib64/pkcs11/p11-kit-trust.so
            name=PKCS#11
            NSS=trustOrder=100

            library=/usr/lib64/libjcPKCS11-2.so
            name=jacarta" >> $RHOMEDIR/.mozilla/firefox/$FF_BD_DIR/pkcs11.txt

            touch $RHOMEDIR/.mozilla/trig

            update-ca-trust enable
            wget -P /etc/pki/ca-trust/source/anchors/ --recursive --reject="index.html*" --no-parent -nd $CRT_HOST/install-assistant/keys/ >> /var/log/install-assistant/citrix-$USER.log
            update-ca-trust extract
			
			
			echo "Connect disk terminal"
			wget -O $RHOMEDIR/.ICAClient/wfclient.ini $REPO_HOST/install-assistant/stunnel/wfclient.ini
			
            if grep "library=/usr/lib64/pkcs11/p11-kit-trust.so" $RHOMEDIR/.mozilla/firefox/$FF_BD_DIR/pkcs11.txt
                then
                    echo "Установка завершена успешно" && echo "Установка завершена успешно" >> /var/log/install-assistant/install-assistant.log 
                    echo "citrix_$USER=1" >> /tmp/install-assistant/check_installed
                else
                    echo "Установка завершена с ошибкой. Проверьте содержимое файла по пути $RHOMEDIR/.mozilla/firefox/$FF_BD_DIR/pkcs11.txt"
                    echo "Установка завершена с ошибкой. Проверьте содержимое файла по пути $RHOMEDIR/.mozilla/firefox/$FF_BD_DIR/pkcs11.txt" >> /var/log/install-assistant/install-assistant.log 
            fi
    fi
}

#Настройка профиля пользователя
function system_setup {
    #Проверка выполнености пункта
    if grep "system_setup=1" /tmp/install-assistant/check_installed;
        then
            echo ""
        else    
            # Настройка изображения рабочего стола, в соответствии с разрешением
            a=$(xdpyinfo | awk '/dimensions/{print $2}')
            echo $a
            wget -P /usr/share/wallpapers/backgrounds/redos/ -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/wallpapers/Lakhta_$a.jpg
            echo "
[org/mate/desktop/background]
picture-filename='/usr/share/backgrounds/redos/Lakhta_$a.jpg'
            " >> /etc/dconf/db/local.d/00_background

            # Настройка политики парольной защиты
            sed -i 's/dcredit = -1/dcredit = -2/' /etc/security/pwquality.conf
            sed -i 's/# difok = 1/difok = 4/' /etc/security/pwquality.conf
            sed -i 's/minlen = 8/minlen = 6/' /etc/security/pwquality.conf

            # Настройка экрана блокировки
            echo "
[org/mate/desktop/session]
idle-delay=15

[org/mate/screensaver]
idle-activation-enabled=true
lock-enabled=true
            " >> /etc/dconf/db/local.d/screensaver_policy

            echo "
/org/mate/desktop/session/idle-delay
/org/mate/screensaver/idle-activation-enabled
/org/mate/screensaver/lock-enabled
/org/mate/desktop/background/picture-filename
            " >> /etc/dconf/db/local.d/locks/screensaver
            
            # Обновление конфигураций dconf
            dconf update

            echo "system_setup=1" >> /tmp/install-assistant/check_installed
    fi
}

#Настройка иконок рабочего стола
function user_setup {
    #Проверка выполнености пункта
    if grep "user_setup-$USER=1" /tmp/install-assistant/check_installed;
        then
            echo ""
        else
            RHOMEDIR=$(eval echo ~$USER)

            #Настройка иконок
            wget -P /usr/share/icons -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/icons/cp-ico.png
            wget -P /usr/share/icons -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/icons/cpico.ico
            wget -P /usr/share/icons -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/icons/favicon.ico
            wget -P $RHOMEDIR/'Рабочий стол' -r -nH --cut-dirs=2 --no-parent --reject="index.html*" $CRT_HOST/install-assistant/icons/web_icons.tar.gz

            chmod 775 /$RHOMEDIR/'Рабочий стол'/
            sudo -u $USER tar xvzf  $RHOMEDIR/'Рабочий стол'/web_icons.tar.gz -C /$RHOMEDIR/'Рабочий стол'/
            rm -rf  $RHOMEDIR/'Рабочий стол'/web_icons.tar.gz

            cp /tmp/vkteams.desktop $RHOMEDIR/'Рабочий стол'/  
            cp /usr/share/applications/1cv8s-*.desktop /$RHOMEDIR/'Рабочий стол'/
            cp /usr/share/applications/r7-office-desktopeditors.desktop /$RHOMEDIR/'Рабочий стол'/
            cp /usr/share/applications/organizer.desktop /$RHOMEDIR/'Рабочий стол'/
            cp /usr/share/applications/litoria.desktop /$RHOMEDIR/'Рабочий стол'/

            chmod 777 $RHOMEDIR/'Рабочий стол'/1cv8s-*.desktop
            chmod 777 $RHOMEDIR/'Рабочий стол'/r7-office-desktopeditors.desktop
            chmod 777 $RHOMEDIR/'Рабочий стол'/organizer.desktop
            chmod 777 $RHOMEDIR/'Рабочий стол'/litoria.desktop
            chmod 777 $RHOMEDIR/'Рабочий стол'/vkteams.desktop

            # Настройка Скала
            cp /usr/share/applications/vdi-client.desktop $RHOMEDIR/'Рабочий стол'/
            chmod +x $RHOMEDIR/'Рабочий стол'/vdi-client.desktop
            chmod 777 $RHOMEDIR/'Рабочий стол'/vdi-client.desktop
            su $USER -c '/opt/vdi-client/bin/linux_vdi_client_wrapper.sh'
            sleep 5
            killall desktop-client
            #cp -f /tmp/Skala_R/app-config $RHOMEDIR/.vdi-client/ 
            cp -f /tmp/Skala_R/app-config-REDOS $RHOMEDIR/.vdi-client/ 
            cp -f /tmp/Skala_R/app-config-WIN $RHOMEDIR/.vdi-client/ 
            cp -f /tmp/Skala_R/app-config-WIN $RHOMEDIR/.vdi-client/app-config

            echo "user_setup-$USER=1" >> /tmp/install-assistant/check_installed
    fi
}

#Установка всех пунктов
function install_all {
        addrepo
        update_system
        set_hostname
        beesu - "join-to-domain.sh -g"
        install_smartcard_software
        two_fa_config
        install_base_software
        install_SZI
        install_x2go
        disable_updates_r7
}

if [ -n "$1" ]
    then
        while [ -n "$1" ]
        do
        case "$1" in
        install_all | addrepo | update_system | set_hostname | install_smartcard_software | two_fa_config | install_base_software | install_SZI | install_x2go | disable_updates_r7 | install_1c | install_stunnel | system_setup | user_setup) $1 ;;
        *) echo "$1 опция не найдена" ;;
        esac
        shift
        done
    exit 1
fi

function main_setup {
    SELECTION=$(zenity --list --text="Выберите необходимые пункты для установки" \
        --checklist --column "Pick" --column "" \
        FALSE '
Выполнить все пункты
' \
        FALSE 'Настройка репозитория' \
        FALSE 'Обновление системы' \
        FALSE 'Переименование АРМ' \
        FALSE 'Ввод в домен' \
        FALSE 'Установка ПО для работы с ключевыми носителями' \
        FALSE 'Настройка 2fa' \
        FALSE 'Установка базового ПО' \
        FALSE 'Установка СрЗИ' \
        FALSE 'Установка x2go и x11vnc' \
        FALSE 'Отключение обновлений Р7' \
        --width=450 --height=550)

        SUB='Выполнить все пункты'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Выполнить все пункты"
        install_all
        fi

        SUB='Настройка репозитория'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Настройка репозитория"
        addrepo
        fi

        SUB='Обновление системы'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Обновление системы"
        update_system
        fi

        SUB='Переименование АРМ'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Переименование АРМ"
        set_hostname
        fi

        SUB='Ввод в домен'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Ввод в домен"
        beesu - "join-to-domain.sh -g"
        fi

        SUB='Установка ПО для работы с ключевыми носителями'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Установка ПО для работы с ключевыми носителями"
        install_smartcard_software
        fi

        SUB='Настройка 2fa'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Настройка 2fa"
        two_fa_config
        fi

        SUB='Установка базового ПО'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Установка базового ПО"
        install_base_software
        fi

        SUB='Установка СрЗИ'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Установка СрЗИ"
        install_SZI
        fi

        SUB='Установка x2go и x11vnc'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Установка x2go и x11vnc"
        install_x2go
        fi

        SUB='Отключение обновлений Р7'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Отключение обновлений Р7"
        disable_updates_r7
        fi
}

function nonmain_setup {
    SELECTION=$(zenity --list --text="Выберите необходимые пункты для установки" \
        --checklist --column "Pick" --column "" \
        FALSE '
Выполнить все пункты
' \
        FALSE 'Установка 1C' \
        FALSE 'Установка ПО для доступа к ТФ' \
        FALSE 'Настройка ПО в профиле пользователя (обои, хранитель сна)' \
        FALSE 'Настройка ОС (ярлыки, конфигурация Скала-Р)' \
        --width=500 --height=550)

        SUB='Выполнить все пункты'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Выполнить все пункты"
        install_1c
        install_stunnel
        system_setup
        user_setup
        fi

        SUB='Установка 1C'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Установка 1C"
        install_1c
        fi

        SUB='Установка ПО для доступа к ТФ'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Установка ПО для доступа к ТФ"
        install_stunnel
        fi

        SUB='Настройка ПО в профиле пользователя (обои, хранитель сна)'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Настройка ПО в профиле пользователя (обои, хранитель сна)"
        system_setup
        fi

        SUB='Настройка ОС (ярлыки, конфигурация Скала-Р)'
        if [[ "$SELECTION" == *"$SUB"* ]]; then
        echo "Настройка ОС (ярлыки, конфигурация Скала-Р)"
        user_setup
        fi
} 

SELECTION=$(zenity --list --text="" \
    --checklist --column "Pick" --column "" \
    FALSE 'Общие настройки АРМ' \
    FALSE 'Настройка учетной записи пользователя АРМ' \
    --width=450 --height=550)


SUB='Общие настройки АРМ'
if [[ "$SELECTION" == *"$SUB"* ]]; then
main_setup
fi

SUB='Настройка учетной записи пользователя АРМ'
if [[ "$SELECTION" == *"$SUB"* ]]; then
nonmain_setup
fi

final_install
