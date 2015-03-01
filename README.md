# spy-glass (aka Citygram connector)

__Spyglass__  is a [Code for America](https://github.com/codeforamerica) project by the [Charlotte Team](http://team-charlotte.tumblr.com/) for the [2014 fellowship](http://www.codeforamerica.org/geeks/our-geeks/2014-fellows/).

### What does this do now?

This is a registry of micro ETL endpoints. What does that even mean? Good question. Citygram has good [overview documentation](https://github.com/codeforamerica/citygram/wiki/Getting-Started-with-Citygram). 

But here's a specific example of the information flow:

[CKAN code enforcement](https://www.google.com/webhp?sourceid=chrome-instant&ion=1&espv=2&es_th=1&ie=UTF-8#q=311%20open%20data%20socrata&es_th=1)  -> [Citygram connector](https://github.com/BetaNYC/citygram-services-nyc/blob/nyc-updates/lib/spy_glass/registry/nyc-311.rb) -> [Citygram](https://www.citygram.nyc/)

This particular Citygram connector pulls the [last seven days worth](https://github.com/citygram/citygram-services/blob/master/lib/spy_glass/registry/lexington-code-enforcement-complaints.rb#L7) of code complaints and [formats them as geojson](https://citygram-services.herokuapp.com/) that Citygram polls many times a day.

It creates a unique key that [is a composite](https://github.com/BetaNYC/citygram-services-nyc/blob/nyc-updates/lib/spy_glass/registry/nyc-311.rb#L45) of the CaseNo and Status columns. When this key changes, Citygram will create a new event that will be sent to subscribers. Since the key is a composite, an event is created whenever a status changes for a given case. 

### Why are we doing this?

TODO

### What will this do in the future?

TODO

### How to contribute

- You can file an [issue](https://github.com/BetaNYC/citygram-services-nyc/issues/new).
- Join in the conversation at [talk.beta.nyc/citygram](https://talk.beta.nyc/c/working-groups/citygram).

### Who is this made by?

See the [contributors list](https://github.com/BetaNYC/citygram-services-nyc/graphs/contributors).

### Technical Overview

TODO

### Setup

* [Install Ruby](https://github.com/codeforamerica/howto/blob/master/Ruby.md)

```
git clone https://github.com/citygram/citygram-services.git
cd citygram-services
cp .env.sample .env
gem install bundler
bundle install
bundle exec rackup
```
You can now see your site at [http://localhost:9292/](http://localhost:9292/)
