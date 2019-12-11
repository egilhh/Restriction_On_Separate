with Ada.Text_IO;

separate(Foo)
procedure Bar is
begin
   Ada.Text_IO.Put_Line("Implementation attributes allowed in separate Bar" & False'Img);
end Bar;