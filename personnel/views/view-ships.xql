xquery version "3.0";
(: view ships that you have access to
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser GPL version 3 or later
 :)
import module namespace mem="http://stsf.net/xquery/members"
  at "xmldb:exist:///personnel/modules/members.xqm";
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///personnel/modules/personnel.xqm";
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///personnel/modules/ships.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "xmldb:exist:///personnel/modules/settings.xqm";
import module namespace site="http://stsf.net/xquery/site"
  at "xmldb:exist:///personnel/modules/site.xqm";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace s="http://stsf.net/personnel/ships";

let $logged-in := session:get-attribute("member-number")
let $accessible-ships :=
  collection($ship:ship-collection)//s:ship
let $ships-list := 
  <nav>
    {
      for $ship in $accessible-ships
      order by $ship
      return $ship/<a href="ships?ship={s:name/string()}">{s:name/string()}</a>
    }
  </nav>
return 
  site:form(
    (),
    <title>Ships</title>,
    $ships-list
  )