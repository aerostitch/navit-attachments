-- SQL to rename / merge trac users

--create table rename_user (oldname varchar(1000), newname varchar(1000), keep_session int, primary key (oldname));
-- Insert the users to be renamed into rename_user.
-- oldname and newname should be self-explanatory. 
-- About keep_session:
-- For renaming an account, set keep_session=1.
-- For merging multiple accounts, use the same newname for all accounts,
-- and set keep_session=0 for all but one account. The account with
-- keep_session=1 is the one whose account information (name, email,
-- OpenID etc.) will be kept for the merged acount.

update attachment set author=(select r.newname from rename_user r where r.oldname=attachment.author)
where attachment.author in (select r2.oldname from rename_user r2);
update component set owner=(select r.newname from rename_user r where r.oldname=component.owner)
where component.owner in (select r2.oldname from rename_user r2);
update report set author=(select r.newname from rename_user r where r.oldname=report.author)
where report.author in (select r2.oldname from rename_user r2);
update revision set author=(select r.newname from rename_user r where r.oldname=revision.author)
where revision.author in (select r2.oldname from rename_user r2);
update ticket set reporter=(select r.newname from rename_user r where r.oldname=ticket.reporter)
where ticket.reporter in (select r2.oldname from rename_user r2);
update ticket set owner=(select r.newname from rename_user r where r.oldname=ticket.owner)
where ticket.owner in (select r2.oldname from rename_user r2);
update ticket_change set author=(select r.newname from rename_user r where r.oldname=ticket_change.author)
where ticket_change.author in (select r2.oldname from rename_user r2);
update ticket_change set oldvalue=(select r.newname from rename_user r where r.oldname=ticket_change.oldvalue)
where ticket_change.oldvalue in (select r2.oldname from rename_user r2) and ticket_change.field in ('reporter', 'owner');
update ticket_change set newvalue=(select r.newname from rename_user r where r.oldname=ticket_change.newvalue)
where ticket_change.newvalue in (select r2.oldname from rename_user r2) and ticket_change.field in ('reporter', 'owner');
update wiki set author=(select r.newname from rename_user r where r.oldname=wiki.author)
where wiki.author in (select r2.oldname from rename_user r2);

-- ----------------
-- accounts to be deleted:

delete from session_attribute where authenticated=1 and
sid in (select r2.oldname from rename_user r2  where keep_session=0);
delete from session where authenticated=1 and
sid in (select r2.oldname from rename_user r2  where keep_session=0);
delete from permission where
username in (select r2.oldname from rename_user r2  where keep_session=0);

-- ----------------

-- account to be renamed:
update session_attribute set sid=(select r.newname from rename_user r where r.oldname=session_attribute.sid)
where session_attribute.sid in (select r2.oldname from rename_user r2 where keep_session=1) and session_attribute.authenticated=1;
update session set sid=(select r.newname from rename_user r where r.oldname=session.sid)
where session.sid in (select r2.oldname from rename_user r2  where keep_session=1) and session.authenticated=1;
update permission set username=(select r.newname from rename_user r where r.oldname=permission.username)
where permission.username in (select r2.oldname from rename_user r2  where keep_session=1);

drop table rename_user;
