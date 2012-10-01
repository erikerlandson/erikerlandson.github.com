---
layout: page
title: "planet"
date: 2012-09-27 12:42
comments: true
sharing: true
footer: true
---

{% rssfeed url:http://erikerlandson.github.com/blog/categories/computing/atom.xml count:15 ttl:3600 %}
  {{ item.link }}
  {{ item.day }}
  {{ item.description }} 
{% endrssfeed %}
