xquery version "3.0";
(: view players that you have access to
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser GPL version 3 or later
 :)
import module namespace mem="http://stsf.net/xquery/members"
  at "xmldb:exist:///personnel/modules/members.xqm";
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///personnel/modules/personnel.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "xmldb:exist:///personnel/modules/players.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "xmldb:exist:///personnel/modules/settings.xqm";
import module namespace site="http://stsf.net/xquery/site"
  at "xmldb:exist:///personnel/modules/site.xqm";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace p="http://stsf.net/personnel/players";

let $logged-in := session:get-attribute("member-number")
let $accessible-players :=
  collection($pl:player-collection)//
    p:player[
      if (prs:is-game-master())
      then true() 
      else descendant::p:id=$logged-in
    ] 
let $players-table := 
  <table border="1">
    <tr>
      <th>Name</th>
      <th>Board name</th>
      <th>Group</th>
      <th>Email</th>
      <th>Character name</th>
      <th>Character board name</th>
      <th>Email</th>
      <th>Applied to</th>
      <th>Assigned to</th>
    </tr>
    {
      for $player in $accessible-players
      let $member-number := $player/p:id/number()
      let $db-user := mem:member-name($member-number)
      return $player/(
        <tr>
          <td>{p:name/string()}</td>
          <td><a href="{$settings:absolute-url-base}/forms/players.xql?player-id={$member-number}">{p:boardName/string()}</a></td>
          <td>{
            if ($db-user=sm:get-group-members("administrator"))
            then "Administrator"
            else if ($db-user=sm:get-group-members("gamemaster"))
            then "GM"
            else "Player"
          }</td>
          <td>{p:email/string()}</td>
          <!--
          <td/>
          <td/>
          <td/>
          <td/>
          <td/>
          -->
        </tr>,
        for $character in p:character
        return $character/(
          <tr>
            <td/>
            <td/>
            <td/>
            <td/>
            <td>{p:name/string()}</td>
            <td>{p:boardName/string()}</td>
            <td>{p:email/string()}</td>
            <td>Applied to</td>
            <td>Assigned to</td>
          </tr>
        )
      )
    }
  </table>
return 
  site:form(
    (),
    <title>Players</title>,
    $players-table
  )