xquery version "3.0";
(: reassign an unassigned character (usable by ship GM and admins) 
 : POST the following:
 : <x:reassign>
 :  <x:ship>{$name}</x:ship>
 :  <x:position>{$id}</x:position>
 :  <x:character>{$id}</x:character>
 : </x:reassign>
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

let $reassignment := request:get-data()/x:reassign
let $ship := $reassignment/x:ship/string()
let $position := $reassignment/x:position/number()
let $character := $reassignment/x:character/number()
let $pos := ship:get-position($ship, $position)
return
  if (not(prs:is-administrator() or ship:is-game-master($ship)))
  then prs:error(403, "Unauthorized")
  else if (empty($pos))
  then prs:error(400, "Position does not exist")
  else if ($pos/s:status = ("pending","filled"))
  then prs:error(400, "Position is filled or pending")
  else 
    let $null := ship:reassign($ship, $position, $character)
    return ship:transform-extended(ship:get-ship($ship)) 