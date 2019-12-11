with Ada.Text_IO;

with Foo;


procedure Main is
begin
   Ada.Text_IO.Put_Line("Implementation attributes allowed in Main. " & True'Img);
   Foo.Bar;
end Main;