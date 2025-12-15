# AmneziaWG installer
Этот проект представляет собой bash-скрипт, предназначенный для максимально простой настройки VPN AmneziaWG на сервере Linux!
Debian 11–13
Ubuntu >= 24.04
Для временных файлов требуется 2 ГБ свободного места.
Перед установкой настоятельно рекомендуется обновить систему до последней доступной версии и выполнить перезагрузку после этого.
Для загрузки скрипта используйте curl или wget:
```bash
curl -O https://raw.githubusercontent.com/shurikx/amneziawg-install/main/awg.sh
```
```bash
wget https://raw.githubusercontent.com/shurikx/amneziawg-install/main/awg.sh
```
Установите права доступа:
```bash
chmod +x awg.sh
```
И выполните:
```bash
./awg.sh
```
За основу использовал [RomikB](https://github.com/RomikB/amneziawg-install)
