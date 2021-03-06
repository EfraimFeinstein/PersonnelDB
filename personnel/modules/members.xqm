xquery version "3.0";
(: member database functions.
 : the member database is a flat file containing a mapping between
 : IPB member numbers and eXist users/passwords
 :
 : A separate database file links all board names to member numbers.
 : This requires periodic updates 
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License, version 3 or later
 :)
module namespace mem="http://stsf.net/xquery/members";

import module namespace prs="http://stsf.net/xquery/personnel"
  at "personnel.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "settings.xqm";

declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace m="http://stsf.net/personnel/members";
declare namespace p="http://stsf.net/personnel/players";
declare namespace error="http://stsf.net/errors";

declare variable $mem:member-collection :=
  concat($prs:data-collection, "/members");
declare variable $mem:member-db := "members.xml";
declare variable $mem:member-db-uri := 
  xs:anyURI(concat($mem:member-collection, "/", $mem:member-db));
declare variable $mem:board-db := "boardnames.xml";
declare variable $mem:board-db-uri :=
  xs:anyURI(concat($mem:member-collection, "/", $mem:board-db));

(: get the eXist user name from a given member number :)
declare function mem:member-name(
  $member-number as xs:integer
  ) as xs:string {
  concat("member-", string($member-number))
};

(: create an empty members database, can only be done by admin! :)
declare function mem:create-member-db(
  ) as xs:boolean {
    doc-available($mem:member-db-uri) or (
      xmldb:get-current-user()="admin" and
      (
        (if ( 
          xmldb:store($mem:member-collection, $mem:member-db, 
          <m:members/>)
          )
        then (
          sm:chmod($mem:member-db-uri, "rw-rw----"),
          sm:chgrp($mem:member-db-uri, "dba"),
          sm:chown($mem:member-db-uri, "admin"),
          true()
        )
        else (
          false(),
          error(xs:QName("error:MEMBERS"), "Cannot create members database!")
        )) and
        (if ( 
          xmldb:store($mem:member-collection, $mem:board-db, 
          <m:boardnames/>)
          )
        then (
          sm:chmod($mem:board-db-uri, "rw-rw-r--"),
          sm:chgrp($mem:board-db-uri, "dba"),
          sm:chown($mem:board-db-uri, "admin"),
          true()
        )
        else (
          false(),
          error(xs:QName("error:BOARD"), "Cannot create board names database!")
        ))
      )
    )
};

(: add a new member to the member database :)
declare function mem:create-member(
  $member-number as xs:integer
  ) as empty() {
  let $db-name := mem:member-name($member-number)
  let $db-password := util:uuid()
  let $new-member-entry := 
    <m:member>
      <m:number>{$member-number}</m:number>
      <m:password>{$db-password}</m:password>
    </m:member>
  return
    system:as-user ("admin", $settings:admin-password,
      let $null := xmldb:create-group($db-name, "admin")
      let $null2 := xmldb:create-user($db-name, $db-password, ($db-name, "player"), ())
      let $null3 := update insert $new-member-entry into doc($mem:member-db-uri)/*
      return ()
    ) 
};

(: update only new players in the board name db :)
declare function mem:update-board-name-db(
  ) {
  system:as-user("admin", $settings:admin-password,
    local:refresh-board-name-db(doc($mem:board-db-uri)//m:last-start)
  )
};

declare function mem:refresh-board-name-db(
  ) {
  system:as-user("admin", $settings:admin-password, 
    local:refresh-board-name-db(0)
  )
};

(: refresh the board name database. do not do this too often :)
declare function local:refresh-board-name-db(
  $start as xs:integer?
  ) {
  let $start := ($start, 0)[1]
  let $max-results := 60 (: the boards will not take a number > 60 :)
  let $return :=
    http:send-request(
      <http:request 
        href="http://www.stsf.net/forums/index.php?app=members&amp;module=list&amp;sort_key=members_display_name&amp;sort_order=asc&amp;max_results={$max-results}&amp;st={$start}" method="get"
          follow-redirect="true"
          >
      </http:request>
    )
  let $active-page := ($return//html:li[@class="page active"])[1]/number()
  let $n-pages := xs:integer(substring-after(($return//html:li[@class="page active"])[1]/preceding-sibling::html:li/html:a[@href="#"], "of "))
  let $this-page :=
    for $member in $return//html:ul[@class="ipsMemberList"]/html:li 
    let $member-number := xs:integer(substring-after($member/@id, "id_"))
    let $boardname := $member//html:h3/html:strong/html:a/string()
    let $db-member := doc($mem:board-db-uri)//m:boardname[m:number=$member-number]
    return (
      if (exists($db-member))
      then 
        if ($db-member/m:name = $boardname)
        then ( (: nothing to do... :) )
        else update value $db-member/m:name with $boardname 
      else
        update insert element m:boardname {
          element m:number { $member-number },
          element m:name { $boardname }
        } into doc($mem:board-db-uri)/*
    )
  return
    if ($active-page < $n-pages)
    then local:refresh-board-name-db($start + $max-results)
    else
      let $hint := doc($mem:board-db-uri)//m:last-start
      return 
        if (exists($hint))
        then
          (: this is a hint as to where to update from :)
          update value $hint with $start
        else
          update insert element m:last-start { $start }
          into doc($mem:board-db-uri)/*
};

declare function mem:member-number-by-board-name(
  $boardName as xs:string
  ) as xs:integer? {
  doc($mem:board-db-uri)//m:boardname[m:name=$boardName]/m:number
};

declare function mem:board-name-by-member-name(
  $member-name as xs:string
  ) as xs:string? {
  doc($mem:board-db-uri)//m:boardname
    [m:number=xs:integer(substring-after($member-name, '-'))]/m:name/string()
};

declare function mem:login-member(
  $member-number as xs:integer
  ) as xs:boolean? {
  let $member-name := mem:member-name($member-number)
  let $member-password := 
    system:as-user("admin", $settings:admin-password,
      doc($mem:member-db-uri)//m:member[m:number=$member-number]/m:password/string()
    )
  where $member-password
  return
    xmldb:login("/db", $member-name, $member-password, true()) 
};

declare function mem:logout-member(
  ) {
  session:invalidate()
};