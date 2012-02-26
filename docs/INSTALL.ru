<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ru"
 lang="ru" dir="ltr">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta name="Author" content="~AsmodeuS~">
  <meta name="description" content="ABillS - AsmodeuS Billing system / Cisco PPPoE PPTP PPPD livingston Lucent VPN CaTV Hotspot VOiP Mail Postfix Linux FreeBSD">
  <meta name="keywords" content="Billing dialup pppoe pptp cisco lucent ppp livingston portmaster homonet radius vpn catv hotspot linux freebsd voip asmodeus">


  <title>
    abills:docs_03:install:ru    [ABillS]
  </title>

  <meta name="generator" content="DokuWiki"/>
<meta name="robots" content="noindex,follow"/>
<meta name="date" content="1970-01-01T03:00:00+0300"/>
<meta name="keywords" content="abills,docs_03,install,ru"/>
<link rel="search" type="application/opensearchdescription+xml" href="/wiki/lib/exe/opensearch.php" title="ABillS"/>
<link rel="start" href="/wiki/"/>
<link rel="contents" href="/wiki/doku.php/abills:docs_03:install:ru?do=index" title="Все страницы"/>
<link rel="alternate" type="application/rss+xml" title="Recent Changes" href="/wiki/feed.php"/>
<link rel="alternate" type="application/rss+xml" title="Current Namespace" href="/wiki/feed.php?mode=list&amp;ns=abills:docs_03:install"/>
<link rel="alternate" type="text/html" title="Plain HTML" href="/wiki/doku.php/abills:docs_03:install:ru?do=export_xhtml"/>
<link rel="alternate" type="text/plain" title="Wiki Markup" href="/wiki/doku.php/abills:docs_03:install:ru?do=export_raw"/>
<link rel="stylesheet" media="screen" type="text/css" href="/wiki/lib/exe/css.php?t=sidebar&amp;tseed=1327656554"/>
<link rel="stylesheet" media="all" type="text/css" href="/wiki/lib/exe/css.php?s=all&amp;t=sidebar&amp;tseed=1327656554"/>
<link rel="stylesheet" media="print" type="text/css" href="/wiki/lib/exe/css.php?s=print&amp;t=sidebar&amp;tseed=1327656554"/>
<script type="text/javascript"><!--//--><![CDATA[//><!--
var NS='abills:docs_03:install';var JSINFO = {"id":"abills:docs_03:install:ru","namespace":"abills:docs_03:install"};
//--><!]]></script>
<script type="text/javascript" charset="utf-8" src="/wiki/lib/exe/js.php?tseed=1327656554"></script>

  <link rel="shortcut icon" href="/wiki/lib/tpl/sidebar/images/favicon.ico" />

  </head>

<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("UA-15229262-1");
pageTracker._trackPageview();
} catch(err) {}</script>

<body class='sidebar_inside_left'>
<div class="dokuwiki">
  
  <div class="stylehead">

    <div class="header">
      <div class="pagename">
        [[<a href="/wiki/doku.php/abills:docs_03:install:ru?do=backlink" >abills:docs_03:install:ru</a>]]
      </div>
      <div class="logo">
        <a href="/wiki/doku.php/"  name="dokuwiki__top" id="dokuwiki__top" accesskey="h" title="[ALT+H]"><img src=http://abills.net.ua/img/abills_logo.gif></a>      </div>

      <div class="clearer"></div>
    </div>

    
    <div class="bar" id="bar__top">
      <div class="bar-left" id="bar__topleft">
        <form class="button btn_source" method="post" action="/wiki/doku.php/abills:docs_03:install:ru"><div class="no"><input type="hidden" name="do" value="edit" /><input type="hidden" name="rev" value="" /><input type="submit" value="Показать исходный текст" class="button" accesskey="v" title="Показать исходный текст [V]" /></div></form>        <form class="button btn_revs" method="get" action="/wiki/doku.php/abills:docs_03:install:ru"><div class="no"><input type="hidden" name="do" value="revisions" /><input type="submit" value="История страницы" class="button" accesskey="o" title="История страницы [O]" /></div></form>
<form class="button" method="get" action="">
  <div class="no">
    <button type="submit" class="button">
      <img src="/wiki/lib/images/fileicons/pdf.png" alt="PDF Export" />
      Export to PDF
    </button>
    <input type="hidden" name="do" value="export_pdf" />
    <input type="hidden" name="id" value="abills:docs_03:install:ru" />
  </div>
</form>

      </div>

      <div class="bar-right" id="bar__topright">
        <form class="button btn_recent" method="get" action="/wiki/doku.php/abills:docs_03:install:ru"><div class="no"><input type="hidden" name="do" value="recent" /><input type="submit" value="Недавние изменения" class="button" accesskey="r" title="Недавние изменения [R]" /></div></form>        <form action="/wiki/doku.php/" accept-charset="utf-8" class="search" id="dw__search" method="get"><div class="no"><input type="hidden" name="do" value="search" /><input type="text" id="qsearch__in" accesskey="f" name="id" class="edit" title="[F]" /><input type="submit" value="Поиск" class="button" title="Поиск" /><div id="qsearch__out" class="ajax_qsearch JSpopup"></div></div></form>&nbsp;
      </div>

      <div class="clearer"></div>
    </div>

        <div class="breadcrumbs">
      <span class="bchead">Вы посетили:</span>          </div>
    
    
  </div>
    
  <div class="page">
    <!-- wikipage start -->
    <div class="plugin_translation"><span>Translations of this page:</span> <ul>  <li><div class="li"><span class="curid"><a href="/wiki/doku.php/abills:docs_03:install:ru" class="wikilink2" title="abills:docs_03:install:ru" rel="nofollow">ru</a></span></div></li>  <li><div class="li"><a href="/wiki/doku.php/en:abills:docs_03:install:ru" class="wikilink1" title="en:abills:docs_03:install:ru">en</a></div></li>  <li><div class="li"><a href="/wiki/doku.php/ua:abills:docs_03:install:ru" class="wikilink2" title="ua:abills:docs_03:install:ru" rel="nofollow">ua</a></div></li></ul></div>
<h1 class="sectionedit1"><a name="ehta_stranica_eschjo_ne_suschestvuet" id="ehta_stranica_eschjo_ne_suschestvuet">Эта страница ещё не существует</a></h1>
<div class="level1">

<p>
Вы перешли по ссылке на тему, для которой ещё не создана страница. Если позволяют ваши права доступа, вы можете создать её, нажав на кнопку «Создать страницу».
</p>

</div>

    <!-- wikipage stop -->
  </div>
  <div id="sidebar">
    <div id="sidebartop"></div>
    <div id="sidebar_content">
      
<h1 class="sectionedit1"><a name="documentation_index" id="documentation_index">Documentation index</a></h1>
<div class="level1">
<ul>
<li class="level1"><div class="li"> <a href="/wiki/doku.php/abills:index" class="wikilink1" title="abills:index">ABillS - Описание</a></div>
<ul>
<li class="level2"><div class="li"> <a href="/wiki/doku.php/abills:docs:screenshots:screeshots" class="wikilink1" title="abills:docs:screenshots:screeshots">Screeshots</a></div>
</li>
<li class="level2"><div class="li"> <a href="/wiki/doku.php/abills:docs:features:ru" class="wikilink1" title="abills:docs:features:ru">Возможности</a></div>
</li>
</ul>
</li>
<li class="level1"><div class="li"> Установка</div>
<ul>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:docs:manual:install:ru" class="wikilink1" title="abills:docs:manual:install:ru">Установка Универсальная</a></div>
</li>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:docs:manual:install_freebsd:ru" class="wikilink1" title="abills:docs:manual:install_freebsd:ru">FreeBSD</a></div>
</li>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:docs:manual:install_ubuntu:ru" class="wikilink1" title="abills:docs:manual:install_ubuntu:ru">Ubuntu</a></div>
</li>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:docs:manual:install_debian:ru" class="wikilink1" title="abills:docs:manual:install_debian:ru">Debian</a></div>
</li>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:docs:ipv6:ru" class="wikilink1" title="abills:docs:ipv6:ru">IPv6</a></div>
</li>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:docs:other:migration:ru" class="wikilink1" title="abills:docs:other:migration:ru">Миграция</a></div>
</li>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:docs:other:ru" class="wikilink1" title="abills:docs:other:ru">Дополнительно</a></div>
</li>
</ul>
</li>
<li class="level1"><div class="li"> Modules</div>
<ul>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:abon:ru" class="wikilink1" title="abills:docs:abon:ru">Abon</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:ashield:ru" class="wikilink1" title="abills:docs:modules:ashield:ru">Ashield</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:bonus:ru" class="wikilink1" title="abills:docs:modules:bonus:ru">Bonus</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:bsr1000:ru" class="wikilink1" title="abills:docs:bsr1000:ru">BSR1000</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:cards:ru" class="wikilink1" title="abills:docs:modules:cards:ru">Cards</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:dv:ru" class="wikilink1" title="abills:docs:modules:dv:ru">Dv</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:dhcphosts:ru" class="wikilink1" title="abills:docs:modules:dhcphosts:ru">Dhcphosts</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:docs:ru" class="wikilink1" title="abills:docs:docs:ru">Docs</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:dunes:ru" class="wikilink1" title="abills:docs:dunes:ru">Dunes</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:extfin:ru" class="wikilink1" title="abills:docs:modules:extfin:ru">Extfin</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:ipn:ru" class="wikilink1" title="abills:docs:modules:ipn:ru">Ipn</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:iptv:ru" class="wikilink1" title="abills:docs:modules:iptv:ru">Iptv</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:vlan:ru" class="wikilink1" title="abills:docs:modules:vlan:ru">Vlan</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:mail:ru" class="wikilink1" title="abills:docs:modules:mail:ru">Mail</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:maps:ru" class="wikilink1" title="abills:docs:modules:maps:ru">Maps</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:marketing:ru" class="wikilink1" title="abills:docs:modules:marketing:ru">Marketing</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:mdelivery:ru" class="wikilink1" title="abills:docs:mdelivery:ru">Mdelivery</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:msgs:ru" class="wikilink1" title="abills:docs:msgs:ru">Msgs</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:multidoms:ru:abills" class="wikilink1" title="abills:docs:modules:multidoms:ru:abills">Multidoms</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:paysys:ru" class="wikilink1" title="abills:docs:modules:paysys:ru">Paysys</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:portal:ru" class="wikilink1" title="abills:docs:modules:portal:ru">Portal</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:netlist:ru" class="wikilink1" title="abills:docs:netlist:ru">Netlist</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:voip:ru" class="wikilink1" title="abills:docs:voip:ru">Voip</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:sharing:ru" class="wikilink1" title="abills:docs:modules:sharing:ru">Sharing</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:snmputils:ru" class="wikilink1" title="abills:docs:modules:snmputils:ru">Snmputils</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:sms:ru" class="wikilink1" title="abills:docs:modules:sms:ru">Sms</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:modules:storage:ru" class="wikilink1" title="abills:docs:modules:storage:ru">Storage</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:sqlcmd:ru" class="wikilink1" title="abills:docs:sqlcmd:ru">Sqlcmd</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:squid:ru" class="wikilink1" title="abills:docs:squid:ru">Squid</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:ureports:ru" class="wikilink1" title="abills:docs:ureports:ru">Ureports</a></div>
</li>
</ul>
</li>
<li class="level1"><div class="li"> Конфигурация</div>
<ul>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:mschap_mppe:ru" class="wikilink1" title="abills:docs:mschap_mppe:ru">MS-CHAP &amp; MPPE</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:802.1x:ru" class="wikilink1" title="abills:docs:802.1x:ru">IEEE 802.1x</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:rlm_perl:ru" class="wikilink1" title="abills:docs:rlm_perl:ru">rlm_perl</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:ipsec:ru" class="wikilink1" title="abills:docs:ipsec:ru">IPSec</a></div>
</li>
</ul>
</li>
<li class="level1"><div class="li"> Frequently Asked Questions</div>
<ul>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:faq:ru" class="wikilink1" title="abills:docs:faq:ru">Russian</a></div>
</li>
</ul>
</li>
<li class="level1"><div class="li"> Misc</div>
<ul>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:abm:ru" class="wikilink1" title="abills:docs:abm:ru">ABM</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:amon:ru" class="wikilink1" title="abills:docs:amon:ru">Amon</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:mrtg:ru" class="wikilink1" title="abills:docs:mrtg:ru">MRTG</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:graphics.cgi:ru:abills" class="wikilink1" title="abills:docs:graphics.cgi:ru:abills">graphics.cgi</a></div>
</li>
</ul>
</li>
<li class="level1"><div class="li"> NAS Configuration</div>
<ul>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:asterisk" class="wikilink1" title="abills:docs:asterisk">Asterisk</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:exppp:ru" class="wikilink1" title="abills:docs:exppp:ru">Exppp</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:mpd:ru" class="wikilink1" title="abills:docs:mpd:ru">MPD</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:portmaste:ru" class="wikilink1" title="abills:docs:portmaste:ru">Livingston Portmaster 2/3</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:radpppd:en" class="wikilink1" title="abills:docs:radpppd:en">radpppd</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:chillispot:ru" class="wikilink1" title="abills:docs:chillispot:ru">Сhillispot</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:cisco_2511:ru" class="wikilink1" title="abills:docs:cisco_2511:ru">Сisco</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:gnugk:ru" class="wikilink1" title="abills:docs:gnugk:ru">GNUgk</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:mikrotik:ru" class="wikilink1" title="abills:docs:mikrotik:ru">Mikrotik</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:3com_5232:ru" class="wikilink1" title="abills:docs:3com_5232:ru">3Com 5232</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:linux:lepppd:ru" class="wikilink1" title="abills:docs:linux:lepppd:ru">Linux PPPD IPv4 zone counters</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:linux:pppd_radattr:ru" class="wikilink1" title="abills:docs:linux:pppd_radattr:ru">Linux PPPD + radattr.so</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:linux:accel_pptp:ru" class="wikilink1" title="abills:docs:linux:accel_pptp:ru">Linux accel-pptp</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:linux:radcoad:ru" class="wikilink1" title="abills:docs:linux:radcoad:ru">Linux PPPD + radcoad</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:vyatta:vyatta:ru" class="wikilink1" title="abills:docs:vyatta:vyatta:ru">Vyatta</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:lucent_max_tnt:ru" class="wikilink1" title="abills:docs:lucent_max_tnt:ru">Lucent MAX TNT</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:usr_netserver:ru" class="wikilink1" title="abills:docs:usr_netserver:ru">USR Netserver 8/16</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:nas:patton:ru" class="wikilink1" title="abills:docs:nas:patton:ru">Patton</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:nas:openvpn:ru:openvpn" class="wikilink1" title="abills:docs:nas:openvpn:ru:openvpn">OpenVPN</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:nas:juniper:ru:juniper" class="wikilink1" title="abills:docs:nas:juniper:ru:juniper">Juniper</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:nas:ericsson_smartedge:ru:ericsson_smartedge" class="wikilink1" title="abills:docs:nas:ericsson_smartedge:ru:ericsson_smartedge">Ericsson SmartEdge</a></div>
</li>
</ul>
</li>
<li class="level1"><div class="li"> Development</div>
<ul>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:development:nas_integration:ru" class="wikilink1" title="abills:docs:development:nas_integration:ru">NAS Integration</a></div>
</li>
<li class="level4"><div class="li"> <a href="/wiki/doku.php/abills:docs:development:modules:ru" class="wikilink1" title="abills:docs:development:modules:ru">Модули</a></div>
</li>
</ul>
</li>
<li class="level1"><div class="li"> <a href="/wiki/doku.php/abills:docs:download:download" class="wikilink1" title="abills:docs:download:download">Скачать</a></div>
</li>
</ul>
<ul>
<li class="level1"><div class="li"> ChangeLogs</div>
<ul>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:changelogs:0.5x" class="wikilink1" title="abills:changelogs:0.5x">0.5x</a></div>
</li>
<li class="level3"><div class="li"> <a href="/wiki/doku.php/abills:changelogs:0.4x" class="wikilink1" title="abills:changelogs:0.4x">Old</a></div>
</li>
</ul>
</li>
<li class="level2"><div class="li"> <a href="/wiki/doku.php/abills:todo:todo" class="wikilink1" title="abills:todo:todo">todo</a></div>
</li>
<li class="level2"><div class="li"> <a href="/wiki/doku.php/abills:price:price" class="wikilink1" title="abills:price:price">Price</a></div>
</li>
<li class="level2"><div class="li"> <a href="/wiki/doku.php/abills:demo:demo" class="wikilink1" title="abills:demo:demo">demo</a></div>
</li>
<li class="level2"><div class="li"> <a href="http://abills.net.ua/forum/" class="urlextern" title="http://abills.net.ua/forum/"  rel="nofollow">Forum</a></div>
</li>
<li class="level2"><div class="li"> <a href="/wiki/doku.php/abills:customers:customers" class="wikilink1" title="abills:customers:customers">Customers</a></div>
</li>
<li class="level2"><div class="li"> <a href="/wiki/doku.php/abills:contact:contact" class="wikilink1" title="abills:contact:contact">Contact</a></div>
</li>
</ul>

</div>
<!-- EDIT1 SECTION "Documentation index" [2-] -->    </div>
  </div>

  <div class="clearer">&nbsp;</div>

  
  <div class="stylefoot">

    <div class="meta">
      <div class="user">
              </div>
      <div class="doc">
              </div>
    </div>

   
    <div class="bar" id="bar__bottom">
      <div class="bar-left" id="bar__bottomleft">
        <form class="button btn_source" method="post" action="/wiki/doku.php/abills:docs_03:install:ru"><div class="no"><input type="hidden" name="do" value="edit" /><input type="hidden" name="rev" value="" /><input type="submit" value="Показать исходный текст" class="button" accesskey="v" title="Показать исходный текст [V]" /></div></form>        <form class="button btn_revs" method="get" action="/wiki/doku.php/abills:docs_03:install:ru"><div class="no"><input type="hidden" name="do" value="revisions" /><input type="submit" value="История страницы" class="button" accesskey="o" title="История страницы [O]" /></div></form>      </div>
      <div class="bar-right" id="bar__bottomright">
                                <form class="button btn_login" method="get" action="/wiki/doku.php/abills:docs_03:install:ru"><div class="no"><input type="hidden" name="do" value="login" /><input type="hidden" name="sectok" value="ceab8f3ca4f9b89edccd7e1581f3bc71" /><input type="submit" value="Войти" class="button" title="Войти" /></div></form>        <form class="button btn_index" method="get" action="/wiki/doku.php/abills:docs_03:install:ru"><div class="no"><input type="hidden" name="do" value="index" /><input type="submit" value="Все страницы" class="button" accesskey="x" title="Все страницы [X]" /></div></form>        <a class="nolink" href="#dokuwiki__top"><input type="button" class="button" value="Наверх" onclick="window.scrollTo(0, 0)" title="Наверх" /></a>&nbsp;
      </div>
      <div class="clearer"></div>
    </div>

  </div>

</div>

<div class="footerinc">
  <a  href="/wiki/feed.php" title="Recent changes RSS feed"><img src="/wiki/lib/tpl/sidebar/images/button-rss.png" width="80" height="15" alt="Recent changes RSS feed" /></a>

  <a  href="http://creativecommons.org/licenses/by-nc-sa/2.0/" rel="license" title="Creative Commons License"><img src="/wiki/lib/tpl/sidebar/images/button-cc.gif" width="80" height="15" alt="Creative Commons License" /></a>

  <a  href="https://www.paypal.com/xclick/business=andi%40splitbrain.org&amp;item_name=DokuWiki+Donation&amp;no_shipping=1&amp;no_note=1&amp;tax=0&amp;currency_code=EUR&amp;lc=US" title="Donate"><img src="/wiki/lib/tpl/sidebar/images/button-donate.gif" alt="Donate" width="80" height="15" /></a>

  <a  href="http://www.php.net" title="Powered by PHP"><img src="/wiki/lib/tpl/sidebar/images/button-php.gif" width="80" height="15" alt="Powered by PHP" /></a>

  <a  href="http://validator.w3.org/check/referer" title="Valid XHTML 1.0"><img src="/wiki/lib/tpl/sidebar/images/button-xhtml.png" width="80" height="15" alt="Valid XHTML 1.0" /></a>

  <a  href="http://jigsaw.w3.org/css-validator/check/referer" title="Valid CSS"><img src="/wiki/lib/tpl/sidebar/images/button-css.png" width="80" height="15" alt="Valid CSS" /></a>

  <a  href="http://wiki.splitbrain.org/wiki:dokuwiki" title="Driven by DokuWiki"><img src="/wiki/lib/tpl/sidebar/images/button-dw.png" width="80" height="15" alt="Driven by DokuWiki" /></a>



<!--

<rdf:RDF xmlns="http://web.resource.org/cc/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<Work rdf:about="">
   <dc:type rdf:resource="http://purl.org/dc/dcmitype/Text" />
   <license rdf:resource="http://creativecommons.org/licenses/by-nc-sa/2.0/" />
</Work>

<License rdf:about="http://creativecommons.org/licenses/by-nc-sa/2.0/">
   <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
   <permits rdf:resource="http://web.resource.org/cc/Distribution" />
   <requires rdf:resource="http://web.resource.org/cc/Notice" />
   <requires rdf:resource="http://web.resource.org/cc/Attribution" />
   <prohibits rdf:resource="http://web.resource.org/cc/CommercialUse" />
   <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
   <requires rdf:resource="http://web.resource.org/cc/ShareAlike" />
</License>

</rdf:RDF>

-->


<SCRIPT language="JavaScript">
//<!--
var id='336';
var img='nabat1';
var j=0;
var an=navigator.appName; 
var d=document; c=''; je='';
var script='http://www.nabat.com.ua/cgi-bin/counter/hellping.cgi';
//-->

</SCRIPT>
<SCRIPT language="javascript1.1"><!--
j=1//--></SCRIPT><SCRIPT language="JavaScript1.2"><!--
j=2//--></SCRIPT><SCRIPT language="JavaScript1.3"><!--
j=3//--></SCRIPT>

<SCRIPT language="JavaScript">
<!--
d.cookie="v=1;path=/";
s=screen;
an!="Netscape"?c=s.colorDepth:c=s.pixelDepth;
r=escape(d.referrer);

d.write('<a href="http://nabat.com.ua/"><img alt=nabat border=0 width=88 height=15 src="'+script+'?id='+id+'&img='+img+((typeof(s)=='undefined')?'':'&res='+s.width+'&c='+c) +
 '&from='+r+'&pg='+escape(window.location.href)+(d.cookie?'&ce=1':'')+
 '&j='+j+(navigator.javaEnabled()?'&je=1':'')+'"></a>');
//-->

</SCRIPT>
<noscript>
<a href="http://www.nabat.com.ua"><img src='http://www.nabat.com.ua/cgi-bin/counter/hellping.cgi?336+nabat1' width=88 height=31 border=0 alt="Nabat"></a>
</noscript>
<!-- END Nabat Rate -->
</div>

<div class="no"></div>
</body>
</html>
