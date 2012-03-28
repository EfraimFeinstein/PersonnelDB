xquery version "3.0";
(: Get the selected ship
 : Method: GET
 : Parameters:
 :  ship = ship name or "new"
 : Return:
 :  200 OK
 :  403 Not authenticated
 :  404 Ship not found
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)

import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "xmldb:exist:///db/personnel/modules/players.xqm";
import module namespace mem="http://stsf.net/xquery/members"
  at "xmldb:exist:///db/personnel/modules/members.xqm";
import module namespace ship="http://stsf.net/xquery/ships"
  at "xmldb:exist:///db/personnel/modules/ships.xqm";

declare namespace p="http://stsf.net/personnel/players";
declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";
declare namespace error="http://stsf.net/error";

declare function local:transform(
  $node as node()*
  ) as node()* {
  for $n in $node
  return
    typeswitch($n)
    case element(s:heldBy)
    return 
      element s:heldBy {
        $n/@*,
        attribute x:boardName { 
          if ($n/number())
          then collection($pl:player-collection)//p:character[p:id=$n/number()]/p:boardName/string()
          else () 
        },
        local:transform($n/node())
      }
    case element() return 
      element {name($n)}{
        $n/@*,
        local:transform($n/node())
      }
    case document-node() return local:transform($n/node())
    default return $n
};

let $member-number := session:get-attribute("member-number")
let $ship := request:get-parameter("ship", "new") 
return
  if (not($member-number))
  then 
    prs:error(403, "Not authenticated")
  else if ($ship = "new")
  then
    if (prs:is-administrator())
    then local:transform(doc("/db/personnel/resources/ship-template.xml"))
    else prs:error(403, "Only administrators can create new ships")
  else
    let $ship-xml := ship:get-ship($ship)
    return
      if (exists($ship-xml))
      then local:transform($ship-xml)
      else prs:error(404, "Not found")
      
    