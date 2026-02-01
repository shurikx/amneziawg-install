# AmneziaWG Installer

Этот проект представляет собой **bash-скрипт**, предназначенный для **быстрой и простой установки AmneziaWG** на сервере Linux.
---
## ⚙️ Поддерживаемые системы

- **Debian **  
- **Ubuntu 22.04+**

> Для временных файлов требуется **не менее 2 ГБ свободного места**.
Перед установкой рекомендуется:
Обновить систему до последней версии:
```bash
apt update && apt upgrade -y
```
Перезагрузить сервер после обновления:
```bash
reboot
```
Загрузка скрипта
Используйте curl или wget:
```bash
curl -O https://raw.githubusercontent.com/shurikx/amneziawg-install/main/awg.sh
```
или
```bash
wget https://raw.githubusercontent.com/shurikx/amneziawg-install/main/awg.sh
```
Сделайте скрипт исполняемым:
```bash
chmod +x awg.sh
```
Запустить скрипт:
```bash
./awg.sh
```
Скрипт основан на работе [RomikB](https://github.com/RomikB/amneziawg-install) и доработан для стабильной работы на современных версиях Debian и Ubuntu
