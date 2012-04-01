xquery version "3.0";
(: set access rights for a player. You must be an administrator! 
 : POST an XML structure of the form:
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
import module namespace settings="http://stsf.net/xquery/settings"
  at "xmldb:exist:///personnel/modules/settings.xqm";

let $logged-in := session:get-attribute("member-number")
let $player-id := request:get-parameter("player-id", $logged-in)
let $data := request:get-data()/levels
return
  if (prs:is-administrator())
  then
    system:as-user("admin", $settings:admin-password, 
      let $db-user := mem:member-name($player-id)
      let $groups := $data/level[access="true"][xmldb:group-exists(name)]/name
      return
          xmldb:change-user($db-user, (), $groups, ())
    )
  else 
    prs:error(403, "You must be an administrator to use this function")