/*
This will clean up the Trac SIDs (user names) in Navit's Trac.
Goals:
* clean up the SIDs consisting of an URI
* join SIDs based on the same OpenID URI

See http://trac.navit-project.org/ticket/1140 for details.

To use:
* first run this file (.read trac-user-name-cleanup.sql), to build the
  renaming table
* then run rename-users-trac.sql , which performs the rename

*/

-- Preliminary cleanup: 
-- Delete user accounts that never wrote anything (ticket, comment etc.)
-- and have not logged in since January 2015.

drop table if exists sid_with_data;
create table sid_with_data (sid varchar primary key);

insert into sid_with_data
SELECT author from attachment
UNION SELECT author from attachment
UNION SELECT owner from component
UNION SELECT username from permission
UNION SELECT author from report
UNION SELECT author from revision
UNION SELECT reporter from ticket
UNION SELECT owner from ticket
UNION SELECT author from ticket_change
UNION SELECT oldvalue from ticket_change where  field in ('reporter', 'owner')
UNION SELECT newvalue from ticket_change where  field in ('reporter', 'owner')
UNION SELECT author from wiki;
delete from sid_with_data where sid is NULL;

delete from session where authenticated=1 and sid not in 
(select sid from sid_with_data) and last_visit<1420066800;
delete from session_attribute where authenticated=1 and sid not in 
(select sid from session where authenticated=1);

-- Create list of SIDs that look like a URI, and simplify them.
-- For the Navit wiki and launchpad.net extract the user name from the URI.
drop table if exists httpsids;
PRAGMA case_sensitive_like = TRUE;
create table httpsids (sid varchar primary key, newsid varchar);
insert into httpsids (sid, newsid) select sid, replace(sid, 'http://wiki.navit-project.org/index.php/user:', '')
from session where sid like 'http://wiki.navit-project.org/index.php/user:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'https://wiki.navit-project.org/index.php/user:', '')
from session where sid like 'https://wiki.navit-project.org/index.php/user:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'http://wiki-new.navit-project.org/index.php/user:', '')
from session where sid like 'http://wiki-new.navit-project.org/index.php/user:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'https://wiki-new.navit-project.org/index.php/user:', '')
from session where sid like 'https://wiki-new.navit-project.org/index.php/user:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'http://wiki.test.navit-project.org/index.php/user:', '')
from session where sid like 'http://wiki.test.navit-project.org/index.php/user:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'https://wiki.test.navit-project.org/index.php/user:', '')
from session where sid like 'https://wiki.test.navit-project.org/index.php/user:%' and authenticated=1;

insert into httpsids (sid, newsid) select sid, replace(sid, 'http://wiki.navit-project.org/index.php/User:', '')
from session where sid like 'http://wiki.navit-project.org/index.php/User:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'https://wiki.navit-project.org/index.php/User:', '')
from session where sid like 'https://wiki.navit-project.org/index.php/User:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'http://wiki-new.navit-project.org/index.php/User:', '')
from session where sid like 'http://wiki-new.navit-project.org/index.php/User:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'https://wiki-new.navit-project.org/index.php/User:', '')
from session where sid like 'https://wiki-new.navit-project.org/index.php/User:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'http://wiki.test.navit-project.org/index.php/User:', '')
from session where sid like 'http://wiki.test.navit-project.org/index.php/User:%' and authenticated=1;
insert into httpsids (sid, newsid) select sid, replace(sid, 'https://wiki.test.navit-project.org/index.php/User:', '')
from session where sid like 'https://wiki.test.navit-project.org/index.php/User:%' and authenticated=1;

insert into httpsids (sid, newsid) select sid, replace(sid, 'https://launchpad.net/~', '')
from session where sid like 'https://launchpad.net/~%' and authenticated=1;

insert into httpsids (sid, newsid) select sid, replace(sid, 'http://', '')
from session where sid like 'http://%' and authenticated=1
and sid not in (select sid from httpsids);
insert into httpsids (sid, newsid) select sid, replace(sid, 'https://', '')
from session where sid like 'https://%' and authenticated=1
and sid not in (select sid from httpsids);

PRAGMA case_sensitive_like = FALSE;

update httpsids set newsid=rtrim(newsid, '/');

-- Find accounts with identical or equivalent OpenID URI. 
-- URI is taken from session_attribute or from the SID.
drop table if exists oidurls;
create table oidurls (sid varchar primary key, normalurl varchar);
insert into oidurls (sid, normalurl) select sid, value from session_attribute
where name='openid_session_identity_url_data' and authenticated=1;
insert into oidurls (sid, normalurl) select sid, sid from session
where sid  like 'http%' and sid not in (select sid from oidurls);

-- Normalize URIs, to make equivalent URIs identical.
update oidurls set normalurl=lower(normalurl);
update oidurls set normalurl=replace(normalurl,'https','http');
update oidurls set normalurl=replace(normalurl,'wiki-new.navit-project.org','wiki.navit-project.org');
update oidurls set normalurl=replace(normalurl,'wiki.test.navit-project.org','wiki.navit-project.org');
-- ----------------------------
-- Check for conflicting SIDs because of the simplification.
-- Idea: For all SIDs which are mapped to the same SID, find the
-- corresponding OpenID URI (if available).
-- Result: new SID, OpenID URI for old SID, old SID
/*
select httpsids.newsid, coalesce(oidurls.normalurl, '-NO URI-'), httpsids.sid from httpsids
left join oidurls on httpsids.sid=oidurls.sid where httpsids.sid in  (
  select sid from httpsids where newsid in (select  newsid from httpsids group by newsid having count(*)>1 )
);
*/
-- -> Result: No conflicts :-).


drop table if exists rename_user;
create table rename_user (oldname varchar(1000), newname varchar(1000), keep_session int, primary key (oldname));

-- Join SIDs with equivalent OpenID URIs.
-- * group by "normalurl"
-- * find max(last_visit) for each group
-- * find SID corresponding to max(last_visit)
insert into rename_user (oldname, newname, keep_session)
select o.sid, (select s3.sid from session s3 where s3.last_visit=(
    select max(last_visit) from oidurls o2 join session s2
    on o2.sid=s2.sid and s2.authenticated=1 where o2.normalurl=o.normalurl
    )) as newsid, 0
from oidurls o; 
-- We keep the SID with latest login date. That is the SID that does not
-- change, so we don't need to do anything with it.
delete from rename_user where oldname=newname; 

-- Simplify SIDs as described in httpsids

-- For existing rename records change "newname" as appropriate.
update rename_user set newname=coalesce(
  (select h.newsid from httpsids h where h.sid=rename_user.newname),
  rename_user.newname);

-- If there is no rename record yet, insert one.
insert into rename_user (oldname, newname, keep_session)
select h.sid, h.newsid,1 from httpsids h
where h.sid not in (select oldname from rename_user);

-- Fix conflicts with existing SIDs

-- Build table of conflicting SID
-- "Conflicting" means: SID exists in session table and in rename_user.newname.
drop table if exists conflict_sid;
create table conflict_sid (sid varchar primary key, hasurl int);
insert into conflict_sid
select s.sid, exists (select * from oidurls o where o.sid=s.sid)
from session s where s.authenticated=1 
and exists (select * from rename_user ru where ru.newname=s.sid and ru.keep_session=1)
and not exists (select * from rename_user ru2 where ru2.oldname=s.sid);

-- Delete SIDs without an OpenID URI (those cannot login anyway)
with nourl as (
  select cs.sid from conflict_sid cs where cs.hasurl=0
) insert into rename_user (oldname,newname,keep_session)  select sid,sid,0 from nourl;
 
-- If OpenID URI is available (which will then be different for the two conflicting SIDs)
-- -> rename SID with older last_visit (-> -2-)

-- last_visit older for existing SID -> rename it, thus new record in rename_user
insert into rename_user (oldname, newname, keep_session)
select sid, sid||' -2-',1 from (
  with hasurl as (
    select cs.sid from conflict_sid cs where cs.hasurl=1
  ) select h.sid, s.last_visit lv_exist, ru.oldname, s2.last_visit lv_neu from hasurl h
  join session s on s.sid=h.sid and s.authenticated=1
  join rename_user ru on ru.newname=h.sid and ru.keep_session=1
  join session s2 on s2.authenticated=1 and s2.sid=ru.oldname
) bla where lv_exist<lv_neu;

-- last_visit older for new SID (for rename) -> rename it, thus change record in rename_user
update rename_user set newname=newname||' -2-' where oldname in (
  select oldname from (
    with hasurl as (
      select cs.sid from conflict_sid cs where cs.hasurl=1
    ) select h.sid, s.last_visit lv_exist, ru.oldname, s2.last_visit lv_neu from hasurl h
    join session s on s.sid=h.sid and s.authenticated=1
    join rename_user ru on ru.newname=h.sid
    join session s2 on s2.authenticated=1 and s2.sid=ru.oldname
  ) bla where lv_exist>=lv_neu);

-- Special cases for cp15 and sleske
insert into rename_user (oldname, newname, keep_session) values
('sleske', 'sleske', 0), ('sleske (2)', 'sleske', 1);
update rename_user set newname='cp15', keep_session=0 where oldname in ('cp15','Cp15');

-- Cleanup
drop table sid_with_data;
drop table httpsids;
drop table oidurls;
drop table conflict_sid;
