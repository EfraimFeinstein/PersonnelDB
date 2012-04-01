xquery version "3.0";
(: approve a pending application (usable by ship GM and admins) 
 : POST the following:
 : <x:approve>
 :  <x:ship>{$name}</x:ship>
 :  <x:position>{$id}</x:position>
 : </x:approve>
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU LGPL 3+
 :)
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace appl="http://stsf.net/xquery/applications"
  at "xmldb:exist:///db/personnel/modules/applications.xqm";
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///db/personnel/modules/ships.xqm";
  
declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";

let $approval := request:get-data()/x:approve
let $ship := $approval/x:ship/string()
let $position := $approval/x:position/number()
let $pos := ship:get-ship($ship)/descendant::s:position[s:id=$position]
return
  if (not(prs:is-administrator() or ship:is-game-master($ship)))
  then prs:error(403, "Unauthorized")
  else if ($pos/s:status != "pending")
  then prs:error(400, "Position is not pending")
  else appl:approve($ship, $position, $pos/s:heldBy/number()) 