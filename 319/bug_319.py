#! /usr/bin/python
import dbus
import time
bus = dbus.SessionBus()
conn = bus.get_object('org.navit_project.navit',
                       '/org/navit_project/navit')
iface = dbus.Interface(conn, dbus_interface='org.navit_project.navit');
iter=iface.iter();
navit=bus.get_object('org.navit_project.navit', conn.get_navit(iter));
iface.iter_destroy(iter);
navit_iface = dbus.Interface(navit, dbus_interface='org.navit_project.navit.navit');
navit_iface.set_destination((1, 0xc1c116, 0x26e33a), 'bla'); 
navit_iface.set_center((1, 0xc1b969, 0x26c9a1));
navit_iface.set_position((1, 0xc1b969, 0x26c9a1));
#navit_iface.set_center((1, 0xc1c116, 0x26e33a));
#navit_iface.set_position((1, 0x1611bc, 0x5c29a2));
