with Ada.Text_IO;

package body Foo is
   
   procedure Bar is separate;

begin
   Ada.Text_IO.Put_Line("Implementation attributes allowed in Foo. " & True'Img);
end Foo;