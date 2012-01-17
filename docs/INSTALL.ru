=====OS=====
 **Замечания по установкe операционной системы.**
===FreeBSD===
  * При разбиении диска на разделы крайне рекомендуется отвести для раздела **/var** не менее 10 Гигабайт. Если планируется высокая нагрузка это значение можно увеличить.
  * Рекомендованный дистрибутивный набор (Distribution Set) - **6 Kernel-Developer **
  * Более подробно об установке читайте тут [[http://www.asmodeus.com.ua/library/os/freebsd/handbook/|FreeBSD Handbook]]

=====Radius=====
Загрузить пакет FreeRadius можно по адресу [http://www.freeradius.org]

  # tar zxvf freeradius-1.1.0.tar.gz
  # cd freeradius-1.1.0
  # ./configure --prefix=/usr/local/radiusd/
  # make
  # make install

После успешной установки правим файлы:\\
**/usr/local/radiusd/etc/raddb/users**\\

  DEFAULT Auth-Type = Accept
    Exec-Program-Wait = "/usr/abills/libexec/rauth.pl"

**/usr/local/radiusd/etc/raddb/acct_users**

  DEFAULT Acct-Status-Type == Start
     Exec-Program = "/usr/abills/libexec/racct.pl"
  
  DEFAULT Acct-Status-Type == Alive
     Exec-Program = "/usr/abills/libexec/racct.pl"
  
  DEFAULT Acct-Status-Type == Stop
     Exec-Program = "/usr/abills/libexec/racct.pl"

**/usr/local/radiusd/etc/raddb/clients.conf**\\
В этот файл нужно вписать IP адрес или имя NAS сервера с
которого будут поступать данные для радиуса и пароль доступа.
\\
  client nashost.nasdomain {
     secret = radsecret
     shortname = shorrname
  }
\\

**/usr/local/radiusd/etc/raddb/radiusd.conf**\\
В этом файле нужно закомментировать использование модулей
'chap' и 'mschap' в разделе 'authorize'

  authorize {
    preprocess
  #  chap
  #  counter
  #  attr_filter
  #  eap
  #  suffix
    files
  # etc_smbpasswd
  # sql
  # mschap
  }















=====MySQL=====
Загрузить пакет MySQL можно по адресу [http://www.mysql.com]\\

  # tar xvfz mysql-4.1.16.tar.gz
  # cd mysql-4.1.16
  # ./configure
  # make
  # make install

Создаём пользователя и базу.

  # mysql -u root -p

  use mysql;
  INSERT INTO user (Host, User, Password) 
    VALUES ('localhost','abills', password('sqlpassword'));
  
  INSERT INTO db (Host, Db, User, Select_priv, Insert_priv, Update_priv, 
    Delete_priv, Create_priv, Drop_priv, Index_priv, Alter_priv, 
    Lock_tables_priv, Create_tmp_table_priv) 
  VALUES ('localhost', 'abills', 'abills', 'Y', 'Y', 'Y', 'Y', 'Y', 
    'Y', 'Y', 'Y', 'Y', 'Y');
  CREATE DATABASE abills;
  flush privileges;


Загружаем таблицы в базу. \\

  # mysql -D abills < abills.sql

Если возникают трудности с кодировками используйте флаг ''--default-character-set=''

=====Web Server=====




=====Apache=====
 [[http://www.apache.org|Apache]]\\
 Веб сервер должен быть собран  с поддержкой ''mod_rewrite''\\

  # ./configure --prefix=/usr/local/apache --enable-rewrite=shared
  # make
  # make install

Вносим в конфигурационый файл следующие опции **httpd.conf**.

  #Abills version 0.3
  # User interface
  Alias /abills "/usr/abills/cgi-bin/"
  <Directory "/usr/abills/cgi-bin">
     <IfModule mod_rewrite.c>
        RewriteEngine on
        RewriteCond %{HTTP:Authorization} ^(.*)
        RewriteRule ^(.*) - [E=HTTP_CGI_AUTHORIZATION:%1]
        Options Indexes ExecCGI SymLinksIfOwnerMatch
     </IfModule>
    AddHandler cgi-script .cgi
    Options Indexes ExecCGI FollowSymLinks
    AllowOverride none
    DirectoryIndex index.cgi
    Order allow,deny
    Allow from all
  
    <Files ~ "\.(db|log)$">
      Order allow,deny
      Deny from all
    </Files>
  </Directory>
  
  
  #Admin interface
  <Directory "/usr/abills/cgi-bin/admin">
    AddHandler cgi-script .cgi
    Options Indexes ExecCGI FollowSymLinks
    AllowOverride none
    DirectoryIndex index.cgi
    order deny,allow
    allow from all
  </Directory>






=====Perl modules=====
Для работы системы нужны модули.\\

| **DBI**        |                           |
| **DBD-mysql** |                           |
| **Digest-MD5** | для Chap авторизации      |
| **Digest-MD4** | для MS-Chap авторизации   |
| **Crypt-DES**  | для MS-Chap авторизации   |
| **Digest-SHA1**| для MS-ChapV2 авторизации |
| **libnet**     | Нужен только при авторизации из UNIX passwd |
| **Time-HiRes** | Нужен только для тестирования скорости выполнения авторизациИ, аккаунтинга, и страниц веб-интерфейса |

Эти модули можно загрузить с сайта [http://www.cpan.org] или установка с консоли.

  # cd /root 
  # perl -MCPAN -e shell 
  o conf prerequisites_policy ask 
  install    DBI      
  install    DBD::mysql    
  install    Digest::MD5 
  install    Digest::MD4 
  install    Crypt::DES 
  install    Digest::SHA1 
  install    Bundle::libnet 
  install    Time::HiRes 
  quit 
















=====ABillS=====
Загрузить пакет можно по адресу [http://sourceforge.net/projects/abills/]\\

  # tar zxvf abills-0.3x.tgz
  # cp -Rf abills /usr/
  # cp /usr/abills/libexec/config.pl.default /usr/abills/libexec/config.pl

Правим конфигурационный файл системы\\
**/usr/abills/libexec/config.pl** \\

\\
  #DB configuration 
  $conf{dbhost}='localhost';
  $conf{dbname}='abills'; 
  $conf{dblogin}='abills';
  $conf{dbpasswd}='sqlpassword'; 
  $conf{ADMIN_MAIL}='info@your.domain'; 
  $conf{USERS_MAIL_DOMAIN}="your.domain";
  # используется для шифрования паролей администраторов и пользователей.
  $conf{secretkey}="test12345678901234567890"; 
\\

**При изменении значения в $conf{secretkey} поменяйте его также в файле abills.sql **

Вносим в ''cron'' периодические процессы
**/etc/crontab**

 */5  *      *    *     *   root   /usr/abills/libexec/billd -all\\
 1     0     *    *     *   root    /usr/abills/libexec/periodic daily\\
 1     0     *    *     *   root    /usr/abills/libexec/periodic monthly\\

\\

Установить права на чтение и запись вебсервером для файлов веб интерфейса \\

  # chown -Rf www /usr/abills/cgi-bin
  # chown -Rf www /usr/abills/Abills/templates
  # chown -Rf www /usr/abills/backup
  
Открываем веб интерфейс http://your.host/abills/admin/


Логин администратора по умолчанию **abills** пароль **abills**\\


Прежде всего надо сконфигурировать сервера доступа NAS (Network Access Server). \\
Переходим в меню\\
**System configuration->NAS**\\

**Параметры**
^ IP                     | IP адрес NAS сервера                        |
^ Name                   | Название                                    |
^ Radius NAS-Identifier  | Идентификатор сервера (можно не вписывать) |
^ Describe               | Описание сервера                            |
^ Type                   | Тип сервера.  В зависимости от типа по разному обрабатываются запросЫ на авторизацию |
^ Authorization          | Тип авторизации. \\ **SYSTEM** - При хранении паролей в UNIX базе (/etc/passwd)\\ **SQL** - при хранении паролей SQL базе (MySQL, PosgreSQL)\\  |
^ Alive                  | Период отправки Alive пакетов               |
^ Disable                | Отключить                                   |
^ :Manage:               | Секция менеджмента NAS сервера              |
^ IP:PORT                  | IP адрес и порт для контроля соединения. Например, для отключения пользователя из веб-интерфейса |
^ User                   | Пользователь для контроля                   |
^ Password               | Пароль                                      |
^ RADIUS Parameters      | Дополнительные параметры которые передаются NAS серверу после успешной авторизации.|


После заведения сервера доступа добавте ему пул адресов **IP POOLs**.
^ FIRST IP | Первый адрес в пуле|
^ COUNT    | Количество адресов |
Одному серверу доступа может принадлежать несколько пулов адресов.



Создание тарифного плана\\
Меню\\
**System configuration->Dialup & VPN->Tarif Plans**\\


Регистрация пользователя\\
**Customers->Users->Add**\\


Заведение сервиса Dialup/VPN на пользователя.\\
**Customers->Users->Information->Services->Dialup / VPN**\\



**Проверяем**\\
  # radtest testuser testpassword 127.0.0.1:1812 0 radsecret 0 127.0.0.1

Если всё правильно настроено, в файле логов **/usr/abills/var/log/abills.log** должна появиться строка \\

  2005-02-23 12:55:55 LOG_INFO: AUTH [testuser] NAS: 1 (xxx.xxx.xxx.xxx) GT: 0.03799



