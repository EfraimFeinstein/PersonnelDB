xquery version "3.0";
(: site.xqm
 : Copyright 2010-2012 Efraim Feinstein
 : Licensed under the GNU Lesser General Public License, version 3 or later
 : 
 :)
module namespace site="http://stsf.net/xquery/site";

import module namespace prs="http://stsf.net/xquery/personnel"
  at "personnel.xqm";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace ev="http://www.w3.org/2001/xml-events";
declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace html="http://www.w3.org/1999/xhtml"; 

declare variable $site:xslt-pi := 
  ( 
    processing-instruction xml-stylesheet {
      'type="text/xsl" href="/exist/apps/xforms/xsltforms.xsl"'
    },
    processing-instruction css-conversion {'no'}
  );
(:~ when to debug: when not on the primary server :)
declare variable $site:debug-pi := 
  if (request:exists() and not(request:get-server-name()='localhost')) 
  then ()
  else processing-instruction xsltforms-options {'debug="yes"'};

(:~ write a form
 :
 : @param $model the XForms model 
 : @param $head-content the content of the page under the head element
 : @param $body-content the content of the page under the body element 
 :)
declare function site:form(
	$model as element(xf:model)?,
	$head-content as element()+,
	$body-content as element()+
	) as node()+ {
	site:form($model, $head-content, $body-content, 
		site:css(), site:header(), site:sidebar(), site:footer())
};

(:~ write a form with custom CSS link or style element
 : Use site:css() to get the default value
 :)
declare function site:form(
	$model as element(xf:model)?,
	$head-content as element()+,
	$body-content as element()+,
	$css as element()*
	) as node()+ {
	site:form($model, $head-content, $body-content, $css,
		site:header(), site:sidebar(), site:footer())
};

(:~ form with defaulted app-header :)
declare function site:form(
	$model as element(xf:model)?,
	$head-content as element()+,
	$body-content as element()+,
	$css as element()*,
	$header as element()*,
	$sidebar as element()*,
	$footer as element()*) 
	as node()+ {
	site:form($model, $head-content, $body-content, $css, $header, $sidebar, $footer,
		site:app-header())
};


(:~ write a form, long version that allows custom CSS, header, sidebar, footer, application header :)
declare function site:form(
	$model as element(xf:model)?,
	$head-content as element()+,
	$body-content as element()+,
	$css as element()*,
	$header as element()*,
	$sidebar as element()*,
	$footer as element()*,
	$app-header as element()*) 
	as node()+ {
	(
	util:declare-option("exist:serialize", 
    "method=xhtml omit-xml-declaration=no indent=yes media-type=application/xhtml+xml"
  ),
	$site:xslt-pi, $site:debug-pi,
	<html	
	  xmlns:p="http://stsf.net/personnel/players"
	  xmlns:s="http://stsf.net/personnel/ships">
		<head>
			{
			$css,
			$head-content,
      (: favicon :)
      <link rel="shortcut icon" href="/personnel/resources/favicon.ico"/>,
			$model
			}
		</head>
		<body>
      <div id="allContent">
        <div id="header">{
          $header
        }</div>
        <div id="sidebar">{
          $sidebar
        }</div>
        {
        	if (exists($app-header))
        	then
        		<div id="appHeader">{
        			$app-header
        		}</div>
        	else ()
        }
        <div id="mainContent">{
          $body-content 
        }</div>
        <div id="footer">{
          $footer 
        }</div>
      </div>
		</body>
	</html>
	)
};

(:~ site wide styling pointers (link, style) :)
declare function site:css() 
	as element()* {
	<link type="text/css" rel="stylesheet" 
	  href="/personnel/resources/site.css"/>
};

(:~ site-wide header :)
declare function site:header() 
	as element()* {
	(
	<h1>STSF Personnel Database</h1>
	)
};

(:~ show sidebar logo :)
declare function site:_sidebar-logo(
	) as element()+ {
	<div id="logo-div">
		<img id="logo" src="/resources/stsf.png" alt="STSF Logo"/>
	</div>
}; 

(:~ site-wide sidebar :)
declare function site:sidebar() 
	as element()* {
  site:_sidebar-logo(),
  let $logged-in := session:get-attribute("authenticated")
  let $member-number := session:get-attribute("member-number")
  return (
    <nav>
      { 
        if ($logged-in)
        then (
          <a href="logout">Log out {$logged-in}</a>,
          <a href="players?player-id={$member-number}">My characters</a>
        )
        else
          <a href="login">Login</a>
      }
    </nav>,
    if (prs:is-game-master())
    then
      <nav>
        <a href="ships">Administrate ships</a>
      </nav>
    else (),
    if (prs:is-administrator())
    then
      <nav>
        <a href="players">Administrate players</a>
        <a href="ships">Administrate ships</a>
      </nav>
    else ()
	)
};

(:~ site-wide footer :)
declare function site:footer() 
	as element()* {
  (
		<p>This site powered by <a href="http://www.exist-db.org">eXist</a> native XML database and {
			<a href="http://www.agencexml.com/xsltforms">XSLTForms</a>} XForms processor. 
			The software is free and open source. 
			See the <a href="https://github.com/EfraimFeinstein/PersonnelDB">source code</a> for details.</p>
	)
};

(: the app-header is a header that goes inside the applet's space :)
declare function site:app-header()
	as element()* {
	()
};
