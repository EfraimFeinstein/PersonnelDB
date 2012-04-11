xquery version "3.0";
(: Add a character to the given (current) player
 : Note: cannot be used by non-administrators 
 :  to add characters to anyone other then self 
 : Request parameters: 
 :    player-id
 : Data:
 :  <p:character>
 :    <p:boardName>...</p:boardName>
 :    <p:password>...</p:password>
 :    <p:name>...</p:name>?
 :    <p:email>...</p:email>?
 :  </p:character>
 : 
 : Method: POST
 : Return:
 :  200 OK and the rewritten player element
 :  400 Error
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
let $new-character := request:get-data()/p:character
return
  if (not($player-id))
  then 
    prs:error(400, "player-id parameter is required or you are not authenticated")
  else 
    let $ch := pl:add-character($player-id, $new-character)
    return pl:transform-extended(pl:get-player-by-id($player-id))
    