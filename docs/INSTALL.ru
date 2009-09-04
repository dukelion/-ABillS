=====Установка и предварительная настройка=====
  * Для установки серверной части системы требуется любая ОС семейства Unix (FreeBSD,Linux,Solaris).\\
  * Для работы администратора и пользователей с биллингом подойдёт любая система, имеющая современный WEB-браузер. Для работы с серверной частью системы не потребуется никаких дополнительных настроек на ПК администратора или клиентов.

=====Требование к ресурсам системы для установки серверной части=====

Оптимальная конфигурация системы для работы с серверной частью в первую очередь зависит от ширины обслуживаемого биллингом канала и количества одновременно  работающих пользователей, а также от спектра предоставляемых услуг провайдером. \\
Рекомендованная конфигурация при 250 активных пользователях и 40 мб/сек канале при размещении сервера билинга и сервера доступа на одном физическом сервере:
  * Процессор на базе Intel x86 или другой совместимый с тактовой частотой 2 Ггц и выше.
  * Оперативной памяти не менее 1 Гб
  * Жёсткий диск для хранения автоматических бекапов системы не менее 100 гб.
=====Замечания по установкe операционной системы.=====
===FreeBSD===
  * При разбиении диска на разделы крайне рекомендуется отвести для раздела **/var** не менее 10 Гигабайт. Если планируется высокая нагрузка, это значение можно увеличить.
  * Рекомендованный дистрибютивный набор (Distribution Set) - **6 Kernel-Developer **
  * Более подробно об установке читайте тут [[http://www.asmodeus.com.ua/library/os/freebsd/handbook/|FreeBSD Handbook]]
  * [[http://www.seteved.ru/index.php?option=com_content&task=view&id=180&Itemid=29|Установка FreeBSD 7 в картинках, для начинающих]]

===Linux===

=====Radius=====
Загрузить пакет FreeRadius можно по адресу [http://www.freeradius.org]

  # tar zxvf freeradius-1.1.0.tar.gz
  # cd freeradius-1.1.0
  # ./configure --prefix=/usr/local/radiusd/
  # make
  # make install

====Версия 1.хх====
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
  client 127.0.0.1 {
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

====Версия 2.xx====

в **raddb/radiusd.conf** в секции ''modules'' описываем секции:

  abills_preauth 
  exec abills_preauth { 
    program = "/usr/abills/libexec/rauth.pl pre_auth" 
    wait = yes 
    input_pairs = request 
    shell_escape = yes 
    #output = no 
    output_pairs = config 
  } 
  
  abills_postauth 
  exec abills_postauth { 
    program = "/usr/abills/libexec/rauth.pl post_auth" 
    wait = yes 
    input_pairs = request 
    shell_escape = yes 
    #output = no 
    output_pairs = config 
  } 
  
  abills_auth 
  exec abills_auth { 
    program = "/usr/abills/libexec/rauth.pl" 
    wait = yes 
    input_pairs = request 
    shell_escape = yes 
    output = no 
    output_pairs = reply 
   } 
  
  abills_acc 
    exec abills_acc { 
    program = "/usr/abills/libexec/racct.pl" 
    wait = yes 
    input_pairs = request 
    shell_escape = yes 
    output = no 
    output_pairs = reply 
  }

 в секции ''exec''\\
 Код:


  exec {                                                       
     wait = yes                                           
     input_pairs = request                                 
     shell_escape = yes                                   
     output = none                                         
     output_pairs = reply                                 
  }

Файл raddb/sytes-inable/default - правим секции authorize, preacct, post-auth. Остальное в этих секциях ремарим. \\

Код:

  authorize { 
    preprocess 
    abills_preauth 
    mschap 
    files 
    abills_auth 
   } 
   
  preacct { 
    preprocess 
    abills_acc 
   } 
  
  post-auth { 
    Post-Auth-Type REJECT { 
       abills_postauth 
     } 
  } 

в **raddb/users** \\
Код:

  DEFAULT Auth-Type = Accept













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
 Веб-сервер должен быть собран  с поддержкой ''mod_rewrite''\\

  # ./configure --prefix=/usr/local/apache --enable-rewrite=shared
  # make
  # make install

Если нужно шифрование трафика для веб-интерфейса, тогда создаём сертификаты. Apache должен быть собран с mod_ssl.

  # /usr/abills/misc/sslcerts.sh apache

Вносим в конфигурационый файл следующие опции **httpd.conf**.

  #Abills version 0.5
  Listen 9443
  <VirtualHost _default_:9443>
  
    DocumentRoot "/usr/abills/cgi-bin"
    #ServerName www.example.com:9443
    #ServerAdmin admin@example.com
    ErrorLog /var/log/httpd/abills-error.log
    #TransferLog /var/log/httpd/abills-access.log
    CustomLog /var/log/httpd/abills-access_log common
   
    <IfModule ssl_module>
      #   SSL Engine Switch:
      #   Enable/Disable SSL for this virtual host.
      SSLEngine on
      SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
      SSLCertificateFile /usr/abills/Certs/server.crt
      SSLCertificateKeyFile /usr/abills/Certs/server.key
      <FilesMatch "\.(cgi)$">
        SSLOptions +StdEnvVars
      </FilesMatch>
      BrowserMatch ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
  
      CustomLog /var/log/abills-ssl_request.log \
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    </IfModule>
  
  
  # User interface
    <Directory "/usr/abills/cgi-bin">
      <IfModule ssl_module>
        SSLOptions +StdEnvVars
      </IfModule>
  
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
    
    #For hotspot solution
    #ErrorDocument 404 "/abills/"
    #directoryIndex "/abills" index.cgi
   </Directory>
  
   #Admin interface
   <Directory "/usr/abills/cgi-bin/admin">
     <IfModule ssl_module>
       SSLOptions +StdEnvVars
     </IfModule>
  
     AddHandler cgi-script .cgi
     Options Indexes ExecCGI FollowSymLinks
     AllowOverride none
     DirectoryIndex index.cgi
     order deny,allow
     allow from all
   </Directory>
  
  </VirtualHost>


Или включаем ** abills/misc/apache/abills_httpd.conf ** в конфигурационный файл apache

  Include /usr/abills/misc/apache/abills_httpd.conf

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
  $conf{dbuser}='abills';
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
 1     1     *    *     *   root    /usr/abills/libexec/periodic monthly\\

\\

Установить права на чтение и запись вебсервером для файлов веб интерфейса \\

  # chown -Rf www /usr/abills/cgi-bin
  # chown -Rf www /usr/abills/Abills/templates
  # chown -Rf www /usr/abills/backup
  
Веб интерфейс администратора:\\
**https://your.host:9443/admin/**\\
\\
Логин администратора по умолчанию **abills** пароль **abills**\\

Веб интерфейс для пользователей:\\
**https://your.host:9443/**\\
\\



В интерфейсе администратора прежде всего надо сконфигурировать сервера доступа NAS (Network Access Server). \\
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

