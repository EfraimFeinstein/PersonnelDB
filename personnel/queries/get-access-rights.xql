xquery version "3.0";
(: retrieve access rights for a player or the logged in player 
 : returned as an XML structure of the form:
 : <levels xmlns="">
 :  <level access="on|off">name</level>
 : </levels>
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU LGPL 3 or above
 :)
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///personnel/modules/personnel.xqm";
import module namespace mem="http://stsf.net/xquery/members"
  at "xmldb:exist:///personnel/modules/members.xqm";

let $logged-in := session:get-attribute("member-number")
let $player-id := request:get-parameter("player-id", $logged-in)
return
  if ($logged-in)
  then
    let $db-user := 
      if ($player-id = "new")
      then () 
      else mem:member-name($player-id)
    return
      <levels xmlns="">{
        let $user-groups := 
          if ($player-id = "new") 
          then ()
          else xmldb:get-user-groups($db-user)
        for $group in sm:get-groups()[not(.=("dba","guest"))][not(starts-with(.,"member-"))]
        let $is-member := $group = $user-groups
        order by $group
        return
          <level>
            <access>{
            if ($is-member)
            then 'true'
            else 'false'
            }</access>
            <name>{$group}</name>
          </level>
      }</levels>
  else 
    prs:error(403, "You must be logged in to use this function")