Index: navit.c
===================================================================
--- navit.c    (revision 3744) 
+++ navit.c    (working copy) 
@@ -735,6 +735,94 @@
     }
 }
 
+static void 
+navit_cmd_sys_cmd(struct navit *this, char *function, struct attr **in, struct attr ***out, int *valid) 
+{ 
+    navit_float x, y; 
+    char *cx, *cy; 
+    FILE * fp; 
+    int n, nparms, number_parms, no_default_parms, validpos; 
+    const char ** user_parms; 
+    struct attr valid_attr, geo_attr; 
+ 
+     
+    validpos = 1; 
+    no_default_parms = 0; 
+ 
+ 
+    nparms=0; 
+ 
+    if(in) 
+        { 
+            while(in[nparms]) 
+                { 
+                    if (in && in[nparms] && ATTR_IS_STRING(in[nparms]->type) && in[nparms]->u.str) 
+                        { 
+                            if(strstr(in[nparms]->u.str,"NO_DEFAULT_PARMS")) 
+                                { 
+                                    no_default_parms=1; 
+                                    break; 
+                                } 
+                        } 
+                    else 
+                        { 
+                            fprintf(stderr, "Incorrect parameter %i in a call to a %s() function.\nPlease, ensure that each parameter is enclosed by double quotes.\n", nparms + 1, function); 
+                            return; 
+                        } 
+                    nparms++; 
+                } 
+            if(!no_default_parms) 
+                { 
+                    /* Currently latitude, longitude and NULL */ 
+                    number_parms = nparms + 3; 
+                } 
+            else 
+                number_parms = nparms + 1; 
+             
+            user_parms = malloc((number_parms) * sizeof(const char **)); 
+            if (!user_parms) 
+                return; 
+             
+            for (n=0; n<nparms; n++) 
+                { 
+                    user_parms[n] = (const char *) in[n]->u.str; 
+                } 
+            if (!no_default_parms) 
+                { 
+                    cx=malloc(250); 
+                    cy = malloc(250); 
+                     
+                    sprintf(cx, "%f", x); 
+                    sprintf(cy, "%f", y); 
+ 
+                    user_parms[nparms] = (const char *) cx; 
+                    user_parms[nparms + 1] = (const char *) cy; 
+                    user_parms[nparms + 2] = NULL; 
+                } 
+            else 
+                user_parms[nparms] = NULL; 
+             
+             
+/* Check the existence of the file, FIXME Should check too the exec permissions */ 
+            fp = fopen(user_parms[0], "r"); 
+            if (fp == NULL) 
+                { 
+                    fprintf(stderr, "Warning: File '%s' not found\n", user_parms[0]); 
+                    return; 
+                } 
+            else 
+                { 
+                    fclose(fp); 
+                    if (fork() == 0) 
+                        { 
+                               execv(user_parms[0], (char *const) user_parms); 
+                //system(user_parms[0]); 
+                        } 
+                }             
+        } 
+} 
+ 
+ 
 static struct command_table commands[] = {
     {"zoom_in",command_cast(navit_cmd_zoom_in)},
     {"zoom_out",command_cast(navit_cmd_zoom_out)},
@@ -744,6 +832,7 @@
     {"set_destination",command_cast(navit_cmd_set_destination)},
     {"announcer_toggle",command_cast(navit_cmd_announcer_toggle)},
     {"fmt_coordinates",command_cast(navit_cmd_fmt_coordinates)},
+    {"sys_cmd", command_cast(navit_cmd_sys_cmd)}, 
 };
     
 
