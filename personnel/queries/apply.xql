xquery version "3.0";
(: apply to a position
 : Expects XML of the form:
 :  <x:application>
 :    <x:ship>{ship name}</x:ship>
 :    <x:position>{id#}</x:position>
 :    <x:player>{id#}</x:player>
 :    <x:character n="{ch#}">{id#}</x:character>
 :  </x:application> 
 : alternatively, multiple applications can be in
 : <x:applications><x:application/>+</x:applications> 
 : for a player's character to apply to a given position 
 : (the n on the x:character should be 1 unless the same character
 :  is listed more than once)
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
let $applications := request:get-data()//x:application
for $application in $applications
let $player := pl:get-player-by-id($application/x:player)
let $character := $player/p:character
  [p:id=$application/x:character]
  [($application/x:character/@n/number(), 1)[1]]
let $ship := $application/x:ship/string()
let $can-apply := 
  prs:is-administrator() or
  ship:is-game-master($ship) or 
  pl:get-player-by-id($member-number)=$application/x:player
let $position := $application/x:position/number()
return
  if (not($can-apply))
  then prs:error(403, "Unauthorized")
  else if (empty($character)) 
  then prs:error(400, "Character does not exist")
  else if (not(ship:is-open-position($ship, $position)))
  then prs:error(400, "Requested position is not open")
  else appl:apply($ship, $position, $application/x:character)