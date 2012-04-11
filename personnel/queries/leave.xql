xquery version "3.0";
(: put a character on leave. If only a character is given,
 : we attempt to find what position he holds
 : POST the following:
 : <x:leave return="player"?>
 :  <x:ship>{$name}</x:ship>?
 :  <x:position>{$id}</x:position>?
 :  <x:character>{$id}</x:character>
 : </x:leave>
 : Return the updated s:ship structure, or player structure if
 :  return="player" is specified
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU LGPL 3+
 :)
import module namespace appl="http://stsf.net/xquery/applications"
  at "xmldb:exist:///db/personnel/modules/applications.xqm";
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///db/personnel/modules/ships.xqm";

declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";

let $leave := request:get-data()/x:leave
let $char := $leave/x:character/number()
let $character-position := 
  collection($ship:ship-collection)//s:position[s:heldBy=$char]
let $ship := ($leave/x:ship, $character-position/ancestor::s:ship/s:name)[1]/string()
let $position := ($leave/x:position, $character-position/s:id)[1]/number()
let $pos := ship:get-position($ship, $position)
let $character := ($char, $pos/s:heldBy/number())[1]
return
  if (not(prs:is-administrator() or ship:is-game-master($ship)))
  then prs:error(403, "Unauthorized")
  else if (empty($pos))
  then prs:error(400, "Position does not exist")
  else if ($pos/s:status != "filled")
  then prs:error(400, "Position is not filled")
  else 
    let $null := appl:leave($ship, $position, $character)
    return 
      if ($leave/@return = "player")
      then pl:get-player-by-id($character) 
      else ship:get-ship($ship) 