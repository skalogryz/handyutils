program hashsample;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, hashstrings;

var
  st : THashedStringList;
begin
  st := THashedStringList.Create;
  try
    st.Values['test']:='test1';
    writeln(st.Text);
  finally
    st.Free;
  end;
end.

