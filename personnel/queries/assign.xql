xquery version "3.0";
(: assign to a position (only can be used by the ship GM or an administrator)
 : Expects XML of the form:
 :  <x:assignment>
 :    <x:ship>{ship name}</x:ship>
 :    <x:position>{id#}</x:position>
 :    <x:character>{id#}</x:character>
 :  </x:assignment> 
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU LGPL 3+
 :)
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "xmldb:exist:///db/personnel/modules/players.xqm";
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///db/personnel/modules/ships.xqm";
import module namespace appl="http://stsf.net/xquery/applications"
  at "xmldb:exist:///db/personnel/modules/applications.xqm";

declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";
declare namespace p="http://stsf.net/personnel/players";

(: ship game masters can initiate applications for anyone to their own ships... :)
let $member-number := session:get-attribute("member-number")
let $assignment := request:get-data()/x:assignment
let $player := pl:get-player-by-id($assignment/x:character)
let $character := $player/p:character
  [p:id=$assignment/x:character]
let $ship := $assignment/x:ship/string()
let $can-assign := 
  prs:is-administrator() or
  ship:is-game-master($ship)
let $position := $assignment/x:position/number()
return
  if (not($can-assign))
  then prs:error(403, "Unauthorized")
  else if (empty($character)) 
  then prs:error(400, "Character does not exist")
  else if (not(ship:is-open-position($ship, $position)))
  then prs:error(400, "Requested position is not open")
  else 
    let $application := appl:apply($ship, $position, $assignment/x:character)
    let $approval := appl:approve($ship, $position, $assignment/x:character)
    return ()