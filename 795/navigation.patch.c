Index: navigation.c
===================================================================
--- navigation.c	(Revision 5156)
+++ navigation.c	(Arbeitskopie)
@@ -933,6 +933,47 @@
 }
 
 /**
+ * @brief Returns if it possible to turn into a way that is the other direction or more straight than the route turn.
+ *
+ *
+ * @param from The navigation item which should form the start
+ * @param to The navigation item which should form the end
+ * @param angle_of_route angle is < 0 if route turns to the left and > 0 for turns to the right
+ * @return The number of possibilities to turn or -1 on error
+ */
+static int
+is_opposite_turn_possible(struct navigation *nav, struct navigation_itm *nav_itm, int angle_of_route)
+{
+	int count_left = 0, count_right = 0;
+	struct navigation_way *w;
+
+	if (!nav_itm) {
+		return -1;
+	}
+
+	w = nav_itm->way.next;
+	while (w) {
+          if (!way->flags || ((w->flags & nav->vehicleprofile->flags) == nav->vehicleprofile->flags)) {
+			// If a way is generally allowed for the vehicle take it into account. It's important
+			// to consider for announcing, even if it is a one-way in the reverse direction, for instance.
+			if (angle_delta(nav_itm->prev->angle_end, w->angle2) < angle_of_route) {
+				count_left++; // one more possibility to turn left or less right that the route.
+			} else {
+				count_right++; // one more possibility to turn right or less left that the route.
+			}
+		}
+		w = w->next;
+	}
+
+	if (angle_of_route >= 0) { // turn of route is right. Possible to turn left or drive straighter than the route?
+		return (count_left > 0);
+	} else {
+		return (count_right > 0);
+	}
+}
+
+
+/**
  * @brief Calculates distance and time to the destination
  *
  * This function calculates the distance and the time to the destination of a
@@ -1538,9 +1579,20 @@
 	}
 
 	if (delta < 0) {
-		/* TRANSLATORS: left, as in 'Turn left' */
-		dir=_("left");
+		// if there is a Y-junction and the right way also turn turns left, don't say 'left', but right.
+		if (is_opposite_turn_possible(nav, cmd->itm, delta) > 0) {
+			// TRANSLATORS: left, as in 'Turn left'
+			dir=_("left");
+		}
 		delta=-delta;
+	} else {
+		// This is turn 'right' as default, but also check a possible Y-junction, in which the left way
+		// keeps also slightly right. In this case if the street is really right or going just left on the map,
+		// but is the 'most left' possibility.
+		if (is_opposite_turn_possible(nav, cmd->itm, delta) == 0) {
+			// TRANSLATORS: left, as in 'Turn left'
+			dir=_("left");
+		}
 	}
 
 	if (strength_needed) {
