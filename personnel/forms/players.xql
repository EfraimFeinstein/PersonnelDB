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
import module namespace prs="http://stsf.net/xquery/personnel"
  at "/db/personnel/modules/personnel.xqm";
import module namespace site="http://stsf.net/xquery/site"
  at "/db/personnel/modules/site.xqm";
import module namespace settings="http://stsf.net/xquery/settings"
  at "/db/personnel/modules/settings.xqm";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace ev="http://www.w3.org/2001/xml-events";
declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace p="http://stsf.net/personnel/players";
declare namespace x="http://stsf.net/personnel/extended";

let $member-number := session:get-attribute("member-number")
let $player-id := request:get-parameter("player-id", $member-number)
let $new := not($player-id) or string($player-id) = "new"
let $is-gm := prs:is-game-master()
let $is-admin := prs:is-administrator() 
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
      <xf:instance id="new-character-instance">
        <p:character>
          <p:name/>
          <p:boardName/>
          <p:password/>
          <p:email/>
        </p:character>
      </xf:instance>
      <xf:instance id="new-character-result"/>
      <xf:instance id="player-result"/>
      <xf:instance id="access-rights-instance" src="{$settings:absolute-url-base}/queries/get-access-rights.xql?player-id={$player-id}">
      </xf:instance>
      <xf:bind nodeset="instance('access-rights-instance')/level/access" type="xf:boolean"/>
      <xf:instance id="application-instance">
        <x:applications>
          <x:application>
            <x:ship/>
            <x:department/>
            <x:position/>
            <x:player>{$player-id}</x:player>
            <x:character n=""/>
          </x:application>
        </x:applications>
      </xf:instance> 
      <xf:instance id="open-positions-instance" 
        src="{$settings:absolute-url-base}/queries/get-open-positions.xql"/>
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
          {
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
      <xf:submission 
        id="add-character-submit"
        resource="{$settings:absolute-url-base}/queries/add-character.xql?player-id={$player-id}"
        method="post"
        ref="instance('new-character-instance')"
        replace="instance"
        instance="new-character-result"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Character added successfully.</xf:message>
          <xf:setvalue ref="instance('new-character-instance')/*" value=""/>
          <xf:insert 
            nodeset="instance('player-instance')/*"
            at="last()"
            origin="instance('new-character-result')"
            />
        </xf:action>
        <xf:action ev:event="xforms-submit-error">
          <xf:message>Error: 
          <xf:output value="event('response-body')"/></xf:message>
        </xf:action>
      </xf:submission>
      <xf:submission 
        id="access-rights-submit"
        resource="{$settings:absolute-url-base}/queries/set-access-rights.xql?player-id={$player-id}"
        method="post"
        ref="instance('access-rights-instance')"
        replace="none"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Access rights changed successfully.</xf:message>
        </xf:action>
        <xf:action ev:event="xforms-submit-error">
          <xf:message>Error: 
          <xf:output value="event('response-body')"/></xf:message>
        </xf:action>
      </xf:submission>
      <xf:submission 
        id="application-submit"
        resource="{$settings:absolute-url-base}/queries/apply.xql"
        method="post"
        ref="instance('application-instance')"
        replace="none"
        >
        <xf:action ev:event="xforms-submit-done">
          <xf:message>Applied successfully.</xf:message>
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
    (
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
    </xf:group>,
    if ($is-admin and not($new))
    then
      <xf:group class="access-rights-editor" ref="instance('access-rights-instance')">
        <xf:label>Access rights editor</xf:label>
        <xf:repeat nodeset="level">
          <xf:output ref="name"/>
          <xf:input ref="access"/>
        </xf:repeat>
        <xf:trigger>
          <xf:label>Set rights</xf:label>
          <xf:send ev:event="DOMActivate" submission="access-rights-submit"/>
        </xf:trigger>
      </xf:group>
    else (),
    if ($new)
    then ()
    else (
      <h2>My characters</h2>,
      <xf:group class="new-character-editor" ref="instance('new-character-instance')">
        <xf:label>Add a new character:</xf:label>
        <xf:input ref="p:name">
          <xf:label>Name: </xf:label>
        </xf:input>
        <xf:input ref="p:boardName">
          <xf:label>Board name: </xf:label>
        </xf:input>
        <xf:secret ref="p:password">
          <xf:label>Board password: </xf:label>
        </xf:secret>
        <xf:input ref="p:email">
          <xf:label>E-mail: </xf:label>
        </xf:input>
        <xf:trigger>
          <xf:label>Add character</xf:label>
          <xf:send ev:event="DOMActivate" submission="add-character-submit"/>
        </xf:trigger>
      </xf:group>,
      <xf:group class="character-editor" ref="instance('player-instance')">
        <xf:repeat id="characters" nodeset="p:character">
          <xf:output ref="p:id">
            <xf:label>Member number: </xf:label>
          </xf:output>
          <xf:input ref="p:name">
            <xf:label>Name:</xf:label>
          </xf:input>
          <xf:input ref="p:email">
            <xf:label>E-mail address:</xf:label>
          </xf:input>
          {
            element { if ($is-admin) then "xf:input" else "xf:output" }{
              attribute ref { "p:boardName" },
              <xf:label>Board name:</xf:label>
            }
          }
          <xf:group class="assignment" ref="p:history">
            <xf:trigger ref=".[not(p:application)]|p:application[last()]/following-sibling::p:leave">
              <xf:label>Apply for a position</xf:label>
              <xf:show ev:event="DOMActivate" dialog="application-dialog"/>
            </xf:trigger>
            <xf:trigger ref="p:application[p:status='pending']">
              <xf:label>Add an additional application</xf:label>
              <xf:show ev:event="DOMActivate" dialog="application-dialog"/>
            </xf:trigger>
            <xf:trigger ref="p:application[p:status='approved'][last()][not(following-sibling::p:leave)]">
              <xf:label>Apply for a transfer</xf:label>
              <xf:show ev:event="DOMActivate" dialog="application-dialog"/>
            </xf:trigger>
            <xf:trigger ref="p:application[last()][p:status='approved'][not(following-sibling::p:leave)]">
              <xf:label>Go on extended leave</xf:label>
            </xf:trigger>
          </xf:group>
          <xf:dialog id="application-dialog">
            <xf:select1 ref="instance('application-instance')/x:application/x:ship" appearance="compact">
              <xf:label>Ship:</xf:label>
              <xf:itemset nodeset="instance('open-positions-instance')//x:ship">
                <xf:label ref="s:name"/>
                <xf:value ref="s:name"/>
              </xf:itemset>
            </xf:select1>
            <xf:select1 ref="instance('application-instance')/x:application/x:department" appearance="compact">
              <xf:label>Department:</xf:label>
              <xf:itemset nodeset="instance('open-positions-instance')//x:ship[s:name=instance('application-instance')/x:application/x:ship]/x:department">
                <xf:label ref="s:name"/>
                <xf:value ref="s:name"/>
              </xf:itemset>
            </xf:select1>
            <xf:select1 ref="instance('application-instance')/x:application/x:position" appearance="compact">
              <xf:label>Position:</xf:label>
              <xf:itemset nodeset="instance('open-positions-instance')//x:ship[s:name=instance('application-instance')/x:application/x:ship]/x:department[s:name=instance('application-instance')/x:application/x:department]/x:position">
                <xf:label ref="s:name"/>
                <xf:value ref="s:id"/>
              </xf:itemset>
            </xf:select1>
            <xf:trigger>
              <xf:label>Apply</xf:label>
              <xf:action ev:event="DOMActivate">
                <xf:setvalue ref="instance('application-instance')/x:application/x:player" value="context()/ancestor::p:player/p:id"/>
                <xf:setvalue ref="instance('application-instance')/x:application/x:character" value="context()/ancestor::p:player/p:character[index('characters')]/p:id"/>
                <xf:setvalue ref="instance('application-instance')/x:application/x:character/@n" value="count(context()/ancestor::p:player/p:character[index('characters')]/preceding-sibling::p:character[p:id=instance('application-instance')/x:application/x:character]) + 1"/>
                <xf:hide dialog="application-dialog"/>
                <xf:send submission="application-submit"/>
              </xf:action>
            </xf:trigger>
            <xf:trigger>
              <xf:label>Cancel</xf:label>
              <xf:hide ev:event="DOMActivate" dialog="application-dialog"/>
            </xf:trigger>
          </xf:dialog>
        </xf:repeat>
      </xf:group>
    )
    )
  )