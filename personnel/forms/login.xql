xquery version "3.0";
(: login form
 : Copyright 2012 Efraim Feinstein <efraim.feinstein@gmail.com>
 : Licensed under the GNU Lesser General Public License
 :)
import module namespace site="http://stsf.net/xquery/site"
  at "/db/personnel/modules/site.xqm";

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace ev="http://www.w3.org/2001/xml-events";
declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace html="http://www.w3.org/1999/xhtml";

site:form(
  <xf:model>
    <xf:instance id="login-instance">
      <login xmlns="">
        <user/>
        <password/>
      </login>
    </xf:instance>
    <xf:instance id="login-result"/>
    <xf:submission 
      id="login-submit"
      resource="/exist/rest/db/personnel/queries/login.xql"
      method="post"
      ref="instance('login-instance')"
      replace="none"
      >
      <xf:action ev:event="xforms-submit-done">
        <xf:message>Done (TODO:load players page)</xf:message>
      </xf:action>
      <xf:action ev:event="xforms-submit-error">
        <xf:message>Login error: 
        <xf:output value="event('response-body')"/></xf:message>
      </xf:action>
    </xf:submission>
  </xf:model>,
  <title>Login</title>,
  <xf:group class="login" ref="instance('login-instance')">
    <xf:input ref="user">
      <xf:label>User name:</xf:label>
    </xf:input>
    <xf:secret ref="password">
      <xf:label>Password:</xf:label>
    </xf:secret>
    <xf:trigger>
      <xf:label>Login</xf:label>
      <xf:send ev:event="DOMActivate" submission="login-submit"/>
    </xf:trigger>
  </xf:group>
)