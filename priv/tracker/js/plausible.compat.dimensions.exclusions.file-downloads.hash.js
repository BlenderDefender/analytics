!function(){"use strict";var e,t,i,u=window.location,d=window.document,f=d.getElementById("plausible"),g=f.getAttribute("data-api")||(e=f.src.split("/"),t=e[0],i=e[2],t+"//"+i+"/api/event");function w(e){console.warn("Ignoring Event: "+e)}function a(e,t){if(/^localhost$|^127(\.[0-9]+){0,2}\.[0-9]+$|^\[::1?\]$/.test(u.hostname)||"file:"===u.protocol)return w("localhost");if(!(window._phantom||window.__nightmare||window.navigator.webdriver||window.Cypress)){try{if("true"===window.localStorage.plausible_ignore)return w("localStorage flag")}catch(e){}var i=f&&f.getAttribute("data-include"),a=f&&f.getAttribute("data-exclude");if("pageview"===e){var n=!i||i&&i.split(",").some(c),r=a&&a.split(",").some(c);if(!n||r)return w("exclusion rule")}var o={};o.n=e,o.u=u.href,o.d=f.getAttribute("data-domain"),o.r=d.referrer||null,o.w=window.innerWidth,t&&t.meta&&(o.m=JSON.stringify(t.meta)),t&&t.props&&(o.p=t.props);var l=f.getAttributeNames().filter(function(e){return"event-"===e.substring(0,6)}),p=o.p||{};l.forEach(function(e){var t=e.replace("event-",""),i=f.getAttribute(e);p[t]=p[t]||i}),o.p=p,o.h=1;var s=new XMLHttpRequest;s.open("POST",g,!0),s.setRequestHeader("Content-Type","text/plain"),s.send(JSON.stringify(o)),s.onreadystatechange=function(){4===s.readyState&&t&&t.callback&&t.callback()}}function c(e){var t=u.pathname;return t+=u.hash,console.log(t),t.match(new RegExp("^"+e.trim().replace(/\*\*/g,".*").replace(/([^\.])\*/g,"$1[^\\s/]*")+"/?$"))}}var n=["pdf","xlsx","docx","txt","rtf","csv","exe","key","pps","ppt","pptx","7z","pkg","rar","gz","zip","avi","mov","mp4","mpeg","wmv","midi","mp3","wav","wma"],r=f.getAttribute("file-types"),o=f.getAttribute("add-file-types"),l=r&&r.split(",")||o&&o.split(",").concat(n)||n;function p(e){for(var t=e.target,i="auxclick"===e.type&&2===e.which,a="click"===e.type;t&&(void 0===t.tagName||"a"!==t.tagName.toLowerCase()||!t.href);)t=t.parentNode;var n,r=t&&t.href&&t.href.split("?")[0];r&&(n=r.split(".").pop(),l.some(function(e){return e===n}))&&((i||a)&&plausible("File Download",{props:{url:r}}),t.target&&!t.target.match(/^_(self|parent|top)$/i)||e.ctrlKey||e.metaKey||e.shiftKey||!a||(setTimeout(function(){u.href=t.href},150),e.preventDefault()))}d.addEventListener("click",p),d.addEventListener("auxclick",p);var s=window.plausible&&window.plausible.q||[];window.plausible=a;for(var c,v=0;v<s.length;v++)a.apply(this,s[v]);function h(){c=u.pathname,a("pageview")}window.addEventListener("hashchange",h),"prerender"===d.visibilityState?d.addEventListener("visibilitychange",function(){c||"visible"!==d.visibilityState||h()}):h()}();