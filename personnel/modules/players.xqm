xquery version "3.0";
(: player database functions
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)
module namespace pl="http://stsf.net/xquery/players";

import module namespace settings="http://stsf.net/xquery/settings"
  at "settings.xqm";
import module namespace mem="http://stsf.net/xquery/members"
  at "members.xqm";
import module namespace prs="http://stsf.net/xquery/personnel"
  at "personnel.xqm";

declare namespace p="http://stsf.net/personnel/players";
declare namespace s="http://stsf.net/personnel/ships";
declare namespace x="http://stsf.net/personnel/extended";
declare namespace error="http://stsf.net/errors";

declare variable $pl:player-collection := 
  concat($prs:data-collection, "/players");

(: add player posting information to a player structure :)
declare function pl:transform-extended(
  $nodes as node()*
  ) as node()* {
  for $node in $nodes
  return
    typeswitch($node)
    case element(p:character) return
      element p:character {
        $node/@*,
        local:transform($node/node()),
        for $posting in 
          collection($ship:ship-collection)//(
            s:position[s:heldBy=$node/p:id]|
            s:unassigned/s:heldBy[.=$node/p:id]
            )
        let $ship := $posting/ancestor::s:ship/s:name/string()
        let $department := $posting/parent::s:department/s:name/string()
        let $position := $posting/s:name/string()
        let $leave := $node/p:history/p:leave[empty(p:endDate)]
        let $unassigned := $posting/parent::s:unassigned
        let $status := 
          if ($unassigned)
          then "unassigned"
          else if ($posting/s:status="filled")
          then "posted"
          else if ($posting/s:status="pending")
          then "applied"
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
          },
        for $application in $node/p:history/(p:application[p:status="cascade"]|p:leave)
        let $applied-position := 
          if ($application instance of element(p:leave))
          then ()
          else collection($ship:ship-collection)//
            s:ship[s:name=$application/p:ship]//s:position[s:id=$application/p:position]
        let $leave := $application/self::p:leave[empty(p:endDate)]
        let $status := 
          if (exists($leave))
          then "leave"
          else "applied"
        return
          element x:posting {
            element x:status { $status },
            element x:ship { $application/p:ship },
            element x:department { $applied-position/ancestor::s:department/s:name/string() },
            element x:position { $applied-position/s:name/string() },
            element x:unassigned { false() },
            element x:leave { $leave }
          }
      }
    case element() return 
      element {name($node)}{ $node/@*, pl:transform-extended($node/node()) }
    case document-node() return pl:transform-extended($node/node())
    default return $node
};


declare function pl:login-player(
  $boardName as xs:string
  ) as xs:boolean? {
  let $player := pl:get-player($boardName)
  let $member-number := 
    xs:integer(
      collection($pl:player-collection)//
        p:character[p:boardName=$boardName]/p:id
    )
  let $did-login :=
    mem:login-member($member-number)
  where $did-login
  return (
    session:set-attribute("authenticated", $boardName),
    session:set-attribute("member-number", $member-number),
    true()
  )
};

declare function pl:logout-player(
  ) {
  mem:logout-member()
};


declare function pl:get-player(
  $name as xs:string
  ) as element(p:player)? {
  (collection($pl:player-collection)//p:player[p:character/p:boardName=$name])[1]
};

declare function pl:get-player-by-id(
  $id as xs:integer
  ) as element(p:player)? {
  (collection($pl:player-collection)//p:player[descendant::p:id=$id])[1]
};

(: determine a player resource by board name or integer id :)
declare function pl:player-resource(
  $player-id as item()
  ) as xs:string? {
  typeswitch ($player-id)
  case xs:integer 
  return 
    let $primary-id := pl:get-player-by-id($player-id)
    return
      if ($primary-id)
      then util:document-name($primary-id)
      else concat(string($player-id), ".xml")
  default
  return util:document-name(pl:get-player($player-id))
};

declare function pl:can-edit-player(
  $new-player as element(p:player),
  $member-number as xs:integer?
  ) as xs:boolean {
  let $member-number := ($member-number, xs:integer($new-player/p:character[1]/p:id))[1]
  let $player-xml := xs:anyURI(concat(string($pl:player-collection), "/", pl:player-resource($member-number)))
  let $current-user := xmldb:get-current-user()
  return
    if (doc-available($player-xml))
    then
      (: can edit the player :)
      sm:has-access($player-xml, "w") and
      (
        util:log-system-out((xmldb:get-current-user(), " has access: ", sm:has-access($player-xml, "w"))),
        (: only administrators can:
         : change player id numbers and board names
         : or use this to add characters
         :)
        (
          let $old-player := doc($player-xml)/p:player
          return
            count($old-player/p:character) = count($new-player/p:character) and
            (every $new-character in $new-player/p:character 
            satisfies (
              ($new-character/p:id=$old-player/p:character/p:id) and
              ($new-character/p:boardName = $old-player/p:character/p:boardName)
              )
            )
        ) or
        sm:get-group-members("administrator")=$current-user or
        $current-user="admin" 
      )
    else
      (: can create a player :)
      sm:has-access(xs:anyURI($pl:player-collection), "w") and
      sm:get-group-members("administrator")=$current-user and
      not($new-player/p:character/p:id = collection($pl:player-collection)//p:id) 
};

(:~ add a character to the given player :)
declare function pl:add-character(
  $player-id as xs:integer,
  $new-character as element(p:character)
  ) as element(p:character)? {
  if (xmldb:get-current-user()=(mem:member-name($player-id), "admin")
    or prs:is-administrator())
  then
    let $boardName := $new-character/p:boardName/string()
    let $password := $new-character/p:password/string()
    let $character-number := 
      if (prs:is-administrator())
      then mem:member-number-by-board-name($boardName)
      else prs:auth-ipb($boardName,$password)
    return
      if (empty($character-number))
      then
        error(xs:QName("error:AUTHENTICATION"), "Authentication failed")
      else if (collection($pl:player-collection)//p:id=$character-number)
      then 
        error(xs:QName("error:OWNERSHIP"), "The character has already been claimed by another player")
      else 
        let $char :=
          element p:character {
            element p:id { $character-number },
            ($new-character/p:name, element p:name { $boardName })[1],
            $new-character/p:boardName,
            ($new-character/p:email, collection($pl:player-collection)//p:player[p:id=$player-id]/p:email)[1],
            element p:history { () } 
          }
        return (
          update insert $char into pl:get-player-by-id($player-id), 
          $char
        )
  else error(xs:QName("error:ACCESS"), "A non-administrator player has to add his/her own characters")
};

(: make or edit a player :)
declare function pl:edit-player(
  $player as element(p:player)
  ) as xs:boolean? {
  if (not(pl:can-edit-player($player, ())))
  then
    error(xs:QName("error:EDIT"), "Access denied")
  else if (not(validation:jing($player, xs:anyURI("/db/personnel/schemas/players.rnc"))))
  then
    error(xs:QName("error:VALIDATION"), "Could not validate the player object")
  else
    let $member-number := xs:integer($player/p:character[1]/p:id)
    let $player-xml := pl:player-resource($member-number)
    let $member-name := mem:member-name($member-number) 
    let $player-resource :=
      xs:anyURI(concat($pl:player-collection, "/", $player-xml))
    let $player-exists := doc-available($player-resource)
    return
      if (xmldb:store($pl:player-collection, $player-xml,
        $player))
      then
        if ($player-exists)
        then true() (: done :)
        else (: create member and set permissions :)
          system:as-user("admin", $settings:admin-password,
          (
          mem:create-member($member-number),
          sm:chown($player-resource, $member-name),
          sm:chgrp($player-resource, "player"),
          sm:chmod($player-resource, "rw-r--r--"),
          sm:add-group-ace($player-resource, "administrator", true(), "w"),
          true()
          )
        )
    else 
      error(xs:QName("error:STORE"), "Could not store player data")
};

(: set the player's access level.
 : access level may be any of:
 : administrator, gamemaster, player, and/or ship gamemaster
 : only the administrator can change an access level 
 :)
declare function pl:set-access-level(
  $player-name as xs:string,
  $access-levels as xs:string*
  ) {
  if (prs:is-administrator())
  then 
    let $player := pl:get-player($player-name)
    let $member-name := mem:member-name($player/p:character[1]/p:id)
    let $new-access-levels := distinct-values(($access-levels, "player"))
    return
      system:as-user("admin", $settings:admin-password, (
        xmldb:change-user($member-name, (), $new-access-levels, ())
      ))
  else 
    error(xs:QName("error:RIGHTS"), "Only an administrator can set access levels")
};

(: apply a character to a position -- assume checks already done 
 : return the application status
 :)
declare function pl:apply(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) as xs:string {
  let $pl := pl:get-player-by-id($character)
  let $ch := $pl/p:character[p:id=$character]
  let $status := 
    (: if waiting for another application, 
    cascade, otherwise, pending :)
    if ($ch/p:history/p:application[not(p:decisionDate)])
    then "cascade"
    else "pending"
  return (
    update insert element p:application {
      element p:ship { $ship },
      element p:position { $position },
      element p:status { $status },
      element p:applyDate { current-dateTime() }
    } into $ch/p:history,
    $status
  )
};

declare function pl:approve(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) {
  let $pl := pl:get-player-by-id($character)
  let $ch := $pl/p:character[p:id=$character]
  let $app := $ch/p:history/p:application
    [p:ship=$ship][p:position=$position][p:status="pending"][1]
  let $leave := $ch/p:history/p:leave[empty(p:endDate)]
  return (
    (: if the player is on leave, return him to duty:)
    if (exists($leave))
    then update insert element p:endDate { current-dateTime() } into $leave
    else (),
    update value $app/p:status with "approved",
    update insert element p:decisionDate { 
      current-dateTime() 
    } into $app,
    update delete $ch/p:history/p:application[p:status="cascade"]
  )
};

declare function pl:reject(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) {
  let $pl := pl:get-player-by-id($character)
  let $ch := $pl/p:character[p:id=$character]
  let $app := $ch/p:history/p:application
    [p:ship=$ship][p:position=$position]
  return (
    update value $app/p:status with "rejected",
    update insert element p:decisionDate { 
      current-dateTime() 
    } into $app,
    update value 
      $app/following-sibling::p:application[p:status="cascade"][1]/p:status
      with "pending"
  )
};

declare function pl:leave(
  $ship as xs:string,
  $position as xs:integer,
  $character as xs:integer
  ) {
  let $pl := pl:get-player-by-id($character)
  let $ch := $pl/p:character[p:id=$character]
  return (
    update insert element p:leave {
      element p:startDate { current-dateTime() }
    } into $ch/p:history
  )
};

declare function pl:return(
  $character as xs:string
  ) {
  let $pl := pl:get-player-by-id($character)
  let $ch := $pl/p:character[p:id=$character]
  return (
    update insert element p:endDate {
      current-dateTime()
    } into $ch/p:history/p:leave[last()]
  )
};