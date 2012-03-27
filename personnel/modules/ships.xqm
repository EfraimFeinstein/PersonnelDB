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
import module namespace prs="http://stsf.net/xquery/personnel"
  at "personnel.xqm";

declare namespace p="http://stsf.net/personnel/players";
declare namespace s="http://stsf.net/personnel/ships";
declare namespace error="http://stsf.net/errors";

declare variable $ship:ship-collection := 
  concat($prs:data-collection, "/ships");

declare function ship:get-ship(
  $name as xs:string
  ) as element(s:ship)? {
  collection($ship:ship-collection)//s:ship[.=$name]
};

(: determine a ship resource by ship name :)
declare function ship:ship-resource(
  $name as xs:string
  ) as xs:string? {
  concat(string($name), ".xml")
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
      not(validation:jing($player, xs:anyURI("/db/personnel/schemas/ships.rnc")))
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
            then ()
            else xmldb:create-group($ship-gm-group, "admin"),
            sm:chown($ship-resource, "admin"),
            sm:chgrp($ship-resource, $ship-gm-group),
            sm:chmod($ship-resource, "rw-rw-r--"),
            sm:add-group-ace($ship-resource, "administrator", true(), "w"),
            true()
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