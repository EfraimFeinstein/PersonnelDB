xquery version "3.0";
(: Get the selected player's XML records
 : Method: GET
 : Parameters:
 :  player-id = player id number, if not given, select authenticated member
 : Return:
 :  200 OK
 :  403 Not authenticated
 :  404 Player id not found
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)

import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "xmldb:exist:///db/personnel/modules/players.xqm";

declare namespace p="http://stsf.net/personnel/players";
declare namespace error="http://stsf.net/error";

let $authenticated-member := session:get-attribute("member-number")
let $player-id := request:get-parameter("player-id", $authenticated-member) 
return
  if (not($authenticated-member))
  then 
    prs:error(403, "Not authenticated")
  else
    let $requested-player := collection($pl:player-collection)//p:id[.=$player-id]/ancestor::p:player
    return
      if (not(prs:is-game-master() or $requested-player/p:id=$authenticated-member))
      then
        prs:error(403, "Only a game master or administrator can get player information for anyone other than themselves.")
      else 
        $requested-player
    