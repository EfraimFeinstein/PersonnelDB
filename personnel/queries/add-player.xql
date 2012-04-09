xquery version "3.0";
(: Add a new player record
 : Method: POST
 : Parameters: 
 :  refresh= If nonzero, indicates that the player database should be refreshed
 : Content:
 :  <p:player>
 :    <p:boardName/>
 :    <p:name/>?
 :    <p:email/>
 :  </p:player>
 : Return:
 :  200 OK
 :  400 Error
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)


import module namespace mem="http://stsf.net/xquery/members"
  at "xmldb:exist:///db/personnel/modules/members.xqm";
import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "xmldb:exist:///db/personnel/modules/players.xqm";

declare namespace p="http://stsf.net/personnel/players";
declare namespace error="http://stsf.net/error";

if (not(prs:is-game-master()))
then
  prs:error(403, "Only a GM can add a new player")
else
  let $refresh := 
    if (request:get-parameter("refresh", ()))
    then mem:refresh-board-name-db()
    else ()
  let $data := request:get-data()/p:player
  let $member-number := mem:member-number-by-board-name($data/p:boardName)
  let $player := 
    element p:player {
      element p:character {
        element p:id { $member-number },
        ($data/p:name, element p:name { $data/p:boardName/string() })[1],
        $data/p:boardName,
        $data/p:email,
        element p:history { () }
      }
    }
  return 
    if ($member-number)
    then
      let $success := pl:edit-player($player)
      return $player
    else
      prs:error(400, "Could not find the player with the given board name. Refresh the database?")