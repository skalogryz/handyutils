{
  Free to any use - distribution, changes and modification w/o any notice.
  Dmitry 'skalogryz' Boyarintsev - Aug 2018

}
unit StrTemplateWithClasses;

{$ifdef fpc}{$mode delphi}{$H+}{$endif}

interface

uses
  Classes, SysUtils, StrTemplateCore;


function FillTemplate(const s: string; src: TStrings): string; overload;
function FillTemplate(const tmp: TTemplate; src: TStrings): string; overload;

// todo: This actoually would be slow, because TStrings.Value[] is used
//       Value[] is typically implemented as a linear search (with parsing actual values)
//       So, if your list is long, then it would be quite ineffecient.
//       But, if your list is short, you can consider the soltuion as good-enough
function StringsToValSource(src: TStrings): TValSource;

type

  { TStringsValSource }

  TStringsValSource = class(TValSource)
    data: TStrings;
    constructor Create(Asource: Tstrings);
    function LenOf(const val: string): Integer; override;
    function CopyTo(const val: string; var dst: String; ofs: Integer): Integer; override;
  end;

implementation

function StringsToValSource(src: TStrings): TValSource;
begin
  Result:=TStringsValSource.Create(src);
end;

function FillTemplate(const s: string; src: TStrings): string; overload;
var
  tmp : TTemplate;
begin
  tmp := ParseTemplate(s);
  try
    Result := FillTemplate(tmp, src);
  finally
    tmp.Free;
  end;
end;

function FillTemplate(const tmp: TTemplate; src: TStrings): string; overload;
var
  vs : TValSource;
begin
  vs := StringsToValSource(src);
  try
    Result := FillTemplate(tmp, vs);
  finally
    vs.Free;
  end;
end;

{ TStringsValSource }

constructor TStringsValSource.Create(Asource: Tstrings);
begin
  inherited Create;
  data:=ASource;
end;

function TStringsValSource.LenOf(const val: string): Integer;
begin
  Result:=length(data.Values[val]);
end;

function TStringsValSource.CopyTo(const val: string; var dst: String;
  ofs: Integer): Integer;
var
  s : string;
begin
  s := data.Values[val];
  Result := length(s);
  if (length(s)>0) then Move(s[1], dst[ofs], Result);
end;

end.

