# spy-glass (aka Citygram connector)

__Spyglass__  is a [Code for America](https://github.com/codeforamerica) project by the [Charlotte Team](http://team-charlotte.tumblr.com/) for the [2014 fellowship](http://www.codeforamerica.org/geeks/our-geeks/2014-fellows/).

### Why are we doing this?


### What does this do now?

This is a registry of micro ETL endpoints. What does that even mean? Good question. Citygram has good [overview documentation](https://github.com/codeforamerica/citygram/wiki/Getting-Started-with-Citygram). 

But here's a specific example of the information flow:

[CKAN code enforcement](http://www.civicdata.com/dataset/lexington-code-enforcement-complaints)  -> [Citygram connector](https://github.com/citygram/citygram-services/blob/master/lib/spy_glass/registry/lexington-code-enforcement-complaints.rb) -> [Citygram](https://www.citygram.org/lexington)

This particular Citygram connector pulls the [last seven days worth](https://github.com/citygram/citygram-services/blob/master/lib/spy_glass/registry/lexington-code-enforcement-complaints.rb#L7) of code complaints and [formats them as geojson](https://citygram-services.herokuapp.com/) that Citygram polls many times a day.

It creates a unique key that [is a composite](https://github.com/citygram/citygram-services/blob/master/lib/spy_glass/registry/lexington-code-enforcement-complaints.rb#L25) of the CaseNo and Status columns. When this key changes, Citygram will create a new event that will be sent to subscribers. Since the key is a composite, an event is created whenever a status changes for a given case. 

### What will this do in the future?

TODO

### Who is this made by?
- [Danny Whalen](https://github.com/invisiblefunnel)
- [Erik Schwartz](https://github.com/eeeschwartz)

### Setup

* [Install Ruby](https://github.com/codeforamerica/howto/blob/master/Ruby.md)

```
git clone https://github.com/citygram/citygram-services.git
cd citygram-services
cp .env.sample .env
gem install bundler
bundle install
bundle exec rake db:create db:migrate
bundle exec rackup
```

### Vagrant

You can setup a dev server with postres setup with Vagrant:

```
vagrant up
vagrant ssh
cd /vagrant
bundle exec rackup
```
