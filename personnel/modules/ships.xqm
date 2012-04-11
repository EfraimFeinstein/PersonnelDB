xquery version "3.0";
(: ship database functions
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)
module namespace ship="http://stsf.net/xquery/ships";

import module namespace settings="http://stsf.net/xquery/settings"
  at "settings.xqm";
import module namespace mem="http://stsf.net/xquery/members"
  at "members.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "players.xqm";
import module namespace prs="http://stsf.net/xquery/personnel"
  at "personnel.xqm";

declare namespace p="http://stsf.net/personnel/players";
declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";
declare namespace error="http://stsf.net/errors";

declare variable $ship:ship-collection := 
  concat($prs:data-collection, "/ships");

declare function ship:get-ship(
  $name as xs:string
  ) as element(s:ship)? {
  collection($ship:ship-collection)//s:ship[s:name=$name]
};

(: determine a ship resource by ship name :)
declare function ship:ship-resource(
  $name as xs:string
  ) as xs:string? {
  concat(encode-for-uri(string($name)), ".xml")
};

declare function ship:can-edit-ship(
  $new-ship as element(s:ship),
  $member-number as xs:integer
  ) as xs:boolean {
  let $ship-name := $new-ship/s:name
  let $ship-xml := xs:anyURI(concat(string($ship:ship-collection), "/", ship:ship-resource($ship-name)))
  let $current-user := xmldb:get-current-user()
  return
    if (doc-available($ship-xml))
    then
      (: can edit the ship, which is entirely controlled by
       : the normal group mechanisms
       :)
      sm:has-access($ship-xml, "w") 
    else
      (: can create a ship: only administrators :)
      sm:has-access(xs:anyURI($ship:ship-collection), "w") and
      sm:get-group-members("administrator")=$current-user and
      not($new-ship/s:name = collection($ship:ship-collection)//s:name) 
};

(: additional validation not done by RelaxNG :)
declare function local:additional-validation(
  $ship as element(s:ship)
  ) as xs:boolean {
  (: each position has a unique id :)
  let $ids := $ship//s:position/s:id
  return count($ids) = count(distinct-values($ids))
};

(: make or edit a ship :)
declare function ship:edit-ship(
  $ship as element(s:ship)
  ) as xs:boolean? {
  let $member-number := session:get-attribute("member-number")
  return
    if (not(ship:can-edit-ship($ship, $member-number)))
    then
      error(xs:QName("error:EDIT"), "Access denied")
    else if (
      not(validation:jing($ship, xs:anyURI("/db/personnel/schemas/ships.rnc")))
      and local:additional-validation($ship)
      )
    then
      error(xs:QName("error:VALIDATION"), "Could not validate the ship object")
    else
      let $ship-xml := ship:ship-resource($ship/s:name)
      let $ship-resource :=
        xs:anyURI(concat($ship:ship-collection, "/", $ship-xml))
      let $ship-exists := doc-available($ship-resource)
      let $ship-gm-group := concat($ship/s:name, " GM")
      let $ship-player-group :=  concat($ship/s:name, " Player")
      return
        if (xmldb:store($ship:ship-collection, $ship-xml,
          $ship))
        then
          if ($ship-exists)
          then true() (: done :)
          else (: create ship and set permissions :)
            system:as-user("admin", $settings:admin-password,
            (
            if (xmldb:group-exists($ship-gm-group))
            then true()
            else xmldb:create-group($ship-gm-group, "admin"),
            sm:chown($ship-resource, "admin"),
            sm:chgrp($ship-resource, $ship-gm-group),
            sm:chmod($ship-resource, "rw-rw-r--"),
            sm:add-group-ace($ship-resource, "administrator", true(), "w"),
            (: the player group needs to be able to make applications :)
            sm:add-group-ace($ship-resource, "player", true(), "w") 
          )
        )
        else 
          error(xs:QName("error:STORE"), "Could not store ship data")
};

declare function ship:add-gm(
  $ship as xs:string,
  $gm as xs:string
  ) as xs:boolean? {
  if (prs:is-administrator())
  then
    system:as-user("admin", $settings:admin-password,
      xmldb:add-user-to-group($gm, concat($ship, " GM"))
    )
  else
    error(xs:QName("error:ACCESS"),"Access denied")
};

declare function ship:remove-gm(
  $ship as xs:string,
  $gm as xs:string
  ) as xs:boolean? {
  if (prs:is-administrator())
  then
    system:as-user("admin", $settings:admin-password,
      xmldb:remove-user-from-group($gm, concat($ship, " GM"))
    )
  else
    error(xs:QName("error:ACCESS"),"Access denied")
};

(: is the current logged in user a GM of the given ship? :)
declare function ship:is-game-master(
  $ship as xs:string
  ) as xs:boolean {
  sm:get-group-members(concat($ship, " GM"))=
    xmldb:get-current-user()
};

(: return the player records of the GMs of the given ship :)
declare function ship:get-game-master-players(
  $ship as xs:string
  ) as element(p:player)* {
  for $gm in sm:get-group-members(concat($ship, " GM"))[not(.="admin")]
  return
    pl:get-player(mem:board-name-by-member-name($gm))
};

declare function ship:is-open-position(
  $ship as xs:string,
  $position-id as xs:integer
  ) as xs:boolean {
  exists(collection($ship:ship-collection)//
    s:ship[s:name=$ship]/descendant::s:position
      [s:id=$position-id][
        s:status=("open",
         "reserved"[ship:is-game-master($ship)])
      ])
};

declare function ship:get-position(
  $ship as xs:string,
  $position as xs:integer
  ) as element(s:position)? {
  collection($ship:ship-collection)//s:ship[s:name=$ship]/
    descendant::s:position[s:id=$position]
};

(: process an application to a position -- assume all other checks
 : have taken place
 : return true() if the position can be applied for
 :)
declare function ship:apply(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) as xs:boolean? {
  let $pos := ship:get-position($ship, $position)
  where not($pos/s:status = ("pending", "filled"))
  return (
    if ($pos/s:status/@saved)
    then update value $pos/s:status/@saved with $pos/s:status 
    else update insert attribute saved { $pos/s:status } into $pos/s:status,
    update value $pos/s:status with "pending",
    update value $pos/s:heldBy with $character,
    true()
  )
};

(: approve an application and assign a character :)
declare function ship:approve(
  $ship as xs:string,
  $position as xs:integer
  ) {
  let $pos := ship:get-position($ship, $position)
  return 
    update value $pos/s:status with "filled"
};

(: reject a pending application :)
declare function ship:reject(
  $ship as xs:string,
  $position as xs:integer
  ) as xs:boolean? {
  let $pos := ship:get-position($ship, $position)
  (: only pending applications can be rejected! :)
  where $pos/s:status = "pending"
  return ( 
    update value $pos/s:status with $pos/s:status/@saved/string(),
    update value $pos/s:heldBy with "",
    true()
  )
};

(: a player leaves a given position :)
declare function ship:leave(
  $ship as xs:string,
  $position as xs:integer
  ) as xs:boolean? {
  let $pos := ship:get-position($ship, $position)
  (: only filled positions can be left! :)
  where $pos/s:status = "filled"
  return ( 
    update value $pos/s:status with $pos/s:status/@saved/string(),
    update value $pos/s:heldBy with "",
    true()
  )
};

(: reopen a position by unassigning a player, but keep the player
 : on the ship
 :)
declare function ship:unassign(
  $ship as xs:string,
  $position as xs:integer
  ) as xs:boolean? {
  let $pos := ship:get-position($ship, $position)
  let $shipx := ship:get-ship($ship)
  let $heldby := $pos/s:heldBy
  (: only filled positions can be left! :)
  where $pos/s:status = "filled"
  return ( 
    update insert $heldby into $shipx//s:unassigned[empty(s:heldBy=$heldby)],
    update value $pos/s:status with $pos/s:status/@saved/string(),
    update value $pos/s:heldBy with "",
    true()
  )
};

(: reassign an unassigned character :)
declare function ship:reassign(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) as xs:boolean? {
  let $pos := ship:get-position($ship, $position)
  let $shipx := ship:get-ship($ship)
  let $heldby := $shipx//s:unassigned/s:heldBy[.=$character]
  where exists($heldby) and 
    $pos/s:status=("open","reserved")
  return (
    if ($pos/s:status/@saved)
    then update value $pos/s:status/@saved with $pos/s:status/string() 
    else update insert attribute saved { $pos/s:status/string() } into $pos/s:status,
    update value $pos/s:status with "filled",
    update value $pos/s:heldBy with $character,
    update delete $heldby,
    true()
  )
};

(: add extended information to the ship structure :)
declare function ship:transform-extended(
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
        ship:transform-extended($n/node())
      }
    case element() return 
      element {name($n)}{
        $n/@*,
        ship:transform-extended($n/node())
      }
    case document-node() return ship:transform-extended($n/node())
    default return $n
};
