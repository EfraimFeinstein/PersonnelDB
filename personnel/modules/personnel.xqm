xquery version "3.0";
(: common functions support module
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)
module namespace prs="http://stsf.net/xquery/personnel";

import module namespace settings="http://stsf.net/xquery/settings"
  at "settings.xqm";
import module namespace mem="http://stsf.net/xquery/members"
  at "members.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "players.xqm";

declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace p="http://stsf.net/personnel/players";
declare namespace error="http://stsf.net/errors";

declare variable $prs:data-collection := "/db/personnel/data";

declare function prs:error(
  $code as xs:integer,
  $message as item()+
  ) as element(error) {
  response:set-status-code($code),
  <error xmlns="">{
    $message
  }</error>
};

(: authenticate against IPB, return a user's member number :)
declare function prs:auth-ipb(
  $user as xs:string,
  $password as xs:string
  ) as xs:integer? {
  let $body-string := concat("auth_key=", $settings:ipb-auth-key, 
    "&amp;ips_username=", encode-for-uri($user), 
    "&amp;ips_password=", encode-for-uri($password), 
    "&amp;anonymous=1")
  let $return-value :=
    let $intermediate-return :=
      http:send-request( 
        <http:request 
          href="http://stsf.net/forums/index.php?app=core&amp;module=global&amp;section=login&amp;do=process" method="post"
          follow-redirect="true"
          >
          <http:body media-type="application/x-www-form-urlencoded">{$body-string}</http:body>
        </http:request>)
    return 
      if ($intermediate-return/@status = "302")
      then
        (: sometimes, we get one too many redirects :)
        http:send-request( 
        <http:request 
          href="{$intermediate-return/http:header[@name='location']/@value}" method="get"
          follow-redirect="true"
          >
        </http:request>)
      else $intermediate-return
  let $user-link := $return-value//html:a[@id="user_link"]
  let $is-logged-in := exists($user-link)
  return
    if ($is-logged-in)
    then
      let $logout-return :=
        http:send-request(<http:request method="get">{$return-value//html:a[.='Sign Out']/@href}</http:request>)
      return xs:integer(substring-after($user-link/@href, "showuser="))
    else ()
};


(: perform initial setup on first login :)
declare function prs:setup(
  ) as xs:boolean? {
  let $groups-to-create := ("player", "administrator", "gamemaster") 
  return
    (: check if setup has already been done :)
    if (sm:find-groups-by-groupname("player")="player")
    then
      error(xs:QName("error:SETUP"), "Setup has already been run!")
    else system:as-user("admin", $settings:admin-password,
      (
      (: create members database :)
      mem:create-member-db(),
      (: create initial groups :)
      for $group in $groups-to-create
      let $null := xmldb:create-group($group, "admin")
      return (),
      (: create initial administrative users :)
      for $admin-user at $n in $settings:admin-users
      let $edited :=
        pl:edit-player(
          element p:player {
            element p:id { $settings:admin-numbers[$n] },
            element p:name { $admin-user },
            element p:boardName { $admin-user },
            element p:email { $settings:admin-emails[$n] }
          }
        )
      let $access-level := 
        pl:set-access-level($admin-user, ("player", "gamemaster", "administrator"))
      where not($edited)
      return 
        error(xs:QName("error:SETUP"), "Cannot set up administrative players!"),
      (: set permissions and ownership of the data collections :)
      for $collection in ("/personnel/data/ships", "/personnel/data/players")
      return (
        sm:chgrp(xs:anyURI($collection), "gamemaster"),
        sm:chmod(xs:anyURI($collection), "rwxrwxr-x"),
        sm:add-group-ace(xs:anyURI($collection), "administrator", true(), "w")
      )
    ))
};

(: determine if the logged in user is an administrator :)
declare function prs:is-administrator(
  ) as xs:boolean {
  xmldb:get-current-user()=("admin", sm:get-group-members("administrator"))
};

(: determine if the logged in user has the rights of a game master :)
declare function prs:is-game-master(
  ) as xs:boolean {
  xmldb:get-current-user()=(
    "admin", 
    sm:get-group-members("administrator"), 
    sm:get-group-members("gamemaster")
  )
};

(:~ remove everything from the extended namespace :)
declare function prs:remove-extensions(
  $node as node()*
  ) as node()* {
  for $n in $node
  return
    typeswitch($n)
    case element()
    return
      element { name($n) }{
        $n/(@* except @x:*),
        prs:remove-extensions($n/node())
      }
    default return $n
};
