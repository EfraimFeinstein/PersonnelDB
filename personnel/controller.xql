xquery version "3.0";
(: main entry controller 
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)

import module namespace settings="http://stsf.net/xquery/settings"
  at "modules/settings.xqm";

declare namespace exist="http://exist.sourceforge.net/NS/exist";

let $db-base := "/personnel/"
let $ext-base := $settings:absolute-url-base
let $authenticated := session:get-attribute("authenticated")
let $null := util:log-system-out(("controller: path=", $exist:path, " resource=", $exist:resource))
return
  if (
    starts-with($exist:path, "/queries") or 
    starts-with($exist:path, "/resources") or
    starts-with($exist:path, "/views"))
  then
    element exist:dispatch {
      element exist:forward {
        attribute url { concat($db-base, $exist:path) }
      }
    }
  else if (not($authenticated) and not($exist:resource="login"))
  then
    element exist:dispatch {
      element exist:redirect {
        attribute url { concat($ext-base, "/login") }
      }
    }
  (: from here on, we are authenticated :)
  else
    element exist:dispatch {
      switch ($exist:resource)
      case "login"
      return
        element exist:forward {
          attribute url { concat($db-base, "forms/login.xql") }
        }
      case "logout"
      return (
        session:invalidate(),
        element exist:redirect {
          attribute url { concat($ext-base, "/login") }
        }
      )
      case ("admin", "")
      return
        element exist:forward { 
          attribute url { concat($db-base, "forms/admin.xql") }
        }
      case "players"
      return
        element exist:forward {
          attribute url { concat($db-base, "forms/players.xql") }
        }
      case "ships"
      return 
        element exist:forward { 
          attribute url { concat($db-base, "forms/ships.xql") }
        } 
      case "view-players"
      return
        element exist:forward {
          attribute url { concat($db-base, "views/view-players.xql") }
        }
      case "view-ships"
      return
        element exist:forward {
          attribute url { concat($db-base, "views/view-ships.xql") }
        }
      default 
      return 
        element exist:ignore { () } 
    }