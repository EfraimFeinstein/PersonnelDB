xquery version "3.0";
(: authenticate a user against Invision Power Board.
 : if the user is authenticated, set the following in the session:
 :  authenticated=true
 :  log in the session to "user", "administrator", or "GM" 
 : Method: POST
 : Parameters:
 :  user=, password=
 : Return:
 :  204 OK
 :  403 Cannot authenticate
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)

import module namespace prs="http://stsf.net/xquery/personnel"
  at "xmldb:exist:///db/personnel/modules/personnel.xqm";
import module namespace pl="http://stsf.net/xquery/players"
  at "xmldb:exist:///db/personnel/modules/players.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "xmldb:exist:///db/personnel/modules/settings.xqm";
  
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace p="http://stsf.net/personnel/players";
declare namespace m="http://stsf.net/personnel/members";
declare namespace error="http://stsf.net/error";


let $data := request:get-data()
let $user := $data//user/string()
let $password := $data//password/string()
let $all-players := collection("/db/personnel/data/players")
return
  if (not($user) or not($password))
  then
    prs:error(400, "user and password parameters are required")
  (: has the user graduated? :)
  else if (empty($all-players//p:boardName[.=$user]))
  then
    prs:error(403, "User is not in the database. Has s/he graduated?")
  else 
    (: try to log in to IPB and get the member number :)
    let $member-number := prs:auth-ipb($user, $password)
    return
      if (not($member-number))
      then
        prs:error(403, "User cannot be authenticated against the message board. Wrong username or password.")
      else
        (: log in the session :)
        let $did-login := pl:login-player($user)
        return
          if ($did-login)
          then
            response:set-status-code(204)
          else 
            prs:error(400, "Error logging in")