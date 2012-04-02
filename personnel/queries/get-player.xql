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
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///db/personnel/modules/ships.xqm";

declare namespace x="http://stsf.net/personnel/extended";
declare namespace p="http://stsf.net/personnel/players";
declare namespace s="http://stsf.net/personnel/ships";
declare namespace error="http://stsf.net/error";

(: add player posting information :)
declare function local:transform(
  $nodes as node()*
  ) as node()* {
  for $node in $nodes
  return
    typeswitch($node)
    case element(p:character) return
      element p:character {
        $node/@*,
        local:transform($node/node()),
        let $posting := 
          collection($ship:ship-collection)//(
            s:position[s:heldBy=$node/p:id]|
            s:unassigned/s:heldBy[.=$node/p:id]
            )
        let $ship := $posting/ancestor::s:ship/s:name/string()
        let $department := $posting/parent::s:department/s:name/string()
        let $position := $posting/s:name/string()
        let $leave := $node/p:history/p:leave[empty(p:endDate)]
        let $unassigned := $posting instance of element(s:unassigned)
        let $status := 
          if ($unassigned)
          then "unassigned"
          else if (exists($posting))
          then "posted"
          else if (exists($leave))
          then "leave"
          else "unposted"
        return
          element x:posting {
            element x:status { $status },
            element x:ship { $ship },
            element x:department { $department },
            element x:position { $position },
            element x:unassigned { $unassigned },
            element x:leave { exists($leave) }
          }
      }
    case element() return 
      element {name($node)}{ $node/@*, local:transform($node/node()) }
    case document-node() return local:transform($node/node())
    default return $node
};

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
        local:transform($requested-player)
    