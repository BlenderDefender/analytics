!function(){"use strict";var e,t,n,p=window.location,g=window.document,d=g.getElementById("plausible"),w=d.getAttribute("data-api")||(e=d.src.split("/"),t=e[0],n=e[2],t+"//"+n+"/api/event");function f(e){console.warn("Ignoring Event: "+e)}function a(e,t){try{if("true"===window.localStorage.plausible_ignore)return f("localStorage flag")}catch(e){}var n=d&&d.getAttribute("data-include"),a=d&&d.getAttribute("data-exclude");if("pageview"===e){var r=!n||n&&n.split(",").some(l),i=a&&a.split(",").some(l);if(!r||i)return f("exclusion rule")}function l(e){var t=p.pathname;return t+=p.hash,console.log(t),t.match(new RegExp("^"+e.trim().replace(/\*\*/g,".*").replace(/([^\.])\*/g,"$1[^\\s/]*")+"/?$"))}var o={};o.n=e,o.u=t&&t.u?t.u:p.href,o.d=d.getAttribute("data-domain"),o.r=g.referrer||null,o.w=window.innerWidth,t&&t.meta&&(o.m=JSON.stringify(t.meta)),t&&t.props&&(o.p=t.props);var u=d.getAttributeNames().filter(function(e){return"event-"===e.substring(0,6)}),s=o.p||{};u.forEach(function(e){var t=e.replace("event-",""),n=d.getAttribute(e);s[t]=s[t]||n}),o.p=s,o.h=1;var c=new XMLHttpRequest;c.open("POST",w,!0),c.setRequestHeader("Content-Type","text/plain"),c.send(JSON.stringify(o)),c.onreadystatechange=function(){4===c.readyState&&t&&t.callback&&t.callback()}}var r=window.plausible&&window.plausible.q||[];window.plausible=a;for(var i=0;i<r.length;i++)a.apply(this,r[i])}();