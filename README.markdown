Mozilla Sheriff Duty
====================
Mozilla Sheriff Duty is a Sinatra-based web app for managing sheriff duty 
amongst sheriffs at Mozilla.

Requirements
------------
Sheriff Duty uses several Ruby gems:

* [sinatra](http://www.sinatrarb.com/)
* [net/ldap](http://github.com/RoryO/ruby-net-ldap)
* [sequel](http://sequel.rubyforge.org/)
  * [mysql](http://www.tmtm.org/en/mysql/ruby/)
* [json](http://flori.github.com/json/)
* [pony](http://github.com/benprew/pony)
  * [tlsmail](http://rubyforge.org/projects/tlsmail/) on Ruby < 1.8.7
* [icalendar](http://icalendar.rubyforge.org/)
* [rack-flash](http://github.com/nakajima/rack-flash)
* [rack-ssl-enforcer](http://github.com/tobmatth/rack-ssl-enforcer)

Most gems can be installed by simply running:

    $ gem install <gem_name>

`sudo` at your own discretion. On Ruby < 1.8.7, some gems may not install and 
complain about your Ruby version being too old. In that case, run:

    $ gem install <gem_name> -f

This forces `gem` to proceed with the installation.

Configuration
-------------
Use the included `config-sample.yaml` file as a template to create 
`config.yaml`. The file should look like this:

    db:
      driver: "mysql"
      host: ""
      username: ""
      password: ""
      database: ""
    ldap:
      host: "pm-ns.mozilla.org"
      port: 389
      bind_dn: ""
      bind_password: ""
    ssl:
      enforced: true
    mail:
      enabled: true
      from: "sheriffbot@mozilla.com"
    ical:
      enabled: true

### Database ###

The database schema can be set up using the `db_setup` task present in the 
Rakefile.

### LDAP Authentication ###
The LDAP server is used in two ways:

* A user's credentials are used to bind to the LDAP server in order to confirm
that it is valid; after validation a session is initiated until they log out.
Other than this, the credentials are not used in any other way.

* The credentials in the config file (the `bind_dn` and `bind_password` fields) 
are currently used to prepopulate a sheriff's basic info (such as their full 
name) or by the various tasks in Rakefile.

### SSL Enforcement ###
SSL enforcement redirects all plain-text requests to their equivalent SSL URLs.
It should be enabled as a good practice; it is particularly dangerous to send
LDAP credentials in clear over the wire.

### Email Notification ###
The `pony` gem is used to send out email notifications for sheriffs who have 
the option enabled. The `from` field is in standard RFC format, i.e. the
following is valid:

      from: "\"The Happy Sheriffbot\" <sheriffbot@mozilla.org>"

### iCal Feeds ###
The `icalendar` gem is used for providing iCal feeds. It can be optionally 
disabled; the feature would then disappear from the UI.

Running on Passenger
--------------------
The template files for the `config.ru` used by Phusion Passenger (mod_rails) 
are `production.ru` and `development.ru`.

Rakefile
--------
The Rakefile contains various tasks that are either necessary for the Sheriff 
Duty app to continue to function properly, or useful for maintenance activities.

When run directly:

    $ rake

The tasks `next_week_assignment` and `upcoming_notification` are invoked by
default. These default tasks are meant to be run as a daily cron job.

### next_week_assignment ###
This task assigns more sheriff for following weeks and runs every Wednesday; 
run it like this:

    $ rake next_week_assignment weeks_ahead=2

Without the `weeks_ahead` parameter it only fills one week ahead. It also makes 
the assumption that on the weekends, no one specific is sheriffing and 
`#developer` fills in.

### upcoming_notification ###
This task is responsible for sending sheriffs emails `n` days before their duty 
depending how their preferences are set.

### setup_db ###
This task creates the necessary tables in the database. It requires the 
database settings to be filled out correctly in `config.yaml`.

### populate_fullnames ###
This task searches for sheriffs who don't have their fullname filled in and 
does so by looking them up on the LDAP server and pulling in the `cn` field.

### import_from_google_calendar ###
This task should be run with the `feed` parameter, a URL to an iCal feed:

    $ rake import_from_google_calendar feed=http://example.com/ical/feed.ics

When run with no `feed` parameter, [this iCal feed][1] is used by default.
Since an iCal can contain several calendars, the first calendar is assumed.
Every day in the calendar is then scanned:

* If the `summary` of the day equals `#developers`, it is skipped.
* The `dtstart` attribute is considered to be the date of the day.
* The sheriff on a given day is extracted from the `summary` attribute.
  * Everything before the first opening parentheses is trimmed and then assumed
  to be the _full name_, the `cn` of a sheriff.
  * Everything contained between the last pair of parentheses is trimmed and
  considered to be the _nick_ of the sheriff.

Since a sheriff is identified by the email address in the database, simply 
knowing the full name or the nick of a sheriff is not enough. The email address 
of a sheriff is looked up on the LDAP server in this order:

* The _full name_ matches the `cn` attribute.
* The _nick_ is a substring of the `cn` attribute.
* The _nick_ is a substring of the `im` attribute.

If none of the above occur, the sheriff / day is skipped and this is indicated
in stderr. Additionally when a condition described above occurs but more than
one entries match said condition, the sheriff / day is also skipped.

[1]: http://www.google.com/calendar/ical/j6tkvqkuf9elual8l2tbuk2umk%40group.calendar.google.com/public/basic.ics

