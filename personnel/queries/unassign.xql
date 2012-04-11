xquery version "3.0";
(: unassign a post (usable by ship GM and admins) 
 : POST the following:
 : <x:unassign>
 :  <x:ship>{$name}</x:ship>
 :  <x:position>{$id}</x:position>
 : </x:unassign>
 : Return the updated ship structure
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU LGPL 3+
 :)
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///db/personnel/modules/ships.xqm";

declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";

let $unassignment := request:get-data()/x:unassign
let $ship := $unassignment/x:ship/string()
let $position := $unassignment/x:position/number()
let $pos := ship:get-ship($ship)/descendant::s:position[s:id=$position]
return
  if (not(prs:is-administrator() or ship:is-game-master($ship)))
  then prs:error(403, "Unauthorized")
  else if (not($pos/s:status = "filled"))
  then prs:error(400, "Position is not filled")
  else 
    let $null := ship:unassign($ship, $position)
    return ship:transform-extended(ship:get-ship($ship)) 