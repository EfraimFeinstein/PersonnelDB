xquery version "3.0";
(: players and characters form
 : 
 : Calling this without any parameters shows all players
 : Calling it with ?player-id=number shows only that player
 : Administrators can see and edit all players, non-administrators can
 :  only see and edit their own.
 :
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License
 :)
import module namespace site="http://stsf.net/xquery/site"
  at "/db/personnel/modules/site.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "/db/personnel/modules/settings.xqm";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace ev="http://www.w3.org/2001/xml-events";
declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace p="http://stsf.net/personnel/players";

let $member-number := session:get-attribute("member-number")
let $player-id := request:get-parameter("player-id", $member-number)
let $new := not($player-id) or string($player-id) = "new" 
return
  site:form(
    <xf:model>
      <xf:instance id="player-instance">{
        if ($new)
        then
          <p:player>
            <p:name/>
            <p:boardName/>
            <p:email/>
          </p:player>
        else
          attribute src { concat($settings:absolute-url-base, "/queries/get-player.xql?player-id=", $player-id) }
      }</xf:instance>
      <xf:instance id="player-result"/>
      <xf:submission 
        id="player-submit"
        resource="{$settings:absolute-url-base}/queries/{
          if ($new)
          then "add-player.xql"
          else concat("edit-player.xql?player-id=", $player-id)
        }"
        method="post"
        ref="instance('player-instance')"
        replace="instance"
        instance="player-instance"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Player {
            if ($new)
            then "added"
            else "edited"
          } successfully.</xf:message>
          { (: TODO: :)
            if ($new)
            then
              <xf:load>
                <xf:resource value="concat('{$settings:absolute-url-base}/forms/players?player-id=', instance('player-instance')/p:id)"/>
              </xf:load>
            else ()
          }
        </xf:action>
        <xf:action ev:event="xforms-submit-error">
          <xf:message>Error: 
          <xf:output value="event('response-body')"/></xf:message>
        </xf:action>
      </xf:submission>
    </xf:model>,
    <title>{
      if ($new)
      then "Add new player"
      else "Edit player"
    }</title>,
    <xf:group class="player-editor" ref="instance('player-instance')">
      <xf:output ref="p:id">
        <xf:label>Member number: </xf:label>
      </xf:output>
      <xf:input ref="p:boardName">
        <xf:label>Board name:</xf:label>
      </xf:input>
      <xf:input ref="p:name">
        <xf:label>Full name:</xf:label>
      </xf:input>
      <xf:input ref="p:email">
        <xf:label>Contact email: </xf:label>
      </xf:input>
      <xf:trigger>
        <xf:label>{
          if ($new)
          then "Add player"
          else "Edit player"
        }</xf:label>
        <xf:send ev:event="DOMActivate" submission="player-submit"/>
      </xf:trigger>
    </xf:group>
  )