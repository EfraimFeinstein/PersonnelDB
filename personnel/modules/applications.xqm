xquery version "3.0";
(: applications module
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License version 3 or later
 :)
module namespace appl="http://stsf.net/xquery/applications";

import module namespace mem="http://stsf.net/xquery/members"
  at "members.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "players.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "settings.xqm";
import module namespace ship="http://stsf.net/xquery/ships"
  at "ships.xqm";

declare namespace p="http://stsf.net/personnel/players";
declare namespace s="http://stsf.net/personnel/ships";
declare namespace m="http://stsf.net/personnel/mail";

declare function local:template(
  $nodes as node()*,
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) as xs:string {
  string-join(
    for $node in $nodes
    return
      typeswitch($node)
      case document-node() 
      return local:template($node/node(), $ship, $position, $character)
      case element(m:template)
      return local:template($node/node(), $ship, $position, $character)
      case element(m:ship)
      return $ship
      case element(m:position)
      return 
        let $p := ship:get-ship($ship)//s:position[s:id=$position]
        return 
          ($p/s:name, "in", $p/parent::s:department/s:name)
      case element(m:character)
      return
        pl:get-player-by-id($character)/p:character[p:id=$character]/(p:name[.],p:boardName)[1]
      case element(m:gm)
      return 
        string-join(
          for $gm in sm:get-group-members(concat($ship, " GM"))[not(.="admin")]
          let $pl := pl:get-player(mem:board-name-by-member-name($gm))
          return 
            concat($pl/s:name, " <", $pl/s:email, ">")
         , " and ")
      default return $node
    , " ")
};

declare function local:send-application-email(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) {
  let $sent := mail:send-email(
    <mail>
      <from>{$settings:from-email-address}</from>
      <reply-to/>
      {
        for $gm in ship:get-game-master-players($ship)
        return
          <to>{$gm/p:email/string()}</to>
      }
      <cc/>
      <bcc/>
      <subject>Star Trek Simulation Forum application</subject>
      <message>
        <text>{
          local:template(doc("/personnel/resources/gm-template.xml"),
          $ship,$position,$character)
        }</text>
      </message>
    </mail>, 
    $settings:smtp-server, ()
  )
  return ()
};

declare function appl:apply(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) {
  let $status := pl:apply($ship, $position, $character)
  return
    if ($status = "pending")
    then (
      (: do not block up positions for cascading applications :)
      let $app := ship:apply($ship, $position, $character)
      return local:send-application-email($ship, $position, $character)
    )
    else ()
};

declare function appl:approve(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) {
  (: was this a transfer application? if so, leave the previous ship:)
  let $character := pl:get-player-by-id($character)//p:character[p:id=$character]
  let $old-position := $character/p:history/p:application[p:status="approved"][last()][following-sibling::p:leave]
  where exists($old-position)
  return
    let $old-ship := $old-position/p:ship
    let $old-position := $old-position/p:position
    let $null := ship:leave($old-ship, $old-position)
    return (),
  ship:approve($ship, $position),
  pl:approve($ship, $position, $character),
  let $sent := mail:send-email(
    <mail>
      <from>{$settings:from-email-address}</from>
      <reply-to/>
      <to>{pl:get-player-by-id($character)/p:email/string()}</to>
      <cc/>
      <bcc/>
      <subject>Star Trek Simulation Forum posting</subject>
      <message>
        <text>{
          local:template(doc("/personnel/resources/acceptance-template.xml"),
          $ship,$position,$character)
        }</text>
      </message>
    </mail>, 
    $settings:smtp-server, ()
  )
  return ()
};

declare function appl:reject(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) {
  pl:reject($ship, $position, $character),
  let $ship-result := ship:reject($ship, $position)
  let $pl := pl:get-player($character)
  let $ch := $pl/p:character[p:id=$character]
  let $next-cascade := $ch/p:history/p:application[p:status="cascade"][1]
  return
    if (empty($next-cascade))
    then
      let $sent := mail:send-email(
        <mail>
          <from>{$settings:from-email-address}</from>
          <reply-to/>
          <to>{($ch/p:email, $pl/p:email)[1]/string()}</to>
          <cc/>
          <bcc/>
          <subject>Star Trek Simulation Forum posting</subject>
          <message>
            <text>{
              local:template(doc("/personnel/resources/rejection-template.xml"),
              $ship,$position,$character)
            }</text>
          </message>
        </mail>, 
        $settings:smtp-server, ()
      )
      return ()
    else 
      let $next-ship := $next-cascade/p:ship
      let $next-position := $next-cascade/p:position
      let $appl := ship:apply($next-ship, $next-position, $character)
      return 
        if ($appl)
        then local:send-application-email($next-ship, $next-position, $character)
        else appl:reject($next-ship, $next-position, $character)
};

declare function appl:leave(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) {
  let $pl := pl:leave($ship, $position, $character)
  let $sh := ship:leave($ship, $position)
  return ()
  
};