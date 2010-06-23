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
* yaml
* erb
* [json](http://flori.github.com/json/)
* [pony](http://github.com/benprew/pony)
* [icalendar](http://icalendar.rubyforge.org/)

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
    mail:
      enabled: true
      from: "sheriffbot@mozilla.com"
    ical:
      enabled: true

### Database ###

The database schema is presented below and must be manually created. This might 
be moved to the Rakefile in the near future.

    CREATE TABLE `days` (
      `day` date NOT NULL,
      `sheriff_mail` varchar(128) NOT NULL,
      `updated` timestamp NOT NULL default '0000-00-00 00:00:00',
      `revisions` tinyint(4) NOT NULL default '0',
      PRIMARY KEY  (`day`),
      KEY `sheriff_mail` (`sheriff_mail`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;

    CREATE TABLE `sheriffs` (
      `mail` varchar(128) NOT NULL,
      `nick` varchar(128) NOT NULL,
      `fullname` varchar(128) NOT NULL,
      `email_notifications` tinyint(1) NOT NULL DEFAULT 1,
      `upcoming_duty_notifications` tinyint(1) NOT NULL DEFAULT 1,
      `days_in_advance_for_upcoming_duty` tinyint(5) UNSIGNED NOT NULL DEFAULT 2,
      PRIMARY KEY  (`mail`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;

    CREATE TABLE `subbings` (
      `id` varchar(32) NOT NULL,
      `subject_mail` varchar(128) NOT NULL,
      `object_mail` varchar(128) default NULL,
      `request` tinyint(1) NOT NULL,
      `fulfilled` tinyint(1) NOT NULL default '0',
      `day_day` date NOT NULL,
      `comment` longtext COLLATE utf8_general_ci NOT NULL,
      PRIMARY KEY  (`id`),
      KEY `subject_mail` (`subject_mail`),
      KEY `day_day` (`day_day`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;

    CREATE TABLE `sessions` (
      `sid` varchar(32) NOT NULL,
      `session` longtext COLLATE utf8_general_ci,
      `timestamp` timestamp NOT NULL DEFAULT '1970-01-01 00:00:01',
      PRIMARY KEY (`sid`),
      KEY `timestamp` (`timestamp`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;

### LDAP Authentication ###
The LDAP server is used in two ways:

* A user's credentials are used to bind to the LDAP server in order to confirm
that it is valid; after validation a session is initiated until they log out.
Other than this, the credentials are not used in any other way.

* The credentials in the config file (the `bind_dn` and `bind_password` fields) 
are currently used to prepopulate a sheriff's basic info (such as their full 
name) or by the various tasks in Rakefile.

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
Duty app to continue to function properly, or useful for maintenance activities
to be run as a cron job.

When run directly:

    $ rake

The tasks `next_week_assignment` and `upcoming_notification` are invoked by
default. These default tasks are meant to be run as a daily cron job.

### next_week_assignment ###
This task assigns more sheriff for next week and runs every Wednesday; for now 
it only fills one week ahead. It makes the assumption that no one specific is
sheriffing and `#developer` fills in on the weekends.

### upcoming_notification ###
This task is responsible for sending sheriffs emails `n` days before their duty 
depending how their preferences are set.

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

