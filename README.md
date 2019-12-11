How to enforce pragma Restrictions on subunits (**separate** subprograms)
=====

Configuration pragmas, like pragma Restricions, normally applies to
the whole partition. GNAT, however, allows you to enforce the restrictions 
on a per-compilation unit basis by using the "-gnatec" command line switch.
In a project file  (.gpr) this would look like


```Ada    
project Foo is
 
   <...>
   
   package Compiler is
      for Default_Switches ("Ada") use ("-gnatec=restrictions.adc"); -- whole partition
      -- or
      -- for Switches ("foo-baz.adb") use ("-gnatec=restrictions.adc"); -- per-compilation unit
   end Compiler;
   
   <...>
end Foo;
```

This, however, does not work for subunits (**separate** subprograms), as GNAT compiles
subunits as part of the enclosing parent unit.

# So is there a workaround?

Yes.

Well, it's more of a hack than a workaround...
Feel free to find it useful at your own risk ;)

## The hack
The trick is to fool gprbuild into performing a separate (no pun intended) 
syntax checking step on the subunit in question. This example takes advantage
of the way project files work to fake a language and perform the build in multiple steps

Assuming a project project structure like this (most small projects start out in a similar fashion):

* root
  * src            - Source_Dirs
    * foo.ads
    * foo.adb
    * foo-bar.adb  - The subunit
    * main.adb
  * foo.gpr        - The project file
  * obj            - Object_Dir
  * bin            - Exec_Dir

Work through these steps:

1. Create a configuration file with the wanted restrictions (This example prevents using implementation defined attributes, like GNAT's 'Img)
GNAT convention is to to use the file extension .adc, and is called restrictions.adc 
in this example.
2. Move the project file into its own subdirectory
(Mostly to avoid accidental compilation of the original project, as the restrictions won't apply to files in that project)
3. Create another project file in this subdirectory 
(This is where we'll fake a language). 
Called foo_bar.gpr in this example.
4. Create an aggregate project file in the root project directory 
(The new "main" project. This is how we'll build in multiple steps). 
Called restriction_on_separate.gpr in this example


The project structure should now look something like this 
(This how this example is arranged):

* root
  * src                          - Source_Dirs
    * foo.ads
    * foo.adb
    * foo-bar.adb                - The subunit
    * main.adb
  * restriction_on_separate.gpr  - new "main" project
  * adc
    * restrictions.adc           - The configuration file
  * gpr
    * foo.gpr                    - The original project file
    * foo_bar.gpr                - Where the magic happens
  * obj                          - Object_Dir
  * bin                          - Exec_Dir


Now we just have to fake a new language...
In this example, the fake language is called "Subunit". Both the definition and usage is
put in foo_bar.gpr, in the following way.
We want to tell gprbuild to use gcc when compiling, that the file extension to expect is .adb (yeah, same as Ada... Makes it a bit easier)
and not to expect any output from the compilation process.


```Ada
   package Configuration is
      for Object_Generated ("Subunit") use "False";
   end Configuration;
   
   package Naming is
      for Body_Suffix ("Subunit") use ".adb";
   end Naming;
   
   package Compiler is
      for Driver ("Subunit") use "gcc"; 
   end Compiler;

```


We're now ready to use the new language to do a syntax check of the subunit:


```Ada
   for Languages use ("Subunit");
   
   for Source_Dirs use ("../src");
   for Source_Files use ("foo-bar.adb");
   for Object_Dir use "../obj";

   package Compiler is
      for Default_Switches ("Subunit") use ("-c", "-gnatc", "-gnatec=../adc/restrictions.adc");
   end Compiler;

```

We're only fooling gprbuild here, so gcc will still recognize .adb as an Ada file, which means
we only need to tell it to compile only (-c, required by gcc) and to only check syntax and semantics (-gnatc),
and of course which configuration file to use (-gnatec).


So now we're ready to build (-p is just to automatically create any missing directories, like obj and bin)


gprbuild -p -P restriction_on_separate.gpr

The result should look like this:
Compile
   [Subunit]      foo-bar.adb
foo-bar.adb:6:84: violation of restriction "No_Implementation_Attributes" at ../adc/restrictions.adc:1
gprbuild: *** compilation phase failed

Fixing the violation, should now result in a successful build, even though other parts of the code
is using an implementation defined attribute.
 
If I forgot to mention something in this readme, the example should be complete, so take a look there...


