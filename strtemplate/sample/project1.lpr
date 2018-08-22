program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, StrTemplateCore, StrTemplateWithClasses;

var
  t: TStringList;

begin
  t:=TStringList.Create;
  try
    t.Values['username']:='John';
    t.Values['hello']:='World';
    //t.Values['variable']:='or yes, there is';

    //writeln(FillTemplate('%username%', t));
    //writeln(FillTemplate('pepe', t));
    writeln(FillTemplate('%% Hello, %username%%username% your hello is %hello%. And there''s no variable: %variable%. Should be working at 100%%', t));
    //writeln(FillTemplate('%pepe%', t));
    //writeln(FillTemplate('Hello, %username%%username% your hello is %hello', t));
  finally
    t.Free;
  end;
end.


