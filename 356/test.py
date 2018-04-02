#! /usr/bin/python
import dbus
import time;
bus = dbus.SessionBus()
conn = bus.get_object('org.navit_project.navit',
                       '/org/navit_project/navit')
iface = dbus.Interface(conn, dbus_interface='org.navit_project.navit');
iter=iface.iter();
navit=bus.get_object('org.navit_project.navit', conn.get_navit(iter));
iface.iter_destroy(iter);
navit_iface = dbus.Interface(navit, dbus_interface='org.navit_project.navit.navit');
time.sleep(1);
navit_iface.set_position('0x16ccae 0x692db8');
time.sleep(1);
navit_iface.set_destination('0x16d279 0x6922f5', '');
time.sleep(1);
navit_iface.set_center('0x16cdfa 0x6929d6');

